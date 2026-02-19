package data;

public class TroopType {
    public int id;
    public String name;
    public int level;
    public int damage;
    public int attackRate;
    public String damageType;
    public int size;
    public String movementType;
    public int movementSpeed;
    public int goldCost;
    public int elixirCost;

    public TroopType(int id, String name, int level, int damage, int attackRate, String damageType, int size, String movementType, int movementSpeed, int goldCost, int elixirCost) {
        this.id = id;
        this.name = name;
        this.level = level;
        this.damage = damage;
        this.attackRate = attackRate;
        this.damageType = damageType;
        this.size = size;
        this.movementType = movementType;
        this.movementSpeed = movementSpeed;
        this.goldCost = goldCost;
        this.elixirCost = elixirCost;
    }
}
