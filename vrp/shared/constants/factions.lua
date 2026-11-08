VEHICLE_BOX_LOAD = {}
VEHICLE_BOX_LOAD[543] = {["count"]= 2, [1] = Vector3(0, -1.9, -0.2), [2] = Vector3(0, -1.1, -0.2)}
VEHICLE_BOX_LOAD[427] = {["count"]= 2,	[1] = Vector3(0, -1.5, -0.2), [2] = Vector3(0, -3, -0.2)}

FACTION_TRUNK_MAX_ITEMS = {
	[41] = 10,
	[48] = 3,
	[47] = 5,
	[73] = 10,
	[90] = 2,
	[59] = 10,
	[91] = 10,
	[96] = 10,
}

FACTION_TRUNK_SWAT_ITEMS = 
{
	[90] = true,
	[59] = true,
	[91] = true,
	[96] = true,
}

FACTION_TRUNK_SWAT_ITEM_PERMISSIONS = 
{
	[90] = {3, 3}, --// rank,faction
	[59] = {0},
	[91] = {3},
	[96] = {0},
}

VEHICLE_BAG_LOAD = {}
VEHICLE_BAG_LOAD[428] = {["count"]= 5, [1] = Vector3(0, -1.2, 0), [2] = Vector3(0, -1.2, 0), [3] = Vector3(0, -1.2, 0), [4] = Vector3(0, -1.2, 0), [5] = Vector3(0, -1.2, 0)}
VEHICLE_BAG_LOAD[427] = {["count"]= 2, [1] = Vector3(0, -1.5, -0.2), [2] = Vector3(0, -3, -0.2)}
VEHICLE_BAG_LOAD[543] = {["count"]= 2, [1] = Vector3(0, -1.9, -0.2), [2] = Vector3(0, -1.1, -0.2)}

VEHICLE_PACKAGE_LOAD = {}
VEHICLE_PACKAGE_LOAD[456] = {["count"]= 5, [1] = Vector3(0, -1.2, 0), [2] = Vector3(0, -1.2, 0), [3] = Vector3(0, -1.2, 0), [4] = Vector3(0, -1.2, 0), [5] = Vector3(0, -1.2, 0)}

VEHICLE_WEAPON_PACKAGE_LOAD = {}
VEHICLE_WEAPON_PACKAGE_LOAD[543] = {["count"]= 1, [1] = Vector3(0, -1.9, -0.05)}
VEHICLE_WEAPON_PACKAGE_LOAD[422] = {["count"]= 1, [1] = Vector3(0, -0.86, -0.05)}

FACTION_FBI_BUGS = 5

FACTION_DIPLOMACY = {
	[1] = "Verbündet",
	[2] = "Waffenstillstand",
	[3] = "im Krieg",
}
for i, v in pairs(FACTION_DIPLOMACY) do
	FACTION_DIPLOMACY[v] = i
end

FACTION_DIPLOMACY_REQUEST = {
	[1] = "Bündnis-Anfrage",
	[2] = "Waffenstillstands-Anfrage",
	[3] = "Kriegserklärung",
}

FACTION_WAR_KILL_BONUS = 250
TICKET_PRICE_ONCE = 500
TICKET_PRICE_PER_WANTED = 750

FMS_STATUS_COLORS = {
	[1] = {255,255,255},
	[2] = {180,180,180},
	[3] = {0,200,0},
	[4] = {0,150,255},
	[5] = {255,255,0},
	[6] = {255,0,0},
	[7] = {180,0,180},
}