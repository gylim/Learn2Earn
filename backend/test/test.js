const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("LearnToEarn", function () {
  let learntoearn, contractAdd, deployer, signer1, signer2;
  before("Should deploy the contract", async function () {
    const LearnToEarn = await ethers.getContractFactory("LearnToEarn");
    learntoearn = await LearnToEarn.deploy(ethers.utils.parseEther("0.05"), 8);
    await learntoearn.deployed();
    contractAdd = await learntoearn.address;
    [deployer, signer1, signer2] = await ethers.getSigners();
  });

  it("should set the provost", async function() {
    assert.equal(await learntoearn.provost(), deployer.address);
  });

  it("should set the tuition fee", async function() {
    assert.equal(await learntoearn.tuitionFee(), ethers.utils.parseEther("0.05"));
  });

  it("should set the session length", async function() {
    assert.equal(await learntoearn.sessions(), 8);
  });

  it("should allow new students to register", async function() {
    const student1 = learntoearn.connect(signer1);
    await student1.register(60[{value: ethers.utils.parseEther("0.05")}])
    expect(await learntoearn.cohort[0].wallet()).to.equal(signer1.address);
  });

  it
});
