key_value() {
  local col="$1"
  local key="$2:"
  local value="${3:-}"
  printf "%s%-*s %s\n" "  " "$col" "$key" "$value" >&2
}
