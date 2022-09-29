# MetaDex Lottery
This directory contains the smart contracts for MetaDex's lottery.

## Local installation
Clone the lottery folder by excecuting a [sparse checkout](https://git-scm.com/docs/git-sparse-checkout)
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

A global installation of hardhat is not supported. Run `yarn global list` to list global packages and `yarn global remove hardhat`.
Install Hardhat locally(from the root folder) using Yarn.
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
