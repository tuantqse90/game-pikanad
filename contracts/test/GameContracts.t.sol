// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GameToken.sol";
import "../src/CreatureNFT.sol";
import "../src/BattleRewards.sol";
import "../src/PvPBattle.sol";

contract GameContractsTest is Test {
    GameToken public gameToken;
    CreatureNFT public creatureNFT;
    BattleRewards public battleRewards;
    PvPBattle public pvpBattle;

    address public owner = address(this);
    address public player1 = address(0x1);
    address public player2 = address(0x2);
    uint256 public serverKey = 0xBEEF;
    address public serverSigner;

    function setUp() public {
        serverSigner = vm.addr(serverKey);

        gameToken = new GameToken();
        creatureNFT = new CreatureNFT();
        battleRewards = new BattleRewards(address(gameToken), serverSigner);
        pvpBattle = new PvPBattle(address(gameToken), serverSigner);

        // Authorize minters
        gameToken.addMinter(address(battleRewards));
        gameToken.addMinter(address(pvpBattle));
        creatureNFT.addMinter(serverSigner);
    }

    // ── GameToken Tests ──

    function test_TokenNameAndSymbol() public view {
        assertEq(gameToken.name(), "Game Pikanad Token");
        assertEq(gameToken.symbol(), "PIKN");
    }

    function test_OwnerCanMint() public {
        gameToken.mint(player1, 100e18);
        assertEq(gameToken.balanceOf(player1), 100e18);
    }

    function test_UnauthorizedCannotMint() public {
        vm.prank(player1);
        vm.expectRevert(GameToken.NotAuthorizedMinter.selector);
        gameToken.mintBattleReward(player1, 10e18);
    }

    // ── CreatureNFT Tests ──

    function test_MintRareCreature() public {
        vm.prank(serverSigner);
        uint256 tokenId = creatureNFT.mintCreature(
            player1,
            7,   // speciesId (Pyrodrake)
            2,   // rarity (RARE)
            10,  // level
            60,  // hp
            20,  // attack
            12,  // defense
            11   // speed
        );
        assertEq(tokenId, 1);
        assertEq(creatureNFT.ownerOf(1), player1);

        CreatureNFT.CreatureStats memory stats = creatureNFT.getCreature(1);
        assertEq(stats.speciesId, 7);
        assertEq(stats.rarity, 2);
        assertEq(stats.level, 10);
    }

    function test_CannotMintCommonAsNFT() public {
        vm.prank(serverSigner);
        vm.expectRevert(CreatureNFT.RarityTooLow.selector);
        creatureNFT.mintCreature(player1, 1, 0, 5, 44, 14, 8, 12); // COMMON
    }

    function test_CannotMintUncommonAsNFT() public {
        vm.prank(serverSigner);
        vm.expectRevert(CreatureNFT.RarityTooLow.selector);
        creatureNFT.mintCreature(player1, 4, 1, 5, 38, 11, 7, 16); // UNCOMMON
    }

    // ── BattleRewards Tests ──

    function test_ClaimBattleReward() public {
        bytes32 battleId = keccak256("battle_001");
        uint256 amount = 10e18;

        // Create server signature
        bytes32 messageHash = keccak256(abi.encodePacked(player1, battleId, amount));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(player1);
        battleRewards.claimReward(battleId, amount, signature);

        assertEq(gameToken.balanceOf(player1), amount);
        assertTrue(battleRewards.isClaimed(battleId));
    }

    function test_CannotDoubleClaimReward() public {
        bytes32 battleId = keccak256("battle_002");
        uint256 amount = 10e18;

        bytes32 messageHash = keccak256(abi.encodePacked(player1, battleId, amount));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(player1);
        battleRewards.claimReward(battleId, amount, signature);

        vm.prank(player1);
        vm.expectRevert(BattleRewards.AlreadyClaimed.selector);
        battleRewards.claimReward(battleId, amount, signature);
    }

    // ── PvPBattle Tests ──

    function test_PvPBattleFlow() public {
        uint256 stake = pvpBattle.STAKE_AMOUNT();

        // Give players tokens
        gameToken.mint(player1, stake);
        gameToken.mint(player2, stake);

        // Players approve PvPBattle contract
        vm.prank(player1);
        gameToken.approve(address(pvpBattle), stake);
        vm.prank(player2);
        gameToken.approve(address(pvpBattle), stake);

        // Create battle
        bytes32 battleId = keccak256("pvp_001");
        pvpBattle.createBattle(battleId, player1, player2);

        // Resolve: player1 wins
        bytes32 messageHash = keccak256(abi.encodePacked(battleId, player1));
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        pvpBattle.resolveBattle(battleId, player1, signature);

        // Winner gets 95% of total stake (2 * 10 = 20, 95% = 19)
        uint256 expectedReward = (stake * 2 * 9500) / 10000;
        assertEq(gameToken.balanceOf(player1), expectedReward);
        assertEq(gameToken.balanceOf(player2), 0);
    }
}
