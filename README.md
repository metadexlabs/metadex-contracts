# MetaDex Overview

A repo for all the MetaDex's smart contracts. Every functionality's code resides in its own folder.

The protocol's ERC20 token: [METADEX](./token/README.md)

## Learn more
- Website: ``
- Discord: ``
- Twitter: ``


## Feature list

| Name                                                                  | Description                                                                                       |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------|
| [Token](./token)                                                      | The ERC20 METADEX token smart contract                                                            |
| [Vesting](./vesting/)                                                 | MetaDex's vesting implementation                                                                  |
| [Lottery](./lottery/)                                                 | The lottery implementation using Chainlink's VRF                                                  |

## Cloning an existing feature
Refer to the specific feature's README.

## Creating a new feature
1. Create a new folder from the root directory.
2. Run `npm init`. Any other package manager like Yarn's `yarn init` can be used. If running npm, note that npm 7 or later is recommended because it makes installing Hardhat plugins simpler.