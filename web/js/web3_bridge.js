/**
 * Web3 Bridge - Connects Godot (GDScript) to Monad blockchain via ethers.js
 *
 * Godot calls these functions via JavaScriptBridge.eval() and
 * receives results via callbacks registered on window.godotWeb3Callback.
 */

let provider = null;
let signer = null;
let gameTokenContract = null;
let creatureNFTContract = null;
let battleRewardsContract = null;
let pvpBattleContract = null;
let connectedAddress = null;

// Callback bridge: Godot registers a callback, JS calls it with results
window.godotWeb3Callback = null;

function _sendToGodot(eventName, data) {
    if (window.godotWeb3Callback) {
        window.godotWeb3Callback(JSON.stringify({ event: eventName, data: data }));
    }
}

/**
 * Connect MetaMask wallet
 */
async function web3_connect_wallet() {
    try {
        if (typeof window.ethereum === "undefined") {
            _sendToGodot("wallet_error", { message: "MetaMask not found" });
            return;
        }

        provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        connectedAddress = await signer.getAddress();

        // Try to switch to Monad network
        try {
            await window.ethereum.request({
                method: "wallet_switchEthereumChain",
                params: [{ chainId: CHAIN_CONFIG.chainId }],
            });
        } catch (switchError) {
            // Chain not added yet, add it
            if (switchError.code === 4902) {
                await window.ethereum.request({
                    method: "wallet_addEthereumChain",
                    params: [CHAIN_CONFIG],
                });
            }
        }

        // Initialize contracts
        _initContracts();

        _sendToGodot("wallet_connected", { address: connectedAddress });
    } catch (error) {
        _sendToGodot("wallet_error", { message: error.message });
    }
}

function _initContracts() {
    if (!signer) return;

    if (CONTRACTS.gameToken !== "0x0000000000000000000000000000000000000000") {
        gameTokenContract = new ethers.Contract(CONTRACTS.gameToken, GAME_TOKEN_ABI, signer);
    }
    if (CONTRACTS.creatureNFT !== "0x0000000000000000000000000000000000000000") {
        creatureNFTContract = new ethers.Contract(CONTRACTS.creatureNFT, CREATURE_NFT_ABI, signer);
    }
    if (CONTRACTS.battleRewards !== "0x0000000000000000000000000000000000000000") {
        battleRewardsContract = new ethers.Contract(CONTRACTS.battleRewards, BATTLE_REWARDS_ABI, signer);
    }
    if (CONTRACTS.pvpBattle !== "0x0000000000000000000000000000000000000000") {
        pvpBattleContract = new ethers.Contract(CONTRACTS.pvpBattle, PVP_BATTLE_ABI, signer);
    }
}

/**
 * Get PIKN token balance
 */
async function web3_get_token_balance() {
    try {
        if (!gameTokenContract || !connectedAddress) {
            _sendToGodot("balance_result", { balance: "0" });
            return;
        }
        const balance = await gameTokenContract.balanceOf(connectedAddress);
        const formatted = ethers.formatEther(balance);
        _sendToGodot("balance_result", { balance: formatted });
    } catch (error) {
        _sendToGodot("balance_error", { message: error.message });
    }
}

/**
 * Get owned NFT creatures
 */
async function web3_get_nft_creatures() {
    try {
        if (!creatureNFTContract || !connectedAddress) {
            _sendToGodot("nft_creatures_result", { creatures: [] });
            return;
        }

        const balance = await creatureNFTContract.balanceOf(connectedAddress);
        const creatures = [];

        for (let i = 0; i < balance; i++) {
            const tokenId = await creatureNFTContract.tokenOfOwnerByIndex(connectedAddress, i);
            const stats = await creatureNFTContract.getCreature(tokenId);
            creatures.push({
                tokenId: tokenId.toString(),
                speciesId: stats.speciesId,
                rarity: stats.rarity,
                level: stats.level,
                hp: stats.hp,
                attack: stats.attack,
                defense: stats.defense,
                speed: stats.speed,
            });
        }

        _sendToGodot("nft_creatures_result", { creatures: creatures });
    } catch (error) {
        _sendToGodot("nft_creatures_error", { message: error.message });
    }
}

/**
 * Claim battle reward with server signature
 */
async function web3_claim_battle_reward(battleIdHex, amountWei, signatureHex) {
    try {
        if (!battleRewardsContract) {
            _sendToGodot("claim_error", { message: "Contract not initialized" });
            return;
        }

        const tx = await battleRewardsContract.claimReward(battleIdHex, amountWei, signatureHex);
        const receipt = await tx.wait();

        _sendToGodot("claim_success", {
            txHash: receipt.hash,
            battleId: battleIdHex,
        });
    } catch (error) {
        _sendToGodot("claim_error", { message: error.message });
    }
}

/**
 * Get connected wallet address
 */
function web3_get_address() {
    return connectedAddress || "";
}

/**
 * Check if wallet is connected
 */
function web3_is_connected() {
    return connectedAddress !== null;
}

// Listen for account changes
if (typeof window.ethereum !== "undefined") {
    window.ethereum.on("accountsChanged", (accounts) => {
        if (accounts.length === 0) {
            connectedAddress = null;
            _sendToGodot("wallet_disconnected", {});
        } else {
            connectedAddress = accounts[0];
            _sendToGodot("wallet_changed", { address: connectedAddress });
        }
    });

    window.ethereum.on("chainChanged", () => {
        window.location.reload();
    });
}

console.log("Web3 Bridge loaded for Game Pikanad");
