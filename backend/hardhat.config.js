require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

module.exports = {
  solidity: "0.8.0",

  networks: {
    localhost: {
      url: "http://localhost:8545"
    }
  }
};
