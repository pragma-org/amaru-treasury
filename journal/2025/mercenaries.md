# Journal :: Mercenaries

## Preamble

| Maintainer(s)            | [Pi Lanningham][]                                                                                            |
| :----------------------- | ----------------------------------------------------------------:                                            |
| Owner's credential       | `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2`                                                   |
| Treasury's script hash   | `877f57e0bdcc8167e984dee052d8dd7346effc08ff80a29b045e1a10`                                                   |
| Treasury's stake address | [`stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8`][]                                            |
| Treasury's address       | [`addr1xxrh74lqhhxgzelf...3fkpz7rggqpymr9r`][]<br/>[`mercenaries@amaru`](https://pool.pm/$mercenaries@amaru) |
| Initial allocation       | ₳500,000                                                                                                     |
| Current balance          | ₳400,047 <br/> $47,761                                                                                       |

## Delivered Milestones

#### [Amaru Doctor][AmaruDoctor_2025_09_12]

##### [Milestone 1](https://ipfs.io/ipfs/QmZyqiVXY7oHNx5gJPdj7DBmzde3Vrapg8QouzSP2tidbE)

<details><summary>Node diversity workshop environment + storage traits analysis.</summary>

* [wip: adding otel read capabilities](https://github.com/jeluard/amaru-doctor/pull/52)
* [wip: update amaru dep; organize scroll](https://github.com/jeluard/amaru-doctor/pull/53)
* [wip: add DynamicList and OtelViewState for OTEL view models](https://github.com/jeluard/amaru-doctor/pull/54)
* [wip: add update fns for TraceGraph updating](https://github.com/jeluard/amaru-doctor/pull/55)
* [wip: add otel-based views](https://github.com/jeluard/amaru-doctor/pull/56)
* [feat: add pool render; pause emacs keybindings](https://github.com/jeluard/amaru-doctor/pull/57)
* [feat: add prometheus metrics reading](https://github.com/jeluard/amaru-doctor/pull/58)
</details>

#### [Haskell & Pallas CBOR Decoding][HaskellPallas_2025_10_20]

#### [Milestone 1](https://ipfs.io/ipfs/QmZ1gmXGesosFiwDTF597Qgc5o2QSZGAW5TsHqCnHUZUoH)

<details><summary>Analysis of the gaps between Haskell & Pallas CBOR codecs</summary>

* [Initial analysis](https://github.com/rrruko/pallas-primitives-codec-notes/commit/22ee6a23232ff8495eadc06d11066952ff3f3d0f)
* [Conway cost models](https://github.com/rrruko/pallas-primitives-codec-notes/commit/dc3cf273daee17ac8298cc4414600c8e8f202315)
* [Babbage notes](https://github.com/rrruko/pallas-primitives-codec-notes/commit/d8da20347729133f2f3a02be252d789b34954f80)
* [WIP Alonzo](https://github.com/rrruko/pallas-primitives-codec-notes/commit/75fe38d81ce0dde3b7cc0e7aaa40e15649f7a983)
</details>

## Transactions

| ID           | [`197b673435395a88fb8287cb5ac8ab23b2ea9721d63411208efd029f11aea93e + 18 others`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                    +46.324018 ADA, +80,240.643956 USDM |
| Agreement?   |                                                                    N/A |

Execution of the previous 20 swaps, across multiple transactions at an average rate of 0.8024 USDM per ADA.

---

| ID           | [`3cf9f4f352cf918f1ae7255a8fbb3b61c7d68236e4f56d810d9dad7f11f211f4`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                               disburse |
| Delta amount |                                                           -100,000 ADA |
| Agreement?   |                                                                    N/A |

Disbursing funds into 20 separate swaps, each of 5k ADA for at least 4k USDM. This split minimizes slippage, while securing 32% of the budget in a stable fiat backed stablecoin.

---

| ID           | [`dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             initialize |
| Delta amount |                                                           +500,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 500,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                              `publish` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the mercenaries scope as follows:

- **reorganize**: 1 signature from:
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
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

[Pi Lanningham]: https://github.com/Quantumplation

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8`]: https://cardanoscan.io/stakeKey/stake17xrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yqhgk7k8
[`addr1xxrh74lqhhxgzelf...3fkpz7rggqpymr9r`]: https://explorer.cardano.org/address/addr1xxrh74lqhhxgzelfsn0wq5kcm4e5dmluprlcpg5mq30p5yy80at7p0wvs9n7npx7upfd3htngmhlcz8lsz3fkpz7rggqpymr9r
[`197b673435395a88fb8287cb5ac8ab23b2ea9721d63411208efd029f11aea93e + 18 others`]: https://explorer.cardano.org/tx/197b673435395a88fb8287cb5ac8ab23b2ea9721d63411208efd029f11aea93e
[`3cf9f4f352cf918f1ae7255a8fbb3b61c7d68236e4f56d810d9dad7f11f211f4`]: https://explorer.cardano.org/tx/3cf9f4f352cf918f1ae7255a8fbb3b61c7d68236e4f56d810d9dad7f11f211f4
[`dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266`]: https://explorer.cardano.org/tx/dc67e79626a265ce808f1a7ca5fcfa5bdb0d7fb635691fc5bd82917930d8f266
[`0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c`]: https://explorer.cardano.org/tx/0729a234e4e12b945f06189ca479681e49ffcc116fb3713720bada72180fe27c
[`b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857`]: https://explorer.cardano.org/tx/b6aaa5bdfec89b0c52c338842971b12f525625dcfc7e899b4c8ebb15f8a45857
[AmaruDoctor_2025_09_12]: https://ipfs.io/ipfs/QmQyaSb1hfyzEgSkNuDeNudiXn8uMSMbgTNUMkWEc4eMVc
[HaskellPallas_2025_10_20]: https://ipfs.io/ipfs/Qme5Nob2xDR5MVZqypNcMa9RfQBDp1UYQ1YGJREKXhRwhy
