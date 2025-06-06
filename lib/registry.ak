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

use aiken/cbor
use aiken/crypto.{ScriptHash}
use aiken/primitive/bytearray
use cardano/address.{Credential}
use cardano/assets.{PolicyId}
use cardano/transaction.{Datum}
use sundae/multisig
use types.{ScriptHashRegistry, TreasuryConfiguration, TreasuryPermissions}

pub fn export_registry(treasury: ScriptHash) {
  expect bytearray.length(treasury) == 28
  cbor.serialise(
    ScriptHashRegistry {
      treasury: Credential.Script(treasury),
      vendor: Credential.Script(
        #"00000000000000000000000000000000000000000000000000000000",
      ),
    },
  )
}

pub fn export_treasury_configuration(
  registry_token: PolicyId,
  scope_owner: ScriptHash,
  expiration: Int,
) -> ByteArray {
  expect bytearray.length(registry_token) == 28
  expect bytearray.length(scope_owner) == 28
  cbor.serialise(
    TreasuryConfiguration {
      registry_token,
      permissions: TreasuryPermissions {
        reorganize: multisig.Script(scope_owner),
        sweep: multisig.Script(scope_owner),
        fund: multisig.AnyOf([]),
        disburse: multisig.Script(scope_owner),
      },
      expiration,
      payout_upperbound: 0,
    },
  )
}

/// Assert (or fail) that a given datum is inline and has an expected shape.
pub fn with_inline_registry(
  datum: Datum,
  return: fn(ScriptHashRegistry) -> result,
) -> result {
  expect Datum.InlineDatum(data) = datum
  expect registry: ScriptHashRegistry = data
  return(registry)
}
