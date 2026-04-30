human_si() {
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=si "$1"
  elif command -v gnumfmt >/dev/null 2>&1; then
    gnumfmt --to=si "$1"
  else
    awk -v n="$1" '
      function human(x) {
        s=" k M G T P E"
        split(s, u)
        i=0
        while (x >= 1000 && i < length(u)-1) { x /= 1000; i++ }
        return sprintf("%.1f%s", x, u[i+1])
      }
      BEGIN { print human(n) }
    '
  fi
}
