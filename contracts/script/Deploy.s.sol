// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GameToken.sol";
import "../src/CreatureNFT.sol";
import "../src/BattleRewards.sol";
import "../src/PvPBattle.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address serverSigner = vm.envAddress("SERVER_SIGNER");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy GameToken
        GameToken gameToken = new GameToken();

        // Deploy CreatureNFT
        CreatureNFT creatureNFT = new CreatureNFT();

        // Deploy BattleRewards
        BattleRewards battleRewards = new BattleRewards(
            address(gameToken),
            serverSigner
        );

        // Deploy PvPBattle
        PvPBattle pvpBattle = new PvPBattle(
            address(gameToken),
            serverSigner
        );

        // Authorize contracts as minters
        gameToken.addMinter(address(battleRewards));
        gameToken.addMinter(address(pvpBattle));
        creatureNFT.addMinter(serverSigner);

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("GameToken:", address(gameToken));
        console.log("CreatureNFT:", address(creatureNFT));
        console.log("BattleRewards:", address(battleRewards));
        console.log("PvPBattle:", address(pvpBattle));
    }
}
