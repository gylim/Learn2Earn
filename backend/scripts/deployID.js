const hre = require("hardhat");

async function main() {
  const InterestDistribution = await hre.ethers.getContractFactory(
    "InterestDistribution"
  );
  const interestDistribution = await InterestDistribution.deploy();

  await interestDistribution.deployed();
  console.log(
    "InterestDistribution deployed to:",
    interestDistribution.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
