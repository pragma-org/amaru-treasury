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

use aiken/crypto.{ScriptHash}
use cardano/address.{Address, Credential, StakeCredential}
use cardano/assets.{AssetName, PolicyId, ada_asset_name, ada_policy_id}
use cardano/transaction.{Datum, InlineDatum}
use config
use sundae/multisig.{MultisigScript}

/// An order to execute within the SundaeSwap ecosystem
pub type OrderDatum {
  /// An optional pool identifier against which this order must be executed
  /// If set to none, the order is allowed to execute against any pool with the
  /// correct assets.
  pool_ident: Option<ByteArray>,
  /// An canonical "owner" of this order, with the possibility of multisig
  /// schemes and script restrictions. Allows updates or cancellations of the order
  owner: MultisigScript,
  /// The maximum amount of Lovelace that can be taken as a protocol fee.
  max_protocol_fee: Int,
  /// Where the output of executing an order should be sent
  destination: Destination,
  /// A description of how to actually execute the order
  details: Order,
  /// Arbitrary extension data. Unused.
  extension: Data,
}

/// The destination where funds are to be sent after the order
///
/// NOTE: The actual 'Destination' type for Sundae has more variants after Fixed, but we don't care about them.
pub type Destination {
  Fixed {
    /// The address to attach to the output.
    address: Address,
    /// The datum to attach to the output;
    datum: Datum,
  }
}

/// The specific order details for executing an order.
///
/// NOTE: The actual 'Order' type for Sundae has more variants after Swap, but we don't care about them.
pub type Order {
  /// Do not use.
  Unused
  /// A swap from one token to another, offering some subset of the UTXO, in return for at least some quantity of another token
  Swap {
    offer: (PolicyId, AssetName, Int),
    min_received: (PolicyId, AssetName, Int),
  }
}

/// Construct the address where to send the order. It may carry a stake credential.
pub fn order_address(stake_credential: Option<StakeCredential>) -> Address {
  Address {
    payment_credential: Credential.Script(config.sundae_order_contract),
    stake_credential,
  }
}

/// Extract an order from an inline datum, and fails otherwise.
pub fn expect_order_datum(datum: Datum) -> OrderDatum {
  expect InlineDatum(data) = datum
  expect order: OrderDatum = data
  order
}

/// Create an order to swap ADA for USDM, managed by a script but targetting the treasury.
pub fn ada_to_usdm(
  owner: ScriptHash,
  treasury: Address,
  ada: Int,
  usdm: Int,
) -> OrderDatum {
  expect ada > 0
  expect usdm > 0

  // `min_microusdm_per_ada` corresponds to the exchange rate from Lovelace to
  // μUSDM (like ADA, USDM also has 6 decimals).
  //
  // This ensures one cannot swap the treasury for less than an agreed upon
  // threshold.
  expect usdm * 1_000_000 >= ada * config.min_microusdm_per_ada

  OrderDatum {
    pool_ident: None,
    owner: multisig.Script(owner),
    max_protocol_fee: config.sundae_protocol_fee,
    destination: Fixed { address: treasury, datum: Datum.NoDatum },
    details: Swap {
      offer: (ada_policy_id, ada_asset_name, ada * 1_000_000),
      min_received: (
        config.usdm_policy_id,
        config.usdm_asset_name,
        usdm * 1_000_000,
      ),
    },
    extension: Void,
  }
}
