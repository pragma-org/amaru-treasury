build_transaction() {
  local args=("latest" "transaction" "build" "--tx-in" "$fuel" "--tx-in-collateral" "$fuel")

  # Spent treasury inputs
  local i
  for i in "${!txins[@]}"; do
    args+=(
      "--tx-in" "${txins[$i]}"
      "--spending-tx-in-reference" "$treasury_reference"
      "--spending-plutus-script-v3"
      "--spending-reference-tx-in-redeemer-file" "$redeemer"
    )
  done

  # Permissions & reference inputs
  args+=(
    "--read-only-tx-in-reference" "$registry_reference"
    "--read-only-tx-in-reference" "$scopes_reference"
    "--withdrawal" "$permissions_stake_address+0"
    "--withdrawal-tx-in-reference" "$permissions_reference"
    "--withdrawal-plutus-script-v3"
    "--withdrawal-reference-tx-in-redeemer-value" "[]"
  )

  # Outputs
  for i in "${!tx_outs[@]}"; do
    args+=("--tx-out" "${tx_outs[i]}")

    if [[ -n "${tx_outs_datums[i]+_}" ]]; then
      args+=("--tx-out-inline-datum-file" "${tx_outs_datums[i]}")
    fi
  done

  # Signers
  for signer in "${signers[@]}"; do args+=("--required-signer-hash" "$signer"); done

  # Auxiliary data & closing
  local auxiliary_data=$(treasury_instance_metadata "$registry_reference")
  out=$(mktemp)
  args+=( \
    "--change-address" "$wallet_address" \
    "--metadata-json-file" "$auxiliary_data" \
    "--invalid-hereafter" "$upper_bound" \
    $(network_id) \
    "--out-file" "$out" \
  )

  print_build_args "${args[@]}"

  cli_out=$(cardano-cli "${args[@]}")
  if [[ $? != 0 ]]; then
    echo "$cli_out" >&2
    exit 1
  fi

  echo $out
}
