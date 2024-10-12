-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Race/RaceManager.lua
-- *  PURPOSE:     Race Manager class
-- *
-- ****************************************************************************

RaceManager = inherit(Singleton)

addRemoteEvents{"raceJoinLobby", "raceLeaveLobby", "raceCreateLobby"}

RaceManager.Maps = {
    ":orl_maps/Race/dd-ninetowers.map",
	":orl_maps/Race/dd-fourtowers.map",
	":orl_maps/Race/dd-fivetowers.map",
	":orl_maps/Race/dd-bigtower.map",
	":orl_maps/Race/dd-seventowers.map",
}

RaceManager.Lobbys = { }

RaceManager.DDInvalidVehicles = {
	-- Airplanes
	[592] = true, -- Andromada
	[577] = true, -- AT-400
	[553] = true, -- Nevada
	[460] = true, -- Skimmer
	-- Boats
	[472] = true, -- Coastguard
	[473] = true, -- Dinghy
	[493] = true, -- Jetmax
	[595] = true, -- Launch
	[484] = true, -- Marquis
	[430] = true, -- Predator
	[453] = true, -- Reefer
	[452] = true, -- Speeder
	[446] = true, -- Squalo
	[454] = true, -- Tropic
	-- Bikes
	[509] = true, -- Bike
	[481] = true, -- BMX
	[510] = true, -- Mountain Bike
	-- Government vehicles
	[544] = true, -- Fire Truck
	-- RC Vehicles
	[441] = true, -- RC Bandit
	[464] = true, -- RC Baron
	[594] = true, -- RC Cam
	[501] = true, -- RC Goblin
	[465] = true, -- RC Raider
	[564] = true, -- RC Tiger
	-- Trailers
	[606] = true, -- Baggage Trailer
	[607] = true, -- Baggage Trailer
	[610] = true, -- Farm Trailer
	[584] = true, -- Petrol trailer
	[611] = true, -- Trailer
	[608] = true, -- Trailer
	[435] = true, -- Trailer 1
	[450] = true, -- Trailer 2
	[591] = true, -- Trailer 3
	-- Trains & Railroad cars
	[590] = true, -- Box Freight
	[538] = true, -- Brown Streak
	[570] = true, -- Brown Streak Carriage
	[569] = true, -- Flat Freight
	[537] = true, -- Freight
	[449] = true, -- Tram
	-- Recreational
	[539] = true, -- Vortex
}

RaceManager.DDWarningVehicles = {
	-- Airplanes
	[520] = true, -- Hydra
	[476] = true, -- Rustler
	-- Helicopters
	[425] = true, -- Hunter
	[447] = true, -- Seasparrow
	-- Government vehicles
	[432] = true, -- Rhino
}

function RaceManager:constructor()
    self.m_BankServer = BankServer.get("gameplay.race") or BankServer:create("gameplay.race")

    self.m_RaceMarker = createMarker(2728.17, -1827.92, 10.9, "cylinder", 1, 255, 255, 255)
    self.m_RaceBlip = Blip:new("Kart.png", 2728.17, -1827.92)
    self.m_RaceBlip:setDisplayText("Destruction Derby", BLIP_CATEGORY.Leisure)

    self.m_Maps = {}
    self.m_MapIndex = {}

	for k, v in pairs(RaceManager.Maps) do
		if fileExists(v) then
			local mapFileName = v:match("[^/]+$"):sub(0, -5)
			if mapFileName then
				local instance = MapParser:new(v)
				self.m_Maps[mapFileName] = instance
				table.insert(self.m_MapIndex, mapFileName)
			else
				outputDebug(("Can't load map file '%s'. Cant resolve filename from path"):format(v))
			end
		end
	end

    nextframe(function()
        self:createLobby("Server1", "Server Lobby #1", false, 15, true, self:getRandomMap())
        self:createLobby("Server2", "Server Lobby #2", false, 15, true, self:getRandomMap())
        self:createLobby("Server3", "Server Lobby #3", false, 15, true, self:getRandomMap())
    end)

    addEventHandler("onMarkerHit", self.m_RaceMarker, bind(self.Event_onMarkerHit, self))

	addEventHandler("raceJoinLobby", root, function(lobbyOwner, password)
		local lobby = RaceManager.Lobbys[lobbyOwner]
		if not lobby then 
			client:sendError(_"Diese Lobby existiert nicht!")
			return
		end
		if #lobby.m_Players >= lobby.m_MaxPlayers then
			client:sendError(_"Diese Lobby ist voll!")
			return
		end
		if lobby.m_LobbyPassword and lobby.m_LobbyPassword ~= password then
			client:sendError(_"Falsches Passwort!")
			return
		end
		lobby:addPlayer(client)
	end)

	addEventHandler("raceLeaveLobby", root, function()
		if client.raceLobby then
			client.raceLobby:removePlayer(client)
		end
	end)

	addEventHandler("raceCreateLobby", root, function(password, maxPlayers, mapFileName)
		if source ~= client then return end
		if RaceManager.Lobbys[client] then return end

		local requiredMoney = 500
		if client:getMoney() >= requiredMoney then 
			client:transferMoney(self.m_BankServer, requiredMoney, "Destruction Derby Lobby", "Gameplay", "Race")
		else
			return client:sendError(_("Du hast nicht genug Geld dabei! (%d$)", client, requiredMoney)) 
		end

		RaceManager:createLobby(client, ("%ss Lobby"):format(client:getName()), password, maxPlayers, false, mapFileName)
		RaceManager.Lobbys[client]:addPlayer(client)
	end)

    Player.getChatHook():register(
		function(player, text, type)
			if player.raceLobby then
				return player.raceLobby:onPlayerChat(player, text, type)
			end
		end
	)

    Player.getQuitHook():register(
		function(player)
			if player.raceLobby then
				player.raceLobby:removePlayer(player)
			end
		end
	)

    PlayerManager:getSingleton():getWastedHook():register(
		function(player, killer, weapon)
			if player.raceLobby then
                if player:isInVehicle() then player:removeFromVehicle() end

                nextframe(function()
                    player:respawn()
					player:setDimension(player.raceLobby.m_LobbyDimension)
					toggleAllControls(player, false, true, false)
                    FactionRescue:getSingleton():removePedDeathPickup(player)
                    player:triggerEvent("abortDeathGUI", true)
                    player.raceLobby:disqualifyPlayer(player)
					player:triggerEvent("HUDRadar:hideRadar")
                end)

                return true
            end
		end
	)
    
    PlayerManager:getSingleton():getAFKHook():register(
		function(player)
			if player.raceLobby then
				player.raceLobby:removePlayer(player)
			end
		end
	)

    core:getStopHook():register(
		function()
			for id, lobby in pairs(RaceManager.Lobbys) do
				for i, player in pairs(lobby.m_Players) do
					lobby:removePlayer(player)
				end
			end
		end
	)
end

function RaceManager:getRandomMap()
    return self.m_MapIndex[math.random(1, #self.m_MapIndex)]
end

function RaceManager:Event_onMarkerHit(hitElement, matchingDimension)
    if hitElement:getType() == "player" and matchingDimension and hitElement:isLoggedIn() and not hitElement.inVehicle then
		local lobbyTable, mapTable = {}, {}
		for i, lobby in pairs(RaceManager.Lobbys) do
			lobbyTable[i] = {
				["Password"] = lobby.m_LobbyPassword and true or false,
				["Players"] = #lobby.m_Players,
				["MaxPlayers"] = lobby.m_MaxPlayers,
				["Name"] = lobby.m_LobbyName,
				["Map"] = lobby.m_MapName,
				["MapAuthor"] = lobby.m_Map:getMapAuthor() or "Unbekannt",
				["Owner"] = lobby.m_LobbyOwner,
			}
		end
		for i, mapFileName in pairs(self.m_MapIndex) do
			mapTable[mapFileName] = self.m_Maps[mapFileName]:getMapName() or mapFileName
		end
        hitElement:triggerEvent("raceOpenLobbyGUI", source, lobbyTable, mapTable)
    end
end

function RaceManager:createLobby(lobbyOwner, lobbyName, password, maxPlayers, isPermanent, mapFileName)
    RaceManager.Lobbys[lobbyOwner] = Race:new(lobbyOwner, lobbyName, password, maxPlayers, isPermanent, mapFileName)
end

function RaceManager:deleteLobby(lobbyOwner)
    RaceManager.Lobbys[lobbyOwner] = nil
end