import { WebSocketServer, WebSocket } from "ws";
import { Matchmaking } from "./matchmaking";
import { BattleRoom } from "./battle_room";

const PORT = parseInt(process.env.PORT || "8080");

const wss = new WebSocketServer({ port: PORT });
const matchmaking = new Matchmaking();
const activeRooms = new Map<string, BattleRoom>();

interface PlayerConnection {
    ws: WebSocket;
    playerId: string;
    walletAddress?: string;
    party: any[];
}

const players = new Map<string, PlayerConnection>();

wss.on("connection", (ws: WebSocket) => {
    let playerId = "";

    ws.on("message", (raw: Buffer) => {
        try {
            const msg = JSON.parse(raw.toString());
            handleMessage(ws, msg, playerId, (id) => { playerId = id; });
        } catch (err) {
            ws.send(JSON.stringify({ type: "error", message: "Invalid message" }));
        }
    });

    ws.on("close", () => {
        if (playerId) {
            matchmaking.removePlayer(playerId);
            players.delete(playerId);
            // Notify battle room if player was in one
            for (const [roomId, room] of activeRooms) {
                if (room.hasPlayer(playerId)) {
                    room.handleDisconnect(playerId);
                    if (room.isFinished()) activeRooms.delete(roomId);
                }
            }
        }
    });
});

function handleMessage(
    ws: WebSocket,
    msg: any,
    playerId: string,
    setPlayerId: (id: string) => void
) {
    switch (msg.type) {
        case "register": {
            const id = msg.playerId || `player_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
            setPlayerId(id);
            players.set(id, {
                ws,
                playerId: id,
                walletAddress: msg.walletAddress,
                party: msg.party || [],
            });
            ws.send(JSON.stringify({ type: "registered", playerId: id }));
            break;
        }

        case "join_queue": {
            if (!playerId) return;
            const player = players.get(playerId);
            if (!player) return;

            matchmaking.addPlayer(playerId, player.party);

            // Try to match
            const match = matchmaking.tryMatch();
            if (match) {
                const room = new BattleRoom(match.player1, match.player2);
                activeRooms.set(room.roomId, room);

                const p1 = players.get(match.player1);
                const p2 = players.get(match.player2);

                if (p1 && p2) {
                    room.start(p1, p2);
                }
            } else {
                ws.send(JSON.stringify({ type: "queue_joined", position: matchmaking.queueSize() }));
            }
            break;
        }

        case "leave_queue": {
            if (playerId) matchmaking.removePlayer(playerId);
            ws.send(JSON.stringify({ type: "queue_left" }));
            break;
        }

        case "battle_action": {
            if (!playerId) return;
            for (const [, room] of activeRooms) {
                if (room.hasPlayer(playerId)) {
                    room.handleAction(playerId, msg.action);
                    break;
                }
            }
            break;
        }
    }
}

console.log(`Game Pikanad PvP Server running on port ${PORT}`);
