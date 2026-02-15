// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GameToken.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BattleRewards - Server-signed reward claims (anti-cheat)
/// @notice Players submit server-signed proofs to claim battle rewards on-chain.
contract BattleRewards is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    GameToken public gameToken;
    address public serverSigner;

    mapping(bytes32 => bool) public claimedBattles;

    event RewardClaimed(
        address indexed player,
        bytes32 indexed battleId,
        uint256 amount
    );

    error AlreadyClaimed();
    error InvalidSignature();

    constructor(address _gameToken, address _serverSigner) Ownable(msg.sender) {
        gameToken = GameToken(_gameToken);
        serverSigner = _serverSigner;
    }

    function setServerSigner(address _signer) external onlyOwner {
        serverSigner = _signer;
    }

    /// @notice Claim battle reward with server signature
    /// @param battleId Unique battle identifier
    /// @param amount Reward amount in tokens
    /// @param signature Server's signature over (player, battleId, amount)
    function claimReward(
        bytes32 battleId,
        uint256 amount,
        bytes calldata signature
    ) external {
        if (claimedBattles[battleId]) revert AlreadyClaimed();

        // Verify server signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, battleId, amount)
        );
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signature);

        if (signer != serverSigner) revert InvalidSignature();

        claimedBattles[battleId] = true;
        gameToken.mintBattleReward(msg.sender, amount);

        emit RewardClaimed(msg.sender, battleId, amount);
    }

    /// @notice Check if a battle reward has been claimed
    function isClaimed(bytes32 battleId) external view returns (bool) {
        return claimedBattles[battleId];
    }
}
