const hre = require("hardhat");

async function main() {
  const LearnToEarn = await hre.ethers.getContractFactory("LearnToEarn");
  const learnToEarn = await LearnToEarn.deploy(
    "0x72BF91260505c08C1390b5C618e08b2816dCC579",
    "0x608d11e704bafb68cfeb154bf7fd641120e33ad4",
    "0xd4D80d6BFA4B3C597Ab2ea57E111EadaA1Ec0dc7",
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
