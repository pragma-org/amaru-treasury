compute_validity_period() {
  slot=$(ccli query tip | jq '.slot')
  to_epoch_end=$(ccli query tip | jq '.slotsToEpochEnd')
  upper_bound=$((slot + to_epoch_end - 1))

  if [ "$(network_tag)" = "preview" ]; then
    first_shelley_slot=0
    beginning_of_shelley=1666656000000
    if [ "$to_epoch_end" -lt "25920" ]; then
      upper_bound=$((upper_bound + 86400 - 1))
    fi
  else
    if [ "$(network_tag)" = "preprod" ]; then
      first_shelley_slot=86400
      beginning_of_shelley=1655769600000
    else
      first_shelley_slot=4492800
      beginning_of_shelley=1596059091000
    fi
    if [ "$to_epoch_end" -lt "129600" ]; then
      upper_bound=$((upper_bound + 432000 - 1))
    fi
  fi

  upper_bound_posix=$(( upper_bound * 1000 - first_shelley_slot * 1000 + beginning_of_shelley ))

  key_value "$COL" "current_time.slot" "$slot"
  key_value "$COL" "valid_until.slot" "$upper_bound"
  key_value "$COL" "valid_until.locale" "$(human_readable_timestamp "$upper_bound_posix")"

  echo "$upper_bound"
}
