require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

// The next line is part of the sample project, you don't need it in your
// project. It imports a Hardhat task definition, that can be used for
// testing the frontend.
require("./tasks/faucet");
require("./tasks/accounts");
require('dotenv').config({path:__dirname+'/.env'})


const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;

module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: `${RINKEBY_RPC_URL}`,
      accounts: [`${PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: `${ETHERSCAN_KEY}`
  },
  gas: 2100000,
  gasPrice: 8000000000,
};
