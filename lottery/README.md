# MetaDex Lottery
This directory contains the smart contracts for MetaDex's lottery.

## Local installation
Clone the lottery folder by excecuting a [sparse checkout](https://git-scm.com/docs/git-sparse-checkout).

Yarn is the recommended package manager for this directory.

In the root folder, run
```sh
yarn install
```

Install TypeScript.
```sh
yarn add typescript --dev
```

Install ts-node.
```sh
yarn add ts-node
```

Install Hardhat locally(from the root folder) using Yarn.
A global installation of hardhat is not supported. Run `yarn global list` to list global packages and `yarn global remove hardhat` if you would like to remove the global installation.
Run this command for a local installation.
```sh
yarn add hardhat
```

## Local network
Run Hardhat's local network for testing:
```sh
npx hardhat node
```

## Runing Tests
```sh
yarn test
```
