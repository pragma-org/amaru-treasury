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

// A collection of utilities over addresses.

use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential, Referenced}

/// Create an `Address` from a `ScriptHash`, using the script for both payment
/// credential and stake credential.
pub fn from_script(script: ScriptHash) -> Address {
  Address {
    payment_credential: Credential.Script(script),
    stake_credential: Some(Referenced.Inline(Credential.Script(script))),
  }
}
