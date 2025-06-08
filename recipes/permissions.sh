#!/usr/bin/env bash

# Copyright 2025 PRAGMA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -euo pipefail
source recipes/shared.sh

show_usage() {
  cat <<EOF
Usage: ${0##*/} [NETWORK] [SCOPE]

Arguments:
  NETWORK      Target network (preview | mainnet)
  SCOPE        Which scope to create permissions for (ledger, consensus, mercenaries, marketing or contingency)

Example:
  ${0##*/} preview ledger 5bc659e149349b7d1d23493c7b7276a2ac83ad07c4249c125d3b1f49
EOF
}

trap 'ret=$?; if (( ret != 0 )); then show_usage; fi' EXIT

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

SCOPE=${2:-}
fail_when_missing "SCOPE" ${SCOPE:-}
SCOPE_CONSTR=$(scope_to_constr $SCOPE)

SCOPES_HASH=$(jq -r ".validators[0].hash" build/scopes.plutus.json)
fail_when_missing "SCOPES_HASH" ${SCOPES_HASH:-}

step "Building" "$SCOPE's permissions"
aiken build -D --env $ENV

TMP=$(mktemp)
step "Applying" "parameters"

sub_step "Scopes NFT" $SCOPES_HASH
aiken blueprint apply -v permissions -o $TMP "581c$SCOPES_HASH"

sub_step "Scope" $SCOPE
BLUEPRINT=$(aiken blueprint apply -i $TMP -v permissions $SCOPE_CONSTR)

VALIDATOR=$(echo $BLUEPRINT | jq -r '.validators[] | select(.title=="permissions.permissions.withdraw")')
HASH=$(echo $VALIDATOR | jq -r '.hash')
step "Hash" $HASH
step "Size" "$(script_size "$VALIDATOR") bytes"

OUT="build/permissions-$SCOPE.plutus.json"
echo $BLUEPRINT | \
  jq '.validators = ([.validators[] | select(.title=="permissions.permissions.withdraw")])' | \
  jq ".validators[0].title = \"permissions~1$SCOPE\"" > $OUT
step "Saved as" $OUT
echo "" >&2

# Quick sanity check that all permissions scripts have been compiled with the same params...
SCOPES=(ledger consensus mercenaries marketing contingency)
ALL_MATCH=true
for s in "${SCOPES[@]}"; do
  f="build/permissions-$s.plutus.json"
  if [[ ! -f $f ]] || ! grep -q "$SCOPES_HASH" "$f"; then
    ALL_MATCH=false
    break
  fi
done

if [ "$ALL_MATCH" == "true" ]; then
  echo -e "\n\033[1mBuild minting transaction?\033[0m (requires a running cardano-node)" >&2
  ask_to_continue
  fail_when_missing "CARDANO_NODE_SOCKET_PATH" ${CARDANO_NODE_SOCKET_PATH:-}

  echo -e "\033[1mProvide a fuel UTxO's transaction id:\033[0m (base16 / hex-encoded)" >&2
  read -p "❯ " FUEL_TX

  echo -e "\033[1mProvide a fuel UTxO's output index:\033[0m (with leading 0)" >&2
  read -p "❯ " FUEL_IX

  step "Fuel UTxO" "$FUEL_TX#$FUEL_IX"

  # echo -e "\n\033[1mConfirm?\033[0m" >&2
  # ask_to_continue

  if [[ $NETWORK == "mainnet" ]]; then
    NETWORK_FLAG="--mainnet"
  elif [[ $NETWORK == "preprod" ]]; then
    NETWORK_FLAG="--testnet-magic 1"
  else
    NETWORK_FLAG="--testnet-magic 2"
  fi

  CHANGE_ADDR=$(cardano-cli conway query utxo \
    $NETWORK_FLAG \
    --tx-in "$FUEL_TX#$FUEL_IX" \
    --output-json | jq -r ".[].address" \
  )

  if [[ -z "$CHANGE_ADDR" ]]; then
    echo -e "\033[91mFuel UTxO missing or already spent!\033[0m" >&2
    exit 1
  fi

  step "Change" $CHANGE_ADDR

  TMP=$(mktemp -d)

  permissions () {
    SCOPE=$1
    step "Scope" $SCOPE
    SCRIPT=$(jq -r ".validators[0].compiledCode" build/permissions-$SCOPE.plutus.json)
    OUT_SCRIPT=$TMP/script-permissions-$SCOPE.cbor
    OUT_CERT=$TMP/certificate-permissions-$SCOPE.json
    echo -e "{\n  \"type\": \"PlutusScriptV3\",\n  \"description\": \"\",\n  \"cborHex\": \"$SCRIPT\"\n}" > $OUT_SCRIPT
    cardano-cli conway stake-address registration-certificate --key-reg-deposit-amt 2000000 --stake-script-file $OUT_SCRIPT --out-file $OUT_CERT
    echo "--certificate-file $OUT_CERT --certificate-script-file $OUT_SCRIPT --certificate-redeemer-value \"[]\""
  }

  OUT=build/publish-permissions.tx.json

  CLI_OUT=$(cardano-cli conway transaction build \
     $NETWORK_FLAG \
     --tx-in "$FUEL_TX#$FUEL_IX" \
     --tx-in-collateral "$FUEL_TX#$FUEL_IX" \
     $(permissions "ledger") \
     $(permissions "consensus") \
     $(permissions "mercenaries") \
     $(permissions "marketing") \
     $(permissions "contingency") \
     --change-address $CHANGE_ADDR \
     --out-file $OUT)

  if [[ $? != 0 ]]; then
    echo $CLI_OUT
    exit 1
  fi

  echo "" >&2

  if command -v ogmios 2>&1 >/dev/null; then
    echo -e "\033[1mPreview:\033[0m" >&2
    ogmios inspect transaction $(jq -r ".cborHex" $OUT) | jq "del(.scripts[].cbor)" >&2
    echo "" >&2
  fi

  step "Saved as" $OUT
fi
