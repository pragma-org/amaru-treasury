# Journal :: Ledger

## Preamble

| Maintainer(s)            | [Matthias Benkort][]                                                                               |
| :---------------         | ----------------------------------------------------------------------:                            |
| Owner's credential       | `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb`                                         |
| Treasury's script hash   | `a7966878550ce11ec8a83b93fc1a6e105d544f78494401066c4fe0cf`                                         |
| Treasury's stake address | [`stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g`][]                                  |
| Treasury's address       | [`addr1xxnev6rc25xwz8kg...qsvmz0ur8sjjwfw8`][]<br/>[`ledger@amaru`](https://pool.pm/$ledger@amaru) |
| Initial allocation       | ₳300,000                                                                                           |
| Current balance          | ₳168,757<br/>$85,041                                                                               |

## Transactions

| ID           | [`073145f5f5764735dab401e360a83a7e13ad6c1df87b742b91bc678c67d21941`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         | `disburse`                                                             |
| Delta amount | -16,000 USDM                                                           |
| Agreement?   | [Plutus Virtual Machine development][agreement_plutus_virtual_machine] |

Disbursement of 16,000 USDM from the ledger treasury in payment of invoice Sundae Labs CON-36, for the completion of Milestone 1 as per Remunerated Contributor Agreement for _Plutus Virtual Machine V3 implementation & testing_.

---


| ID           | [`4619d0e401e15dcd2a5afa03e8bf5b73a8ff600b1ef41c71c819f82ad7d1be5f`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                          +1 ledger@amaru, +1.28007 ADA |
| Agreement?   |                                                                    N/A |

Minting a sub-handle NFT to facilitate tracking of the ledger treasury by external parties.

---

| ID           | [`93542fcf82bac42a38dff030976851130bb5db7f8e79e6c87784b3488930c946`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                        +25,780.315769 USDM, +2.306 ADA |
| Agreement?   |                                                                    N/A |

Result of the previous swap being credited back to the account alongside a deposit amount that was sent with the order to account for the minimum ada value on UTxO.

---

| ID           | [`f6eeb12a16c518d89f59e275268330e7ea39571feedef13dbf866ffb7a33c8ed`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             `disburse` |
| Delta amount |                                                            -31,000 ADA |
| Agreement?   |                                                                    N/A |

Securing another chunk of the budget to USDM, while the price of ADA is reasonably high for the period.

The final destination for the swap is the (ledger) treasury itself.

---

| ID           | [`77de6d15a3a7f0e173e2ae3a95e78fd3f830ff1de7e925bf752970de3f0ca082`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                        +75,252.447141 USDM, +2.408 ADA |
| Agreement?   |                                                                    N/A |

Result of the previous swap being credited back to the account alongside a deposit amount that was sent with the order to account for the minimum ada value on UTxO.

---

| ID           | [`415e986796f63dacb18cb75dcfa299fbbe0910c44b6a10efbd153fcc322177f9`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             `disburse` |
| Delta amount |                                                           -100,250 ADA |
| Agreement?   |                                                                    N/A |

Securing half of the budget to USDM, while the price of ADA is reasonably high for the period.

We cannot get a hold of the entire budget in USDM, because there's simply not enough liquidity on Cardano at the moment. But, the budget was planned with a rate of $0.5 per ADA; so we can currently secure more USDM with less ADA, which de-risk the devaluation of the budget due to price fluctuations. The swap order is parameterized with an owner script which enforces the same permissions as the 'disburse' operation (3 out of 4 signatures).

The final destination for the swap is the (ledger) treasury itself.

---

| ID           | [`a6fa866a87f15301d0fef1f0d4729a3ededc717b0059b05ba51ce43dc8009f1d`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                           +300,000 ADA |
| Agreement?   |                                                                    N/A |

Withdrawal from the reward account of 300,000 ADA received by the treasury withdrawal governance action, and locked at the treasury smart contract.

---

| ID           | [`8f1fc137efac1923f414dbc6dff29fd07b92b873018b8ea66d33ef16de3d0d12`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                          +8.410131 USDM, +2.000000 ADA |
| Agreement?   |                                                                    N/A |

Result of the previous swap being credited back to the account alongside a deposit amount that was sent with the order to account for the minimum ada value on UTxO.

---

| ID           | [`848adba4c45372e388bdf96d585d85cd056ea7819c8a810810b47551b39024d3`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                             `disburse` |
| Delta amount |                                                         -14.000000 ADA |
| Agreement?   |                                                                    N/A |

Experimenting with a swap from ADA to USDM using a decentralized order book (SundaeSwap). The funds spent in this context were sent to the script address from an external source. This transaction is only meant to test the final setup in real conditions. The swap order is parameterized with an owner script which enforces the same permissions as the 'disburse' operation (3 out of 4 signatures). The destination for the swap is the treasury itself.

---

| ID           | [`1da3917f4ceb275781773250137d240d09c9038f2c7682c18dcfc033445d74f4`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                                    N/A |
| Delta amount |                                                         +14.000000 ADA |
| Agreement?   |                                                                    N/A |

Sending some funds from an external account into the treasury account to try out the smart contract in real conditions prior to any real treasury withdrawal.

---

| ID           | [`ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                           `initialize` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7`][] |
| :----------- | ---------------------------------------------------------------------: |
| Type         |                                                              `publish` |
| Delta amount |                                                                      0 |
| Agreement?   |                                                                    N/A |

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

---

[Matthias Benkort]: https://github.com/KtorZ

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->

[`stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g`]: https://cardanoscan.io/stakeKey/stake17xnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pncv8fq8g
[`addr1xxnev6rc25xwz8kg...qsvmz0ur8sjjwfw8`]: https://explorer.cardano.org/address/addr1xxnev6rc25xwz8kg4qae8lq6dcg964z00py5gqgxd387pna8je58s4gvuy0v32pmj07p5msst42y77zfgsqsvmz0ur8sjjwfw8

[agreement_plutus_virtual_machine]: https://ipfs.io/ipfs/bafybeigqfdrxwc4msfct5xnlswwvp4voxq27z7wt57pbwpbovih45pacyi

[`4619d0e401e15dcd2a5afa03e8bf5b73a8ff600b1ef41c71c819f82ad7d1be5f`]: https://explorer.cardano.org/tx/4619d0e401e15dcd2a5afa03e8bf5b73a8ff600b1ef41c71c819f82ad7d1be5f
[`93542fcf82bac42a38dff030976851130bb5db7f8e79e6c87784b3488930c946`]: https://explorer.cardano.org/tx/93542fcf82bac42a38dff030976851130bb5db7f8e79e6c87784b3488930c946
[`f6eeb12a16c518d89f59e275268330e7ea39571feedef13dbf866ffb7a33c8ed`]: https://explorer.cardano.org/tx/f6eeb12a16c518d89f59e275268330e7ea39571feedef13dbf866ffb7a33c8ed
[`77de6d15a3a7f0e173e2ae3a95e78fd3f830ff1de7e925bf752970de3f0ca082`]: https://explorer.cardano.org/tx/77de6d15a3a7f0e173e2ae3a95e78fd3f830ff1de7e925bf752970de3f0ca082
[`415e986796f63dacb18cb75dcfa299fbbe0910c44b6a10efbd153fcc322177f9`]: https://explorer.cardano.org/tx/415e986796f63dacb18cb75dcfa299fbbe0910c44b6a10efbd153fcc322177f9
[`a6fa866a87f15301d0fef1f0d4729a3ededc717b0059b05ba51ce43dc8009f1d`]: https://explorer.cardano.org/tx/a6fa866a87f15301d0fef1f0d4729a3ededc717b0059b05ba51ce43dc8009f1d
[`8f1fc137efac1923f414dbc6dff29fd07b92b873018b8ea66d33ef16de3d0d12`]: https://explorer.cardano.org/tx/8f1fc137efac1923f414dbc6dff29fd07b92b873018b8ea66d33ef16de3d0d12
[`1da3917f4ceb275781773250137d240d09c9038f2c7682c18dcfc033445d74f4`]: https://explorer.cardano.org/tx/1da3917f4ceb275781773250137d240d09c9038f2c7682c18dcfc033445d74f4
[`848adba4c45372e388bdf96d585d85cd056ea7819c8a810810b47551b39024d3`]: https://explorer.cardano.org/tx/848adba4c45372e388bdf96d585d85cd056ea7819c8a810810b47551b39024d3
[`cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7`]: https://explorer.cardano.org/tx/cd25ce7b027fea4e28d5075691aa5822baa859bc74cc79db0377043bc9f383c7
[`ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe`]: https://explorer.cardano.org/tx/ec641b987f10cc6d7751c63a3ae383e5b09007833446424959376c1c0f67a4fe
[`073145f5f5764735dab401e360a83a7e13ad6c1df87b742b91bc678c67d21941`]: https://explorer.cardano.org/tx/073145f5f5764735dab401e360a83a7e13ad6c1df87b742b91bc678c67d21941
