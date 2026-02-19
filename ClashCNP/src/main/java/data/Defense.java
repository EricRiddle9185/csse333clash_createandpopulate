package data;

public class Defense extends BuildingType {
	public int damage;
	public int attackRate;
	public String damageType;
	public String attacksMovementType;
	
	public Defense(BuildingType bt, int damage, int attackRate, String damageType, String attacksMovementType) {
		super(bt.name, bt.level, bt.buildTime, bt.maxHealth, bt.size, bt.goldCost, bt.elixirCost);
		this.damage = damage;
		this.attackRate = attackRate;
		this.damageType = damageType;
		this.attacksMovementType = attacksMovementType;
	}
}
