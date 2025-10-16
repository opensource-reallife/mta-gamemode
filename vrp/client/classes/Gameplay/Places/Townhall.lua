Townhall = inherit(Singleton)

function Townhall:constructor()
	self.m_Peds = {}
	self.m_OnClickFunc = bind(self.Event_OnPedClick, self)

	--// PRESIDENT
	local president = Ped.create(153, Vector3(1478.25, -1802.2, 1.18))
	president:setAnimation("cop_ambient", "Coplook_loop", -1, true, false, false, true)
	president:setRotation(Vector3(0, 0, 45))
	president:setData("NPC:Immortal", true)
	president:setFrozen(true)
	president.Texture = FileTextureReplacer:new(president, "files/images/Textures/Cityhall/tex16.jpg", "wmyconb", {}, true, true)

	--// TOWNHALL PED
	local townhallPed = Ped.create(189, Vector3(1485.14, -1788.91, 1.18))
	townhallPed:setRotation(Vector3(0, 0, 0))
	townhallPed.Name = _"Stadthalle"
	townhallPed.Description = _"Für mehr Infos klicke mich an!"
	townhallPed.Type = 3
	townhallPed.Func = function() TownhallGUI:new(townhallPed) end
	self.m_Peds[#self.m_Peds + 1] = townhallPed

	--// VEHICLE SPAWNER PEDS
	local itemSpawnerPed = Ped.create(171, Vector3(1767.33, -1721.86, 13.37)) -- driving school
	itemSpawnerPed:setRotation(Vector3(0, 0, 180))
	itemSpawnerPed.Name = _"Fahrzeugverleih"
	itemSpawnerPed.Description = _("Fahrzeug für %s$ ausleihen!", VEHICLE_RENTAL_PRICE)
	itemSpawnerPed.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed

	local itemSpawnerPed2 = Ped.create(171, Vector3(1509.99, -1749.29, 13.55)) -- city hall
	itemSpawnerPed2:setRotation(Vector3(0, 0, 97.13))
	itemSpawnerPed2.Name = _"Fahrzeugverleih"
	itemSpawnerPed2.Description = _("Fahrzeug für %s$ ausleihen!", VEHICLE_RENTAL_PRICE)
	itemSpawnerPed2.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed2

	--// WT PED AREA
	local itemSpawnerPed3 = Ped.create(287, Vector3(2734.81, -2457.07, 13.65))
	itemSpawnerPed3:setRotation(Vector3(0, 0, 270))
	itemSpawnerPed3.Name = _"Ausrüstungsfahrzeug"
	itemSpawnerPed3.Description = _"Hier startet der Staatswaffentruck!"
	itemSpawnerPed3.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed3

	--// WT PED SF
	local itemSpawnerPed4 = Ped.create(307, Vector3(-2103.76, -2277.80, 30.62))
	itemSpawnerPed4:setRotation(Vector3(0, 0, 320))
	itemSpawnerPed4.Name = _"Illegaler Waffentruck"
	itemSpawnerPed4.Description = _"Hier startet der Waffentruck!"
	itemSpawnerPed4.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed4

	--// VEHICLE SPAWNER RESCUE
	local itemSpawnerPed5 = Ped.create(171, Vector3(1180.90, -1331.90, 13.58))
	itemSpawnerPed5:setRotation(Vector3(0, 0, 270))
	itemSpawnerPed5.Name = _"Fahrzeugverleih"
	itemSpawnerPed5.Description = _("Fahrzeug für %s$ ausleihen!", VEHICLE_RENTAL_PRICE)
	itemSpawnerPed5.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed5

	--// RESCUE BASE HEAL PED
	local itemSpawnerPed6 = Ped.create(70, Vector3(1172.33, -1321.48, 15.40))
	itemSpawnerPed6:setRotation(Vector3(0, 0, 270))
	itemSpawnerPed6.Name = _"Erste Hilfe"
	itemSpawnerPed6.Description = _"Klicke mich für Heilung an!"
	itemSpawnerPed6.Func = function() triggerServerEvent("factionRescuePlayerHealBase", localPlayer) end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed6

	--// VEHICLE SPAWNER JAIL
	local itemSpawnerPed8 = Ped.create(171, Vector3(-468.34, -544.60, 25.53))
	itemSpawnerPed8:setRotation(Vector3(0, 0, 86))
	itemSpawnerPed8.Name = _"Fahrzeugverleih"
	itemSpawnerPed8.Description = _("Fahrzeug für %s$ ausleihen!", VEHICLE_RENTAL_PRICE)
	itemSpawnerPed8.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed8

	--// LS PIER FERRIS WHEEL PED
	local ferrisWheelPed = Ped.create(189, Vector3(379.57, -2020.66, 7.83), 50)
	ferrisWheelPed:setRotation(Vector3(0, 0, 90))
	ferrisWheelPed.Name = _"Riesenrad"
	ferrisWheelPed.Description = _"Klicke hier für Informationen!"
	ferrisWheelPed.Func = function() FerrisWheelGUI:new() end
	self.m_Peds[#self.m_Peds + 1] = ferrisWheelPed

	--// DT PED 
	local itemSpawnerPed8 = Ped.create(1, Vector3(-1096.38, -1614.74, 76.37))
	itemSpawnerPed8:setRotation(Vector3(0, 0, 270))
	itemSpawnerPed8.Name = _"Illegaler Weed-Transport"
	itemSpawnerPed8.Description = _"Hier startet der Drogentruck!"
	itemSpawnerPed8.Func = function() end
	self.m_Peds[#self.m_Peds + 1] = itemSpawnerPed8
	
	-- Initialize
	self:initalizePeds()

	local col = createColRectangle(1399.60, -1835.2, 1540.14-1399.60, 1835.2-1582.84) -- pershing square
	self.m_NoParkingZone = NoParkingZone:new(col)
	NonCollisionArea:new("Cuboid", {Vector3(1502.43, -1850.71, 12), 40, 10 ,10})
end

function Townhall:destructor()
	for i, v in pairs(self.m_Peds) do
		if v.SpeakBubble then
			delete(v.SpeakBubble) -- would also happen automatically ^^
		end
		v:destroy()
	end
end

function Townhall:initalizePeds()
	for i, v in pairs(self.m_Peds) do
		setElementData(v, "clickable", true)
		v:setData("NPC:Immortal", true)
		v:setData("Townhall:onClick", function () self.m_OnClickFunc(v) end)
		v:setFrozen(true)
		v.SpeakBubble = SpeakBubble3D:new(v, v.Name, v.Description)
	end
end

function Townhall:Event_OnPedClick(ped)
	if ped.Func then
		ped.Func()
	else
		ShortMessage:new("Clicked-Ped: "..ped.Type)
		TownhallInfoGUI:getSingleton():openTab(ped.Type)
	end
end