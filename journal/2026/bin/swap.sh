#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/_prelude.sh"

COL=26

usage() {
  cat <<USAGE
Swap ADA for USDM using SundaeSwap order book.

Usage: swap.sh <WALLET_ADDRESS> <AMOUNT_USDM> <RATE> <SCOPE> <WITNESS_SCOPE>...
USAGE
}

[[ $# -ge 5 ]] || { usage; exit 1; }

title ":: Environment"
print_environment
echo "" >&2

title ":: Arguments"
wallet_address=$1
amount_usdm_display=$2
rate=$3
scope=$4
shift 4
witness_scopes=("$@")
amount_usdm=$((amount_usdm_display * 1000000))
amount_lovelace=$(awk "BEGIN {printf \"%.0f\", ($amount_usdm / $rate)}")
unit="ada"
echo "" >&2

title ":: Configuration"
metadata=$(load_metadata)
load_treasury_config $metadata $scope
load_permissions_config $metadata $scope
pparams=$(mktemp)
ccli query protocol-parameters > "$pparams"
swap_order_address=$(echo "31fa6a58bbe2d0ff05534431c8e2f0ef2cbdc1602a8456e4b13c8f3077$treasury_script_hash" | bech32 addr)
echo "" >&2

title ":: Signers"
build_signers "$metadata" "$scope" "${witness_scopes[@]}"
echo "" >&2

title ":: Fuel"
fuel=$(resolve_fuel "$wallet_address")
echo "" >&2

title ":: Selecting Treasury UTxOs"
select_treasury_utxos "$treasury_address" "$amount_lovelace" "$unit" true
echo "" >&2

title ":: Validity Period"
upper_bound=$(compute_validity_period)
echo "" >&2

title ":: cardano-cli latest transaction build"
CHUNK_SIZE=12500000000
full=$((amount_lovelace / CHUNK_SIZE))
rem=$((amount_lovelace % CHUNK_SIZE))
declare -a tx_outs
declare -a tx_outs_datums
add_swap_order () {
  local lovelace=$1
  swap_order_lovelace=$((lovelace + SUNDAE_PROTOCOL_FEE_LOVELACE + MIN_UTXO_DEPOSIT_LOVELACE))
  datum=$(swap_order "$lovelace" "$rate" "$metadata" "$treasury_script_hash")
  tx_outs+=("$swap_order_address+$swap_order_lovelace")
  tx_outs_datums+=("$datum")
}
if [[ $leftover_treasury_usdm -gt 0 ]]; then
  tx_outs+=("$treasury_address+$leftover_treasury_lovelace+$leftover_treasury_usdm $USDM_POLICY.$USDM_TOKEN")
else
  tx_outs+=("$treasury_address+$leftover_treasury_lovelace")
fi
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
write_conway_tx "$tx" "disburse"
