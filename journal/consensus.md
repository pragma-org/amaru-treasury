# Journal :: Consensus

## Preamble

| Maintainer(s)            |                                                 [Arnaud Bailly][] |
| :----------------------- | ----------------------------------------------------------------: |
| Credential               |        `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` |
| Treasury's stake address | [`stake17xd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhccrqj9l`][] |
| Treasury's address       |                     [`addr1xxd74ehu0l4d5mx0...v87ue8d0sn774ak`][] |
| Initial allocation       |                                                          ₳300,000 |

## Delivered Milestones

### Pankzsoft contract

Contract: [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft-2025-09-14]

#### Milestone 2

Delivery of Consensus pipeline: Complete simulation testing to cover all stages and integrate with pure-stage framework

* [refactor: use a prefix range to iterate over parent/child relationships](https://github.com/pragma-org/amaru/pull/478)
* [fix: remove the use of column families in rocksdb](https://github.com/pragma-org/amaru/pull/473)
* [refactor: move forward chain to pure stage](https://github.com/pragma-org/amaru/pull/464)
* [feat: add a command to dump the state of the chain store](https://github.com/pragma-org/amaru/pull/459)
* [fix: remove the pure-stage dependency in amaru-ledger](https://github.com/pragma-org/amaru/pull/450)
* [refactor: use a chain store inside the headers tree](https://github.com/pragma-org/amaru/pull/444)
* [refactor: move store + validate block stages to pure stage](https://github.com/pragma-org/amaru/pull/440)
* [refactor: move the fetch block stage to pure-stage](https://github.com/pragma-org/amaru/pull/432)
* [refactor: remove an unnecessary type parameter for stage refs](https://github.com/pragma-org/amaru/pull/421)
* [refactor: document the simulation code](https://github.com/pragma-org/amaru/pull/418)

Invoice (redacted): [ipfs://bafybeiakblvgqiy66eucta467zr435dwarhw4p4rgsbiw7qx4u3t5qyvvi](ipfs://bafybeiakblvgqiy66eucta467zr435dwarhw4p4rgsbiw7qx4u3t5qyvvi)

#### Milestone 1

Delivery of Ouroboros Praos: Implement correct and efficient chain selection algorithm

* [refactor: store headers in a tree for chain selection](https://github.com/pragma-org/amaru/pull/372)
* [refactor: refactor the setting of arguments from env. variables in the simulation test](https://github.com/pragma-org/amaru/pull/414)
* [feat: reduce the processing time for chain selection and optimise rollbacks](https://github.com/pragma-org/amaru/pull/398)
* [docs: fix the description of a chain fragment](https://github.com/pragma-org/amaru/pull/362)
* [chore: add a make command to update the license header in source files](https://github.com/pragma-org/amaru/pull/356)

Invoice (redacted): [ipfs://bafybeigj3sqaxoegljdqgnl64jjpai35t5rfsbdea4havq6yynku4w6tzy](ipfs://bafybeigj3sqaxoegljdqgnl64jjpai35t5rfsbdea4havq6yynku4w6tzy)

## Transactions

| ID           | [`088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                       - 16,000.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft-2025-09-14] |
|              |                                                                        |

Disbursement of $16,000.00 in payment of invoice for completion of [Milestone 2](#milestone-2)


| ID           | [`79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                       - 15,590.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft-2025-09-14] |
|              |                                                                        |

Disbursement of $15,590.00 in payment of invoice for completion of [Milestone 1](#milestone-1)

| ID           | [`54861a6532a3f270fb754dcd0a45b73034289d98755fd25627e650df9572bd97`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                           - 10.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft-2025-09-14] |
|              |                                                                        |

Canary transaction to test disbursement in USDM process.

----

| ID           | [`429c5291c16430383e83d6057f2e4a40fbe152ee702e042ce728ef1cd24bb358 + others`][] |
|:-------------|--------------------------------------------------------------------------------:|
| Type         |                                                                             N/A |
| Delta amount |                                                 + ₳47.507211, + 141,258.93 USDM |
| Agreement?   |                                                                             N/A |

Execution of the previous 20 swaps, across multiple transactions at an average rate of 0.7062 USDM per ADA.

| ID           | [`d5c047bbdd387f7d0b8a69d04e37c6a567c44c5ae18524bc1de55eacd69c8068`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                               disburse |
| Delta amount |                                                             - ₳200,000 |
| Agreement?   |                                                                    N/A |

Disbursing funds into 20 separate swaps, each of 10k ADA for at least 7k USDM.

---

| ID           | [`90f2895219e1b39811ad23aa04beacc74a559cad488cf5b55ec559214422686b`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                                    N/A |
| Delta amount |                                                  - ₳1.28 ; +73.51 USDM |
| Agreement?   |                                                                    N/A |

Canary Swap order execution

---

| ID           | [`56b5f6c81668968bff810424df5d39daac1a736d1bede531778f408ac076fe7c`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                               disburse |
| Delta amount |                                                                 - ₳100 |
| Agreement?   |                                                                    N/A |

Canary transaction disbursing into 1 swap for at least 70USDM.

---

| ID           | [`acf08b7611ce385b9c776ad783b9d31666fa8f04a9f631d161537d52da6c7b62`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             initialize |
| Delta amount |                                                             + ₳300,000 |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 300,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`7068b2a950a02d43296679a2ca7f3f028504afc5a88f63e002ee09b733c533d9`][] |
|:-------------|-----------------------------------------------------------------------:|
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
[`54861a6532a3f270fb754dcd0a45b73034289d98755fd25627e650df9572bd97`]: https://explorer.cardano.org/tx/54861a6532a3f270fb754dcd0a45b73034289d98755fd25627e650df9572bd97
[Pankzsoft-2025-09-14]: [ipfs://bafybeia7jrqjmllqozpzfmx3k3div5rsh4mgr6vscl77eujopxo7qgh6na](ipfs://bafybeia7jrqjmllqozpzfmx3k3div5rsh4mgr6vscl77eujopxo7qgh6na)
[`79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f`]: https://explorer.cardano.org/tx/79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f
[`088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83`]: https://explorer.cardano.org/tx/088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83
