import { WebSocket } from "ws";
import { v4 as uuidv4 } from "uuid";
import { BattleValidator } from "./battle_validator";

interface PlayerState {
    playerId: string;
    ws: WebSocket;
    creature: {
        speciesName: string;
        level: number;
        hp: number;
        maxHp: number;
        attack: number;
        defense: number;
        speed: number;
        skills: Array<{ name: string; element: number; power: number; accuracy: number }>;
    };
    ready: boolean;
}

export class BattleRoom {
    readonly roomId: string;
    private player1: PlayerState | null = null;
    private player2: PlayerState | null = null;
    private currentTurn: string = "";
    private finished = false;
    private validator = new BattleValidator();

    constructor(p1Id: string, p2Id: string) {
        this.roomId = uuidv4();
    }

    hasPlayer(playerId: string): boolean {
        return (
            this.player1?.playerId === playerId ||
            this.player2?.playerId === playerId
        );
    }

    isFinished(): boolean {
        return this.finished;
    }

    start(p1: { ws: WebSocket; playerId: string; party: any[] }, p2: { ws: WebSocket; playerId: string; party: any[] }): void {
        // Use first creature from each player's party
        this.player1 = this._makePlayerState(p1);
        this.player2 = this._makePlayerState(p2);

        if (!this.player1 || !this.player2) {
            this.finished = true;
            return;
        }

        // Determine who goes first based on speed
        this.currentTurn =
            this.player1.creature.speed >= this.player2.creature.speed
                ? this.player1.playerId
                : this.player2.playerId;

        // Notify both players
        this._send(this.player1.ws, {
            type: "battle_start",
            roomId: this.roomId,
            yourCreature: this.player1.creature,
            opponentCreature: this.player2.creature,
            yourTurn: this.currentTurn === this.player1.playerId,
        });

        this._send(this.player2.ws, {
            type: "battle_start",
            roomId: this.roomId,
            yourCreature: this.player2.creature,
            opponentCreature: this.player1.creature,
            yourTurn: this.currentTurn === this.player2.playerId,
        });
    }

    handleAction(playerId: string, action: any): void {
        if (this.finished || playerId !== this.currentTurn) return;

        const attacker = playerId === this.player1?.playerId ? this.player1 : this.player2;
        const defender = playerId === this.player1?.playerId ? this.player2 : this.player1;
        if (!attacker || !defender) return;

        // Validate action
        if (!this.validator.validateAction(action, attacker.creature)) return;

        // Execute attack
        const skillIndex = action.skillIndex || 0;
        const skill = attacker.creature.skills[skillIndex];
        if (!skill) return;

        const result = this.validator.calculateDamage(
            attacker.creature,
            defender.creature,
            skill
        );

        defender.creature.hp = Math.max(0, defender.creature.hp - result.damage);

        // Broadcast result to both players
        const turnResult = {
            type: "turn_result",
            attacker: attacker.playerId,
            skillName: skill.name,
            damage: result.damage,
            effectiveness: result.effectiveness,
            hit: result.hit,
            attackerHp: attacker.creature.hp,
            defenderHp: defender.creature.hp,
        };

        this._send(this.player1!.ws, turnResult);
        this._send(this.player2!.ws, turnResult);

        // Check for battle end
        if (defender.creature.hp <= 0) {
            this._endBattle(attacker.playerId);
            return;
        }

        // Switch turn
        this.currentTurn = defender.playerId;
        this._send(attacker.ws, { type: "turn_change", yourTurn: false });
        this._send(defender.ws, { type: "turn_change", yourTurn: true });
    }

    handleDisconnect(playerId: string): void {
        if (this.finished) return;
        const winner =
            playerId === this.player1?.playerId
                ? this.player2?.playerId
                : this.player1?.playerId;
        if (winner) this._endBattle(winner);
    }

    private _endBattle(winnerId: string): void {
        this.finished = true;
        const result = {
            type: "battle_end",
            winner: winnerId,
            roomId: this.roomId,
        };
        if (this.player1) this._send(this.player1.ws, result);
        if (this.player2) this._send(this.player2.ws, result);
    }

    private _makePlayerState(p: { ws: WebSocket; playerId: string; party: any[] }): PlayerState | null {
        const first = p.party?.[0];
        if (!first) return null;

        return {
            playerId: p.playerId,
            ws: p.ws,
            creature: {
                speciesName: first.speciesName || "Unknown",
                level: first.level || 5,
                hp: first.hp || 44,
                maxHp: first.maxHp || 44,
                attack: first.attack || 14,
                defense: first.defense || 8,
                speed: first.speed || 12,
                skills: first.skills || [
                    { name: "Tackle", element: 4, power: 35, accuracy: 1.0 },
                ],
            },
            ready: true,
        };
    }

    private _send(ws: WebSocket, data: any): void {
        try {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify(data));
            }
        } catch {}
    }
}
