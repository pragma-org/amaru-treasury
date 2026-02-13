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
  cat <<EOF Register treasury scripts as stake credentials, for use in withdrawals & governance actions.
Usage: ${0##*/} [NETWORK]

Arguments:
  NETWORK      Target network (preview | mainnet)

Example:
  ${0##*/} preview
EOF
}

trap 'ret=$?; if (( ret != 0 )); then show_usage; fi' EXIT

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

echo -e "\n\033[1mBuild stake credential registrations & always-abstain vote delegations for all treasury scripts?\033[0m (requires a running cardano-node)" >&2
ask_to_continue
fail_when_missing "CARDANO_NODE_SOCKET_PATH" ${CARDANO_NODE_SOCKET_PATH:-}

echo -e "\033[1mProvide a fuel UTxO's transaction id:\033[0m (base16 / hex-encoded)" >&2
read -p "❯ " FUEL_TX

echo -e "\033[1mProvide a fuel UTxO's output index:\033[0m (with leading 0)" >&2
read -p "❯ " FUEL_IX

step "Fuel UTxO" "$FUEL_TX#$FUEL_IX"

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

register_stake_credential () {
  SCOPE=$1
  step "Scope" $SCOPE
  SCRIPT=$(jq -r ".validators[0].compiledCode" build/treasury-$SCOPE.plutus.json)
  OUT_SCRIPT=$TMP/script-treasury-$SCOPE.cbor
  OUT_CERT=$TMP/certificate-treasury-$SCOPE.json
  echo -e "{\n  \"type\": \"PlutusScriptV3\",\n  \"description\": \"\",\n  \"cborHex\": \"$SCRIPT\"\n}" > $OUT_SCRIPT
  cardano-cli conway stake-address registration-and-vote-delegation-certificate --always-abstain --key-reg-deposit-amt 2000000 --stake-script-file $OUT_SCRIPT --out-file $OUT_CERT
  echo "--certificate-file $OUT_CERT --certificate-script-file $OUT_SCRIPT --certificate-redeemer-value \"[]\""
}

OUT=build/register-treasury-as-credentials.tx.json

CLI_OUT=$(cardano-cli conway transaction build \
   $NETWORK_FLAG \
   --tx-in "$FUEL_TX#$FUEL_IX" \
   --tx-in-collateral "$FUEL_TX#$FUEL_IX" \
   $(register_stake_credential "core_development") \
   $(register_stake_credential "ops_and_use_cases") \
   $(register_stake_credential "network_compliance") \
   $(register_stake_credential "middleware") \
   $(register_stake_credential "contingency") \
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
