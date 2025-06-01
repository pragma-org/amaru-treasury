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

use cardano/address
use sundae.{ada_to_usdm}

// ----------------------------------------------------------------- ada_to_usdm

const ada_to_usdm_ = ada_to_usdm("", address.from_verification_key(""), _, _)

test ada_to_usdm_negative_1() fail {
  expect _ = ada_to_usdm_(10, -1)
}

test ada_to_usdm_negative_2() fail {
  expect _ = ada_to_usdm_(-1, 10)
}

test ada_to_usdm_low() fail {
  expect _ = ada_to_usdm_(10, 4)
}

test ada_to_usdm_equal() {
  expect _ = ada_to_usdm_(10, 5)
}

test ada_to_usdm_high() {
  expect _ = ada_to_usdm_(10, 20)
}
