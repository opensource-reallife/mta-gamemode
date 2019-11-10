-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/InventoryManager.lua
-- *  PURPOSE:     InventoryManager Class
-- *
-- ****************************************************************************
InventoryManagerOld = inherit(Singleton)

function InventoryManagerOld:constructor()

	self.m_Slots={
		["Items"] = 21,
		["Objekte"] = 5,
		["Essen"] = 6,
		["Drogen"] = 7,
	}

	self.m_ItemData = {}
	self.m_ItemData = self:loadItems()
	self.Map = {}

	addRemoteEvents{"onPlayerItemUseServer", "onPlayerSecondaryItemUseServer", "throwItem", "refreshInventory",
	"requestTrade", "acceptItemTrade", "acceptWeaponTrade", "declineTrade"}

	addEventHandler("onPlayerItemUseServer", root, bind(self.Event_onItemUse, self))
	addEventHandler("onPlayerSecondaryItemUseServer", root, bind(self.Event_onItemSecondaryUse, self))
	addEventHandler("throwItem", root, bind(self.Event_throwItem, self))
	addEventHandler("refreshInventory", root, bind(self.Event_refreshInventory, self))
	addEventHandler("requestTrade", root, bind(self.Event_requestTrade, self))
	addEventHandler("acceptItemTrade", root, bind(self.Event_acceptItemTrade, self))
	addEventHandler("acceptWeaponTrade", root, bind(self.Event_acceptWeaponTrade, self))
	addEventHandler("declineTrade", root, bind(self.Event_declineTrade, self))

	WearableManager:new()
end

function InventoryManagerOld:destructor()

end

function InventoryManagerOld:getItemDataForItem(itemName)
	return self.m_ItemData[itemName]
end

function InventoryManagerOld:loadItems()
	local result = sql:queryFetch("SELECT * FROM ??_inventory_items_old", sql:getPrefix())
	local itemData = {}
	local itemName
	for i, row in ipairs(result) do
		itemName = row["Objektname"]
		itemData[itemName] = {}
		itemData[itemName]["Name"] = itemName
		itemData[itemName]["Info"] = utf8.escape(row["Info"])
		itemData[itemName]["Tasche"] = row["Tasche"]
		itemData[itemName]["Icon"] = row["Icon"]
		itemData[itemName]["Item_Max"] = tonumber(row["max_items"])
		itemData[itemName]["Wegwerf"] = tonumber(row["wegwerfen"])
		itemData[itemName]["Handel"] = tonumber(row["Handel"])
		itemData[itemName]["Stack_max"] = tonumber(row["stack_max"])
		itemData[itemName]["Verbraucht"] = tonumber(row["verbraucht"])
		itemData[itemName]["ModelID"] = tonumber(row["ModelID"])
		itemData[itemName]["MaxWear"] = tonumber(row["MaxWear"]) or nil
	end

	return itemData
end

function InventoryManagerOld:loadInventory(player)
	if not self.Map[player] then
		local instance = InventoryOld:new(player, self.m_Slots, self.m_ItemData, nil--[[ItemManager:getSingleton():getClassItems()]])
		self.Map[player] = instance
		return instance
	end
end

function InventoryManagerOld:deleteInventory(player)
	self.Map[player] = nil
end

function InventoryManagerOld:Event_onItemUse(itemid, bag, itemName, place, delete)
	client:getInventoryOld():useItem(itemid, bag, itemName, place, delete)
end

function InventoryManagerOld:Event_onItemSecondaryUse(itemid, bag, itemName, place)
	client:getInventoryOld():useItemSecondary(itemid, bag, itemName, place)
end

function InventoryManagerOld:Event_throwItem(item, bag, id, place, name)
	client:getInventoryOld():throwItem(item, bag, id, place, name)
end

function InventoryManagerOld:Event_refreshInventory()
	client:getInventoryOld():syncClient()
end

function InventoryManagerOld:Event_requestTrade(type, target, item, amount, money, value)
	if (client:getPosition() - target:getPosition()).length > 10 then
		client:sendError(_("Du bist zu weit von %s entfernt!", client, target.name))
		return false
	end

	if not money then money = 0 end
	local amount = math.abs(amount)
	local money = math.abs(money)

	if type == "Item" then
		client.sendRequest = {target = target, item = item, amount = amount, money = money, itemValue = value}
		target.receiveRequest = {target = client, item = item, amount = amount, money = money, itemValue = value}

		if client:getInventoryOld():getItemAmount(item) >= amount then
			local text = _("%s möchte dir %d %s schenken! Geschenk annehmen?", target, client.name, amount, item)
			if money and money > 0 then
				text = _("%s möchte dir %d %s für %d$ verkaufen! Handel annehmen?", target, client.name, amount, item, money)
			end
			ShortMessageQuestion:new(client, target, text, "acceptItemTrade", "declineTrade", client, target, item, amount, money)
		else
			client:sendError(_("Du hast nicht ausreichend %s!", client, item))
		end
	elseif type == "Weapon" then
		if client:hasTemporaryStorage() then client:sendError(_("Du kannst aktuell keine Waffen handeln!", client)) return end
		if target:hasTemporaryStorage() then client:sendError(_("Der Spieler kann aktuell keine Waffen handeln!", client)) return end

		if client:getFaction() and (not client:getFaction():isEvilFaction()) and client:isFactionDuty() then
			client:sendError(_("Du darfst im Dienst keine Waffen weitergeben!", client))
			return
		end

		if target:getFaction() and (not target:getFaction():isEvilFaction()) and target:isFactionDuty() then
			client:sendError(_("%s ist im Dienst und darf keine Waffen annehmen!", target, target:getName()))
			return
		end

		if target:getWeaponLevel() < MIN_WEAPON_LEVELS[item] then
			client:sendError(_("Das Waffenlevel von %s ist zu niedrig! (Benötigt: %i)", client, target.name, MIN_WEAPON_LEVELS[item]))
			target:sendError(_("Dein Waffenlevel ist zu niedrig! (Benötigt: %i)", target, MIN_WEAPON_LEVELS[item]))
			return
		end

		client.sendRequest = {target = target, item = item, amount = amount, money = money}
		target.receiveRequest = {target = client, item = item, amount = amount, money = money}

		local text = _("%s möchte dir eine/n %s mit %d Schuss schenken! Geschenk annehmen?", target, client.name, WEAPON_NAMES[item], amount)
		if money and money > 0 then
			text = _("%s möchte dir eine/n %s mit %d Schuss für %d$ verkaufen! Handel annehmen?", target, client.name, WEAPON_NAMES[item], amount, money)
		end
		ShortMessageQuestion:new(client, target, text, "acceptWeaponTrade", "declineTrade", client, target, item, amount, money)
	end
end

function InventoryManagerOld:validateTrading(player, target, playerClient)
	--if playerClient ~= target then return false end
	if not player.sendRequest or not target.receiveRequest then return false end
	if player.sendRequest.target ~= target or target.receiveRequest.target ~= player then return false end

	return true
end

function InventoryManagerOld:Event_declineTrade(player, target)
	if not self:validateTrading(player, target, client) then return end -- Todo: Report possible cheat attempt

	target:sendError(_("Du hast das Angebot von %s abglehent!", target, player:getName()))
	player:sendError(_("%s hat den Handel abglehent!", player, target:getName()))

	player.sendRequest = nil
	target.receiveRequest = nil
end

function InventoryManagerOld:Event_acceptItemTrade(player, target)
	if not self:validateTrading(player, target, client) then return end -- Todo: Report possible cheat attempt

	local item = player.sendRequest.item
	local amount = player.sendRequest.amount
	local money = player.sendRequest.money
	local value = player.sendRequest.itemValue

	if (player:getPosition() - target:getPosition()).length > 10 then
		player:sendError(_("Du bist zuweit von %s entfernt!", player, target.name))
		target:sendError(_("Du bist zuweit von %s entfernt!", target, player.name))
		return false
	end
	if (player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty()) then
		if (not player:getFaction():isStateFaction()) or (not player:getFaction():isFactionDuty()) then
			if ArmsDealer:getSingleton():getItemData(item) then
				player:sendError(_("Du kannst dieses Item im Dienst nicht an Zivilisten handeln!", player))
				return false
			end
		end
	end
	if player:getInventoryOld():getItemAmount(item) >= amount then
		if target:getMoney() >= money then
			if target:getInventoryOld():giveItem(item, amount, value) then
				player:sendInfo(_("%s hat den Handel akzeptiert!", player, target:getName()))
				target:sendInfo(_("Du hast das Angebot von %s akzeptiert und erhälst %d %s für %d$!", target, player:getName(), amount, item, money))
				if amount <= 10 then
					player:meChat(true, _("übergibt %s eine Tüte!", player, target:getName()))
				elseif amount <= 25 then
					player:meChat(true, _("übergibt %s ein Päckchen!", player, target:getName()))
				else
				player:meChat(true, _("übergibt %s ein Paket!", player, target:getName()))
				end
				player:getInventoryOld():removeItem(item, amount, value)
				WearableManager:getSingleton():removeWearable( player, item, value )
				target:transferMoney(player, money, "Handel", "Gameplay", "Trade")
				StatisticsLogger:getSingleton():itemTradeLogs( player, target, item, money, amount)

				if item == "Osterei" and money == 0 then
					target:giveAchievement(91) -- Verschenke ein Osterei
				end
			else
				target:sendError(_("Du hast nicht genug Platz für dieses Item!", player))
				player:sendError(_("%s hat nicht genug Platz für dieses Item!", player, target:getName()))
			end
		else
			player:sendError(_("%s hat nicht ausreichend Geld (%d$)!", player, target:getName(), money))
			target:sendError(_("Du hast nicht ausreichend Geld (%d$)!", target, money))
		end
	else
		target:sendError(_("%s hat nicht mehr ausreichend %s!", target, player:getName(), item))
		player:sendError(_("Du hast nicht mehr ausreichend %s!", player, item))
	end
end

function InventoryManagerOld:Event_acceptWeaponTrade(player, target)
	if not self:validateTrading(player, target) then return end -- Todo: Report possible cheat attempt

	local weaponId = player.sendRequest.item
	local amount = player.sendRequest.amount
	local money = player.sendRequest.money

	if (player:getPosition() - target:getPosition()).length > 10 then
		player:sendError(_("Du bist zuweit von %s entfernt!", player, target.name))
		target:sendError(_("Du bist zuweit von %s entfernt!", target, player.name))
		return false
	end

	if player:getFaction() and (not player:getFaction():isEvilFaction()) and player:isFactionDuty() then
		player:sendError(_("Du darfst im Dienst keine Waffen weitergeben!", player))
		return
	end
	if target:getFaction() and (not target:getFaction():isEvilFaction()) and target:isFactionDuty() then
		player:sendError(_("%s ist im Dienst und darf keine Waffen annehmen!", target, target:getName()))
		return
	end

	if player:hasTemporaryStorage() then player:sendError(_("Du kannst aktuell keine Waffen handeln!", player)) return end
	if target:hasTemporaryStorage() then player:sendError(_("Der Spieler kann aktuell keine Waffen handeln!", player)) return end

	local weaponSlot = getSlotFromWeapon(weaponId)
	if player:getWeapon(weaponSlot) > 0 then
		if player:getTotalAmmo(weaponSlot) >= amount then
			if target:getMoney() >= money then
				player:sendInfo(_("%s hat den Handel akzeptiert!", player, target:getName()))
				target:sendInfo(_("Du hast das Angebot von %s akzeptiert und erhälst eine/n %s mit %d Schuss für %d$!", target, player:getName(), WEAPON_NAMES[weaponId], amount, money))
				takeWeapon(player, weaponId)
				giveWeapon(target, weaponId, amount)
				target:transferMoney(player, money, "Waffen-Handel", "Gameplay", "WeaponTrade")
			else
				player:sendError(_("%s hat nicht ausreichend Geld (%d$)!", player, target:getName(), money))
				target:sendError(_("Du hast nicht ausreichend Geld (%d$)!", target, money))
			end
		else
			target:sendError(_("%s hat nicht mehr ausreichend Munition!", target, player:getName()))
			player:sendError(_("Du hast nicht mehr ausreichend Munition!", player))
		end
	else
		target:sendError(_("%s hat die Waffe nicht mehr!", target, player:getName()))
		player:sendError(_("Du hast die Waffe nicht mehr!", player))
	end
end