const { expect } = require("chai");

describe("RobiGovernor contract", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: `before`, `beforeEach`, `after`, `afterEach`.

  // They're very useful to setup the environment for tests, and to clean it
  // up after they run.

  // A common pattern is to declare some variables, and assign them in the
  // `before` and `beforeEach` callbacks.

  let RobiToken;
  let hardhatToken;
  let owner;
  let addr1;
  let addr2;
  let addrs;
  const governorContractName = "RobiGovernor";
  const tokenContractName = "RobiToken";
  const tokenName = "RobiToken";
  const tokenSymbol = "RTK";
  const initialRtkSupply = 1000;
  const newProposal = { forumLink: "testingForumLink", title: "testingTitle", description: "testingDescription"};
  const approveVote = 0;
  const rejectVote = 1;
  const fee = 1;
  const maxForumLinkSize = 200;
  const maxTitleSize = 100;
  const maxDescriptionSize = 200;
  const defaultVotingPeriod = 10;

  async function mineNBlocks(n) {
    for (let index = 0; index < n; index++) {
      await ethers.provider.send('evm_mine');
    }
  }

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    RobiToken = await ethers.getContractFactory(tokenContractName);
    RobiGovernor = await ethers.getContractFactory(governorContractName);
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // deploy RobiToken and RobiGovernor contracts
    hardhatToken = await RobiToken.deploy(initialRtkSupply, tokenName, tokenSymbol);
    hardhatGovernor = await RobiGovernor.deploy(hardhatToken.address, governorContractName, defaultVotingPeriod);

    await hardhatToken.deployed();
    await hardhatGovernor.deployed();
  });

  describe("Deployment", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right name", async function () {
      expect(await hardhatGovernor.name()).to.equal(governorContractName);
    });

    it("Should set the right fee", async function () {
      expect(await hardhatGovernor.fee()).to.equal(fee);
    });

    it("Should set the right maxForumLinkSize", async function () {
      expect(await hardhatGovernor.maxForumLinkSize()).to.equal(maxForumLinkSize);
    });

    it("Should set the right maxTitleSize", async function () {
      expect(await hardhatGovernor.maxTitleSize()).to.equal(maxTitleSize);
    });

    it("Should set the right maxDescriptionSize", async function () {
      expect(await hardhatGovernor.maxDescriptionSize()).to.equal(maxDescriptionSize);
    });

    it("Should set the right votingPeriod", async function () {
      expect(await hardhatGovernor.getVotingPeriod()).to.equal(defaultVotingPeriod);
    });

    it("Should update the voting period", async function () {
      const newVotingPeriod = 1000;
      await hardhatGovernor.updateVotingPeriod(newVotingPeriod);
      expect(await hardhatGovernor.getVotingPeriod()).to.equal(newVotingPeriod);
    });

    it("Should create proposal and check if defeated after vote period has expired", async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      // mine vote period number of blocks
      await mineNBlocks(defaultVotingPeriod + 1)

      await hardhatGovernor.connect(owner).updateProposalStates();

      // fetch proposal, vote and all proposals
      const proposal = await hardhatGovernor.getProposal(0);

      // assertions

      // test if proposal status is DEFEATED (1)
      expect(proposal.status).to.equal(1);
    });

    it("Should create proposal, cast approve vote and check if proposal passed", async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      await hardhatGovernor.connect(addr1).castVote(0, approveVote);

      // mine vote period number of blocks
      await mineNBlocks(defaultVotingPeriod + 1)

      await hardhatGovernor.connect(owner).updateProposalStates();

      // fetch proposal, vote and all proposals
      const proposal = await hardhatGovernor.getProposal(0);

      // test if proposal status is PASSED (2)
      expect(proposal.status).to.equal(2);
      expect(proposal.forVotes).to.equal(50);
    });

    it("Should create proposal, cast against vote and check if proposal was defeated", async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      await hardhatGovernor.connect(addr1).castVote(0, rejectVote);

      // mine vote period number of blocks
      await mineNBlocks(defaultVotingPeriod + 1)

      await hardhatGovernor.connect(owner).updateProposalStates();

      // fetch proposal, vote and all proposals
      const proposal = await hardhatGovernor.getProposal(0);

      // test if proposal status is DEFEATED (1)
      expect(proposal.status).to.equal(1);
      expect(proposal.againstVotes).to.equal(50);
    });

    it("Should create proposal, cast approve vote, check if proposal passed and update state to executed.",
        async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      await hardhatGovernor.connect(addr1).castVote(0, approveVote);

      // mine vote period number of blocks
      await mineNBlocks(defaultVotingPeriod + 1)

      await hardhatGovernor.connect(owner).updateProposalStates();

      await hardhatGovernor.connect(owner).confirmProposalExecution(0);

      // fetch proposal, vote and all proposals
      const proposal = await hardhatGovernor.getProposal(0);

      // test if proposal status is EXECUTED (3)
      expect(proposal.status).to.equal(3);
      expect(proposal.forVotes).to.equal(50);
    });

    it("Should create proposal and revert attempt to confirm proposal execution while voting period is still active",
        async function () {
          // Transfer 50 tokens from owner to addr1
          await hardhatToken.transfer(addr1.address, 50);

          // fetch fee amount required
          const proposalFee = (await hardhatGovernor.fee()).toString();

          // create proposal and send fee amount of ETH along
          await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
              { value: ethers.utils.parseEther(proposalFee) });

          await expect(
              hardhatGovernor.connect(owner).confirmProposalExecution(0)
          ).to.be.revertedWith("Proposal voting period is still open!");
        });


    it("Should create proposal and cast vote", async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      await hardhatGovernor.connect(addr1).castVote(0, rejectVote);

      // check if LogProposalVotesUpdate event was emitted with the right values
      await expect(hardhatGovernor.connect(addr1).castVote(0, rejectVote))
          .to.emit(hardhatGovernor, 'LogProposalVotesUpdate')
          .withArgs(0, [rejectVote, 50]);

      // fetch proposal, vote and all proposals
      const [proposal, vote, allProposals, proposalCount] = await Promise.all([
        hardhatGovernor.getProposal(0),
        hardhatGovernor.getVote(0, addr1.address),
        hardhatGovernor.getProposals(),
        hardhatGovernor.proposalCount(),
      ]);

      // assertions

      // test if vote status is as we set it
      expect(vote.status).to.equal(rejectVote);

      // test if proposal was created with correct title
      expect(proposal.title).to.equal(newProposal.title);

      // test if proposal was added to the proposals mapping
      expect(allProposals.length).to.equal(1);

      // test if proposal count was increased
      expect(proposalCount).to.equal(1);
    });

  });
});
