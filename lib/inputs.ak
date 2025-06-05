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
use aiken/crypto.{ScriptHash}
use cardano/address.{Credential}
use cardano/assets.{Value}
use cardano/transaction.{Input, Output, OutputReference}

/// Find all inputs locked by the given credential.
pub fn locked_by(inputs: List<Input>, credential: Credential) -> List<Input> {
  list.filter(
    inputs,
    fn(input) { input.output.address.payment_credential == credential },
  )
}

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

/// Traverse all inputs searching for script-locked UTxOs. Return the script
/// hash and the aggregated balance of assets locked by that script.
///
/// Fails if multiple UTxOs are locked by *different* script hash, or if
/// there's no script-locked UTxO whatsoever.
pub fn expect_single_script(
  inputs: List<Input>,
  return: fn(ScriptHash, Value) -> a,
) -> a {
  expect [Pair(script, balance)] =
    collect_script_inputs(inputs)
      |> dict.to_pairs

  return(script, balance)
}

/// Search inputs and collect all script hashes of script-locked payment
/// credentials. We use a dict to de-duplicate script hashes that are found
/// multiple times.
fn collect_script_inputs(inputs: List<Input>) -> Dict<ScriptHash, Value> {
  let next, scripts <- list.foldl(inputs, dict.empty)
  when next.output.address.payment_credential is {
    Credential.Script(script_hash) ->
      scripts
        |> dict.insert_with(
            script_hash,
            next.output.value,
            fn(_, left, right) { Some(assets.merge(left, right)) },
          )
    Credential.VerificationKey(..) -> scripts
  }
}
