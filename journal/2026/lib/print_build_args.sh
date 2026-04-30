print_build_args() {
  local argv=("$@")
  local i=3 arg val
  while (( i < ${#argv[@]} )); do
    arg="${argv[i]}"
    val="${argv[i+1]:-}"

    if [[ -z "$val" || "$val" =~ ^-- ]]; then
      key_value 45 "$arg" "true"
      ((i+=1))
    else
      key_value 45 "$arg" "$val"
      ((i+=2))
    fi
  done
}
