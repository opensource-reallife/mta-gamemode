PROJECT_NAME = "OpenReallife"
PROJECT_VERSION = nil
DISABLE_SENTRY = true
DISABLE_INFLUX = true
DISABLE_MIGRATION = true

PRIVATE_DIMENSION_SERVER = 65535 -- This dimension should not be used for playing
PRIVATE_DIMENSION_CLIENT = 2 -- This dimension should be used for things which
							 -- happen while the player is in PRIVATE_DIMENSION on the server

INGAME_WEB_PATH = "https://ingame.openreallife.net"
PICUPLOAD_PATH = "https://picupload.pewx.de"

if DEBUG then
	INGAME_WEB_PATH = "https://ingame.openreallife.net"
end

DOMAINS = {"openreallife.net", "forum.openreallife.net", INGAME_WEB_PATH:gsub("https://", ""), PICUPLOAD_PATH:gsub("https://", ""), "i.imgur.com", "cp.openreallife.net"}
FORUM_MAX_CONNECTION_ATTEMPTS = 4

-- LEVELS
MAX_JOB_LEVEL = 10
MAX_WEAPON_LEVEL = 10
MAX_VEHICLE_LEVEL = 10
MAX_SKIN_LEVEL = 10
MAX_FISHING_LEVEL = 15
MAX_WANTED_LEVEL = 6

-- WANTED AMOUNTS
WANTED_AMOUNT_VENDINGMACHINE = 1
WANTED_AMOUNT_HOUSEROB = 2
WANTED_AMOUNT_WEEDBEGGAR = 2
WANTED_AMOUNT_MURDER = 3
WANTED_AMOUNT_MURDER_BEGGAR = 3
WANTED_AMOUNT_MURDER_TOLLSTATION = 3
WANTED_AMOUNT_AREA69 = 6

-- EVENTS:
local function getEasterDate(year)
    local a = year % 19
    local b = math.floor(year / 100)
    local c = year % 100
    local d = math.floor(b / 4)
    local e = b % 4
    local f = math.floor((b + 8) / 25)
    local g = math.floor((b - f + 1) / 3)
    local h = (19 * a + b - d - g + 15) % 30
    local i = math.floor(c / 4)
    local k = c % 4
    local l = (32 + 2 * e + 2 * i - h - k) % 7
    local m = math.floor((a + 11 * h + 22 * l) / 451)
    local month = math.floor((h + l - 7 * m + 114) / 31)
    local day = ((h + l - 7 * m + 114) % 31) + 1

    return {["day"] = day, ["month"] = month}
end

EVENT_EASTER_START_DAY = 0
local function isEasterEventActive()
    local rt = getRealTime()
    local year = rt.year + 1900
    local easterDate = getEasterDate(year) -- Ostersonntag

    local easterTimestamp = os.time({
        year = year,
        month = easterDate.month,
        day = easterDate.day,
        hour = 0
    })

    local eventStart = easterTimestamp - (7 * 24 * 60 * 60)
    local eventEnd = easterTimestamp + (7 * 24 * 60 * 60)
	EVENT_EASTER_START_DAY = (os.date("*t", eventStart)).yday

    local now = os.time({
        year = year,
        month = rt.month + 1,
        day = rt.monthday,
        hour = rt.hour,
        min = rt.minute,
        sec = rt.second
    })

    return now >= eventStart and now <= eventEnd
end

EVENT_EASTER = isEasterEventActive()
EVENT_EASTER_SLOTMACHINES_ACTIVE = EVENT_EASTER
EVENT_HALLOWEEN = (getRealTime().month == 9 and (getRealTime().monthday >= 24 and getRealTime().monthday <= 31)) or (getRealTime().month == 10 and (getRealTime().monthday >= 1 and getRealTime().monthday <= 7))
EVENT_CHRISTMAS = getRealTime().month == 11 -- quests, mostly REMEMBER TO ADD/REMOVE <vrpfile src="files/models/skins/kobold.txd" /> AND <vrpfile src="files/models/skins/kobold.dff" /> TO META.XML DUE TO BIG FILE SIZE
EVENT_CHRISTMAS_MARKET = EVENT_CHRISTMAS and (getRealTime().monthday >= 6 and getRealTime().monthday <= 26) -- determines whether the christmas market is enabled at pershing square (shops, ferris wheel, wheels of fortune)
SNOW_SHADERS_ENABLED = getRealTime().month == 11 or getRealTime().month == 0 -- disable them during summer time
FIREWORK_ENABLED = true -- can users use firework?
FIREWORK_SHOP_ACTIVE = getRealTime().month == 11 and (getRealTime().monthday >= 25 and getRealTime().monthday <= 31) -- can users buy firework at the user meetup point?

-- PAYDAY:
PAYDAY_NOOB_BONUS = 500 -- dollar
PAYDAY_NOOB_BONUS_MAX_PLAYTIME = 50 -- hours
PAYDAY_UNEMPLOYED = 500

--TEXTURES:
TEXTURE_STATUS = {
	["Testing"] = 0,
	["Pending"] = 1,
	["Active"] = 2,
	["Declined"] = 3
}
local status = {}
for k, v in pairs(TEXTURE_STATUS) do
	status[k] = v
	status[v] = k
end
TEXTURE_STATUS = status

--ALCOHOL:
MAX_ALCOHOL_LEVEL = 6
ALCOHOL_LOSS_INTERVAL =  5*60 -- IN SECONDS
ALCOHOL_LOSS = 0.5 -- every 10 Minutes

--JOB_LEVELS:
JOB_LEVEL_PIZZA = 0
JOB_LEVEL_SWEEPER = 0
JOB_LEVEL_LOGISTICAN = 2
JOB_LEVEL_TRASHMAN = 2
JOB_LEVEL_TREASURESEEKER = 4
JOB_LEVEL_FORKLIFT = 3
JOB_LEVEL_LUMBERJACK = 6
JOB_LEVEL_HELITRANSPORT = 5
JOB_LEVEL_FARMER = 8
JOB_LEVEL_GRAVEL = 7
JOB_LEVEL_SERVICETECHNICIAN = 1
JOB_LEVEL_BOXER = 10

BLIP_CATEGORY = {
	Default = "Allgemein",
	Shop = "Shops",
	Job = "Arbeitsstellen",
	Faction = "Fraktions-Basen",
	Company = "Unternehmenssitze",
	VehicleMaintenance = "Fahrzeug-Unterhaltung",
	Leisure = "Freizeit",
	Other = "Anderes",
}

BLIP_COLOR_CONSTANTS = {
	Red = {200, 0, 0},
	Orange = {255, 150, 0},
	Yellow = {200, 200, 0},
	Green = {20, 255, 50},
	Blue = {20, 70, 200},
}

BLIP_CATEGORY_ORDER = {
	BLIP_CATEGORY.Default, BLIP_CATEGORY.Job, BLIP_CATEGORY.Faction, BLIP_CATEGORY.Company, BLIP_CATEGORY.VehicleMaintenance, BLIP_CATEGORY.Shop, BLIP_CATEGORY.Leisure, BLIP_CATEGORY.Other
}

--USER RANKS:
RANK = {}
RANK[-1] = "Banned"
RANK[0] = "User"
RANK[1] = "Ticketsupporter"
RANK[2] = "Clanmember"
RANK[3] = "Supporter"
RANK[4] = "Moderator"
RANK[5] = "Administrator"
RANK[6] = "Servermanager"
RANK[7] = "Developer"
RANK[8] = "StellvProjektleiter"
RANK[9] = "Projektleiter"


RANKSCOREBOARD = {}
RANKSCOREBOARD[-1] = "Banned"
RANKSCOREBOARD[0] = "User"
RANKSCOREBOARD[1] = "Ticketsupporter"
RANKSCOREBOARD[2] = "Clanmember"
RANKSCOREBOARD[3] = "Supporter"
RANKSCOREBOARD[4] = "Moderator"
RANKSCOREBOARD[5] = "Administrator"
RANKSCOREBOARD[6] = "Servermanager"
RANKSCOREBOARD[7] = "Developer"
RANKSCOREBOARD[8] = "Stellv. Projektleiter"
RANKSCOREBOARD[9] = "Projektleiter"

RANKCOLORS = {}
RANKCOLORS[-1] = {0, 0, 0}
RANKCOLORS[0] = {255, 255, 255}
RANKCOLORS[1] = {120, 120, 120}
RANKCOLORS[2] = {210, 40, 100}
RANKCOLORS[3] = {200, 170, 40}
RANKCOLORS[4] = {0, 80, 200}
RANKCOLORS[5] = {60, 185, 100}
RANKCOLORS[6] = {235, 130, 10}
RANKCOLORS[7] = {160, 65, 180}
RANKCOLORS[8] = {200, 75, 60}
RANKCOLORS[9] = {180, 60, 60}

local r2 = {}
for k, v in pairs(RANK) do
	r2[k] = v
	r2[v] = k
end
RANK = r2

--ADMIN PERMISSIONS:
ADMIN_RANK_PERMISSION = {

	--player punish
	["freeze"] = RANK.Supporter,
	["rkick"] = RANK.Supporter,
	["prison"] = RANK.Supporter,
	["offlinePrison"] = RANK.Supporter,
	["unprison"] = RANK.Moderator,
	["offlineUnPrison"] = RANK.Moderator,
	["warn"] = RANK.Supporter,
	["offlineWarn"] = RANK.Supporter,
	["removeWarn"] = RANK.Administrator,
	["removeOfflineWarn"] = RANK.Administrator,
	["timeban"] = RANK.Supporter,
	["permaban"] = RANK.Supporter,
	["offlineTimeban"] = RANK.Supporter,
	["offlinePermaban"] = RANK.Supporter,
	["offlineUnban"] = RANK.Administrator,
	["throwaway"] = RANK.Moderator,
	["modsBan"] = RANK.Supporter,
	["removeModsBan"] = RANK.Administrator,
	["offlineModsBan"] = RANK.Supporter,
	["offlineRemoveModsBan"] = RANK.Administrator,

	--admin general
	["event"] = RANK.Moderator,
	["eventMoneyWithdraw"] = RANK.Administrator,
	["eventMoneyDeposit"] = RANK.Supporter,
	["vehicleTexture"] = RANK.Moderator,
	["spect"] = RANK.Supporter,
	["aduty"] = RANK.Ticketsupporter,
	["smode"] = RANK.Ticketsupporter,
	["adminAnnounce"] = RANK.Supporter,
	["clearchat"] = RANK.Supporter,
	["clearAd"] = RANK.Supporter,
	["supermanFly"] = RANK.Moderator, -- flying supporter
	["nickchange"] = RANK.Moderator,
	["offlineNickchange"] = RANK.Moderator,
	["loginFix"] = RANK.Moderator,
	["syncForum"] = RANK.Supporter,
	["freeVip"] = RANK.Moderator,
	["cinemaRemoveLobby"] = RANK.Supporter,
	["openAdminMenu"] = RANK.Ticketsupporter,
	["disablereg"] = RANK.Servermanager, --disablereg, enablereg

	--group management
	["setFaction"] = RANK.Administrator,
	["setCompany"] = RANK.Administrator,
	["resetAction"] = RANK.Moderator,
	["playerHistory"] = RANK.Supporter,
	["respawnFaction"] = RANK.Ticketsupporter, -- respawn whole faction
	["respawnCompany"] = RANK.Ticketsupporter, -- respawn whole company

	--teleport
	["direction"] = RANK.Supporter, -- Up Down Left Right
	["mark"] = RANK.Supporter, -- also gotomark
	["gethere"] = RANK.Clanmember,
	["goto"] = RANK.Clanmember,
	["tp"] = RANK.Supporter,
	["gotocords"] = RANK.Supporter,

	--vehicle interaction
	["checkOverlappingVehicles"] = RANK.Administrator,
	["respawnRadius"] = RANK.Supporter,
	["showVehicles"] = RANK.Supporter,
	["showGroupVehicles"] = RANK.Supporter,
	["toggleVehicleHandbrake"] = RANK.Moderator,
	["respawnVehicle"] = RANK.Supporter, -- respawn per click
	["parkVehicle"] = RANK.Supporter, -- set spawn position
	["repairVehicle"] = RANK.Supporter, -- repair per click
	["despawnVehicle"] = RANK.Supporter, -- despawn
	["flipVehicle"] = RANK.Supporter, -- despawn
	["deleteVehicle"] = RANK.Administrator, -- permanently destroy vehicle
	["looseVehicleHandbrake"] = RANK.Supporter,
	["endVehicleSale"] = RANK.Supporter, -- also for ending rent
	["editVehicleGeneral"] = RANK.Administrator, -- this is used to just open the window itself
	["editVehicleModel"] = RANK.Administrator,
	["editVehicleOwnerType"] = RANK.Administrator,
	["editVehicleOwnerID"] = RANK.Administrator,
	["editVehicleTunings"] = RANK.Administrator,
	["editVehicleHandling"] = RANK.Administrator, -- handling editor
	["editVehicleTexture"] = RANK.Developer, --override textures without visiting the texture shop


	--development
	["cookie"] = RANK.Developer, -- give that man a cookie
	["showDebugElementView"] = RANK.Administrator, --F10 view
	["runString"] = RANK.Servermanager, --drun, dcrun, dpcrun
	["seeRunString"] = RANK.Administrator, --chat and console outputs from above

	--World Items (e.g. Barricade)
	["moveWorldItem"] 				= RANK.Supporter,
	["deleteWorldItem"] 			= RANK.Supporter,
	["showWorldItemInformation"] 	= RANK.Supporter,

	--server edit tools
	["editHouseGeneral"] = RANK.Supporter, -- this is used to just open the window itself
	["editHouseInterior"] = RANK.Administrator,
	["freeHouse"] = RANK.Administrator, -- free house from owner, tenants and house bank account money
	["endHouseSale"] = RANK.Supporter,

	["createSkyscraper"] = RANK.Developer, -- also includes deleting
	["addHouseToSkyscraper"] = RANK.Developer, -- also includes removing 

	["addVehicleToFCShop"] = RANK.Developer,

	["openGates"] = RANK.Administrator,
	
	["pedMenu"] = RANK.Administrator,
	["fireMenu"] = RANK.Supporter,
	["toggleFire"] = RANK.Supporter,
	["editFire"] = RANK.Administrator,
	["eventGangwarMenu"] = RANK.Supporter,
	["transactionMenu"] = RANK.Administrator,
	["multiAccountMenu"] = RANK.Supporter, -- supporters are only allowed to see, administrators are allowed to create and delete multiaccounts
	["serialAccountMenu"] = RANK.Supporter,
	["vehicleMenu"] = RANK.Moderator,
	["leaderBanMenu"] = RANK.Supporter, -- supporters are only allowed to see, administrators are allowed to create and delete leaderbans

	["openMapEditor"] = RANK.Moderator,
	["createNewMap"] = RANK.Moderator,
	["setMapStatus"] = RANK.Moderator,
	["remoteOpenMapEditor"] = RANK.Administrator,
	["createNewCategory"] = RANK.Administrator,
	--keypad-system
	["placeKeypadObjects"] = RANK.Administrator, -- ItemKeyPad, ItemEntrance, ItemDoor
}

GroupRank = {
	Normal = 0,
	Rank1 = 1,
	Rank2 = 2,
	Rank3 = 3,
	Rank4 = 4,
	Manager = 5,
	Leader = 6
}

FactionRank = {
	Normal = 0,
	Rank3 = 3,
	Rank4 = 4,
	Manager = 5,
	Leader = 6
}

CompanyRank = {
	Normal = 0,
	Manager = 4,
	Leader = 5
}

OBJECT_DELETE_MIN_RANK = 4 -- faction/company/group rank to destroy WorldItems (i.e. not put them into their inventory)

local r3 = {}
for k, v in pairs(GroupRank) do
	r3[k] = v
	r3[v] = k
end
GroupRank = r3

Crime = {
	Kill = {id = 1, text = "Mord", maxwanted = 4, maxdistance = 1500},
	Hotwire = {id = 2, text = "Fahrzeug kurzgeschlossen", maxwanted = 2, maxdistance = 400},
	BankRobbery = {id = 3, text = "Banküberfall", maxwanted = 6, maxdistance = math.huge},
	JailBreak = {id = 4, text = "Gefängnisausbruch", maxwanted = 4, maxdistance = math.huge},
	PlacingBomb = {id = 5, text = "Legen einer Bombe", maxwanted = 6, maxdistance = 5000},
	HouseRob = {id = 6, text = "Einbruch", maxwanted = 3, maxdistance = math.huge},
	ShopRob = {id = 7, text = "Raubüberfall", maxwanted = 5, maxdistance = math.huge}
}

AMMUNATION_APP_MULTIPLICATOR = 1.5
AmmuNationInfo = {
	[30] = { -- AK-47
		Magazine = {price=40,amount=30},
		Weapon = 700
	},
	[31] = { -- M4A1
		Magazine = {price=50,amount=50},
		Weapon = 750
	},
	[29] = { -- MP5
		Magazine = {price=30,amount=30},
		Weapon = 450
	},
	[25] = { -- Shotgun
		Magazine = {price=5,amount=1},
		Weapon = 300
	},
	[33] = { -- Rifle
		Magazine = {price=5,amount=1},
		Weapon = 500
	},
	[22] = { -- Pistol
		Magazine = {price=15,amount=17},
		Weapon = 250
	},
	[24] = { -- Desert Eagle
		Magazine = {price=30,amount=7},
		Weapon = 500
	},
	[1] = { -- Brass Knuckles
		Weapon = 50
	},
	[0] = { -- Armor
		Weapon = 150
	},
}

DEFAULT_GANGAREA_RESOURCES = 500
SprayWallData = {
	{wallPosition = Vector3(2512.3999, -1683.4, 13.9), 	wallRotation = 129},
	{wallPosition = Vector3(2080.5, -1597.1, 13.8), 	wallRotation = 269.5},
	{wallPosition = Vector3(1758.7, -1938.9, 14), 		wallRotation = 0},
	{wallPosition = Vector3(1761.5, -1350.2, 16), 		wallRotation = 0},
	{wallPosition = Vector3(1913.1, -1361.5, 14), 		wallRotation = 267},
	{wallPosition = Vector3(1959.6, -1173.6, 20.4), 	wallRotation = 179.5},
	{wallPosition = Vector3(2215.5, -1173.9, 26.1), 	wallRotation = 89.75},
	{wallPosition = Vector3(2768.2, -1625, 11.3), 		wallRotation = 0},
	{wallPosition = Vector3(1237.9, -916.40002, 43.1), 	wallRotation = 280},
	{wallPosition = Vector3(382.70001, -1875.7, 8.2), 	wallRotation = 92},
	{wallPosition = Vector3(1065.2, -1617.6, 21.1), 	wallRotation = 0},
	{wallPosition = Vector3(474.60001, -1517.6, 20.8), 	wallRotation = 0},
	{wallPosition = Vector3(2808.8999, -1426.1, 40.5), 	wallRotation = 270.75},
	{wallPosition = Vector3(2822.2, -2383.2, 12.5), 	wallRotation = 180.25},
	{wallPosition = Vector3(2274.7, -68.9, 27), 		wallRotation = 0},
	{wallPosition = Vector3(731.29999, -1337.2, 13.9), 	wallRotation = 0},
	{wallPosition = Vector3(1084.5, -1219.5, 18.2), 	wallRotation = 0},
	{wallPosition = Vector3(2761.8999, -2015.6, 13.9), 	wallRotation = 0},
}

TURFING_STOPREASON_LEAVEAREA = 1
TURFING_STOPREASON_NEWOWNER = 2
TURFING_STOPREASON_DEFENDED = 3

SkinShopLevel = {1, 3, 5, 7, 9, 10}
SkinInfo = {
	-- skinId -- skinName -- skinPrice -- skinLevel
    [0] = {"CJ", 10000, 0},

    [1] = {"Offenes Hemd", 50, 1},
	[2] = {"Weißer Hut", 100, 1},
	[7] = {"Jeans-Jacke", 50, 1},
	[9] = {"Brauner Anzug", 250, 1},
	[10] = {"Alte Dame", 50, 1},
	[11] = {"Kellnerin", 150, 1},
	[12] = {"Schwarzes Kleid", 150, 1},
	[14] = {"Hawaii-Shirt", 100, 1},
	[15] = {"Kariertes Hemd", 50, 1},
	[17] = {"Business", 200, 1},
	[19] = {"Rapper", 50, 1},
	[20] = {"Gelbes Shirt", 50, 1},
	[21] = {"Blau kariertes Hemd", 150, 1},
	[22] = {"Rapper 2", 100, 1},
	[23] = {"Skater", 50, 1},
	[30] = {"Tanktop mit Kreuz", 100, 1},
	[33] = {"Trenchcoat", 100, 1},
	[98] = {"Polo-Hemd, Jeans", 200, 1},
	[130] = {"Alte Dame mit Zöpfen", 50, 1},
	[131] = {"Countrygirl", 100, 1},
	[157] = {"Farmerin, barfuß", 50, 1},
	[158] = {"Cowboy", 100, 1},
	[159] = {"Farmer", 50, 1},
	[161] = {"Cowboy 2", 100, 1},
	[170] = {"Rotes T-Shirt", 100, 1},
	[182] = {"Rentner mit Bierbauch", 50, 1},
	[183] = {"Braun kariertes Hemd", 50, 1},
	[184] = {"Blau-weiß-schwarzes Shirt", 100, 1},
	[190] = {"Frau mit schulterfreiem Top", 100, 1},
	[196] = {"Alte Dame mit Dutt", 50, 1},
	[197] = {"Alte Dame mit Kopftuch", 50, 1},
	[198] = {"Cowgirl", 100, 1},
	[201] = {"Truckerin", 100, 1},
	[202] = {"Trucker", 100, 1},
	[206] = {"Olivfarbenes Shirt", 100, 1},
	[207] = {"Frau, bauchfrei", 150, 1},
	[217] = {"Graues T-Shirt", 150, 1},
	[218] = {"Alte Dame 2", 50, 1},
	[226] = {"Frau mit Beinstulpen", 200, 1},
	[232] = {"Alte Dame 3", 50, 1},
	[250] = {"Langärmelig, olivgrünes T-Shirt", 150, 1},

	[18] = {"Strandboy", 500, 3},
	[28] = {"Tank Top", 400, 3},
	[29] = {"Hoodie", 400, 3},
	[31] = {"Älteres Cowgirl", 400, 3},
	[32] = {"Augenklappe", 400, 3},
	[34] = {"Cowboy 3", 500, 3},
	[39] = {"Alte Dame 4", 300, 3},
	[40] = {"Rotes Kleid", 400, 3},
	[43] = {"Daddy Cool", 1000, 3},
	[46] = {"Weißes Hemd, Kette", 500, 3},
	[47] = {"Kakifarbenes Hemd", 500, 3},
	[48] = {"Blau-weiß gestreiftes Hemd", 500, 3},
	[59] = {"Beige-braun gestreiftes Hemd", 500, 3},
	[77] = {"Alte Dame mit Hut", 300, 3},
	[91] = {"Weißes Kleid", 600, 3},
	[101] = {"Parker-Jacke", 500, 3},
	[128] = {"Trucker, schulterlange Haare", 400, 3},
	[129] = {"Alte Dame mit Sonnenbrille", 400, 3},
	[132] = {"Rentner mit Stirnband", 500, 3},
	[133] = {"Trucker, rote Cap", 500, 3},
	[142] = {"Festtagsgewand (Afrikanisch)", 600, 3},
	[143] = {"Sonnenbrille, blaue Jacke", 500, 3},
	[144] = {"Maske, Afro", 500, 3},
	[147] = {"Business-Anzug, grau", 700, 3},
	[160] = {"Farmer, Glatze mit Vollbart", 300, 3},
	[176] = {"Leichter Vollbart, blaues Shirt", 600, 3},
	[177] = {"Undercut, blaues Shirt", 600, 3},
	[193] = {"Frau mit schulterfreiem Top", 500, 3},
	[199] = {"Frau mit Blumenkleid", 400, 3},
	[210] = {"Graues Hemd", 400, 3},
	[213] = {"Elvis-Imitator", 500, 3},
	[220] = {"Sommerliche Festtagskleidung", 600, 3},
	[223] = {"Gangster mit Goldkette", 800, 3},
	[225] = {"Oberteil mit chaotischem Muster", 500, 3},
	[229] = {"Weißes Hemd mit Palmen", 400, 3},
	[231] = {"Renterin mit Dutt", 600, 3},
	[262] = {"Rentner mit Bierbauch 2", 600, 3},

	[26] = {"Camper", 1500, 5},
	[35] = {"Anglerhut", 2000, 5},
	[36] = {"Baseball Cap", 2500, 5},
	[37] = {"Baseball Cap 2", 2500, 5},
	[38] = {"Golferin", 3000, 5},
	[44] = {"Schnurrbart, blau kariertes Hemd", 3000, 5},
	[45] = {"Grüne Badehose", 1500, 5},
	[53] = {"Golferin 2", 3000, 5},
	[54] = {"Frau mit brauner Jacke", 1500, 5},
	[55] = {"Gestreifter Rock", 1500, 5},
	[56] = {"Rock, grünes Oberteil", 1500, 5},
	[58] = {"Zinkrotes Hemd (Asiate)", 2000, 5},
	[62] = {"Opa im Schlafanzug", 3500, 5},
	[64] = {"Augenbrauen, braune Stiefeletten", 1500, 5},
	[88] = {"Alte Dame mit rotem Oberteil", 3000, 5},
	[89] = {"Alte Dame mit hellblauem Kleid", 2000, 5},
	[94] = {"Golfer", 3500, 5},
	[97] = {"Rote Badehose", 2500, 5},
	[148] = {"Frau mit türkisfarbenem Anzug", 4000, 5},
	[179] = {"Grünes Tank Top, Dogtags", 2500, 5},
	[180] = {"Basketball-Shirt", 2000, 5},
	[185] = {"Gesteiftes Hemd, schwarze Hose", 3500, 5},
	[188] = {"Grünes T-Shirt", 3000, 5},
	[194] = {"Kellnerin 2", 4000, 5},
	[214] = {"Griechisches Kleid", 4500, 5},
	[215] = {"Weiße Hose, gelbes Oberteil", 4000, 5},
	[216] = {"Frau mit lavendelfarbenem Kleid", 3500, 5},
	[221] = {"Weißes Hemd", 3500, 5},
	[222] = {"Schwarz-buntes Polohemd", 3500, 5},
	[224] = {"Restaurantbesitzerin", 5000, 5},
	[227] = {"Business-Anzug, blaue Krawatte", 5000, 5},
	[235] = {"Rentner mit Cordhose", 3000, 5},
	[240] = {"BWL Justus", 4500, 5},
	[243] = {"Rotes Oberteil", 2500, 5},
	[258] = {"Beige kariertes Hemd", 3500, 5},
	[259] = {"Kurze Hose, kariertes Hemd", 3000, 5},
	[261] = {"Trucker mit Ziegenbart", 3000, 5},
	[263] = {"Schwarz-buntes Kleid", 4000, 5},
	[302] = {"Waffenverkäufer", 3500, 5},

	[24] = {"Los Santos Jacke", 20000, 7},
	[25] = {"College-Jacke", 17500, 7},
	[41] = {"Trainingsanzug", 10000, 7},
	[51] = {"Radfahrer", 20000, 7},
	[52] = {"Radfahrer 2", 20000, 7},
	[63] = {"Latexstrümpfe", 22500, 7},
	[66] = {"College-Jacke 2", 17500, 7},
	[85] = {"Streetworkerin", 15000, 7},
	[90] = {"Crop Top", 22500, 7},
	[95] = {"Armer Rentner", 15000, 7},
	[96] = {"Basketball-Outfit", 15000, 7},
	[99] = {"Radfahrer 3", 20000, 7},
	[138] = {"Weißer Bikini", 22500, 7},
	[139] = {"Gelber Bikini", 22500, 7},
	[140] = {"Roter Bikini", 22500, 7},
	[154] = {"Blaue Badehose", 17500, 7},
	[168] = {"Frittenbude", 15000, 7},
	[187] = {"Business-Anzug, blau gestreift", 25000, 7},
	[189] = {"Kellner", 22500, 7},
	[219] = {"Sekretärin", 25000, 7},
	[234] = {"Rentner mit Sonnenbrille", 17500, 7},
	[236] = {"Rentner mit Schnurrbart", 20000, 7},
	[238] = {"Augenbrauen, rotes Outfit", 20000, 7},

	[16] = {"Lufttransportmitarbeiter", 90000, 9},
	[67] = {"Gangster mit weißem Oberteil", 60000, 9},
	[68] = {"Pfarrer", 80000, 9},
	[92] = {"Skaterin", 75000, 9},
	[151] = {"Jeansrock, schwarze Brille", 60000, 9},
	[152] = {"Zöpfe, rot karierter Rock", 50000, 9},
	[209] = {"Donutladen", 90000, 9},
	[228] = {"Business-Anzug, schwarz", 100000, 9},
	[233] = {"Weißes Shirt, Jeans", 70000, 9},
	[241] = {"Afro mit Bierbauch", 60000, 9},
	[245] = {"Weißes Top, roter Rock", 50000, 9},
	[246] = {"Domina 2", 70000, 9},
	[249] = {"Zuhälter", 85000, 9},
	[251] = {"Beachwatch", 80000, 9},
	[256] = {"4 Zöpfe", 60000, 9},
	[307] = {"Blau-weiß gestreiftes Hemd 2", 75000, 9},

	[80] = {"Boxer, rotes Outfit", 350000, 10},
	[81] = {"Boxer, blaues Outfit", 350000, 10},
	[82] = {"Elvis-Kostüm, grau", 250000, 10},
	[83] = {"Elvis-Kostüm, weiß", 250000, 10},
	[84] = {"Elvis-Kostüm, blau", 250000, 10},
	[156] = {"Jeve Stobs", 250000, 10},
	[162] = {"Alabamaboy", 200000, 10},
	[167] = {"Taste The Cock", 500000, 10},
	[205] = {"Kill Your Hunger", 500000, 10},
	[264] = {"Fetter Clown", 500000, 10},
	[303] = {"Geschäftsmann", 500000, 10},
	[306] = {"Elektronikexperte", 250000, 10},
	[308] = {"Russischer Waffenhändler", 350000, 10},

	-- event skins
	[244] = {"Weihnachtsmann", math.huge, -1},
	[310] = {"Zombie", math.huge, -1},

	-- other skins
	[260] = {"Construction Worker", math.huge, -1}, --Adminskin
	[155] = {"Pizzalieferant", math.huge, -1},
	[78] = {"Obdachloser", math.huge, -1},
	[79] = {"Obdachloser", math.huge, -1},
	[134] = {"Obdachloser", math.huge, -1},
	[135] = {"Obdachloser", math.huge, -1},
	[136] = {"Obdachloser", math.huge, -1},
	[137] = {"Obdachloser", math.huge, -1},
	[200] = {"Obdachloser", math.huge, -1},
	[212] = {"Obdachloser", math.huge, -1},
	[230] = {"Obdachloser", math.huge, -1},
	[239] = {"Obdachloser", math.huge, -1},
	[178] = {"Domina", math.huge, -1},

	--unused skins
	[27] = {"Construction Worker", math.huge, -1},
	[57] = {"Oriental Ped", math.huge, -1},
	[60] = {"Normal Ped", math.huge, -1},
	[69] = {"Normal Ped", math.huge, -1},
	[72] = {"Hippy", math.huge, -1},
	[75] = {"Prostitute", math.huge, -1},
	[87] = {"Stripper", math.huge, -1},
	[145] = {"Crack Maker", math.huge, -1},
	[146] = {"Crack Maker", math.huge, -1},
	[150] = {"Businesswoman", math.huge, -1},
	[153] = {"Construction Worker", math.huge, -1},
	[171] = {"Blackjack Dealer", math.huge, -1},
	[172] = {"Casino croupier", math.huge, -1},
	[203] = {"Karate Teacher", math.huge, -1},
	[204] = {"Karate Teacher", math.huge, -1},
	[252] = {"Naked Valet", math.huge, -1},
	[254] = {"Biker Drug Dealer", math.huge, -1},
	[290] = {"Rose", math.huge, -1},
	[304] = {"Kendl Johnson", math.huge, -1},
	[305] = {"Jethro", math.huge, -1},

	--unused special skins
	[3] = {"Country Police Officer", math.huge, -1},
	[4] = {"SFPD Bike Cop", math.huge, -1},
	[5] = {"Barry 'Big Bear' Thorne", math.huge, -1},
	[6] = {"Female Valet", math.huge, -1},
	[8] = {"Cab Driver", math.huge, -1},
	[65] = {"Airport Worker", math.huge, -1},
	[86] = {"Hispanic Girl", math.huge, -1},
	[119] = {"LVPD Bike Cop", math.huge, -1},
	[273] = {"Chinese Claude", math.huge, -1},
	[289] = {"Airport Worker", math.huge, -1},
}

Tasks = {
	TASK_GUARD = 1,
	TASK_SHOOT_TARGET = 2,
	TASK_GETTING_TARGETTED = 3,
}

VehicleTypes = {
	Player = 1;
	Faction = 2;
	Company = 3;
	Group = 4;
}

VehicleTypeName = {
	[VehicleTypes.Player] = "player";
	[VehicleTypes.Faction] = "faction";
	[VehicleTypes.Company] = "company";
	[VehicleTypes.Group] = "group";
}

VehiclePositionType = {World = 0, Garage = 1, Mechanic = 2, Hangar = 3, Harbor = 4, Unregistered = 5,}
VehiclePositionTypeName = {[0] = "World", [1] = "Garage", [2] = "Autohof" , [3]  = "Hangar", [4] = "Hafen", [5] = "Stadthalle",}
VehicleType = {Automobile = 0, Plane = 1, Bike = 2, Helicopter = 3, Boat = 4, Trailer = 5}
VehicleSpecial = {Soundvan = 1}
VEHICLE_TOTAL_LOSS_HEALTH = 260 -- below = total loss
NO_LICENSE_VEHICLES = {509, 481, 462, 510, 448}
TRUCK_MODELS =  {499, 609, 498, 524, 532, 578, 486, 406, 573, 455, 588, 403, 514, 423, 414, 443, 515, 531, 456, 433, 427, 407, 544, 432, 431, 437, 408}

GROUP_CREATE_COSTS = 350000
GROUP_RENAME_TIMEOUT = 60*60*24*30 -- 30 Days (in seconds)
GROUP_RENAME_COSTS = 50000

GROUP_NAME_MIN = 5
GROUP_NAME_MAX = 24
GROUP_NAME_MATCH = "^[a-zA-Z0-9 _.-]*$"

GARAGE_UPGRADES_COSTS = {[1] = 200000, [2] = 250000, [3] = 500000}
HANGAR_UPGRADES_COSTS = {[1] = 9999999, [2] = 0, [3] = 0}
GARAGE_UPGRADES_TEXTS = {[0] = "Garage: keine Garage", [1] = "Garage: Standard Garage", [2] = "Garage: Komfortable Garage", [3] = "Garage: Luxus Garage"}
HANGAR_UPGRADES_TEXTS = {[0] = "Hangar: kein Hangar", [1] = "Hangar: Unkown Hangar", [2] = "Hangar: Unkown Hangar", [3] = "Hangar: Unkown Hangar"}

WEAPONTRUCK_MAX_LOAD = 60000 -- Dollars
EVIDENCETRUCK_MAX_LOAD = 60000 -- Dollars
STATE_EVIDENCE_MAX_OBJECTS = 100000 -- dollars
STATE_EVIDENCE_MAX_CLIPS = 50
STATE_EVIDENCE_OBJECT_PRICE = {
	Waffe = 1, -- * weapon cost
	Munition = 1, -- * munition cost
	Item = 10
}


PlayerAttachObjects = {
	[1550] = {model = 1550, name = "Geldsack", pos = Vector3(0, -0.2, 0), rot = Vector3(0, 0, 180), bone = 3, placeDown = true, blockFlyingVehicles = true},
	[2912] = {model = 2912, name = "Waffenkiste", pos = Vector3(0, 0.5, 0.35), rot = Vector3(10, 0, 0), blockJump = true, blockSprint = true, blockWeapons = true, blockVehicle = true, animationData = {"carry", "crry_prtial", 1, true, true, false, true}, placeDown = true},
	[2919] = {model = 2919, name = "Waffen", pos = Vector3(0, -0.2, 0), rot = Vector3(0, 90, 90), 	blockJump = true, bone = 3, blockSprint = true,  blockVehicle = false, placeDown = true},
	[1826] = {model = 1826, name = "Angelruten", pos = Vector3(-0.03, 0.02, 0.05), rot = Vector3(180, 120, 0), blockJump = false, bone = 12, blockSprint = true, blockVehicle = true},
	[1575] = {model = 1575, name = "Drogen", pos = Vector3(0, -0.25, 0.12), rot = Vector3(180, 90, 90), bone = 3, blockJump = false, blockSprint = true, blockFlyingVehicles = true, placeDown = true, scale = {x = 1, y = 1.5, z = 1.4}},
	[2358] = {model = 2358, name = "Waffen", pos = Vector3(0, 0.45, 0.62), rot = Vector3(10, 0, 0), blockSprint = true, blockFlyingVehicles = true, blockVehicle = true, placeDown = true, blockWeapons = true, animationData = {"carry", "crry_prtial", 1, true, true, false, true}}
}



COROUTINE_STATUS_RUNNING = "running"
COROUTINE_STATUS_SUSPENDED = "suspended"
COROUTINE_STATUS_DEAD = "dead"

THREAD_PRIORITY_LOW = 500
THREAD_PRIORITY_MIDDLE = 250
THREAD_PRIORITY_HIGH = 150
THREAD_PRIORITY_HIGHEST = 50

AD_COST = 30
AD_COST_PER_CHAR = 3
AD_BREAK_TIME = 30 -- In Seconds
AD_MIN_PLAYTIME = 10 -- In Hours

AD_DURATIONS = {
	["20s"] = 20,
	["30s"] = 30,
	["45s"] = 45
}

BODYPART_NAMES = {
	[3] = "Körper",
	[4] =  "Hüfte",
	[5] =  "Linker Arm",
	[6] =  "Rechter Arm",
	[7] =  "Linkes Bein",
	[8] =  "Rechtes Bein",
	[9] =  "Kopf"
}


MEDIC_TIME = 180000
DEATH_TIME = 30000
DEATH_TIME_PREMIUM = 0
DEATH_TIME_ADMIN = 0


if DEBUG then
	MEDIC_TIME = 25000
	DEATH_TIME = 0
end


BeggarTypes = { -- Important: Do not change order! Only add a new one below!
	Money = 1;
	Food = 2;
	Transport = 3;
    Weed = 4;
	Heroin = 5;
}

BeggarTypeNames = {}
for i, v in pairs(BeggarTypes) do
	BeggarTypeNames[v] = i
end

HOSPITAL_POSITION = Vector3(1177.80, -1323.94, 14.09)
HOSPITAL_ROTATION = Vector3(0, 0, 270)

WEAPON_LEVEL = {
	[1] = {["costs"] = 750},
	[2] = {["costs"] = 1125},
	[3] = {["costs"] = 1500},
	[4] = {["costs"] = 2250},
	[5] = {["costs"] = 3000},
	[6] = {["costs"] = 3750},
	[7] = {["costs"] = 4875},
	[8] = {["costs"] = 6000},
	[9] = {["costs"] = 7125},
	[10] = {["costs"] = 8250}
}

BOXING_MONEY = {0, 50, 100, 500, 1000, 5000, 10000, 50000, 100000}

FERRIS_IDS = {
	Base = 6461,
	Gond = 3752,
	Wheel = 6298,
}

SPAWN_LOCATIONS = {
	DEFAULT = 0,
	NOOBSPAWN = 1,
	--GARAGE = 2, (not used anymore)
	FACTION_BASE = 3,
	COMPANY_BASE = 4,
	HOUSE = 5,
	VEHICLE = 6,
	GROUP_BASE = 7
}

VEHICLE_MODEL_SPAWNS = {
	[508] = true,
	[484] = true,
	[483] = true,
	[454] = true,
}

VEHICLE_SPAWN_OFFSETS = {
	[508] = Vector3(3, 0, 0),
	[484] = Vector3(0, -2, 2),
	[483] = Vector3(2, 2, 0),
	[454] = Vector3(-0.4, -3.0, 2),
}

HOUSE_INTERIOR_TABLE = {
	[1] = {1, 223.27, 1287.43, 1081.91};
	[2] = {5, 2233.86, -1113.76, 1050.88};
	[3] = {8, 2365.22, -1135.14, 1050.87};
	[4] = {11, 2282.94, -1139.96, 1050.75};
	[5] = {6, 2196.37, -1204.39, 1049.02};
	[6] = {10, 2269.85, -1210.45, 1047.48};
	[7] = {6, 2308.74, -1212.39, 1048.9};
	[8] = {1, 2217.14, -1076.27, 1050.48};
	[9] = {2, 2237.54, -1081.10, 1049.02};
	[10] = {9, 2318.07, -1026.23, 1050.21};
	[11] = {4, 260.99, 1284.81, 1080.25};
	[12] = {5, 140.24, 1366.50, 1083.85};
	[13] = {9, 82.97, 1322.54, 1083.86};
	[14] = {15, -284.05, 1471.09, 1084.37};
	[15] = {4, -260.75, 1456.69, 1084.36};
	[16] = {8, -42.58, 1405.95, 1084.23};
	[17] = {2, 2468.07, -1698.29, 1013.3};
	[18] = {1, 2525.21, -1679.39, 1015.3};
	[19] = {8, 2807.57, -1173.78, 1025.35};
	[20] = {5, 318.55, 1115.48, 1083.5};
	[21] = {12, 2324.46, -1149.03, 1050.51};
	[22] = {5, 1298.86, -796.24, 1083.65};
}

CompanyStaticId = {
	DRIVINGSCHOOL = 1,
	MECHANIC = 2,
	SANNEWS = 3,
	EPT = 4,
}

FactionStaticId = {
	SAPD = 1,
	FBI = 2,
	MBT = 3,
	RESCUE = 4,
	LCN = 5,
	YAKUZA = 6,
	GROVE = 7,
	BALLAS = 8,
	OUTLAWS = 9,
	VATOS = 10,
	TRIAD = 11,
	BRIGADA = 12,
	INSURGENT = 13,
}

SEASONS = {
	SPRING = 1,
	SUMMER = 2,
	FALL = 3,
	WINTER = 4,
}

VEHICLE_IMPORT_POSITION = Vector3(319.99, -44.79, 1.57) -- where the ped will be located and the UI shows the mission start button

COLLECTABLES_COUNT_PER_PLAYER = 40 -- how many collectables each player can collect

CONTROL_NAMES = { "fire", "aim_weapon", "next_weapon", "previous_weapon", "forwards", "backwards", "left", "right", "zoom_in", "zoom_out",
 "change_camera", "jump", "sprint", "look_behind", "crouch", "action", "walk", "conversation_yes", "conversation_no",
 "group_control_forwards", "group_control_back", "enter_exit", "vehicle_fire", "vehicle_secondary_fire", "vehicle_left", "vehicle_right",
 "steer_forward", "steer_back", "accelerate", "brake_reverse", "radio_next", "radio_previous", "radio_user_track_skip", "horn", "sub_mission",
 "handbrake", "vehicle_look_left", "vehicle_look_right", "vehicle_look_behind", "vehicle_mouse_look", "special_control_left", "special_control_right",
 "special_control_down", "special_control_up" }


LexiconPages = {
	VehicleTexture = "58",
	VehicleImport = "60",
	VehicleTake = "34",
	VehicleRental = "36",
	Cinema = "38",
	BeggarPed = "40",
	JobOverview = "4",
	JobPizzaDelivery = "10",
	JobRoadSweeper = "8",
	JobLogistician = "14",
	JobTreasureSeeker = "26",
	JobTrashman = "6",
	JobForkLift = "16",
	JobLumberjack = "12",
	JobHeliTransport = "22",
	JobFarmer = "18",
	JobGravel = "20",
	JobBoxer = "24",
	JobServiceTechnician = "62",
	ActionBankRobbery = "28",
	ActionWeaponTruck = "32",
	ActionWeedTruck = "30",
	Animation = "56",
	Walkingstyle = "54",
	BankATM = "52",
	Achievement = "50",
	IDCard = "48",
	Group = "46",
	ShortMessage = "44",
	WeaponLevel = "42",
}

ATM_NORMAL_MODEL = 2942
ATM_BROKEN_MODEL = 2943

GROUP_PROPERTY_SET_FOR_SALE_FEE = 5000

CHAT_MSG_REPEAT_COOLDOWN = 500 -- cooldown for different chat messages
CHAT_SAME_MSG_REPEAT_COOLDOWN = 3000 -- cooldown for same chat messages