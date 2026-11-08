-- ****************************************************************************
-- *
-- *  PROJECT:     eXo
-- *  FILE:        server/classes/Factions/Depot.lua
-- *  PURPOSE:     Depot class
-- *
-- ****************************************************************************
Depot = inherit(Object)
Depot.Map = {}

function Depot.initalize()
	addRemoteEvents{"equipmentDepotAdd", "equipmentDepotTake"}

	addEventHandler("equipmentDepotAdd", root, function(id, item, amount)
		if Depot.Map[id] then
			Depot.Map[id]:addEquipment(client, item, math.floor(amount))
		end
	end)

	addEventHandler("equipmentDepotTake", root, function(id, item, amount)
		if Depot.Map[id] then
			Depot.Map[id]:takeEquipment(client, item, math.floor(amount))
		end
	end)
end
--//
function Depot.load(Id, Owner, type)
	if Depot.Map[Id] then return Depot.Map[Id] end
	if Id == 0 then
		sql:queryExec("INSERT INTO ??_depot (OwnerType) VALUES (?)", sql:getPrefix(), type or "GroupProperty")
		Id = sql:lastInsertId()
		Owner:setDepotId(Id)
	end

	local row = sql:queryFetchSingle("SELECT Weapons, Items, Equipments FROM ??_depot WHERE Id = ?;", sql:getPrefix(), Id)
	if not row then
		return
	end
	local weapons = row.Weapons or ""
	local items = row.Items or ""
	local equipments = row.Equipments or ""
	local DepotSave = false
	if string.len(weapons) < 5 then
		weapons = {}
		for i=1,45 do
			weapons[i] = {}
			weapons[i]["Id"] = i
			weapons[i]["Waffe"] = 0
			weapons[i]["Munition"] = 0
		end
		weapons = toJSON(weapons)
		DepotSave = true
		outputDebugString("Creating new Weapon-Table for Depot "..Id)
	end
	if string.len(items) < 5 then
		items = {}
		for i=1,6 do
			items[i] = {}
			items[i]["Item"] = 0
			items[i]["Amount"] = 0
		end
		items = toJSON(items)
		DepotSave = true
		outputDebugString("Creating new Item-Table for Depot "..Id)
	end

	if string.len(equipments) < 5 then
		equipments = {}
		for category, data in pairs(ArmsDealer.Data) do
			if category ~= "Waffen" then
				for product, subdata in pairs(data) do
					equipments[product] = 0
				end
			end
		end
		equipments = toJSON(equipments)
		DepotSave = true
		outputDebugString("Creating new Equipment-Table for Depot "..Id)
	end

	Depot.Map[Id] = Depot:new(Id, weapons, items, equipments, Owner)

	if DepotSave == true then Depot.Map[Id]:save() end

	return Depot.Map[Id]
end

function Depot:constructor(Id, weapons, items, equipments, owner)
	self.m_Id = Id
	self.m_Weapons = fromJSON(weapons)
	for id, weapon in pairs(self.m_Weapons) do
		if not weapon["InSchuss"] then
			weapon["Munition"] = (weapon["Munition"] or 0) * getWeaponClipSize(id)
			weapon["InSchuss"] = true
		end
	end
	self.m_Items = fromJSON(items)
	self.m_Equipments = fromJSON(equipments)
	self.m_Owner = owner
end

function Depot:destructor()
  self:save()
end

function Depot:save()
	return sql:queryExec("UPDATE ??_depot SET Weapons = ?, Items = ?, Equipments = ? WHERE Id = ?", sql:getPrefix(), toJSON(self.m_Weapons), toJSON(self.m_Items), toJSON(self.m_Equipments), self.m_Id)
end

function Depot:getId()
  return self.m_Id
end

function Depot:getWeaponTable()
  return self.m_Weapons
end

function Depot:getEquipmentTable()
	return self.m_Equipments
end

function Depot:getWeapon(id)
	if not self.m_Weapons[id] then return -1 end
	return self.m_Weapons[id]["Waffe"],self.m_Weapons[id]["Munition"]
end

function Depot:getEquipmentItem(item)
	return self.m_Equipments[item]
end

function Depot:takeWeaponD(id,amount)
	self.m_Weapons[id]["Waffe"] = self.m_Weapons[id]["Waffe"]-amount
end

function Depot:takeMagazineD(id,amount)
	self.m_Weapons[id]["Munition"] = self.m_Weapons[id]["Munition"] - amount
end

function Depot:addWeaponD(id,amount)
	self.m_Weapons[id]["Waffe"] = self.m_Weapons[id]["Waffe"] + amount
end

function Depot:addMagazineD(id,amount)
	self.m_Weapons[id]["Munition"] = self.m_Weapons[id]["Munition"] + amount
end

function Depot:getStorage(element)
	return ItemStorage.get("depot", self.m_Id, {
		title = "Itemlager",
		head = "Itemlager:",
		rule = "Jede Bewegung landet im Log",
		element = element,
		getCapacity = function()
			return InventoryManager:getSingleton():getCapacity("depot")
		end,
		accepts = function(itemName, data)
			return data["Handel"] == 1 and data["Id"] ~= 64 and not data["WaffenId"] and not data["MunitionFuer"]
		end,
		canAccess = function(player)
			return not element or not isElement(element) or getDistanceBetweenPoints3D(element.position, player.position) <= 15
		end,
		onMoved = function(player, action, itemName, amount)
			if action == "insert" then
				StatisticsLogger:getSingleton():addItemDepotLog(player, self.m_Id, itemName, amount)
				self.m_Owner:addLog(player, "Itemlager", ("hat %s  %s in das Lager gelegt!"):format(amount, itemName))
			else
				StatisticsLogger:getSingleton():addItemDepotLog(player, self.m_Id, itemName, -amount)
				self.m_Owner:addLog(player, "Itemlager", ("hat %s  %s aus dem Lager genommen!"):format(amount, itemName))
			end
		end,
	})
end

function Depot:importLegacyItems(storage)
	local changed = false
	for index, slot in pairs(self.m_Items) do
		if slot["Item"] and slot["Item"] ~= 0 then
			if storage:importItem(slot["Item"], slot["Amount"]) then
				self.m_Items[index] = {["Item"] = 0, ["Amount"] = 0}
				changed = true
			end
		end
	end
	if changed then self:save() end
end

function Depot:showItemDepot(player, depotElement)
	local storage = self:getStorage(depotElement)
	self:importLegacyItems(storage)
	storage:open(player)
end

function Depot:addItem(player, itemId, amount, giveItemFromServer)
	local item = InventoryManager:getSingleton():resolveItemName(itemId)
	if not item then return end
	local storage = self:getStorage()
	self:importLegacyItems(storage)
	if not giveItemFromServer and not player:getInventory():removeItem(InventoryManager:getSingleton():getItemId(item), amount) then
		player:sendError(_("Du hast nicht genug %s!", player, item))
		return
	end
	storage:importItem(item, amount)
	player:sendInfo(_("Du hast %d %s ins Depot gelegt!", player, amount, item))
	StatisticsLogger:getSingleton():addItemDepotLog(player, self.m_Id, item, amount)
	self.m_Owner:addLog(player, "Itemlager", ("hat %s  %s in das Lager gelegt!"):format(amount, item))
	storage:syncAll()
end

function Depot:showEquipmentDepot(player, depotElement)
	EquipmentStorage.get(self, depotElement):open(player)
	setElementData(player, "isEquipmentGUIOpen", false, true)
end

function Depot:showArmory(player, element)
	ArmoryStorage.get(self, element):open(player)
end

function Depot:getPlayerWeapons(player)
	local playerWeapons = {}
	if isInventoryWeaponContext(player) then
		for _index, info in ipairs(player:getInventory():getCarriedWeapons()) do
			playerWeapons[info[1]] = true
		end
	end
	for i=1, 12 do
		if getPedWeapon(player,i) > 0 then
			playerWeapons[getPedWeapon(player,i)] = true
		end
	end
	return playerWeapons
end

function Depot:takeWeaponsFromDepot(player,weaponTable)
	local playerWeapons = self:getPlayerWeapons(player)
	local ammoStorage = {}
	local weaponStorage = {}
	local bIsStorageWeapon = false
	local isInVariable = false
	local weaponInStorage, ammoInStorage = Guns:getWeaponInStorage( player, 2)
	local weaponBeforeEquip = getPedWeapon(player, 2)
	local ammoBeforeEquip = getPedTotalAmmo(player, 2)
	local logData = {} -- ["WeaponName"] = MagCount
	for weaponID,v in pairs(weaponTable) do
		for typ,amount in pairs(weaponTable[weaponID]) do
			if amount > 0 then
				local clipAmmo = getWeaponProperty(weaponID, "pro", "maximum_clip_ammo") or 1
				if WEAPON_CLIPS[weaponID] then clipAmmo = WEAPON_CLIPS[weaponID] end

				if typ == "Waffe" then
					if self.m_Weapons[weaponID]["Waffe"] >= amount and not player:getInventory():canCarryWeapon(weaponID, THROWABLE_WEAPONS[weaponID] and amount or 0) then
						player:sendError(_("%s ist zu schwer für dich!", player, WEAPON_NAMES[weaponID]))
					elseif self.m_Weapons[weaponID]["Waffe"] >= amount then
						slot = getSlotFromWeapon(weaponID)
						if slot == 2 then
							isInVariable = false
							for i = 1, #weaponStorage do
								if weaponStorage[i] == weaponID then
									isInVariable = true
								end
							end
							if not isInVariable then
								weaponStorage[#weaponStorage+1] = weaponID
								ammoStorage[weaponID] = clipAmmo
							end
						end
						if not logData[WEAPON_NAMES[weaponID]] then
							logData[WEAPON_NAMES[weaponID]] = 1
						else
							logData[WEAPON_NAMES[weaponID]] = logData[WEAPON_NAMES[weaponID]] + 1
						end
						if not THROWABLE_WEAPONS[weaponID] then
							giveWeapon(player,weaponID, NO_MUNITION_WEAPONS[weaponID] and 1 or 0) -- not usable shovel and night vision fix
						else
							giveWeapon(player,weaponID, amount, true)
						end
						self:takeWeaponD(weaponID,amount)
					else
						player:sendError(_("Es sind nicht genug %s im Lager (%s)!", player, WEAPON_NAMES[weaponID], amount))
					end
				elseif typ == "Munition" then
					playerWeapons = self:getPlayerWeapons(player)
					if playerWeapons[weaponID] then
						if self.m_Weapons[weaponID]["Munition"] >= amount and not player:getInventory():canCarryWeapon(weaponID, amount) then
							player:sendError(_("%s-Munition ist zu schwer für dich!", player, WEAPON_NAMES[weaponID]))
						elseif self.m_Weapons[weaponID]["Munition"] >= amount then
							self:takeMagazineD(weaponID,amount)
							bIsStorageWeapon = false
							for i = 1, #weaponStorage do
								if weaponStorage[i] == weaponID then
									bIsStorageWeapon = true
								end
							end
							if bIsStorageWeapon then
								ammoStorage[weaponID] = ammoStorage[weaponID]+amount
							end
							giveWeapon(player, weaponID, amount)
							if not logData[WEAPON_NAMES[weaponID]] then
								logData[WEAPON_NAMES[weaponID]] = amount
							else
								logData[WEAPON_NAMES[weaponID]] = logData[WEAPON_NAMES[weaponID]] + amount
							end
						else
							player:sendError(_("Es ist nicht genug %s-Munition im Lager (%s)!", player, WEAPON_NAMES[weaponID], amount))
						end
					else
						player:sendError(_("Du hast keine %s für diese Munition!", player, WEAPON_NAMES[weaponID]))
					end
				end
				if logData.w or logData.m then

				end
			end
		end
	end
	local textForPlayer = "Du hast folgende Waffen aus dem Lager genommen:"
	for i,v in pairs(logData) do
		self.m_Owner:addLog(player, "Waffenlager", ("hat ein/e(n) %s mit %s Schuss aus dem Lager genommen!"):format(i, (v-1)))
		textForPlayer = textForPlayer.."\n"..i
		if v > 1 then
			textForPlayer = textForPlayer.. " mit ".. (v-1) .. " Schuss"
		end
	end
	player:sendInfo(textForPlayer)
	self:save()
end



function Depot:addEquipment(player, item, amount, forceSpawn)
	if not forceSpawn and not self:checkDistanceFromEquipment(player) then return end
	if self.m_Equipments then
		local armsData = ArmsDealer:getSingleton():getItemData(item)
		local allAmount
		if not armsData[3] then
			allAmount = amount == -1 and player:getInventory():getItemAmount(item)
		else
			allAmount = amount == -1 and getPedTotalAmmo(player, getSlotFromWeapon ( armsData[3]))
		end

		if forceSpawn
		or (armsData[3] and (getPedWeapon(player, getSlotFromWeapon ( armsData[3])) == armsData[3]) and ((amount > 0 and getPedTotalAmmo(player, getSlotFromWeapon ( armsData[3])) >= amount) or amount==-1))
		or (amount > 0 and player:getInventory():removeItem(InventoryManager:getSingleton():getItemId(item), amount))
		or (amount==-1 and self:removeAllEquipment(player, item, allAmount)) then
			if not self.m_Equipments[item] then
				self.m_Equipments[item] = 0
			end
			if amount > 0 then
				self.m_Equipments[item] = self.m_Equipments[item] + amount
				if armsData[3] then
					if not forceSpawn and not takeWeapon(player, armsData[3], amount) then
						self.m_Equipments[item] = self.m_Equipments[item] - amount -- prevent bug-abuse
					end
				end
			else
				self.m_Equipments[item] = self.m_Equipments[item] + allAmount
				amount = allAmount
				if armsData[3] then
					if not forceSpawn and not takeWeapon(player, armsData[3]) then
						self.m_Equipments[item] = self.m_Equipments[item] - allAmount -- prevent bug-abuse
					end
				end
			end
			StatisticsLogger:getSingleton():addItemDepotLog(player, self.m_Id, item, -amount)
			self.m_Owner:addLog(player, "Itemlager", ("hat %s  %s in das Lager gelegt!"):format(amount, item))
			player:sendInfo(_("Du hast %d %s ins Depot gelegt!", player, amount, item))
			return
		else
			player:sendError(_("Du hast nicht genug %s!", player, item))
		end
	end
end

function Depot:removeAllEquipment(player, item, amount) -- this executes removeItem x amount since removeAllItem occasionally misses an item in the inventory
	for i = 1, amount do
		if not player:getInventory():removeItem(InventoryManager:getSingleton():getItemId(item), 1) then
			return false
		end
	end
	return true
end

function Depot:takeEquipment(player, item, amount)
	if not self:checkDistanceFromEquipment(player) then return end
	if not player:isFactionDuty() then return player:sendError(_("Du bist nicht im Fraktionsmodus!", player)) end
	if player:getFaction() then
		if self.m_Owner == player:getFaction() then
			local perms = player:getFaction():getEquipmentPermissions()
			if perms then
				if perms[item] then
					if perms[item] > player:getFaction():getPlayerRank(player) then
						return player:sendError(_("Keine Berechtigung erst ab Rang %i!", player, perms[item]))
					end
				end
			end
		end
	end
	if self.m_Equipments[item] then
 		local armsData = ArmsDealer:getSingleton():getItemData(item)
		if armsData[3] or (amount > 0 and self.m_Equipments[item] >= amount) or (amount==-1 and player:getInventory():getFreePlacesForItem(item) >= self.m_Equipments[item] ) then
			if amount > 0 then
				self.m_Equipments[item] = self.m_Equipments[item] - amount
				if not armsData[3] then
					if not player:getInventory():giveItem(InventoryManager:getSingleton():getItemId(item), amount) then
						self.m_Equipments[item] = self.m_Equipments[item] + amount
						return
					end
				else
					giveWeapon(player, armsData[3], amount)
				end
			elseif amount == -1 then
				amount = self.m_Equipments[item]
				self.m_Equipments[item] = 0
				if not armsData[3] then
					if not player:getInventory():giveItem(InventoryManager:getSingleton():getItemId(item), amount) then
						self.m_Equipments[item] = amount
						return
					end
				else
					giveWeapon(player, armsData[3], amount)
				end
			end
			player:sendInfo(_("Du hast %d %s aus dem Depot genommen!", player, amount, item))
			StatisticsLogger:getSingleton():addItemDepotLog(player, self.m_Id, item, -amount)
			self.m_Owner:addLog(player, "Itemlager", ("hat %s  %s aus dem Lager genommen!"):format(amount, item))
			return
		else
			player:sendError(_("Du hast nicht genug Platz in deinem Inventar!", player))
		end
	end
end

function Depot:checkDistanceFromEquipment(player)
	if player and isElement(player) and player.m_LastEquipmentDepot and isElement(player.m_LastEquipmentDepot)
	and (player.m_LastEquipmentDepot:getInterior() == player:getInterior())
	and (player.m_LastEquipmentDepot:getDimension() == player:getDimension()) then
		return (player:getPosition() - player.m_LastEquipmentDepot:getPosition()):getLength() < 8 or player:sendError("Zu weit entfernt!")
	end
	return false
end
