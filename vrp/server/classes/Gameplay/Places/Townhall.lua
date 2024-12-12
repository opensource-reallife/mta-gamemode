Townhall = inherit(Singleton)

function Townhall:constructor()
	self.m_Blip = Blip:new("Stadthalle.png", 1481.22, -1749.11, root, 600)
	self.m_Blip:setDisplayText("Stadthalle")
	self.m_Blip:setOptionalColor({7, 161, 213})
	self:createGarage()
	self.m_EnterExit = InteriorEnterExit:new(Vector3(1481.09, -1771.09, 18.80), Vector3(1481.36, -1773.08, 1.18), 180, 0, 0)
end

function Townhall:createGarage()
	VehicleTeleporter:new(Vector3(1403.63, -1503.30, 13.57), Vector3(2108.466796875, 959.41778564453, 3398.7609863281), Vector3(0, 0, 270), Vector3(0, 0, 180), 9, 0, "cylinder" , 5, Vector3(0,0,3))
	InteriorEnterExit:new(Vector3(1397.12, -1571.02, 14.27), Vector3(2118.47, 909.90, 3389.54), 180, 0, 9, 0)
	local blip = Blip:new("Parking.png", 1403.63, -1503.30, root, 400)
	blip:setDisplayText("Parkhaus", BLIP_CATEGORY.VehicleMaintenance)
	blip:setOptionalColor({0, 83, 135})
	local col = createColCuboid(2069.40, 886.28, 3388.49, 2169.50-2086.40+20, 964.03-886.28, 12)
	col:setInterior(9)
	ParkGarageZone:new(col)
end

function Townhall:destructor()
	delete(self.m_EnterExit)
	delete(self.m_Blip)
end
