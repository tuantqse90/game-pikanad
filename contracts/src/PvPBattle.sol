// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GameToken.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PvPBattle - Stake tokens, server resolves winner
/// @notice Players stake PIKN tokens to enter PvP battles.
/// Server resolves the winner and signs the result.
/// Winner gets 95% of the pot, 5% is protocol fee.
contract PvPBattle is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    GameToken public gameToken;
    address public serverSigner;

    uint256 public constant STAKE_AMOUNT = 10 * 1e18; // 10 PIKN to enter
    uint256 public constant FEE_BPS = 500; // 5% = 500 basis points
    uint256 public constant BPS_DENOMINATOR = 10000;

    struct Battle {
        address player1;
        address player2;
        uint256 totalStake;
        bool resolved;
        address winner;
    }

    mapping(bytes32 => Battle) public battles;
    uint256 public protocolFees;

    event BattleCreated(bytes32 indexed battleId, address indexed player1, address indexed player2);
    event BattleResolved(bytes32 indexed battleId, address indexed winner, uint256 reward);
    event FeesWithdrawn(address indexed to, uint256 amount);

    error BattleAlreadyExists();
    error BattleAlreadyResolved();
    error InvalidSignature();
    error InsufficientAllowance();

    constructor(address _gameToken, address _serverSigner) Ownable(msg.sender) {
        gameToken = GameToken(_gameToken);
        serverSigner = _serverSigner;
    }

    function setServerSigner(address _signer) external onlyOwner {
        serverSigner = _signer;
    }

    /// @notice Create a PvP battle. Both players must have approved STAKE_AMOUNT.
    /// Called by the server after matchmaking.
    function createBattle(
        bytes32 battleId,
        address player1,
        address player2
    ) external {
        if (battles[battleId].player1 != address(0)) revert BattleAlreadyExists();

        // Transfer stakes from both players
        gameToken.transferFrom(player1, address(this), STAKE_AMOUNT);
        gameToken.transferFrom(player2, address(this), STAKE_AMOUNT);

        battles[battleId] = Battle({
            player1: player1,
            player2: player2,
            totalStake: STAKE_AMOUNT * 2,
            resolved: false,
            winner: address(0)
        });

        emit BattleCreated(battleId, player1, player2);
    }

    /// @notice Resolve a battle with server signature
    function resolveBattle(
        bytes32 battleId,
        address winner,
        bytes calldata signature
    ) external {
        Battle storage battle = battles[battleId];
        if (battle.resolved) revert BattleAlreadyResolved();

        // Verify server signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(battleId, winner)
        );
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signature);
        if (signer != serverSigner) revert InvalidSignature();

        battle.resolved = true;
        battle.winner = winner;

        // Calculate reward: 95% to winner, 5% protocol fee
        uint256 fee = (battle.totalStake * FEE_BPS) / BPS_DENOMINATOR;
        uint256 reward = battle.totalStake - fee;

        protocolFees += fee;
        gameToken.transfer(winner, reward);

        emit BattleResolved(battleId, winner, reward);
    }

    /// @notice Withdraw accumulated protocol fees
    function withdrawFees(address to) external onlyOwner {
        uint256 amount = protocolFees;
        protocolFees = 0;
        gameToken.transfer(to, amount);
        emit FeesWithdrawn(to, amount);
    }
}
