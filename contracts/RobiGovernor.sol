// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RobiToken.sol";

contract RobiGovernor is Ownable, ReentrancyGuard {

    /*
     * Events
     */
    event LogProposalCreated(uint proposalId);

    event LogProposalStatusUpdate(uint proposalId, ProposalStatus status);

    event LogProposalVotesUpdate(uint proposalId, Vote vote);

    /*
     * Structs
     */
    struct Votes {
        mapping(address => Vote) votes;
    }

    struct Vote {
        VoteStatus status;
        // weight represents balance of user at the voteStart block height
        uint weight;
    }

    struct Proposal {
        uint id;
        uint voteStart; // block number
        uint voteEnd; // block number
        address payable proposer;
        string title;
        string description;
        ProposalStatus status;
        uint forVotes;
        uint againstVotes;
        uint fee;
        bool feeRefunded;
        string forumLink;
    }

    /*
     * Enums
     */
    enum ProposalStatus { ACTIVE, DEFEATED, PASSED, EXECUTED }

    enum VoteStatus { APPROVED, REJECTED }

    /*
     * State variables
     */
    string private _name;

    // @notice uint256 is proposalId
    mapping(uint256 => Proposal) private _proposals;

    // @notice uint256 is proposalId
    mapping(uint256 => Votes) private votes;
    uint proposalsCounter;

    address immutable private governanceTokenAddress;

    constructor(address _token, string memory name) {
        _name = name;
        governanceTokenAddress = _token;
    }

    function castVote(uint proposalId, VoteStatus voteStatus) public returns (bool) {
        Proposal storage proposal = _proposals[proposalId];

        // vote can only be cast between vote start and end block heights
        require(block.number >= proposal.voteStart && block.number < proposal.voteEnd, "Voting period is not active.");

        // establish contract interface
        RobiToken tokenContract = RobiToken(governanceTokenAddress);
        uint balance = tokenContract.getBalanceAtBlockHeight(msg.sender, proposal.voteStart);

        require(balance > 0, "You have no voting power.");

        Vote storage currentVote = votes[proposalId].votes[msg.sender];

        currentVote.status = voteStatus;
        currentVote.weight = balance;

        emit LogProposalVotesUpdate(proposalId, currentVote);

        return true;
    }

    function updateProposalStates() payable public onlyOwner nonReentrant {
        for (uint i = 0; i < proposalsCounter; i++) {
            Proposal storage proposal = _proposals[proposalsCounter];
            // if proposal is active and time to vote has passed
            if (proposal.status == ProposalStatus.ACTIVE && block.number >= proposal.voteEnd) {
                processProposal(proposal);
            }
        }
    }

    function confirmProposalExecution(uint proposalId) public onlyOwner {
        require(block.number < _proposals[proposalId].voteEnd, "Proposal voting period is still open!");

        _proposals[proposalId].status = ProposalStatus.EXECUTED;

        emit LogProposalStatusUpdate(proposalId, _proposals[proposalId].status);
    }

    function processProposal(Proposal storage proposal) private onlyOwner {
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.PASSED;
            if (!proposal.feeRefunded) {
                proposal.feeRefunded = true;
                proposal.proposer.transfer(proposal.fee);
            }
        } else {
            proposal.status = ProposalStatus.DEFEATED;
        }

        emit LogProposalStatusUpdate(proposal.id, proposal.status);
    }

    function createProposal(string memory forumLink, string memory title, string memory description
    ) payable public returns (uint) {
        // check if user paid enough fee
        require(msg.value >= fee(), "Fee is lower than required");
        // string input length checks
        require(utfStringLength(forumLink) <= maxForumLinkSize(), "Forum link length exceeds max size");
        require(utfStringLength(title) <= maxTitleSize(), "Title length exceeds max size");
        require(utfStringLength(description) <= maxTitleSize(), "Description length exceeds max size");

        uint proposalId = proposalsCounter;
        _proposals[proposalId] = Proposal(proposalId, block.number, block.number + votingPeriod(), payable(msg.sender),
        title, description, ProposalStatus.ACTIVE, 0, 0, fee(), false, forumLink);

        proposalsCounter++;

        emit LogProposalCreated(proposalId);

        return proposalsCounter - 1;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function getProposal(uint id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    function getVote(uint proposalId) public view returns (Vote memory) {
        return votes[proposalId].votes[msg.sender];
    }

    function getVotes(uint proposalId) public view returns (Vote memory) {
        return votes[proposalId].votes[msg.sender];
    }

    function getProposals() public view returns (Proposal[] memory proposals) {
        Proposal[] memory tmpProposals = new Proposal[](proposalsCounter);
        for (uint i = 0; i < proposalsCounter; i++) {
            tmpProposals[i] = _proposals[i];
        }
        return tmpProposals;
    }

    function proposalCount() public view returns (uint256) {
        return proposalsCounter;
    }

    function fee() public pure returns (uint256) {
        return 10;
    }

    function maxForumLinkSize() public pure returns (uint256) {
        return 200;
    }

    function maxTitleSize() public pure returns (uint256) {
        return 100;
    }

    function maxDescriptionSize() public pure returns (uint256) {
        return 500;
    }

    function votingPeriod() public pure returns (uint256) {
        return 46027; // 1 week
    }

    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);
        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
            //For safety
                i+=1;

            length++;
        }
    }
}