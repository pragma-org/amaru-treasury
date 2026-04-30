#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/../lib/_prelude.sh"

usage() {
  cat <<USAGE
Collect funds from a treasury stake address and send it to a treasury contract UTxO.

Usage: init.sh <WALLET_ADDRESS> <SCOPE>
USAGE
}

[[ $# -ge 2 ]] || { usage; exit 1; }

title ":: Environment"
print_environment
echo "" >&2

title ":: Arguments"
wallet_address=$1
scope=$2
key_value "$COL" "wallet.address" "$wallet_address"
key_value "$COL" "scope" "$scope"
echo "" >&2

title ":: Configuration"
metadata=$(load_metadata)
load_treasury_config $metadata $scope
load_permissions_config $metadata $scope
pparams=$(mktemp)
ccli query protocol-parameters > "$pparams"
echo "" >&2

title ":: Validity Period"
upper_bound=$(compute_validity_period)
echo "" >&2

title ":: Treasury's Balance"
treasury_lovelace=$(ccli_ query stake-address-info --address "$treasury_stake_address" | jq -cr '.[0].rewardAccountBalance')
key_value "$COL" "ada (before -> after)" "₳0 -> ₳$(awk "BEGIN {print ($treasury_lovelace / 1000000)}")"
echo "" >&2

title ":: cardano-cli latest transaction build"
auxiliary_data=$(treasury_instance_metadata "$registry_reference")
redeemer=$(mktemp)
jq --null-input "[]" > "$redeemer"
tx=$(mktemp)
args=(
  "latest" "transaction" "build"
  "--tx-in" "$fuel"
  "--tx-in-collateral" "$fuel"
  "--read-only-tx-in-reference" "$registry_reference"
  "--withdrawal" "$treasury_stake_address+$treasury_lovelace"
  "--withdrawal-tx-in-reference" "$treasury_reference"
  "--withdrawal-plutus-script-v3"
  "--withdrawal-reference-tx-in-redeemer-value" "[]"
  "--tx-out" "$treasury_address+$treasury_lovelace"
  "--change-address" "$wallet_address"
  "--metadata-json-file" "$auxiliary_data"
  "--invalid-hereafter" "$upper_bound"
  $(network_id)
  "--out-file" "$tx"
)
print_build_args "${args[@]}"
echo "" >&2

title ":: Transaction"
write_conway_tx "$tx" "disburse"
