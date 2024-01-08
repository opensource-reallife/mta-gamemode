-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Shops/FCVehicleShop.lua
-- *  PURPOSE:     Faction & Company Vehicle Shop Class
-- *
-- ****************************************************************************
FCVehicleShop = inherit(Object)

function FCVehicleShop:constructor(id, name, npc, vehicleSpawn, aircraftSpawn, boatSpawn, factions, companies)
	self.m_Id = id
	self.m_Name = name
	self.m_BankAccountServer = BankServer.get("server.fc_vehicle_shop")
	self:reload()

	self.m_Factions = factions and fromJSON(factions) or {}
	self.m_Companies = companies and fromJSON(companies) or {}

	self.m_VehicleSpawn = fromJSON(vehicleSpawn)
	self.m_VehicleNonCollisionCol = createColSphere(self.m_VehicleSpawn.posX, self.m_VehicleSpawn.posY, self.m_VehicleSpawn.posZ, 10)
	self.m_VehicleNonCollisionCol:setData("NonCollisionArea", {players = true}, true)

	self.m_AircraftSpawn = fromJSON(aircraftSpawn)
	self.m_AircraftNonCollisionCol = createColSphere(self.m_AircraftSpawn.posX, self.m_AircraftSpawn.posY, self.m_AircraftSpawn.posZ, 10)
	self.m_AircraftNonCollisionCol:setData("NonCollisionArea", {players = true}, true)

	self.m_BoatSpawn = fromJSON(aircraftSpawn)
	self.m_BoatNonCollisionCol = createColSphere(self.m_BoatSpawn.posX, self.m_BoatSpawn.posY, self.m_BoatSpawn.posZ, 10)
	self.m_BoatNonCollisionCol:setData("NonCollisionArea", {players = true}, true)


	local npcData = fromJSON(npc)

	if (not npcData["interior"] or npcData["interior"] == 0) and (not npcData["dimension"] or npcData["dimension"] == 0) then
		self.m_Blip = Blip:new("CarShop.png", npcData["posX"], npcData["posY"], {faction = self.m_Factions, company = self.m_Companies}, 400)
		self.m_Blip:setDisplayText(self.m_Name, BLIP_CATEGORY.Shop)
		self.m_Blip:setOptionalColor({37, 78, 108})
	end

	self.m_Ped = NPC:new(npcData["skinId"], npcData["posX"], npcData["posY"], npcData["posZ"], npcData["rotZ"])
	self.m_Ped:setInterior(npcData["interior"] or 0)
	self.m_Ped:setInterior(npcData["dimension"] or 0)
	ElementInfo:new(self.m_Ped, _("Fahrzeugverkauf", client), 1.3)
	self.m_Ped:setImmortal(true)
	self.m_Ped:setFrozen(true)
	self.m_Ped:setData("clickable", true, true)
	addEventHandler("onElementClicked", self.m_Ped, function(button, state, player)
		if button == "left" and state == "down" then
			player.m_VehicleShop = self
			player.m_VehicleShopMarker = self.m_Ped
			self:Event_onShopOpen(player)
		end
	end)
end

function FCVehicleShop:reload()
	self.m_VehicleList = {}

	local result = sql:queryFetch("SELECT * FROM ??_fc_vehicle_shop_veh WHERE ShopId = ?", sql:getPrefix(), self.m_Id)
	for k, row in pairs(result) do
		if not self.m_VehicleList[row.OwnerType] then self.m_VehicleList[row.OwnerType] = {} end
		if not self.m_VehicleList[row.OwnerType][row.OwnerId] then self.m_VehicleList[row.OwnerType][row.OwnerId] = {} end
		
		self.m_VehicleList[row.OwnerType][row.OwnerId][row.Id] = {
			model = row.Model,
			price = row.Price,
			description = row.Description,
			ownerId = row.OwnerId,
			ownerType = row.OwnerType,
			tunings = fromJSON(row.Tunings),
			elsPreset = row.ELSPreset
		}
	end
end

function FCVehicleShop:Event_onShopOpen(player)
	if not player or not player.m_VehicleShopMarker or Vector3(player.position - player.m_VehicleShopMarker.position):getLength() > 5 then
		return 
	end
	if player:getFaction() and player:isFactionDuty() and table.find(self.m_Factions, player:getFaction():getId()) then
		player:triggerEvent("showFCVehicleShopGUI", self.m_Id, self.m_Name, player:getFaction().m_VehicleLimits, player:getFaction().m_Vehicles, player:getFaction().m_MaxVehicles, self.m_VehicleList[VehicleTypes.Faction][player:getFaction():getId()], self.m_Ped)
	elseif player:getCompany() and player:isCompanyDuty() and table.find(self.m_Companies, player:getCompany():getId()) then
		player:triggerEvent("showFCVehicleShopGUI", self.m_Id, self.m_Name, player:getCompany().m_VehicleLimits, player:getCompany().m_Vehicles, player:getCompany().m_MaxVehicles, self.m_VehicleList[VehicleTypes.Company][player:getCompany():getId()], self.m_Ped)
	else
		player:sendError(_("Du bist nicht OnDuty oder der Händler liefert nicht an deine Fraktion/dein Unternehmen!", player))
	end
end

function FCVehicleShop:buyVehicle(player, vehicleId)
	local vehData
	local vehType

	if player:getFaction() and player:isFactionDuty() and table.find(self.m_Factions, player:getFaction():getId()) then
		vehData = self.m_VehicleList[VehicleTypes.Faction][player:getFaction():getId()][vehicleId]
		vehType = VehicleCategory:getSingleton():getCategoryName(VehicleCategory:getSingleton():getModelCategory(vehData.model))

		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "buyVehicle") then
			player:sendError(_("Du bist nicht berechtigt weitere Fraktionsfahrzeuge zu kaufen!", player))
			return
		end
		if #player:getFaction().m_Vehicles >= player:getFaction().m_MaxVehicles then
			player:sendError(_("Du bist nicht berechtigt weitere Fraktionsfahrzeuge zu kaufen!", player))
			return
		end
		local current, limit = FCVehicleShop.getVehicleLimit(vehData.model, player:getFaction().m_VehicleLimits, player:getFaction().m_Vehicles)
		if current >= limit then
			player:sendError(_("Maximale Anzahl bereits erreicht!", player))
			return
		end
		if not player:getFaction():transferMoney(self.m_BankAccountServer, vehData.price, ("Fraktions Fahrzeugkauf von %s"):format(player:getName()), "Faction", "VehicleBought") then
			player:sendError(_("Deine Fraktion hat nicht genug Geld!", player))
			return
		end

		ownerId = player:getFaction():getId()
		ownerType = VehicleTypes.Faction
	elseif player:getCompany() and player:isCompanyDuty() and table.find(self.m_Companies, player:getCompany():getId()) then
		vehData = self.m_VehicleList[VehicleTypes.Company][player:getCompany():getId()][vehicleId]
		vehType = VehicleCategory:getSingleton():getCategoryName(VehicleCategory:getSingleton():getModelCategory(vehData.model))

		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "company", "buyVehicle") then
			player:sendError(_("Du bist nicht berechtigt weitere Unternehmensfahrzeuge zu kaufen!", player))
			return
		end
		if #player:getCompany().m_Vehicles >= player:getCompany().m_MaxVehicles then
			player:sendError(_("Du bist nicht berechtigt weitere Unternehmensfahrzeuge zu kaufen!", player))
			return
		end
		local current, limit = FCVehicleShop.getVehicleLimit(vehData.model, player:getCompany().m_VehicleLimits, player:getCompany().m_Vehicles)
		if current >= limit then
			player:sendError(_("Maximale Anzahl bereits erreicht!", player))
			return
		end
		if not player:getCompany():transferMoney(self.m_BankAccountServer, vehData.price, ("Unternehmens Fahrzeugkauf von %s"):format(player:getName()), "Company", "VehicleBought") then
			player:sendError(_("Dein Unternehmen hat nicht genug Geld!", player))
			return
		end

		ownerId = player:getCompany():getId()
		ownerType = VehicleTypes.Company
	end

	local color = vehData.color
	local spawnPos = self.m_VehicleSpawn
	
	if vehType == "Boot" then
		spawnPos = self.m_BoatSpawn
	elseif vehType == "Helikopter" or vehType == "Propellerflugzeug" or vehType == "Düsenflugzeug" then
		spawnPos = self.m_AircraftSpawn
	end

	local veh = VehicleManager:getSingleton():createNewVehicle(ownerId, ownerType, vehData.model, spawnPos.posX, spawnPos.posY, spawnPos.posZ, 0, 0, spawnPos.rotZ, 0, 0, vehData.price)
	
	if vehType ~= "Sattelauflieger" and vehType ~= "Anhänger" then
		warpPedIntoVehicle(player, veh)
	end

	veh:getTunings().m_Tuning = vehData.tunings
	veh:getTunings():applyTuning()
	veh:setELSPreset(vehData.elsPreset)
end

function FCVehicleShop:addVehicle()

end

function FCVehicleShop.getVehicleLimit(model, vehicleLimits, currentVehicles)
	local current = 0
	local limit = 0

	for id, max in pairs(vehicleLimits) do
		if id == model then
			limit = max
		end
	end

	for k, vehicle in pairs(currentVehicles) do
		if vehicle:getModel() == model then
			current = current + 1
		end
	end

	return current, limit
end