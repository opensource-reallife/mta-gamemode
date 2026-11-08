-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/GangwarManager.lua
-- *  PURPOSE:     Gangwar Class
-- *
-- ****************************************************************************

Gangwar = inherit(Singleton)

GANGWAR_RESET_AREAS = false
GANGWAR_CENTER_HOLD_RANGE = 15
GANGWAR_ATTACK_PAUSE = 1
GANGWAR_DUMP_COLOR = setBytesInInt32(240, 0, 200, 200)
GANGWAR_ATTACK_PICKUPMODEL = 1313
GANGWAR_FLAG_PICKUPMODEL = 2993
GANGWAR_PAYOUT_PER_PLAYER = 400
GANGWAR_PAYOUT_PER_AREA = 800
UNIX_TIMESTAMP_24HRS = 86400
GANGWAR_PAY_PER_DAMAGE = 1
GANGWAR_PAY_PER_KILL = 500
GANGWAR_DIMENSION_BASE = 65000
GANGWAR_INVALID_WINNER = "Ungueltig"
GANGWAR_REQUEST_TIMEOUT = 60
GANGWAR_RESPAWN_DELAY = 3000
GANGWAR_PHASE_NAMES = {prepare = "Aufbauphase", battle = "Attackphase", ["end"] = "Endphase"}

local DEFAULT_SETTINGS = {
	PrepareTime = 300,
	BattleTime = 20,
	FlagTime = 20,
	EndTime = 60,
	MaxParallel = 2,
	MaxAttacks = 4,
	Cooldown = 300,
	SameFactionCooldown = 900,
	MaxPlayers = 12,
	MinPlayers = 3,
	AttackStart = 1830,
	AttackEnd = 2100,
	GangwarHourEnd = 2030,
	BaseIncome = 2500,
	VehicleRadius = 20,
	DefenderDistance = 100,
	MaxFlagDistance = 700,
}

addRemoteEvents{
	"onLoadCharacter", "gangwarGetAreas", "Gangwar:startAttack", "Gangwar:enter", "Gangwar:submitPick", "Gangwar:requestPickData",
	"Gangwar:requestLateJoin", "Gangwar:answerRequest", "Gangwar:spawnVehicle", "Gangwar:requestMenu", "Gangwar:requestVehicleMenu", "Gangwar:leave", "Gangwar:requestNpcData",
	"adminGangwarGetData", "adminGangwarEditArea", "adminGangwarCreateArea", "adminGangwarSetNpc", "adminGangwarSetSpawn", "adminGangwarInvalidate", "adminGangwarToggleBan",
}

function Gangwar:constructor()
	if GANGWAR_RESET_AREAS and DEBUG then
		self:RESET()
	end
	self.m_Areas = {}
	self.m_Sessions = {}
	self.m_Requests = {}
	self.m_NextRequestId = 0
	self.m_Finished = {}
	self.m_Npcs = {}
	self.m_GangwarGuard = GangwarGuard:new()
	self.m_BankAccountServer = BankServer.get("faction.gangwar")
	self:loadConfig()

	local rows = sql:queryFetch("SELECT * FROM ??_gangwar", sql:getPrefix())
	if rows then
		for _, row in ipairs(rows) do
			self.m_Areas[row["ID"]] = Area:new(row, self)
		end
	end
	self:createNpcs()

	addEventHandler("onLoadCharacter", root, bind(self.onPlayerJoin, self))
	addEventHandler("gangwarGetAreas", root, bind(self.getAreas, self))
	addEventHandler("Gangwar:startAttack", root, bind(self.Event_startAttack, self))
	addEventHandler("Gangwar:enter", root, bind(self.Event_enter, self))
	addEventHandler("Gangwar:submitPick", root, bind(self.Event_submitPick, self))
	addEventHandler("Gangwar:requestPickData", root, bind(self.Event_requestPickData, self))
	addEventHandler("Gangwar:requestLateJoin", root, bind(self.Event_requestLateJoin, self))
	addEventHandler("Gangwar:answerRequest", root, bind(self.Event_answerRequest, self))
	addEventHandler("Gangwar:spawnVehicle", root, bind(self.Event_spawnVehicle, self))
	addEventHandler("Gangwar:requestMenu", root, bind(self.Event_requestMenu, self))
	addEventHandler("Gangwar:requestVehicleMenu", root, bind(self.Event_requestVehicleMenu, self))
	addEventHandler("Gangwar:leave", root, bind(self.Event_leave, self))
	addEventHandler("Gangwar:requestNpcData", root, bind(self.Event_requestNpcData, self))
	addEventHandler("adminGangwarGetData", root, bind(self.Event_adminGetData, self))
	addEventHandler("adminGangwarEditArea", root, bind(self.Event_adminEditArea, self))
	addEventHandler("adminGangwarCreateArea", root, bind(self.Event_adminCreateArea, self))
	addEventHandler("adminGangwarSetNpc", root, bind(self.Event_adminSetNpc, self))
	addEventHandler("adminGangwarSetSpawn", root, bind(self.Event_adminSetSpawn, self))
	addEventHandler("adminGangwarToggleBan", root, bind(self.Event_adminToggleBan, self))
	addEventHandler("adminGangwarInvalidate", root, bind(self.Event_adminInvalidate, self))

	PlayerManager:getSingleton():getWastedHook():register(bind(self.onPlayerWasted, self))
	Player.getQuitHook():register(bind(self.onPlayerQuit, self))

	self.m_GlobalTimerId = GlobalTimer:getSingleton():registerEvent(bind(self.onAreaPayday, self), "Gangwar-Payday", false, false, 0)
end

function Gangwar:destructor()
	for _, session in pairs(self.m_Sessions) do
		session:cancelWithoutRating()
	end
	for _, area in pairs(self.m_Areas) do
		area:delete()
	end
	GlobalTimer:getSingleton().m_Events[self.m_GlobalTimerId] = nil
	self.m_GangwarGuard:delete()
end

function Gangwar:loadConfig()
	self.m_Settings = table.copy(DEFAULT_SETTINGS)
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_settings", sql:getPrefix()) or {}) do
		self.m_Settings[row.Name] = tonumber(row.Value)
	end

	self.m_Loadout = {}
	self.m_LoadoutMap = {}
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_loadout ORDER BY Id", sql:getPrefix()) or {}) do
		self.m_Loadout[#self.m_Loadout + 1] = {row.WeaponId, row.Ammo}
		self.m_LoadoutMap[row.WeaponId] = true
	end

	self.m_BannedVehicles = {}
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_banned_vehicles", sql:getPrefix()) or {}) do
		self.m_BannedVehicles[row.Model] = true
	end

	self.m_Factions = {}
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_factions", sql:getPrefix()) or {}) do
		local spawn = tonumber(row.SpawnX) and {tonumber(row.SpawnX), tonumber(row.SpawnY), tonumber(row.SpawnZ)} or nil
		self.m_Factions[row.FactionId] = {x = row.NpcX, y = row.NpcY, z = row.NpcZ, rot = row.NpcRot, interior = row.NpcInterior, dimension = row.NpcDimension, spawn = spawn}
	end

	self.m_Bonus = {}
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_bonus", sql:getPrefix()) or {}) do
		self.m_Bonus[row.Id] = {name = row.Name, amount = row.Amount, areas = {}}
	end
	for _, row in ipairs(sql:queryFetch("SELECT * FROM ??_gangwar_bonus_areas", sql:getPrefix()) or {}) do
		if self.m_Bonus[row.BonusId] then
			table.insert(self.m_Bonus[row.BonusId].areas, row.AreaId)
		end
	end
end

function Gangwar:getSetting(name)
	return self.m_Settings[name]
end

function Gangwar:getFactionIds()
	local ids = {}
	for factionId in pairs(self.m_Factions) do
		ids[#ids + 1] = factionId
	end
	return ids
end

function Gangwar:isGangwarFaction(factionId)
	return self.m_Factions[factionId] ~= nil
end

function Gangwar:getLoadout()
	return self.m_Loadout
end

function Gangwar:isAllowedWeapon(weaponId)
	return self.m_LoadoutMap[weaponId] == true
end

function Gangwar:isVehicleBanned(area, model)
	return self.m_BannedVehicles[model] or area.m_BannedVehicles[model] or false
end

function Gangwar:getOwnedVehicleCounts(faction)
	local counts = {}
	for key, vehicle in pairs(VehicleManager:getSingleton():getFactionVehicles(faction:getId())) do
		if isElement(vehicle) then
			local model = vehicle:getModel()
			counts[model] = (counts[model] or 0) + 1
		end
	end
	return counts
end

function Gangwar:getKnownVehicleModels()
	local seen, list = {}, {}
	for factionId in pairs(self.m_Factions) do
		local faction = FactionManager:getSingleton():getFromId(factionId)
		if faction then
			for model in pairs(self:getOwnedVehicleCounts(faction)) do
				if not seen[model] then
					seen[model] = true
					list[#list + 1] = {model = model, name = getVehicleNameFromModel(model) or tostring(model)}
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function Gangwar:getFactionSpawn(faction, area)
	local config = self.m_Factions[faction:getId()]
	if config and config.spawn then
		return config.spawn
	end
	local point = factionNavigationpoint[faction:getId()]
	if point then
		return {point.x, point.y, point.z}
	end
	return area:getPosition()
end

function Gangwar:createNpcs()
	for factionId, config in pairs(self.m_Factions) do
		self:createNpc(factionId, config)
	end
end

function Gangwar:createNpc(factionId, config)
	local faction = FactionManager:getSingleton():getFromId(factionId)
	if not faction then return end
	if self.m_Npcs[factionId] and isElement(self.m_Npcs[factionId]) then
		destroyElement(self.m_Npcs[factionId])
	end
	local npc = NPC:new(faction:getRandomSkin(), config.x, config.y, config.z, config.rot)
	npc:setDimension(config.dimension)
	npc:setInterior(config.interior)
	npc:setFrozen(true)
	npc:setImmortal(true)
	npc:setData("clickable", true, true)
	npc.m_GangwarFaction = factionId
	addEventHandler("onElementClicked", npc, bind(self.onNpcClicked, self))
	ElementInfo:new(npc, "Gangwar")
	self.m_Npcs[factionId] = npc
end

function Gangwar:onNpcClicked(button, state, player)
	if button ~= "left" or state ~= "up" then return end
	local faction = player:getFaction()
	if not faction or faction:getId() ~= source.m_GangwarFaction then
		player:sendError(_("Nur Mitglieder dieser Fraktion können hier den Gangwar organisieren!", player))
		return
	end
	self:sendNpcData(player)
end

function Gangwar:getAttackMode()
	if DEBUG then return "regular" end
	local time = getRealTime()
	local current = time.hour*100 + time.minute
	if current >= self:getSetting("AttackStart") and current < self:getSetting("AttackEnd") then
		return "regular"
	elseif current >= self:getSetting("AttackEnd") then
		return "given"
	end
	return "closed"
end

function Gangwar:getRegularAttackCount(faction)
	self.m_AttackCountCache = self.m_AttackCountCache or {}
	local cached = self.m_AttackCountCache[faction:getId()]
	if cached and getTickCount() - cached.tick < 5000 then
		return cached.amount
	end
	local amount = self:queryRegularAttackCount(faction)
	self.m_AttackCountCache[faction:getId()] = {amount = amount, tick = getTickCount()}
	return amount
end

function Gangwar:queryRegularAttackCount(faction)
	local time = getRealTime()
	local midnight = time.timestamp - time.hour*3600 - time.minute*60 - time.second
	local startValue = self:getSetting("AttackStart")
	local endValue = self:getSetting("AttackEnd")
	local startStamp = midnight + math.floor(startValue/100)*3600 + (startValue%100)*60
	local endStamp = midnight + math.floor(endValue/100)*3600 + (endValue%100)*60
	local row = sqlLogs:queryFetchSingle("SELECT COUNT(*) AS Amount FROM ??_Gangwar WHERE Angreifer = ? AND StartZeit >= ? AND StartZeit < ? AND Gewinner <> ?", sqlLogs:getPrefix(), faction.m_Name, startStamp, endStamp, GANGWAR_INVALID_WINNER)
	return row and tonumber(row.Amount) or 0
end

function Gangwar:getFreeSlot()
	for slot = 1, self:getSetting("MaxParallel") do
		if not self.m_Sessions[slot] then
			return slot
		end
	end
	return false
end

function Gangwar:getFactionSession(faction)
	if not faction then return false end
	for _, session in pairs(self.m_Sessions) do
		if session.m_Faction1 == faction or session.m_Faction2 == faction then
			return session
		end
	end
	return false
end

function Gangwar:getAreaUnlockText(area)
	local unlockTime = area.m_LastAttack + GANGWAR_ATTACK_PAUSE*UNIX_TIMESTAMP_24HRS
	if unlockTime <= getRealTime().timestamp then
		return false
	end
	local time = getRealTime(unlockTime)
	return ("Attackierbar ab %02d.%02d. %02d:%02d Uhr"):format(time.monthday, time.month + 1, time.hour, time.minute)
end

function Gangwar:isGangwarHour()
	local time = getRealTime()
	return time.hour*100 + time.minute < self:getSetting("GangwarHourEnd")
end

function Gangwar:getActiveMemberCount(faction)
	local count = 0
	for index, player in ipairs(faction:getOnlinePlayers(true)) do
		if (player.m_JailTime or 0) == 0 and (player.m_PrisonTime or 0) == 0 then
			count = count + 1
		end
	end
	return count
end

function Gangwar:getAttackBlockReason(faction, area, mode)
	if not area or not area.m_Active then return "Gebiet nicht verfügbar" end
	if area.m_Owner == faction:getId() then return "Eigenes Gebiet" end
	if area.m_IsAttacked then return "Wird angegriffen" end

	local owner = FactionManager:getSingleton():getFromId(area.m_Owner)
	if not owner or not self:isGangwarFaction(owner:getId()) then return "Besitzer nimmt nicht teil" end
	if self:getFactionSession(faction) then return "Ihr seid im Gangwar" end
	if self:getFactionSession(owner) then return "Gegner ist im Gangwar" end
	if not self:getFreeSlot() then return "Alle Gangwar-Plätze belegt" end

	local lock = self.m_GangwarGuard:getAttackerLock(faction)
	if lock > 0 then return ("Cooldown: %d Sek."):format(lock) end
	lock = self.m_GangwarGuard:getDefenderLock(owner)
	if lock > 0 then return ("Gegner-Cooldown: %d Sek."):format(lock) end
	lock = self.m_GangwarGuard:getPairLock(faction, owner)
	if lock > 0 then return ("Gleiche Fraktion erst in %d:%02d Min."):format(math.floor(lock/60), lock%60) end

	if mode == "regular" then
		local unlockText = self:getAreaUnlockText(area)
		if unlockText then
			return unlockText
		end
		if not DEBUG then
			if self:getRegularAttackCount(faction) >= self:getSetting("MaxAttacks") then
				return "Attacks aufgebraucht"
			end
			if not self:isGangwarHour() and self:getActiveMemberCount(owner) < self:getSetting("MinPlayers") then
				return "Zu wenige aktive Gegner online"
			end
		end
	elseif mode == "given" and not DEBUG and self:getRegularAttackCount(faction) < self:getSetting("MaxAttacks") then
		return "Erst alle regulären Attacks aufbrauchen"
	end
	return false
end

function Gangwar:getMemberList(faction)
	local list = {}
	for playerId, rank in pairs(faction:getPlayers(true)) do
		local player = Player.getFromId(playerId)
		list[#list + 1] = {id = playerId, name = Account.getNameFromId(playerId) or tostring(playerId), rank = rank, online = player and isElement(player) and player:isLoggedIn() or false}
	end
	table.sort(list, function(a, b)
		if a.rank ~= b.rank then return a.rank > b.rank end
		return a.name < b.name
	end)
	return list
end

function Gangwar:sanitizePicks(faction, ids, requiredId)
	local result, seen = {}, {}
	if type(ids) ~= "table" then return result end
	for _, id in ipairs(ids) do
		id = tonumber(id)
		if id and not seen[id] and faction:getPlayerRank(id) and #result < self:getSetting("MaxPlayers") then
			seen[id] = true
			result[#result + 1] = id
		end
	end
	if requiredId and not seen[requiredId] then
		if #result >= self:getSetting("MaxPlayers") then
			table.remove(result)
		end
		table.insert(result, 1, requiredId)
	end
	return result
end

function Gangwar:sendNpcData(player)
	local faction = player:getFaction()
	if not faction or not self:isGangwarFaction(faction:getId()) then
		player:sendError(_("Deine Fraktion nimmt nicht am Gangwar teil!", player))
		return
	end

	local mode = self:getAttackMode()
	local areas = {}
	for id, area in pairs(self.m_Areas) do
		if area.m_Active then
			local owner = FactionManager:getSingleton():getFromId(area.m_Owner)
			local session = area.m_AttackSession
			local running = false
			if session then
				running = ("%s gegen %s, %s"):format(session.m_Faction1:getShortName(), session.m_Faction2:getShortName(), GANGWAR_PHASE_NAMES[session.m_Phase])
			end
			local unlockText = mode ~= "given" and area.m_Owner ~= faction:getId() and self:getAreaUnlockText(area) or false
			areas[#areas + 1] = {
				id = id,
				name = area.m_Name,
				owner = owner and owner:getShortName() or "-",
				own = area.m_Owner == faction:getId(),
				running = running,
				locked = unlockText and true or false,
				x = area.m_Position[1],
				y = area.m_Position[2],
				blocked = running or unlockText or (mode == "closed" and "Keine Attackzeit") or self:getAttackBlockReason(faction, area, mode),
			}
		end
	end
	table.sort(areas, function(a, b) return a.name < b.name end)

	local session = self:getFactionSession(faction)
	player:triggerEvent("GangwarNpc:open", {
		mode = mode,
		attacksLeft = mode == "regular" and math.max(0, self:getSetting("MaxAttacks") - self:getRegularAttackCount(faction)) or 0,
		maxAttacks = self:getSetting("MaxAttacks"),
		canStart = PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "startGangWar"),
		areas = areas,
		session = session and session:getNpcInfo(player) or false,
		members = self:getMemberList(faction),
		maxPlayers = self:getSetting("MaxPlayers"),
		playerId = player:getId(),
	})
end

function Gangwar:Event_startAttack(areaId, ids)
	local faction = client:getFaction()
	if not faction or not self:isGangwarFaction(faction:getId()) then return end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "faction", "startGangWar") then
		client:sendError(_("Dazu bist du nicht berechtigt!", client))
		return
	end

	if not client:isFactionDuty() then
		client:sendError(_("Du musst im Fraktionsdienst sein!", client))
		return
	end

	local mode = self:getAttackMode()
	if mode == "closed" then
		client:sendError(_("Zurzeit sind keine Attacks möglich!", client))
		return
	end

	local area = self.m_Areas[tonumber(areaId)]
	local reason = self:getAttackBlockReason(faction, area, mode)
	if reason then
		client:sendError(reason)
		return
	end

	local picks = self:sanitizePicks(faction, ids, client:getId())
	local minimum = (mode == "regular" and not DEBUG) and self:getSetting("MinPlayers") or 1
	if #picks < minimum then
		client:sendError(_("Es müssen mindestens %d Spieler eingeteilt werden!", client, minimum))
		return
	end

	local defender = FactionManager:getSingleton():getFromId(area.m_Owner)
	if mode == "regular" then
		self:beginAttack(area, faction, defender, client, picks, false)
		return
	end

	local player = client
	local request = self:createRequest({
		attacker = faction,
		defender = defender,
		text = _("%s möchte das Gebiet %s angreifen. Attack freigeben?", player, faction:getShortName(), area.m_Name),
		candidates = function()
			local list = {}
			for index, member in ipairs(defender:getOnlinePlayers()) do
				if PermissionsManager:getSingleton():hasPlayerPermissionsTo(member, "faction", "giveGangwarAttack") then
					list[#list + 1] = member
				end
			end
			return list
		end,
		rankFaction = defender,
		onAccept = function()
			if self:getAttackMode() ~= "given" or self:getAttackBlockReason(faction, area, "given") then
				faction:sendMessage("[Gangwar] #FFFFFFDer Attack ist nicht mehr möglich!", 200, 0, 0, true)
				return
			end
			self:beginAttack(area, faction, defender, isElement(player) and player or false, picks, true)
		end,
		onDecline = function()
			faction:sendMessage(("[Gangwar] #FFFFFF%s hat den Attack auf %s nicht freigegeben!"):format(defender:getShortName(), area.m_Name), 200, 0, 0, true)
		end,
	})
	if request then
		client:sendInfo(_("Die Anfrage wurde an %s gesendet!", client, defender:getShortName()))
	end
end

function Gangwar:beginAttack(area, attacker, defender, player, picks, isGiven)
	local slot = self:getFreeSlot()
	if not slot then return false end
	local session = area:attack(attacker, defender, player, picks, slot, isGiven)
	if session then
		self.m_Sessions[slot] = session
		session:enterStarter()
	end
	return session
end

function Gangwar:onSessionFinished(session)
	self.m_AttackCountCache = {}
	if self.m_Sessions[session.m_Slot] == session then
		self.m_Sessions[session.m_Slot] = nil
	end
	for id, request in pairs(self.m_Requests) do
		if request.session == session then
			self:closeRequest(id)
		end
	end
end

function Gangwar:addFinishedAttack(record)
	table.insert(self.m_Finished, 1, record)
	self.m_Finished[11] = nil
end

function Gangwar:Event_enter()
	local session = self:getFactionSession(client:getFaction())
	if not session then
		client:sendError(_("Deine Fraktion ist in keinem Gangwar!", client))
		return
	end
	session:tryEnter(client)
end

function Gangwar:Event_submitPick(ids)
	local session = self:getFactionSession(client:getFaction())
	if session then
		session:submitPick(client, ids)
	end
end

function Gangwar:Event_requestPickData()
	local session = self:getFactionSession(client:getFaction())
	if session then
		session:sendPickData(client)
	end
end

function Gangwar:Event_requestLateJoin()
	local session = self:getFactionSession(client:getFaction())
	if session then
		session:requestLateJoin(client)
	end
end

function Gangwar:Event_spawnVehicle(vehicleId)
	local session = client.m_GangwarSession
	if session then
		session:spawnVehicle(client, tonumber(vehicleId))
	end
end

function Gangwar:Event_requestNpcData()
	self:sendNpcData(client)
end

function Gangwar:Event_requestMenu()
	local session = self:getFactionSession(client:getFaction())
	if session then
		client:triggerEvent("GangwarMenu:open", session:getNpcInfo(client))
	end
end

function Gangwar:Event_requestVehicleMenu()
	local session = client.m_GangwarSession
	if session then
		session:requestVehicleMenu(client)
	end
end

function Gangwar:Event_leave()
	local session = client.m_GangwarSession
	if session then
		session:leaveByPlayer(client)
	end
end

function Gangwar:createRequest(config)
	self.m_NextRequestId = self.m_NextRequestId + 1
	local id = self.m_NextRequestId
	config.id = id
	config.timer = setTimer(bind(self.resolveRequest, self), GANGWAR_REQUEST_TIMEOUT*1000, 1, id, false)
	self.m_Requests[id] = config
	if not self:askRequest(id) then
		return false
	end
	return config
end

function Gangwar:askRequest(id)
	local request = self.m_Requests[id]
	if not request then return false end

	local best, bestRank
	for _, player in ipairs(request.candidates()) do
		if isElement(player) and player ~= request.current then
			local rank = request.rankFaction:getPlayerRank(player) or 0
			if not bestRank or rank > bestRank then
				best, bestRank = player, rank
			end
		end
	end

	request.current = best
	if not best then
		self:resolveRequest(id, false)
		return false
	end
	best:triggerEvent("Gangwar:requestQuestion", id, request.text)
	return true
end

function Gangwar:closeRequest(id)
	local request = self.m_Requests[id]
	if not request then return end
	self.m_Requests[id] = nil
	if isTimer(request.timer) then killTimer(request.timer) end
	if request.current and isElement(request.current) then
		request.current:triggerEvent("Gangwar:requestClose", id)
	end
	return request
end

function Gangwar:resolveRequest(id, accepted)
	local request = self:closeRequest(id)
	if not request then return end
	if accepted then
		if request.onAccept then request.onAccept() end
	else
		if request.onDecline then request.onDecline() end
	end
end

function Gangwar:Event_answerRequest(id, accepted)
	local request = self.m_Requests[id]
	if request and request.current == client then
		self:resolveRequest(id, accepted == true)
	end
end

function Gangwar:onCandidateGone(player)
	for id, request in pairs(self.m_Requests) do
		if request.current == player then
			request.current = nil
			nextframe(function()
				self:askRequest(id)
			end)
		end
	end
end

function Gangwar:isDamageAllowed(attacker, target)
	local session = target.m_GangwarSession
	if not session or session ~= attacker.m_GangwarSession then return false end
	if session.m_Phase ~= "battle" then return false end
	if attacker.vehicle then return false end
	return session:isWithinFlagRange(attacker) and session:isWithinFlagRange(target)
end

function Gangwar:onPlayerWasted(player, killer, weapon, bodypart)
	local session = player.m_GangwarSession
	if not session then return end

	player:increaseStatistics("Deaths", 1)
	DamageManager:getSingleton():clearPlayer(player)
	player.m_LastDamagedBy = {}
	if killer and isValidElement(killer, "vehicle") then
		killer = killer.controller
	end
	session:onPlayerWasted(player, killer)
	setTimer(bind(self.respawnAfterDeath, self), GANGWAR_RESPAWN_DELAY, 1, player)
	return true
end

function Gangwar:respawnAfterDeath(player)
	if not isElement(player) or not player.m_GangwarReturn then return end
	local target = player.m_GangwarReturn
	player.m_GangwarRespawn = true
	player:respawn(target.position, target.rotation)
	player.m_GangwarRespawn = false
	self:finishLeave(player)
end

function Gangwar:finishLeave(player)
	local target = player.m_GangwarReturn
	if not target then return end
	player.m_GangwarReturn = nil
	if player:hasTemporaryStorage() then
		player:restoreStorage()
	end
	player:setInterior(target.interior)
	player:setDimension(target.dimension)
	player:setPosition(target.position)
	player:setHunger(player:getHunger())
	player:triggerEvent("Gangwar:leaveWorld")
end

function Gangwar:onPlayerQuit(player)
	local session = player.m_GangwarSession
	if session then
		session:onPlayerQuit(player)
	end
	self:onCandidateGone(player)
	if player.m_GangwarReturn then
		self:finishLeave(player)
	end
end

function Gangwar:onPlayerLeaveFaction(player)
	local session = player.m_GangwarSession
	if session then
		session:eliminate(player)
	end
end

function Gangwar:onPlayerJoin()
	local session = self:getFactionSession(source:getFaction())
	if session then
		session:sendPickStatus(source)
	end
end

function Gangwar:isPlayerInGangwar(player)
	return player.m_GangwarSession ~= nil
end

function Gangwar:getWorldRemovals()
	if not self.m_MapRemovals then
		self.m_MapRemovals = {}
		for index, resource in ipairs(getResources()) do
			if getResourceState(resource) == "running" then
				self:collectMapRemovals(resource)
			end
		end
		self:parseMapRemovalFile(":exo_maps/removals.lua")
		self:parseMapRemovalFile(":exo_maps/textur_removals.lua")
	end

	local list = WorldModelRegistry.getOutdoorEntries()
	for index, entry in ipairs(self.m_MapRemovals) do
		list[#list + 1] = entry
	end
	return list
end

function Gangwar:collectMapRemovals(resource)
	for index, object in ipairs(getElementsByType("removeWorldObject", getResourceRootElement(resource))) do
		local x, y, z = tonumber(getElementData(object, "posX")), tonumber(getElementData(object, "posY")), tonumber(getElementData(object, "posZ"))
		local radius = tonumber(getElementData(object, "radius")) or 0
		local interior = tonumber(getElementData(object, "interior")) or 0
		if (interior == 0 or interior == -1) and x and y and z and radius < 1000 then
			self.m_MapRemovals[#self.m_MapRemovals + 1] = {tonumber(getElementData(object, "model")), radius, x, y, z, interior}
			local lodModel = tonumber(getElementData(object, "lodModel"))
			if lodModel and lodModel ~= 0 then
				self.m_MapRemovals[#self.m_MapRemovals + 1] = {lodModel, radius, x, y, z, interior}
			end
		end
	end
end

function Gangwar:parseMapRemovalFile(path)
	if not fileExists(path) then return end
	local file = fileOpen(path, true)
	if not file then return end
	local content = fileRead(file, fileGetSize(file))
	fileClose(file)
	content = content:gsub("%-%-%[%[.-%]%]", "")
	for line in content:gmatch("[^\r\n]+") do
		local code = line:gsub("%-%-.*$", "")
		local model, radius, x, y, z = code:match("removeWorldModel%s*%(%s*(%d+)%s*,%s*([%d%.]+)%s*,%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)%s*,%s*(%-?[%d%.]+)")
		if model and tonumber(radius) < 1000 then
			self.m_MapRemovals[#self.m_MapRemovals + 1] = {tonumber(model), tonumber(radius), tonumber(x), tonumber(y), tonumber(z), 0}
		end
	end
end

function Gangwar:RESET()
	sql:queryFetch("UPDATE ??_gangwar SET Besitzer='8', lastAttack='0'", sql:getPrefix())
	outputDebugString("Gangwar-areas were reseted!")
end

function Gangwar:getAreas()
	local nowTimestamp = getRealTime().timestamp
	for _, area in pairs(self.m_Areas) do
		if area.m_Active then
			client:triggerEvent("gangwarLoadArea", area:getName(), area:getPosition(), area:getOwnerId(), area:getLastAttack(), nowTimestamp >= area:getLastAttack() + (GANGWAR_ATTACK_PAUSE*UNIX_TIMESTAMP_24HRS), area:getId())
		end
	end
	client:triggerEvent("gangwarLoadAttackLog", GangwarStatistics:getSingleton():getAttackLog())
	client:triggerEvent("gangwarLoadTopList", GangwarStatistics.TopStats["Damage"], GangwarStatistics.TopStats["Kill"], GangwarStatistics.TopStats["MVP"], GangwarStatistics:getSingleton():getPlayerStats(client))
end

function Gangwar:onAreaPayday()
	local counts = {}
	local owned = {}
	for _, area in pairs(self.m_Areas) do
		if area.m_Active then
			counts[area.m_Owner] = (counts[area.m_Owner] or 0) + 1
			owned[area.m_ID] = area.m_Owner
		end
	end

	local baseIncome = self:getSetting("BaseIncome")
	for factionId in pairs(self.m_Factions) do
		local faction = FactionManager:getSingleton():getFromId(factionId)
		if faction then
			local online = #faction:getOnlinePlayers()
			local count = counts[factionId] or 0
			if online > 1 then
				if count > 0 then
					local amount = GANGWAR_PAYOUT_PER_PLAYER*online + GANGWAR_PAYOUT_PER_AREA*count
					self.m_BankAccountServer:transferMoney(faction, amount, "Gangwar-Payday", "Faction", "Gangwar")
					faction:sendMessage("Gangwar-Payday: #FFFFFFEure Fraktion erhält: "..amount.." $ (Pro Online-Member: "..GANGWAR_PAYOUT_PER_PLAYER.." und Pro Gebiet: "..GANGWAR_PAYOUT_PER_AREA.."$)", 0, 200, 0, true)
				end
				self:payAreaBonus(faction, owned)
			elseif count > 0 then
				faction:sendMessage("Gangwar Payday: Es sind nicht genügend Spieler online für den Gangwar-Payday!", 200, 0, 0, true)
			end
			if online > 0 then
				self.m_BankAccountServer:transferMoney(faction, baseIncome, "Grundeinkommen", "Faction", "Grundeinkommen")
				faction:sendMessage("Fraktions Payday: Grundeinkommen der Fraktion: "..baseIncome.."$ !", 0, 200, 0, true)
			end
		end
	end
end

function Gangwar:payAreaBonus(faction, owned)
	for _, bonus in pairs(self.m_Bonus) do
		local complete, activeAreas = true, 0
		for _, areaId in ipairs(bonus.areas) do
			if owned[areaId] then
				activeAreas = activeAreas + 1
				if owned[areaId] ~= faction:getId() then
					complete = false
				end
			end
		end
		if complete and activeAreas > 0 then
			self.m_BankAccountServer:transferMoney(faction, bonus.amount, "Gebietsbonus: "..bonus.name, "Faction", "Gangwar")
			faction:sendMessage(("Gebietsbonus: #FFFFFF%s bringt eurer Fraktion %d $!"):format(bonus.name, bonus.amount), 0, 200, 0, true)
		end
	end
end

function Gangwar:isAdminAllowed(player)
	return player and player:getRank() >= ADMIN_RANK_PERMISSION["eventGangwarMenu"]
end

function Gangwar:sendAdminData(player)
	local areas = {}
	for id, area in pairs(self.m_Areas) do
		local owner = FactionManager:getSingleton():getFromId(area.m_Owner)
		areas[#areas + 1] = {
			id = id, name = area.m_Name, owner = owner and owner:getShortName() or "-", ownerId = area.m_Owner, lastAttack = area.m_LastAttack,
			active = area.m_Active, attacked = area.m_IsAttacked and true or false, cars = area.m_CarCount,
			x = area.m_Position[1], y = area.m_Position[2], banned = area:getBannedVehicleList(),
		}
	end
	table.sort(areas, function(a, b) return a.name < b.name end)

	local running = {}
	for slot, session in pairs(self.m_Sessions) do
		if session.m_Phase ~= "end" then
			running[#running + 1] = {slot = slot, area = session.m_AreaObj.m_Name, attacker = session.m_Faction1:getShortName(), defender = session.m_Faction2:getShortName(), phase = session.m_Phase}
		end
	end

	local finished = {}
	for index, record in ipairs(self.m_Finished) do
		finished[#finished + 1] = {index = index, area = record.areaName, attacker = record.attacker:getShortName(), defender = record.defender:getShortName(), winner = record.winnerName, invalid = record.invalid}
	end

	local factions = {}
	for factionId, config in pairs(self.m_Factions) do
		local faction = FactionManager:getSingleton():getFromId(factionId)
		if faction then
			factions[#factions + 1] = {id = factionId, name = faction:getShortName(), hasSpawn = config.spawn ~= nil}
		end
	end
	table.sort(factions, function(a, b) return a.name < b.name end)
	local globalBans = {}
	for model in pairs(self.m_BannedVehicles) do
		globalBans[#globalBans + 1] = model
	end
	player:triggerEvent("gangwarAdminData", areas, running, finished, factions, self:getKnownVehicleModels(), globalBans)
end

function Gangwar:Event_adminGetData()
	if self:isAdminAllowed(client) then
		self:sendAdminData(client)
	end
end

function Gangwar:Event_adminCreateArea(name)
	if not self:isAdminAllowed(client) or type(name) ~= "string" or #name == 0 then return end
	local x, y, z = getElementPosition(client)
	x, y, z = math.floor(x), math.floor(y), math.floor(z)
	local owner = next(self.m_Factions) or 5
	local result, _numrows, insertId = sql:queryFetch("INSERT INTO ??_gangwar (Name, Besitzer, x, y, z, cX, cY, cX2, cY2, lastAttack, Autos, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 4, 0)",
		sql:getPrefix(), name, owner, x, y, z, x - 50, y - 50, x + 50, y + 50)
	if not result or not insertId then
		client:sendError(_("Das Gebiet konnte nicht angelegt werden!", client))
		return
	end
	self.m_Areas[insertId] = Area:new({ID = insertId, Name = name, Besitzer = owner, x = x, y = y, z = z, cX = x - 50, cY = y - 50, cX2 = x + 50, cY2 = y + 50, lastAttack = 0, Autos = 4, active = 0}, self)
	StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Gebiet", "Neues Gebiet: "..name)
	client:sendInfo(_("Das Gebiet wurde angelegt und ist noch inaktiv. Stelle nun Flagge und Ecken ein!", client))
	self:sendAdminData(client)
end

function Gangwar:Event_adminEditArea(areaId, field, value)
	if not self:isAdminAllowed(client) then return end
	local area = self.m_Areas[tonumber(areaId)]
	if not area then return end
	if area.m_IsAttacked then
		client:sendError(_("Das Gebiet wird gerade angegriffen!", client))
		return
	end

	local x, y, z = getElementPosition(client)
	x, y, z = math.floor(x), math.floor(y), math.floor(z)
	if field == "flag" then
		area.m_Position = {x, y, z}
	elseif field == "corner1" then
		area:setCorner(1, x, y)
	elseif field == "corner2" then
		area:setCorner(2, x, y)
	elseif field == "name" and type(value) == "string" and #value > 0 then
		area.m_Name = value
	elseif field == "cars" and tonumber(value) then
		area.m_CarCount = math.max(0, math.floor(tonumber(value)))
	elseif field == "active" then
		area.m_Active = not area.m_Active
	else
		return
	end

	area:saveConfig()
	area:refreshRadar()
	if field == "flag" or field == "cars" then
		GangwarMapEditor:getSingleton():refreshPreview(area.m_ID)
	end
	StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Gebiet", ("Gebiet: %s; Geändert: %s"):format(area.m_Name, field))
	self:sendAdminData(client)
end

function Gangwar:Event_adminSetNpc(factionId)
	if not self:isAdminAllowed(client) then return end
	factionId = tonumber(factionId)
	if not factionId or not FactionManager:getSingleton():getFromId(factionId) then return end
	local x, y, z = getElementPosition(client)
	local _rx, _ry, rotation = getElementRotation(client)
	local config = {x = x, y = y, z = z, rot = rotation, interior = client:getInterior(), dimension = client:getDimension(), spawn = self.m_Factions[factionId] and self.m_Factions[factionId].spawn}
	sql:queryExec("INSERT INTO ??_gangwar_factions (FactionId, NpcX, NpcY, NpcZ, NpcRot, NpcInterior, NpcDimension) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE NpcX = VALUES(NpcX), NpcY = VALUES(NpcY), NpcZ = VALUES(NpcZ), NpcRot = VALUES(NpcRot), NpcInterior = VALUES(NpcInterior), NpcDimension = VALUES(NpcDimension)",
		sql:getPrefix(), factionId, x, y, z, rotation, config.interior, config.dimension)
	self.m_Factions[factionId] = config
	self:createNpc(factionId, config)
	client:sendInfo(_("Der Gangwar-NPC wurde an deine Position gesetzt!", client))
	self:sendAdminData(client)
end

function Gangwar:Event_adminSetSpawn(factionId)
	if not self:isAdminAllowed(client) then return end
	factionId = tonumber(factionId)
	local config = factionId and self.m_Factions[factionId]
	if not config then
		client:sendError(_("Diese Fraktion nimmt nicht am Gangwar teil!", client))
		return
	end
	if client:getInterior() ~= 0 then
		client:sendError(_("Der Spawn muss außerhalb von Interiors liegen!", client))
		return
	end
	local x, y, z = getElementPosition(client)
	sql:queryExec("UPDATE ??_gangwar_factions SET SpawnX = ?, SpawnY = ?, SpawnZ = ? WHERE FactionId = ?", sql:getPrefix(), x, y, z, factionId)
	config.spawn = {x, y, z}
	StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Spawn", "Fraktion: "..factionId)
	client:sendInfo(_("Der Gangwar-Spawn der Fraktion wurde an deine Position gesetzt!", client))
	self:sendAdminData(client)
end

function Gangwar:Event_adminToggleBan(scope, model)
	if not self:isAdminAllowed(client) then return end
	scope, model = tonumber(scope), tonumber(model)
	if not scope or not model then return end

	if scope == 0 then
		if self.m_BannedVehicles[model] then
			self.m_BannedVehicles[model] = nil
			sql:queryExec("DELETE FROM ??_gangwar_banned_vehicles WHERE Model = ?", sql:getPrefix(), model)
		else
			self.m_BannedVehicles[model] = true
			sql:queryExec("INSERT IGNORE INTO ??_gangwar_banned_vehicles (Model) VALUES (?)", sql:getPrefix(), model)
		end
		StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Fahrzeug", "Alle Gebiete, Modell: "..model)
	else
		local area = self.m_Areas[scope]
		if not area then return end
		area.m_BannedVehicles[model] = (not area.m_BannedVehicles[model]) or nil
		area:saveConfig()
		StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Fahrzeug", "Gebiet: "..area.m_Name..", Modell: "..model)
	end
	self:sendAdminData(client)
end

function Gangwar:Event_adminInvalidate(kind, id)
	if not self:isAdminAllowed(client) then return end
	if kind == "running" then
		local session = self.m_Sessions[tonumber(id)]
		if session then
			Admin:getSingleton():sendShortMessage("%s hat den Attack auf %s für ungültig erklärt!", {client:getName(), session.m_AreaObj.m_Name})
			StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Ungültig", "Gebiet: "..session.m_AreaObj.m_Name)
			session:cancelWithoutRating()
		end
	elseif kind == "finished" then
		local record = self.m_Finished[tonumber(id)]
		if record and not record.invalid then
			self:invalidateFinished(record)
			Admin:getSingleton():sendShortMessage("%s hat den Attack auf %s für ungültig erklärt!", {client:getName(), record.areaName})
			StatisticsLogger:getSingleton():addAdminAction(client, "Gangwar-Ungültig", "Gebiet: "..record.areaName)
		end
	end
	self:sendAdminData(client)
end

function Gangwar:invalidateFinished(record)
	record.invalid = true
	self.m_AttackCountCache = {}
	local area = self.m_Areas[record.areaId]
	if area and (not area.m_IsAttacked or area.m_AttackSession.m_Phase == "end") then
		area.m_Owner = record.previousOwner
		area.m_LastAttack = record.previousLastAttack
		area:update()
		area:refreshRadar()
	end
	sqlLogs:queryExec("UPDATE ??_Gangwar SET Gewinner = ? WHERE Gebiet = ? AND Angreifer = ? AND StartZeit = ?", sqlLogs:getPrefix(), GANGWAR_INVALID_WINNER, record.areaName, record.attacker.m_Name, record.startTime)
	GangwarStatistics:getSingleton():markAttackLogInvalid(record.areaName, record.attacker.m_Name, record.startTime)
	self.m_GangwarGuard:clearAfterAttack(record.attacker, record.defender)
	local message = ("[Gangwar] #FFFFFFDer Attack auf %s wurde von einem Admin für ungültig erklärt und nicht gewertet!"):format(record.areaName)
	record.attacker:sendMessage(message, 200, 120, 0, true)
	record.defender:sendMessage(message, 200, 120, 0, true)
end
