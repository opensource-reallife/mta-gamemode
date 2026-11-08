ItemStorage = inherit(Object)
ItemStorage.Map = {}

addRemoteEvents{"itemStorageMove", "itemStorageClose"}

function ItemStorage.get(storageType, ownerId, config)
	local key = ("%s:%d"):format(storageType, ownerId)
	if not ItemStorage.Map[key] then
		ItemStorage.Map[key] = ItemStorage:new(key, storageType, ownerId)
	end
	ItemStorage.Map[key]:setConfig(config)
	return ItemStorage.Map[key]
end

function ItemStorage:constructor(key, storageType, ownerId)
	self.m_Key = key
	self.m_Type = storageType
	self.m_OwnerId = ownerId
	self.m_Rows = {}
	self.m_Viewers = {}

	local manager = InventoryManager:getSingleton()
	for _index, row in ipairs(sql:queryFetch("SELECT * FROM ??_item_storages WHERE StorageType = ? AND OwnerId = ?", sql:getPrefix(), storageType, ownerId)) do
		local itemName = manager:resolveItemName(tonumber(row["ItemId"]))
		if itemName then
			self.m_Rows[tonumber(row["Id"])] = {
				["Item"] = itemName,
				["ItemId"] = tonumber(row["ItemId"]),
				["Amount"] = tonumber(row["Amount"]),
				["Value"] = row["Value"] or "",
				["WearLevel"] = tonumber(row["WearLevel"]) or nil
			}
		end
	end
	self:removeExpired()
end

function ItemStorage:setConfig(config)
	self.m_Config = config or self.m_Config
end

function ItemStorage:getItemData(itemName)
	return InventoryManager:getSingleton():getItemDataForItem(itemName)
end

function ItemStorage:getWeight()
	local weight = 0
	for id, row in pairs(self.m_Rows) do
		weight = weight + self:getItemData(row["Item"])["Gewicht"] * row["Amount"]
	end
	return weight
end

function ItemStorage:getCapacity()
	return self.m_Config.getCapacity()
end

function ItemStorage:removeExpired()
	local now = getRealTime().timestamp
	for id, row in pairs(table.copy(self.m_Rows)) do
		local data = self:getItemData(row["Item"])
		local expiry = data["VerfallAm"] or (data["VerfallTage"] and (tonumber(row["Value"]) or 0))
		if expiry and expiry <= now then
			StatisticsLogger:getSingleton():addItemMoveLog(self.m_Type == "gunbox" and self.m_OwnerId or 0, row["Item"], -row["Amount"], ("Verfall %s"):format(self.m_Key))
			self:removeRow(id, row["Amount"])
		end
	end
end

function ItemStorage:findRow(itemName, value, wearLevel)
	for id, row in pairs(self.m_Rows) do
		if row["Item"] == itemName and row["Value"] == (value or "") and row["WearLevel"] == wearLevel then
			return id
		end
	end
	return false
end

function ItemStorage:addRow(itemName, amount, value, wearLevel)
	local id = self:findRow(itemName, value, wearLevel)
	if id then
		self.m_Rows[id]["Amount"] = self.m_Rows[id]["Amount"] + amount
		sql:queryExec("UPDATE ??_item_storages SET Amount = ? WHERE Id = ?", sql:getPrefix(), self.m_Rows[id]["Amount"], id)
		return
	end

	local itemId = InventoryManager:getSingleton():getItemId(itemName)
	sql:queryExec("INSERT INTO ??_item_storages (StorageType, OwnerId, ItemId, Amount, Value, WearLevel) VALUES (?, ?, ?, ?, ?, ?)", sql:getPrefix(), self.m_Type, self.m_OwnerId, itemId, amount, value or "", wearLevel)
	self.m_Rows[sql:lastInsertId()] = {["Item"] = itemName, ["ItemId"] = itemId, ["Amount"] = amount, ["Value"] = value or "", ["WearLevel"] = wearLevel}
end

function ItemStorage:removeRow(id, amount)
	local row = self.m_Rows[id]
	if row["Amount"] - amount > 0 then
		row["Amount"] = row["Amount"] - amount
		sql:queryExec("UPDATE ??_item_storages SET Amount = ? WHERE Id = ?", sql:getPrefix(), row["Amount"], id)
	else
		self.m_Rows[id] = nil
		sql:queryExec("DELETE FROM ??_item_storages WHERE Id = ?", sql:getPrefix(), id)
	end
end

function ItemStorage:importItem(item, amount, value)
	local itemName = InventoryManager:getSingleton():resolveItemName(item)
	if itemName and amount and amount > 0 then
		self:addRow(itemName, amount, value)
		return true
	end
	return false
end

function ItemStorage:importWeapon(weaponId, ammo)
	local manager = InventoryManager:getSingleton()
	local weaponItem = manager:getWeaponItemName(weaponId)
	if not weaponItem then return false end

	if THROWABLE_WEAPONS[weaponId] then
		self:addRow(weaponItem, math.max(1, ammo or 1))
		return true
	end
	self:addRow(weaponItem, 1)
	local ammoItem = manager:getAmmoItemName(weaponId)
	if ammoItem and ammo and ammo > 0 then
		self:addRow(ammoItem, ammo)
	end
	return true
end

function ItemStorage:open(player)
	if not self.m_Config.canAccess(player) then return false end
	self:removeExpired()
	player.m_OpenStorage = self
	self.m_Viewers[player] = true
	player:triggerEvent("itemStorageOpen", self.m_Key, self.m_Config.title, self.m_Config.head, self.m_Config.rule, self.m_Config.element)
	self:sync(player)
	return true
end

function ItemStorage:close(player)
	if player.m_OpenStorage == self then
		player.m_OpenStorage = nil
	end
	self.m_Viewers[player] = nil
end

function ItemStorage:sync(player)
	player:getInventory():syncClient()
	player:triggerEvent("itemStorageSync", self.m_Key, self.m_Rows, self:getWeight(), self:getCapacity(), self:getAcceptedItems(), self:getSyncOptions(player))
end

function ItemStorage:syncAll()
	for player in pairs(self.m_Viewers) do
		if isElement(player) and player.m_OpenStorage == self then
			self:sync(player)
		else
			self.m_Viewers[player] = nil
		end
	end
end

function ItemStorage:getAcceptedItems()
	local accepted = {}
	for itemName, data in pairs(InventoryManager:getSingleton().m_ItemData) do
		if self.m_Config.accepts(itemName, data) then
			accepted[itemName] = true
		end
	end
	return accepted
end

function ItemStorage:deposit(player, itemName, amount, value, wearLevel)
	local inventory = player:getInventory()
	local data = self:getItemData(itemName)
	local wearFilter = nil
	if data["MaxWear"] then
		wearFilter = wearLevel or false
	else
		wearLevel = nil
	end

	if not self.m_Config.accepts(itemName, data) then
		return player:sendError(_("Dieses Item kannst du hier nicht einlagern!", player))
	end
	if value == "duty" or data["DienstItem"] == 1 then
		return player:sendError(_("Dienst-Items kannst du nicht einlagern!", player))
	end
	if data["WaffenId"] and inventory:isWeaponArmed(data["WaffenId"]) then
		return player:sendError(_("Stecke die Waffe zuerst weg!", player))
	end
	if self.m_Config.canDeposit and not self.m_Config.canDeposit(player, itemName, data, value) then
		return
	end
	if self:getWeight() + data["Gewicht"] * amount > self:getCapacity() + 0.0001 then
		return player:sendError(_("%dx %s passt nicht mehr hinein! Frei sind noch %.2f kg.", player, amount, itemName, math.max(0, self:getCapacity() - self:getWeight())))
	end
	if not inventory:removeItem(data["Id"], amount, value, wearFilter) then
		return player:sendError(_("Du hast nicht genug %s!", player, itemName))
	end

	WearableManager:getSingleton():removeWearable(player, itemName, value)
	self:addRow(itemName, amount, value, wearLevel)
	player:sendInfo(_("Du hast %dx %s eingelagert!", player, amount, itemName))
	if self.m_Config.onMoved then
		self.m_Config.onMoved(player, "insert", itemName, amount)
	end
	self:syncAll()
end

function ItemStorage:withdraw(player, itemName, amount, value, wearLevel)
	local id = self:findRow(itemName, value, wearLevel)
	if not id or self.m_Rows[id]["Amount"] < amount then
		return player:sendError(_("So viel ist hier nicht eingelagert!", player))
	end

	local inventory = player:getInventory()
	local data = self:getItemData(itemName)

	if self.m_Config.onWithdraw then
		local handled = self.m_Config.onWithdraw(player, itemName, data, amount, value)
		if handled == true then
			self:removeRow(id, amount)
			self:syncAll()
			return
		elseif handled == false then
			return
		end
	end

	if data["WaffenId"] and not THROWABLE_WEAPONS[data["WaffenId"]] then
		if inventory:hasWeapon(data["WaffenId"]) then
			return player:sendError(_("Du hast bereits eine %s dabei!", player, itemName))
		end
		if player:getWeaponLevel() < (MIN_WEAPON_LEVELS[data["WaffenId"]] or 0) then
			return player:sendError(_("Dein Waffenlevel ist zu niedrig! (Benötigt: %i)", player, MIN_WEAPON_LEVELS[data["WaffenId"]]))
		end
		amount = 1
	end
	if not inventory:giveItem(data["Id"], amount, value, false, wearLevel) then
		return
	end

	self:removeRow(id, amount)
	player:sendInfo(_("Du hast %dx %s entnommen!", player, amount, itemName))
	if self.m_Config.onMoved then
		self.m_Config.onMoved(player, "take", itemName, amount)
	end
	self:syncAll()
end

addEventHandler("itemStorageMove", root, function(key, direction, item, amount, value, wearLevel)
	local storage = ItemStorage.Map[key]
	if not storage or client.m_OpenStorage ~= storage then return end
	if not storage.m_Config.canAccess(client) then
		storage:close(client)
		return
	end
	if client:hasTemporaryStorage() then
		return client:sendError(_("Das geht gerade nicht!", client))
	end

	local itemName = InventoryManager:getSingleton():resolveItemName(item)
	amount = math.floor(tonumber(amount) or 0)
	if not itemName or amount <= 0 then return end
	if value == "" then value = nil end
	wearLevel = tonumber(wearLevel)

	if direction == "toStore" then
		storage:deposit(client, itemName, amount, value, wearLevel)
	elseif direction == "toPlayer" then
		storage:withdraw(client, itemName, amount, value, wearLevel)
	end
end)

addEventHandler("itemStorageClose", root, function()
	if client.m_OpenStorage then
		client.m_OpenStorage:close(client)
	end
end)

function ItemStorage:getSyncOptions(player)
	return nil
end

EquipmentStorage = inherit(ItemStorage)

function EquipmentStorage.get(depot, element)
	local key = ("equipment:%d"):format(depot:getId())
	if not ItemStorage.Map[key] then
		ItemStorage.Map[key] = EquipmentStorage:new(key, depot)
	end
	ItemStorage.Map[key].m_Config.element = element
	return ItemStorage.Map[key]
end

function EquipmentStorage:constructor(key, depot)
	self.m_Key = key
	self.m_Depot = depot
	self.m_Rows = {}
	self.m_Viewers = {}
	self.m_Config = {
		title = "Ausrüstungslager",
		head = "Lager:",
		rule = "Jede Bewegung landet im Log",
		getCapacity = function()
			return InventoryManager:getSingleton():getCapacity("equipment")
		end,
		accepts = function(itemName, data)
			return self:isProduct(itemName) and data["Handel"] == 1
		end,
		canAccess = function(player)
			return self.m_Depot:checkDistanceFromEquipment(player)
		end,
	}
end

function EquipmentStorage:isProduct(itemName)
	if ArmsDealer.Data["Waffen"][itemName] then return false end
	local data = InventoryManager:getSingleton():getItemDataForItem(itemName)
	if not data or data["WaffenId"] then return false end
	return ArmsDealer:getSingleton():getItemData(itemName) and true or false
end

function EquipmentStorage:removeExpired()
end

function EquipmentStorage:refreshRows()
	self.m_Rows = {}
	for itemName, amount in pairs(self.m_Depot:getEquipmentTable()) do
		if amount > 0 and self:isProduct(itemName) then
			local armsData = ArmsDealer:getSingleton():getItemData(itemName)
			self.m_Rows[#self.m_Rows + 1] = {["Item"] = itemName, ["Amount"] = amount, ["Value"] = "", ["WeaponIcon"] = armsData[3]}
		end
	end
end

function EquipmentStorage:sync(player)
	self:refreshRows()
	ItemStorage.sync(self, player)
end

function EquipmentStorage:getSyncOptions(player)
	local entries = {}
	for itemName in pairs(self.m_Depot:getEquipmentTable()) do
		local armsData = ArmsDealer:getSingleton():getItemData(itemName)
		if armsData and armsData[3] and self:isProduct(itemName) and getPedWeapon(player, getSlotFromWeapon(armsData[3])) == armsData[3] then
			local ammo = getPedTotalAmmo(player, getSlotFromWeapon(armsData[3]))
			if ammo > 0 then
				entries[#entries + 1] = {name = itemName, value = "", amount = ammo, weaponIcon = armsData[3]}
			end
		end
	end
	return {entries = entries}
end

function EquipmentStorage:deposit(player, itemName, amount, value)
	self:refreshRows()
	local data = self:getItemData(itemName)
	if self:getWeight() + data["Gewicht"] * amount > self:getCapacity() + 0.0001 then
		return player:sendError(_("%dx %s passt nicht mehr hinein!", player, amount, itemName))
	end
	self.m_Depot:addEquipment(player, itemName, amount)
	self:syncAll()
end

function EquipmentStorage:withdraw(player, itemName, amount, value)
	self.m_Depot:takeEquipment(player, itemName, amount)
	self:syncAll()
end

ArmoryStorage = inherit(ItemStorage)

function ArmoryStorage.get(depot, element)
	local key = ("armory:%d"):format(depot:getId())
	if not ItemStorage.Map[key] then
		ItemStorage.Map[key] = ArmoryStorage:new(key, depot)
	end
	ItemStorage.Map[key].m_Config.element = element
	return ItemStorage.Map[key]
end

function ArmoryStorage:constructor(key, depot)
	self.m_Key = key
	self.m_Depot = depot
	self.m_Rows = {}
	self.m_Viewers = {}
	self.m_Config = {
		canAccess = function(player)
			if not player.m_WeaponStoragePosition or getDistanceBetweenPoints3D(player.position, player.m_WeaponStoragePosition) > 10 then
				player:sendError(_("Du bist zu weit entfernt", player))
				return false
			end
			if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "useWeapons") then
				player:sendError(_("Du bist nicht berechtigt, Waffen zu nutzen!", player))
				return false
			end
			if self:getFaction():isStateFaction() and not player:isFactionDuty() then
				player:sendError(_("Du bist nicht im Dienst!", player))
				return false
			end
			return true
		end,
	}
end

function ArmoryStorage:getFaction()
	return self.m_Depot.m_Owner
end

function ArmoryStorage:getLimit(data)
	local weaponId = data["WaffenId"] or data["MunitionFuer"]
	local info = weaponId and self:getFaction().m_WeaponDepotInfo[weaponId]
	if not info then return 0 end
	return data["WaffenId"] and info["Waffe"] or info["Magazine"]
end

function ArmoryStorage:removeExpired()
end

function ArmoryStorage:refreshRows()
	local manager = InventoryManager:getSingleton()
	self.m_Rows = {}
	for weaponId, info in pairs(self.m_Depot:getWeaponTable()) do
		local weaponItem = manager:getWeaponItemName(weaponId)
		if weaponItem and (info["Waffe"] or 0) > 0 then
			self.m_Rows[#self.m_Rows + 1] = {["Item"] = weaponItem, ["Amount"] = info["Waffe"], ["Value"] = ""}
		end
		local ammoItem = manager:getAmmoItemName(weaponId)
		if ammoItem and (info["Munition"] or 0) > 0 then
			self.m_Rows[#self.m_Rows + 1] = {["Item"] = ammoItem, ["Amount"] = info["Munition"], ["Value"] = ""}
		end
	end
end

function ArmoryStorage:isPlayerAllowed(player, weaponId)
	local faction = self:getFaction()
	local special = faction.m_SpecialWeapons and faction.m_SpecialWeapons["Weapons"] or {}

	if not faction:isEvilFaction() then
		if not faction.m_ValidWeapons[weaponId] and not special[weaponId] then return false end
		if (weaponId == 27 or weaponId == 34) and not player:getData("Faction:InSpecialDuty") then return false end
		if weaponId == 36 and (player:getData("Faction:InSpecialDuty") or faction:getId() ~= 3) then return false end
	end

	if PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "changePermissions") then return true end

	local permissions = faction.m_PlayerWeaponPermissions[player:getId()] or {}
	local permission = permissions[tostring(weaponId)]
	if permission ~= nil then return permission == true end

	local rankWeapons = faction:getRankWeapons(faction.m_Players[player:getId()]) or {}
	return rankWeapons[tostring(weaponId)] == 1
end

function ArmoryStorage:deposit(player, itemName, amount, value)
	local inventory = player:getInventory()
	local data = self:getItemData(itemName)
	local weaponId = data["WaffenId"] or data["MunitionFuer"]
	if not weaponId or not self.m_Depot.m_Weapons[weaponId] or self:getLimit(data) <= 0 then
		return player:sendError(_("Dieses Item kannst du hier nicht einlagern!", player))
	end

	local stored = self.m_Depot.m_Weapons[weaponId][data["WaffenId"] and "Waffe" or "Munition"]
	if stored + amount > self:getLimit(data) then
		return player:sendError(_("Im Lager ist kein Platz mehr für %s (Limit %d)!", player, itemName, self:getLimit(data)))
	end
	if data["WaffenId"] and not THROWABLE_WEAPONS[weaponId] and inventory:isWeaponArmed(weaponId) then
		inventory:disarmWeapon(weaponId)
	end
	if not inventory:removeItem(data["Id"], amount, value) then
		return player:sendError(_("Du hast nicht genug %s!", player, itemName))
	end

	if data["WaffenId"] then
		self.m_Depot:addWeaponD(weaponId, amount)
	else
		self.m_Depot:addMagazineD(weaponId, amount)
	end
	self:getFaction():addLog(player, "Waffenlager", ("hat %s %s in das Lager gelegt!"):format(amount, itemName))
	player:sendInfo(_("Du hast %dx %s eingelagert!", player, amount, itemName))
	self.m_Depot:save()
	self:syncAll()
end

function ArmoryStorage:withdraw(player, itemName, amount, value)
	local inventory = player:getInventory()
	local data = self:getItemData(itemName)
	local weaponId = data["WaffenId"] or data["MunitionFuer"]
	local info = weaponId and self.m_Depot.m_Weapons[weaponId]
	if not info then return end

	if not self:isPlayerAllowed(player, weaponId) then
		return player:sendError(_("Du darfst %s nicht entnehmen!", player, itemName))
	end

	if data["WaffenId"] then
		if not THROWABLE_WEAPONS[weaponId] then
			if inventory:hasWeapon(weaponId) then
				return player:sendError(_("Du hast bereits eine %s dabei!", player, itemName))
			end
			amount = 1
		end
		if info["Waffe"] < amount then
			return player:sendError(_("So viel ist hier nicht eingelagert!", player))
		end
		if not inventory:canCarryWeapon(weaponId, THROWABLE_WEAPONS[weaponId] and amount or 0) then
			return player:sendError(_("%s ist zu schwer für dich!", player, itemName))
		end
		self.m_Depot:takeWeaponD(weaponId, amount)
		giveWeapon(player, weaponId, THROWABLE_WEAPONS[weaponId] and amount or (NO_MUNITION_WEAPONS[weaponId] and 1 or 0))
	else
		if info["Munition"] < amount then
			return player:sendError(_("So viel ist hier nicht eingelagert!", player))
		end
		local dutyValue = inventory:getDutyValue()
		if not inventory:giveItem(data["Id"], amount, dutyValue, dutyValue and true or false) then
			return
		end
		self.m_Depot:takeMagazineD(weaponId, amount)
	end

	self:getFaction():addLog(player, "Waffenlager", ("hat %s %s aus dem Lager genommen!"):format(amount, itemName))
	player:sendInfo(_("Du hast %dx %s entnommen!", player, amount, itemName))
	self.m_Depot:save()
	self:syncAll()
end

function ArmoryStorage:open(player)
	if not self.m_Config.canAccess(player) then return false end
	player.m_OpenStorage = self
	self.m_Viewers[player] = true
	player:triggerEvent("factionArmoryOpen", self.m_Key, self.m_Config.element)
	self:sync(player)
	return true
end

function ArmoryStorage:sync(player)
	self:refreshRows()
	player:getInventory():syncClient()

	local manager = InventoryManager:getSingleton()
	local depotInfo = self:getFaction().m_WeaponDepotInfo
	local weapons = {}
	for weaponId, info in pairs(self.m_Depot:getWeaponTable()) do
		local weaponItem = manager:getWeaponItemName(weaponId)
		local limits = depotInfo[weaponId]
		if weaponItem and limits then
			local stock, ammo = info["Waffe"] or 0, info["Munition"] or 0
			if limits["Waffe"] > 0 or limits["Magazine"] > 0 or stock > 0 or ammo > 0 then
				weapons[#weapons + 1] = {
					id = weaponId,
					weaponItem = weaponItem,
					ammoItem = manager:getAmmoItemName(weaponId),
					stock = stock,
					limit = limits["Waffe"],
					ammo = ammo,
					ammoLimit = limits["Magazine"],
					locked = not self:isPlayerAllowed(player, weaponId),
				}
			end
		end
	end
	player:triggerEvent("factionArmorySync", self.m_Key, weapons, self:getWeight())
end
