assert_execution_units() {
  local tx_file="$1"
  local pparams="$2"
  local tx_inspect max_mem max_cpu redeemer_count used_mem used_cpu

  # Guard: skip if ogmios not available
  if ! command -v ogmios >/dev/null 2>&1; then
    echo "warning: ogmios not found in PATH; skipping execution units check" >&2
    return 0
  fi

  tx_inspect=$(mktemp)
  ogmios inspect transaction "$(jq -r .cborHex "$tx_file")" > "$tx_inspect"

  max_mem=$(jq -r '.maxTxExecutionUnits.memory' "$pparams")
  max_cpu=$(jq -r '.maxTxExecutionUnits.steps' "$pparams")

  redeemer_count=$(jq '.redeemers | length' "$tx_inspect")
  used_mem=$(jq '[.redeemers[].executionUnits.memory] | add // 0' "$tx_inspect")
  used_cpu=$(jq '[.redeemers[].executionUnits.cpu] | add // 0' "$tx_inspect")

  key_value "$COL" "redeemers" "$redeemer_count"
  key_value "$COL" "mem.total" "used=$(human_si "$used_mem") / max=$(human_si "$max_mem")"
  key_value "$COL" "cpu.total" "used=$(human_si "$used_cpu") / max=$(human_si "$max_cpu")"

  if (( redeemer_count == 0 )); then
    echo "error: could not find any redeemer execution units in built transaction" >&2
    exit 1
  fi

  if (( used_mem > max_mem )); then
    echo "error: transaction memory execution units exceed protocol maximum: $(human_si "$used_mem") > $(human_si "$max_mem")" >&2
    exit 1
  fi

  if (( used_cpu > max_cpu )); then
    echo "error: transaction CPU execution units exceed protocol maximum: $(human_si "$used_cpu") > $(human_si "$max_cpu")" >&2
    exit 1
  fi
}
