// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RobiToken.sol";

/// @dev RobiToken interface containing only needed methods
interface IRobiToken {
    function getBalanceAtBlockHeight(address _address, uint _blockHeight) external view returns (uint);
}

contract RobiGovernor is Ownable, ReentrancyGuard {

    /*
     * Events
     */

    /// @notice LogProposalCreated is emitted when proposal is created
    event LogProposalCreated(uint proposalId);

    /// @notice LogProposalStatusUpdate is emitted when proposals status has been updated
    event LogProposalStatusUpdate(uint proposalId, ProposalStatus status);

    /// @notice LogProposalVotesUpdate is emitted when vote for specific proposal has been updated
    event LogProposalVotesUpdate(uint proposalId, Vote vote);

    /*
     * Structs
     */

    /// @notice votes mapping maps user address to his vote
    /// @dev votes mapping is used as nested mapping for specific proposal votes
    struct Votes {
        mapping(address => Vote) votes;
    }

    /// @notice Vote struct represents users vote and is defined by status and weight (users balance on voteStart)
    /// @dev  Vote -> weight should be users balance at voteStart
    struct Vote {
        VoteStatus status;
        // weight represents balance of user at the voteStart block height
        uint weight;
    }

    /// @notice VoteResult struct represents response for users vote on specific proposal
    /// @dev VoteResult struct is used as response object for get all user votes query
    struct VoteResult {
        Vote vote;
        uint proposalId;
        address voter;
    }

    /// @notice Proposal struct represents specific proposal
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

    /// @notice ProposalStatus enum represents the state of specific proposal
    enum ProposalStatus { ACTIVE, DEFEATED, PASSED, EXECUTED }

    /// @notice VoteStatus enum represents the state of users vote
    enum VoteStatus { APPROVED, REJECTED }

    /*
     * Modifiers
     */

    /// @dev checks if string is empty
    /// @param data string to be checked
    modifier noEmptyString(string memory data) {
        require(bytes(data).length > 0, "RobiGovernor: String is empty");
        _;
    }

    /*
     * State variables
     */

    string private _name;

    // @notice _proposals mapping maps proposal id (uint256) to specific proposal
    mapping(uint256 => Proposal) private _proposals;

    // @notice votes mapping maps proposal id (uint256) to its Votes
    mapping(uint256 => Votes) private votes;
    uint proposalsCounter;

    // @notice governanceTokenAddress holds address of the governance token
    IRobiToken immutable private robiToken;

    uint private _votingPeriod;

    /// @notice Construct contract by specifying governance token address and governance name
    /// @param _token Governance token address
    /// @param contractName Contract name
    constructor(address _token, string memory contractName, uint votingPeriod) noEmptyString(contractName) {
        _name = contractName;
        robiToken = IRobiToken(_token);
        _votingPeriod = votingPeriod; // 1 hour
    }

    /// @notice This function is used to cast vote on specific proposal
    /// @param proposalId Specific proposal id
    /// @param voteStatus VoteStatus enum that specifies users decision
    /// @return bool True if cast was successful and false if not
    function castVote(uint proposalId, VoteStatus voteStatus) public returns (bool) {
        Proposal storage proposal = _proposals[proposalId];

        // vote can only be cast between vote start and end block heights
        require(block.number >= proposal.voteStart && block.number < proposal.voteEnd, "Voting period is not active.");

        // establish contract interface
        uint balance = robiToken.getBalanceAtBlockHeight(msg.sender, proposal.voteStart);

        // Check if users balance on voteStart was greater than 0
        require(balance > 0, "You have no voting power.");

        Vote storage currentVote = votes[proposalId].votes[msg.sender];

        // check if user has already voted and subtract vote weight from total for or against
        if (currentVote.weight != 0) {
            if (currentVote.status == VoteStatus.APPROVED) {
                proposal.forVotes -= currentVote.weight;
            } else {
                proposal.againstVotes -= currentVote.weight;
            }
        }

        if (VoteStatus.APPROVED == voteStatus) {
            proposal.forVotes += balance;
        } else {
            proposal.againstVotes += balance;
        }

        currentVote.status = voteStatus;
        currentVote.weight = balance;

        emit LogProposalVotesUpdate(proposalId, currentVote);

        return true;
    }

    /// @notice This function is used to update the proposal states and should be called now and then.
    /// @dev This function is protected against reentrancy because of external transfer call inside loop
    function updateProposalStates() payable public nonReentrant {
        // iterate all proposals
        // FIXME optimise proposal state update logic before production
        for (uint i = 0; i < proposalsCounter; i++) {
            Proposal storage proposal = _proposals[proposalsCounter];
            // if proposal is active and time to vote has passed
            if (proposal.status == ProposalStatus.ACTIVE && block.number >= proposal.voteEnd) {
                processProposal(proposal.id);
            }
        }
    }

    /// @notice This function confirms proposal execution by owner
    /// @dev This function should be triggered only when proposal is enacted
    /// @param proposalId Proposal id
    function confirmProposalExecution(uint proposalId) public onlyOwner {
        require(block.number >= _proposals[proposalId].voteEnd, "Proposal voting period is still open!");

        _proposals[proposalId].status = ProposalStatus.EXECUTED;

        emit LogProposalStatusUpdate(proposalId, _proposals[proposalId].status);
    }

    /// @notice This function is used to process proposal states and return fees if proposal has passed
    /// @dev Calling function should be protected by reentrancy guard
    /// @param proposalId Proposal which is being processed
    function processProposal(uint proposalId) private {
        Proposal storage proposal = _proposals[proposalId];
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

    /// @notice This function is used to create a new proposal
    /// @dev This function accepts fee (payable) required for creating a proposal. Fee is returned if proposal passes
    /// @param forumLink string representing link to the forum where discussion about proposal should be held
    /// @param title Proposals title
    /// @param description Proposals description
    /// @return uint Proposal id
    function createProposal(string memory forumLink, string memory title, string memory description
    ) payable noEmptyString(forumLink) noEmptyString(title) noEmptyString(description) public returns (uint) {
        // check if user paid enough fee
        require(msg.value >= fee(), "Fee is lower than required");
        // string input length checks
        require(utfStringLength(forumLink) <= maxForumLinkSize(), "Forum link length exceeds max size");
        require(utfStringLength(title) <= maxTitleSize(), "Title length exceeds max size");
        require(utfStringLength(description) <= maxDescriptionSize(), "Description length exceeds max size");

        uint proposalId = proposalsCounter;
        _proposals[proposalId] = Proposal(proposalId, block.number, block.number + _votingPeriod, payable(msg.sender),
        title, description, ProposalStatus.ACTIVE, 0, 0, fee(), false, forumLink);

        proposalsCounter++;

        emit LogProposalCreated(proposalId);

        return proposalsCounter - 1;
    }


    /// @notice This function is used to update the voting period
    function updateVotingPeriod(uint256 newPeriod) public onlyOwner {
        _votingPeriod  = newPeriod;
    }

    /// @notice This function returns name of this contract
    /// @return string Contracts name
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice This function returns Proposal struct
    /// @param id Proposal id
    /// @return Proposal Proposal struct
    function getProposal(uint id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    /// @notice This function returns users vote for specific proposal
    /// @param proposalId Proposal id
    /// @return Vote Users vote for specific proposal
    function getVote(uint proposalId, address _address) public view returns (Vote memory) {
        return votes[proposalId].votes[_address];
    }

    /// @notice This function returns all user votes for all proposals
    /// @return VoteResult[] Array of user VoteResult structs
    function getUserVotes() public view returns (VoteResult[] memory) {
        VoteResult[] memory tmpVotes = new VoteResult[](proposalsCounter);
        for (uint i = 0; i < proposalsCounter; i++) {
            tmpVotes[i] = VoteResult(votes[i].votes[msg.sender], i, msg.sender);
        }
        return tmpVotes;
    }

    /// @notice This function returns all proposals
    /// @return proposals Array of proposals
    function getProposals() public view returns (Proposal[] memory proposals) {
        Proposal[] memory tmpProposals = new Proposal[](proposalsCounter);
        for (uint i = 0; i < proposalsCounter; i++) {
            tmpProposals[i] = _proposals[i];
        }
        return tmpProposals;
    }

    /// @notice This function returns proposal count
    /// @return uint256 Number of proposals
    function proposalCount() public view returns (uint256) {
        return proposalsCounter;
    }

    /// @notice This function returns fee required for creation of proposal
    /// @return uint256 Number representing fee
    function fee() public pure returns (uint256) {
        return 1;
    }

    /// @notice This function returns max forum link size
    /// @return uint256 Number representing max forum link size
    function maxForumLinkSize() public pure returns (uint256) {
        return 200;
    }

    /// @notice This function returns max title size
    /// @return uint256 Number representing max title size
    function maxTitleSize() public pure returns (uint256) {
        return 100;
    }

    /// @notice This function returns max description size
    /// @return uint256 Number representing max description size
    function maxDescriptionSize() public pure returns (uint256) {
        return 200;
    }

    /// @notice This function returns voting period
    /// @dev Voting period is specified in number of blocks
    /// @return uint256 Number representing voting period
    function getVotingPeriod() public view returns (uint) {
        return _votingPeriod;
    }

    /// @notice This function returns length of string
    /// @dev This function should be used for determining the actual string length
    /// @return length Number representing provided string length
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