import { ethers } from "ethers";

/**
 * Signs battle results for on-chain reward claims.
 * The server's private key should be set via SERVER_PRIVATE_KEY env var.
 */

export class BlockchainSigner {
    private wallet: ethers.Wallet;

    constructor() {
        const privateKey = process.env.SERVER_PRIVATE_KEY;
        if (!privateKey) {
            console.warn("SERVER_PRIVATE_KEY not set. Blockchain signing disabled.");
            this.wallet = ethers.Wallet.createRandom();
        } else {
            this.wallet = new ethers.Wallet(privateKey);
        }
    }

    get address(): string {
        return this.wallet.address;
    }

    /**
     * Sign a battle reward claim for a player.
     * @param playerAddress The player's wallet address
     * @param battleId The unique battle identifier (bytes32)
     * @param amount Reward amount in wei
     * @returns The signature hex string
     */
    async signBattleReward(
        playerAddress: string,
        battleId: string,
        amount: bigint
    ): Promise<string> {
        const messageHash = ethers.solidityPackedKeccak256(
            ["address", "bytes32", "uint256"],
            [playerAddress, battleId, amount]
        );
        return this.wallet.signMessage(ethers.getBytes(messageHash));
    }

    /**
     * Sign a PvP battle result for on-chain resolution.
     * @param battleId The battle identifier (bytes32)
     * @param winnerAddress The winner's wallet address
     * @returns The signature hex string
     */
    async signPvPResult(
        battleId: string,
        winnerAddress: string
    ): Promise<string> {
        const messageHash = ethers.solidityPackedKeccak256(
            ["bytes32", "address"],
            [battleId, winnerAddress]
        );
        return this.wallet.signMessage(ethers.getBytes(messageHash));
    }
}
