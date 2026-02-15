// Monad chain configuration and contract addresses
const CHAIN_CONFIG = {
    // Monad Testnet
    chainId: "0x279F", // 10143
    chainName: "Monad Testnet",
    rpcUrls: ["https://testnet-rpc.monad.xyz"],
    nativeCurrency: {
        name: "MON",
        symbol: "MON",
        decimals: 18,
    },
    blockExplorerUrls: ["https://testnet.monadexplorer.com"],
};

// Contract addresses (update after deployment)
const CONTRACTS = {
    gameToken: "0x0000000000000000000000000000000000000000",
    creatureNFT: "0x0000000000000000000000000000000000000000",
    battleRewards: "0x0000000000000000000000000000000000000000",
    pvpBattle: "0x0000000000000000000000000000000000000000",
};

// Minimal ABIs for the functions we need
const GAME_TOKEN_ABI = [
    "function balanceOf(address) view returns (uint256)",
    "function approve(address spender, uint256 amount) returns (bool)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
];

const CREATURE_NFT_ABI = [
    "function balanceOf(address) view returns (uint256)",
    "function tokenOfOwnerByIndex(address, uint256) view returns (uint256)",
    "function getCreature(uint256) view returns (tuple(uint16 speciesId, uint8 rarity, uint8 level, uint16 hp, uint16 attack, uint16 defense, uint16 speed))",
    "function mintCreature(address, uint16, uint8, uint8, uint16, uint16, uint16, uint16) returns (uint256)",
];

const BATTLE_REWARDS_ABI = [
    "function claimReward(bytes32, uint256, bytes) external",
    "function isClaimed(bytes32) view returns (bool)",
];

const PVP_BATTLE_ABI = [
    "function STAKE_AMOUNT() view returns (uint256)",
    "function createBattle(bytes32, address, address) external",
    "function resolveBattle(bytes32, address, bytes) external",
];
