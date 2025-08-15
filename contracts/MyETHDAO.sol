// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MyETHDAO {
    address public owner;
    uint256 public feeBasisPoints = 1;

    struct Proposal {
        string title;
        string summary;
        uint256 ethAmount;
        string aboutOwner;
        address recipient;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakes;
    uint256 public treasuryBalance;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, string message);
    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 votes);
    event Executed(uint256 proposalId, bool passed);

    constructor() {
        owner = msg.sender;
    }

    // ✅ Stake ETH agar bisa voting
    function deposit() external payable {
        require(msg.value >= 0.01 ether, "Min 0.01 ETH");

        // Simpan sisanya sebagai stake
        stakes[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // Donate to Treasury
    function donateToTreasury() external payable {
        require(msg.value > 0, "No ETH sent");

        uint256 fee = (msg.value * feeBasisPoints) / 10000;
        uint256 amountAfterFee = msg.value - fee;

        // Transfer fee ke owner
        (bool sent, ) = owner.call{value: fee}("");
        require(sent, "Fee transfer failed");

        treasuryBalance += amountAfterFee;
    }

    // ✅ Tarik ETH jika sudah tidak ingin voting
    function withdraw() external {
        uint256 amount = stakes[msg.sender];
        require(amount > 0, "No stake to withdraw");

        stakes[msg.sender] = 0; // reset stake sebelum transfer (prevent re-entrancy)
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, "Stake withdrawn");
    }

    // ✅ Buat proposal
    function createProposal(string memory _title, string memory _summary, uint256 _ethAmount, string memory _aboutOwner) external {
        require(stakes[msg.sender] >= 0.1 ether, "Need at least 0.1 ETH staked");
        require(_ethAmount <= treasuryBalance, "Insufficient treasury funds");
        require(_ethAmount > 0, "Proposal amount must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_summary).length > 0, "Summary cannot be empty");
        require(bytes(_aboutOwner).length > 0, "About owner cannot be empty");
        
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.title = _title;
        p.summary = _summary;
        p.ethAmount = _ethAmount;
        p.aboutOwner = _aboutOwner;
        p.recipient = msg.sender; // penerima proposal adalah pembuatnya
        p.deadline = block.timestamp + 3 days; // voting window
        emit ProposalCreated(proposalCount, _title);
    }

    // ✅ Voting
    function vote(uint256 _proposalId, bool support) external {
        Proposal storage p = proposals[_proposalId];

        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.hasVoted[msg.sender], "Already voted");
        require(stakes[msg.sender] >= 0.01 ether, "Stake min 0.01 ETH");

        uint256 votes = stakes[msg.sender] / 0.01 ether;

        p.hasVoted[msg.sender] = true;

        if (support) {
            p.votesFor += votes;
        } else {
            p.votesAgainst += votes;
        }

        emit Voted(_proposalId, msg.sender, support, votes);
    }

    // ✅ Eksekusi (manual, sesuai proposal menang atau tidak)
    function executeProposal(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];

        require(block.timestamp >= p.deadline, "Voting not ended");
        require(!p.executed, "Already executed");

        p.executed = true;

        bool passed = p.votesFor > p.votesAgainst;
        emit Executed(_proposalId, passed);

        if (passed) {
            require(address(this).balance >= p.ethAmount, "Insufficient DAO funds");
            require(treasuryBalance >= p.ethAmount, "Insufficient treasury funds");
            
            treasuryBalance -= p.ethAmount;
            (bool sent, ) = p.recipient.call{value: p.ethAmount}("");
            require(sent, "Transfer failed");
        }
    }

    // ✅ Lihat ringkasan proposal
    function getProposal(uint256 _id) external view returns (
        string memory description,
        string memory summary,
        uint256 ethAmount,
        string memory aboutOwner,
        address recipient,
        uint256 deadline,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed
    ) {
        Proposal storage p = proposals[_id];
        return (p.title, p.summary, p.ethAmount, p.aboutOwner, p.recipient, p.deadline, p.votesFor, p.votesAgainst, p.executed);
    }
}