-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Shops/FCVehicleShop.lua
-- *  PURPOSE:     Faction & Company Vehicle Shop Class
-- *
-- ****************************************************************************
FCVehicleShop = inherit(Object)

function FCVehicleShop:constructor(id, name, npc, spawn, type, typeId)
	self.m_Name = name

	self.m_BankAccountServer = BankServer.get("server.fc_vehicle_shop")

	self.m_VehicleList = {}

	local npcData = fromJSON(npc)
	local spawnPos = fromJSON(spawn)

	self.m_FactionOrCompany = false
	self.m_Blip = false
	if type == 2 then
		self.m_FactionOrCompany = FactionManager:getSingleton():getFromId(typeId)
		self.m_Blip = Blip:new("CarShop.png", npcData["posX"], npcData["posY"], {faction = typeId}, 400, {factionColors[typeId].r, factionColors[typeId].g, factionColors[typeId].b})
	elseif type == 3 then
		self.m_FactionOrCompany = CompanyManager:getSingleton():getFromId(typeId)
		self.m_Blip = Blip:new("CarShop.png", npcData["posX"], npcData["posY"], {company = typeId}, 400, {companyColors[typeId].r, companyColors[typeId].g, companyColors[typeId].b})
	else
		return false
	end
	self.m_Blip:setDisplayText(_("Autohaus - %s", client, tostring(self.m_FactionOrCompany:getName())), BLIP_CATEGORY.Shop)

	self.m_Ped = NPC:new(self.m_FactionOrCompany:getRandomSkin(), npcData["posX"], npcData["posY"], npcData["posZ"], npcData["rotZ"])
	ElementInfo:new(self.m_Ped, _("Fahrzeugverkauf", client), 1.3)
	self.m_Ped:setImmortal(true)
	self.m_Ped:setFrozen(true)

	self.m_Spawn = {spawnPos["posX"], spawnPos["posY"], spawnPos["posZ"], spawnPos["rotZ"]}
	self.m_NonCollissionCol = createColSphere(spawnPos["posX"], spawnPos["posY"], spawnPos["posZ"], 10)
	self.m_NonCollissionCol:setData("NonCollisionArea", {players = true}, true)

	self.m_Ped:setData("clickable", true, true)
	addEventHandler("onElementClicked", self.m_Ped, function(button, state, player)
		if button == "left" and state == "down" then
			self:Event_onShopOpen(player)
		end
	end)
end

function FCVehicleShop:Event_onShopOpen(player)
	
end

function FCVehicleShop:buyVehicle()

end

function FCVehicleShop:addVehicle()

end