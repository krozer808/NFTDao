//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "./IERC721.sol";

contract DAO {
    address owner;
    Token public token;
    IERC721 public nft;
    uint256 public quorum;
    uint256 public currentTokenId = 1;

    struct Proposal {
        uint256 id;
        string name;
        uint256 tokenId;
        address payable recipient;
        uint256 votes;
        bool finalized;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    mapping(address => mapping(uint256 => bool)) votes;

    event Propose(
        uint id,
        uint256 currentTokenId,
        address recipient,
        address creator
    );
    event Vote(uint256 id, address investor);
    event Finalize(uint256 id);

    constructor(Token _token, address _nft, uint256 _quorum) {
        owner = msg.sender;
        token = _token;
        quorum = _quorum;
        nft = IERC721(_nft); 
    }

    // Allow contract to receive ether
    receive() external payable {}

    modifier onlyInvestor() {
        require(
            token.balanceOf(msg.sender) > 0,
            "must be token holder"
        );
        _;
    }

    // Create proposal
    function createProposal(
        string memory _name,
        address payable _recipient
    ) external onlyInvestor {
        
        require(IERC721(nft).ownerOf(currentTokenId) == address(this), "The contract does not own the NFT");

        proposalCount++;

        proposals[proposalCount] = Proposal(
            proposalCount,
            _name,
            currentTokenId,
            _recipient,
            0,
            false
        );

        emit Propose(
            proposalCount,
            currentTokenId,
            _recipient,
            msg.sender
        );
    }

    // Vote on proposal
    function vote(uint256 _id) external onlyInvestor {
        // Fetch proposal from mapping by id
        Proposal storage proposal = proposals[_id];

        // Don't let investors vote twice
        require(!votes[msg.sender][_id], "already voted");

        // update votes
        proposal.votes += token.balanceOf(msg.sender);

        // Track that user has voted
        votes[msg.sender][_id] = true;

        // Emit an event
        emit Vote(_id, msg.sender);
    }

    // Finalize proposal & transfer nft
    function finalizeProposal(uint256 _id) external onlyInvestor {
    
    // Fetch proposal from mapping by id
    Proposal storage proposal = proposals[_id];

    // Ensure proposal is not already finalized
    require(proposal.finalized == false, "proposal already finalized");

    // Mark proposal as finalized
    proposal.finalized = true;

    // Check that proposal has enough votes
    require(proposal.votes >= quorum, "must reach quorum to finalize proposal");

    // Check that the contract has the nft
    require(IERC721(nft).ownerOf(currentTokenId) == address(this), "The contract does not own the NFT");

    // Transfer the nft to recipient
    IERC721(nft).safeTransferFrom(address(this), proposal.recipient, currentTokenId);

    // Mark proposal as finalized
    proposal.finalized = true;

    // Increment the currentTokenId for the next proposal
    currentTokenId++;

    // Emit event
    emit Finalize(_id);
}

}
