is_blacklisted() {
  local needle="$1"
  local item

  for item in "${BLACKLIST[@]}"; do
    [[ "$item" = "$needle" ]] && return 0
  done

  return 1
}
