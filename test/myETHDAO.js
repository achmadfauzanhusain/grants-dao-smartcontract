const { expect } = require("chai");
const { ethers } = require("hardhat")

describe("MyETHDAO", () => {
    let deployer, user
    let dao

    beforeEach(async () => {
        [deployer, user] = await ethers.getSigners()

        // deploy the ETHDAO contract
        const ETHDAO = await ethers.getContractFactory("MyETHDAO")
        dao = await ETHDAO.deploy()
        dao = await dao.waitForDeployment()

        // user donates to treasury
        await dao.connect(user).donateToTreasury({ value: ethers.parseEther("1")})

        // user stake ETH for voting
        await dao.connect(user).deposit({ value: ethers.parseEther("0.01") })

        // deployer stake ETH for create proposal
        await dao.connect(deployer).deposit({ value: ethers.parseEther("0.1") })

        // deployer create a proposal
        await dao.connect(deployer).createProposal("Proposal 1", "Summary of proposal 1", ethers.parseEther("0.01"), "About the owner of proposal 1")

        // user votes on the proposal
        await dao.connect(user).vote(1, true)
    })

    describe("Deployment", () => {
        it("Sets the deployer", async() => {
            let result = await dao.owner()
            expect(result).equal(deployer.address)
        })

        it("check stake amount", async() => {
            let deployerStake = await dao.stakes(deployer.address)
            expect(deployerStake).equal(ethers.parseEther("0.1"))

            let userStake = await dao.stakes(user.address)
            expect(userStake).equal(ethers.parseEther("0.01"))
        })

        // create a proposal
        it("Check proposal count", async() => {
            const count = await dao.proposalCount()
            expect(count).equal(1)
        })

        it("Check create proposal", async() => {
            const proposal = await dao.proposals(1)
            expect(proposal.title).equal("Proposal 1")
            expect(proposal.summary).equal("Summary of proposal 1")
            expect(proposal.ethAmount).equal(ethers.parseEther("0.01"))
            expect(proposal.aboutOwner).equal("About the owner of proposal 1")
            expect(proposal.recipient).equal(deployer.address)
            expect(proposal.votesFor).to.equal(1)
        })
    })

    describe("Withdraw", () => {
        let balanceBefore, balanceAfter
        beforeEach(async () => {
            balanceBefore = await ethers.provider.getBalance(user.address)
            // user withdraws their stake
            await dao.connect(user).withdraw()
        })

        it("Updates user balance", async () => {
            balanceAfter = await ethers.provider.getBalance(user.address)
            expect(balanceAfter).greaterThan(balanceBefore)
        })

        it("Updates contract balance", async () => {
            const balance = await ethers.provider.getBalance(dao.target)
            expect(balance).equal(0)
        })
    })
})