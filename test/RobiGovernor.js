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

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    RobiToken = await ethers.getContractFactory(tokenContractName);
    RobiGovernor = await ethers.getContractFactory(governorContractName);
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // deploy RobiToken and RobiGovernor contracts
    hardhatToken = await RobiToken.deploy(initialRtkSupply, tokenName, tokenSymbol);
    hardhatGovernor = await RobiGovernor.deploy(hardhatToken.address, governorContractName);

    await hardhatToken.deployed();
    await hardhatGovernor.deployed();
  });

  describe("Deployment", function () {
    // If the callback function is async, Mocha will `await` it.
    it("Should set the right name", async function () {
      expect(await hardhatGovernor.name()).to.equal(governorContractName);
    });

    it("Should create proposal and cast vote", async function () {
      // Transfer 50 tokens from owner to addr1
      await hardhatToken.transfer(addr1.address, 50);

      const addr1LatestCheckpoint = await hardhatToken.getLatestBalanceCheckpoint(addr1.address);
      console.log("addr1LatestCheckpoint", addr1LatestCheckpoint);

      // fetch fee amount required
      const proposalFee = (await hardhatGovernor.fee()).toString();

      // create proposal and send fee amount of ETH along
      const txHash = await hardhatGovernor.createProposal(newProposal.forumLink, newProposal.title, newProposal.description,
          { value: ethers.utils.parseEther(proposalFee) });

      // fetch proposal
      const proposal = await hardhatGovernor.getProposal(0);
      console.log("Proposal", proposal);

      // fetch all proposals
      const allProposals = await hardhatGovernor.getProposals();

      console.log("Balance", await hardhatToken.balanceOf(
          addr1.address
      ));

      console.log("Checkpoints", await hardhatToken.getBalanceCheckpoints(addr1.address));
      const castVoteTxHash = await hardhatGovernor.connect(addr1).castVote(0, 1);
      console.log(castVoteTxHash);
      // await expect(hardhatGovernor.connect(addr1).castVote(0, 1))
      //     .to.emit(hardhatGovernor, 'LogProposalVotesUpdate')
      //     .withArgs(0, [0, 25]);

      //
      // const vote = await hardhatGovernor.getVote(0);
      // console.log("Vote", vote);
      // console.log("Before asserting....");

      // assertions

      // test if proposal was created with correct title
      // expect(vote.status).to.equal(1);

      // test if proposal was created with correct title
      expect(proposal.title).to.equal(newProposal.title);

      // test if proposal was added to the proposals mapping
      expect(allProposals.length).to.equal(1);
    });

  });
});
