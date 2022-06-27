const hre = require("hardhat");

async function main() {
  const InterestDistributionTest = await hre.ethers.getContractFactory(
    "InterestDistributionTest"
  );
  const interestDistributionTest = await InterestDistributionTest.deploy(
    "0xD2D925Ba2Da83D3d70703d1Ec1fd1DB2c43189C9",
    "0x608d11e704bafb68cfeb154bf7fd641120e33ad4",
    "0x1905D081af234D9E6643B93A748D3F8A405F97a4",
    120
  );

  await interestDistributionTest.deployed();
  console.log(
    "InterestDistributionTest deployed to:",
    interestDistributionTest.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
