--MAX_FISHING_LEVEL = 15 --> main.lua
MIN_FISHING_DIFFICULTY = 15
MAX_FISHING_DIFFUCULTY = 150

LEGENDARY_MIN_LEVEL = 7

FISHING_INVENTORY_BAG = "Items"

FISHING_EQUIPMENT = {
	-- Coolingbags
	[68] = {level = 8},
	[67] = {level = 4},
	[66] = {level = 0},

	-- Fishingrods
	[65] = {level = 0},
	[98] = {level = 3},
	[99] = {level = 7},
	[100] = {level = 13},

	-- Baits
	[70] = {level = 3},
	[101] = {level = 5},
	[102] = {level = 11},

	-- Accessories
	[103] = 	{level = 1},
	[104] = 		{level = 10},
}

FISHING_BAGS = {
	[68] = {max = 65},
	[67] = {max = 25},
	[66] = {max = 15},
}

FISHING_RODS = {
	[65] = 			{baitSlots = 0, accessorieSlots = 0, difficultyReduction = 0, biteTimeReduction = 0},
	[98] = 			{baitSlots = 1, accessorieSlots = 0, difficultyReduction = 15, biteTimeReduction = 4000},
	[99] = 		{baitSlots = 1, accessorieSlots = 1, difficultyReduction = 25, biteTimeReduction = 7500},
	[100] = 	{baitSlots = 1, accessorieSlots = 1, difficultyReduction = 40, biteTimeReduction = 10000},
}

FISHING_BAITS = {
	[false] = 			{biteTimeReduction = 0, difficultyReduction = 0},
	[70] = 		{biteTimeReduction = 1000, difficultyReduction = 25},
	[101] = 	{biteTimeReduction = 5000, difficultyReduction = 5},
	[102] = 	{biteTimeReduction = 5000, difficultyReduction = 15},
}

FISHING_ACCESSORIES = {
	[false] = 			{biteTimeReduction = 0, difficultyReduction = 0, bobberBarHeightMultiplier = 1},
	[103] =		{biteTimeReduction = 1000, difficultyReduction = 0, bobberBarHeightMultiplier = 1, renderBobber = true},
	[104] =		{biteTimeReduction = 2500, difficultyReduction = 10, bobberBarHeightMultiplier = 1.1},
}

-- (level * 15)^2 // for i = 1, 15 do print(("[%s] = %s,"):format(i, math.floor((i*15)^(i>10 and 2.2 or 2)))) end
FISHING_LEVELS = {
	[1] = 225,
	[2] = 900,
	[3] = 2025,
	[4] = 3600,
	[5] = 5625,
	[6] = 8100,
	[7] = 11025,
	[8] = 14400,
	[9] = 18225,
	[10] = 22500,
	[11] = 75590,
	[12] = 91537,
	[13] = 109163,
	[14] = 128493,
	[15] = 149555,
}

FISHING_MOTIONTYPE = {
	MIXED = 0,
	DART = 1,
	SMOOTH = 2,
	SINKER = 3,
	FLOATER = 4,
}

FISHING_EVENT_ID = {
	EASTER = 1,
	HALLOWEEN = 2,
	CHRISTMAS = 3,
}

FISHING_DESERT_WATERHEIGHT = 13
FISHING_DESERT_WATER = {
	{l = -33, r = 82, u = 1590, d = 1464},
	{l = -80, r = -33, u = 1590, d = 1511},
	{l = -59, r = -33, u = 1511, d = 1489},
	{l = -44, r = -33, u = 1489, d = 1475},
	{l = -70, r = -59, u = 1511, d = 1500},
	{l = -50, r = -44, u = 1489, d = 1481},
}

FISHING_CAVE_WATERHEIGHT = 13
FISHING_CAVE_WATER = {
	{l = -425, r = -405, u = 1376, d = 1340}
}

FISHING_BAD_CATCH_MESSAGES = {
	"eine alte Brille",
	"eine rolle Toilettenpapier",
	"ein Stück rostiges Blech",
	"ein hauch von Tüll",
	"einen Stock",
	"eine Zahnbürste",
	"ein defektes Smartphone",
	"einen alten Hut",
	"eine Patronenhülse",
	"einen BH in Übergröße",
	"ein benutztes Kondom",
	"ein unbenutztes Kondom",
	"einen Lippenstift",
	"einen Stift",
	"Metallschrott",
	"die Unterhose von xXKing",
	"Socken von Stumpy",
	"einen nutzlosen SchrimpX",
	"einen PawnX Sticker",
	"eine alte Tastatur",
	"eine alte CD",
	"eine alte Maus",
	"eine leere Flasche Bier",
	"eine leere Bierdose",
	"eine leere Cola Dose",
	"ein volles Glas Wasser",
	"ein leeres Glas Wasser",
	"ein Blatt Papier",
	"eine alte Zeitung",
	"einen alten Schuh",
	"ein paar Turnschuhe",
	"einen kaputten Helm",
	"eine rostige alte Gießkanne",
	"ein leere Tüte",
	"einen #PewPorn.com Kugelschreiber",
	"nichts",
}

FISHING_BAD_CATCH_MESSAGES_SEWERS = {
	"einen dreckigen Schuh", 
	"einen Müllsack",
	"eine Bierflasche",
	"nichts",
}

FISHING_BAD_CATCH_ITEMS_SEWERS = 
{
	111,
	110,
	109,
}

function getFishingItemId(item)
	if not item or type(item) == "number" then return item end
	if localPlayer then return Inventory:getSingleton():getItemId(item) end
	return InventoryManager:getSingleton():getItemId(item)
end