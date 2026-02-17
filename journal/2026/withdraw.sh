#!/usr/bin/env bash

set -euo pipefail

# Column at which display values in key/value tables.
COL=26

usage () {
    cat <<EOF
Disburse some ADA to an Amaru contributor

Usage: disburse-ada.sh <WALLET_ADDRESS> <SCOPE>...

Arguments:
  WALLET_ADDRESS:         Address to use to pay fees, collateral, and send change to
  SCOPE:                  Name of treasury scope to disburse from, one of:
  			    - core_development
			    - ops_and_use_cases
			    - network_compliance
			    - middleware
			    - contingency
EOF
}

title () {
  echo -e "\033[95;1m$1\033[0m" >&2
}

human_readable_timestamp () {
  if [ "$(uname)" == "Darwin" ]; then
    date -r $(($1 / 1000))
  else
    date -d "@$(($1 / 1000))"
  fi
}

key_value() {
  local col="$1"
  local key="$2:"
  local value="$3"
  local indent="  "
  printf "%s%-*s %s\n" "  " $col "$key" "$value"
}

network_id() {
  case ${CARDANO_NODE_NETWORK_ID} in
    0) echo -n "--mainnet"
      ;;
    764824073) echo -n "--mainnet"
      ;;
    *) echo -n "--testnet-magic ${CARDANO_NODE_NETWORK_ID}"
      ;;
  esac
}

network_tag() {
  case ${CARDANO_NODE_NETWORK_ID} in
    0) echo -n "mainnet"
     ;;
    764824073) echo -n "mainnet"
     ;;
    1) echo -n "preprod"
     ;;
    2) echo -n "preview"
     ;;
    *) echo "unknown network"; exit 1
     ;;
  esac
}

address_from_script_hash() {
  [[ $# -eq 1 ]] || { echo "expect one script hash argument" ; exit 1 ; }
  HASH=$(echo -n $1 | bech32 script)
  ADDRESS_NO_STAKE=$(echo -n $HASH | cardano-address address payment --network-tag $(network_tag))
  echo -n "$ADDRESS_NO_STAKE" | cardano-address address delegation "$HASH"
}

stake_address_from_script_hash() {
  [[ $# -eq 1 ]] || { echo "expect one script hash argument" ; exit 1 ; }
  HASH=$(echo -n $1 | bech32 script)
  echo -n $HASH | cardano-address address stake --network-tag $(network_tag)
}

ccli () {
  cardano-cli "$@" --socket-path "${CARDANO_NODE_SOCKET_PATH}" $(network_id)
}

[[ $# -eq 2 ]] || { usage ; exit 1 ; }

: "${CARDANO_NODE_SOCKET_PATH:=./node.socket}"
: "${CARDANO_NODE_NETWORK_ID:=2}"
: "${RATIONALE_JSON:=./rationale.json}"

title ":: Environment Variables"
key_value $COL "CARDANO_NODE_SOCKET_PATH" $CARDANO_NODE_SOCKET_PATH
key_value $COL "CARDANO_NODE_NETWORK_ID" $CARDANO_NODE_NETWORK_ID
key_value $COL "RATIONALE_JSON" $RATIONALE_JSON
echo ""

title ":: Arguments"
wallet_address=$1
scope=$2

# Fuel to pay for fees & al. Must be large enough for collateral.
key_value $COL "wallet.address" $wallet_address
key_value $COL "scope" $scope
echo ""

title ":: Configuration"
metadata=$(cat ./$(dirname "$0")/metadata.json | jq -c)
treasury_script_hash=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.hash")
treasury_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.deployed_at")
registry_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.registry_script.deployed_at")
treasury_address=$(address_from_script_hash $treasury_script_hash)
treasury_stake_address=$(stake_address_from_script_hash $treasury_script_hash)
fuel=$(ccli conway query utxo --address "$wallet_address" --output-json | jq -rc '. | keys | @csv' | tr ',' '\n' | tr -d '"' | head -1)

key_value $COL "network" $(network_tag)
key_value $COL "wallet.utxo" $fuel
key_value $COL "treasury.script_hash" $treasury_script_hash
key_value $COL "treasury.address" $treasury_address
key_value $COL "treasury.stake_address" $treasury_stake_address
key_value $COL "treasury.reference" $treasury_reference
key_value $COL "registry.reference" $registry_reference
echo ""

treasury_lovelace=$(ccli conway query stake-address-info --address "$treasury_stake_address" | jq .[0].rewardAccountBalance)

title ":: Treasury's Balance"
key_value $COL "ada (before -> after)" "0 -> $(( ${treasury_lovelace} / 1000000 ))"
echo ""

treasury_instance=$(ccli conway query utxo --tx-in "$registry_reference" --output-json | jq -r -c '.[keys[0]].value | keys[0]')

tmp_metadata=$(mktemp)
jq ".[\"1694\"].instance = \"$treasury_instance\"" $RATIONALE_JSON > $tmp_metadata

args=( \
  "latest" "transaction" "build" \
  "--tx-in" "$fuel" \
  "--tx-in-collateral" "$fuel" \
  "--read-only-tx-in-reference" "$registry_reference" \
  "--withdrawal" "$treasury_stake_address+0" \
  "--withdrawal-tx-in-reference" "$treasury_reference" \
  "--withdrawal-plutus-script-v3" \
  "--withdrawal-reference-tx-in-redeemer-value" "[]" \
)

if [[ $treasury_lovelace -gt 0 ]]; then
  args+=( "--tx-out" "$treasury_address+$treasury_lovelace" )
fi

tmp=$(mktemp)

args+=( \
  "--change-address" "$wallet_address" \
  "--metadata-json-file" $tmp_metadata \
  $(network_id) \
  "--out-file" "$tmp" \
)

title ":: cardano-cli latest transaction build"
i=3
while (( i < ${#args[@]} )); do
  arg="${args[i]}"
  val="${args[i+1]}"

  if [[ "$val" =~ ^-- ]]; then
    key_value 45 "$arg" "true"
    ((i+=1))
  else
    key_value 45 "$arg" "$val"
    ((i+=2))
  fi
done
echo ""

cli_out=$(cardano-cli "${args[@]}")
if [[ $? != 0 ]]; then
  echo $cli_out
  exit 1
fi

# Fix cardano-cli own incompatibilities...
tx_id=$(cardano-cli conway transaction txid --tx-file $tmp --output-text)
out=withdraw-$scope-${tx_id:0:12}.cbor.json
jq '.type = "Tx ConwayEra"' $tmp > $out

title ":: Transaction"
key_value $COL "transaction.id" "$tx_id"
key_value $COL "transaction.file" "$out"
