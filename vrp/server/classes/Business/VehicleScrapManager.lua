-- ****************************************************************************
-- *
-- *  PROJECT:     OpenReallife
-- *  FILE:        server/classes/Business/VehicleScrapManager.lua
-- *  PURPOSE:     manager for vehicle scrapping missions for mechanic
-- *
-- ****************************************************************************

VehicleScrapManager = inherit(Singleton)
VehicleScrapManager.LoadUpMarker = Vector3(1173.599609375, -1303.400390625, 13.546875)

addRemoteEvents{}


function VehicleScrapManager:constructor()
    self.m_ScrapMarkers = {} -- all scrap markers
    self.m_VehiclesOnRoute = {} -- vehicles that are currently on a scrap route
    self.m_VehicleObjectsToScrap = {} -- objects of vehicles to scrap, and be attached to the scrap truck

end

function VehicleScrapManager:startCarScrapRoute_Event(player)
	if client:getCompany() ~= self then client:sendError("Wie zum Teufel hast du das geschafft?") return end

	if client:getCompany() == self and client:isCompanyDuty() then
		self.m_ScrapMarkers = createMarker(864.33, -1170.54, 17.27, "cylinder", 3, 255, 0, 0, 150)

		client:sendInfo("Die Verschrottung der Fahrzeuge wurde gestartet. Fahre zum Schrottplatz und lade die Autos ab.")

		
		addEventHandler("onMarkerHit", self.m_ScrapMarker, bind(self.Event_onMarkerHit, self))
	end
end

function VehicleScrapManager:stopCarScrapRoute()
end

-- // Events

function VehicleScrapManager:Event_onMarkerHit(hitElement, matchingDimension)
	if getElementType(hitElement) ~= "player" then return end
	if hitElement:getCompany() ~= self then return end
	if not hitElement:isCompanyDuty() then return end
	if not hitElement and self.m_ScrapMarker then return end

	player:triggerEvent("VehicleScrapManager:loadUpTimer", time/1000)

	self.m_Countdown = ShortCountdown:new(time, "Schloss knacken", "files/images/Other/LockPick.png")

	-- //Autos entladen + Geld geben
	-- hitElement:sendSuccess("Du hast die Fahrzeuge erfolgreich verschrottet und Geld dafür erhalten!")

	-- //Marker entfernen + Route beenden
	-- self.m_ScrapMarker:destroy()
	-- self.m_ScrapMarker = nil
end