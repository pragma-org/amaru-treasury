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

// A collection of utilities over transaction outputs.

use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName}
use cardano/transaction.{Output}

/// Find the output (if any), that forward an NFT from an original
/// script-locked input.
///
/// Fails if there's no forwarding output.
pub fn forwarding_nft(
  destination: ScriptHash,
  asset_name: AssetName,
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
      let has_token =
        fn() { assets.quantity_of(head.value, destination, asset_name) == 1 }
      if to_script && has_token() {
        // We need not to check for the tail here because the token is guaranteed to be unique.
        // Thus, it cannot be found in more than one output. We can stop at the first one.
        head
      } else {
        forwarding_nft(destination, asset_name, tail)
      }
    }
  }
}
