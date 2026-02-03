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
Usage: ${0##*/} [NETWORK] [SEED_TX] [SEED_IX] [OWNER]...

Arguments:
  NETWORK  Target network (preview | mainnet)
  SEED_TX  Base16-encoded transaction id of seed UTxO
  SEED_IX  Base16-encoded CBOR output index of seed UTxO
  OWNER    A blake2b-224 hash digest of an owner verification key.
  	   Repeated 4 times for each scope owner:
	   - core_development
	   - ops_and_use_cases
	   - network_compliance
	   - middleware

Example:
  ${0##*/} preview \\
    a8fdcc3912943ee940c0d32db88186337b8346346079e5f945b534a791c43e26 \\
    01 \\
    7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb \\
    6db01d01e6fe2b770eea422f0323f7425ef727e487a817ac2d752a9a \\
    d01e6fe2b770eea422f0323f7425ef727e487a817ac2d752a9a6db01 \\
    70b46e985fa50328fcb3d80594b6c5c54974a08d2c766a47570bfa36
EOF
}

NETWORK=${1:-mainnet}
ENV=$(network_to_env $NETWORK)

SEED_TX=${2:-}
fail_when_missing "SEED_TX" ${SEED_TX:-}

SEED_IX=${3:-}
fail_when_missing "SEED_IX" ${SEED_IX:-}

SEED_UTXO="d8799f5820${SEED_TX}${SEED_IX}ff"

CORE_DEVELOPMENT=${4:-}
fail_when_missing "CORE_DEVELOPMENT" ${CORE_DEVELOPMENT:-}

OPS_AND_USE_CASES=${5:-}
fail_when_missing "OPS_AND_USE_CASES" ${OPS_AND_USE_CASES:-}

NETWORK_COMPLIANCE=${6:-}
fail_when_missing "NETWORK_COMPLIANCE" ${NETWORK_COMPLIANCE:-}

MIDDLEWARE=${7:-}
fail_when_missing "MIDDLEWARE" ${MIDDLEWARE:-}

aiken build -D --env $ENV

# ---------- Scopes datum
step "Building" "scopes datum"
FN=$(aiken_export "scope" "export_scopes")
SCOPES=$(eval_uplc $FN \
  "$(to_bytestring_term $CORE_DEVELOPMENT)" \
  "$(to_bytestring_term $OPS_AND_USE_CASES)" \
  "$(to_bytestring_term $NETWORK_COMPLIANCE)" \
  "$(to_bytestring_term $MIDDLEWARE)" \
)
step "Scopes" $SCOPES

# ---------- Scopes script
echo "" >&2
step "Compiling" "scopes script"
step "With" "owners"
sub_step "CoreDevelopment" "$CORE_DEVELOPMENT"
sub_step "OpsAndUseCases" "$OPS_AND_USE_CASES"
sub_step "NetworkCompliance" "$NETWORK_COMPLIANCE"
sub_step "Middleware" "$MIDDLEWARE"

step "And" "parameters"
sub_step "Seed UTxO" "$SEED_TX#$SEED_IX"

BLUEPRINT=$(aiken blueprint apply -v scopes $SEED_UTXO)
VALIDATOR=$(echo $BLUEPRINT | jq -r '.validators[] | select(.title=="traps.scopes.spend")')
HASH=$(echo $VALIDATOR | jq -r '.hash')
SCRIPT=$(echo $VALIDATOR | jq -r '.compiledCode')
step "Hash" $HASH
OUT=build/scopes.plutus.json
echo $BLUEPRINT | \
  jq '.validators = ([.validators[] | select(.title=="traps.scopes.spend")])' | \
  jq ".validators[0].title = \"scopes\"" > $OUT
step "Saved as" $OUT

# ---------- Scopes minting
echo "" >&2

echo -e "\033[1mBuild minting transaction?\033[0m (requires a running cardano-node)" >&2
ask_to_continue
fail_when_missing "CARDANO_NODE_SOCKET_PATH" ${CARDANO_NODE_SOCKET_PATH:-}

SCOPES_TOKEN_NAME=$(get_toml "aiken.toml" "config.$ENV" "scopes_token_name" | tr -d "\n" | basenc --base16 -w 0)

if [[ $NETWORK == "mainnet" ]]; then
  NETWORK_FLAG="--mainnet"
  ADDRESS=$(bech32 addr <<< "71$HASH")
else
  NETWORK_FLAG="--testnet-magic 2"
  ADDRESS=$(bech32 addr_test <<< "70$HASH")
fi

CHANGE_ADDR=$(cardano-cli conway query utxo \
  $NETWORK_FLAG \
  --tx-in "$SEED_TX#$SEED_IX" \
  --output-json | jq -r ".[].address" \
)

if [[ -z "$CHANGE_ADDR" ]]; then
  echo -e "\033[91mSeed UTxO missing or already spent!\033[0m" >&2
  exit 1
fi

step "Change" $CHANGE_ADDR

TMP=$(mktemp -d)
echo $SCOPES | tr [:lower:] [:upper:] | basenc -d --base16 > $TMP/datum.cbor
echo -e "{\n  \"type\": \"PlutusScriptV3\",\n  \"description\": \"\",\n  \"cborHex\": \"$SCRIPT\"\n}" > $TMP/script.cbor

OUT=build/mint-scopes.tx.json

CLI_OUT=$(cardano-cli conway transaction build \
  $NETWORK_FLAG \
  --tx-in "$SEED_TX#$SEED_IX" \
  --tx-in-collateral "$SEED_TX#$SEED_IX" \
  --tx-out "$ADDRESS+2000000+1 $HASH.$SCOPES_TOKEN_NAME" \
  --tx-out-inline-datum-cbor-file $TMP/datum.cbor \
  --mint "1 $HASH.$SCOPES_TOKEN_NAME" \
  --mint-script-file $TMP/script.cbor \
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
