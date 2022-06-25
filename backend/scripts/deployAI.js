const hre = require("hardhat");

async function main() {
  const AaveInteraction = await hre.ethers.getContractFactory(
    "AaveInteraction"
  );
  const lpAddressProviderAddress = "0xBA6378f1c1D046e9EB0F538560BA7558546edF3C"; // Polygon mainnet: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
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
