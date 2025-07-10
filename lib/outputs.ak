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

use aiken/collection/dict
// A collection of utilities over transaction outputs.

use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName, Value}
use cardano/transaction.{Output}

/// Find the output (if any), that forward an NFT from an original
/// script-locked input.
///
/// Fails if there's no forwarding output.
pub fn forwarding_nft(
  destination: ScriptHash,
  expected_asset_name: AssetName,
  outputs: List<Output>,
) -> Output {
  when outputs is {
    [] -> {
      trace @"missing forwarding output": destination
      fail
    }
    [head, ..tail] -> {
      let to_script =
        head.address.payment_credential == Credential.Script(destination)
      if to_script && expect_nft(head.value, destination, expected_asset_name) {
        // We need not to check for the tail here because the token is guaranteed to be unique.
        // Thus, it cannot be found in more than one output. We can stop at the first one.
        head
      } else {
        forwarding_nft(destination, expected_asset_name, tail)
      }
    }
  }
}

/// Expect a given NFT at the value, allowing (and expecting) some ada but /
/// nothing else. This prevents administrator to inadvertently send undesired
/// tokens to smart-contract controlled outputs.
pub fn expect_nft(
  value: Value,
  expected_policy: ScriptHash,
  expected_asset_name: AssetName,
) -> Bool {
  let pairs = value |> assets.to_dict |> dict.to_pairs
  expect [_ada, Pair(policy, assets)] = pairs
  expect [Pair(asset_name, quantity)] = assets |> dict.to_pairs
  and {
    (policy == expected_policy)?,
    (asset_name == expected_asset_name)?,
    (quantity == 1)?,
  }
}
