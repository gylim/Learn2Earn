const hre = require("hardhat");

async function main() {
  const LearnToEarn = await hre.ethers.getContractFactory("LearnToEarn");
  const learnToEarn = await LearnToEarn.deploy(
    "0xD2D925Ba2Da83D3d70703d1Ec1fd1DB2c43189C9",
    "0x608d11e704bafb68cfeb154bf7fd641120e33ad4",
    "0x1905D081af234D9E6643B93A748D3F8A405F97a4",
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
