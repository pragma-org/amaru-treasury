#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/_prelude.sh"

COL=26

usage() {
  cat <<USAGE
Swap ADA for USDM using SundaeSwap order book.

Usage: swap.sh <WALLET_ADDRESS> <AMOUNT> <RATE> <SCOPE> <WITNESS_SCOPE>...
USAGE
}

[[ $# -ge 5 ]] || { usage; exit 1; }

title ":: Environment"
print_environment
echo "" >&2

title ":: Arguments"
wallet_address=$1
amount_ada=$2
rate=$3
scope=$4
shift 4
witness_scopes=("$@")
amount_lovelace=$((amount_ada * 1000000))
amount_usdm_display=$(awk "BEGIN {print ($amount_ada * $rate)}")
amount_usdm=$(awk "BEGIN {print ($amount_usdm_display * 1000000)}")
echo "" >&2

title ":: Configuration"
metadata=$(load_metadata)
load_treasury_config $metadata $scope
load_permissions_config $metadata $scope
pparams=$(mktemp)
ccli query protocol-parameters > "$pparams"
swap_order_address=$(echo "31fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077$treasury_script_hash" | bech32 addr)
unit=ada
echo "" >&2

title ":: Signers"
build_signers "$metadata" "$scope" "${witness_scopes[@]}"
echo "" >&2

title ":: Fuel"
fuel=$(resolve_fuel "$wallet_address")
echo "" >&2

title ":: Selecting Treasury UTxOs"
select_treasury_utxos "$treasury_address" "$unit" true
leftover_treasury_lovelace=$((acc_lovelace - amount_lovelace))
leftover_treasury_usdm=$(awk "BEGIN {print ($acc_usdm + $amount_usdm)}")
echo "" >&2

title ":: cardano-cli latest transaction build"
CHUNK_SIZE=10000
full=$((amount_ada / CHUNK_SIZE))
rem=$((amount_ada % CHUNK_SIZE))
declare -a tx_outs
add_swap_order () {
  local amount=$1
  chunk_lovelace=$((amount * 1000000))
  swap_order_lovelace=$((chunk_lovelace + SUNDAE_PROTOCOL_FEE_LOVELACE + MIN_UTXO_DEPOSIT_LOVELACE))
  datum=$(swap_order "$chunk_lovelace" "$rate" "$metadata" "$treasury_script_hash")
  tx_outs+=("$swap_order_address+$swap_order_lovelace" "--tx-out-inline-datum-file" "$datum")
}
for ((i = 0; i < full; i++)); do
  add_swap_order "$CHUNK_SIZE"
done
if [[ $rem -gt 0 ]]; then
  add_swap_order "$rem"
fi
redeemer=$(make_redeemer_disburse "$unit")
tx=$(build_transaction)
echo "" >&2

title ":: Transaction"
write_conway_tx "disburse"
