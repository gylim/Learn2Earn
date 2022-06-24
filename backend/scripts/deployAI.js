const hre = require("hardhat");

async function main() {
  const AaveInteraction = await hre.ethers.getContractFactory(
    "AaveInteraction"
  );
  const lpAddressProviderAddress = "0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6"; // Polygon mainnet: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
  const aaveInteraction = await AaveInteraction.deploy(
    lpAddressProviderAddress
  );

  await aaveInteraction.deployed();
  console.log("AaveInteraction deployed to:", aaveInteraction.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
