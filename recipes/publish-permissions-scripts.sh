#!/usr/bin/env bash

# Copyright 2026 PRAGMA
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
Usage: ${0##*/} [NETWORK]

Arguments:
  NETWORK   Target network (preview | preprod | mainnet)

Example:
  ${0##*/} preview
EOF
}

trap 'ret=$?; if (( ret != 0 )); then show_usage; fi' EXIT

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

echo -e "\n\033[1mBuild transaction publishing permissions scripts?\033[0m (requires a running cardano-node)" >&2
ask_to_continue

fail_when_missing "CARDANO_NODE_SOCKET_PATH" ${CARDANO_NODE_SOCKET_PATH:-}

TMP=$(mktemp -d)

permissions-script () {
    SCOPE=$1
    ADDR=$2
    SCRIPT=$(jq -r ".validators[0].compiledCode" build/permissions-$SCOPE.plutus.json)
    OUT_SCRIPT=$TMP/script-permissions-$SCOPE.cbor
    echo -e "{\n  \"type\": \"PlutusScriptV3\",\n  \"description\": \"\",\n  \"cborHex\": \"$SCRIPT\"\n}" > $OUT_SCRIPT
    echo "--tx-out $ADDR+25000000 --tx-out-reference-script-file $OUT_SCRIPT"
}

if [[ $NETWORK == "mainnet" ]]; then
  NETWORK_FLAG="--mainnet"
elif [[ $NETWORK == "preprod" ]]; then
  NETWORK_FLAG="--testnet-magic 1"
else
  NETWORK_FLAG="--testnet-magic 2"
fi

echo -e "\033[1mProvide a fuel UTxO's transaction id:\033[0m (base16 / hex-encoded)" >&2
read -p "❯ " FUEL_TX

echo -e "\033[1mProvide a fuel UTxO's output index:\033[0m (with leading 0)" >&2
read -p "❯ " FUEL_IX

step "Fuel UTxO" "$FUEL_TX#$FUEL_IX"

CHANGE_ADDR=$(cardano-cli conway query utxo \
  $NETWORK_FLAG \
  --tx-in "$FUEL_TX#$FUEL_IX" \
  --output-json | jq -r ".[].address" \
)

if [[ -z "$CHANGE_ADDR" ]]; then
  echo -e "\033[91mSeed UTxO missing or already spent!\033[0m" >&2
  exit 1
fi

step "Change" $CHANGE_ADDR

OUT=build/publish-permissions-scripts.tx.json

CLI_OUT=$(cardano-cli conway transaction build \
   $NETWORK_FLAG \
   --tx-in "$FUEL_TX#$FUEL_IX" \
   $(permissions-script core_development $CHANGE_ADDR) \
   $(permissions-script ops_and_use_cases $CHANGE_ADDR) \
   $(permissions-script network_compliance $CHANGE_ADDR) \
   $(permissions-script middleware $CHANGE_ADDR) \
   $(permissions-script contingency $CHANGE_ADDR) \
   --change-address $CHANGE_ADDR \
   --out-file $OUT)

if [[ $? != 0 ]]; then
  echo $CLI_OUT
  exit 1
fi

step "Saved as" $OUT
