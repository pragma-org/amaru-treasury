# Journal :: Consensus

## Preamble

| Maintainer(s)            | [Arnaud Bailly][]                                                 |
| :----------------------- | ----------------------------------------------------------------: |
| Owner's credential       | `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b`        |
| Treasury's script hash   | `9beae6fc7feada6ccf824554b5e3a498eab15205ac9248c3fb993b5f`        |
| Treasury's stake address | [`stake17xd74ehu0l4d5mx0sfz4fd0r5jvw4v2jqkkfyjxrlwvnkhccrqj9l`][] |
| Treasury's address       | [`addr1xxd74ehu0l4d5mx0...v87ue8d0sn774ak`][]                     |
| Initial allocation       | ₳300,000                                                          |
| Current balance          | ₳99,951 <br/> $109,259                                            |

## Delivered Milestones

#### [Implementing P2P networking for Amaru including dynamic peer selection][RKSW_2025_10_01]

##### [Milestone 3 & 4](http://ipfs.io/ipfs/QmYkv27UuCU2CqShWuDVQPQLAGrrLtBsmTkSvHhwvW7Lct)

<details><summary>Rewrite network stack using pure-stage.</summary>

> [!NOTICE]
> This work significantly departs from the pre-defined milestones in the initial contract with the provider.
> The Amaru Maintainers Committee acknowledges this state of affair which is due to the inadequacy of the original envisioned networking stack for Amaru specific purposes, in particular related to the integration in the existing architecture, peer-to-peer management, responder (eg. server). This lead to the need to a complete rewrite of the networking logic which is what is currently being worked on.

* [reimplement muxer using pure-stage](https://github.com/pragma-org/amaru/pull/584) _In progress_

</summary>

##### [Milestone 2](https://ipfs.io/ipfs/bafybeiale2rvfcgjzsomotmnh43mq6ll2xsvrjxswb6lp6ochqpouecqea)

<details><summary>Implement the initiator side to enhance the pull stage with the above networking improvement and offer a principled integration in the pure-stage consensus implementation.</summary>

* [add short-circuit facilities for pure-stage](https://github.com/pragma-org/amaru/pull/526)
* [make upstream connections dynamic](https://github.com/pragma-org/amaru/pull/513)
* [signal pure-stage termination to simulation](https://github.com/pragma-org/amaru/pull/486)
* [add muxer to amaru-network](https://github.com/pragma-org/amaru/pull/471)
</details>

##### [Milestone 1](https://ipfs.io/ipfs/bafybeiale2rvfcgjzsomotmnh43mq6ll2xsvrjxswb6lp6ochqpouecqea)

<details><summary>Enhance the downstream server with a spec-compliant multiplexer implementation that will also support initiator mode later.</summary>

* [rk/better external effect](https://github.com/pragma-org/amaru/pull/441)
* [chore: make RawBlock cheaply cloneable](https://github.com/pragma-org/amaru/pull/438)
* [small improvement to implementation of pure-stage](https://github.com/pragma-org/amaru/pull/425)
* [reinstate tracing spans for stages](https://github.com/pragma-org/amaru/pull/412)
* [move most stages to pure_stage](https://github.com/pragma-org/amaru/pull/392)
* [pure-stage error handling](https://github.com/pragma-org/amaru/pull/384)
* [document how to run gh actions locally](https://github.com/pragma-org/amaru/pull/381)
* [add EDR on Time in Amaru](https://github.com/pragma-org/amaru/pull/376)
* [improve EDR012](https://github.com/pragma-org/amaru/pull/373)
* [Create EDR 012-interaction-between-consensus-and-ledger.md](https://github.com/pragma-org/amaru/pull/369)
* [persistent state vs. pure_stage](https://github.com/pragma-org/amaru/pull/366)
* [move validate_header to pure_stage](https://github.com/pragma-org/amaru/pull/365)
</details>

#### [Consensus and simulation development][Pankzsoft_2025_09_14]

##### [Milestone 2](https://ipfs.io/ipfs/bafybeiakblvgqiy66eucta467zr435dwarhw4p4rgsbiw7qx4u3t5qyvvi)


<details><summary>Delivery of Consensus pipeline. Complete simulation testing to cover all stages and integrate with pure-stage framework.</summary>

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
</details>

##### [Milestone 1](https://ipfs.io/ipfs/bafybeigj3sqaxoegljdqgnl64jjpai35t5rfsbdea4havq6yynku4w6tzy)

<details><summary>Delivery of Ouroboros Praos. Implement correct and efficient chain selection algorithm.</summary>

* [refactor: store headers in a tree for chain selection](https://github.com/pragma-org/amaru/pull/372)
* [refactor: refactor the setting of arguments from env. variables in the simulation test](https://github.com/pragma-org/amaru/pull/414)
* [feat: reduce the processing time for chain selection and optimise rollbacks](https://github.com/pragma-org/amaru/pull/398)
* [docs: fix the description of a chain fragment](https://github.com/pragma-org/amaru/pull/362)
* [chore: add a make command to update the license header in source files](https://github.com/pragma-org/amaru/pull/356)
</details>

#### [Consensus scope: Consensus and simulation environment development][Sundae_2025_10_01]

##### [Milestone 2]()

<details><summary>Integrate mempool and block forging into consensus.</summary>

* [ci: use smaller simulation parameters on a push to main](https://github.com/pragma-org/amaru/pull/580)
* [test: run the nightly simulation test once a day with larger defaults](https://github.com/pragma-org/amaru/pull/575)
* [ci: add a nightly job to run the simulation](https://github.com/pragma-org/amaru/pull/570)
* [feat: update the visualization of traces now that runnables are not produced anymore](https://github.com/pragma-org/amaru/pull/569)
* [fix: fix a chain selection bug found via the simulator](https://github.com/pragma-org/amaru/pull/568)
* [ci: persist failed data on test coverage](https://github.com/pragma-org/amaru/pull/564)
* [test: put back the random stage execution](https://github.com/pragma-org/amaru/pull/561)
* [docs: update the simulator readme](https://github.com/pragma-org/amaru/pull/544)
* [feat: replay trace entries](https://github.com/pragma-org/amaru/pull/541)
* [fix: start a trace from the pull stage](https://github.com/pragma-org/amaru/pull/540)
* [fix: fix the chain selection algorithm to avoid sending irrelevant forks](https://github.com/pragma-org/amaru/pull/538)
* [feat: better interleavings simulation](https://github.com/pragma-org/amaru/pull/536)

</details>

##### [Milestone 1](https://ipfs.io/ipfs/QmSHnmfJWRsnPYLa1U1NdgwunkGR2YVAXN6ts9a3HFopga)

<details><summary>Network Integration: Integrate new P2P network driver and adapt stages and simulation framework.</summary>

* [test: make the select_chain tests more robust](https://github.com/pragma-org/amaru/pull/530)
* [feat: generate better arrival times / slots for the simulation](https://github.com/pragma-org/amaru/pull/521)
* [test: display statistics for the generation of data for the simulation](https://github.com/pragma-org/amaru/pull/517)
* [feat: check that a received header has the correct point](https://github.com/pragma-org/amaru/pull/511)
* [test: improve the data generation for the consensus simulation](https://github.com/pragma-org/amaru/pull/510)
* [refactor: use HeaderHash where possible](https://github.com/pragma-org/amaru/pull/508)
* [refactor: remove an unused chain store effect](https://github.com/pragma-org/amaru/pull/507)
* [feat: make a full effect for validating headers](https://github.com/pragma-org/amaru/pull/503)
* [docs: update the consensus diagram](https://github.com/pragma-org/amaru/pull/502)
* [feat: memoized header hash](https://github.com/pragma-org/amaru/pull/501)
* [refactor: remove store_header and store_block as separate stages](https://github.com/pragma-org/amaru/pull/500)
* [feat: move the select_chain stage to the end of the stage graph](https://github.com/pragma-org/amaru/pull/498)
* [test: introduce a separate config for the simulated nodes](https://github.com/pragma-org/amaru/pull/493)
* [refactor: move validate_header effects to pure-stage](https://github.com/pragma-org/amaru/pull/489)
* [feat: more encapsulated effects](https://github.com/pragma-org/amaru/pull/488)
* [feat: signal pure-stage termination to simulation](https://github.com/pragma-org/amaru/pull/487)

</details>

## Transactions

| ID           | [`dccff813154febe90874e251a61a1d05d6872327d93847dade5dda694d30f374`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                          - 44,000.00 ₳ |
| Agreement?   |                       [AMC-RKSW Agreement 2025-10-01][RKSW_2025_10_01] |

Disbursement of ₳44,000.00 in payment of invoice for work in progress on _Milestones 3 & 4_

---

| ID           | [`ec61841159e0067a2cc9db4ff87d1e7ca76f1fd205d45927183a384a667fd270`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                          - 44,000.00 ₳ |
| Agreement?   |                       [AMC-RKSW Agreement 2025-10-01][RKSW_2025_10_01] |

Disbursement of ₳44,000.00 in payment of invoice for completion of _Milestones 1 & 2_

---

| ID           | [`088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                       - 16,000.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft_2025_09_14] |
|              |                                                                        |

Disbursement of $16,000.00 in payment of invoice for completion of [Milestone 2](#milestone-2)

---

| ID           | [`79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                       - 15,590.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft_2025_09_14] |
|              |                                                                        |

Disbursement of $15,590.00 in payment of invoice for completion of [Milestone 1](#milestone-1)

---

| ID           | [`54861a6532a3f270fb754dcd0a45b73034289d98755fd25627e650df9572bd97`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                             `disburse` |
| Delta amount |                                                           - 10.00 USDM |
| Agreement?   |             [AMC-Pankzsoft Agreement 2025-09-14][Pankzsoft_2025_09_14] |
|              |                                                                        |

Canary transaction to test disbursement in USDM process.

---

| ID           | [`429c5291c16430383e83d6057f2e4a40fbe152ee702e042ce728ef1cd24bb358 + others`][] |
|:-------------|--------------------------------------------------------------------------------:|
| Type         |                                                                             N/A |
| Delta amount |                                                 + ₳47.507211, + 141,258.93 USDM |
| Agreement?   |                                                                             N/A |

Execution of the previous 20 swaps, across multiple transactions at an average rate of 0.7062 USDM per ADA.

---

| ID           | [`d5c047bbdd387f7d0b8a69d04e37c6a567c44c5ae18524bc1de55eacd69c8068`][] |
|:-------------|-----------------------------------------------------------------------:|
| Type         |                                                               disburse |
| Delta amount |                                                             - ₳200,000 |
| Agreement?   |                                                                    N/A |

Disbursing funds into 20 separate swaps, each of 10k ADA for at least 7k USDM.

---

| ID             | [`90f2895219e1b39811ad23aa04beacc74a559cad488cf5b55ec559214422686b`][]   |
| :------------- | -----------------------------------------------------------------------: |
| Type           | N/A                                                                      |
| Delta amount   | - ₳1.28, +73.51 USDM                                                     |
| Agreement?     | N/A                                                                      |

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

---

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
[Pankzsoft_2025_09_14]: https://ipfs.io/ipfs/bafybeia7jrqjmllqozpzfmx3k3div5rsh4mgr6vscl77eujopxo7qgh6na
[`79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f`]: https://explorer.cardano.org/tx/79dd616f50dae7cc94ca633912bc96e8ea6de7d205d3e232ec494368c9bd453f
[`088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83`]: https://explorer.cardano.org/tx/088c80ad8620e480de51e49c2e6c6a0d504d47e30f2255e545a2d532494cec83
[RKSW_2025_10_01]: https://ipfs.io/ipfs/bafybeib56kic322ncfg5jkwwp2nxhisbm7uk7ansitf4qqyik5zuhw34ga
[`ec61841159e0067a2cc9db4ff87d1e7ca76f1fd205d45927183a384a667fd270`]: https://explorer.cardano.org/tx/ec61841159e0067a2cc9db4ff87d1e7ca76f1fd205d45927183a384a667fd270
[`dccff813154febe90874e251a61a1d05d6872327d93847dade5dda694d30f374`]: https://explorer.cardano.org/tx/dccff813154febe90874e251a61a1d05d6872327d93847dade5dda694d30f374
[Sundae_2025_10_01]: https://ipfs.io/ipfs/bafybeifembdl6i5pzhzwui2v4kzp6gmv4re4hvpbbnhmpabkzdfywo5vfm
