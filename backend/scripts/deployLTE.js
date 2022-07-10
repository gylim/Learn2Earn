const hre = require("hardhat");

async function main() {
  const LearnToEarn = await hre.ethers.getContractFactory("LearnToEarn");
  const learnToEarn = await LearnToEarn.deploy(
    "0x8c49846d72e49Efa25cc20420c6BCFDedC9A22c9",
    "0x608d11e704bafb68cfeb154bf7fd641120e33ad4",
    "0x7f4E9bD11C53ccAfa9A5619970B110cC626FeF4c",
    120
  );

  await learnToEarn.deployed();
  console.log("LearnToEarn deployed to:", learnToEarn.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
