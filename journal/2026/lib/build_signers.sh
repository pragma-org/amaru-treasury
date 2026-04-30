build_signers() {
  local metadata="$1"
  local scope="$2"
  shift 2
  local witness key owner

  signers=()
  owner=$(echo "$metadata" | jq -cr ".treasuries.${scope}.owner")

  if [[ "$scope" != "contingency" ]]; then
    key_value "$COL" "* $scope.key" "$owner"
    signers+=( "$owner" )
  fi

  if [[ -n "$@" ]]; then
    for witness in "$@"; do
      if [[ "$witness" = "contingency" ]]; then
        usage
        exit 1
      fi
      key=$(echo "$metadata" | jq -cr ".treasuries.${witness}.owner")
      key_value "$COL" "+ $witness.key" "$key"
      signers+=( "$key" )
    done
  fi
}
