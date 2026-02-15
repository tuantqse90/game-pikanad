// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CreatureNFT - ERC-721 for rare+ creatures
/// @notice Only creatures with rarity >= RARE can be minted as NFTs.
/// Stores species_id and stats on-chain.
contract CreatureNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;

    struct CreatureStats {
        uint16 speciesId;
        uint8 rarity; // 0=Common, 1=Uncommon, 2=Rare, 3=Legendary
        uint8 level;
        uint16 hp;
        uint16 attack;
        uint16 defense;
        uint16 speed;
    }

    mapping(uint256 => CreatureStats) public creatureStats;
    mapping(address => bool) public authorizedMinters;

    event CreatureMinted(
        address indexed owner,
        uint256 indexed tokenId,
        uint16 speciesId,
        uint8 rarity,
        uint8 level
    );

    error NotAuthorizedMinter();
    error RarityTooLow();

    constructor() ERC721("Pikanad Creature", "PIKC") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    modifier onlyMinter() {
        if (!authorizedMinters[msg.sender] && msg.sender != owner()) {
            revert NotAuthorizedMinter();
        }
        _;
    }

    function addMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
    }

    /// @notice Mint a creature NFT. Only rarity >= 2 (RARE) is allowed.
    function mintCreature(
        address to,
        uint16 speciesId,
        uint8 rarity,
        uint8 level,
        uint16 hp,
        uint16 attack,
        uint16 defense,
        uint16 speed
    ) external onlyMinter returns (uint256) {
        if (rarity < 2) revert RarityTooLow();

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        creatureStats[tokenId] = CreatureStats({
            speciesId: speciesId,
            rarity: rarity,
            level: level,
            hp: hp,
            attack: attack,
            defense: defense,
            speed: speed
        });

        emit CreatureMinted(to, tokenId, speciesId, rarity, level);
        return tokenId;
    }

    /// @notice Get stats of a creature by token ID
    function getCreature(uint256 tokenId) external view returns (CreatureStats memory) {
        _requireOwned(tokenId);
        return creatureStats[tokenId];
    }

    // Required overrides for ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable) returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
