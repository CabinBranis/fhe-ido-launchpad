// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FHE Private IDO Launchpad (Demo)
 * @notice Minimal launchpad showcasing encrypted contributions/allocations
 *         on an FHE-enabled EVM. Ciphertexts are represented by `bytes`.
 *         Real FHEVM arithmetic/checks should be done on ciphertext.
 */
contract Launchpad {
    // -------------------------------------------------------------
    //                        DATA MODELS
    // -------------------------------------------------------------

    struct Sale {
        address project;      // sale owner (project)
        bytes token;          // token metadata or address (could be ciphertext/placeholder)
        uint256 start;        // start timestamp
        uint256 end;          // end timestamp
        bool active;          // sale open/closed flag
        bool finalized;       // finalized flag
        // Plaintext aggregates (demo-only hints)
        uint256 contributors; // unique participant count
        uint256 contributions;// number of contribution txs
    }

    struct EncryptedContribution {
        address user;
        bytes encryptedAmount; // ciphertext contribution amount
        uint256 timestamp;
        bool exists;           // track first-time contributor
        bool claimed;          // allocation claimed
    }

    // -------------------------------------------------------------
    //                           STORAGE
    // -------------------------------------------------------------

    address public owner;

    mapping(uint256 => Sale) public sales;
    uint256 public nextSaleId;

    // saleId => user => position
    mapping(uint256 => mapping(address => EncryptedContribution)) public positions;

    // -------------------------------------------------------------
    //                            EVENTS
    // -------------------------------------------------------------

    event SaleCreated(uint256 indexed saleId, address indexed project, bytes token, uint256 start, uint256 end);
    event SaleStatusChanged(uint256 indexed saleId, bool active);
    event SaleFinalized(uint256 indexed saleId, bytes encryptedSummary);

    event ContributedEncrypted(uint256 indexed saleId, address indexed user, bytes encryptedAmount);
    event AllocationClaimedEncrypted(uint256 indexed saleId, address indexed user, bytes encryptedAllocation);

    // -------------------------------------------------------------
    //                          MODIFIERS
    // -------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyProject(uint256 saleId) {
        require(msg.sender == sales[saleId].project, "Not project");
        _;
    }

    modifier saleActive(uint256 saleId) {
        Sale storage s = sales[saleId];
        require(s.active && block.timestamp >= s.start && block.timestamp < s.end, "Sale not active");
        _;
    }

    // -------------------------------------------------------------
    //                        INITIALIZATION
    // -------------------------------------------------------------

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    // -------------------------------------------------------------
    //                         SALE LIFECYCLE
    // -------------------------------------------------------------

    /// @notice Create a new sale window.
    function createSale(bytes calldata token, uint256 start, uint256 end) external returns (uint256 saleId) {
        require(end > start && end > block.timestamp, "Invalid window");

        saleId = nextSaleId++;
        sales[saleId] = Sale({
            project: msg.sender,
            token: token,
            start: start,
            end: end,
            active: true,
            finalized: false,
            contributors: 0,
            contributions: 0
        });

        emit SaleCreated(saleId, msg.sender, token, start, end);
    }

    /// @notice Pause/resume sale (project control).
    function setSaleActive(uint256 saleId, bool active_) external onlyProject(saleId) {
        sales[saleId].active = active_;
        emit SaleStatusChanged(saleId, active_);
    }

    // -------------------------------------------------------------
    //                           PARTICIPATE
    // -------------------------------------------------------------

    /// @notice Submit an encrypted contribution (ciphertext).
    function contributeEncrypted(uint256 saleId, bytes calldata encAmount) external saleActive(saleId) {
        EncryptedContribution storage p = positions[saleId][msg.sender];

        if (!p.exists) {
            p.user = msg.sender;
            p.exists = true;
            sales[saleId].contributors += 1;
        }

        // Overwrite or accumulate off-chain (client/FHE layer decides)
        p.encryptedAmount = encAmount;
        p.timestamp = block.timestamp;

        sales[saleId].contributions += 1;
        emit ContributedEncrypted(saleId, msg.sender, encAmount);
    }

    // -------------------------------------------------------------
    //                           FINALIZE
    // -------------------------------------------------------------

    /**
     * @notice Finalize sale and publish an encrypted summary/commitment
     *         (e.g., encrypted Merkle root of allocations).
     */
    function finalizeSale(uint256 saleId, bytes calldata encryptedSummary) external onlyProject(saleId) {
        Sale storage s = sales[saleId];
        require(!s.finalized, "Already finalized");
        require(block.timestamp >= s.end, "Not ended");

        s.finalized = true;
        s.active = false;

        emit SaleFinalized(saleId, encryptedSummary);
    }

    /**
     * @notice Claim an encrypted allocation after finalization.
     * @dev Real FHEVM would compute allocation amount on ciphertext.
     */
    function claimAllocationEncrypted(uint256 saleId, bytes calldata encAllocation) external {
        Sale storage s = sales[saleId];
        require(s.finalized, "Not finalized");

        EncryptedContribution storage p = positions[saleId][msg.sender];
        require(p.exists, "No contribution");
        require(!p.claimed, "Already claimed");

        p.claimed = true;
        emit AllocationClaimedEncrypted(saleId, msg.sender, encAllocation);
    }

    // -------------------------------------------------------------
    //                              VIEWS
    // -------------------------------------------------------------

    function isActive(uint256 saleId) external view returns (bool) {
        Sale storage s = sales[saleId];
        return s.active && block.timestamp >= s.start && block.timestamp < s.end;
    }

    function getSaleAggregates(uint256 saleId)
        external
        view
        returns (uint256 contributors, uint256 contributions, bool finalized)
    {
        Sale storage s = sales[saleId];
        return (s.contributors, s.contributions, s.finalized);
    }
}
