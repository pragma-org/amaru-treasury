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

// A collection of utilities over values

use cardano/assets.{Value}
use config

/// Create a value holding a given quantity (possibly negative) of USDM (6 decimals)
pub fn from_usdm(quantity: Int) -> Value {
  assets.from_asset(
    config.usdm_policy_id,
    config.usdm_asset_name,
    quantity * 1_000_000,
  )
}

/// Create a value holding a given quantity (possibly negative) of ADA (6 decimals)
pub fn from_ada(quantity: Int) -> Value {
  assets.from_lovelace(quantity * 1_000_000)
}

/// Returns True if both values have exactly the same assets (though may differ on their lovelace value).
pub fn match_assets(left: Value, right: Value) {
  assets.match(left, right, fn(_, _) { True })
}
