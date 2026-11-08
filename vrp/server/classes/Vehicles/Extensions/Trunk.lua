-- ****************************************************************************
-- *
-- *  PROJECT:     eXo
-- *  FILE:        server/classes/Vehicles/Trunk.lua
-- *  PURPOSE:     Vehicle Trunk class
-- *
-- ****************************************************************************
Trunk = inherit(Object)
Trunk.Map = {}
Trunk.ItemSlots = 4
Trunk.WeaponSlots = 2


function Trunk.create()
	local item = {}
	local weapon = {}

	for i=1, Trunk.ItemSlots do
		item[i] = {["Item"] = "none", ["Amount"] = 0}
	end
	for i=1, Trunk.WeaponSlots do
		weapon[i] = {["WeaponId"] = 0, ["Amount"] = 0}
	end

	local row = sql:queryFetchSingle("INSERT INTO ??_vehicle_trunks (ItemSlot1, ItemSlot2, ItemSlot3, ItemSlot4, WeaponSlot1, WeaponSlot2) VALUES (?,?,?,?,?,?);",
	sql:getPrefix(), toJSON(item[1]), toJSON(item[2]), toJSON(item[3]), toJSON(item[4]), toJSON(weapon[1]), toJSON(weapon[2]))

	return sql:lastInsertId()
end

function Trunk.load(Id)
	local Id = Id
	if Trunk.Map[Id] then return Trunk.Map[Id] end
	if Id == 0 then	Id = Trunk.create()	end

	local row = sql:queryFetchSingle("SELECT * FROM ??_vehicle_trunks WHERE Id = ?;", sql:getPrefix(), Id)
	if row and Id > 0 then
		Trunk.Map[row.Id] = Trunk:new(row.Id, row.ItemSlot1, row.ItemSlot2, row.ItemSlot3, row.ItemSlot4, row.WeaponSlot1, row.WeaponSlot2)
		return Trunk.Map[row.Id]
	else
		return Trunk.load(0)
	end
end

function Trunk.getFromId(id)
	return Trunk.Map[id]
end

function Trunk:constructor(Id, ItemSlot1, ItemSlot2, ItemSlot3, ItemSlot4, WeaponSlot1, WeaponSlot2)
	self.m_Id = Id
	self.m_ItemSlot = {}
	self.m_ItemSlot[1] = fromJSON(ItemSlot1)
	self.m_ItemSlot[2] = fromJSON(ItemSlot2)
	self.m_ItemSlot[3] = fromJSON(ItemSlot3)
	self.m_ItemSlot[4] = fromJSON(ItemSlot4)
	self.m_WeaponSlot = {}
	self.m_WeaponSlot[1] = fromJSON(WeaponSlot1)
	self.m_WeaponSlot[2] = fromJSON(WeaponSlot2)
end

function Trunk:destructor()
  self:save()
end

function Trunk:setVehicle(veh) --only for display purposes, not to actually change the owner
	self.m_Vehicle = veh
end

function Trunk:save()
	return sql:queryExec("UPDATE ??_vehicle_trunks SET ItemSlot1 = ?, ItemSlot2 = ?, ItemSlot3 = ?, ItemSlot4 = ?, WeaponSlot1 = ?, WeaponSlot2 = ? WHERE Id = ?", sql:getPrefix(), toJSON(self.m_ItemSlot[1]), toJSON(self.m_ItemSlot[2]), toJSON(self.m_ItemSlot[3]), toJSON(self.m_ItemSlot[4]), toJSON(self.m_WeaponSlot[1]), toJSON(self.m_WeaponSlot[2]), self.m_Id)
end

function Trunk:checkDistance(player)
	if isValidElement(self.m_Vehicle, "vehicle") then
		if Vector3(self.m_Vehicle:getPosition() - player:getPosition()):getLength() < 5 then
			if self.m_Vehicle:getDimension() == player:getDimension() and player:getInterior() == self.m_Vehicle:getInterior() then
				return true
			end
		end
	end
	return false
end

function Trunk:importLegacySlots()
	local changed = false
	local storage = self:getStorage()
	for index, slot in pairs(self.m_ItemSlot) do
		if slot["Item"] and slot["Item"] ~= "none" and slot["Item"] ~= 0 then
			local value = slot["Value"]
			if value == "" then value = nil end
			if storage:importItem(slot["Item"], slot["Amount"], value) then
				self.m_ItemSlot[index] = {["Item"] = "none", ["Amount"] = 0}
				changed = true
			end
		end
	end
	for index, slot in pairs(self.m_WeaponSlot) do
		if slot["WeaponId"] and slot["WeaponId"] > 0 then
			if storage:importWeapon(slot["WeaponId"], slot["Amount"]) then
				self.m_WeaponSlot[index] = {["WeaponId"] = 0, ["Amount"] = 0}
				changed = true
			end
		end
	end
	if changed then self:save() end
end

function Trunk:getStorage()
	return ItemStorage.get("trunk", self.m_Id, {
		title = "Fahrzeug-Kofferraum",
		head = "Kofferraum:",
		rule = "Items mit Handel und erlaubte Waffen",
		element = self.m_Vehicle,
		getCapacity = function()
			return InventoryManager:getSingleton():getCapacity("trunk", self.m_Vehicle and self.m_Vehicle:getModel())
		end,
		accepts = function(itemName, data)
			if data["WaffenId"] then return not RESTRICTED_WEAPONS[data["WaffenId"]] end
			if data["MunitionFuer"] then return not RESTRICTED_WEAPONS[data["MunitionFuer"]] end
			return data["Handel"] == 1
		end,
		canAccess = function(player)
			return self:checkDistance(player)
		end,
		canDeposit = function(player, itemName, data, value)
			if (data["WaffenId"] or data["MunitionFuer"]) and player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty() then
				player:sendError(_("Du darfst im Dienst keine Waffen einlagern!", player))
				return false
			end
			if InventoryManager:getSingleton():getItemId(itemName) == 64 and not SkinInfo[tonumber(value)] then
				player:sendError(_("Du kannst diesen Skin nicht in den Kofferraum legen!", player))
				return false
			end
			return true
		end,
		onWithdraw = function(player, itemName, data, amount, value)
			if not (player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty()) then return nil end
			local vehicle = self.m_Vehicle
			if data["WaffenId"] then
				StateEvidence:getSingleton():addWeaponsToEvidence(player, data["WaffenId"], amount)
			elseif data["MunitionFuer"] then
				StateEvidence:getSingleton():addMunitionToEvidence(player, data["MunitionFuer"], amount)
			elseif FactionState:getSingleton():isItemIllegal(itemName) then
				if not StateEvidence:getSingleton():addItemToEvidence(player, itemName, amount) then return false end
			else
				player:sendError(_("Dieses Item ist nicht illegal!", player))
				return false
			end
			vehicle:sendOwnerMessage(_("%s hat %d %s aus dem Kofferraum deines Fahrzeuges %s konfisziert!", player, player:getName(), amount, itemName, vehicle:getName()))
			StatisticsLogger:getSingleton():addVehicleTrunkLog(self.m_Id, player, "take", "item", itemName, amount, 0)
			return true
		end,
		onMoved = function(player, action, itemName, amount)
			StatisticsLogger:getSingleton():addVehicleTrunkLog(self.m_Id, player, action, "item", itemName, amount, 0)
		end,
	})
end

function Trunk:open(player)
	if not self:checkDistance(player) then return end

	if self.m_Vehicle and self.m_Vehicle:getModel() then
		local vehId = self.m_Vehicle:getModel()

		if InventoryManager:getSingleton():getCapacity("trunk", vehId) <= 0 then
			player:sendError(_("Dieses Fahrzeug hat keinen Kofferraum!", player))
			return
		end

		if self.m_Vehicle:getOwnerType() == VehicleTypes.Group then
			if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "group", "useTrunk") and not (player:getRank() >= RANK.Moderator and player:getPublicSync("supportMode")) then
				player:sendError(_("Du hast keine Berechtigung den Kofferraum dieses Fahrzeuges zu benutzen!", player))
				return
			end
		end
	end

	self:importLegacySlots()
	self:getStorage():open(player)
end


function Trunk:getId()
  return self.m_Id
end
