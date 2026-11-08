-- Dirty way to set globals i guess
--[[
if fileExists(':vrp/server/config/config.json') then
  local file = fileOpen(':vrp/server/config/config.json', true)
  local data = fileRead(file, fileGetSize(file))
  data = fromJSON(data)

  MYSQL_CONFIG = data['mysql']

else
  outputDebugString("Trump did this to us")
  -- Even dirtier way to prevent running without config
  -- shutdown('No config no server')
end
]]
IS_TESTSERVER = getServerName():find("Script") ~= nil
PERFORMANCE_HOOK_TRIGGER_PERCENT = 20 -- everything that has a higher percentage on lua timiing gets sent to slack
PERFORMANCE_HOOK_TRIGGER_PERCENT_FUNC = 1 -- every function that has a higher percentage on lua timiing gets sent to slack

CHAT_WHISPER_RANGE = 2.5
CHAT_TALK_RANGE = 10
CHAT_SCREAM_RANGE = 30
CHAT_DISTRICT_RANGE = 50

CheatSeverity = {Low = 1, Middle = 2, High = 3, Brutal = 4}

NOOB_SPAWN = Vector3(1481.07, -1764.84, 18.80)
NOOB_SKIN = 78

START_MONEY_BAR = 7500

Interiors = {
    -- Name -- Dimension ("Allocate" a block of dimensions)
    AmmuNation1 = 50000,
    AmmuNation2 = 50001,
}

BankAccountTypes = {
  Player = 1;
  Faction = 2;
  Company = 3;
  Admin = 4;
  Server = 5;
  Shop = 6;
  House = 7;
  Group = 8;
  VehicleShop = 9;
}

USER_GROUP_TYPES = {
	Faction = 1;
	Company = 2;
	Group = 3;
}

BAIL_PRICES =
{
	[1] = 1000,
	[2] = 2000,
	[3] = 3000,
	[4] = 4000,
	[5] = 5000,
	[6] = 6000,
	[7] = 4000, --ab hier nicht angepasst (max 6 Wanteds)
	[8] = 5000,
	[9] = 7000,
	[10] = 8000,
	[11] = 9000,
	[12] = 10000,
}

JAIL_COSTS =
{
	[1] = 250,
	[2] = 500,
	[3] = 750,
	[4] = 1000,
	[5] = 1250,
	[6] = 1500,
	[7] = 3500, --ab hier nicht angepasst (max 6 Wanteds)
	[8] = 4000,
	[9] = 5000,
	[10] = 6000,
	[11] = 7000,
	[12] = 8000,
}

JAIL_TIME_PER_WANTED_BAIL = 3
JAIL_TIME_PER_WANTED_ARREST = 3
JAIL_TIME_PER_WANTED_KILL = 4
JAIL_TIME_PER_WANTED_OFFLINE = 5

RESOURCES_TO_STOP = {
    "scoreboard";
    "helpmanager";
}

JobBoxerMoney = {
    15,
    30,
	60,
	90,
	120
}

DRUG_NPC_SPAWNPOINTS = {
	Vector3(1520.64, -1676.92, 13.55),
	Vector3(1520.96, -1680.14, 13.55),
}