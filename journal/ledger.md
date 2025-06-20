# Journal :: Ledger

## Preamble

| Maintainer(s)            | [Matthias Benkort][]                                              |
| :---                     | ---:                                                              |
| Credential               | `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb`        |
| Treasury's stake address | [`stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g`][] |
| Treasury's address       | [`addr1xxnev6rc25xwz8kg...qsvmz0ur8sjjwfw8`][]                    |
| Initial allocation       | ₳300,000                                                          |

## Transactions

| ID           | [`ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe`][] |
| :---         | ---:                                                                   |
| Type         | `initialize`                                                           |
| Delta amount | 0                                                                      |
| Agreement?   | N/A                                                                    |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7`][] |
| :---         | ---:                                                                   |
| Type         | `publish`                                                              |
| Delta amount | 0                                                                      |
| Agreement?   | N/A                                                                    |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the ledger scope as follows:

- **reorganize**: 1 signature from:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
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

[Matthias Benkort]: https://github.com/KtorZ

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->
[`stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g`]: https://cardanoscan.io/stakeKey/stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g
[`addr1xxnev6rc25xwz8kg...qsvmz0ur8sjjwfw8`]: https://explorer.cardano.org/address/addr1xxnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pna8je58s4gvuy0v32pmj07p5msst42y77zfgsqsvmz0ur8sjjwfw8

[`cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7`]: https://explorer.cardano.org/tx/cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7
[`ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe`]: https://explorer.cardano.org/tx/ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe
