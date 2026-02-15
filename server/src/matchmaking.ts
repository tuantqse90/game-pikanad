/** Simple FIFO matchmaking queue */

interface QueueEntry {
    playerId: string;
    party: any[];
    joinedAt: number;
}

export interface MatchResult {
    player1: string;
    player2: string;
}

export class Matchmaking {
    private queue: QueueEntry[] = [];

    addPlayer(playerId: string, party: any[]): void {
        // Don't add duplicates
        if (this.queue.find((e) => e.playerId === playerId)) return;
        this.queue.push({ playerId, party, joinedAt: Date.now() });
    }

    removePlayer(playerId: string): void {
        this.queue = this.queue.filter((e) => e.playerId !== playerId);
    }

    tryMatch(): MatchResult | null {
        if (this.queue.length < 2) return null;

        const p1 = this.queue.shift()!;
        const p2 = this.queue.shift()!;

        return { player1: p1.playerId, player2: p2.playerId };
    }

    queueSize(): number {
        return this.queue.length;
    }
}
