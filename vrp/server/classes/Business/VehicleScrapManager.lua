-- ****************************************************************************
-- *
-- *  PROJECT:     OpenReallife
-- *  FILE:        server/classes/Business/VehicleScrapManager.lua
-- *  PURPOSE:     manager for vehicle scrapping missions for mechanic
-- *
-- ****************************************************************************

VehicleScrapManager = inherit(Singleton)
VehicleScrapManager.LoadUpMarker = Vector3(849.74, -1171.97, 17.27)
VehicleScrapManager.UnloadMarker = Vector3(866.90, -1169.41, 17.27)

-- ggf. Fahrzeugwracks in DB und random auf Map spawnen lassen bei Auftragannahme (macht mehr sinn für distance check und abwechselungsreichere Routen)

VehicleScrapManager.ScrapPricePerKm = 3

addRemoteEvents{"mechanicScrapRouteStart"}


function VehicleScrapManager:constructor()
    self.m_ScrapMarkers = {} -- all scrap markers
    self.m_VehiclesOnRoute = {} -- vehicles that are currently on a scrap route
    self.m_VehicleObjectsToScrap = {} -- objects of vehicles to scrap, and be attached to the scrap truck

	self.m_StartMarker = createMarker(VehicleScrapManager.LoadUpMarker, "cylinder", 3, 255, 0, 0, 150)
	self.m_StartMarker:setVisibleTo(root, false)

	self.m_BankAccountServer = BankServer.get("company.mechanic")

	addEventHandler("mechanicScrapRouteStart", root, bind(self.startCarScrapRoute_Event, self))
end

function VehicleScrapManager:startCarScrapRoute_Event(player)
	if self.m_ScrapMarkers[client.vehicle:getId()] or self.m_VehicleObjectsToScrap[client.vehicle:getId()] then return client:sendError("Du hast bereits eine Verschrottungsroute gestartet!") end
	if client:getCompany() and client:getCompany():getId() ~= CompanyStaticId.MECHANIC then client:sendError("Wie zum Teufel hast du das geschafft?") return end
	if client:getCompany() and client:getCompany():getId() == CompanyStaticId.MECHANIC and client:isCompanyDuty() then

		self.m_StartBlip = Blip:new("Marker.png", VehicleScrapManager.LoadUpMarker.x, VehicleScrapManager.LoadUpMarker.y, client, 9999, BLIP_COLOR_CONSTANTS.Green)
		self.m_StartBlip:setDisplayText("Mechaniker: Fahrzeugverschrottung")
		self.m_StartMarker:setVisibleTo(client, true)

		client.vehicle:setData("Mechanic_ScrapObject", false)
		client:sendInfo("Die Verschrottung des Wracks wurde gestartet. Fahre zum Schrottplatz und lade das Wrack ab.")
		
		addEventHandler("onMarkerHit", self.m_StartMarker, bind(self.Event_onStartMarkerHit, self))
		addEventHandler("onVehicleExit", client.vehicle, bind(self.Event_onVehicleExit, self))
		addEventHandler("onVehicleDestroy", client.vehicle, bind(self.Event_onVehicleDestroy, self))

		PlayerManager:getSingleton():getQuitHook():register(bind(self.Event_onPlayerQuit, self))
	end
end

function VehicleScrapManager:stopPlayerCarScrapRoute(player, vehicle)
	outputChatBox(player)
	outputChatBox(tostring(vehicle).. "" ..tostring(vehicle:getId()))
	if self.m_ScrapMarkers[vehicle:getId()] then
		self.m_ScrapMarkers[vehicle:getId()]:destroy()
		self.m_ScrapMarkers[vehicle:getId()] = nil
	end
	if self.m_VehicleObjectsToScrap[vehicle:getId()] then
		self.m_VehicleObjectsToScrap[vehicle:getId()]:destroy()
		self.m_VehicleObjectsToScrap[vehicle:getId()] = nil
	end
	vehicle:setData("Mechanic_ScrapObject", nil, true)

	if isElement(self.m_StartBlip) then
		self.m_StartBlip:destroy()
		self.m_StartBlip = nil
	end

	self.m_StartMarker:setVisibleTo(player, false)

	player:sendInfo("Die Verschrottungsroute wurde abgebrochen.")

	removeEventHandler("onMarkerHit", self.m_StartMarker, bind(self.Event_onStartMarkerHit, self))
	removeEventHandler("onVehicleExit", player.vehicle, bind(self.Event_onVehicleExit, self))
	removeEventHandler("onVehicleDestroy", player.vehicle, bind(self.Event_onVehicleDestroy, self))
end

-- // Events

function VehicleScrapManager:Event_onStartMarkerHit(hitElement, matchingDimension)
	if getElementType(hitElement) ~= "player" then return end
	if hitElement:getCompany() and hitElement:getCompany():getId() ~= CompanyStaticId.MECHANIC then return end
	if hitElement.vehicle:getCompany() and hitElement.vehicle:getCompany():getId() ~= CompanyStaticId.MECHANIC and hitElement:getData("Mechanic_DFT") then return hitElement:sendError(_("Falsches Fahrzeug"), hitElement) end
	if not hitElement:isCompanyDuty() then return end
	if hitElement.vehicle:getData("Mechanic_ScrapObject") then return end

	hitElement.vehicle:setData("Mechanic_ScrapObject", true, true)

	local pos = hitElement.vehicle:getPosition()
	local rot = hitElement.vehicle:getRotation()

	self.m_ScrapMarkers[hitElement.vehicle:getId()] = createMarker(VehicleScrapManager.UnloadMarker, "cylinder", 3, 0, 255, 0, 150)

	self.m_VehicleObjectsToScrap[hitElement.vehicle:getId()] = createObject(3594, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z)
	self.m_VehicleObjectsToScrap[hitElement.vehicle:getId()]:attach(hitElement.vehicle, 0, -1, 0.8, 0, 0, 0)
	self.m_VehicleObjectsToScrap[hitElement.vehicle:getId()]:setCollisionsEnabled(false)

	self.m_StartMarker:setVisibleTo(hitElement, false)

	addEventHandler("onMarkerHit", self.m_ScrapMarkers[hitElement.vehicle:getId()], bind(self.Event_onFinishMarkerHit, self))
end

function VehicleScrapManager:Event_onFinishMarkerHit(hitElement, matchingDimension)
	if getElementType(hitElement) ~= "player" then return end
	if hitElement:getCompany() and hitElement:getCompany():getId() ~= CompanyStaticId.MECHANIC then return end
	if hitElement.vehicle:getCompany() and hitElement.vehicle:getCompany():getId() ~= CompanyStaticId.MECHANIC and hitElement:getData("Mechanic_DFT") then return hitElement:sendError(_("Falsches Fahrzeug"), hitElement) end
	if not hitElement:isCompanyDuty() then return end
	if not hitElement.vehicle:getData("Mechanic_ScrapObject") then return hitElement:sendError(("Du hast das Wrack nicht aufgeladen!"), hitElement) end

	-- TODO:
	-- Autos entladen + Geld geben [3$ per km, distance from load to unload. 70% to company and 30% to player]
	-- Marker entfernen + Route beenden
	-- 

	-- local startPoint = getDistanceBetweenPoints3D(VehicleScrapManager.LoadUpMarker, TODO:Anfahrtspunkt)
	-- local finishPoint = getDistanceBetweenPoints3D(TODO:Anfahrtspunkt, VehicleScrapManager.UnloadMarker)
	local distance = getDistanceBetweenPoints3D(VehicleScrapManager.LoadUpMarker, VehicleScrapManager.UnloadMarker)
	outputChatBox("Distance: "..distance)
	local reward = distance * VehicleScrapManager.ScrapPricePerKm
	outputChatBox("Reward: "..reward)

	hitElement:sendSuccess(_("Du hast die Fahrzeuge erfolgreich verschrottet und Geld dafür erhalten!"), hitElement)

	--local dist = math.round(getDistanceBetweenPoints3D(self.m_BusStops[lastId].object.position, self.m_BusStops[stopId].object.position) * (math.random(998, 1002)/1000))
	local mechanicInstance = CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC)

	hitElement:giveCombinedReward("Fahrzeugverschrottung-Gehalt", {
		money = {
			mode = "give",
			bank = true,
			amount = math.round(reward * 0.3),
			toOrFrom = self.m_BankAccountServer,
			category = "Company",
			subcategory = "Scrap"
		},
		points = math.round(5 * (distance/1000)),--5 / km
	})
	self.m_BankAccountServer:transferMoney({mechanicInstance, nil, true}, math.round(reward * 0.7), ("Fahrzeugverschrottung von %s"):format(hitElement:getName()), "Company", "Scrap")

	self.m_ScrapMarkers[hitElement.vehicle:getId()]:destroy()
	self.m_ScrapMarkers[hitElement.vehicle:getId()] = nil

	self.m_VehicleObjectsToScrap[hitElement.vehicle:getId()]:destroy()
	self.m_VehicleObjectsToScrap[hitElement.vehicle:getId()] = nil

	removeEventHandler("onVehicleExit", hitElement.vehicle, bind(self.Event_onVehicleExit, self))
	removeEventHandler("onVehicleDestroy", hitElement.vehicle, bind(self.Event_onVehicleDestroy, self))
end

function VehicleScrapManager:Event_onPlayerQuit(player)
	outputDebug("VehicleScrapManager:Event_onPlayerQuit - triggered")
end

function VehicleScrapManager:Event_onVehicleExit(player, seat)
	if seat == 0 and player and isElement(player) then
		outputDebug("VehicleScrapManager:Event_onVehicleExit - triggered")
		player:triggerEvent("CountdownStop","ChristmasTruck")
		player:triggerEvent("VehicleHealthStop")
	end
	--self:stopPlayerCarScrapRoute(player, vehicle:getId())
	--player:sendError("Du musst im Fahrzeug bleiben, um die Verschrottung abzuschließen!")
end

function VehicleScrapManager:Event_onVehicleDestroy(vehicle)
	outputDebug("VehicleScrapManager:Event_onVehicleDestroy - triggered")
end

function VehicleScrapManager:destructor()
	for _, marker in pairs(self.m_ScrapMarkers) do
		marker:destroy()
	end
	for _, obj in pairs(self.m_VehicleObjectsToScrap) do
		obj:destroy()
	end
	self.m_ScrapMarkers = nil
	self.m_VehicleObjectsToScrap = nil
end