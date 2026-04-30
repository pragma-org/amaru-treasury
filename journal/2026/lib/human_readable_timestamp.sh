human_readable_timestamp() {
  if [ "$(uname)" = "Darwin" ]; then
    date -r $(($1 / 1000))
  else
    date -d "@$(($1 / 1000))"
  fi
}
