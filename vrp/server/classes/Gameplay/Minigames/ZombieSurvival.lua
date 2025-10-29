-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Deathmatch/ZombieSurvival.lua
-- *  PURPOSE:     ZombieSurvival for Deathmatch-Script
-- *
-- ****************************************************************************

ZombieSurvival = inherit(Object)
ZombieSurvival.PickupWeapons = {25, 24, 22, 33}

function ZombieSurvival.initalize()
	local b = Blip:new("Evil.png", -31.64, 1377.67)
	b:setDisplayText("Zombie Survival", BLIP_CATEGORY.Leisure)

	local zombiePed = createPed(162, -31.64, 1377.67, 9.17, 90)
	zombiePed:setFrozen(true)
	local zombieMarker = createMarker(-34.6, 1377.80, 8.4, "cylinder", 1, 255, 0, 0, 125)

	--[[ Cutscene
	local zombieColShape = createColSphere(-31.64, 1377.67, 9.17, 25)
	addEventHandler("onColShapeHit", zombieColShape, function(hitElement, dim)
		if hitElement:getType() == "player" and dim then
			hitElement:triggerEvent("playZombieCutscene")
		end
	end)
	]]

	addEventHandler("onMarkerHit", zombieMarker, function(hitElement, dim)
		if hitElement:getType() == "player" and dim and not hitElement.vehicle then
			if HalloweenQuestManager:getSingleton():getQuestState(hitElement) <= 0 then
				hitElement:sendError(_("Beende zuerst die Halloween-Quest vom Friedhof!", hitElement))
			else
				hitElement:triggerEvent("showMinigameGUI", "ZombieSurvival")
			end
		end
	end)

	addRemoteEvents{"startZombieSurvival"}
	addEventHandler("startZombieSurvival", root, function()
		if client:isFactionDuty() or client:isCompanyDuty() then
			client:sendError(_("Du darfst nicht im Dienst sein!", client))
			return
		end

		local index = #MinigameManager.Current+1
		MinigameManager.Current[index] = ZombieSurvival:new()
		MinigameManager.Current[index]:addPlayer(client)
		MinigameManager.Current[index].Type = "ZombieSurvival"
		client.Minigame = MinigameManager.Current[index]
	end)
end

function ZombieSurvival:constructor()
	self.m_Dimension = DimensionManager:getSingleton():getFreeDimension()
	self.m_Zombies = {}
	self.m_ZombieKills = {}
	self.m_ZombieTimers = {}
	self.m_ZombieTime = 10000
	self.m_IncreaseTimer = setTimer(bind(self.increaseZombies, self), 20000, 0)
	self.m_CreatePickupTimer = setTimer(bind(self.createPickup, self), 20000, 0)
	self.m_ZombieWastedBind = bind(self.zombieWasted, self)

	self:addZombie()
	self:loadMap()
	outputDebug("Lobby erstellt - Dimension"..self.m_Dimension)
	addEventHandler("onZombieWasted", resourceRoot, self.m_ZombieWastedBind)
end

function ZombieSurvival:destructor()
	for index, object in pairs(self.m_Map) do
		object:destroy()
	end
	for index, zombie in pairs(self.m_Zombies) do
		delete(zombie)
	end
	for player, score in pairs(self.m_ZombieKills) do
		if score then
			self:removePlayer(player)
		end
	end
	for index, timer in pairs(self.m_ZombieTimers) do
		if isTimer(timer) then killTimer(timer) end
	end

	if isTimer(self.m_CreatePickupTimer) then killTimer(self.m_CreatePickupTimer) end
	if isTimer(self.m_IncreaseTimer) then killTimer(self.m_IncreaseTimer) end
	if isElement(self.m_Pickup) then self.m_Pickup:destroy() end

	outputDebug("Lobby zerstört - Dimension"..self.m_Dimension)
	DimensionManager:getSingleton():freeDimension(self.m_Dimension)
end

function ZombieSurvival:zombieWasted(ped, player)
	if not self.m_ZombieKills[player] then return end
	if isElement(player) then
		self.m_ZombieKills[player] = self.m_ZombieKills[player]+1
		player:triggerEvent("setScore", self.m_ZombieKills[player])
	end
end

function ZombieSurvival:getRandomPosition()
	return Vector3(math.random(82, 210), math.random(1728, 1798), 17.64)
end

function ZombieSurvival:addPlayer(player)
	player:createStorage(true)
	for _, stat in ipairs({69, 70, 71, 72, 74, 76, 77, 78}) do
		setPedStat(player, stat, stat == 69 and 900 or 1000)
	end

	player:giveAchievement(54)
	self.m_ZombieKills[player] = 0
	setElementDimension(player,self.m_Dimension)
	player:setPosition(self:getRandomPosition())
	setElementInterior(player,0)
	player:setArmor(0)
	player:setHealth(100)
	player:giveWeapon(24, 15, true)
	player:triggerEvent("showScore")

	addEventHandler("onPlayerDamage", player, function(attacker, weapon, bodypart, loss)
		if isElement(attacker) and getElementData(attacker, "zombie") == true then
			if (source:getHealth()-loss*15) <= 0 then
				source:fadeCamera(false, 0)
				source:kill()
				return
			end
			source:setHealth(source:getHealth()-loss*15)
		end
	end)
	outputDebug("Spieler "..player:getName().." hinzugefügt - Dimension"..self.m_Dimension)
end

function ZombieSurvival:removePlayer(player)
	player:triggerEvent("hideScore")

	local score = self.m_ZombieKills[player]
	local skin = player:getModel()
	spawnPlayer(player, -35.72, 1380.00, 9.42, 0, skin, 0, 0)
	player:restoreStorage()
	player:setHeadless(false)
	player:setCameraTarget(player)
	player:fadeCamera(true, 1)
	player:setAlpha(255)
	player:sendInfo(_("Du bist gestorben! Das Zombie Survival wurde beendet! Score: %d", player, score))
	MinigameManager:getSingleton().m_ZombieSurvivalHighscore:addHighscore(player:getId(), score)
	self.m_ZombieKills[player] = nil

	-- Check for Freaks Achievement
	if MinigameManager:getSingleton():checkForFreaks(player) then
		player:giveAchievement(22)
	end

	-- Reward pumpkins and candy based on score
	if EVENT_HALLOWEEN and not player:isDisconnecting() then
		local pumpkinAmount = math.round(score / 30)
		local candyAmount = math.round(score / 3)

		if pumpkinAmount + candyAmount > 0 then
			player:getInventory():giveItem("Kürbis", pumpkinAmount)
			player:getInventory():giveItem("Suessigkeiten", candyAmount)
			player:sendSuccess(_("Du hast %s Kürbisse und und %s Süßigkeiten erhalten!", player, pumpkinAmount, candyAmount))
		end
	end

	removeEventHandler("onZombieWasted", resourceRoot, self.m_ZombieWastedBind)
	outputDebug("Spieler "..player:getName().." entfernt - Dimension"..self.m_Dimension)

	player.Minigame = nil
	self:delete()
end

function ZombieSurvival:getRandomPlayer()
	local random = {}
	for player, score in pairs(self.m_ZombieKills) do
		if score then
			table.insert(random, player)
		end
	end
	return random[math.random(1, #random)]
end

function ZombieSurvival:getPlayers()
	local players = {}
	for player, score in pairs(self.m_ZombieKills) do
		if score then
			table.insert(players, player)
		end
	end
	return players
end

function ZombieSurvival:increaseZombies()
	self.m_ZombieTime = self.m_ZombieTime*0.95
	if self.m_ZombieTime < 500 then
		self.m_ZombieTime = 500
		if isTimer(self.m_IncreaseTimer) then killTimer(self.m_IncreaseTimer) end
	end
end

function ZombieSurvival:createPickup()
	if isElement(self.m_Pickup) then self.m_Pickup:destroy() end
	self.m_Pickup = createPickup(self:getRandomPosition(), 2, ZombieSurvival.PickupWeapons[math.random(1, #ZombieSurvival.PickupWeapons)], 5000000, 30)
	self.m_Pickup:setDimension(self.m_Dimension)
end

function ZombieSurvival:addZombie()
	for i, zombie in pairs(self.m_Zombies) do
		if not zombie or (zombie and not isElement(zombie.m_Ped)) then
			self.m_Zombies[i] = nil
		end
	end
	if table.size(self.m_Zombies) < 20 then
		local pos = self:getRandomPosition()
		self:createSmoke(pos)
		self.m_ZombieTimers[#self.m_ZombieTimers+1] = setTimer(bind(self.spawnZombie, self), 2500, 1, pos)
	end
	self.m_ZombieTimers[#self.m_ZombieTimers+1] = setTimer(bind(self.addZombie, self), self.m_ZombieTime, 1)
end

function ZombieSurvival:spawnZombie(pos)
	local zombie = Zombie:new(pos, 310, self.m_Dimension)
	zombie:disableSeeCheck()
	zombie:SprintToPlayer(self:getRandomPlayer())
	table.insert(self.m_Zombies, zombie)
end

function ZombieSurvival:createSmoke(pos)
	local smoker = createObject(2780, pos.x, pos.y, pos.z-1)
	smoker:setAlpha(0)
	smoker:setDimension(self.m_Dimension)
	smoker:setCollisionsEnabled(false)
	setTimer(destroyElement, 3000, 1, smoker)
end

function ZombieSurvival:loadMap()
	self.m_Map = {
		createObject(987, 213.2, 1787.2, 16.6, 0, 0, 90),
		createObject(987, 213.2, 1775.2, 16.6, 0, 0, 90),
		createObject(987, 213.2, 1763.2, 16.6, 0, 0, 90),
		createObject(987, 213.2, 1751.2, 16.6, 0, 0, 90),
		createObject(987, 213.2, 1739.2, 16.6, 0, 0, 90),
		createObject(987, 213.2, 1727.2, 16.6, 0, 0, 90),
		createObject(987, 201.3, 1727.2, 16.6),
		createObject(987, 189.3, 1727.2, 16.6),
		createObject(987, 177.3, 1727.2, 16.6),
		createObject(987, 165.3, 1727.2, 16.6),
		createObject(987, 153.3, 1727.2, 16.6),
		createObject(987, 141.3, 1727.2, 16.6),
		createObject(987, 129.3, 1727.2, 16.6),
		createObject(987, 117.3, 1727.2, 16.6),
		createObject(987, 105.2, 1727.2, 16.6),
		createObject(987, 93.2, 1727.2, 16.6),
		createObject(987, 81.2, 1727.2, 16.6),
		createObject(987, 81.2, 1739.1, 16.6, 0, 0, 270),
		createObject(987, 81.2, 1751.1, 16.6, 0, 0, 270),
		createObject(987, 81.2, 1763.1, 16.6, 0, 0, 270),
		createObject(987, 81.2, 1775.1, 16.6, 0, 0, 270),
		createObject(987, 81.2, 1787.1, 16.6, 0, 0, 270),
		createObject(987, 81.2, 1799, 16.6, 0, 0, 270),
		createObject(987, 93.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 105.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 117.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 129.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 141.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 153.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 165.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 177.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 189.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 201.2, 1799, 16.6, 0, 0, 180),
		createObject(987, 213.2, 1799, 16.6, 0, 0, 180 )
	}
	for index, object in pairs(self.m_Map) do
		object:setDimension(self.m_Dimension)
	end
end
