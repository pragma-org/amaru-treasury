# Journal :: Contingency

## Preamble

| Maintainer(s)            | [Matthias Benkort][], [Arnaud Bailly][], [Pi Lanningham][], [Damien Czapla][] |
| :---                     | ---:                                                                          |
| Owner's credential       | `e425984e24fb2c06ad676882178ddee6e47b994a589ae3d70c817c79`[^1]                |
| Treasury's script hash   | `e425984e24fb2c06ad676882178ddee6e47b994a589ae3d70c817c79`                    |
| Treasury's stake address | [`stake178jztxzwynajcp4dva5gy9udmmnwg7ueffvf4c7hpjqhc7gtj5nzz`][]             |
| Treasury's address       | [`addr1x8jztxzwynajcp4d...3awryp03usyfpxhc`][]                                |
| Initial allocation       | ₳300,000                                                                      |

## Transactions

| ID           | [`6cedda690acc6cfaba32bc4632e827a8dcbbb97973b2e5fd5c3fda3491d43fe3`][] |
| :---         | ---:                                                                   |
| Type         | `initialize`                                                           |
| Delta amount | 0                                                                      |
| Agreement?   | N/A                                                                    |

Registering the treasury script as a stake credential, required to enable withdrawals from the treasury into it. The same transaction also publishes the treasury script in a UTxO which will be used later as a reference input to reduces the cost of future transactions.

---

| ID           | [`44ae2c263b2115023e4b137f718549fcac78c0a59b7983e918d9e79d1a503b3c`][] |
| :---         | ---:                                                                   |
| Type         | `publish`                                                              |
| Delta amount | 0                                                                      |
| Agreement?   | N/A                                                                    |

Publishing the initial registry datum identifying the treasury script. This is needed to avoid circular dependencies between on-chain validators. In particular, we define the original set of permissions for the contingency scope as follows:

- **reorganize**: 1 signature from either of:
  - `7095faf3d48d582fbae8b3f2e726670d7a35e2400c783d992bbdeffb` (ledger)
  - `790273b642e528f620648bf494a3db052bad270ce7ee873324d0cf3b` (consensus)
  - `97e0f6d6c86dbebf15cc8fdf0981f939b2f2b70928a46511edd49df2` (mercenaries)
  - `f3ab64b0f97dcf0f91232754603283df5d75a1201337432c04d23e2e` (marketing)
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
[Arnaud Bailly]: https://github.com/abailly
[Pi Lanningham]: https://github.com/Quantumplation
[Damien Czapla]: https://github.com/Dam-CZ

<!-- TODO: use explorer.cardano.org deeplink once it supports stake addresses -->
[`stake178jztxzwynajcp4dva5gy9udmmnwg7ueffvf4c7hpjqhc7gtj5nzz`]: https://cardanoscan.io/stakeKey/stake178jztxzwynajcp4dva5gy9udmmnwg7ueffvf4c7hpjqhc7gtj5nzz
[`addr1x8jztxzwynajcp4d...3awryp03usyfpxhc`]: https://explorer.cardano.org/address/addr1x8jztxzwynajcp4dva5gy9udmmnwg7ueffvf4c7hpjqhc70yykvyuf8m9sr26emgsgtcmhhxu3aejjjcnt3awryp03usyfpxhc

[`44ae2c263b2115023e4b137f718549fcac78c0a59b7983e918d9e79d1a503b3c`]: https://explorer.cardano.org/tx/44ae2c263b2115023e4b137f718549fcac78c0a59b7983e918d9e79d1a503b3c
[`6cedda690acc6cfaba32bc4632e827a8dcbbb97973b2e5fd5c3fda3491d43fe3`]: https://explorer.cardano.org/tx/6cedda690acc6cfaba32bc4632e827a8dcbbb97973b2e5fd5c3fda3491d43fe3

[^1]: The credential for the contingency treasury is a native script corresponding to a `anyOf` contructor of each scope owners credentials. It is only used to lock the reference script deployed during the `initialize` step; such that it can be destroyed once the expiration date is reached. Otherwise, operations on the treasury are authorized through the set of permissions defined in the treasury script, and highlighted in the `publish` step.
