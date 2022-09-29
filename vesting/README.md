# MetaDex Vesting
This directory contains the smart contracts for MetaDex's vesting.

## Local installation
Clone the vesting folder by excecuting a [sparse checkout](https://git-scm.com/docs/git-sparse-checkout)

Run `yarn`

## Compile
`yarn compile` will compile all smart contracts in the contracts directory. ABI files will be automatically exported in build/abi directory.

## Testing
`yarn test`

## Code coverage
`yarn coverage` to print the report on the console and generate a static website containing full report in the coverage directory.