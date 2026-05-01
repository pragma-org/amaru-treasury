select_treasury_utxos() {
  local treasury_address="$1"
  local target="$2"
  local unit="$3"
  local sort_by_lovelace_desc="${4:-false}"
  local tmp_utxos utxo_filter txin usdm lovelace

  tmp_utxos=$(mktemp)
  if [[ "$unit" = "ada" ]]; then
    utxo_filter="to_entries"
  else
    utxo_filter="to_entries | map(select(.value.value.${USDM_POLICY}[\"${USDM_TOKEN}\"]))"
  fi
  if [[ "$sort_by_lovelace_desc" = "true" ]]; then
    utxo_filter="$utxo_filter | sort_by(.value.value.lovelace) | reverse"
  fi
  utxo_filter="$utxo_filter | .[] | [.key,.value.value.${USDM_POLICY}[\"${USDM_TOKEN}\"],.value.value.lovelace] | @csv"

  $(ccli query utxo --address "$treasury_address" --output-json | jq -rc "$utxo_filter" | tr -d '"' > "$tmp_utxos")

  acc_usdm=0
  acc_lovelace=0
  txins=()

  while IFS=, read -r txin usdm lovelace; do
    if is_blacklisted "$txin"; then
      continue
    fi

    [[ -n "$usdm" ]] && acc_usdm=$(( acc_usdm + usdm ))
    acc_lovelace=$(( acc_lovelace + lovelace ))

    txins+=( "$txin" )

    if [[ "$unit" = "ada" ]]; then
      [[ "$acc_lovelace" -ge "$target" ]] && break
    else
      [[ "$acc_usdm" -ge "$target" ]] && break
    fi
  done < "$tmp_utxos"

  if [[ "$unit" = "ada" ]]; then
    leftover_treasury_lovelace=$((acc_lovelace - target))
    leftover_treasury_usdm=$acc_usdm
  else
    leftover_treasury_lovelace=$acc_lovelace
    leftover_treasury_usdm=$((acc_usdm - target))
  fi

  if [[ $leftover_treasury_usdm -lt 0 ]]; then
    echo "error: not enough USDM to cover request; missing \$$(( -1 * leftover_treasury_usdm / 1000000 ))"
    exit 1
  fi

  if [[ $leftover_treasury_lovelace -lt 0 ]]; then
    echo "error: not enough ADA to cover request; missing ₳$(( -1 * leftover_treasury_lovelace / 1000000 ))"
    exit 1
  fi

  key_value "$COL" "ada (before -> after)" "$((acc_lovelace / 1000000)) -> $((leftover_treasury_lovelace / 1000000))"
  key_value "$COL" "usdm (before -> after)" "$((acc_usdm / 1000000)) -> $((leftover_treasury_usdm / 1000000))"
}
