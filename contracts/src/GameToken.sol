// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GameToken (PIKN) - ERC-20 token earned from battles
/// @notice Players earn PIKN tokens by winning battles. Only authorized minters can mint.
contract GameToken is ERC20, Ownable {
    mapping(address => bool) public authorizedMinters;

    uint256 public constant BATTLE_REWARD = 10 * 1e18; // 10 tokens per battle win
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18; // 1 billion max

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event BattleRewardMinted(address indexed player, uint256 amount);

    error NotAuthorizedMinter();
    error ExceedsMaxSupply();

    constructor() ERC20("Game Pikanad Token", "PIKN") Ownable(msg.sender) {}

    modifier onlyMinter() {
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert NotAuthorizedMinter();
        }
        _;
    }

    function addMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
        emit MinterAdded(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
        emit MinterRemoved(minter);
    }

    /// @notice Mint battle reward tokens to a player
    function mintBattleReward(address player, uint256 amount) external onlyMinter {
        if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(player, amount);
        emit BattleRewardMinted(player, amount);
    }

    /// @notice Mint arbitrary amount (owner only, for initial liquidity etc.)
    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(to, amount);
    }
}
