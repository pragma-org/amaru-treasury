#!/usr/bin/env bash
set -euo pipefail

labels="${LABELS:-}"

if [[ $# -lt 1 ]]; then
  echo "usage: og <tx.json> [labels.json]" >&2
  return 1
fi

if [[ $# -ge 2 ]]; then
  labels="$2"
fi

jq_args=()
if [[ -n "$labels" && -f "$labels" ]]; then
  jq_args=(--slurpfile labels "$labels")
else
  jq_args=(--argjson labels '[]')
fi

ogmios inspect transaction "$(jq -r .cborHex "$1")" \
  | jq "${jq_args[@]}" '
    def ixpad:
      if . < 10 then "0\(.)" else tostring end;

    def outref:
      "\(.transaction.id)#\(.index | ixpad)";

    def has_labels:
      ($labels | length) > 0;

    def label_root:
      if has_labels then $labels[0] else {} end;

    def from_metadatum:
      if type != "object" then
        .
      elif has("string") then
        .string
      elif has("int") then
        .int
      elif has("bytes") then
        .bytes
      elif has("list") then
        [.list[] | from_metadatum]
        | if all(.[]; type == "string") then
            join("")
          else
            .
          end
      elif has("map") then
        .map
        | map({
            key: (.k | from_metadatum | tostring),
            value: (.v | from_metadatum)
          })
        | from_entries
      else
        .
      end;

    def ada:
      if .ada.lovelace? then
        .ada = ("₳" + ((.ada.lovelace / 1000000) | tostring))
      else . end;

    def usdm:
      if .["c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad"]["0014df105553444d"]? then
        .usdm = ("$" + (
          .["c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad"]["0014df105553444d"]
          / 1000000
          | tostring
          ))
        | del(.["c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad"])
      else . end;

    def pretty_value:
      ada | usdm;

    def label_map:
      if has_labels then
        (
          label_root.treasuries
          | to_entries
          | reduce .[] as $t ({};
              .[$t.value.address] = ("treasury:" + $t.key)
              | if $t.value.owner != null then
                  .[$t.value.owner] = ("owner:" + $t.key)
                else . end
              | .[$t.value.treasury_script.hash] = ("treasury_script:" + $t.key)
              | .[$t.value.permissions_script.hash] = ("permissions_script:" + $t.key)
              | .[$t.value.registry_script.hash] = ("registry_script:" + $t.key)
              | .[$t.value.treasury_script.deployed_at] = ("deployed:treasury_script:" + $t.key)
              | .[$t.value.permissions_script.deployed_at] = ("deployed:permissions_script:" + $t.key)
              | .[$t.value.registry_script.deployed_at] = ("deployed:registry_script:" + $t.key)
            )
        )
        + {
          (label_root.scope_owners): "scope_owners",
          "addr1q8qrds2nnx7clx3kcpp2l0eu45twmdcahsfu9m0xcwy59j6xz3vs0hnfaz9nhje8z34kfnds4jyk7hs6dnrag6e2lfgqtyf4rl": "Crypto Accounting Group",
          "addr1qxpvfz0ptxgsmud84rkds37qmfyc673wz5tz6s4a893slyuwn8hpd0ycdvtlf0f9wx62xvavmv40qg7geuxequcrl9gs3spr33": "RKSW",
          "addr1qyf2nf64ahyx7amvpcytw20fre7zqqr2pwpdq2p7cl2g3evn36yuhgl049rxhhuckm2lpq3rmz5dcraddyl45d6xgvqqs5gp66": "KtorZ",
          "addr1qxu84ftxpzh3zd8p9awp2ytwzk5exj0fxcj7paur4kd4ytun36yuhgl049rxhhuckm2lpq3rmz5dcraddyl45d6xgvqqsp504c": "KtorZ",
          "addr1q8u9wlaatrm7hrp3z57jac5r3ha24qe9w0xax2jysxsvy762yxduv3dm849vlvh5jrefgcvl2ps0p5rsd6chf9vsxq7sm55htl": "Damien",
          "addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqaejyqwur6p8pqmycmzz55lcnan4x99mnt2a5fe54ggt4gxst7gy3n": "SundaeSwap (Order Contract)",
          "addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqa6lhvl999wzz8r4jhway0djuzsgxvf3up5pe3l2sq8ct56qlgdu8k": "SundaeSwap (Order Contract)",
          "addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqa6xw3kxg9guxue7dh53tptctpq694f5ytfwa98v2x3mhj6qcya6y6": "SundaeSwap (Order Contract)",
          "addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqalmgsvhk7fxyuw7jw78qrprmg6anhtrqapnvr8sk67acudq5up5n4": "SundaeSwap (Order Contract)",
          "addr1x8ax5k9mutg07p2ngscu3chsauktmstq92z9de938j8nqalxm0lsjfz7hzwy7kpl42jzswr7gtz8ruvxscm6sjrq9f8qkrg7f6": "SundaeSwap (Order Contract)"
        }
      else
        {}
      end;

    def replace_outref($m):
      (outref as $r
        | if has_labels then
    	($m[$r] // $r)
          else
    	$r
          end
      );

    def replace_address($m):
      if has_labels and $m[.address] then
        .address = $m[.address]
      else
        .
      end;

    label_map as $m
    | . as $tx

    | .inputs      |= map(replace_outref($m))
    | .references  |= map(replace_outref($m))
    | .collaterals |= map(replace_outref($m))

    | .outputs |= map(
        replace_address($m)
        | .value |= pretty_value
      )

    | if .collateralReturn? then
        .collateralReturn |= (
          replace_address($m)
          | .value |= pretty_value
        )
      else . end

    | if .fee? then
        .fee |= pretty_value
      else . end

    | if .totalCollateral? then
        .totalCollateral |= pretty_value
      else . end

    | if .withdrawals? then
        .withdrawals |= with_entries(.value |= pretty_value)
      else . end

    | if .metadata.labels? then
        .metadata.labels |= with_entries(
          if .value.json? then
            .value = (.value.json | from_metadatum)
          else
            .
          end
        )
      else . end

    | if has_labels then
        .requiredExtraSignatories |= map($m[.] // .)
      else . end

    | .redeemers |= map(
        if .validator.purpose == "spend" then
          ($tx.inputs[.validator.index] | outref) as $r
          | $m[$r] // $r
        elif .validator.purpose == "withdraw" then
          "withdraw"
        else
          .
        end
      )
  '
