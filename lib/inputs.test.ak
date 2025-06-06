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

use aiken/crypto.{ScriptHash, VerificationKeyHash, blake2b_256}
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/address
use cardano/fuzz as cardano
use cardano/transaction.{Input, Output, ScriptPurpose, Spend}
use inputs.{expect_single_script}

fn generate(seed: Int, fuzzer: Fuzzer<a>, map: fn(a) -> b) -> b {
  let prng = Seeded { seed: blake2b_256(bytearray.push("", seed)), choices: "" }
  expect Some((_, a)) = fuzzer(prng)
  map(a)
}

fn locked_by_script(script: ScriptHash) -> fn(Input) -> Input {
  fn(input) {
    Input {
      ..input,
      output: Output { ..input.output, address: address.from_script(script) },
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

fn spend(input: Input) -> fn(Data) -> Pair<ScriptPurpose, Data> {
  fn(redeemer) { Pair(Spend(input.output_reference), redeemer) }
}

test expect_single_script_trivial() {
  let input_1 = generate(1, cardano.input(), locked_by_script("foo"))

  let redeemer_1 = generate(1, fuzz.data(), spend(input_1))

  let script_hash, redeemer <- expect_single_script([input_1], [redeemer_1])

  and {
    script_hash == "foo",
    redeemer == redeemer_1.2nd,
  }
}

test expect_single_script_only_scripts() {
  let input_1 = generate(1, cardano.input(), locked_by_script("foo"))
  let input_2 = generate(2, cardano.input(), locked_by_script("foo"))
  let input_3 = generate(3, cardano.input(), locked_by_script("foo"))

  let redeemer_1 =
    generate(1, fuzz.data(), fn(r) { Pair(Spend(input_1.output_reference), r) })
  let redeemer_2 =
    generate(1, fuzz.data(), fn(r) { Pair(Spend(input_2.output_reference), r) })
  let redeemer_3 =
    generate(1, fuzz.data(), fn(r) { Pair(Spend(input_3.output_reference), r) })

  let
    script_hash,
    redeemer,
  <-
    expect_single_script(
      [input_1, input_2, input_3],
      [redeemer_1, redeemer_2, redeemer_3],
    )

  and {
    script_hash == "foo",
    redeemer == redeemer_1.2nd,
    redeemer == redeemer_2.2nd,
    redeemer == redeemer_3.2nd,
  }
}

test expect_single_script_mixed_scripts_and_keys() {
  let input_1 = generate(1, cardano.input(), locked_by_script("foo"))
  let input_2 = generate(2, cardano.input(), locked_by_key("foo"))
  let input_3 = generate(3, cardano.input(), locked_by_script("foo"))

  let redeemer_1 = generate(1, fuzz.data(), spend(input_3))
  let redeemer_3 = generate(1, fuzz.data(), spend(input_1))

  let
    script_hash,
    redeemer,
  <- expect_single_script([input_1, input_2, input_3], [redeemer_1, redeemer_3])

  and {
    script_hash == "foo",
    redeemer == redeemer_1.2nd,
    redeemer == redeemer_3.2nd,
  }
}

test expect_single_script_no_scripts() fail {
  let input_1 = generate(1, cardano.input(), locked_by_key("foo"))
  let input_2 = generate(2, cardano.input(), locked_by_key("bar"))
  let input_3 = generate(3, cardano.input(), locked_by_key("foo"))

  expect_single_script([input_1, input_2, input_3], [], fn(_, _) { True })
}

test expect_single_script_different_scripts() fail {
  let input_1 = generate(1, cardano.input(), locked_by_key("foo"))
  let input_2 = generate(2, cardano.input(), locked_by_key("bar"))
  let input_3 = generate(3, cardano.input(), locked_by_key("foo"))

  let redeemer_1 = generate(1, fuzz.data(), spend(input_1))
  let redeemer_2 = generate(1, fuzz.data(), spend(input_2))
  let redeemer_3 = generate(1, fuzz.data(), spend(input_3))

  expect_single_script(
    [input_1, input_2, input_3],
    [redeemer_1, redeemer_2, redeemer_3],
    fn(_, _) { True },
  )
}

test expect_single_script_different_redeemers() fail {
  let input_1 = generate(1, cardano.input(), locked_by_key("foo"))
  let input_2 = generate(2, cardano.input(), locked_by_key("foo"))

  let redeemer_1 = generate(1, fuzz.data(), spend(input_1))
  let redeemer_2 =
    generate(
      2,
      fuzz.data() |> fuzz.such_that(fn(data) { data != redeemer_1.2nd }),
      spend(input_2),
    )

  expect_single_script(
    [input_1, input_2],
    [redeemer_1, redeemer_2],
    fn(_, _) { True },
  )
}
