// SPDX-License-Identifier:  GPL-3.0

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Contract is ERC20, Ownable {

    // Error Messages for the contract
    error ErrorAlreadyQueued(bytes32 txnHash);
    error ErrorNotQueued(bytes32 txnHash);
    error ErrorNotReady(uint256 blockTimestmap, uint256 timestamp);

    // Queue Minting Event
    event QueueMint(
        bytes32 txnHash,
        address to,
        uint256 amount,
        uint256 timestamp
    );

    // Mint Event
    event ExecuteMint(
        bytes32 txnHash,
        address to,
        uint256 amount,
        uint256 timestamp
    );

    // Minting Queue
    mapping(bytes32 => bool) public mintQueue;

    constructor() ERC20("TimeLock Token", "TLT") {}

    // Create hash of transaction data for use in the queue

    function generateTxnHash(
        address _to,
        uint256 _amount,
        uint256 _timestamp
    ) public pure returns (bytes32) {

        return keccak256(abi.encode(_to, _amount, _timestamp));

    }

    // Queue a mint for a given address amount, and timestamp
    function queueMint(
        address _to,
        uint256 _amount)
        public
        onlyOwner
    {
        uint256 timestamp = block.timestamp + 600;
        uint256 lockedAmount = (30 * _amount)/100; 

        // Generate the transaction hash
        bytes32 txnHash = generateTxnHash(_to, _amount, timestamp);

        // Check if the transaction is already in the queue
        if (mintQueue[txnHash]) {

            revert ErrorAlreadyQueued(txnHash);

        }

        mint(_to, _amount - lockedAmount);

        // Queue the transaction
        mintQueue[txnHash] = true;

        // Emit the QueueMint event
        emit QueueMint(txnHash, _to, _amount, timestamp);
    }

    // Execute a mint for a given address, amount, and timestamp
    function executeMint(
        address _to,
        uint256 _amount,
        uint256 _timestamp)
        external
        onlyOwner
    {
        // Generate the transaction hash
        bytes32 txnHash = generateTxnHash(_to, _amount, _timestamp);
        uint256 lockedAmount = (30 * _amount)/100;

        // Check if the transaction is in the queue
        if (!mintQueue[txnHash]) {

            revert ErrorNotQueued(txnHash);

        }

        // Check if the time has passed
        if (block.timestamp < _timestamp) {

            revert ErrorNotReady(block.timestamp, _timestamp);

        }
 
        // Remove the transaction from the queue
        mintQueue[txnHash] = false;

        // Execute the mint
        mint(_to, lockedAmount);

        // Emit the ExecuteMint event
        emit ExecuteMint(txnHash, _to, _amount, _timestamp);
    }


    // Mint tokens to a given address

    function mint(
        address to, 
        uint256 amount)
        internal 
    {
        _mint(to, amount);
    }

}
