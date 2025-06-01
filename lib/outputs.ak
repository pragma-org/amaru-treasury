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

use aiken/collection/list
use cardano/address.{Address}
use cardano/assets.{Value}
use cardano/transaction.{Output}

/// Sum up all assets on the outputs held at an address using a selection
/// function. The selection function may crash the program if it meets
/// unnacceptable conditions.
pub fn total_at(outputs: List<Output>, zero: Value, at: Address) -> Value {
  outputs
    |> list.reduce(
        zero,
        fn(total, output) {
          if output.address == at {
            assets.merge(total, output.value)
          } else {
            total
          }
        },
      )
}
