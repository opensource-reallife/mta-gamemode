-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Race/Race.lua
-- *  PURPOSE:     Race class
-- *
-- ****************************************************************************

Race = inherit(Object)

function Race:constructor(lobbyOwner, lobbyName, password, maxPlayers, isPermanent, mapFileName)
    self.m_LobbyOwner = lobbyOwner
    self.m_LobbyName = lobbyName
    self.m_PermanentLobby = isPermanent
    self.m_LobbyPassword = password
    self.m_MaxPlayers = maxPlayers
    self.m_LobbyDimension = DimensionManager:getSingleton():getFreeDimension()
    
    self.m_Players = {}
    self.m_PlayerScore = {}
    self.m_PlayerVehicle = {}

    self.m_Map = false
    self.m_MapId = false
    self.m_MapName = ""

    self.m_Mode = false

    self.m_RoundCounter = 1
    self.m_StartRoundTimer = false

    self.m_Checkpoints = {}
    self.m_Spawnpoints = {}

    self.m_DDCheckpointHitFunc = bind(self.Event_DDCheckpointHit, self)
    self.m_DDCurrentCheckpoint = false

    self.m_WaterCheckTimer = Timer(function()
        for k, v in pairs(self.m_PlayerVehicle) do
            if isElement(v) and v:isInWater() then v:getController():kill() end
        end
    end, 3000, 0)

    self:changeMap(mapFileName)
end

function Race:changeMap(mapFileName)
    self:endRound()
	self:unloadMap()

    if not mapFileName then
        mapFileName = RaceManager:getSingleton():getRandomMap()
    end

    self:loadMap(mapFileName)

    local mapName = RaceManager:getSingleton().m_Maps[mapFileName]:getMapName()
    local mapAuthor = RaceManager:getSingleton().m_Maps[mapFileName]:getMapAuthor()
    self:sendShortMessage(("Die Karte wurde zu '%s' von %s geändert."):format(mapName, mapAuthor))
end

function Race:loadMap(mapFileName)
	if not RaceManager:getSingleton().m_Maps[mapFileName] then return end

	self.m_Map = RaceManager:getSingleton().m_Maps[mapFileName]
    self.m_MapName = self.m_Map:getMapName() or mapFileName
	self.m_MapId = self.m_Map:create(self.m_LobbyDimension)

    self.m_Mode = string.match(mapFileName, "^(.-)%s*%-")

	self.m_Checkpoints = self.m_Map:getElementsByType("checkpoint", self.m_MapId)
	self.m_Spawnpoints = self.m_Map:getElementsByType("spawnpoint", self.m_MapId)
end

function Race:unloadMap()
	if self.m_Map then self.m_Map:destroy(self.m_MapId) end
end

function Race:addPlayer(player)
    table.insert(self.m_Players, player)
    takeAllWeapons(player)
    player:setDimension(self.m_LobbyDimension)
    player:createStorage(false)
    player:sendShortMessage(("Du hast die Lobby '%s' betreten."):format(self.m_LobbyName))
    player.raceLobby = self
    player:triggerEvent("setCanBeKnockedOffBike", false)
    player:triggerEvent("HUDRadar:hideRadar")
    player:triggerEvent("raceOpenMatchGUI")

    self.m_PlayerScore[player] = "-"
    for k, player in pairs(self.m_Players) do
        player:triggerEvent("raceRefreshMatchGUI", self.m_Players, self.m_PlayerScore)
    end

    self:setSpectator(player)

    if #self.m_Players <= 1 then
        self:prepareRound()
    end
end

function Race:removePlayer(player)
    self:disqualifyPlayer(player)
    if player:getOccupiedVehicle() then player:removeFromVehicle() end
    if isElement(self.m_PlayerVehicle[player]) then self.m_PlayerVehicle[player]:destroy() end
    table.removevalue(self.m_Players, player)
    player:setDimension(0)
    player:restoreStorage()
    player:sendShortMessage(("Du hast die Lobby '%s' verlassen."):format(self.m_LobbyName))
    toggleAllControls(player, true)
    player:toggleControl("enter_exit", true)
    player:triggerEvent("setCanBeKnockedOffBike", true)
    player:triggerEvent("HUDRadar:showRadar")
    player:triggerEvent("raceCloseMatchGUI")
    player:setPosition(2727, -1836, 11)
    player:setCameraTarget(player)
    player.raceLobby = nil
    self.m_PlayerScore[player] = nil

    if player == self.m_LobbyOwner then
        delete(self)
    end
end

function Race:disqualifyPlayer(player)
    if isElement(self.m_PlayerVehicle[player]) then
        player:removeFromVehicle()
        self.m_PlayerVehicle[player]:destroy()
    end
    self.m_PlayerVehicle[player] = nil

    self.m_PlayerScore[player] = table.size(self.m_PlayerVehicle) + 1
    if self.m_PlayerScore[player] == 1 then self:prepareRound() end
    for k, v in pairs(self.m_PlayerVehicle) do
        if table.size(self.m_PlayerVehicle) == 1 then
            self.m_PlayerScore[k] = 1
            self:sendShortMessage(("%s gewinnt!"):format(k:getName()))
            self:prepareRound()
        end
    end

    for k, player in pairs(self.m_Players) do
        player:triggerEvent("raceRefreshMatchGUI", self.m_Players, self.m_PlayerScore)
    end

    self:setSpectator(player)
end

function Race:setSpectator(player)
    player:setPosition(2690.84, -1700.05, 10.44)
    player:setCameraMatrix(2828, -1867, 51, 2797.49, -1831, 30)
    toggleAllControls(player, false, true, false)
end

function Race:onPlayerChat(player, text, type)
	if type == 0 then
		local receivedPlayers = {}
		for i, playeritem in pairs(self.m_Players) do
			playeritem:outputChat(("[%s] #808080%s: %s"):format("Destruction Derby", player:getName(), text), 125, 255, 0, true)
			if playeritem ~= player then
				receivedPlayers[#receivedPlayers+1] = playeritem
			end
		end
		StatisticsLogger:getSingleton():addChatLog(player, "race", text, receivedPlayers)
		return true
	end
end

function Race:sendShortMessage(text, ...)
	local color = {139, 102, 229}
	for k, player in pairs(self.m_Players) do
		player:sendShortMessage(_(text, player), "Destruction Derby", color, ...)
	end
end

function Race:prepareRound()
    self:endRound()

    if self.m_RoundCounter >= 4 then self:changeMap() self.m_RoundCounter = 1 end

    if self.m_StartRoundTimer and self.m_StartRoundTimer:isValid() then self.m_StartRoundTimer:destroy() end
    self.m_StartRoundTimer = Timer(function()
        if #self.m_Players >= 1 then self:startRound() end
    end, 5000, 1)
end

function Race:startRound()
    self:endRound()

    if self.m_RoundCounter == 3 then self:sendShortMessage("Die Karte wird nach dieser Runde geändert!") end
    if self.m_PermanentLobby then self.m_RoundCounter = self.m_RoundCounter + 1 end

    -- prepare players
    for i, player in pairs(self.m_Players) do
        self.m_PlayerScore[player] = "-"
        for k, player in pairs(self.m_Players) do
            player:triggerEvent("raceRefreshMatchGUI", self.m_Players, self.m_PlayerScore)
        end

        local spawnpoint = self.m_Spawnpoints[i]
        local vehicle = TemporaryVehicle.create(spawnpoint.model, spawnpoint.x, spawnpoint.y, spawnpoint.z, spawnpoint.rz)

        self.m_PlayerVehicle[player] = vehicle

        vehicle:setDimension(self.m_LobbyDimension)
        vehicle:setFrozen(true)
        vehicle:setEngineState(true)
        vehicle.m_DisableToggleEngine = true
        vehicle.m_DisableToggleHandbrake = true
        vehicle:setData("disableSpeedLimit", true, true)
        vehicle:setData("disableDamageCheck", true, true)
        vehicle:setData("disableCollisionCheck", true, true)

        player.m_SeatBelt = vehicle
        player:setData("isBuckeled", true, true)

        toggleAllControls(player, true)
        player:toggleControl("enter_exit", false)
        player:warpIntoVehicle(vehicle)
        player:setCameraTarget(player)

        Timer(function()
            if isElement(vehicle) then
                playSoundFrontEnd(player, 44)
            end
        end, 1000, 3)

        Timer(function()
            if isElement(vehicle) then
                playSoundFrontEnd(player, 45)
                vehicle:setFrozen(false)
            end
        end, 4000, 1)
    end

    -- load mode
    if self.m_Mode == "dd" then
        if #self.m_Checkpoints >= 1 then
            for i, checkpoint in pairs(self.m_Checkpoints) do
                checkpoint:setVisibleTo(root, false)
                checkpoint:setColor(0, 0, 255, 255)
                checkpoint:setType("checkpoint")
            end

            local checkpoint = self.m_Checkpoints[Randomizer:get(1, #self.m_Checkpoints)]
            addEventHandler("onMarkerHit", checkpoint, self.m_DDCheckpointHitFunc)
            checkpoint:setVisibleTo(root, true)
            self.m_DDCurrentCheckpoint = checkpoint
        end
    else
        self:sendShortMessage("Fehler: Ungültiger Modus!")
        delete(self)
    end
end

function Race:Event_DDCheckpointHit(hitElement)
    if hitElement:getType() ~= "vehicle" then return end

    local vehicleID = Randomizer:get(400, 611)
    if RaceManager.DDInvalidVehicles[vehicleID] then
        vehicleID = 549
    end

    local pos = hitElement:getPosition()
    local controller = hitElement:getController()
    hitElement:setPosition(pos.x, pos.y, pos.z + 3)
    hitElement:setModel(vehicleID)
    hitElement:fix()
    hitElement:setFuel(100)
    hitElement:setEngineState(true)

    controller:removeFromVehicle()
    controller.m_SeatBelt = vehicle
    controller:setData("isBuckeled", true, true)
    controller:warpIntoVehicle(hitElement)

    if RaceManager.DDWarningVehicles[vehicleID] then
        self:sendShortMessage(("%s hat eine/n %s erhalten!"):format(controller:getName(), hitElement:getName()))
    end

    removeEventHandler("onMarkerHit", source, self.m_DDCheckpointHitFunc)
    source:setVisibleTo(root, false)

    local checkpoint = self.m_Checkpoints[Randomizer:get(1, #self.m_Checkpoints)]
    addEventHandler("onMarkerHit", checkpoint, self.m_DDCheckpointHitFunc)
    checkpoint:setVisibleTo(root, true)
    self.m_DDCurrentCheckpoint = checkpoint
end

function Race:endRound()
    -- destroy all remaining player vehicles
    for k, v in pairs(self.m_PlayerVehicle) do
        if isElement(v) then
            k:removeFromVehicle()
            v:destroy()
        end
    end

    -- cleanup dd checkpoint if needed
    local checkpoint = self.m_DDCurrentCheckpoint
    if checkpoint then
        removeEventHandler("onMarkerHit", checkpoint, self.m_DDCheckpointHitFunc)
        checkpoint:setVisibleTo(root, false)
        self.m_DDCurrentCheckpoint = false
    end

    -- make players spectators
    for k, player in pairs(self.m_Players) do
        self:setSpectator(player)
    end
end

-- Destructor
function Race:destructor()
    self:endRound()
    self:unloadMap()
    self.m_WaterCheckTimer:destroy()
    for k, v in pairs(self.m_Players) do
        self:removePlayer(v)
    end
    DimensionManager:getSingleton():freeDimension(self.m_LobbyDimension)
    RaceManager:getSingleton():deleteLobby(self.m_LobbyOwner)
end