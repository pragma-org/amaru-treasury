//// Copyright 2025 PRAGMA
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
////     http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.

use aiken/collection/list.{for_each}
use aiken/crypto.{ScriptHash, VerificationKeyHash, blake2b_256}
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/address.{Address}
use cardano/assets.{Value, from_lovelace}
use cardano/fuzz as cardano
use cardano/transaction.{Input, Output}
use inputs.{expect_single_script}

fn generate(seed: Int, fuzzer: Fuzzer<a>, map: fn(a) -> b) -> b {
  let prng = Seeded { seed: blake2b_256(bytearray.push("", seed)), choices: "" }
  expect Some((_, a)) = fuzzer(prng)
  map(a)
}

test prop_locked_by(inputs via fuzz.list(cardano.input())) {
  let input <- for_each(inputs)
  let locked = inputs.locked_by(inputs, input.output.address.payment_credential)
  expect and {
      list.length(locked) >= 1,
      list.all(locked, list.has(inputs, _)),
    }
}

fn locked_by_script(script: ScriptHash, value: Value) -> fn(Input) -> Input {
  fn(input) {
    Input {
      ..input,
      output: Output {
        ..input.output,
        address: address.from_script(script),
        value: value,
      },
    }
  }
}

fn locked_by_key(key: VerificationKeyHash) -> fn(Input) -> Input {
  fn(input) {
    Input {
      ..input,
      output: Output {
        ..input.output,
        address: address.from_verification_key(key),
      },
    }
  }
}

test expect_single_script_trivial() {
  let
    script_hash,
    balance,
  <-
    expect_single_script(
      [generate(1, cardano.input(), locked_by_script("foo", from_lovelace(42)))],
    )

  and {
    script_hash == "foo",
    balance == assets.from_lovelace(42),
  }
}

test expect_single_script_ada_only() {
  let
    script_hash,
    balance,
  <-
    expect_single_script(
      [
        generate(1, cardano.input(), locked_by_script("foo", from_lovelace(42))),
        generate(2, cardano.input(), locked_by_key("")),
        generate(3, cardano.input(), locked_by_script("foo", from_lovelace(14))),
      ],
    )

  and {
    script_hash == "foo",
    balance == assets.from_lovelace(56),
  }
}

test expect_single_script_with_assets() {
  let
    script_hash,
    balance,
  <-
    expect_single_script(
      [
        generate(1, cardano.input(), locked_by_key("")),
        generate(
          2,
          cardano.input(),
          locked_by_script("foo", from_lovelace(42) |> assets.add("bar", "", 1)),
        ),
        generate(3, cardano.input(), locked_by_script("foo", from_lovelace(14))),
      ],
    )

  and {
    script_hash == "foo",
    balance == assets.from_asset_list(
      [Pair("", [Pair("", 56)]), Pair("bar", [Pair("", 1)])],
    ),
  }
}

test expect_single_script_multiple_scripts() fail {
  expect_single_script(
    [
      generate(1, cardano.input(), locked_by_script("foo", from_lovelace(14))),
      generate(2, cardano.input(), locked_by_script("bar", from_lovelace(14))),
    ],
    fn(_, _) { True },
  )
}

test expect_single_script_no_scripts() fail {
  expect_single_script(
    [
      generate(1, cardano.input(), locked_by_key("foo")),
      generate(2, cardano.input(), locked_by_key("bar")),
    ],
    fn(_, _) { True },
  )
}
