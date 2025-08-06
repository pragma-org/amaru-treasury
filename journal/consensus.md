# Journal :: Consensus

## Preamble

| Maintainer(s)            |                                                 [Arnaud Bailly][] |
| :----------------------- | ----------------------------------------------------------------: |
| Credential               |        `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` |
| Treasury's stake address | [`stake17xd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhccrqj9l`][] |
| Treasury's address       |                     [`addr1xxd74ehu0l4d5mx0...v87ue8d0sn774ak`][] |
| Initial allocation       |                                                          ₳300,000 |

## Transactions

| ID           | [`429c5291c16430383e83d6057f2e4a40fbe152ee702e042ce728ef1cd24bb358 + others`][] |
|:-------------|--------------------------------------------------------------------------------:|
| Type         |                                                                             N/A |
| Delta amount |                                              + 47.507211 ADA, + 141,258.93 USDM |
| Agreement?   |                                                                             N/A |

Execution of the previous 20 swaps, across multiple transactions at an average rate of 0.7062 USDM per ADA.

| ID           | [`d5c047bbdd387f7d0b8a69d04e37c6a567c44c5ae18524bc1de55eacd69c8068`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                               disburse |
| Delta amount |                                                           -200,000 ADA |
| Agreement?   |                                                                    N/A |

Disbursing funds into 20 separate swaps, each of 10k ADA for at least 7k USDM.

---

| ID           | [`90f2895219e1b39811ad23aa04beacc74a559cad488cf5b55ec559214422686b`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                                    N/A |
| Delta amount |                                                -1.28 ADA ; +73.51 USDM |
| Agreement?   |                                                                    N/A |

Canary Swap order execution

---

| ID           | [`56b5f6c81668968bff810424df5d39daac1a736d1bede531778f408ac076fe7c`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                               disburse |
| Delta amount |                                                               -100 ADA |
| Agreement?   |                                                                    N/A |

Canary transaction disbursing into 1 swap for at least 70USDM.

---

| ID           | [`acf08b7611ce385b9c776ad783b9d31666fa8f04a9f631d161537d52da6c7b62`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             initialize |
| Delta amount |                                                           +300,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 300,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`7068b2a950a02d43296679a2ca7f3f028504afc5a88f63e002ee09b733c533d9`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`e5be93f2530c51e0b1582e5a0e99ccb1235e4395a41c7196d06c4daea3eafe66`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                              `publish` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the consensus scope as follows:

- **reorganize**: 1 signature from:
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
- **disburse**: 3 signatures out of:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
- **sweep**: 3 signatures out of:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
- **fund**: disabled.

[Arnaud Bailly]: https://github.com/abailly

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhccrqj9l`]: https://cardanoscan.io/stakeKey/stake17xd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhccrqj9l
[`addr1xxd74ehu0l4d5mx0...v87ue8d0sn774ak`]: https://explorer.cardano.org/address/addr1xxd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhumatn0cll2mfkvlqj92j678fyca2c4ypdvjfyv87ue8d0sn774ak
[`acf08b7611ce385b9c776ad783b9d31666fa8f04a9f631d161537d52da6c7b62`]: https://explorer.cardano.org/tx/acf08b7611ce385b9c776ad783b9d31666fa8f04a9f631d161537d52da6c7b62
[`e5be93f2530c51e0b1582e5a0e99ccb1235e4395a41c7196d06c4daea3eafe66`]: https://explorer.cardano.org/tx/e5be93f2530c51e0b1582e5a0e99ccb1235e4395a41c7196d06c4daea3eafe66
[`7068b2a950a02d43296679a2ca7f3f028504afc5a88f63e002ee09b733c533d9`]: https://explorer.cardano.org/tx/7068b2a950a02d43296679a2ca7f3f028504afc5a88f63e002ee09b733c533d9
[`56b5f6c81668968bff810424df5d39daac1a736d1bede531778f408ac076fe7c`]: https://explorer.cardano.org/tx/56b5f6c81668968bff810424df5d39daac1a736d1bede531778f408ac076fe7c
[`90f2895219e1b39811ad23aa04beacc74a559cad488cf5b55ec559214422686b`]: https://explorer.cardano.org/tx/90f2895219e1b39811ad23aa04beacc74a559cad488cf5b55ec559214422686b
[`d5c047bbdd387f7d0b8a69d04e37c6a567c44c5ae18524bc1de55eacd69c8068`]: https://explorer.cardano.org/tx/d5c047bbdd387f7d0b8a69d04e37c6a567c44c5ae18524bc1de55eacd69c8068
[`429c5291c16430383e83d6057f2e4a40fbe152ee702e042ce728ef1cd24bb358`]: https://explorer.cardano.org/tx/429c5291c16430383e83d6057f2e4a40fbe152ee702e042ce728ef1cd24bb358
