const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("LearnToEarn", function () {
  let learntoearn, contractAdd, deployer, signer1, signer2, student1, student2
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
    expect(await learntoearn.tuitionFee()).to.equal(ethers.utils.parseEther("0.05"));
  });

  it("should set the session length", async function() {
    assert.equal(await learntoearn.sessions(), 8);
  });

  it("should allow new students to register", async function() {
    student1 = learntoearn.connect(signer1);
    await student1.register(60, {value: ethers.utils.parseEther("0.05")})
    const [x, _] = await learntoearn.isStudent(signer1.address)
    assert.equal(x, true);
  });

  it("should prevent re-registration", async function() {
    await student1.register(60, {value: ethers.utils.parseEther("0.05")})
    expect(await student1.register(60, {value: ethers.utils.parseEther("0.05")})).to.be.reverted;
  });

  it("should allow existing students to ping", async function() {
    expect(await student1.ping()).to.be.ok;
  })

  it("should not allow non-students to ping", async function() {
    student2 = learntoearn.connect(signer2);
    expect(await student2.ping()).to.be.reverted;
  })
});
