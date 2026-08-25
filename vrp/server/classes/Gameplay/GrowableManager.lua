-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Item/GrowableManager.lua
-- *  PURPOSE:     Growable Item manager class
-- *
-- ****************************************************************************
GrowableManager = inherit(Singleton)
GrowableManager.Types = {
	["Weed"] = {
		["Object"] = 1870,
		["ObjectSizeMin"] = 0.1,
		["ObjectSizeSteps"] = 0.05,
		["GrowPerHour"] = 0.5,
		["GrowPerHourWatered"] = 1,
		["HoursWatered"] = 6,
		["MaxSize"] = 20,
		["Item"] = "Weed",
		["Seed"] = "Weed-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 1,
		["Illegal"] = true,
		["SizeBetweenPlants"] = 2
	};
	["Apfelbaum"] = {
		["Object"] = 892,
		["ObjectSizeMin"] = 0.2,
		["ObjectSizeSteps"] = 0.125,
		["GrowPerHour"] = 0.25,
		["GrowPerHourWatered"] = 0.5,
		["HoursWatered"] = 3,
		["MaxSize"] = 6,
		["Item"] = "Apfel",
		["Seed"] = "Apfelbaum-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 3,
		["Illegal"] = false,
		["SizeBetweenPlants"] = 3
	};
	["Blumen"] = {
		["Object"] = 325,
		["ObjectSizeMin"] = 0.4,
		["ObjectSizeSteps"] = 0.8,
		["GrowPerHour"] = 0.09,
		["GrowPerHourWatered"] = 0.17,
		["HoursWatered"] = 4,
		["MaxSize"] = 1,
		["Item"] = "Blumen",
		["Seed"] = "Blumen-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 1,
		["Illegal"] = false,
		["SizeBetweenPlants"] = 1.5
	};
	["Karotte"] = {
		["Object"] = 861,
		["ObjectSizeMin"] = 0.2,
		["ObjectSizeSteps"] = 0.1,
		["GrowPerHour"] = 0.5,
		["GrowPerHourWatered"] = 1,
		["HoursWatered"] = 1,
		["MaxSize"] = 1,
		["Item"] = "Karotte",
		["Seed"] = "Karotten-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 1,
		["Illegal"] = false,
		["SizeBetweenPlants"] = 1.5
	};
	["Birnbaum"] = {
		["Object"] = 657,
		["ObjectSizeMin"] = 0.2,
		["ObjectSizeSteps"] = 0.075,
		["GrowPerHour"] = 0.25,
		["GrowPerHourWatered"] = 0.5,
		["HoursWatered"] = 3,
		["MaxSize"] = 6,
		["Item"] = "Birne",
		["Seed"] = "Birnbaum-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 3,
		["Illegal"] = false,
		["SizeBetweenPlants"] = 3
	};
	["Erdbeerpflanze"] = {
		["Object"] = 810,
		["ObjectSizeMin"] = 0.2,
		["ObjectSizeSteps"] = 0.1,
		["GrowPerHour"] = 0.5,
		["GrowPerHourWatered"] = 1,
		["HoursWatered"] = 3,
		["MaxSize"] = 3,
		["Item"] = "Erdbeeren",
		["Seed"] = "Erdbeer-Samen",
		["ItemPerSize"] = 1,
		["TimesEarnedForDestroy"] = 3,
		["Illegal"] = false,
		["SizeBetweenPlants"] = 2
	};
}
GrowableManager.Map = {}

function GrowableManager:constructor()

	self.m_Timer = setTimer(bind(self.grow, self), 10*60*1000, 0)
	self:load()

	addRemoteEvents{"plant:harvest", "plant:getClientCheck"}
	addEventHandler("plant:harvest", root, bind(self.harvest, self))
	addEventHandler("plant:getClientCheck",root, bind(self.getClientCheck, self))

	--DEBUG
	addCommandHandler("growPlants", function(player)
		if player:getRank() >= RANK.Developer then
			self:grow(true)
			player:sendShortMessage("DEBUG: Alle Pflanzen wachsen nun!")
		end
	end)
end

function GrowableManager:destructor()
	for id, plant in pairs(GrowableManager.Map) do
		plant:save()
	end
end

function GrowableManager:load()
	local result = sql:queryFetch("SELECT * FROM ??_plants", sql:getPrefix())
	for i, row in pairs(result) do
		if getRealTime().timestamp - row.planted < 604800 then
			GrowableManager.Map[row.Id] = Growable:new(row.Id, row.Type, GrowableManager.Types[row.Type], Vector3(row.PosX, row.PosY, row.PosZ), row.Owner, row.Size, row.planted, row.last_grown, row.last_watered, row.times_earned, row.in_greenhouse)
		else
			sql:queryExec("DELETE FROM ??_plants WHERE Id = ?", sql:getPrefix(), row.Id)
		end
	end
end

function GrowableManager:removePlant(id)
	GrowableManager.Map[id] = nil
end

function GrowableManager:grow(force)
	for id, plant in pairs(GrowableManager.Map) do
		plant:checkGrow(force)
	end
end

function GrowableManager:harvest(id)
	if id and id > 0 then
		if GrowableManager.Map[id] then
			GrowableManager.Map[id]:harvest(client)
		else
		--	client:sendError(_("Harvest Error! Plant not found! (%d)", client, id))
		end
	end
end

function GrowableManager:addNewPlant(type, position, owner, inGreenhouse)
	local ts = getRealTime().timestamp
	sql:queryExec("INSERT INTO ??_plants (Type, Owner, PosX, PosY, PosZ, Size, planted, last_grown, last_watered, times_earned, in_greenhouse) VALUES (? , ? , ?, ?, ?, ?, ?, ?, ?, ?, ?)",
	sql:getPrefix(), type, owner:getId(), position.x, position.y, position.z, 0, ts, ts, 0, 0, inGreenhouse)
	StatisticsLogger:getSingleton():addPlantLog(owner, type)
	local id = sql:lastInsertId()
	GrowableManager.Map[id] = Growable:new(id, type, GrowableManager.Types[type], position, owner:getId(), 0, ts, ts, 0, 0, inGreenhouse)
	GrowableManager.Map[id]:onColShapeHit(owner, true)
end

function GrowableManager:getNextPlant(player, range)
	for id, plant in pairs(GrowableManager.Map) do
		if plant and isElement(plant:getObject()) then
			if getDistanceBetweenPoints3D(player:getPosition(), plant:getObject():getPosition()) <= range then
				return plant
			end
		end
	end
	return false
end

function GrowableManager:getPlantNameFromSeed(seed)
	for index, data in pairs(GrowableManager.Types) do
		if data["Seed"] == seed then
			return index
		end
	end
	return false
end

function GrowableManager:checkPlantConditionsForPlayer(player, seed)
	local plantName = GrowableManager:getSingleton():getPlantNameFromSeed(seed)
	if not plantName then player:sendError(_("Internal Error: Invalid Plant", player)) return false end
	if player:isInWater() then player:sendError(_("Du bist im Wasser! Hier kannst du nichts pflanzen!", player)) return false end
	if player.vehicle then player:sendError(_("Du sitzt in einem Fahrzeug!", player)) return false end
	if GrowableManager:getSingleton():getNextPlant(player, GrowableManager.Types[plantName].SizeBetweenPlants) then player:sendError(_("Du bist zu nah an einer anderen Pflanze!", player)) return false end
	return true
end

function GrowableManager:getClientCheck(seed, bool, z_pos, isUnderWater, isWrongDimension)
	if not bool or isUnderWater then client:sendError(_("Dies ist kein guter Untergrund zum Anpflanzen! Suche dir ebene Gras- oder Erdflächen", client)) return false end
	if not self:checkPlantConditionsForPlayer(client, seed) then return false end

	local inGreenhouse = false
	if isWrongDimension then
		if GreenhouseManager:getSingleton().m_Greenhouses[client] then
			if seed == "Weed-Samen" then
				client:sendError(_("Du darfst im Gewächshaus keine illegalen Pflanzen anpflanzen!", client))
				return false
			else
				inGreenhouse = true
			end
		else
			client:sendError(_("Du kannst das gerade nicht tun!", client))
			return false
		end
	end
	
	if not client.m_IsPlanting then
		client.m_IsPlanting = true
		toggleAllControls(client, false)
		client:setAnimation("bomber", "bom_plant", 1500, false, false, false, false)
		setTimer(function(client, seed, z_pos)
			local pos = client:getPosition()
			client:giveAchievement(61)
			client:getInventory():removeItem(seed, 1)
			self:addNewPlant(self:getPlantNameFromSeed(seed), Vector3(pos.x, pos.y, z_pos), client, inGreenhouse)
			toggleAllControls(client, true)
			client.m_IsPlanting = false
			triggerEvent("onGrowablePlanted", client) -- For Quest
		end, 1500, 1, client, seed, z_pos)
	else
		client:sendError(_("Du bist gerade schon am einpflanzen!", client))
	end
end