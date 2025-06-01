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
Usage: ${0##*/} [NETWORK] [SCOPE] [REGISTRY_TX] [REGISTRY_IX]

Arguments:
  NETWORK      Target network (preview | mainnet)
  SCOPE        Which scope to create permissions for (ledger, consensus, mercenaries or marketing)
  REGISTRY_TX  Base16-encoded transaction id of registry UTxO
  REGISTRY_IX  Base16-encoded CBOR output index of registry UTxO

Example:
  ${0##*/} preview \\
    ledger \\
    a8fdcc3912943ee940c0d32db88186337b8346346079e5f945b534a791c43e26 \\
    01
EOF
}

trap 'ret=$?; if (( ret != 0 )); then show_usage; fi' EXIT

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

SCOPE=$2
fail_when_missing "SCOPE" ${SCOPE:-}
SCOPE_CONSTR=$(scope_to_constr $SCOPE)
SCOPE_OWNER=$(jq -r ".validators[0].hash" build/permissions-$SCOPE.plutus.json)

REGISTRY_TX=${3:-}
fail_when_missing "REGISTRY_TX" ${REGISTRY_TX:-}

REGISTRY_IX=${4:-}
fail_when_missing "REGISTRY_IX" ${REGISTRY_IX:-}

REGISTRY_UTXO="d8799f5820${REGISTRY_TX}${REGISTRY_IX}ff"

## ---------- Registry

aiken build -D --env $ENV

step "Applying" "parameters"
sub_step "Registry UTxO" "$REGISTRY_TX#$REGISTRY_IX"
sub_step "Scope" $SCOPE

TMP=$(mktemp)
aiken blueprint apply -o $TMP -v treasury_registry $REGISTRY_UTXO
REGISTRY_BLUEPRINT=$(aiken blueprint apply -i $TMP -v treasury_registry $SCOPE_CONSTR)
REGISTRY_VALIDATOR=$(echo $REGISTRY_BLUEPRINT | jq -r '.validators[] | select(.title=="traps.treasury_registry.mint")')
REGISTRY_HASH=$(echo $REGISTRY_VALIDATOR | jq -r '.hash')
step "Hash" $REGISTRY_HASH
step "Size" "$(script_size "$REGISTRY_VALIDATOR") bytes"
OUT=build/registry-$SCOPE.plutus.json
echo $REGISTRY_BLUEPRINT | \
  jq '.validators = ([.validators[] | select(.title=="traps.treasury_registry.mint")])' | \
  jq ".validators[0].title = \"registry~1$SCOPE\"" > $OUT
step "Saved as" $OUT

## ---------- Treasury config

echo "" >&2
cd treasury-contracts

aiken build -D

FN=$(aiken_export "types" "export_treasury_configuration")
TREASURY_CONFIG=$(eval_uplc $FN \
  "$(to_bytestring_term $REGISTRY_HASH)" \
  "$(to_bytestring_term $SCOPE_OWNER)" \
)
BLUEPRINT=$(aiken blueprint apply -v treasury $TREASURY_CONFIG)

cd ..

echo $TREASURY_CONFIG | tr [:lower:] [:upper:] | basenc -d --base16 > build/treasury-configuration-$SCOPE.cbor

## ---------- Treasury config

VALIDATOR=$(echo $BLUEPRINT | jq -r '.validators[] | select(.title=="treasury.treasury.else")')
HASH=$(echo $VALIDATOR | jq -r '.hash')
step "Hash" $HASH
step "Size" "$(script_size "$VALIDATOR") bytes"

OUT="build/treasury-$SCOPE.plutus.json"
echo $BLUEPRINT | \
  jq '.validators = ([.validators[] | select(.title=="treasury.treasury.else")])' | \
  jq ".validators[0].title = \"treasury~1$SCOPE\"" > $OUT
step "Saved as" $OUT
echo "" >&2
