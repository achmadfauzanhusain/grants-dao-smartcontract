const { ethers } = require("hardhat")

async function main() {
    const [deployer] = await ethers.getSigners()

    const MyETHDAO = await ethers.getContractFactory("MyETHDAO")
    const myethdao = await MyETHDAO.deploy()
    await myethdao.waitForDeployment()

    console.log("MyETHDAO deployed to:", myethdao.target)
    console.log("Deployer address:", deployer.address)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});