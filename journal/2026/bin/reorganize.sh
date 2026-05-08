#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/_prelude.sh"

usage() {
  cat <<USAGE
Reorganize (i.e. merge) UTxOs for a given scope.

Usage: reorganize.sh <WALLET_ADDRESS> <AMOUNT> <UNIT> <SCOPE>
USAGE
}

[[ $# -ge 4 ]] || { usage; exit 1; }

title ":: Environment"
print_environment
echo "" >&2

title ":: Arguments"
wallet_address=$1
amount=$2
unit=$3
scope=$4
parse_amount "$amount" "$unit"
key_value "$COL" "wallet.address" "$wallet_address"
key_value "$COL" "amount.$unit" "$amount"
key_value "$COL" "scope" "$scope"
echo ""

title ":: Configuration"
metadata=$(load_metadata)
load_treasury_config $metadata $scope
load_permissions_config $metadata $scope
pparams=$(mktemp)
ccli query protocol-parameters > "$pparams"
echo "" >&2

title ":: Signers"
build_signers $metadata $scope
echo "" >&2

title ":: Fuel"
fuel=$(resolve_fuel "$wallet_address")
echo "" >&2

title ":: Selecting Treasury UTxOs"
select_treasury_utxos "$treasury_address" "$amount_lovelace" "$unit" false
echo "" >&2

title ":: Validity Period"
upper_bound=$(compute_validity_period)
echo "" >&2

title ":: cardano-cli latest transaction build"
declare -a tx_outs
if [[ $acc_usdm -gt 0 ]]; then
  tx_outs+=("$treasury_address+$acc_lovelace+$acc_usdm $USDM_POLICY.$USDM_TOKEN")
else
  tx_outs+=("$treasury_address+$acc_lovelace")
fi
redeemer=$(make_redeemer_reorganize)
tx=$(build_transaction)
echo "" >&2

title ":: Sanity Check on Execution Units"
assert_execution_units $tx $pparams
echo "" >&2

title ":: Transaction"
write_conway_tx "$tx" "disburse"
