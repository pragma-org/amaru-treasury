parse_amount() {
  local amount="$1"
  local unit="$2"

  if [[ "$unit" = "ada" ]]; then
    amount_lovelace=$(( amount * 1000000 ))
    amount_usdm=0
  elif [[ "$unit" = "usdm" ]]; then
    amount_lovelace=0
    amount_usdm=$(( amount * 1000000 ))
  else
    echo "unrecognized unit; expected either 'ada' or 'usdm'" >&2
    exit 1
  fi
}
