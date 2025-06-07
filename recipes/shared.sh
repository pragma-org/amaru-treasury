# Copyright 2025 PRAGMA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Output some step in a formatted way.
#
# Usage: step [STRING] [STRING]
step () {
  TITLE=$(printf '%*s' 13 "$1")
  echo -e "\033[95;1m$TITLE\033[0m $2" >&2
}

# Like 'step', but doesn't put the title in bold.
sub_step () {
  TITLE=$(printf '%*s' 13 "$1")
  echo -e "\033[95m$TITLE\033[0m $2" >&2
}

# Prompt user to continue, or abort the execution.
ask_to_continue () {
    while true; do
        read -p "$*  [y/n]? " yn
        case $yn in
            [Yy]*) return 0;;
            [Nn]*)
	      echo "Aborting." >&2
	      exit 0
	      ;;
        esac
    done
}

# Get a value from a toml file.
#
# Usage: get_toml [FILENAME] [SECTION] [KEY]
get_toml() {
  get_section() {
    local file="$1"
    local section="$2"
      sed -n "/^\[$section\]/,/^\[/p" "$file" | sed '$d'
    }

    get_section "$1" "$2" | grep "^$3 " | sed 's/^.*=.*"\([^"]*\)".*$/\1/'
}

# Wrap some base16 payload into a Data Bytestring UPLC constant.
#
# Usage: to_bytestring_term [STRING]
to_bytestring_term () {
  echo "(con data (B #$1))"
}

# Wrap some integer into a Data Integer UPLC constant.
#
# Usage: to_integer_term [INT]
to_integer_term () {
  echo "(con data (I $1))"
}

# Export an aiken function into some temporary file for evaluation. Return the file.
#
# Usage: aiken_export [MODULE] [FN_IDENTIFIER]
aiken_export () {
  TMP=$(mktemp -d)
  aiken export --module $1 --name $2 2>/dev/null | jq -r .compiledCode > $TMP/$2.cbor
  echo $TMP/$2.cbor
}

# Eval the given exported Aiken function with the given arguments.
#
# Usage: eval_uplc [FILEPATH] [TERM]...
eval_uplc () {
  aiken uplc eval --cbor $1 "${@:2}" | jq -r .result | sed "1,2d" | cut -c4-
}

# Check whether the provided argument is non-empty, fails otherwise.
#
# Usage: fail_when_missing [STRING] [VAR]
fail_when_missing () {
  if [[ -z ${2:-} ]]; then
    echo -e "\033[91mMissing ENV var or argument '$1'\033[0m" >&2
    show_usage
    exit 1
  fi
}

# Parse an environment variable, and return the corresponding Aiken environment.
#
# Usage: network_to_env [NETWORK]
network_to_env () {
  case $1 in
    "mainnet")
      echo "default"
      echo -e "\033[91mConfiguration for mainnet not ready.\033[0m" >&2
      exit 1
    ;;

    "preview")
      echo "preview"
    ;;

    *)
      echo -e "\033[91munsupported network: use either \033[1m'preview'\033[0m\033[91m or \033[1m'mainnet'\033[0m" >&2
      exit 1
      ;;
  esac
}

# Parse a scope and return its corresponding CBOR Data constructor.
#
# Usage: scope_to_constr [SCOPE]
scope_to_constr () {
  case $1 in
    "ledger")
      echo "d87980"
      ;;
    "consensus")
      echo "d87a80"
      ;;
    "mercenaries")
      echo "d87b80"
      ;;
    "marketing")
      echo "d87c80"
      ;;
    *)
      echo -e "\033[91munsupported scope: must be one of 'ledger', 'consensus', 'mercenaries' or 'marketing'\033[0m" >&2
      exit 1
      ;;
  esac
}

# Return the size of a validator, in bytes.
#
# Usage: script_size [VALIDATOR]
script_size () {
  echo $(($(echo $1 | jq -r '.compiledCode' | wc -c)/2))
}
