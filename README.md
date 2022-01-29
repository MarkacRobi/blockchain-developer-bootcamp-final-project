# Lightweight Governance

This repository contains a POC Governance implementation in the lightest form. It contains 2 smart contracts, first
being ERC20 token implementation and second containing governance logic. Token is used as a governance token.
There are implementation of complex type of governance on OZ, but for the purpose of learning the governance part was
developed from zero.


## File structure

.
├── contracts // Solidity smart contracts
├── frontend // React frontend app
├── scripts // hardhat smart contract deploy script
├── tasks // hardhat utility tasks
├── test // hardhat tests for smart contracts
├── hardhat.config.js // hardhat config file
├── package.json // npm dependencies and config
├── package-lock.json // locked npm dependencies and config
└── README.md // description of project

## Quick start

The first things you need to do are cloning this repository and installing its
dependencies:

```sh
git clone https://github.com/MarkacRobi/blockchain-developer-bootcamp-final-project.git
cd blockchain-developer-bootcamp-final-project
npm install
```

Once installed, let's run Hardhat's testing network:

```sh
npx hardhat node
```

**NOTE**: import one account - private key  from the list of accounts that were created, in your metamask. 
This will give you a fresh testing account with preloaded ETH.

Then, on a new terminal, go to the repository's root folder and run this to
deploy your contract:

```sh
npx hardhat run scripts/deploy.js --network localhost
```

Finally, we can run the frontend with:

```sh
cd frontend
npm install
npm start
```

> Note: There's [an issue in `ganache-core`](https://github.com/trufflesuite/ganache-core/issues/650) that can make the `npm install` step fail. 
>
> If you see `npm ERR! code ENOLOCAL`, try running `npm ci` instead of `npm install`.

Open [http://localhost:3000/](http://localhost:3000/) to see your Dapp. You will
need to have [Metamask](https://metamask.io) installed and listening to
`localhost 8545`.

## What’s Included?

Environment have everything you need to build a Dapp powered by Hardhat and React.

- [Hardhat](https://hardhat.org/): An Ethereum development task runner and testing network.
- [Mocha](https://mochajs.org/): A JavaScript test runner.
- [Chai](https://www.chaijs.com/): A JavaScript assertion library.
- [ethers.js](https://docs.ethers.io/ethers.js/html/): A JavaScript library for interacting with Ethereum.
- [Waffle](https://github.com/EthWorks/Waffle/): To have Ethereum-specific Chai assertions/mathers.
- [A sample frontend/Dapp](./frontend): A Dapp which uses [Create React App](https://github.com/facebook/create-react-app).

## Troubleshooting

- `Invalid nonce` errors: if you are seeing this error on the `npx hardhat node`
  console, try resetting your Metamask account. This will reset the account's
  transaction history and also the nonce. Open Metamask, click on your account
  followed by `Settings > Advanced > Reset Account`.
