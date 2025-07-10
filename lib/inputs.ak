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

// A collection of utilities over transaction inputs.

use aiken/collection/dict.{Dict}
use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash}
use cardano/address.{Credential}
use cardano/transaction.{Input, Output, OutputReference, ScriptPurpose}

/// Find the output corresponding to an output reference in a list of input.
///
/// Fails when no matching output is found.
pub fn resolve(inputs: List<Input>, utxo_ref: OutputReference) -> Output {
  when inputs is {
    [] -> fail
    [head, ..tail] ->
      if head.output_reference == utxo_ref {
        head.output
      } else {
        resolve(tail, utxo_ref)
      }
  }
}

/// Traverse all inputs searching for script-locked UTxOs. Return the
/// associated redeemer.
///
/// Fails if:
/// - there's no script-locked UTxO whatsoever;
/// - multiple UTxOs are locked by *different* script hash;
/// - not all redeemers for these scripts are equal to one another.
pub fn expect_single_script(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Data>,
) -> Data {
  expect [Pair(_, redeemer)] =
    collect_script_inputs(inputs, redeemers)
      |> dict.to_pairs

  redeemer
}

/// Search inputs and collect all script hashes of script-locked payment
/// credentials. We use a dict to de-duplicate script hashes that are found
/// multiple times.
fn collect_script_inputs(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Data>,
) -> Dict<ScriptHash, Data> {
  let next, scripts <- list.foldl(inputs, dict.empty)
  when next.output.address.payment_credential is {
    Credential.Script(script_hash) -> {
      expect Some(redeemer) =
        pairs.get_first(redeemers, ScriptPurpose.Spend(next.output_reference))

      scripts
        |> dict.insert_with(
            script_hash,
            redeemer,
            fn(_, left, right) {
              expect left == right
              Some(left)
            },
          )
    }
    Credential.VerificationKey(..) -> scripts
  }
}
