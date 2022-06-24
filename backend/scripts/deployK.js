const { ethers } = require("hardhat");

async function main() {
  const Keeper = await ethers.getContractFactory("Keeper");
  const keeper = await Keeper.deploy();

  await keeper.deployed();
  console.log("keeper deployed to:", keeper.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
