const hre = require("hardhat");

async function main() {
  const AaveInteraction = await hre.ethers.getContractFactory(
    "AaveInteraction"
  );

  // SEE: https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses
  // WETHGateway && W<NATIVE>-AToken-<network> && PoolAddressesProvider-<network>
  const wETHGatewayAddress = "0xd1decc6502cc690bc85faf618da487d886e54abe";
  const wNativeATokenAddress = "0x608d11e704bafb68cfeb154bf7fd641120e33ad4";
  const lpAddressProviderAddress = "0xba6378f1c1d046e9eb0f538560ba7558546edf3c";

  const aaveInteraction = await AaveInteraction.deploy(
    wETHGatewayAddress,
    wNativeATokenAddress,
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
