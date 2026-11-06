-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/Inventory.lua
-- *  PURPOSE:     Inventory - Class
-- *
-- ****************************************************************************
Inventory = inherit(Object)
Inventory.DefaultBag = "Items"

local DUTY_VALUE = "duty"
local UNLIMITED = 1000000

function Inventory:constructor(owner, inventorySlots, itemData, classItems)
	self.m_InventorySlots = inventorySlots
	self.m_ItemData = itemData
	self.m_Owner = owner
	self.m_Bag = {}
	self.m_Items = {}
	self.m_ClassItems = classItems
	self.m_Overloaded = false
	self.m_Debug = false

	for k, v in pairs(inventorySlots) do
		self.m_Bag[k] = {}
	end

	local result = sql:queryFetch("SELECT * FROM ??_inventory_slots WHERE PlayerId = ?", sql:getPrefix(), self.m_Owner:getId())
	for i, row in ipairs(result) do
		self:loadRow(row)
	end
	self:mergeMigratedExpiry()
	self:removeExpiredItems()

	triggerClientEvent(self.m_Owner, "loadPlayerInventarClient", self.m_Owner, self.m_InventorySlots, self.m_ItemData, InventoryManager:getSingleton():getTabs())
	self:syncClient()
end

function Inventory:destructor()
	self.m_Items = nil
	self.m_Bag = nil
	InventoryManager:getSingleton():deleteInventory(self.m_Owner)
end

function Inventory:resolve(item)
	return InventoryManager:getSingleton():resolveItemName(item)
end

function Inventory:loadRow(row)
	local id = tonumber(row["id"])
	local place = tonumber(row["Platz"])
	local bag = row["Tasche"]
	self.m_Bag[bag] = self.m_Bag[bag] or {}

	if tonumber(row["Menge"]) <= 0 then
		sql:queryExec("DELETE FROM ??_inventory_slots WHERE id = ?", sql:getPrefix(), id)
		return
	end

	local itemName = self:resolve(row["Objekt"])
	if not itemName then
		if next(self.m_ItemData) then
			outputServerLog(("[INV] Unbekanntes Item entfernt: '%s' x%d, Slot %d, Spieler %d"):format(tostring(row["Objekt"]), tonumber(row["Menge"]), id, self.m_Owner:getId()))
			sql:queryExec("DELETE FROM ??_inventory_slots WHERE id = ?", sql:getPrefix(), id)
		end
		return
	end

	if not tonumber(row["Objekt"]) then
		sql:queryExec("UPDATE ??_inventory_slots SET Objekt = ? WHERE id = ?", sql:getPrefix(), tostring(self.m_ItemData[itemName]["Id"]), id)
		self.m_MigratedRows = self.m_MigratedRows or {}
		self.m_MigratedRows[id] = true
	end

	if self.m_Bag[bag][place] then
		place = self:getLowEmptyPlace(bag)
		sql:queryExec("UPDATE ??_inventory_slots SET Platz = ? WHERE id = ?", sql:getPrefix(), place, id)
	end

	self.m_Items[id] = {
		["Objekt"] = itemName,
		["ItemId"] = self.m_ItemData[itemName]["Id"],
		["Menge"] = tonumber(row["Menge"]),
		["Platz"] = place,
		["Tasche"] = bag,
		["Value"] = row["Value"] or "",
		["WearLevel"] = tonumber(row["WearLevel"]) or nil
	}
	self.m_Bag[bag][place] = id
end

function Inventory:mergeMigratedExpiry()
	if not self.m_MigratedRows then return end

	local newest = {}
	for id in pairs(self.m_MigratedRows) do
		local item = self.m_Items[id]
		if item and self.m_ItemData[item["Objekt"]]["VerfallTage"] then
			local first = newest[item["Objekt"]]
			if not first then
				newest[item["Objekt"]] = id
			else
				local keep, drop = first, id
				if (tonumber(item["Value"]) or 0) > (tonumber(self.m_Items[first]["Value"]) or 0) then
					self.m_Items[id]["Menge"] = item["Menge"] + self.m_Items[first]["Menge"]
					self:saveItemAmount(id, self.m_Items[id]["Menge"])
					keep, drop = id, first
				else
					self.m_Items[first]["Menge"] = self.m_Items[first]["Menge"] + item["Menge"]
					self:saveItemAmount(first, self.m_Items[first]["Menge"])
				end
				self.m_Bag[self.m_Items[drop]["Tasche"]][self.m_Items[drop]["Platz"]] = nil
				self.m_Items[drop] = nil
				sql:queryExec("DELETE FROM ??_inventory_slots WHERE id = ?", sql:getPrefix(), drop)
				newest[self.m_Items[keep]["Objekt"]] = keep
			end
		end
	end
	self.m_MigratedRows = nil
end

function Inventory:getRowExpiry(row)
	local data = self.m_ItemData[row["Objekt"]]
	if data["VerfallAm"] then return data["VerfallAm"] end
	if data["VerfallTage"] then return tonumber(row["Value"]) or 0 end
	return false
end

function Inventory:removeExpiredItems()
	if not self.m_Items then return end

	local now = getRealTime().timestamp
	local expired = {}
	for id, row in pairs(self.m_Items) do
		local expiry = self:getRowExpiry(row)
		if expiry and expiry <= now then
			expired[#expired + 1] = {row["Tasche"], row["Platz"], row["Objekt"], row["Menge"], row["Value"]}
		end
	end

	for _index, entry in ipairs(expired) do
		WearableManager:getSingleton():removeWearable(self.m_Owner, entry[3], entry[5])
		self:removeItemFromPlace(entry[1], entry[2])
		if isElement(self.m_Owner) then
			self.m_Owner:sendMessage(_("%dx %s ist abgelaufen und wurde entfernt!", self.m_Owner, entry[4], entry[3]), 255, 0, 0)
		end
	end
end

function Inventory:getRowWeight(row)
	local data = self.m_ItemData[row["Objekt"]]
	if data["DienstItem"] == 1 or row["Value"] == DUTY_VALUE then return 0 end
	return data["Gewicht"] * row["Menge"]
end

function Inventory:getWeight()
	local weight = 0
	for id, row in pairs(self.m_Items) do
		weight = weight + self:getRowWeight(row)
	end
	return weight
end

function Inventory:getMaxWeight()
	local bonus = 0
	local shirt = self.m_Owner.m_IsWearingShirt
	if shirt and self.m_ItemData[shirt] and self.m_ItemData[shirt]["Effekte"] then
		bonus = tonumber(self.m_ItemData[shirt]["Effekte"]["TragkraftBonus"]) or 0
	end
	return InventoryManager:getSingleton():getCapacity("player") + bonus
end

function Inventory:getFreeWeight()
	return self:getMaxWeight() - self:getWeight()
end

function Inventory:isOverloadExempt()
	return self.m_Owner:getPublicSync("supportMode") and self.m_Owner:getRank() >= RANK.Supporter
end

function Inventory:getFreeCarryWeight()
	if self:isOverloadExempt() then return math.huge end
	return self:getMaxWeight() * InventoryManager:getSingleton():getOverloadFactor() - self:getWeight()
end

function Inventory:canCarryWeapon(weaponId, ammo)
	if self:getDutyValue() then return true end
	local manager = InventoryManager:getSingleton()
	local weaponItem = manager:getWeaponItemName(weaponId)
	if not weaponItem then return true end
	local weight = 0
	if THROWABLE_WEAPONS[weaponId] then
		weight = self.m_ItemData[weaponItem]["Gewicht"] * math.max(ammo, 1)
	else
		if not self:hasWeapon(weaponId) then
			weight = self.m_ItemData[weaponItem]["Gewicht"]
		end
		local ammoItem = manager:getAmmoItemName(weaponId)
		if ammoItem then
			weight = weight + self.m_ItemData[ammoItem]["Gewicht"] * ammo
		end
	end
	return weight <= self:getFreeCarryWeight() + 0.0001
end

function Inventory:canCarry(item, amount)
	local itemName = self:resolve(item)
	if not itemName then return false end
	local data = self.m_ItemData[itemName]
	if data["DienstItem"] == 1 then return true end
	return data["Gewicht"] * amount <= self:getFreeCarryWeight() + 0.0001
end

function Inventory:updateOverload()
	if not isElement(self.m_Owner) or not self.m_Items then return end
	local overloaded = self:getWeight() > self:getMaxWeight() + 0.0001
	if overloaded == self.m_Overloaded then return end

	self.m_Overloaded = overloaded
	if self:isOverloadExempt() then
		return
	end

	if overloaded then
		self.m_Owner:sendWarning(_("Überlast! Du kannst nicht mehr sprinten oder springen. Wirf etwas weg.", self.m_Owner))
	else
		self.m_Owner:sendInfo(_("Du bist nicht mehr überladen.", self.m_Owner))
	end
end

function Inventory:updateVisibleWeapons()
	if not isElement(self.m_Owner) or not self.m_Items then return end
	local weapons = {}
	if self:isWeaponContext() then
		for id, row in pairs(self.m_Items) do
			local weaponId = self.m_ItemData[row["Objekt"]]["WaffenId"]
			if weaponId then
				weapons[weaponId] = true
			end
		end
	end
	triggerEvent("WeaponAttach:setCarriedWeapons", self.m_Owner, weapons)
end

function Inventory:syncClient(includeItemData)
	if self.m_SyncPaused then return end
	if not self.m_Owner.m_Disconnecting and self.m_Items then
		self:syncArmedAmmo()
		self:updateOverload()
		self:updateVisibleWeapons()
		self.m_Owner:triggerEvent("syncInventoryFromServer", self.m_Bag, self.m_Items, includeItemData and self.m_ItemData or false, self:getWeight(), self:getMaxWeight())
	end
end

function Inventory:loadItem(id)
	local result = sql:queryFetch("SELECT * FROM ??_inventory_slots WHERE id = ?", sql:getPrefix(), id)
	for i, row in ipairs(result) do
		self:loadRow(row)
	end
	self:syncClient()
end

function Inventory:useItem(itemId, bag, itemName, place)
	if self:getItemAmount(itemName) <= 0 then
		client:sendError(_("Inventar Fehler: Kein Item", client))
		return
	end

	local data = self.m_ItemData[itemName]
	if data["WaffenId"] then
		return self:toggleWeapon(data["WaffenId"])
	end
	if data["MunitionFuer"] then
		client:sendError(_("Munition wird über die passende Waffe verschossen.", client))
		return
	end

	if self.m_ClassItems[itemName] then
		local instance = ItemManager.Map[itemName]
		if instance.use then
			if instance:use(client, itemId, bag, place, itemName) == false then
				return false
			end
		end
	end

	if data["Verbraucht"] == 1 then
		self:removeItemFromPlace(bag, place, 1)
	end

	if data["VerfallTage"] and not self.m_ClassItems[itemName] then
		local id = self:getItemID(bag, place)
		if self.m_Items[id] and self.m_Items[id]["Value"] then
			client:sendShortMessage(_("Dein %s ist noch bis %s gültig!", client, itemName, getOpticalTimestamp(tonumber(self.m_Items[id]["Value"]))), "San Andreas Government")
		else
			client:sendShortMessage(_("Dein %s ist abgelaufen!", client, itemName), "San Andreas Government")
			self:removeItemFromPlace(bag, place, 1)
		end
	end

	self:syncClient()
end

function Inventory:useItemSecondary(itemId, bag, itemName, place)
	if self:getItemAmount(itemName) <= 0 then
		client:sendError(_("Inventar Fehler: Kein Item", client))
		return
	end

	if self.m_ClassItems[itemName] then
		local instance = ItemManager.Map[itemName]
		if instance.useSecondary then
			return instance:useSecondary(client, itemId, bag, place, itemName)
		end
	end
end

function Inventory:saveItemAmount(id, amount)
	sql:queryExec("UPDATE ??_inventory_slots SET Menge = ? WHERE id = ?", sql:getPrefix(), amount, id)
	self:syncClient()
end

function Inventory:saveItemPlace(id, place)
	sql:queryExec("UPDATE ??_inventory_slots SET Platz = ? WHERE id = ?", sql:getPrefix(), place, id)
	self:syncClient()
end

function Inventory:saveItemValue(id, value)
	sql:queryExec("UPDATE ??_inventory_slots SET Value = ? WHERE id = ?", sql:getPrefix(), value, id)
	self:syncClient()
end

function Inventory:saveItemWearLevel(id, wearLevel)
	sql:queryExec("UPDATE ??_inventory_slots SET WearLevel = ? WHERE id = ?", sql:getPrefix(), wearLevel, id)
	self:syncClient()
end

function Inventory:deleteItem(id)
	sql:queryExec("DELETE FROM ??_inventory_slots WHERE id = ?", sql:getPrefix(), id)
	self:syncClient()
end

function Inventory:insertItem(amount, item, place, bag, value, wearLevel)
	sql:queryExec("INSERT INTO ??_inventory_slots (PlayerId, Menge, Objekt, Platz, Tasche, Value, WearLevel) VALUES (?, ?, ?, ?, ?, ?, ?)", sql:getPrefix(), self.m_Owner:getId(), amount, tostring(self.m_ItemData[item]["Id"]), place, bag, value, wearLevel)
	return sql:lastInsertId()
end

function Inventory:getItemID(bag, place)
	if self.m_Bag and self.m_Bag[bag] then
		return self.m_Bag[bag][place]
	end
end

function Inventory:getMaxItemAmount(item)
	return self:getItemAmount(item) + self:getFreePlacesForItem(item)
end

function Inventory:getLowEmptyPlace(bag)
	self.m_Bag[bag] = self.m_Bag[bag] or {}
	local place = 0
	while self.m_Bag[bag][place] do
		place = place + 1
	end
	return place
end

function Inventory:getPlaces(bag)
	local highest = 0
	if bag and self.m_Bag[bag] then
		for place in pairs(self.m_Bag[bag]) do
			if place > highest then highest = place end
		end
	end
	return highest
end

function Inventory:getItemValueByBag(bag, place)
	if bag and place then
		local id = self:getItemID(bag, place)
		if id then
			return self.m_Items[id]["Value"]
		end
	end
end

function Inventory:isPlaceEmpty(bag, place)
	local id = self:getItemID(bag, place)
	return not (id and self.m_Items[id] and self.m_Items[id]["Objekt"])
end

function Inventory:setItemValueByBag(bag, place, value)
	if bag and place then
		local id = self:getItemID(bag, place)
		if id then
			self.m_Items[id]["Value"] = value
			self:saveItemValue(id, value)
		end
	end
end

function Inventory:getRowsOfItem(item)
	local itemName = self:resolve(item)
	local rows = {}
	if not itemName then
		outputDebugString("[INV] Ungültiges Item: "..tostring(item))
		return rows
	end
	for id, row in pairs(self.m_Items) do
		if row["Objekt"] == itemName then
			rows[#rows + 1] = id
		end
	end
	table.sort(rows)
	return rows
end

function Inventory:getItemPlacesByName(item)
	local placeTable = {}
	for _index, id in ipairs(self:getRowsOfItem(item)) do
		placeTable[#placeTable + 1] = {self.m_Items[id]["Platz"], self.m_Items[id]["Tasche"]}
	end
	return placeTable
end

function Inventory:removeItemFromPlace(bag, place, amount, value)
	local id = self:getItemID(bag, place)
	if not id or not self.m_Items[id] then return false end

	local itemAmount = self.m_Items[id]["Menge"]
	local itemName = self.m_Items[id]["Objekt"]

	if not amount then
		amount = itemAmount
	elseif amount < 0 then
		error("removeItem > You cant remove less then 0 items!", 2)
		return false
	end

	if itemAmount - amount < 0 then
		return false
	elseif itemAmount - amount > 0 then
		self.m_Items[id]["Menge"] = itemAmount - amount
		self:saveItemAmount(id, self.m_Items[id]["Menge"])
	else
		self.m_Items[id] = nil
		self.m_Bag[bag][place] = nil
		self:deleteItem(id)
	end

	self:refreshArmedAmmo(itemName)
	self:logItemMove(itemName, -amount)
	return true
end

function Inventory:logItemMove(itemName, amount)
	if self.m_SyncingAmmo or not isElement(self.m_Owner) then return end

	local source = "unbekannt"
	for level = 2, 12 do
		local info = debug.getinfo(level, "Sl")
		if not info then break end
		if not info.short_src:find("Inventory/Inventory.lua", 1, true) then
			source = ("%s:%d"):format(info.short_src:gsub("^.-classes/", ""), info.currentline)
			break
		end
	end
	StatisticsLogger:getSingleton():addItemMoveLog(self.m_Owner:getId(), itemName, amount, source)
end

function Inventory:getFreePlacesForItem(item)
	local itemName = self:resolve(item)
	if not itemName then
		outputDebugString("[INV] Ungültiges Item: "..tostring(item))
		return 0
	end

	local data = self.m_ItemData[itemName]
	local limitSpace = self:getItemLimitSpace(itemName)
	if data["DienstItem"] == 1 or data["Gewicht"] <= 0 or self:isOverloadExempt() then return limitSpace end
	return math.min(limitSpace, math.max(0, math.floor((self:getFreeCarryWeight() + 0.0001) / data["Gewicht"])))
end

function Inventory:getItemLimitSpace(itemName)
	local maxItems = self.m_ItemData[itemName]["Item_Max"]
	if not maxItems or maxItems < 0 then return UNLIMITED end
	return math.max(0, maxItems - self:getItemAmount(itemName))
end

function Inventory:removeItem(item, amount, value, wearFilter)
	local itemName = self:resolve(item)
	if not itemName then return false end

	local matches = function(row)
		if value and row["Value"] ~= value then return false end
		return wearFilter == nil or row["WearLevel"] == (wearFilter or nil)
	end

	local rows = self:getRowsOfItem(itemName)
	local available = 0
	for _index, id in ipairs(rows) do
		if matches(self.m_Items[id]) then
			available = available + self.m_Items[id]["Menge"]
		end
	end
	if available < amount then return false end

	local remaining = amount
	for _index, id in ipairs(rows) do
		if remaining <= 0 then break end
		local row = self.m_Items[id]
		if matches(row) then
			local take = math.min(row["Menge"], remaining)
			if self:removeItemFromPlace(row["Tasche"], row["Platz"], take, value) then
				remaining = remaining - take
			end
		end
	end
	return remaining <= 0
end

function Inventory:removeAllItem(item, value)
	local removed = false
	for _index, id in ipairs(self:getRowsOfItem(item)) do
		local row = self.m_Items[id]
		if not value or row["Value"] == value then
			self:removeItemFromPlace(row["Tasche"], row["Platz"])
			removed = true
		end
	end
	return removed
end

function Inventory:getItemAmount(item, inStack)
	local amount = 0
	for _index, id in ipairs(self:getRowsOfItem(item)) do
		local rowAmount = self.m_Items[id]["Menge"]
		if inStack then
			amount = math.max(amount, rowAmount)
		else
			amount = amount + rowAmount
		end
	end
	return amount
end

function Inventory:throwItem(item, bag, id, place, name, amount)
	local row = self.m_Items[self:getItemID(bag, place)]
	if not row then return end

	local data = self.m_ItemData[row["Objekt"]]
	if data["Wegwerf"] ~= 1 then
		self.m_Owner:sendError(_("Du kannst dieses Item nicht zerstören!", self.m_Owner))
		return
	end
	if data["WaffenId"] and self:isWeaponArmed(data["WaffenId"]) then
		self.m_Owner:sendError(_("Stecke die Waffe zuerst weg!", self.m_Owner))
		return
	end

	local itemName = row["Objekt"]
	local value = row["Value"]
	amount = amount and math.floor(math.abs(amount)) or row["Menge"]
	if amount <= 0 or amount > row["Menge"] then return end

	local dropped = self:dropToWorld(row, amount)
	if dropped then
		self.m_Owner:sendInfo(_("Du hast %dx %s auf den Boden geworfen!", self.m_Owner, amount, itemName))
		self.m_Owner:meChat(true, "wirft %s weg!", itemName, true)
	else
		self.m_Owner:sendInfo(_("Du hast %dx %s weggeworfen!", self.m_Owner, amount, itemName))
		self.m_Owner:meChat(true, "zerstört %s!", itemName, true)
	end
	if amount == row["Menge"] then
		WearableManager:getSingleton():removeWearable(self.m_Owner, itemName, value)
	end
	self:removeItemFromPlace(bag, place, amount)
	if itemName == "Clubkarte" then
		self.m_Owner:setData("PlayHouse:clubcard", nil, true)
	end
end

function Inventory:findStackRow(itemName, value)
	local data = self.m_ItemData[itemName]
	for _index, id in ipairs(self:getRowsOfItem(itemName)) do
		local row = self.m_Items[id]
		if not value and row["Value"] == "" then
			return id
		elseif value and row["Value"] == value and (value == DUTY_VALUE or data["VerfallTage"]) then
			return id
		end
	end
	return false
end

function Inventory:giveItemFromName(itemName, amount, value, force, wearLevel)
	local data = self.m_ItemData[itemName]
	return self:giveItem(data and data["Id"] or itemName, amount, value, force, wearLevel)
end

function Inventory:giveItem(itemId, amount, value, force, wearLevel)
	local itemName = type(itemId) == "number" and self:resolve(itemId)
	if not itemName then
		outputDebugString("[INV] Ungültiges Item bei giveItem: "..tostring(itemId))
		if not self.m_Owner.m_Disconnecting then
			self.m_Owner:sendError(_("Ungültiges Item! (%s)", self.m_Owner, tostring(itemId)))
		end
		return false
	end

	amount = math.floor(amount)
	if amount <= 0 then return false end
	if value == "" then value = false end

	local data = self.m_ItemData[itemName]
	if not value and data["VerfallTage"] then
		value = getRealTime().timestamp + data["VerfallTage"] * 86400
	end

	if not force and amount > self:getItemLimitSpace(itemName) then
		self.m_Owner:sendError(_("Du kannst von %s höchstens %d Stück haben!", self.m_Owner, _(itemName, self.m_Owner), data["Item_Max"]))
		return false
	end

	if not force and not self:canCarry(itemName, amount) then
		self.m_Owner:sendError(_("%dx %s ist zu schwer! Du kannst noch %.2f kg tragen.", self.m_Owner, amount, _(itemName, self.m_Owner), math.max(0, self:getFreeCarryWeight())))
		return false
	end

	local id = self:findStackRow(itemName, value)
	if id and wearLevel and self.m_Items[id]["WearLevel"] ~= wearLevel then
		id = false
	end
	if id then
		self.m_Items[id]["Menge"] = self.m_Items[id]["Menge"] + amount
		self:saveItemAmount(id, self.m_Items[id]["Menge"])
	else
		local bag = Inventory.DefaultBag
		local place = self:getLowEmptyPlace(bag)
		local wear = wearLevel or data["MaxWear"]
		local lastId = self:insertItem(amount, itemName, place, bag, value or "", wear)
		self:loadRow({["id"] = lastId, ["Objekt"] = tostring(data["Id"]), ["Menge"] = amount, ["Platz"] = place, ["Tasche"] = bag, ["Value"] = value or "", ["WearLevel"] = wear})
	end

	self:refreshArmedAmmo(itemName)
	self:logItemMove(itemName, amount)
	self:syncClient()
	return true
end

function Inventory:getItemWearLevelByBag(bag, place)
	if bag and place then
		local id = self:getItemID(bag, place)
		if id then
			return self.m_Items[id]["WearLevel"]
		end
	end
end

function Inventory:setItemWearLevelByBag(bag, place, wearLevel)
	if bag and place then
		local id = self:getItemID(bag, place)
		if id then
			self.m_Items[id]["WearLevel"] = wearLevel
			self:saveItemWearLevel(id, wearLevel)
		end
	end
end

function Inventory:decreaseItemWearLevelByBag(bag, place)
	if bag and place then
		local id = self:getItemID(bag, place)
		if id then
			local wearLevel = self.m_Items[id]["WearLevel"] - 1
			if wearLevel <= 0 then
				self:removeItemFromPlace(bag, place)
				return true
			else
				self:setItemWearLevelByBag(bag, place, wearLevel)
				return false
			end
		end
	end
end

function Inventory:decreaseItemWearLevel(itemName)
	if self.m_ItemData[itemName] and self.m_ItemData[itemName]["MaxWear"] then
		if self:getItemAmount(itemName) ~= 1 then return end

		local place, bag = unpack(self:getItemPlacesByName(itemName)[1])

		local id = self:getItemID(bag, place)
		if not self.m_Items[id]["WearLevel"] then
			self.m_Items[id]["WearLevel"] = self.m_ItemData[itemName]["MaxWear"]
		end

		return self:decreaseItemWearLevelByBag(bag, place)
	end
end

function Inventory:getAmmoItemName(weaponId)
	local manager = InventoryManager:getSingleton()
	if THROWABLE_WEAPONS[weaponId] then
		return manager:getWeaponItemName(weaponId)
	end
	return manager:getAmmoItemName(weaponId)
end

function Inventory:hasWeapon(weaponId)
	local itemName = InventoryManager:getSingleton():getWeaponItemName(weaponId)
	return itemName and self:getItemAmount(itemName) > 0
end

function Inventory:getRounds(weaponId)
	local ammoItem = self:getAmmoItemName(weaponId)
	return ammoItem and self:getItemAmount(ammoItem) or 0
end

function Inventory:isWeaponArmed(weaponId)
	return getPedWeapon(self.m_Owner, getSlotFromWeapon(weaponId)) == weaponId
end

function Inventory:isWeaponContext()
	return isInventoryWeaponContext(self.m_Owner)
end

function Inventory:syncArmedAmmo()
	if self.m_SyncingAmmo or not isElement(self.m_Owner) or isPedDead(self.m_Owner) or not self:isWeaponContext() then return end

	self.m_SyncingAmmo = true
	local manager = InventoryManager:getSingleton()
	for slot = 0, 12 do
		local weaponId = getPedWeapon(self.m_Owner, slot)
		local ammoItem = weaponId > 0 and manager:getWeaponItemName(weaponId) and self:getAmmoItemName(weaponId)
		if ammoItem then
			local carried = self:getItemAmount(ammoItem)
			local loaded = getPedTotalAmmo(self.m_Owner, slot)
			if loaded < carried then
				self:removeItem(ammoItem, carried - loaded)
			end
		end
	end
	self.m_SyncingAmmo = false
end

function Inventory:refreshArmedAmmo(itemName)
	if self.m_SyncingAmmo or not isElement(self.m_Owner) or not self:isWeaponContext() then return end

	local data = self.m_ItemData[itemName]
	local weaponId = data["MunitionFuer"] or (data["WaffenId"] and THROWABLE_WEAPONS[data["WaffenId"]] and data["WaffenId"])
	if weaponId and self:isWeaponArmed(weaponId) then
		local rounds = self:getRounds(weaponId)
		if rounds > 0 then
			_setWeaponAmmo(self.m_Owner, weaponId, rounds)
		elseif THROWABLE_WEAPONS[weaponId] then
			rawTakeWeapon(self.m_Owner, weaponId)
		else
			_setWeaponAmmo(self.m_Owner, weaponId, 0)
		end
	end
end

function Inventory:armWeapon(weaponId, current)
	if not self:hasWeapon(weaponId) then return false end

	local slot = getSlotFromWeapon(weaponId)
	local previous = getPedWeapon(self.m_Owner, slot)
	if previous > 0 and previous ~= weaponId then
		self:syncArmedAmmo()
		rawTakeWeapon(self.m_Owner, previous)
	end

	local rounds = NO_MUNITION_WEAPONS[weaponId] and 1 or self:getRounds(weaponId)
	if previous == weaponId then
		if not NO_MUNITION_WEAPONS[weaponId] then
			_setWeaponAmmo(self.m_Owner, weaponId, rounds)
		end
	else
		rawGiveWeapon(self.m_Owner, weaponId, rounds, current)
	end
	self:updateVisibleWeapons()
	return true
end

function Inventory:disarmWeapon(weaponId)
	if not self:isWeaponArmed(weaponId) then return end
	self:syncArmedAmmo()
	rawTakeWeapon(self.m_Owner, weaponId)
	self:updateVisibleWeapons()
end

function Inventory:toggleWeapon(weaponId)
	if not self:isWeaponContext() then
		self.m_Owner:sendError(_("Du kannst deine Waffen gerade nicht benutzen!", self.m_Owner))
		return false
	end

	if self:isWeaponArmed(weaponId) then
		self:disarmWeapon(weaponId)
		self.m_Owner:sendInfo(_("%s weggesteckt.", self.m_Owner, WEAPON_NAMES[weaponId]))
	else
		if self.m_Owner:getWeaponLevel() < (MIN_WEAPON_LEVELS[weaponId] or 0) then
			self.m_Owner:sendError(_("Dein Waffenlevel ist zu niedrig! (Benötigt: %i)", self.m_Owner, MIN_WEAPON_LEVELS[weaponId]))
			return false
		end

		local row = self.m_Items[self:getRowsOfItem(InventoryManager:getSingleton():getWeaponItemName(weaponId))[1]]
		local faction = self.m_Owner:getFaction()
		if row and row["Value"] ~= DUTY_VALUE and faction and faction:isStateFaction() and self.m_Owner:isFactionDuty() then
			self.m_Owner:sendError(_("Du darfst im Dienst keine privaten Waffen verwenden!", self.m_Owner))
			return false
		end

		self:armWeapon(weaponId, true)
		if not NO_MUNITION_WEAPONS[weaponId] and self:getRounds(weaponId) == 0 then
			self.m_Owner:sendWarning(_("Du hast keine Munition für %s.", self.m_Owner, WEAPON_NAMES[weaponId]))
		end
	end
	self:syncClient()
	return true
end

function Inventory:getDutyValue()
	local faction = self.m_Owner:getFaction()
	if faction and not faction:isEvilFaction() and self.m_Owner:isFactionDuty() then
		return DUTY_VALUE
	end
	return false
end

function Inventory:onWeaponGiven(weaponId, ammo, current)
	local manager = InventoryManager:getSingleton()
	local weaponItem = manager:getWeaponItemName(weaponId)
	local value = self:getDutyValue()
	ammo = math.floor(tonumber(ammo) or 0)
	self.m_SyncPaused = true

	if THROWABLE_WEAPONS[weaponId] then
		if ammo > 0 then
			self:giveItemFromName(weaponItem, ammo, value, true)
		end
	else
		if not self:hasWeapon(weaponId) then
			self:giveItemFromName(weaponItem, 1, value, true)
		end
		local ammoItem = manager:getAmmoItemName(weaponId)
		if ammoItem and ammo > 0 and not NO_MUNITION_WEAPONS[weaponId] then
			self:giveItemFromName(ammoItem, ammo, value, true)
		end
	end

	self:armWeapon(weaponId, current)
	self.m_SyncPaused = false
	self:syncClient()
	return true
end

function Inventory:onWeaponTaken(weaponId, ammo)
	local manager = InventoryManager:getSingleton()
	local weaponItem = manager:getWeaponItemName(weaponId)
	self:syncArmedAmmo()

	if ammo then
		local ammoItem = self:getAmmoItemName(weaponId)
		if ammoItem then
			self:removeItem(ammoItem, math.min(math.floor(ammo), self:getItemAmount(ammoItem)))
		end
		self:syncClient()
		return true
	end

	self.m_SyncingAmmo = true
	self:removeAllItem(weaponItem)
	local ammoItem = manager:getAmmoItemName(weaponId)
	if ammoItem then
		self:removeAllItem(ammoItem)
	end
	self.m_SyncingAmmo = false
	rawTakeWeapon(self.m_Owner, weaponId)
	self:syncClient()
	return true
end

function Inventory:onAllWeaponsTaken()
	self:syncArmedAmmo()
	self.m_SyncingAmmo = true
	for id, row in pairs(table.copy(self.m_Items)) do
		local data = self.m_ItemData[row["Objekt"]]
		if data["WaffenId"] or data["MunitionFuer"] then
			self:removeItemFromPlace(row["Tasche"], row["Platz"])
		end
	end
	self.m_SyncingAmmo = false
	self:syncClient()
end

function Inventory:getCarriedWeapons()
	self:syncArmedAmmo()
	local weapons = {}
	for id, row in pairs(self.m_Items) do
		local weaponId = self.m_ItemData[row["Objekt"]]["WaffenId"]
		if weaponId then
			local rounds = self:getRounds(weaponId)
			weapons[#weapons + 1] = {weaponId, THROWABLE_WEAPONS[weaponId] and row["Menge"] or rounds}
		end
	end
	return weapons
end

function Inventory:takeWeaponsForDeath()
	local weapons = self:getCarriedWeapons()
	local carriedAmmo = {}
	for _index, info in ipairs(weapons) do
		carriedAmmo[info[1]] = true
	end

	local looseAmmo = {}
	self.m_SyncingAmmo = true
	for id, row in pairs(table.copy(self.m_Items)) do
		local data = self.m_ItemData[row["Objekt"]]
		if data["MunitionFuer"] and not carriedAmmo[data["MunitionFuer"]] then
			looseAmmo[#looseAmmo + 1] = {data["MunitionFuer"], row["Menge"]}
		end
		if data["WaffenId"] or data["MunitionFuer"] then
			self:removeItemFromPlace(row["Tasche"], row["Platz"])
		end
	end
	self.m_SyncingAmmo = false
	self:syncClient()
	return weapons, looseAmmo
end

function Inventory:restoreSavedWeapon(weaponId, ammo)
	local manager = InventoryManager:getSingleton()
	if not manager:getWeaponItemName(weaponId) then
		rawGiveWeapon(self.m_Owner, weaponId, ammo)
		return
	end

	if not self:hasWeapon(weaponId) then
		if ammo <= 0 then return end
		self:onWeaponGiven(weaponId, ammo)
	else
		self:armWeapon(weaponId)
	end
end

function Inventory:dropToWorld(row, amount)
	local data = self.m_ItemData[row["Objekt"]]
	if data["WegwerfDrop"] ~= 1 or row["Value"] == DUTY_VALUE or not self:isWeaponContext() then
		return false
	end

	local position = self.m_Owner:getPosition()
	local int, dim = self.m_Owner:getInterior(), self.m_Owner:getDimension()

	if data["WaffenId"] then
		if not WEAPON_MODELS_WORLD[data["WaffenId"]] then return false end
		local ammo = THROWABLE_WEAPONS[data["WaffenId"]] and amount or 0
		PickupWeapon:new(position.x, position.y, position.z, int, dim, data["WaffenId"], ammo, self.m_Owner, false)
	elseif data["MunitionFuer"] then
		if not WEAPON_MODELS_WORLD[data["MunitionFuer"]] then return false end
		PickupWeapon:new(position.x, position.y, position.z, int, dim, data["MunitionFuer"], amount, self.m_Owner, false, false, 0, 0, true)
	else
		PickupItem:new(position.x, position.y, position.z, int, dim, row["Objekt"], amount, row["Value"], self.m_Owner, row["WearLevel"])
	end
	return true
end
