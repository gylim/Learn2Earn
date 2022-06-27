const { ethers } = require("hardhat");

async function main() {
  const LearnToken = await ethers.getContractFactory("LearnToken");
  const learnToken = await LearnToken.deploy();
  await learnToken.deployed();
  console.log("LearnToken deployed to:", learnToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
