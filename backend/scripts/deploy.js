const {ethers} = require("hardhat");
require('dotenv').config();

async function main() {
  const LearnToEarn = await ethers.getContractFactory("LearnToEarn");
  const learntoearn = await LearnToEarn.deploy(4);
  await learntoearn.deployed();
  console.log("Learn2Earn deployed to:", learntoearn.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
