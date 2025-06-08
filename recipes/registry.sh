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
Usage: ${0##*/} [NETWORK] [REGISTRY_TX] [REGISTRY_IX]

Arguments:
  NETWORK      Target network (preview | mainnet)
  REGISTRY_TX  Base16-encoded transaction id of registry UTxO
  REGISTRY_IX  Base16-encoded CBOR output index of registry UTxO

Example:
  ${0##*/} preview \\
    a8fdcc3912943ee940c0d32db88186337b8346346079e5f945b534a791c43e26 \\
    01
EOF
}

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

REGISTRY_TX=${2:-}
fail_when_missing "REGISTRY_TX" ${REGISTRY_TX:-}

REGISTRY_IX=${3:-}
fail_when_missing "REGISTRY_IX" ${REGISTRY_IX:-}

REGISTRY_UTXO="d8799f5820${REGISTRY_TX}${REGISTRY_IX}ff"

step "Seed UTxO" "$REGISTRY_TX#$REGISTRY_IX"
OUT=build/registry-seed.json
echo "{ \"transactionId\": \"$REGISTRY_TX\", \"outputIndex\": $(echo $REGISTRY_IX | sed 's/^0*\([0-9]*\)$/\1/') }" > $OUT
step "Saved As" $OUT


aiken build -D --env $ENV

echo -e "\033[1mBuild minting transaction?\033[0m (requires a running cardano-node)" >&2
ask_to_continue
fail_when_missing "CARDANO_NODE_SOCKET_PATH" ${CARDANO_NODE_SOCKET_PATH:-}

# Construct each treasury registry, for all scopes

TMP=$(mktemp -d)

registry () {
  SCOPE=$1
  step "Scope" $SCOPE
  HASH_TREASURY=$(jq -r ".validators[0].hash" build/treasury-$SCOPE.plutus.json)
  step "Treasury" $HASH_TREASURY
  FN=$(aiken_export "registry" "export_registry")
  DATUM_REGISTRY=$(eval_uplc $FN \
    "$(to_bytestring_term $HASH_TREASURY)" \
  )
  step "Datum" $DATUM_REGISTRY
  echo $DATUM_REGISTRY | tr [:lower:] [:upper:] | basenc -d --base16 > $TMP/datum-$SCOPE.cbor
  SCRIPT=$(jq -r ".validators[0].compiledCode" build/registry-$SCOPE.plutus.json)
  echo -e "{\n  \"type\": \"PlutusScriptV3\",\n  \"description\": \"\",\n  \"cborHex\": \"$SCRIPT\"\n}" > $TMP/script-$SCOPE.cbor
  echo "" >&2
  jq -r ".validators[0].hash" build/registry-$SCOPE.plutus.json
}

HASH_LEDGER=$(registry "ledger")
TOKEN_NAME_LEDGER=$(echo -n "ledger" | basenc --base16 -w 0)
HASH_CONSENSUS=$(registry "consensus")
TOKEN_NAME_CONSENSUS=$(echo -n "consensus" | basenc --base16 -w 0)
HASH_MERCENARIES=$(registry "mercenaries")
TOKEN_NAME_MERCENARIES=$(echo -n "mercenaries" | basenc --base16 -w 0)
HASH_MARKETING=$(registry "marketing")
TOKEN_NAME_MARKETING=$(echo -n "marketing" | basenc --base16 -w 0)
HASH_CONTINGENCY=$(registry "contingency")
TOKEN_NAME_CONTINGENCY=$(echo -n "contingency" | basenc --base16 -w 0)

if [[ $NETWORK == "mainnet" ]]; then
  NETWORK_FLAG="--mainnet"
  ADDRESS_LEDGER=$(bech32 addr <<< "71$HASH_LEDGER")
  ADDRESS_CONSENSUS=$(bech32 addr <<< "71$HASH_CONSENSUS")
  ADDRESS_MERCENARIES=$(bech32 addr <<< "71$HASH_MERCENARIES")
  ADDRESS_MARKETING=$(bech32 addr <<< "71$HASH_MARKETING")
  ADDRESS_CONTINGENCY=$(bech32 addr <<< "71$HASH_CONTINGENCY")
else
  NETWORK_FLAG="--testnet-magic 2"
  ADDRESS_LEDGER=$(bech32 addr_test <<< "70$HASH_LEDGER")
  ADDRESS_CONSENSUS=$(bech32 addr_test <<< "70$HASH_CONSENSUS")
  ADDRESS_MERCENARIES=$(bech32 addr_test <<< "70$HASH_MERCENARIES")
  ADDRESS_MARKETING=$(bech32 addr_test <<< "70$HASH_MARKETING")
  ADDRESS_CONTINGENCY=$(bech32 addr_test <<< "70$HASH_CONTINGENCY")
fi

CHANGE_ADDR=$(cardano-cli conway query utxo \
  $NETWORK_FLAG \
  --tx-in "$REGISTRY_TX#$REGISTRY_IX" \
  --output-json | jq -r ".[].address" \
)

if [[ -z "$CHANGE_ADDR" ]]; then
  echo -e "\033[91mSeed UTxO missing or already spent!\033[0m" >&2
  exit 1
fi

step "Change" $CHANGE_ADDR

OUT=build/mint-registries.tx.json


CLI_OUT=$(cardano-cli conway transaction build \
   $NETWORK_FLAG \
   --tx-in "$REGISTRY_TX#$REGISTRY_IX" \
   --tx-in-collateral "$REGISTRY_TX#$REGISTRY_IX" \
   --tx-out "$ADDRESS_LEDGER+2000000+1 $HASH_LEDGER.$TOKEN_NAME_LEDGER" \
   --tx-out-inline-datum-cbor-file $TMP/datum-ledger.cbor \
   --tx-out "$ADDRESS_CONSENSUS+2000000+1 $HASH_CONSENSUS.$TOKEN_NAME_CONSENSUS" \
   --tx-out-inline-datum-cbor-file $TMP/datum-consensus.cbor \
   --tx-out "$ADDRESS_MERCENARIES+2000000+1 $HASH_MERCENARIES.$TOKEN_NAME_MERCENARIES" \
   --tx-out-inline-datum-cbor-file $TMP/datum-mercenaries.cbor \
   --tx-out "$ADDRESS_MARKETING+2000000+1 $HASH_MARKETING.$TOKEN_NAME_MARKETING" \
   --tx-out-inline-datum-cbor-file $TMP/datum-marketing.cbor \
   --tx-out "$ADDRESS_CONTINGENCY+2000000+1 $HASH_CONTINGENCY.$TOKEN_NAME_CONTINGENCY" \
   --tx-out-inline-datum-cbor-file $TMP/datum-contingency.cbor \
   --mint "1 $HASH_LEDGER.$TOKEN_NAME_LEDGER+1 $HASH_CONSENSUS.$TOKEN_NAME_CONSENSUS+1 $HASH_MERCENARIES.$TOKEN_NAME_MERCENARIES+1 $HASH_MARKETING.$TOKEN_NAME_MARKETING+1 $HASH_CONSENSUS.$TOKEN_NAME_CONTINGENCY" \
   --mint-script-file $TMP/script-ledger.cbor \
   --mint-redeemer-value "[]" \
   --mint-script-file $TMP/script-consensus.cbor \
   --mint-redeemer-value "[]" \
   --mint-script-file $TMP/script-mercenaries.cbor \
   --mint-redeemer-value "[]" \
   --mint-script-file $TMP/script-marketing.cbor \
   --mint-redeemer-value "[]" \
   --mint-script-file $TMP/script-contingency.cbor \
   --mint-redeemer-value "[]" \
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
