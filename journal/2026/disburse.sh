#!/usr/bin/env bash

set -euo pipefail

# Column at which display values in key/value tables.
COL=26

usage () {
    cat <<EOF
Disburse some ADA to an Amaru contributor

Usage: disburse-ada.sh <WALLET_ADDRESS> <AMOUNT> <UNIT> <BENEFICIARY_ADDRESS> <SCOPE> <WITNESS_SCOPE>...

Arguments:
  WALLET_ADDRESS:         Address to use to pay fees, collateral, and send change to
  AMOUNT:                 Amount to send to beneficiary, without decimals.
  UNIT: 		  Unit to use for the amount; either ada or usdm.
  BENEFICIARY_ADDRESS:    Address of the beneficiary to receive disbursement
  SCOPE:                  Name of treasury scope to disburse from, one of:
  			    - core_development
			    - ops_and_use_cases
			    - network_compliance
			    - middleware
			    - contingency
  WITNESS_SCOPE: 	  Other scope owner(s) required for disbursement. May be repeated.
			  Can be one of:
  			    - core_development
			    - ops_and_use_cases
			    - network_compliance
			    - middleware
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

[[ $# -ge 5 ]] || { usage ; exit 1 ; }

: "${CARDANO_NODE_SOCKET_PATH:=./node.socket}"
: "${CARDANO_NODE_NETWORK_ID:=2}"
: "${RATIONALE_JSON:=./rationale.json}"
: "${USDM_POLICY:=c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad}"
: "${USDM_TOKEN:=0014df105553444d}"

title ":: Environment Variables"
key_value $COL "CARDANO_NODE_SOCKET_PATH" $CARDANO_NODE_SOCKET_PATH
key_value $COL "CARDANO_NODE_NETWORK_ID" $CARDANO_NODE_NETWORK_ID
key_value $COL "RATIONALE_JSON" $RATIONALE_JSON
echo ""

title ":: Arguments"
wallet_address=$1
amount=$2
unit=$3
beneficiary_address=$4
scope=$5
witness_scopes=${@:6}

if [[ $unit == "ada" ]]; then
  amount_lovelace=$(( amount * 1000000 ))
  amount_usdm=0
elif [[ $unit == "usdm" ]]; then
  amount_lovelace=0
  amount_usdm=$(( amount * 1000000 ))
else
  echo "unrecognized unit; expected either 'ada' or 'usdm'"
  exit 1
fi

# Fuel to pay for fees & al. Must be large enough for collateral.
key_value $COL "wallet.address" $wallet_address
key_value $COL "beneficiary.address" $beneficiary_address
key_value $COL "amount.$unit" $amount
key_value $COL "scope" $scope
key_value $COL "witnesses" "${witness_scopes[@]}"
echo ""

title ":: Configuration"
metadata=$(cat ./$(dirname "$0")/metadata.json | jq -c)
owner_credential=$(echo "${metadata}" | jq -r ".treasuries.${scope}.owner")
treasury_script_hash=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.hash")
treasury_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.treasury_script.deployed_at")
permissions_script_hash=$(echo "${metadata}" | jq -r ".treasuries.${scope}.permissions_script.hash")
permissions_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.permissions_script.deployed_at")
registry_reference=$(echo "${metadata}" | jq -r ".treasuries.${scope}.registry_script.deployed_at")
scopes_reference=$(echo "${metadata}" | jq -r ".scope_owners")
treasury_address=$(address_from_script_hash $treasury_script_hash)
permissions_stake_address=$(stake_address_from_script_hash $permissions_script_hash)

fuel=$(ccli conway query utxo --address "$wallet_address" --output-json | jq -rc '. | keys | @csv' | tr ',' '\n' | tr -d '"' | head -1)

key_value $COL "network" $(network_tag)
key_value $COL "wallet.utxo" $fuel
key_value $COL "owner.credential" $owner_credential
key_value $COL "treasury.script_hash" $treasury_script_hash
key_value $COL "treasury.address" $treasury_address
key_value $COL "treasury.reference" $treasury_reference
key_value $COL "permissions.script_hash" $permissions_script_hash
key_value $COL "permissions.address" $permissions_stake_address
key_value $COL "permissions.reference" $permissions_reference
key_value $COL "registry.reference" $registry_reference
key_value $COL "scopes.reference" $scopes_reference
echo ""

# Possible signers, we need at least 2 out of 4, with at minima the scope's owner.
title ":: Signers"
signers=()
owner=$(echo "$metadata" | jq -cr ".treasuries.${scope}.owner")
if [[ $scope != "contingency" ]]; then
  key_value $COL "* $scope.key" $owner
  signers+=( $owner )
fi
for witness in ${witness_scopes[@]}; do
  if [[ $witness == "contingency" ]]; then
    usage
    exit 1
  fi
  key=$(echo "$metadata" | jq -cr ".treasuries.${witness}.owner")
  key_value $COL "+ $witness.key" $key
  signers+=( $key )
done
echo ""

tmp_utxos=$(mktemp)
if [[ $unit == "ada" ]]; then
  utxo_filter="to_entries | .[] | [.key,.value.value.${USDM_POLICY}[\"${USDM_TOKEN}\"],.value.value.lovelace] | @csv"
else
  utxo_filter="to_entries | .[] | [.key,.value.value.${USDM_POLICY}[\"${USDM_TOKEN}\"],.value.value.lovelace] | select(.[1]) | @csv"
fi
treasury_utxos=$(ccli conway query utxo --address "$treasury_address" --output-json | jq -rc "$utxo_filter" | tr -d '"' > $tmp_utxos)

acc_usdm=0
acc_lovelace=0
acc_txins=

while IFS=, read txin usdm lovelace ; do
    if [[ -n "$usdm" ]]; then
      acc_usdm=$(( $acc_usdm + $usdm ))
    fi

    acc_lovelace=$(( $acc_lovelace + $lovelace ))

    usdms+=( $usdm )
    lovelaces+=( $lovelace )
    txins+=( $txin )

    if [[ $acc_lovelace -ge $amount_lovelace ]] ; then
      break
    fi
done < $tmp_utxos

leftover_treasury_lovelace=$(($acc_lovelace - $amount_lovelace))
leftover_treasury_usdm=$(($acc_usdm - $amount_usdm))

title ":: Treasury's Balance"
key_value $COL "ada (before -> after)" "$(( ${acc_lovelace} / 1000000 )) -> $(( ${leftover_treasury_lovelace} / 1000000 ))"
key_value $COL "usdm (before -> after)" "$(( ${acc_usdm} / 1000000 )) -> $(( ${leftover_treasury_usdm} / 1000000 ))"
echo ""

treasury_instance=$(ccli conway query utxo --tx-in "$registry_reference" --output-json | jq -r -c '.[keys[0]].value | keys[0]')

tmp_metadata=$(mktemp)
jq ".[\"1694\"].instance = \"$treasury_instance\"" $RATIONALE_JSON > $tmp_metadata

tmp_redeemer=$(mktemp)
if [[ $unit == "ada" ]]; then
  jq --null-input "{ constructor: 3, fields: [ { map: [ { k: {bytes: \"\"}, v: { map: [{k: {bytes: \"\"}, v : {int: ${amount_lovelace} } } ] } }]}]}" > $tmp_redeemer
else
  jq --null-input "{ constructor: 3, fields: [ { map: [ { k: {bytes: \"$USDM_POLICY\"}, v: { map: [{k: {bytes: \"$USDM_TOKEN\"}, v : {int: ${amount_usdm} } } ] } }]}]}" > $tmp_redeemer
fi

args=( \
  "latest" "transaction" "build" \
  "--tx-in" "$fuel" \
  "--tx-in-collateral" "$fuel" \
)

for signer in ${signers[@]}; do
  args+=( "--required-signer-hash" "$signer" )
done

for i in ${!lovelaces[@]}; do
  args+=( \
    "--tx-in" "${txins[$i]}" \
    "--spending-tx-in-reference" "$treasury_reference" \
    "--spending-plutus-script-v3" \
    "--spending-reference-tx-in-redeemer-file" $tmp_redeemer \
    "--read-only-tx-in-reference" "$registry_reference" \
    "--read-only-tx-in-reference" "$scopes_reference" \
    "--withdrawal" "$permissions_stake_address+0" \
    "--withdrawal-tx-in-reference" "$permissions_reference" \
    "--withdrawal-plutus-script-v3" \
    "--withdrawal-reference-tx-in-redeemer-value" "[]" \
  )
done

if [[ $unit == "ada" ]]; then
  # Change back to treasury
  args+=( "--tx-out" "$treasury_address+$leftover_treasury_lovelace+$acc_usdm $USDM_POLICY.$USDM_TOKEN" )
  # Actual disburse
  args+=( "--tx-out" "$beneficiary_address+$amount_lovelace" )
else
  tmp_pparams=$(mktemp)
  ccli latest query protocol-parameters > /tmp/pparams.json
  min_lovelace_utxo=$(cardano-cli latest transaction calculate-min-required-utxo --tx-out "$beneficiary_address+2000000+$amount_usdm $usdm_policy.$usdm_token" --protocol-params-file $tmp_pparams | cut -d ' ' -f2)
  # Change back to treasury
  args+=( "--tx-out" "$treasury_address+$acc_lovelace+$leftover_treasury_usdm $USDM_POLICY.$USDM_TOKEN" )
  # Actual disburse
  args+=( "--tx-out" "$beneficiary_address+$min_lovelace_utxo+$amount_usdm $USDM_POLICY.$USDM_TOKEN" )
fi

title ":: Validity Period"
slot=$(cardano-cli query tip $(network_id) | jq '.slot')
to_epoch_end=$(cardano-cli query tip $(network_id) | jq '.slotsToEpochEnd')
upper_bound=$(($slot + $to_epoch_end - 1))
if [ $(network_tag) == "preview" ]; then
  first_shelley_slot=0
  beginning_of_shelley=1666656000000
  if [ "$to_epoch_end" -lt "25920" ]; then
    upper_bound=$(($upper_bound + 86400 - 1))
  fi
else
  if [ $(network_tag) == "preprod" ]; then
    first_shelley_slot=86400
    beginning_of_shelley=1655769600000
  else
    first_shelley_slot=4492800
    beginning_of_shelley=1596059091000
  fi
  if [ "$to_epoch_end" -lt "129600" ]; then
    upper_bound=$(($upper_bound + 432000 - 1))
  fi
fi
upper_bound_posix=$(( $upper_bound * 1000 - $first_shelley_slot * 1000 + $beginning_of_shelley))

key_value $COL "current_time.slot" $slot
key_value $COL "valid_until.slot" $upper_bound
key_value $COL "valid_until.locale" "$(human_readable_timestamp $upper_bound_posix)"
echo ""

tmp=$(mktemp)

args+=( \
  "--change-address" "$wallet_address" \
  "--metadata-json-file" $tmp_metadata \
  "--invalid-hereafter" "$upper_bound" \
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
out=disburse-$scope-${tx_id:0:12}.cbor.json
jq '.type = "Tx ConwayEra"' $tmp > $out

title ":: Transaction"
key_value $COL "transaction.id" "$tx_id"
key_value $COL "transaction.file" "$out"
