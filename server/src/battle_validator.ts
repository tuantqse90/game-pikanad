/** Server-side battle validation and damage calculation */

// Type effectiveness matrix (same as GDScript version)
const TYPE_CHART: Record<number, Record<number, number>> = {
    0: { 0: 1.0, 1: 0.67, 2: 1.5, 3: 1.0, 4: 1.0 },   // Fire
    1: { 0: 1.5, 1: 1.0, 2: 0.67, 3: 1.0, 4: 1.0 },     // Water
    2: { 0: 0.67, 1: 1.5, 2: 1.0, 3: 1.0, 4: 1.0 },      // Grass
    3: { 0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.5 },       // Wind
    4: { 0: 1.0, 1: 1.0, 2: 1.0, 3: 0.67, 4: 1.0 },      // Earth
};

interface CreatureState {
    level: number;
    hp: number;
    maxHp: number;
    attack: number;
    defense: number;
    speed: number;
    skills: Array<{ name: string; element: number; power: number; accuracy: number }>;
}

interface Skill {
    name: string;
    element: number;
    power: number;
    accuracy: number;
}

interface DamageResult {
    damage: number;
    effectiveness: number;
    hit: boolean;
}

export class BattleValidator {
    validateAction(action: any, creature: CreatureState): boolean {
        if (!action || typeof action.skillIndex !== "number") return false;
        if (action.skillIndex < 0 || action.skillIndex >= creature.skills.length) return false;
        return true;
    }

    calculateDamage(
        attacker: CreatureState,
        defender: CreatureState,
        skill: Skill
    ): DamageResult {
        // Hit check
        const hit = Math.random() <= skill.accuracy;
        if (!hit) return { damage: 0, effectiveness: 1.0, hit: false };

        // Damage formula (matches GDScript)
        const base = skill.power * (attacker.attack / defender.defense);
        const effectiveness = this.getEffectiveness(skill.element, 0); // TODO: need defender element
        const variance = 0.85 + Math.random() * 0.3;
        const damage = Math.max(1, Math.floor(base * effectiveness * variance * 0.5));

        return { damage, effectiveness, hit: true };
    }

    getEffectiveness(atkElement: number, defElement: number): number {
        return TYPE_CHART[atkElement]?.[defElement] ?? 1.0;
    }
}
