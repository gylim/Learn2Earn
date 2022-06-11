const {hre, ethers} = require("hardhat");

async function main() {
  const LearnToEarn = await hre.ethers.getContractFactory("LearnToEarn");
  const learntoearn = await LearnToEarn.deploy(ethers.utils.parseEther(0.05), 8);
  await learntoearn.deployed();
  console.log("Learn2Earn deployed to:", learntoearn.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
