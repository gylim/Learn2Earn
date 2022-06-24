const hre = require("hardhat");

async function main() {
  const InterestDistributionTest = await hre.ethers.getContractFactory(
    "InterestDistributionTest"
  );
  const interestDistributionTest = await InterestDistributionTest.deploy(
    1656095677
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
