--WEB (PHP mtasdk)

function phpSDKGetPlayers()
	local name
	local players = {}
	local i = 1
	for index, player in pairs(getElementsByType("player")) do
		players[i]={}
		players[i]["pname"] = player:getName()
		i = i+1
	end
	return players
end

function phpSDKSendChatBox(messageType, target, message, r, g, b)
	if messageType == "admin" then
		Admin:getSingleton():sendMessage(message, r, g, b, type(target) == "number" and target or 1)
	elseif messageType == "player" then
		local target = getPlayerFromName(target)
		if isElement(target) then
			target:outputChat(message, r, g, b)
		end
	end
	return
end

function phpSDKSendMessage(targetType, targetId, message, options)
	local options = options or {}
	local color = {r = options.r or nil, g = options.g or nil, b = options.b or nil}
	local title = options.title or nil
	local offline = options.offline or false
	local messageType = options.messageType or "chat"
	local timeout = options.timeout or nil
	local minRank = options.minRank or nil
	local withPrefix = options.withPrefix or false

	if targetType == "admin" then
		if messageType == "shortMessage" then
			Admin:getSingleton():sendShortMessageWithRank(message, minRank or 1, nil, title, color, timeout)
		else
			Admin:getSingleton():sendMessage(message, color.r, color.g, color.b, minRank or 1)
		end

		local data = toJSON({status = "SUCCESS"}, true)
		return data:sub(2, #data-1)
	elseif targetType == "faction" then
		if targetId == "state" then
			if messageType == "shortMessage" then
				FactionState:getSingleton():sendShortMessageWithRank(message, minRank or 0, title, color, timeout)
			else
				FactionState:getSingleton():sendMessageWithRank(message, color.r, color.g, color.b, minRank or 0, withPrefix)
			end

			local data = toJSON({status = "SUCCESS"}, true)
			return data:sub(2, #data-1)
		else
			local faction = FactionManager.Map[targetId]

			if not faction then
				local data = toJSON({status = "FAILED"}, true)
				return data:sub(2, #data-1)
			end

			if messageType == "shortMessage" then
				faction:sendShortMessageWithRank(message, minRank or 0, title, color, timeout)
			else
				faction:sendMessageWithRank(message, color.r, color.g, color.b, minRank or 0, withPrefix)
			end

			local data = toJSON({status = "SUCCESS"}, true)
			return data:sub(2, #data-1)
		end
	elseif targetType == "company" then
		local company = CompanyManager.Map[targetId]

		if not company then
			local data = toJSON({status = "FAILED"}, true)
			return data:sub(2, #data-1)
		end

		if messageType == "shortMessage" then
			company:sendShortMessageWithRank(message, minRank or 0, title, color, timeout)
		else
			company:sendMessageWithRank(message, color.r, color.g, color.b, minRank or 0, withPrefix)
		end

		local data = toJSON({status = "SUCCESS"}, true)
		return data:sub(2, #data-1)
	elseif targetType == "group" then
		local group = GroupManager.Map[targetId]

		if not group then
			local data = toJSON({status = "FAILED"}, true)
			return data:sub(2, #data-1)
		end

		if messageType == "shortMessage" then
			group:sendShortMessageWithRank(message, minRank or 0, title, color, timeout)
		else
			group:sendMessageWithRank(message, color.r, color.g, color.b, minRank or 0, withPrefix)
		end

		local data = toJSON({status = "SUCCESS"}, true)
		return data:sub(2, #data-1)
	elseif targetType == "player" then
		local target, isOffline = DatabasePlayer.get(targetId)
		if target then
			if isOffline then
				local data = toJSON({status = "SUCCESS", online = false}, true)
				if offline then
					target:addOfflineMessage(message, 1)
				else
					data = toJSON({status = "FAILED", online = false}, true)
				end

				target.m_DoNotSave = true
				delete(target)

				return data:sub(2, #data-1)
			else
				if messageType == "infoBox" then
					target:sendInfo(message, timeout, title)
				elseif messageType == "successBox" then
					target:sendSuccess(message, timeout, title)
				elseif messageType == "warningBox" then
					target:sendWarning(message, timeout, title)
				elseif messageType == "errorBox" then
					target:sendError(message, timeout, title)
				elseif messageType == "shortMessage" then
					target:sendShortMessage(message, title, color, timeout)
				else
					target:sendMessage(message, color.r, color.g, color.b, true)
				end
				local data = toJSON({status = "SUCCESS", online = true}, true)
				return data:sub(2, #data-1)
			end
		end
	end
	return
end

function phpSDKLoadCharacterInfo(targetName) -- Cause of Migrator
	local target = getPlayerFromName(targetName)
	if isElement(target) then
		target:loadMigratorData()
	end
end

function phpSDKSendActivationMailCallback(answer)
	outputChatBox("phpSDKSendActivationMailCallback: "..answer)
end

function phpSDKSendActivationMail(userID, username)
	callRemote(INGAME_WEB_PATH .. "/ingame/boardActivation.php", phpSDKSendActivationMailCallback, userID, username)
end

local function phpSDKPlayerActivity(player)
	local name = function(lobby, field) local n = lobby and lobby[field] return n and n ~= "" and (": " .. tostring(n)) or "" end
	if player.deathmatchLobby then return "DM-Halle" .. name(player.deathmatchLobby, "m_Name") end
	if player.Minigame then return ({SniperGame = "Snipermode", ZombieSurvival = "Zombie Survival"})[player.Minigame.Type] or "Minispiel" end
	if player.colorCarsLobby then return "Color Cars" .. name(player.colorCarsLobby, "m_LobbyName") end
	if player.raceLobby then return "Destruction Derby" .. name(player.raceLobby, "m_LobbyName") end
	if Kart and Kart:isInstantiated() and Kart.ms_Instance.m_Players and Kart.ms_Instance.m_Players[player] then return "Kartbahn" end
	if player.bInWare then return "Ware-Event" end
	if player.skribbleLobby then return "Skribble" end
	if player.CinemaLobby then return "Kino" end
	return nil
end
function phpSDKSendOnlinePlayers()
	local players = {}
	local i = 1

	for index, player in pairs(getElementsByType("player")) do
		if player.isActive and player:isActive() then
			players[i]= {
				["Name"] = player:getName(),
				["Id"] = player:getId() or 0,
				["Faction"] = player:getFaction() and player:getFaction():getId() or 0,
				["Company"] = player:getCompany() and player:getCompany():getId() or 0,
				["GroupId"] = player:getGroup() and player:getGroup():getId() or 0,
				["PlayTime"] = player:getPlayTime() or 0,
				["AFK"] = player.m_isAFK and true or false,
				["Activity"] = phpSDKPlayerActivity(player),
			}
			i = i+1
		end
	end
	return players
end

function phpSDKGetPlayerLive(playerId)
	local player = Player.getFromId(tonumber(playerId))
	if not player or not isElement(player) or not (player.isActive and player:isActive()) then
		return {online = false}
	end

	local weapons = {}
	for slot = 0, 12 do
		local weapon = getPedWeapon(player, slot)
		if weapon and weapon > 0 then
			weapons[#weapons + 1] = {weapon, getPedTotalAmmo(player, slot)}
		end
	end

	local x, y, z = getElementPosition(player)
	local vehicle = getPedOccupiedVehicle(player)
	local bank = player:getBankAccount()
	return {
		online = true,
		weapons = weapons,
		money = player:getMoney() or 0,
		points = player:getPoints() or 0,
		bank = bank and bank:getMoney() or nil,
		gunBox = player.m_GunBox or {},
		health = math.floor(getElementHealth(player)),
		armor = math.floor(getPedArmor(player)),
		wanteds = player:getWanteds() or 0,
		zone = getZoneName(x, y, z),
		city = getZoneName(x, y, z, true),
		posX = math.floor(x * 10) / 10,
		posY = math.floor(y * 10) / 10,
		rot = math.floor((vehicle and select(3, getElementRotation(vehicle)) or select(3, getElementRotation(player))) or 0),
		speed = vehicle and math.floor(Vector3(getElementVelocity(vehicle)):getLength() * 180) or 0,
		weapon = getPedWeapon(player) or 0,
		ammo = getPedTotalAmmo(player) or 0,
		afk = player.m_isAFK and true or false,
		dead = isPedDead(player) and true or false,
		interior = getElementInterior(player),
		dimension = getElementDimension(player),
		vehicle = vehicle and getElementModel(vehicle) or nil,
		playTime = player:getPlayTime(),
		paNote = player:getPaNote() or 0,
		points = player.m_Points or 0,
		skin = getElementModel(player),
		weaponLevel = player:getWeaponLevel() or 0,
		vehicleLevel = player:getVehicleLevel() or 0,
		skinLevel = player:getSkinLevel() or 0,
		jobLevel = player:getJobLevel() or 0,
		fishingLevel = player:getFishingLevel() or 0,
		drivingLicense = player.m_HasDrivingLicense and true or false,
		bikeLicense = player.m_HasBikeLicense and true or false,
		truckLicense = player.m_HasTruckLicense and true or false,
		pilotsLicense = player.m_HasPilotsLicense and true or false,
	}
end

function phpSDKEditPlayer(adminId, targetId, action, data)
	local result = function(status, err) return {status = status, error = err} end
	targetId = tonumber(targetId)
	data = type(data) == "table" and data or {}
	local adminName = Account.getNameFromId(adminId) or "Control Panel"
	local player = Player.getFromId(targetId)
	local online = player and isElement(player) and player.isActive and player:isActive()

	if action == "stats" then
		if not online then return result("ERROR", "TARGET_OFFLINE") end
		if data.money then player:setMoney(tonumber(data.money)) end
		if data.bank and player:getBankAccount() then player:getBankAccount():setMoney(tonumber(data.bank), "ControlPanel", true) end
		if data.playTime then
			player:setPlayTime(tonumber(data.playTime) - (player:getPlayTime() - player.m_LastPlayTime))
		end
		if data.paNote then player:setPaNote(tonumber(data.paNote)) end
		if data.weaponLevel then player:setWeaponLevel(tonumber(data.weaponLevel)) end
		if data.vehicleLevel then player:setVehicleLevel(tonumber(data.vehicleLevel)) end
		if data.skinLevel then player:setSkinLevel(tonumber(data.skinLevel)) end
		if data.jobLevel then player:setJobLevel(tonumber(data.jobLevel)) end
		if data.fishingLevel then player:setFishingLevel(tonumber(data.fishingLevel)) end
		if data.drivingLicense ~= nil then player.m_HasDrivingLicense = data.drivingLicense == true or data.drivingLicense == 1 end
		if data.bikeLicense ~= nil then player.m_HasBikeLicense = data.bikeLicense == true or data.bikeLicense == 1 end
		if data.truckLicense ~= nil then player.m_HasTruckLicense = data.truckLicense == true or data.truckLicense == 1 end
		if data.pilotsLicense ~= nil then player:setHasPilotsLicense(data.pilotsLicense == true or data.pilotsLicense == 1) end
		if data.points then player:setPoints(tonumber(data.points)) end
		if data.credits and player.m_Premium then player.m_Premium:refresh() end
		player:save()
		return result("SUCCESS")

	elseif action == "weapons" then
		if not online then return result("ERROR", "TARGET_OFFLINE") end
		if data.give then
			if not giveWeapon(player, tonumber(data.give[1]), tonumber(data.give[2]) or 0, false) then
				return result("ERROR", "GIVE_FAILED")
			end
			return result("SUCCESS")
		end
		if data.all then
			takeAllWeapons(player)
		else
			for _, weapon in ipairs(data.weapons or {}) do
				takeWeapon(player, tonumber(weapon))
			end
		end
		return result("SUCCESS")

	elseif action == "inventory" then
		if not online then return result("ERROR", "TARGET_OFFLINE") end
		local inv = player:getInventory()
		local item, amount = tostring(data.item or ""), math.floor(tonumber(data.amount) or 0)
		if not inv or not inv.m_ItemData[item] or amount == 0 then return result("ERROR", "UNKNOWN_ITEM") end
		if amount > 0 then
			if inv:getItemAmount(item) + amount > inv.m_ItemData[item]["Item_Max"] then return result("ERROR", "ITEM_MAX") end
			if inv:giveItem(item, amount) == false then return result("ERROR", "INVENTORY_FULL") end
		else
			if inv:getItemAmount(item) < -amount then return result("ERROR", "NOT_ENOUGH") end
			inv:removeItem(item, -amount)
		end
		return result("SUCCESS")

	elseif action == "gunbox" then
		if not online then return result("ERROR", "TARGET_OFFLINE") end
		local slot = math.floor(tonumber(data.slot) or 0)
		if slot < 1 or slot > 6 then return result("ERROR", "UNKNOWN_SLOT") end
		local weaponId, ammo = math.floor(tonumber(data.weapon) or 0), math.max(0, math.floor(tonumber(data.amount) or 0))
		player.m_GunBox = type(player.m_GunBox) == "table" and player.m_GunBox or {}
		player.m_GunBox[tostring(slot)] = {WeaponId = weaponId, Amount = weaponId > 0 and ammo or 0, VIP = slot >= 4}
		player:triggerEvent("receiveGunBoxData", player.m_GunBox)
		player:save()
		return result("SUCCESS")

	elseif action == "vehicle" or action == "trunk" then
		local vehicle
		local list = VehicleManager:getSingleton():getPlayerVehicles(targetId)
		if tonumber(data.ownerType) == 2 or tonumber(data.ownerType) == 3 then
			local org = tonumber(data.ownerType) == 2 and FactionManager:getSingleton():getFromId(targetId) or CompanyManager:getSingleton():getFromId(targetId)
			list = org and org.m_Vehicles or {}
		elseif tonumber(data.ownerType) == 4 then
			list = VehicleManager:getSingleton():getGroupVehicles(targetId)
		end
		for _, v in pairs(list) do
			if v.m_Id == tonumber(data.vehicleId) then vehicle = v end
		end
		if not vehicle or not isElement(vehicle) then return result("ERROR", "NOT_LOADED") end

		if action == "vehicle" then
			if data.model and tonumber(data.model) ~= vehicle:getModel() then
				vehicle:setModel(tonumber(data.model))
			end
			if data.color1 and data.color2 then
				vehicle:setColor(data.color1[1], data.color1[2], data.color1[3], data.color2[1], data.color2[2], data.color2[3])
				vehicle.m_Tunings:saveColors()
			end
			if data.fuel then vehicle:setFuel(tonumber(data.fuel)) end
			if data.mileage then vehicle:setMileage(tonumber(data.mileage)) end
			vehicle:saveAdminChanges()
			vehicle:save()
			return result("SUCCESS")
		end

		local trunk = vehicle.m_Trunk
		if not trunk then return result("ERROR", "NO_TRUNK") end
		local slot = tonumber(data.slot)
		if data.op == "removeItem" and trunk.m_ItemSlot[slot] then
			trunk.m_ItemSlot[slot] = {Item = "none", Amount = 0, Value = ""}
		elseif data.op == "removeWeapon" and trunk.m_WeaponSlot[slot] then
			trunk.m_WeaponSlot[slot] = {WeaponId = 0, Amount = 0}
		elseif data.op == "addItem" then
			local free
			for index, s in ipairs(trunk.m_ItemSlot) do
				if not free and (not s.Item or s.Item == "none") then free = index end
			end
			if not free then return result("ERROR", "TRUNK_FULL") end
			trunk.m_ItemSlot[free] = {Item = data.item, Amount = tonumber(data.amount), Value = data.value or ""}
		elseif data.op == "addWeapon" then
			local free
			for index, s in ipairs(trunk.m_WeaponSlot) do
				if not free and (tonumber(s.WeaponId) or 0) == 0 then free = index end
			end
			if not free then return result("ERROR", "TRUNK_FULL") end
			trunk.m_WeaponSlot[free] = {WeaponId = tonumber(data.weapon), Amount = tonumber(data.amount) or 0}
		else
			return result("ERROR", "UNKNOWN_ACTION")
		end
		trunk:save()
		local isWeapon = data.op == "removeWeapon" or data.op == "addWeapon"
		StatisticsLogger:getSingleton():addVehicleTrunkLog(trunk.m_Id, adminId, (data.op == "addItem" or data.op == "addWeapon") and "insert" or "take", isWeapon and "weapon" or "item", data.item or data.weapon or "ControlPanel", tonumber(data.amount) or 0, slot or 0)
		return result("SUCCESS")
	end
	return result("ERROR", "UNKNOWN_ACTION")
end

function phpSDKOrgLoan(adminId, groupType, groupId, action, data)
	local result = function(status, err) return {status = status, error = err} end
	local instance = groupType == "faction" and FactionManager:getSingleton():getFromId(tonumber(groupId)) or groupType == "company" and CompanyManager:getSingleton():getFromId(tonumber(groupId))
	if not instance then return result("ERROR", "UNKNOWN_GROUP") end
	data = type(data) == "table" and data or {}
	local category = groupType == "faction" and "Fraktion" or "Unternehmen"
	if action == "rank" then
		local rank, loan = tonumber(data.rank), math.floor(tonumber(data.loan) or -1)
		local max = (groupType == "faction" and FACTION_MAX_RANK_LOANS or COMPANY_MAX_RANK_LOANS)[rank]
		if not max then return result("ERROR", "UNKNOWN_RANK") end
		if loan < 0 or loan > max then return result("ERROR", "MAX_LOAN") end
		instance:setRankLoan(rank, loan)
		instance:save()
		instance:addLog(tonumber(adminId), category, ("hat das Gehalt für Rang %d auf %d$ gesetzt! (Control Panel)"):format(rank, loan))
		return result("SUCCESS")
	elseif action == "member" then
		local playerId = tonumber(data.playerId)
		if not instance:isPlayerMember(playerId) then return result("ERROR", "NOT_A_MEMBER") end
		local enabled = data.enabled == true or data.enabled == 1
		instance:setPlayerLoanEnabled(playerId, enabled and 1 or 0)
		instance:addLog(tonumber(adminId), category, ("hat das Gehalt von %s %s! (Control Panel)"):format(Account.getNameFromId(playerId) or playerId, enabled and "aktiviert" or "deaktiviert"))
		return result("SUCCESS")
	elseif action == "split" and groupType == "faction" then
		local playerId = tonumber(data.playerId)
		if not instance:isPlayerMember(playerId) then return result("ERROR", "NOT_A_MEMBER") end
		local enabled = data.enabled == true or data.enabled == 1
		instance:setPlayerActionMoneySplitEnabled(playerId, enabled and 1 or 0)
		instance:addLog(tonumber(adminId), category, ("hat die Aktionsbeteiligung von Spieler %s %s! (Control Panel)"):format(Account.getNameFromId(playerId) or playerId, enabled and "aktiviert" or "deaktiviert"))
		return result("SUCCESS")
	end
	return result("ERROR", "UNKNOWN_ACTION")
end

local function phpSDKBankAccount(kind, id)
	id = tonumber(id)
	if kind == "player" then
		local player = Player.getFromId(id)
		if player and isElement(player) and player:getBankAccount() then return player:getBankAccount(), player end
		return BankAccount.loadByOwner(id, BankAccountTypes.Player)
	elseif kind == "faction" then
		local faction = FactionManager:getSingleton():getFromId(id)
		return faction and faction.m_BankAccount
	elseif kind == "company" then
		local company = CompanyManager:getSingleton():getFromId(id)
		return company and company.m_BankAccount
	elseif kind == "group" then
		local group = GroupManager.Map[id]
		return group and group.m_BankAccount or BankAccount.loadByOwner(id, BankAccountTypes.Group)
	elseif kind == "admin" then
		return Admin:getSingleton().m_BankAccount
	elseif kind == "topup" then
		return BankServer.get("admin.topup")
	end
end

function phpSDKGetBalances(accounts)
	local balances = {}
	for _, a in pairs(type(accounts) == "table" and accounts or {}) do
		local kind, id = a[1], tonumber(a[2])
		local account
		if kind == "player" then
			local player = Player.getFromId(id)
			account = player and isElement(player) and player:getBankAccount() or (id and BankAccount.loadByOwner(id, BankAccountTypes.Player))
		elseif kind == "group" then
			local group = GroupManager.Map[id]
			account = group and group.m_BankAccount
		elseif kind == "faction" or kind == "company" or kind == "admin" then
			account = phpSDKBankAccount(kind, id)
		end
		if account then balances[("%s:%s"):format(kind, id or 0)] = account:getMoney() end
	end
	return {status = "SUCCESS", balances = balances}
end

function phpSDKForceTransfer(adminId, fromKind, fromId, toKind, toId, amount, reason)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then return {status = "ERROR", error = "INVALID_AMOUNT"} end
	local from, fromPlayer = phpSDKBankAccount(fromKind, fromId)
	local to, toPlayer = phpSDKBankAccount(toKind, toId)
	if not from or not to then return {status = "ERROR", error = "UNKNOWN_ACCOUNT"} end
	if from == to then return {status = "ERROR", error = "SAME_ACCOUNT"} end
	local adminName = Account.getNameFromId(adminId) or "Control Panel"
	local text = ("%s (Control Panel, %s)"):format(reason ~= "" and reason or "Transaktion", adminName)
	if not from:transferMoney(to, amount, text, "Admin", "Transaktion", {allowNegative = true}) then
		return {status = "ERROR", error = "TRANSFER_FAILED"}
	end
	if fromPlayer and isElement(fromPlayer) then fromPlayer:sendShortMessage(("%s hat %s$ von deinem Konto abgebucht: %s"):format(adminName, amount, reason), "Administration") end
	if toPlayer and isElement(toPlayer) then toPlayer:sendShortMessage(("%s hat dir %s$ auf dein Konto überwiesen: %s"):format(adminName, amount, reason), "Administration") end
	return {status = "SUCCESS", from = from:getMoney(), to = to:getMoney()}
end

function phpSDKPremiumGiven(adminId, playerId, kind, text)
	local player = Player.getFromId(tonumber(playerId))
	if not player or not isElement(player) or not (player.isActive and player:isActive()) then
		return {status = "ERROR", error = "TARGET_OFFLINE"}
	end
	if kind == "vip" and player.m_Premium then
		player.m_Premium:refresh()
	end
	player:sendSuccess(text)
	return {status = "SUCCESS"}
end

function phpSDKMarketFee(playerId, amount, companyId, share, reason)
	local result = function(status, err, money) return {status = status, error = err, money = money} end
	amount, share = math.floor(tonumber(amount) or 0), math.floor(tonumber(share) or 0)
	local player = Player.getFromId(tonumber(playerId))
	local account = player and isElement(player) and player:getBankAccount() or BankAccount.loadByOwner(tonumber(playerId), BankAccountTypes.Player)
	if not account then return result("ERROR", "NO_ACCOUNT") end
	local company = CompanyManager:getSingleton():getFromId(tonumber(companyId))
	if not company then return result("ERROR", "UNKNOWN_COMPANY") end
	if amount < 1 or share < 0 or share > amount then return result("ERROR", "INVALID_AMOUNT") end
	if account:getMoney() < amount then return result("ERROR", "NOT_ENOUGH_MONEY", account:getMoney()) end

	if share > 0 then
		account:transferMoney({company, true}, share, reason, "Marktplatz", "Anzeige")
	end
	if amount - share > 0 then
		account:__takeMoney(amount - share, reason, true)
		StatisticsLogger:getSingleton():addMoneyLogNew(account.m_OwnerId, account.m_OwnerType, account.m_Id, 0, BankAccountTypes.Server, 0, amount - share, reason, "Marktplatz", "Gebühr")
	end
	if player and isElement(player) then
		player:sendShortMessage(("Für deine Marktplatz-Anzeige wurden %s$ von deinem Bankkonto abgebucht."):format(amount), "Marktplatz")
	end
	return result("SUCCESS", nil, account:getMoney())
end

function phpSDKGiveQRAchievement(playerId)
	Async.create(
		function()
			local player, isOffline = DatabasePlayer.get(playerId)
			if isOffline then
				player:load()
				delete(player)
				return false
			else
				player:giveAchievement(78)
				return true
			end
		end
	)()
end

function phpSDKKickPlayer(adminId, targetId, reason)
	local target = DatabasePlayer.Map[targetId]

	if not isElement(target) or target:getType() ~= "player" then
		local data = toJSON({status = "ERROR", error = "TARGET_OFFLINE"}, true)
		outputServerLog(data:sub(2, #data-1))
		return data:sub(2, #data-1)
	end

	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		outputServerLog(data:sub(2, #data-1))
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	local format = {adminName, targetName, reason}
	Admin:getSingleton():sendShortMessage("%s hat %s gekickt! Grund: %s", format)
	outputChatBox("Der Spieler "..targetName.." wurde von "..adminName.." gekickt!",root, 200, 0, 0)
	outputChatBox("Grund: "..reason,root, 200, 0, 0)

	if isElement(admin) then
		kickPlayer(target, admin, reason)
	else
		kickPlayer(target, reason)
	end

	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKPrisonPlayer(adminId, targetId, duration, reason)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	if not duration then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local duration = tonumber(duration)

	if not duration or duration <= 0 then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_INVALID"}, true)
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	if tCreated then
		target:load(true)
	end

	local format = {adminName, targetName, duration, reason}
	Admin:getSingleton():sendShortMessage("%s hat %s für %d Minuten ins Prison gesteckt! Grund: %s", format)
	Admin:getSingleton():addPunishLog(adminId, targetId, "prisonCP", reason, duration * 60)
	outputChatBox(_("%s hat %s für %s Minuten ins Prison gesteckt!!", nil, adminName, targetName, duration), root, 200, 0, 0)
	outputChatBox(_("Grund: %s", nil, reason), root, 200, 0, 0)
	target:setPrison(duration * 60)

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKUnprisonPlayer(adminId, targetId, reason)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	if tCreated then
		target:load(true)
	end

	local prisonTime = target:getRemainingPrisonTime()

	if prisonTime == 0 then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "PLAYER_NOT_IN_PRISON"}, true)
		return data:sub(2, #data-1)
	end

	local format = {adminName, targetName, reason}
	Admin:getSingleton():sendShortMessage("%s hat %s aus dem Prison gelassen! Grund: %s", format)
	Admin:getSingleton():addPunishLog(adminId, targetId, "unPrisonCP", reason, 0)

	if tCreated then
		target:setPrison(0, true)
	else
		target:endPrison()
	end

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKBanPlayer(adminId, targetId, duration, reason)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	if not duration then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local duration = tonumber(duration)

	if not duration or duration < 0 then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_INVALID"}, true)
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	if duration == 0 then -- perma
		local format = {adminName, targetName, reason}
		Admin:getSingleton():sendShortMessage("%s hat %s permanent gebannt! Grund: %s", format)
		Admin:getSingleton():addPunishLog(adminId, targetId, "permabanCP", reason, 0)
		outputChatBox(_("Der Spieler %s  wurde von %s gebannt!", nil, targetName, adminName), root, 200, 0, 0)
		outputChatBox(_("Grund: %s", nil, reason), root, 200, 0, 0)
		Ban.addBan(targetId, adminId, reason, 0, adminName)
	else -- time
		local format = {adminName, targetName, duration, reason}
		Admin:getSingleton():sendShortMessage("%s hat %s für %d Stunden gebannt! Grund: %s", format)
		Admin:getSingleton():addPunishLog(adminId, targetId, "timebanCP", reason, duration * 60 * 60)
		outputChatBox(_("Der Spieler %s  wurde von %s für %d Stunden gebannt!", nil, targetName, adminName, duration), root, 200, 0, 0)
		outputChatBox(_("Grund: %s", nil, reason), root, 200, 0, 0)
		Ban.addBan(targetId, adminId, reason, duration * 60 * 60, adminName)
	end

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKUnbanPlayer(adminId, targetId, reason)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	local format = {adminName, targetName}
	Admin:getSingleton():sendShortMessage("%s hat %s offline entbannt!", format)
	Admin:getSingleton():addPunishLog(adminId, targetId, "unbanCP", reason, 0)
	sql:queryExec("DELETE FROM ??_bans WHERE serial = ? OR player_id = ?;", sql:getPrefix(), Account.getLastSerialFromId(targetId), targetId)
	outputChatBox(_("Der Spieler %s wurde von %s entbannt!", nil, targetName, adminName), root, 200, 0, 0)

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKAddWarn(adminId, targetId, duration, reason)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	if not duration then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local duration = tonumber(duration)

	if not duration or duration < 0 then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "DURATION_INVALID"}, true)
		return data:sub(2, #data-1)
	end

	if not reason or reason == "" then
		if tCreated then delete(target) end
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "REASON_MISSING"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	Warn.addWarn(targetId, adminId, reason, duration*60*60*24)
	Admin:getSingleton():addPunishLog(adminId, targetId, "warnCP", reason, duration*60*60*24)
	local format = {adminName, targetName, duration, reason}
	Admin:getSingleton():sendShortMessage("%s hat %s verwarnt! Ablauf in %d Tagen, Grund: %s", format)

	if target and isElement(target) then
		target:sendMessage(_("Du wurdest von %s verwarnt! Ablauf in %s Tagen, Grund: %s", target, adminName, duration, reason), 255, 0, 0)
	end

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

function phpSDKRemoveWarn(adminId, targetId, warnId)
	local admin, aCreated = DatabasePlayer.get(adminId)
	if not admin then
		local data = toJSON({status = "ERROR", error = "UNKNOWN_ADMIN_ID"}, true)
		return data:sub(2, #data-1)
	end

	local target, tCreated = DatabasePlayer.get(targetId)
	if not target then
		if aCreated then delete(admin) end
		local data = toJSON({status = "ERROR", error = "UNKNOWN_PLAYER_ID"}, true)
		return data:sub(2, #data-1)
	end

	local adminName = Account.getNameFromId(adminId)
	local targetName = Account.getNameFromId(targetId)

	Warn.removeWarn(targetId, warnId)
	Admin:getSingleton():addPunishLog(adminId, targetId, "removeWarnCP", nil, 0)
	local format = {adminName, targetName}
	Admin:getSingleton():sendShortMessage("%s hat einen Warn von %s entfernt!", format)

	if tCreated then delete(target) end
	if aCreated then delete(admin) end

	local data = toJSON({status = "SUCCESS"}, true)
	return data:sub(2, #data-1)
end

local function phpSDKHistoryLeave(playerId, uninviterId, elementId, elementType, rank, internal, external)
	local open = sql:queryFetchSingle("SELECT Id FROM ??_player_history WHERE UserId = ? AND ElementId = ? AND ElementType = ? AND LeaveDate IS NULL", sql:getPrefix(), playerId, elementId, elementType)
	if open then
		HistoryPlayer:getSingleton():addLeaveEntry(playerId, uninviterId, elementId, elementType, rank, internal or "", external or "")
	else
		sql:queryExec("INSERT INTO ??_player_history (UserId, InviterId, UninviterId, ElementId, ElementType, UninviteRank, HighestRank, InternalReason, ExternalReason, JoinDate, LeaveDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())",
			sql:getPrefix(), playerId, uninviterId, uninviterId, elementId, elementType, rank, rank, internal or "", external or "")
	end
end

function phpSDKChangeMember(adminId, targetId, groupType, groupId, action, reasonExternal, reasonInternal)
	local result = function(status, err, rank)
		local data = toJSON({status = status, error = err, rank = rank}, true)
		return data:sub(2, #data-1)
	end

	local instance
	if groupType == "faction" then
		instance = FactionManager:getSingleton():getFromId(groupId)
	elseif groupType == "company" then
		instance = CompanyManager:getSingleton():getFromId(groupId)
	end
	if not instance then return result("ERROR", "UNKNOWN_GROUP") end
	if not instance:isPlayerMember(targetId) then return result("ERROR", "NOT_A_MEMBER") end

	local target = Player.getFromId(targetId)
	if target and not isElement(target) then target = nil end

	local adminName = Account.getNameFromId(adminId) or "Control Panel"
	local targetName = Account.getNameFromId(targetId)
	local leaderRank = groupType == "faction" and FactionRank.Leader or CompanyRank.Leader
	local managerRank = groupType == "faction" and FactionRank.Manager or CompanyRank.Manager
	local category = groupType == "faction" and "Fraktion" or "Unternehmen"
	local rank = instance:getPlayerRank(targetId)

	if action == "uninvite" then
		if not reasonExternal or reasonExternal == "" then return result("ERROR", "REASON_MISSING") end
		phpSDKHistoryLeave(targetId, adminId, instance:getId(), groupType, rank, reasonInternal or "", reasonExternal)
		instance:addLog(adminId, category, ("hat den Spieler %s über das ControlPanel aus %s geworfen!"):format(targetName, groupType == "faction" and "der Fraktion" or "dem Unternehmen"))
		instance:removePlayer(targetId)
		if target then target:sendShortMessage(("Entlassen von %s über das ControlPanel. Grund: %s"):format(adminName, reasonExternal), instance:getName()) end
		Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(targetId)
		return result("SUCCESS", nil, rank)
	end

	if action ~= "up" and action ~= "down" then return result("ERROR", "UNKNOWN_ACTION") end
	local newRank = rank + (action == "up" and 1 or -1)
	if newRank < 0 or newRank > leaderRank then return result("ERROR", "RANK_OUT_OF_RANGE") end
	if action == "up" and newRank >= managerRank and LeaderCheck:getSingleton():hasPlayerLeaderBan(targetId) then
		return result("ERROR", "LEADER_BAN")
	end

	instance:setPlayerRank(targetId, newRank)
	if action == "up" then
		HistoryPlayer:getSingleton():setHighestRank(targetId, newRank, instance:getId(), groupType)
	end
	instance:addLog(adminId, category, ("hat den Spieler %s über das ControlPanel auf Rang %d %s!"):format(targetName, newRank, action == "up" and "befördert" or "degradiert"))

	local perms = instance.m_PlayerPermissions and instance.m_PlayerPermissions[targetId]
	if perms then
		for name in pairs(perms) do
			local minRank = PERMISSIONS_INFO[name] and PERMISSIONS_INFO[name][2] and PERMISSIONS_INFO[name][2][groupType]
			if (action == "down" and minRank and newRank < minRank) or (action == "up" and newRank == leaderRank) then
				perms[name] = nil
			end
		end
		if instance.savePlayerPermissions then instance:savePlayerPermissions(targetId) end
		if target then PermissionsManager:getSingleton():syncPermissions(target, groupType) end
	end

	if not target then
		Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(targetId)
		return result("SUCCESS", nil, newRank)
	end
	if action == "up" then
		target:sendShortMessage(_("Du wurdest von %s auf Rang %d befördert!", target, adminName, newRank), instance:getName())
	else
		target:sendShortMessage(_("Du wurdest von %s auf Rang %d degradiert!", target, adminName, newRank), instance:getName())
	end
	if reasonExternal and reasonExternal ~= "" then
		target:sendShortMessage(reasonExternal, instance:getName())
	end
	target:setPublicSync(groupType == "faction" and "FactionRank" or "CompanyRank", newRank)
	Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(targetId)
	return result("SUCCESS", nil, newRank)
end

local cpCrosshairApi = get("cpCrosshairApi") or CP_WEB_PATH .. "/api_crosshair.php"

local function sendCrosshairs(player, crosshairs)
	if type(crosshairs) ~= "table" then return end
	for _, kind in ipairs({"normal", "sniper"}) do
		local item = crosshairs[kind]
		if type(item) == "table" and item.url then
			fetchRemote(item.url,
				function(pixels, errorCode)
					if errorCode == 0 and isElement(player) then
						player:triggerLatentEvent("crosshairApply", kind, item.hash, pixels)
					end
				end
			)
		else
			player:triggerEvent("crosshairApply", kind)
		end
	end
end

function phpSDKSetCrosshair(userId, data, url)
	local api = type(url) == "string" and url:match("^https?://[^%s]+/api_crosshair%.php$")
	if api and api ~= cpCrosshairApi then
		cpCrosshairApi = api
		set("cpCrosshairApi", api)
	end
	local player = DatabasePlayer.Map[userId]

	if player and isElement(player) then
		sendCrosshairs(player, fromJSON(data))
		local data = toJSON({status = "SUCCESS"}, true)
		return data:sub(2, #data-1)
	else
		local data = toJSON({status = "ERROR", error = "PLAYER_IS_OFFLINE"}, true)
		return data:sub(2, #data-1)
	end
end

addEventHandler("characterInitialized", root,
	function()
		local player = source
		fetchRemote(cpCrosshairApi .. "?id=" .. player:getId(),
			function(data, errorCode)
				if errorCode == 0 and isElement(player) then
					sendCrosshairs(player, fromJSON(data))
				end
			end
		)
	end
)

local cpScreenshotUrls = {}

function phpSDKTakeScreenShot(userId, url, adminId)
	local player = DatabasePlayer.Map[userId]

	if player and isElement(player) then
		local tag = (md5(string.random(32) .. getTickCount() .. getRealTime().timestamp) .. md5(tostring(player) .. math.random()) .. md5(userId .. getTickCount() .. math.random()) .. md5(string.random(32))):lower()
		local status = player:takeScreenShot(1280, 720, "cp:" .. tag, 60, 1024 * 1024, 1000)
		if status then
			if tonumber(adminId) then
				sql:queryExec("INSERT INTO ??_account_screenshot (UserId, AdminId, Tag, Status, CreatedAt, UpdatedAt) VALUES (?, ?, ?, 'Processing', NOW(), NOW())", sql:getPrefix(), userId, tonumber(adminId), tag)
			end
			cpScreenshotUrls[tag] = type(url) == "string" and url:match("^https?://[^%s]+/api_screenshot%.php$") or CP_WEB_PATH .. "/api_screenshot.php"
			local data = toJSON({status = "SUCCESS", tag = tag}, true)
			return data:sub(2, #data-1)
		else
			local data = toJSON({status = "ERROR", error = "FAILED"}, true)
			return data:sub(2, #data-1)
		end
	else
		local data = toJSON({status = "ERROR", error = "PLAYER_IS_OFFLINE"}, true)
		return data:sub(2, #data-1)
	end
end

function phpSDKStartScreenCapture(userId, width, height, frameLimit, time, forceResample)
	local player = DatabasePlayer.Map[userId]

	if player and isElement(player) then
		local tag = string.random(128)
		local status = player:triggerEvent("onScreenCaptureStart", tag, width, height, frameLimit, time, forceResample)
		if status then
			local data = toJSON({status = "SUCCESS", tag = tag}, true)
			return data:sub(2, #data-1)
		else
			local data = toJSON({status = "ERROR", error = "FAILED"}, true)
			return data:sub(2, #data-1)
		end
	else
		local data = toJSON({status = "ERROR", error = "PLAYER_IS_OFFLINE"}, true)
		return data:sub(2, #data-1)
	end
end

function phpSDKStopScreenCapture(userId)
	local player = DatabasePlayer.Map[userId]

	if player and isElement(player) then
		local status = player:triggerEvent("onScreenCaptureStop")
		if status then
			local data = toJSON({status = "SUCCESS", tag = tag}, true)
			return data:sub(2, #data-1)
		else
			local data = toJSON({status = "ERROR", error = "FAILED"}, true)
			return data:sub(2, #data-1)
		end
	else
		local data = toJSON({status = "ERROR", error = "PLAYER_IS_OFFLINE"}, true)
		return data:sub(2, #data-1)
	end
end


local cpLive = {}

local function cpLiveStop(player)
	local live = cpLive[player]
	if not live then return false end
	if isTimer(live.timer) then killTimer(live.timer) end
	cpLive[player] = nil
	return true
end

local cpLiveSizes = {[800] = {450, 40}, [1024] = {576, 45}, [1280] = {720, 45}}

function phpSDKSpectateStart(userId, seconds, url, width)
	local player = DatabasePlayer.Map[tonumber(userId)]
	if not player or not isElement(player) then
		local data = toJSON({status = "ERROR", error = "PLAYER_IS_OFFLINE"}, true)
		return data:sub(2, #data-1)
	end
	cpLiveStop(player)
	local live = {tag = (md5(string.random(32) .. getTickCount() .. getRealTime().timestamp .. tostring(player)) .. md5(tostring({}) .. math.random() .. userId)):lower(), pending = 0, stopAt = getTickCount() + math.min(math.max(tonumber(seconds) or 60, 10), 180) * 1000}
	live.url = type(url) == "string" and url:match("^https?://[^%s]+/api_spectate%.php$") or CP_WEB_PATH .. "/api_spectate.php"
	live.width = cpLiveSizes[tonumber(width)] and tonumber(width) or 800
	live.timer = setTimer(function()
		if not isElement(player) or getTickCount() > live.stopAt then
			cpLiveStop(player)
			return
		end
		if live.pending < 3 then
			live.pending = live.pending + 1
			player:takeScreenShot(live.width, cpLiveSizes[live.width][1], "cplive:" .. live.tag, cpLiveSizes[live.width][2], 1024 * 1024, 1000)
		end
	end, 200, 0)
	cpLive[player] = live
	local data = toJSON({status = "SUCCESS", tag = live.tag}, true)
	return data:sub(2, #data-1)
end

function phpSDKSpectateStop(userId)
	local player = DatabasePlayer.Map[tonumber(userId)]
	local data = toJSON({status = (player and isElement(player) and cpLiveStop(player)) and "SUCCESS" or "ERROR"}, true)
	return data:sub(2, #data-1)
end

addEventHandler("onPlayerScreenShot", root, function(resource, status, pixels, timestamp, tag)
	if resource ~= getThisResource() or tag:sub(1, 7) ~= "cplive:" then return end
	local player = source
	local live = cpLive[player]
	if not live or live.tag ~= tag:sub(8, #tag) then return end
	live.pending = math.max(live.pending - 1, 0)
	fetchRemote(live.url, {
		method = "POST",
		formFields = {
			tag = live.tag,
			status = status == "ok" and "SUCCESS" or tostring(status):upper(),
			data = status == "ok" and pixels or ""
		}
	}, function(response)
		if response == "STOP" and cpLive[player] == live then
			cpLiveStop(player)
		end
	end)
end)

addEventHandler("onPlayerQuit", root, function()
	cpLiveStop(source)
end)

function phpSDKAccountRename(actorId, targetId, newName, byAdmin)
	local result = function(status, err, old) return {status = status, error = err, old = old} end
	targetId, actorId = tonumber(targetId), tonumber(actorId)
	newName = tostring(newName or "")
	if not newName:match("^[a-zA-Z0-9_.%[%]]*$") or #newName < 3 or #newName > 22 then return result("ERROR", "INVALID_NAME") end
	local oldName = Account.getNameFromId(targetId)
	if not oldName then return result("ERROR", "UNKNOWN_PLAYER") end
	local taken = sql:queryFetchSingle("SELECT Id FROM ??_account WHERE Name = ? AND Id <> ?", sql:getPrefix(), newName, targetId)
	if taken then return result("ERROR", "NAME_TAKEN") end
	sql:queryExec("UPDATE ??_account SET Name = ? WHERE Id = ?", sql:getPrefix(), newName, targetId)
	StatisticsLogger:getSingleton():addPunishLog(actorId, targetId, "nickchange", ("von %s zu %s (Control Panel)"):format(oldName, newName), 0)
	local player = Player.getFromId(targetId)
	if player and isElement(player) and player:getAccount() then
		player:getAccount().m_Username = newName
		player:setName(newName)
		player:sendShortMessage(byAdmin and ("%s hat deinen Namen über das ControlPanel von %s in %s geändert."):format(Account.getNameFromId(actorId) or "Ein Admin", oldName, newName)
			or ("Dein Name wurde über das ControlPanel von %s in %s geändert."):format(oldName, newName), "Account")
	else
		sql:queryExec("INSERT INTO ??_offlinemessage (PlayerId, Text, Typ, Time) VALUES (?, ?, 1, ?)", sql:getPrefix(), targetId, ("Dein Name wurde über das ControlPanel von %s in %s geändert."):format(oldName, newName), getRealTime().timestamp)
	end
	return result("SUCCESS", nil, oldName)
end

function phpSDKAccountLock(actorId, targetId, reason)
	targetId = tonumber(targetId)
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	sql:queryExec("UPDATE ??_account SET AutologinToken = NULL, RememberToken = NULL, ApiToken = NULL WHERE Id = ?", sql:getPrefix(), targetId)
	local player = Player.getFromId(targetId)
	if player and isElement(player) then
		player:kick(tostring(reason or "Dein Account ist zur Löschung vorgemerkt."))
	end
	return {status = "SUCCESS"}
end

local function phpSDKAccountPurge(targetId, newName, keepSerials)
	local purged = {}
	local prefix = sql:getPrefix()
	local run = function(label, db, query, ...)
		local result, rows = dbPoll(dbQuery(db.m_DBHandle, query, ...), -1)
		if result and tonumber(rows) and rows > 0 then purged[label] = (purged[label] or 0) + rows end
	end
	local account = sql:queryFetchSingle("SELECT LastSerial FROM ??_account WHERE Id = ?", prefix, targetId) or {}
	local lastSerial = account.LastSerial and account.LastSerial ~= "" and account.LastSerial or nil
	local ban = sql:queryFetchSingle("SELECT Id, serial FROM ??_bans WHERE player_id = ? AND (expires = 0 OR expires >= UNIX_TIMESTAMP()) ORDER BY expires = 0 DESC, expires DESC LIMIT 1", prefix, targetId)
	if ban and (ban.serial or ""):gsub("%s", "") == "" and lastSerial then
		sql:queryExec("UPDATE ??_bans SET serial = ? WHERE Id = ?", prefix, lastSerial, ban.Id)
	end
	if not keepSerials then
		local serials = {}
		for _, row in ipairs(sql:queryFetch("SELECT Serial FROM ??_account_to_serial WHERE PlayerId = ? UNION SELECT Serial FROM ??_client_statistics WHERE UserId = ?", prefix, targetId, prefix, targetId) or {}) do
			if row.Serial and row.Serial ~= "" then serials[row.Serial] = true end
		end
		if lastSerial then serials[lastSerial] = true end
		for serial in pairs(serials) do
			local used = sql:queryFetchSingle("SELECT (SELECT COUNT(*) FROM ??_account_to_serial WHERE Serial = ? AND PlayerId <> ?) + (SELECT COUNT(*) FROM ??_account WHERE LastSerial = ? AND Id <> ?) AS Count", prefix, serial, targetId, prefix, serial, targetId)
			if not used or tonumber(used.Count) == 0 then
				run("Mods", sql, "DELETE FROM ??_account_mods WHERE Serial = ?", prefix, serial)
				run("Multiaccount-Serials", sql, "DELETE FROM ??_account_multiaccount WHERE Serial = ?", prefix, serial)
			end
		end
		run("Serials", sql, "DELETE FROM ??_account_to_serial WHERE PlayerId = ?", prefix, targetId)
		run("Hardware", sql, "DELETE FROM ??_client_statistics WHERE UserId = ?", prefix, targetId)
		run("Multiaccount-Serials", sql, "DELETE FROM ??_account_multiaccount WHERE LinkedTo = ?", prefix, targetId)
	end
	run("Screenshots", sql, "DELETE FROM ??_account_screenshot WHERE UserId = ?", prefix, targetId)
	run("TeamSpeak", sql, "DELETE FROM ??_teamspeak_identity WHERE UserId = ?", prefix, targetId)
	run("Aktivität", sql, "DELETE FROM ??_account_activity WHERE UserId = ?", prefix, targetId)
	run("Offline-Nachrichten", sql, "DELETE FROM ??_offlinemessage WHERE PlayerId = ?", prefix, targetId)
	run("Alte CP-Sitzungen", sql, "DELETE FROM cploggedin WHERE gameid = ?", targetId)
	for _, col in ipairs({"Firstname", "Lastname", "EMail", "Adress", "PLZ", "City", "Country"}) do
		run("Rechnungsdaten", sqlPremium, ("UPDATE `user` SET `%s` = NULL WHERE UserId = ? AND `%s` IS NOT NULL"):format(col, col), targetId)
		run("Rechnungsdaten", sqlPremium, ("UPDATE `user` SET `%s` = '' WHERE UserId = ? AND `%s` <> ''"):format(col, col), targetId)
	end
	run("Rechnungsdaten", sqlPremium, "UPDATE `user` SET Name = ? WHERE UserId = ?", newName, targetId)
	local playerCols = {UserId = true, UserID = true, TargetId = true, PlayerId = true, PoliceId = true, HostId = true, ReceivingId = true, GivingId = true, Attacker = true, Target = true, SellerId = true, BuyerId = true, Receiver = true}
	local keep = {vrplogs_punish = true, vrplogs_punishlog = true}
	local tables = {}
	for _, row in ipairs(sqlLogs:queryFetch("SELECT TABLE_NAME AS T, COLUMN_NAME AS C FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ?", sqlLogs.m_Database) or {}) do
		tables[row.T] = tables[row.T] or {}
		tables[row.T][row.C] = true
	end
	for name, cols in pairs(tables) do
		if not keep[name] then
			local where, args = {}, {}
			for col in pairs(cols) do
				if playerCols[col] then
					where[#where + 1] = ("`%s` = ?"):format(col)
					args[#args + 1] = targetId
				end
			end
			if cols.FromType and cols.ToType then
				where[#where + 1] = "(FromType = 1 AND FromId = ?) OR (ToType = 1 AND ToId = ?)"
				args[#args + 1], args[#args + 2] = targetId, targetId
			end
			if cols.ElementType and cols.ElementId then
				where[#where + 1] = "(ElementType = 'player' AND ElementId = ?)"
				args[#args + 1] = targetId
			end
			if #where > 0 then
				run("Logs", sqlLogs, ("DELETE FROM `%s` WHERE %s"):format(name, table.concat(where, " OR ")), unpack(args))
			end
		end
	end
	sql:queryExec("UPDATE ??_account SET Name = ?, EMail = NULL, Password = '', Salt = '', " .. (keepSerials and "" or "LastSerial = NULL, ") .. "LastIP = NULL, AutologinToken = NULL, RememberToken = NULL, ApiToken = NULL, TeamspeakId = NULL, TeamspeakActivationCode = NULL, ForumID = 0 WHERE Id = ?", prefix, newName, targetId)
	return purged
end

function phpSDKAccountDelete(actorId, targetId, newName, keepSerials)
	local result = function(status, err, purged) return {status = status, error = err, purged = purged} end
	targetId, actorId = tonumber(targetId), tonumber(actorId)
	local name = Account.getNameFromId(targetId)
	if not name then return result("ERROR", "UNKNOWN_PLAYER") end
	newName = tostring(newName or "")
	if not newName:match("^[a-zA-Z0-9_.%[%]]+$") or #newName > 22 then return result("ERROR", "INVALID_NAME") end
	local row = sql:queryFetchSingle("SELECT FactionId, CompanyId, GroupId FROM ??_character WHERE Id = ?", sql:getPrefix(), targetId) or {}
	local reason = "Account gelöscht"
	local faction = row.FactionId and row.FactionId ~= 0 and FactionManager:getSingleton():getFromId(row.FactionId)
	if faction and faction:isPlayerMember(targetId) then
		HistoryPlayer:getSingleton():addLeaveEntry(targetId, actorId, faction:getId(), "faction", faction:getPlayerRank(targetId), reason, reason)
		faction:addLog(actorId, "Fraktion", ("hat den Spieler %s aus der Fraktion entfernt! (Account gelöscht, Control Panel)"):format(name))
		faction:removePlayer(targetId)
	end
	local company = row.CompanyId and row.CompanyId ~= 0 and CompanyManager:getSingleton():getFromId(row.CompanyId)
	if company and company:isPlayerMember(targetId) then
		HistoryPlayer:getSingleton():addLeaveEntry(targetId, actorId, company:getId(), "company", company:getPlayerRank(targetId), reason, reason)
		company:addLog(actorId, "Unternehmen", ("hat den Spieler %s aus dem Unternehmen entfernt! (Account gelöscht, Control Panel)"):format(name))
		company:removePlayer(targetId)
	end
	local group = row.GroupId and row.GroupId ~= 0 and GroupManager.Map[row.GroupId]
	if group and group.m_Players[targetId] then
		HistoryPlayer:getSingleton():addLeaveEntry(targetId, actorId, group:getId(), "group", group:getPlayerRank(targetId) or 0, reason, reason)
		local player = Player.getFromId(targetId)
		if player and isElement(player) then
			group:removePlayer(targetId)
		else
			group.m_Players[targetId] = nil
			group.m_PlayerLoans[targetId] = nil
			group.m_PlayerPermissions[targetId] = nil
			sql:queryExec("UPDATE ??_character SET GroupId = 0, GroupRank = 0, GroupLoanEnabled = 0 WHERE Id = ?", sql:getPrefix(), targetId)
		end
	end
	local player = Player.getFromId(targetId)
	if player and isElement(player) then
		player:kick("Dein Account wurde gelöscht.")
	end
	return result("SUCCESS", nil, phpSDKAccountPurge(targetId, newName, keepSerials == true or keepSerials == 1 or keepSerials == "1"))
end

local function phpSDKFindShopVehicle(shopVehId)
	shopVehId = tonumber(shopVehId)
	for shopId, shop in pairs(ShopManager.VehicleShopsMap) do
		for model, list in pairs(shop.m_VehicleList) do
			for index, entry in ipairs(list) do
				if entry.id == shopVehId then return shop, model, index, entry end
			end
		end
	end
end

function phpSDKShopVehicles()
	local shops = {}
	for shopId, shop in pairs(ShopManager.VehicleShopsMap) do
		local list = {}
		for model, entries in pairs(shop.m_VehicleList) do
			for _, entry in ipairs(entries) do
				list[#list + 1] = {id = entry.id, model = model, price = entry.price, level = entry.level, stock = entry.currentStock, max = entry.maxStock}
			end
		end
		shops[tostring(shopId)] = list
	end
	return {status = "SUCCESS", shops = shops}
end

function phpSDKShopVehicleEdit(adminId, shopVehId, data)
	local shop, model, index, entry = phpSDKFindShopVehicle(shopVehId)
	if not shop then return {status = "ERROR", error = "NOT_FOUND"} end
	data = type(data) == "table" and data or {}
	local newModel = tonumber(data.model) or model
	if newModel ~= model then
		if not getVehicleNameFromModel(newModel) or getVehicleNameFromModel(newModel) == "" then return {status = "ERROR", error = "INVALID_MODEL"} end
		if entry.vehicle and isElement(entry.vehicle) then entry.vehicle:setModel(newModel) end
		entry.templateId, entry.template = 0, ""
		table.remove(shop.m_VehicleList[model], index)
		if #shop.m_VehicleList[model] == 0 then shop.m_VehicleList[model] = nil end
		shop.m_VehicleList[newModel] = shop.m_VehicleList[newModel] or {}
		table.insert(shop.m_VehicleList[newModel], entry)
		model, index = newModel, #shop.m_VehicleList[newModel]
	end
	if tonumber(data.price) then entry.price = math.max(0, math.floor(tonumber(data.price))) end
	if tonumber(data.level) then entry.level = math.max(0, math.floor(tonumber(data.level))) end
	if tonumber(data.maxStock) then entry.maxStock = math.floor(tonumber(data.maxStock)) end
	sql:queryExec("UPDATE ??_vehicle_shop_veh SET Model = ?, Name = ?, Price = ?, Level = ?, MaxStock = ?, TemplateId = ? WHERE Id = ?", sql:getPrefix(),
		model, getVehicleNameFromModel(model), entry.price, entry.level, tonumber(data.maxStock) or entry.maxStock, entry.templateId or 0, entry.id)
	if tonumber(data.stock) then
		local max = entry.maxStock
		if max == -1 then entry.maxStock = math.max(0, tonumber(data.stock)) end
		shop:internalSetVehicleStock(model, index, math.max(0, math.floor(tonumber(data.stock))))
		entry.maxStock = max
	end
	return {status = "SUCCESS", stock = entry.currentStock}
end

function phpSDKShopVehicleAdd(adminId, shopId, model, price, level, stock, maxStock, pos)
	local shop = ShopManager.VehicleShopsMap[tonumber(shopId)]
	if not shop then return {status = "ERROR", error = "UNKNOWN_SHOP"} end
	model = tonumber(model)
	if not model or not getVehicleNameFromModel(model) or getVehicleNameFromModel(model) == "" then return {status = "ERROR", error = "INVALID_MODEL"} end
	local x, y, z, rz
	if pos == "admin" then
		local admin = Player.getFromId(tonumber(adminId))
		if not admin or not isElement(admin) then return {status = "ERROR", error = "ADMIN_OFFLINE"} end
		x, y, z = getElementPosition(admin)
		local _, _, r = getElementRotation(admin)
		rz = r
	elseif type(pos) == "table" and tonumber(pos.x) and tonumber(pos.y) and tonumber(pos.z) then
		x, y, z, rz = tonumber(pos.x), tonumber(pos.y), tonumber(pos.z), tonumber(pos.rz) or 0
	else
		return {status = "ERROR", error = "NO_POSITION"}
	end
	price, level, stock, maxStock = math.max(0, math.floor(tonumber(price) or 0)), math.max(0, math.floor(tonumber(level) or 0)), math.max(0, math.floor(tonumber(stock) or 0)), math.floor(tonumber(maxStock) or 0)
	sql:queryExec("INSERT INTO ??_vehicle_shop_veh (ShopId, Model, Name, Category, Level, Price, X, Y, Z, RX, RY, RZ, TemplateId, CurrentStock, MaxStock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, ?, 0, ?, ?)",
		sql:getPrefix(), shop.m_Id, model, getVehicleNameFromModel(model), shop.m_Name, level, price, x, y, z, rz, stock, maxStock)
	local id = sql:lastInsertId()
	shop:addVehicle(id, model, getVehicleNameFromModel(model), shop.m_Name, price, level, Vector3(x, y, z), Vector3(0, 0, rz), 0, stock, maxStock)
	return {status = "SUCCESS", id = id}
end

function phpSDKShopVehicleDelete(adminId, shopVehId)
	local shop, model, index, entry = phpSDKFindShopVehicle(shopVehId)
	if not shop then return {status = "ERROR", error = "NOT_FOUND"} end
	if entry.vehicle and isElement(entry.vehicle) then entry.vehicle:destroy() end
	table.remove(shop.m_VehicleList[model], index)
	if #shop.m_VehicleList[model] == 0 then shop.m_VehicleList[model] = nil end
	sql:queryExec("DELETE FROM ??_vehicle_shop_veh WHERE Id = ?", sql:getPrefix(), entry.id)
	return {status = "SUCCESS"}
end

function phpSDKOrgReloadLimits(groupType, groupId)
	local instance = groupType == "faction" and FactionManager:getSingleton():getFromId(tonumber(groupId)) or groupType == "company" and CompanyManager:getSingleton():getFromId(tonumber(groupId))
	if not instance then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local row = sql:queryFetchSingle(("SELECT PlayerLimit, MaxVehicles, VehicleLimits FROM ??_%s WHERE Id = ?"):format(groupType == "faction" and "factions" or "companies"), sql:getPrefix(), instance:getId())
	if not row then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	instance.m_PlayerLimit = (row.PlayerLimit or 0) > 0
	instance.m_MaxPlayers = row.PlayerLimit or 0
	instance.m_MaxVehicles = row.MaxVehicles or 0
	local limits = {}
	for k, v in pairs(fromJSON(row.VehicleLimits or "") or {}) do limits[tonumber(k)] = v end
	instance.m_VehicleLimits = limits
	return {status = "SUCCESS"}
end

function phpSDKFCShopReload(shopId)
	local shop = ShopManager.FCVehicleShopsMap[tonumber(shopId)]
	if not shop then return {status = "ERROR", error = "UNKNOWN_SHOP"} end
	shop:reload()
	return {status = "SUCCESS"}
end

function phpSDKOrgRespawnVehicles(adminId, groupType, groupId)
	groupId = tonumber(groupId)
	local instance = groupType == "faction" and FactionManager:getSingleton():getFromId(groupId) or groupType == "company" and CompanyManager:getSingleton():getFromId(groupId)
	if not instance then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local list = groupType == "faction" and VehicleManager:getSingleton():getFactionVehicles(groupId) or VehicleManager:getSingleton():getCompanyVehicles(groupId)
	local adminName = Account.getNameFromId(tonumber(adminId)) or "Control Panel"
	instance:sendShortMessage(("%s hat eure Fahrzeuge über das Control Panel respawned!"):format(adminName))
	local vehicles, fails = 0, 0
	for _, vehicle in pairs(list) do
		if isElement(vehicle) and ((groupType == "faction" and vehicle:getFaction() == instance) or (groupType == "company" and vehicle:getCompany() == instance)) then
			vehicles = vehicles + 1
			vehicle:removeAttachedPlayers()
			if not vehicle:respawn(true, true) then
				fails = fails + 1
			else
				vehicle:setInterior(vehicle.m_SpawnInt or 0)
				vehicle:setDimension(vehicle.m_SpawnDim or 0)
			end
		end
	end
	instance.m_LastRespawn = getRealTime().timestamp
	instance:sendShortMessage(("%s/%s Fahrzeuge wurden respawned!"):format(vehicles - fails, vehicles))
	Admin:getSingleton():sendShortMessage(("%s hat die Fahrzeuge von %s über das Control Panel respawned (%s/%s)."):format(adminName, instance:getShortName(), vehicles - fails, vehicles))
	StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId), groupType == "faction" and "respawnFaction" or "respawnCompany", instance:getShortName())
	return {status = "SUCCESS", vehicles = vehicles, respawned = vehicles - fails}
end

function phpSDKReloadBadNames()
	local manager = NameManager:getSingleton()
	local names = {}
	for _, data in pairs(sql:queryFetch("SELECT Name FROM ??_bad_names", sql:getPrefix()) or {}) do
		table.insert(names, string.lower(data["Name"]))
	end
	manager.m_BadNames = names
	return {status = "SUCCESS", count = #names}
end

function phpSDKFactionDepot(factionId)
	local faction = FactionManager:getSingleton():getFromId(tonumber(factionId))
	if not faction then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local depot = faction:getDepot()
	if not depot then return {status = "ERROR", error = "NO_DEPOT"} end
	local weapons, stock = {}, depot:getWeaponTable() or {}
	for id, info in pairs(faction.m_WeaponDepotInfo or {}) do
		local s = stock[id] or {}
		local valid = faction.m_ValidWeapons and faction.m_ValidWeapons[id] and true or false
		if valid or (s.Waffe or 0) > 0 or (s.Munition or 0) > 0 then
			weapons[#weapons + 1] = {id = id, weapons = s.Waffe or 0, magazines = s.Munition or 0, maxWeapons = info.Waffe or 0, maxMagazines = info.Magazine or 0, valid = valid}
		end
	end
	local items = {}
	for slot, it in pairs(depot.m_Items or {}) do
		if type(it) == "table" and it.Item and it.Item ~= 0 and (it.Amount or 0) > 0 then
			items[#items + 1] = {slot = tonumber(slot), item = tostring(it.Item), amount = it.Amount}
		end
	end
	local equipment = {}
	for name, info in pairs(faction.m_EquipmentDepotInfo or {}) do
		equipment[#equipment + 1] = {name = name, amount = (depot:getEquipmentTable() or {})[name] or 0, maxPerDrop = info.MaxPerAirDrop or 0}
	end
	return {status = "SUCCESS", weapons = weapons, items = items, itemSlots = 6, equipment = equipment}
end

function phpSDKFactionDepotEdit(adminId, factionId, kind, key, a, b)
	local faction = FactionManager:getSingleton():getFromId(tonumber(factionId))
	if not faction then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local depot = faction:getDepot()
	if not depot then return {status = "ERROR", error = "NO_DEPOT"} end
	local text
	if kind == "weapon" then
		local id = tonumber(key)
		if not id or id < 1 then return {status = "ERROR", error = "INVALID"} end
		depot.m_Weapons[id] = depot.m_Weapons[id] or {Id = id, Waffe = 0, Munition = 0}
		depot.m_Weapons[id].Waffe = math.max(0, math.floor(tonumber(a) or 0))
		depot.m_Weapons[id].Munition = math.max(0, math.floor(tonumber(b) or 0))
		text = ("Waffe %d: %d Waffen, %d Magazine"):format(id, depot.m_Weapons[id].Waffe, depot.m_Weapons[id].Munition)
	elseif kind == "item" then
		local slot = tonumber(key)
		if not slot or slot < 1 or slot > 6 then return {status = "ERROR", error = "INVALID"} end
		local amount = math.max(0, math.floor(tonumber(b) or 0))
		local empty = not a or a == "" or amount == 0
		depot.m_Items[slot] = {Item = empty and 0 or tostring(a), Amount = empty and 0 or amount}
		text = empty and ("Itemplatz %d geleert"):format(slot) or ("Itemplatz %d: %d %s"):format(slot, amount, tostring(a))
	elseif kind == "equipment" then
		if type(key) ~= "string" or key == "" then return {status = "ERROR", error = "INVALID"} end
		depot.m_Equipments[key] = math.max(0, math.floor(tonumber(a) or 0))
		text = ("%s: %d"):format(key, depot.m_Equipments[key])
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	depot:save()
	Admin:getSingleton():sendShortMessage("%s hat das Lager von %s bearbeitet: %s (Control Panel)", {Account.getNameFromId(tonumber(adminId)) or "?", faction:getShortName() or faction:getName(), text})
	return {status = "SUCCESS"}
end

function phpSDKSetMembership(adminId, targetId, groupType, groupId, rank, reasonExternal, reasonInternal, record)
	record = record ~= false
	targetId, groupId, rank = tonumber(targetId), tonumber(groupId) or 0, tonumber(rank) or 0
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local manager = groupType == "faction" and FactionManager:getSingleton() or groupType == "company" and CompanyManager:getSingleton() or groupType == "group" and GroupManager:getSingleton()
	if not manager then return {status = "ERROR", error = "UNKNOWN_TYPE"} end
	local target = Player.getFromId(targetId)
	if target and not isElement(target) then target = nil end
	local column = groupType == "faction" and "FactionId" or groupType == "company" and "CompanyId" or "GroupId"
	local row = sql:queryFetchSingle(("SELECT %s AS Cur FROM ??_character WHERE Id = ?"):format(column), sql:getPrefix(), targetId)
	local get = function(id)
		if groupType == "group" and not manager:getFromId(id) then manager:loadFromId(id) end
		return manager:getFromId(id)
	end
	local old = row and (row.Cur or 0) > 0 and get(row.Cur) or nil
	local new = groupId > 0 and get(groupId) or nil
	if groupId > 0 and not new then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local maxRank = groupType == "faction" and FactionRank.Leader or groupType == "company" and CompanyRank.Leader or 6
	if rank < 0 or rank > maxRank then return {status = "ERROR", error = "RANK_OUT_OF_RANGE"} end
	local managerRank = groupType == "faction" and FactionRank.Manager or groupType == "company" and CompanyRank.Manager
	local category = groupType == "faction" and "Fraktion" or groupType == "company" and "Unternehmen" or "Gruppe"
	local targetName = Account.getNameFromId(targetId)
	if managerRank and rank >= managerRank and LeaderCheck:getSingleton():hasPlayerLeaderBan(targetId) then return {status = "ERROR", error = "LEADER_BAN"} end
	if old and new and old == new then
		if old:getPlayerRank(targetId) == rank then return {status = "SUCCESS", unchanged = true} end
		local oldRank = old:getPlayerRank(targetId) or 0
		old:setPlayerRank(targetId, rank)
		old:addLog(tonumber(adminId), category, ("hat den Spieler %s über das ControlPanel auf Rang %d %s!"):format(targetName, rank, rank > oldRank and "befördert" or "degradiert"))
		if groupType ~= "group" and record then HistoryPlayer:getSingleton():setHighestRank(targetId, rank, old:getId(), groupType) end
		if target then
			target:setPublicSync(groupType == "faction" and "FactionRank" or groupType == "company" and "CompanyRank" or "GroupRank", rank)
			target:sendShortMessage(("Dein Rang wurde über das ControlPanel auf %d gesetzt."):format(rank), old:getName())
		end
		Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(targetId)
		return {status = "SUCCESS"}
	end
	if old then
		if groupType ~= "group" and record then
			phpSDKHistoryLeave(targetId, adminId, old:getId(), groupType, old:getPlayerRank(targetId) or 0, reasonInternal or "", reasonExternal or "Control Panel")
		end
		old:addLog(tonumber(adminId), category, ("hat den Spieler %s über das ControlPanel aus %s geworfen!"):format(targetName, groupType == "faction" and "der Fraktion" or groupType == "company" and "dem Unternehmen" or "der Gruppe"))
		old:removePlayer(targetId)
	elseif groupType ~= "group" and row and (row.Cur or 0) > 0 then
		sql:queryExec(("UPDATE ??_character SET %s = 0, %s = 0 WHERE Id = ?"):format(column, groupType == "faction" and "FactionRank" or "CompanyRank"), sql:getPrefix(), targetId)
	end
	if new then
		if groupType ~= "group" and record then
			HistoryPlayer:getSingleton():addJoinEntry(targetId, adminId, new:getId(), groupType)
			HistoryPlayer:getSingleton():setHighestRank(targetId, rank, new:getId(), groupType)
		end
		new:addPlayer(targetId, rank)
		new:addLog(tonumber(adminId), category, ("hat den Spieler %s über das ControlPanel mit Rang %d in %s eingeladen!"):format(targetName, rank, groupType == "faction" and "die Fraktion" or groupType == "company" and "das Unternehmen" or "die Gruppe"))
		if groupType == "group" then new:spawnVehicles() end
		if target then target:sendShortMessage(("Du wurdest über das ControlPanel in %s gesetzt (Rang %d)."):format(new:getName(), rank), new:getName()) end
	end
	Async.create(function(id) ServiceSync:getSingleton():syncPlayer(id) end)(targetId)
	return {status = "SUCCESS"}
end

function phpSDKOrgSkins(adminId, groupType, groupId, action, skinId, minRank, oldSkinId)
	local instance = groupType == "faction" and FactionManager:getSingleton():getFromId(tonumber(groupId)) or groupType == "company" and CompanyManager:getSingleton():getFromId(tonumber(groupId))
	if not instance then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	skinId, minRank, oldSkinId = tonumber(skinId), tonumber(minRank) or 0, tonumber(oldSkinId)
	local settings = instance.m_Settings
	local maxRank = groupType == "faction" and FactionRank.Leader or CompanyRank.Leader
	if action ~= "save" and action ~= "delete" then return {status = "ERROR", error = "UNKNOWN_ACTION"} end
	if action == "save" and (not skinId or skinId < 0 or skinId > 312) then return {status = "ERROR", error = "INVALID_SKIN"} end
	if action == "save" and (minRank > maxRank or minRank < (groupType == "faction" and -1 or 0)) then return {status = "ERROR", error = "RANK_OUT_OF_RANGE"} end
	local removeId = action == "delete" and skinId or (oldSkinId and oldSkinId ~= skinId and oldSkinId) or nil
	if removeId and not instance.m_Skins[removeId] then return {status = "ERROR", error = "UNKNOWN_SKIN"} end
	if action == "save" and skinId ~= oldSkinId and instance.m_Skins[skinId] then return {status = "ERROR", error = "SKIN_EXISTS"} end
	local count = 0
	for _ in pairs(instance.m_Skins) do count = count + 1 end
	if action == "delete" and count <= 1 then return {status = "ERROR", error = "LAST_SKIN"} end

	if not next(settings.m_Settings["SkinList"] or {}) then
		for id in pairs(instance.m_Skins) do settings:writeSetting("SkinList", id, 1) end
	end
	local removed = {}
	if removeId then
		instance.m_Skins[removeId] = nil
		settings:writeSetting("SkinList", removeId, nil)
		settings:writeSetting("Skin", removeId, nil)
		removed[removeId] = true
	end
	if action == "save" then
		instance.m_Skins[skinId] = true
		settings:writeSetting("SkinList", skinId, 1)
		settings:writeSetting("Skin", skinId, minRank)
	end
	if groupType == "faction" and not instance:isStateFaction() then
		instance.m_SpecialSkin = nil
		for id in pairs(instance.m_Skins) do if tonumber(instance:getSetting("Skin", id, 0)) == -1 then instance.m_SpecialSkin = id end end
	end

	local changed = 0
	for _, player in pairs(instance:getOnlinePlayers()) do
		local onDuty = groupType == "faction" and player:isFactionDuty() or groupType == "company" and player:isCompanyDuty()
		local model = player:getModel()
		local rank = instance:getPlayerRank(player) or 0
		if onDuty and (removed[model] or (instance.m_Skins[model] and tonumber(instance:getSetting("Skin", model, 0)) > rank)) then
			instance:changeSkin(player)
			player:sendShortMessage("Deine Dienstkleidung wurde über das ControlPanel geändert – du hast eine andere bekommen.", instance:getName())
			changed = changed + 1
		end
	end
	return {status = "SUCCESS", changed = changed}
end


function phpSDKHouse(adminId, action, houseId, data)
	local hm = HouseManager:getSingleton()
	houseId, data = tonumber(houseId) or 0, type(data) == "table" and data or {}
	local pos = tonumber(data.x) and tonumber(data.y) and tonumber(data.z) and Vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z)) or nil
	local interior, price, rent = tonumber(data.interior), tonumber(data.price), tonumber(data.rent)
	if action == "save" then
		if interior and not HOUSE_INTERIOR_TABLE[interior] then return {status = "ERROR", error = "INVALID_INTERIOR"} end
		if houseId == 0 then
			if not pos or not interior or not price then return {status = "ERROR", error = "MISSING_DATA"} end
			sql:queryExec("INSERT INTO ??_houses (x,y,z,interiorID,`keys`,owner,price,lockStatus,rentPrice,elements) VALUES (?,?,?,?,?,?,?,?,?,?)",
				sql:getPrefix(), pos.x, pos.y, pos.z, interior, toJSON({}), 0, price, 0, rent or 25, toJSON({}))
			local id = sql:lastInsertId()
			hm.m_Houses[id] = House:new(id, pos, interior, toJSON({}), 0, price, 0, rent or 25, toJSON({}))
			HouseManager.Map[id] = hm.m_Houses[id]
			return {status = "SUCCESS", id = id}
		end
		local house = hm.m_Houses[houseId]
		if not house then return {status = "ERROR", error = "UNKNOWN_HOUSE"} end
		if pos and not house.m_IsInSkyscraper then
			house.m_Pos = pos
			if isElement(house.m_Pickup) then setElementPosition(house.m_Pickup, pos) end
		end
		if interior and interior ~= house.m_InteriorID then
			house.m_InteriorID = interior
			house:refreshInteriorMarker()
		end
		if price then house.m_Price = price end
		if rent then house.m_RentPrice = rent end
		if house.m_Owner and tonumber(data.buyPrice) then house.m_BuyPrice = tonumber(data.buyPrice) end
		if house.m_Owner and data.salePrice ~= nil then
			local sale = tonumber(data.salePrice) or 0
			house:setForSale(sale > 0, sale, data.showInTownhall == true or tonumber(data.showInTownhall) == 1)
		end
		if data.locked ~= nil and not house.m_ForSale then house.m_LockStatus = data.locked == true or tonumber(data.locked) == 1 end
		house:save()
		return {status = "SUCCESS", id = houseId}
	elseif action == "delete" then
		local house = hm.m_Houses[houseId]
		if not house then return {status = "ERROR", error = "UNKNOWN_HOUSE"} end
		if house.m_IsInSkyscraper then return {status = "ERROR", error = "SKYSCRAPER"} end
		if #house.m_Garage > 0 then return {status = "ERROR", error = "HAS_GARAGE"} end
		for player in pairs(house.m_PlayersInterior or {}) do
			if isElement(player) then house:leaveHouse(player) end
		end
		local owner, refund, cash = house:getOwner(), 0, house.m_BankAccount:getMoney()
		if owner and owner > 0 then
			refund = (house.m_BuyPrice or 0) > 0 and house.m_BuyPrice or house.m_Price
			house.m_BankAccountServer2:transferMoney({"player", owner, true}, refund, "Haus gelöscht (Rückerstattung)", "House", "AdminDelete")
			if cash > 0 then house.m_BankAccount:transferMoney({"player", owner, true}, cash, "Hauskasse (Haus gelöscht)", "House", "AdminDelete") end
			local msg = ("Dein Haus (Hausnr. %d) wurde vom Team entfernt. Du hast den Kaufpreis von %s%s zurückbekommen."):format(houseId, toMoneyString(refund), cash > 0 and (" und die Hauskasse (%s)"):format(toMoneyString(cash)) or "")
			local target, isOffline = DatabasePlayer.get(owner)
			if target then
				if isOffline then
					target:addOfflineMessage(msg, 1)
					target.m_DoNotSave = true
					delete(target)
				else
					target:sendWarning(msg)
					target:triggerEvent("removeHouseBlip", houseId)
				end
			end
			house:clearHouse()
		end
		if isElement(house.m_Pickup) then destroyElement(house.m_Pickup) end
		if isElement(house.m_HouseMarker) then destroyElement(house.m_HouseMarker) end
		hm.m_Houses[houseId] = nil
		HouseManager.Map[houseId] = nil
		sql:queryExec("DELETE FROM ??_houses WHERE Id = ?", sql:getPrefix(), houseId)
		return {status = "SUCCESS", owner = owner or 0, refund = refund, cash = cash}
	end
	return {status = "ERROR", error = "UNKNOWN_ACTION"}
end

function phpSDKGroupProperty(adminId, action, propId, data)
	local pm = GroupPropertyManager:getSingleton()
	propId, data = tonumber(propId) or 0, type(data) == "table" and data or {}
	if action == "save" then
		local name, price, cam, pickup, interior, spawn = data.name, tonumber(data.price), tostring(data.cam or ""), data.pickup, tonumber(data.interior), data.spawn
		local open, salePrice, elevatorData = tonumber(data.open) == 1 and 1 or 0, tonumber(data.salePrice) or 0, tostring(data.elevator or "")
		if not name or not price or not pickup or not interior or not spawn then return {status = "ERROR", error = "MISSING_DATA"} end
		if propId == 0 then
			sql:queryExec("INSERT INTO ??_group_property (Name, GroupId, Type, Price, Cam, Pickup, InteriorId, InteriorSpawn, open, Message, DepotId, ElevatorData, SalePrice) VALUES (?, 0, 1, ?, NULLIF(?, ''), ?, ?, ?, ?, '', 0, NULLIF(?, ''), ?)",
				sql:getPrefix(), name, price, cam, pickup, interior, spawn, open, elevatorData, salePrice)
			local id = sql:lastInsertId()
			pm:loadProperty(id)
			return {status = "SUCCESS", id = id}
		end
		if not pm.Map[propId] then return {status = "ERROR", error = "UNKNOWN_PROPERTY"} end
		local old = sql:queryFetchSingle("SELECT ElevatorData FROM ??_group_property WHERE Id = ?", sql:getPrefix(), propId) or {}
		local keepElevator = (old.ElevatorData or "") == elevatorData
		local _, elevator = pm:unloadProperty(propId, keepElevator)
		sql:queryExec("UPDATE ??_group_property SET Name = ?, Price = ?, Cam = NULLIF(?, ''), Pickup = ?, InteriorId = ?, InteriorSpawn = ?, open = ?, ElevatorData = NULLIF(?, ''), SalePrice = ? WHERE Id = ?",
			sql:getPrefix(), name, price, cam, pickup, interior, spawn, open, elevatorData, salePrice, propId)
		pm:syncPropertyForOwner(pm:loadProperty(propId, keepElevator and elevator or nil))
		return {status = "SUCCESS", id = propId}
	elseif action == "delete" then
		local property = pm.Map[propId]
		if not property then return {status = "ERROR", error = "UNKNOWN_PROPERTY"} end
		local groupId, price, name = tonumber(property.m_OwnerID) or 0, property.m_Price or 0, property.m_Name
		local group = groupId > 0 and (GroupManager:getSingleton():getFromId(groupId) or (GroupManager:getSingleton():loadFromId(groupId) and GroupManager:getSingleton():getFromId(groupId)))
		for _, player in ipairs(getElementsByType("player")) do
			if player:getDimension() == property.m_Dimension and player:getInterior() == property.m_Interior then
				player:setInterior(0)
				player:setDimension(0)
				player:setPosition(property.m_Position)
				player.m_LastGroupPropertyInside = false
			end
		end
		if group then
			for _, player in ipairs(group:getOnlinePlayers()) do player:triggerEvent("forceGroupPropertyClose") end
		end
		pm:unloadProperty(propId, false)
		sql:queryExec("DELETE FROM ??_group_propKeys WHERE PropId = ?", sql:getPrefix(), propId)
		sql:queryExec("DELETE FROM ??_group_property WHERE Id = ?", sql:getPrefix(), propId)
		if group and price > 0 then
			pm.m_BankAccountServer:transferMoney(group, price, "Immobilie "..name.." vom Team gelöscht (Rückerstattung)", "Group", "PropertyAdminDelete")
			local msg = ("Eure Immobilie '%s' wurde vom Team entfernt. Der volle Kaufpreis von %s wurde in die Gruppenkasse zurückerstattet."):format(name, toMoneyString(price))
			group:addLog(tonumber(adminId) or 0, "Immobilien", ("Immobilie '%s' vom Team gelöscht – %s zurückerstattet (Control Panel)"):format(name, toMoneyString(price)))
			for memberId in pairs(group.m_Players or {}) do
				local player = Player.getFromId(memberId)
				if player and isElement(player) then
					player:sendShortMessage(msg, group:getName())
				else
					sql:queryExec("INSERT INTO ??_offlinemessage (PlayerId, Text, Typ, Time) VALUES (?, ?, 1, ?)", sql:getPrefix(), memberId, msg, getRealTime().timestamp)
				end
			end
			StatisticsLogger:GroupBuyImmoLog(groupId, "ADMIN_DELETE", propId)
		end
		return {status = "SUCCESS", group = groupId, refund = group and price or 0}
	end
	return {status = "ERROR", error = "UNKNOWN_ACTION"}
end


function phpSDKInitiatives()
	local manager = InitiativeManager:isInstantiated() and InitiativeManager:getSingleton()
	if not manager then return {status = "ERROR", error = "NOT_LOADED"} end
	local list = {}
	for id, data in pairs(InitiativeManager.Data) do
		local state = manager.m_Initiatives[id] or {false, {}}
		list[#list + 1] = {id = id, name = data[1], description = (data[2]:gsub("%%%%", "%%")), active = state[1] and true or false, votes = table.size(state[2] or {})}
	end
	return {status = "SUCCESS", active = manager:getActiveInitiative(), initiatives = list}
end

function phpSDKRouletteLimit(userId, limit)
	userId, limit = tonumber(userId), tonumber(limit)
	if not userId then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local cur = RouletteManager.Limits[userId]
	if limit then
		sql:queryExec("DELETE FROM ??_roulette_limits WHERE UserId = ?", sql:getPrefix(), userId)
		if limit > 0 then
			sql:queryExec("INSERT INTO ??_roulette_limits (UserId, `Limit`) VALUES (?, ?)", sql:getPrefix(), userId, limit)
		end
		if limit > 0 then
			RouletteManager.Limits[userId] = {Limit = limit, Bets = cur and cur.Bets or 0}
		else
			RouletteManager.Limits[userId] = nil
		end
		cur = RouletteManager.Limits[userId]
	end
	return {status = "SUCCESS", limit = cur and cur.Limit or 0, bets = cur and cur.Bets or 0}
end

function phpSDKReloadServerSettings()
	ServerSettings:getSingleton():load()
	if InitiativeManager:isInstantiated() and InitiativeManager:getSingleton():getActiveInitiative() == 7 then
		JOB_PAY_MULTIPLICATOR = JOB_PAY_MULTIPLICATOR * 0.75
		JOB_EXTRA_POINT_FACTOR = JOB_EXTRA_POINT_FACTOR * 1.5
	end
	return {status = "SUCCESS"}
end

function phpSDKStateEvidence(reload)
	if not StateEvidence:isInstantiated() then return {status = "ERROR", error = "NOT_LOADED"} end
	local evidence = StateEvidence:getSingleton()
	if reload then evidence:loadObjectData() end
	local values = {}
	for _, v in pairs(evidence.m_EvidenceRoomItems or {}) do
		values[#values + 1] = {id = v.Id, value = math.floor(evidence:getObjectPrice(v.Type, v.Object, v.Amount) or 0)}
	end
	return {status = "SUCCESS", fill = math.floor(evidence.m_FillState or 0), max = STATE_EVIDENCE_MAX_OBJECTS, values = values}
end

function phpSDKLoginFix(adminId, targetId)
	targetId = tonumber(targetId)
	if not targetId then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local entry = DatabasePlayer.Map[targetId]
	if not entry then return {status = "ERROR", error = "NOT_IN_USE"} end
	if isElement(entry) and getElementType(entry) == "player" then return {status = "ERROR", error = "ONLINE"} end
	DatabasePlayer.Map[targetId] = nil
	return {status = "SUCCESS"}
end

function phpSDKAdminAnnounce(adminId, text)
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return {status = "ERROR", error = "EMPTY"} end
	local adminName = Account.getNameFromId(tonumber(adminId)) or "Control Panel"
	triggerClientEvent("breakingNews", root, ("%s: %s"):format(adminName, text), "Admin Ankündigung", {255, 150, 0}, {0, 0, 0})
	StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId) or 0, "adminAnnounce", text)
	return {status = "SUCCESS", players = #getElementsByType("player")}
end

function phpSDKLeaderBan(adminId, action, playerId, reason, validUntil, admins)
	local check = LeaderCheck:getSingleton()
	adminId, playerId, validUntil = tonumber(adminId) or 0, tonumber(playerId), tonumber(validUntil) or 0
	if not playerId or not Account.getNameFromId(playerId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local adminName, playerName = Account.getNameFromId(adminId) or "Control Panel", Account.getNameFromId(playerId)
	if action == "add" then
		if check.m_LeaderBans[playerId] then return {status = "ERROR", error = "ALREADY_BANNED"} end
		if validUntil ~= 0 and validUntil <= getRealTime().timestamp then return {status = "ERROR", error = "INVALID_DURATION"} end
		local ids = {}
		for _, id in pairs(type(admins) == "table" and admins or {}) do
			if tonumber(id) and Account.getNameFromId(tonumber(id)) then ids[#ids + 1] = tonumber(id) end
		end
		local now = getRealTime().timestamp
		if not sql:queryExec("INSERT INTO ??_leader_bans (PlayerId, AdminId, Admins, CreatedAt, ValidUntil, Reason) VALUES (?, ?, ?, ?, ?, ?)", sql:getPrefix(), playerId, adminId, toJSON(ids), now, validUntil, tostring(reason or "")) then
			return {status = "ERROR", error = "DB_ERROR"}
		end
		check.m_LeaderBans[playerId] = {validUntil = validUntil, reason = tostring(reason or ""), admins = ids, createdAt = now}
		Admin:getSingleton():sendShortMessage("%s hat %s eine Leadersperre gegeben! (Control Panel)", {adminName, playerName})
		StatisticsLogger:getSingleton():addPunishLog(adminId, playerId, "addLeaderBan", tostring(reason or ""), validUntil == 0 and 0 or validUntil - now)
		return {status = "SUCCESS"}
	elseif action == "remove" then
		sql:queryExec("DELETE FROM ??_leader_bans WHERE PlayerId = ?", sql:getPrefix(), playerId)
		check.m_LeaderBans[playerId] = nil
		Admin:getSingleton():sendShortMessage("%s hat die Leadersperre von %s entfernt! (Control Panel)", {adminName, playerName})
		StatisticsLogger:getSingleton():addPunishLog(adminId, playerId, "removeLeaderBan", tostring(reason or ""))
		return {status = "SUCCESS"}
	end
	return {status = "ERROR", error = "UNKNOWN_ACTION"}
end

function phpSDKVehicleKeys(ids)
	local want = {}
	for _, id in pairs(type(ids) == "table" and ids or {}) do
		if tonumber(id) then want[tonumber(id)] = true end
	end
	local keys = {}
	for _, vehicle in ipairs(getElementsByType("vehicle")) do
		if vehicle.m_Id and want[vehicle.m_Id] and type(vehicle.m_Keys) == "table" and instanceof(vehicle, PermanentVehicle) then
			local list = {}
			for _, pid in ipairs(vehicle.m_Keys) do list[#list + 1] = tonumber(pid) end
			keys[tostring(vehicle.m_Id)] = list
		end
	end
	return {status = "SUCCESS", keys = keys}
end

function phpSDKVehicleKeyChange(adminId, vehicleId, playerId, action)
	vehicleId, playerId = tonumber(vehicleId), tonumber(playerId)
	if not vehicleId or not playerId then return {status = "ERROR", error = "INVALID"} end
	for _, vehicle in ipairs(getElementsByType("vehicle")) do
		if vehicle.m_Id == vehicleId and instanceof(vehicle, PermanentVehicle) and type(vehicle.m_Keys) == "table" then
			local has = table.find(vehicle.m_Keys, playerId)
			if action == "add" then
				if has then return {status = "ERROR", error = "ALREADY"} end
				vehicle:addKey(playerId)
			elseif action == "remove" then
				if not has then return {status = "ERROR", error = "NO_KEY"} end
				vehicle:removeKey(playerId)
			else
				return {status = "ERROR", error = "UNKNOWN_ACTION"}
			end
			sql:queryExec("UPDATE ??_vehicles SET `Keys` = ? WHERE Id = ?", sql:getPrefix(), toJSON(vehicle.m_Keys, true), vehicleId)
			Admin:getSingleton():sendShortMessage("%s hat %s den Schlüssel für Fahrzeug %d %s! (Control Panel)",
				{Account.getNameFromId(tonumber(adminId)) or "?", Account.getNameFromId(playerId) or tostring(playerId), vehicleId, action == "add" and "gegeben" or "entzogen"})
			return {status = "SUCCESS"}
		end
	end
	local row = sql:queryFetchSingle("SELECT `Keys` FROM ??_vehicles WHERE Id = ?", sql:getPrefix(), vehicleId)
	if not row then return {status = "ERROR", error = "UNKNOWN_VEHICLE"} end
	local keys = row.Keys and fromJSON(row.Keys) or {}
	keys = type(keys) == "table" and keys or {}
	local has = table.find(keys, playerId)
	if action == "add" then
		if has then return {status = "ERROR", error = "ALREADY"} end
		table.insert(keys, playerId)
	elseif action == "remove" then
		if not has then return {status = "ERROR", error = "NO_KEY"} end
		table.remove(keys, has)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	sql:queryExec("UPDATE ??_vehicles SET `Keys` = ? WHERE Id = ?", sql:getPrefix(), toJSON(keys, true), vehicleId)
	return {status = "SUCCESS", spawned = false}
end

function phpSDKRunningEvents()
	local action = ActionsCheck:isInstantiated() and ActionsCheck:getSingleton():isCurrentAction() or false
	local gangwars = {}
	if Gangwar:isInstantiated() then
		for _, area in pairs(Gangwar:getSingleton().m_Areas or {}) do
			if type(area) == "table" and area.m_IsAttacked then
				local f1, f2 = area:getMatchFactions()
				gangwars[#gangwars + 1] = {area = area.m_Name, attacker = f1 and f1:getShortName() or "", owner = f2 and f2:getShortName() or ""}
			end
		end
	end
	return {status = "SUCCESS", action = action or false, gangwars = gangwars}
end

function phpSDKGangwar(adminId, action, areaId, value)
	if not Gangwar:isInstantiated() then return {status = "ERROR", error = "NOT_LOADED"} end
	local gw = Gangwar:getSingleton()
	local pause = GANGWAR_ATTACK_PAUSE * UNIX_TIMESTAMP_24HRS
	if action == "list" then
		local areas = {}
		for _, area in pairs(gw.m_Areas or {}) do
			if type(area) == "table" then
			areas[#areas + 1] = {id = area.m_ID, name = area.m_Name, owner = area.m_Owner or 0, lastAttack = area.m_LastAttack or 0, attacked = area.m_IsAttacked and true or false}
			end
		end
		return {status = "SUCCESS", areas = areas, pause = pause, now = getRealTime().timestamp}
	end
	local area
	for _, a in pairs(gw.m_Areas or {}) do
		if type(a) == "table" and tonumber(a.m_ID) == tonumber(areaId) then area = a end
	end
	if type(area) ~= "table" then return {status = "ERROR", error = "UNKNOWN_AREA"} end
	if area.m_IsAttacked then return {status = "ERROR", error = "UNDER_ATTACK"} end
	local adminName = Account.getNameFromId(tonumber(adminId)) or "Control Panel"
	if action == "owner" then
		local faction = FactionManager:getSingleton():getFromId(tonumber(value))
		if not faction or not faction:isEvilFaction() then return {status = "ERROR", error = "UNKNOWN_FACTION"} end
		area.m_Owner = faction.m_Id
		area.m_LastAttack = getRealTime().timestamp
		area:update()
		area.m_RadarArea:delete()
		area:createRadar()
		Admin:getSingleton():sendShortMessage("%s hat das Gebiet %s der Fraktion %s gesetzt! (Control Panel)", {adminName, area.m_Name, faction:getShortName()})
		StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId) or 0, "Gangwar-Gebiet", "Gebiet: " .. area.m_Name .. " Fraktion: " .. faction:getShortName() .. " ! (Control Panel)")
		return {status = "SUCCESS"}
	elseif action == "release" then
		local ts = math.max(0, tonumber(value) or 0)
		if ts == 0 then ts = getRealTime().timestamp end
		area.m_LastAttack = math.max(0, ts - pause)
		area:update()
		area.m_RadarArea:delete()
		area:createRadar()
		local t = getRealTime(ts)
		local when = ("%02d.%02d.%d %02d:%02d"):format(t.monthday, t.month + 1, t.year + 1900, t.hour, t.minute)
		Admin:getSingleton():sendShortMessage("%s hat die Attackier-Zeit des Gebietes %s geändert! (Control Panel)", {adminName, area.m_Name})
		StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId) or 0, "GW-AttackTime", "Gebiet: " .. area.m_Name .. "; AttackTime: " .. when .. "h ! (Control Panel)")
		return {status = "SUCCESS", releaseAt = ts}
	end
	return {status = "ERROR", error = "UNKNOWN_ACTION"}
end

function phpSDKVoucher(adminId, playerId, data)
	local player = Player.getFromId(tonumber(playerId))
	if not player or not isElement(player) or not (player.isActive and player:isActive()) then
		return {status = "ERROR", error = "TARGET_OFFLINE"}
	end
	data = type(data) == "table" and data or {}
	local reason = tostring(data.label or "Gutschein")
	local money, points = math.floor(tonumber(data.money) or 0), math.floor(tonumber(data.points) or 0)
	if money > 0 then
		local account = player:getBankAccount()
		if not account then return {status = "ERROR", error = "NO_ACCOUNT"} end
		account:__giveMoney(money, reason, true)
		account:save()
		StatisticsLogger:getSingleton():addMoneyLogNew(0, BankAccountTypes.Server, 0, account.m_OwnerId, account.m_OwnerType, account.m_Id, money, reason, "ControlPanel", "Gutschein")
	end
	if points > 0 then
		player:givePoints(points, reason)
	end
	local inv = player:getInventory()
	local items = {}
	for _, it in ipairs(type(data.items) == "table" and data.items or {}) do
		local name, amount = tostring(it.item or ""), math.floor(tonumber(it.amount) or 0)
		local info = inv and inv.m_ItemData[name]
		local fits = false
		if info and amount > 0 and inv:getItemAmount(name) + amount <= info["Item_Max"] then
			local bag, stackMax = info["Tasche"], info["Stack_max"]
			local stackSpace, empty = 0, 0
			for place = 0, inv:getPlaces(bag) do
				local id = inv:getItemID(bag, place)
				if not id then
					empty = empty + 1
				elseif inv.m_Items[id]["Objekt"] == name and inv.m_Items[id]["Menge"] < stackMax then
					stackSpace = stackSpace + (stackMax - inv.m_Items[id]["Menge"])
				end
			end
			fits = math.ceil(math.max(0, amount - stackSpace) / stackMax) <= empty
		end
		local given = fits and inv:giveItem(name, amount) ~= false
		items[#items + 1] = {item = name, amount = amount, ok = given, ticket = not given}
	end
	local weapons = {}
	player.m_GunBox = type(player.m_GunBox) == "table" and player.m_GunBox or {}
	for _, wp in ipairs(type(data.weapons) == "table" and data.weapons or {}) do
		local weaponId, ammo = math.floor(tonumber(wp.weapon) or 0), math.floor(tonumber(wp.ammo) or 0)
		local given = false
		if weaponId > 0 and weaponId ~= 38 and ammo > 0 then
			for i = 1, 6 do
				local key = tostring(i)
				player.m_GunBox[key] = player.m_GunBox[key] or {WeaponId = 0, Amount = 0, VIP = i >= 4}
				local slot = player.m_GunBox[key]
				if not given and slot["WeaponId"] == 0 and (not slot["VIP"] or player:isPremium()) then
					slot["WeaponId"], slot["Amount"] = weaponId, ammo
					given = true
				end
			end
		end
		weapons[#weapons + 1] = {weapon = weaponId, ammo = ammo, ok = given}
	end
	player:save()
	player:sendSuccess(_("%s: erhalten!", player, reason))
	return {status = "SUCCESS", money = money, points = points, items = items, weapons = weapons}
end

function phpSDKShopPoints(playerId, amount, reason, offline)
	local player = Player.getFromId(tonumber(playerId))
	if not player or not isElement(player) or not (player.isActive and player:isActive()) then
		amount = math.floor(tonumber(amount) or 0)
		if not offline or player or amount == 0 then return {status = "ERROR", error = "TARGET_OFFLINE"} end
		local result, rows = dbPoll(dbQuery(sql.m_DBHandle, "UPDATE ??_character SET Points = Points + ? WHERE Id = ? AND Points + ? >= 0", sql:getPrefix(), amount, tonumber(playerId), amount), -1)
		if not result or tonumber(rows) == 0 then return {status = "ERROR", error = "NOT_ENOUGH_POINTS"} end
		return {status = "SUCCESS"}
	end
	amount = math.floor(tonumber(amount) or 0)
	if amount == 0 then return {status = "ERROR", error = "INVALID_AMOUNT"} end
	if amount < 0 and player:getPoints() < -amount then
		return {status = "ERROR", error = "NOT_ENOUGH_POINTS"}
	end
	if amount < 0 then
		player:takePoints(-amount, tostring(reason or "Punkteshop"))
	else
		player:givePoints(amount, tostring(reason or "Punkteshop"))
	end
	player:save()
	return {status = "SUCCESS", points = player:getPoints()}
end

function phpSDKBankTransfer(fromId, toType, toId, amount, purpose)
	local result = function(status, err, money) return {status = status, error = err, money = money} end
	fromId, toId, amount = tonumber(fromId), tonumber(toId), math.floor(tonumber(amount) or 0)
	purpose = tostring(purpose or ""):sub(1, 100)
	if purpose == "" then purpose = "-" end
	if amount < 1 or isNan(amount) then return result("ERROR", "INVALID_AMOUNT") end
	if toType == "player" and fromId == toId then return result("ERROR", "SAME_PLAYER") end

	local target, toName
	if toType == "player" then
		toName = Account.getNameFromId(toId)
		target = toName and {"player", toId, true}
	elseif toType == "admin" then
		target, toName = Admin:getSingleton().m_BankAccount, "Adminkasse"
	else
		local org = (toType == "faction" and FactionManager:getSingleton().Map[toId]) or (toType == "company" and CompanyManager:getSingleton().Map[toId])
			or (toType == "group" and GroupManager.Map[toId]) or nil
		target, toName = org, org and org:getName()
	end
	if not target or not toName then return result("ERROR", "UNKNOWN_TARGET") end

	local fromName = Account.getNameFromId(fromId)
	local player = Player.getFromId(fromId)
	local online = player and isElement(player) and player.isActive and player:isActive()
	local account = online and player:getBankAccount() or BankAccount.loadByOwner(fromId, BankAccountTypes.Player)
	if not account then return result("ERROR", "NO_ACCOUNT") end
	if account:getMoney() < amount then return result("ERROR", "NOT_ENOUGH_MONEY", account:getMoney()) end

	if not account:transferMoney(target, amount, ("Überweisung von %s an %s (ControlPanel)\nZweck: %s"):format(fromName or "?", toName, purpose), "Bank", "Transfer") then
		return result("ERROR", "TRANSFER_FAILED", account:getMoney())
	end
	if not online then account:save() end

	if toType == "player" then
		local toPlayer, offline = DatabasePlayer.get(toId)
		if toPlayer then
			if not offline then
				toPlayer:triggerEvent("bankMoneyBalanceRetrieve", toPlayer:getBankMoney())
				toPlayer:sendShortMessage(_("%s hat dir %d$ überwiesen!\nZweck: %s", toPlayer, fromName or "?", amount, purpose))
			else
				toPlayer:addOfflineMessage(("Du hast eine Offline-Überweisung über %s$ von %s erhalten.\nZweck: %s"):format(amount, fromName or "?", purpose), 1)
				delete(toPlayer)
			end
		end
	end
	if online then
		player:triggerEvent("bankMoneyBalanceRetrieve", player:getBankMoney())
		player:sendShortMessage(_("Du hast an %s %d$ überwiesen (ControlPanel)!\nZweck: %s", player, toName, amount, purpose))
	end
	return result("SUCCESS", nil, account:getMoney())
end

addEventHandler("onPlayerScreenShot", root, function(resource, status, pixels, timestamp, tag)
	if resource == getThisResource() then
		if tag:sub(0, 3) == "cp:" then
			local tag = tag:sub(4, #tag)
			local url = cpScreenshotUrls[tag] or CP_WEB_PATH .. "/api_screenshot.php"
			cpScreenshotUrls[tag] = nil
			if status == "ok" then
				fetchRemote(url, {
					method = "POST",
					formFields = {
						status = "SUCCESS",
						data = pixels,
						tag = tag
					}
				}, function(response)
					local image = tostring(response or ""):match("^OK:(%x+%.jpeg)$")
					if image then
						sql:queryExec("UPDATE ??_account_screenshot SET Status = 'Success', Image = ?, UpdatedAt = NOW() WHERE Tag = ? AND Status = 'Processing'", sql:getPrefix(), image, tag)
					end
				end)
			elseif status == "minimized" then
				sql:queryExec("UPDATE ??_account_screenshot SET Status = 'Minimized', UpdatedAt = NOW() WHERE Tag = ? AND Status = 'Processing'", sql:getPrefix(), tag)
				fetchRemote(url, {
					method = "POST",
					formFields = {
						status = "ERROR",
						error = "MINIMIZED",
						tag = tag
					}
				}, function() end)
			elseif status == "disabled" then
				sql:queryExec("UPDATE ??_account_screenshot SET Status = 'Disabled', UpdatedAt = NOW() WHERE Tag = ? AND Status = 'Processing'", sql:getPrefix(), tag)
				fetchRemote(url, {
					method = "POST",
					formFields = {
						status = "ERROR",
						error = "DISABLED",
						tag = tag
					}
				}, function() end)
			end
		end
	end
end)

local function phpSDKNotifyPlayer(playerId, text)
	local target, offline = DatabasePlayer.get(tonumber(playerId))
	if not target then return end
	if offline then
		target:addOfflineMessage(text, 1)
		delete(target)
	else
		target:sendShortMessage(text)
	end
end

function phpSDKWorldItemList()
	local list = {}
	for item in pairs(WorldItemManager.Map) do
		local obj = item.getObject and item:getObject()
		if not item.m_Delete and obj and isElement(obj) then
			local pos = obj:getPosition()
			list[#list + 1] = {
				key = (tostring(item):gsub("table: ", "")),
				item = item.m_ItemName or "Unknown",
				model = obj:getModel(),
				ownerType = instanceof(item, FactionWorldItem) and "faction" or instanceof(item, CompanyWorldItem) and "company" or "player",
				owner = tonumber(item:getOwner()) or 0,
				ownerName = tostring(obj:getData("Owner") or ""),
				placer = tostring(obj:getData("Placer") or ""),
				placed = tonumber(obj:getData("PlacedTimestamp")) or 0,
				x = pos.x, y = pos.y, z = pos.z,
				interior = obj:getInterior(), dimension = obj:getDimension(),
				permanent = item:isPermanent() and true or false,
			}
		end
	end
	return {status = "SUCCESS", items = list}
end

function phpSDKWorldItemDelete(adminId, keys)
	local wanted = {}
	for _, k in ipairs(type(keys) == "table" and keys or {}) do
		wanted[tostring(k)] = true
	end
	local count, owners = 0, {}
	for item in pairs(WorldItemManager.Map) do
		if not item.m_Delete and wanted[(tostring(item):gsub("table: ", ""))] then
			local ownerType = instanceof(item, FactionWorldItem) and "faction" or instanceof(item, CompanyWorldItem) and "company" or "player"
			local ownerKey = ownerType .. ":" .. tostring(tonumber(item:getOwner()) or 0)
			owners[ownerKey] = (owners[ownerKey] or 0) + 1
			local dbId = item:isPermanent() and item:getDataBaseId() or 0
			item:onDelete()
			if dbId > 0 then
				item:setDataBaseId(0)
				sql:queryExec("DELETE FROM ??_WorldItems WHERE Id=?", sql:getPrefix(), dbId)
			end
			count = count + 1
		end
	end
	if count > 0 then
		local adminName = Account.getNameFromId(tonumber(adminId)) or "Control Panel"
		Admin:getSingleton():sendShortMessage(("%s hat %d platzierte Objekte über das Control Panel entfernt."):format(adminName, count))
		StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId), "deleteWorldItems", tostring(count))
		for ownerKey, n in pairs(owners) do
			local ownerType, ownerId = ownerKey:match("^(%a+):(%d+)$")
			ownerId = tonumber(ownerId)
			if ownerId and ownerId > 0 then
				local text = ("%s hat %d eurer platzierten Objekte über das Control Panel entfernt."):format(adminName, n)
				if ownerType == "faction" then
					local faction = FactionManager:getSingleton():getFromId(ownerId)
					if faction then faction:sendShortMessage(text) end
				elseif ownerType == "company" then
					local company = CompanyManager:getSingleton():getFromId(ownerId)
					if company then company:sendShortMessage(text) end
				else
					phpSDKNotifyPlayer(ownerId, ("%s hat %d deiner platzierten Objekte über das Control Panel entfernt."):format(adminName, n))
				end
			end
		end
	end
	return {status = "SUCCESS", count = count}
end

function phpSDKVehicleRespawn(adminId, vehicleId)
	vehicleId = tonumber(vehicleId)
	local vehicle
	for _, v in ipairs(getElementsByType("vehicle")) do
		if v.getId and v:getId() == vehicleId and not instanceof(v, TemporaryVehicle) then
			vehicle = v
			break
		end
	end
	if not vehicle then return {status = "ERROR", error = "NOT_LOADED"} end
	if vehicle.isRespawnAllowed and not vehicle:isRespawnAllowed() then return {status = "ERROR", error = "RESPAWN_NOT_ALLOWED"} end
	vehicle:removeAttachedPlayers()
	local ok
	if instanceof(vehicle, PermanentVehicle, true) then
		ok = vehicle:respawnOnSpawnPosition()
	else
		ok = vehicle:respawn(true, true)
	end
	if ok == false then return {status = "ERROR", error = "RESPAWN_FAILED"} end
	local adminName = Account.getNameFromId(tonumber(adminId)) or "Control Panel"
	Admin:getSingleton():sendShortMessage(("%s hat das Fahrzeug %s (ID %d) über das Control Panel respawnt."):format(adminName, vehicle:getName(), vehicleId))
	local text = ("%s hat euer Fahrzeug %s über das Control Panel respawnt."):format(adminName, vehicle:getName())
	if instanceof(vehicle, FactionVehicle) and vehicle:getFaction() then
		vehicle:getFaction():sendShortMessage(text)
	elseif instanceof(vehicle, CompanyVehicle) and vehicle:getCompany() then
		vehicle:getCompany():sendShortMessage(text)
	elseif instanceof(vehicle, GroupVehicle) and vehicle:getGroup() then
		vehicle:getGroup():sendShortMessage(text)
	elseif tonumber(vehicle:getOwner()) then
		phpSDKNotifyPlayer(vehicle:getOwner(), ("%s hat dein Fahrzeug %s über das Control Panel respawnt."):format(adminName, vehicle:getName()))
	end
	StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId), "respawnVehicle", tostring(vehicleId))
	return {status = "SUCCESS"}
end

function phpSDKNickchangeFee(adminId, playerId, amount, toAdmin, reason)
	amount = math.floor(tonumber(amount) or 0)
	if amount == 0 then return {status = "ERROR", error = "INVALID_AMOUNT"} end
	local player = Player.getFromId(tonumber(playerId))
	local online = player and isElement(player) and player.isActive and player:isActive()
	local account = online and player:getBankAccount() or BankAccount.loadByOwner(tonumber(playerId), BankAccountTypes.Player)
	if not account then return {status = "ERROR", error = "NO_ACCOUNT"} end
	reason = tostring(reason or "Namensänderung")
	toAdmin = toAdmin == true or toAdmin == 1
	local message = amount > 0 and ("Für deine Namensänderung wurden %s$ von deinem Bankkonto abgebucht."):format(amount) or ("Die Kosten deiner Namensänderung (%s$) wurden dir erstattet."):format(-amount)
	local admin = Admin:getSingleton().m_BankAccount
	if amount > 0 then
		if account:getMoney() < amount then return {status = "ERROR", error = "NOT_ENOUGH_MONEY", money = account:getMoney()} end
		if toAdmin then
			if not account:transferMoney(admin, amount, reason, "Admin", "Namensänderung") then return {status = "ERROR", error = "TRANSFER_FAILED"} end
		else
			account:__takeMoney(amount, reason, true)
			StatisticsLogger:getSingleton():addMoneyLogNew(account.m_OwnerId, account.m_OwnerType, account.m_Id, 0, BankAccountTypes.Server, 0, amount, reason, "Admin", "Namensänderung")
		end
	else
		amount = -amount
		if toAdmin then
			admin:transferMoney(account, amount, reason, "Admin", "Namensänderung", {allowNegative = true})
		else
			account:__giveMoney(amount, reason, true)
			StatisticsLogger:getSingleton():addMoneyLogNew(0, BankAccountTypes.Server, 0, account.m_OwnerId, account.m_OwnerType, account.m_Id, amount, reason, "Admin", "Namensänderung")
		end
	end
	if online then
		player:triggerEvent("bankMoneyBalanceRetrieve", player:getBankMoney())
		player:sendShortMessage(message)
	else
		account:save()
		phpSDKNotifyPlayer(playerId, message)
	end
	return {status = "SUCCESS", money = account:getMoney()}
end

function phpSDKCreditPurchase(playerId, amount, toAdmin, reason, message)
	amount = math.floor(tonumber(amount) or 0)
	if amount == 0 then return {status = "ERROR", error = "INVALID_AMOUNT"} end
	local player = Player.getFromId(tonumber(playerId))
	local online = player and isElement(player) and player.isActive and player:isActive()
	local account = online and player:getBankAccount() or BankAccount.loadByOwner(tonumber(playerId), BankAccountTypes.Player)
	if not account then return {status = "ERROR", error = "NO_ACCOUNT"} end
	reason = tostring(reason or "Credits")
	toAdmin = toAdmin == true or toAdmin == 1
	local admin = Admin:getSingleton().m_BankAccount
	if amount > 0 then
		if account:getMoney() < amount then return {status = "ERROR", error = "NOT_ENOUGH_MONEY", money = account:getMoney()} end
		if toAdmin then
			if not account:transferMoney(admin, amount, reason, "Credits", "Kauf") then return {status = "ERROR", error = "TRANSFER_FAILED"} end
		else
			account:__takeMoney(amount, reason, true)
			StatisticsLogger:getSingleton():addMoneyLogNew(account.m_OwnerId, account.m_OwnerType, account.m_Id, 0, BankAccountTypes.Server, 0, amount, reason, "Credits", "Kauf")
		end
	else
		amount = -amount
		if toAdmin then
			admin:transferMoney(account, amount, reason, "Credits", "Kauf", {allowNegative = true})
		else
			account:__giveMoney(amount, reason, true)
			StatisticsLogger:getSingleton():addMoneyLogNew(0, BankAccountTypes.Server, 0, account.m_OwnerId, account.m_OwnerType, account.m_Id, amount, reason, "Credits", "Kauf")
		end
	end
	if online then
		player:triggerEvent("bankMoneyBalanceRetrieve", player:getBankMoney())
		if message and message ~= "" then player:sendShortMessage(tostring(message)) end
	else
		account:save()
		if message and message ~= "" then phpSDKNotifyPlayer(playerId, tostring(message)) end
	end
	return {status = "SUCCESS", money = account:getMoney()}
end

function phpSDKCreditsChanged(playerId, text)
	local player = Player.getFromId(tonumber(playerId))
	if not player or not isElement(player) or not player.m_Premium then return {status = "ERROR", error = "TARGET_OFFLINE"} end
	local row = sqlPremium:queryFetchSingle("SELECT Credits FROM user WHERE UserId = ?", player:getId())
	player.m_Premium.m_Credits = row and row.Credits or 0
	if text and text ~= "" then player:sendShortMessage(tostring(text)) end
	return {status = "SUCCESS", credits = player.m_Premium.m_Credits}
end

function phpSDKSetPassword(adminId, targetId, hash)
	targetId = tonumber(targetId)
	if not targetId or type(hash) ~= "string" or (hash ~= "" and not hash:match("^%$2[aby]%$%d%d%$")) then return {status = "ERROR", error = "INVALID"} end
	if not sql:queryFetchSingle("SELECT Id FROM ??_account WHERE Id = ?", sql:getPrefix(), targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	sql:queryExec("UPDATE ??_account SET Password = ?, Salt = NULL, AutologinToken = '' WHERE Id = ?", sql:getPrefix(), hash, targetId)
	return {status = "SUCCESS"}
end

function phpSDKSetEmail(adminId, targetId, email)
	targetId = tonumber(targetId)
	if not targetId or type(email) ~= "string" or (email ~= "" and not Account.isEmailValid(email)) then return {status = "ERROR", error = "INVALID"} end
	if not sql:queryFetchSingle("SELECT Id FROM ??_account WHERE Id = ?", sql:getPrefix(), targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	if email ~= "" and sql:queryFetchSingle("SELECT Id FROM ??_account WHERE LCASE(EMail) = LCASE(?) AND Id <> ?", sql:getPrefix(), email, targetId) then return {status = "ERROR", error = "EMAIL_USED"} end
	if email == "" then
		sql:queryExec("UPDATE ??_account SET EMail = NULL WHERE Id = ?", sql:getPrefix(), targetId)
	else
		sql:queryExec("UPDATE ??_account SET EMail = ? WHERE Id = ?", sql:getPrefix(), email, targetId)
	end
	return {status = "SUCCESS"}
end

local function phpSDKAffected(db, query, ...)
	local result, rows = dbPoll(dbQuery(db.m_DBHandle, query, ...), -1)
	return result and tonumber(rows) or false
end

function phpSDKCreditsBook(playerId, amount, mode)
	playerId, amount = tonumber(playerId), math.floor(tonumber(amount) or 0)
	local name = playerId and Account.getNameFromId(playerId)
	if not name then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local row = sqlPremium:queryFetchSingle("SELECT Credits FROM `user` WHERE UserId = ?", playerId)
	if mode == "set" then
		if amount < 0 then return {status = "ERROR", error = "INVALID_AMOUNT"} end
		if row then
			sqlPremium:queryExec("UPDATE `user` SET Credits = ? WHERE UserId = ?", amount, playerId)
		else
			sqlPremium:queryExec("INSERT INTO `user` (UserId, Name, Credits, premium_easter, premium, premium_bis) VALUES (?, ?, ?, 0, 0, 0)", playerId, name, amount)
		end
	elseif row then
		if amount ~= 0 and (phpSDKAffected(sqlPremium, "UPDATE `user` SET Credits = Credits + ? WHERE UserId = ? AND Credits + ? >= 0", amount, playerId, amount) or 0) == 0 then
			return {status = "ERROR", error = "NOT_ENOUGH_CREDITS"}
		end
	elseif amount < 0 then
		return {status = "ERROR", error = "NOT_ENOUGH_CREDITS"}
	elseif amount > 0 then
		sqlPremium:queryExec("INSERT INTO `user` (UserId, Name, Credits, premium_easter, premium, premium_bis) VALUES (?, ?, ?, 0, 0, 0)", playerId, name, amount)
	end
	local credits = tonumber((sqlPremium:queryFetchSingle("SELECT Credits FROM `user` WHERE UserId = ?", playerId) or {}).Credits) or 0
	local player = Player.getFromId(playerId)
	if player and isElement(player) and player.m_Premium then
		player.m_Premium.m_Credits = credits
	end
	return {status = "SUCCESS", credits = credits}
end

function phpSDKPremiumGrant(playerId, data)
	playerId = tonumber(playerId)
	local name = playerId and Account.getNameFromId(playerId)
	if not name then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	data = type(data) == "table" and data or {}
	local credits, vipDays = math.floor(tonumber(data.credits) or 0), math.floor(tonumber(data.vipDays) or 0)
	local vipPermanent = data.vipPermanent == true or data.vipPermanent == 1
	local result = {status = "SUCCESS", vehicles = 0}
	if credits > 0 or vipDays > 0 or vipPermanent then
		local row = sqlPremium:queryFetchSingle("SELECT premium_bis FROM `user` WHERE UserId = ?", playerId)
		if not row then
			sqlPremium:queryExec("INSERT INTO `user` (UserId, Name, premium_easter, premium, premium_bis) VALUES (?, ?, 0, 0, 0)", playerId, name)
			row = {premium_bis = 0}
		end
		if credits > 0 then
			result.credits = phpSDKCreditsBook(playerId, credits).status == "SUCCESS"
		end
		if vipDays > 0 or vipPermanent then
			local current = tonumber(row.premium_bis) or 0
			local untilTime = (vipPermanent or current == -1) and -1 or math.max(getRealTime().timestamp, current) + vipDays * 86400
			sqlPremium:queryExec("UPDATE `user` SET premium = 1, premium_bis = ? WHERE UserId = ?", untilTime, playerId)
			result.vipUntil = untilTime
		end
	end
	for _, veh in ipairs(type(data.vehicles) == "table" and data.vehicles or {}) do
		local model = math.floor(tonumber(veh.model) or 0)
		if model >= 400 and model <= 611 then
			sqlPremium:queryExec("INSERT INTO premium_veh (Model, abgeholt, Timestamp_buy, Timestamp_abgeholt, Preis, Soundvan, UserId) VALUES (?, 0, UNIX_TIMESTAMP(), 0, 0, ?, ?)", model, (veh.sound == true or veh.sound == 1) and 1 or 0, playerId)
			result.vehicles = result.vehicles + 1
		end
	end
	return result
end

function phpSDKVoucherOffline(adminId, playerId, data)
	playerId = tonumber(playerId)
	if not playerId or not Account.getNameFromId(playerId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local player = Player.getFromId(playerId)
	if player and isElement(player) then return {status = "ERROR", error = "TARGET_ONLINE"} end
	data = type(data) == "table" and data or {}
	local prefix = sql:getPrefix()
	local reason = tostring(data.label or "Gutschein")
	local result = {status = "SUCCESS", items = {}, weapons = {}}
	local money, points = math.floor(tonumber(data.money) or 0), math.floor(tonumber(data.points) or 0)
	if money > 0 then
		local account = BankAccount.loadByOwner(playerId, BankAccountTypes.Player)
		if account then
			account:__giveMoney(money, reason, true)
			account:save()
			StatisticsLogger:getSingleton():addMoneyLogNew(0, BankAccountTypes.Server, 0, account.m_OwnerId, account.m_OwnerType, account.m_Id, money, reason, "ControlPanel", "Gutschein")
		end
		result.money = account and true or false
	end
	if points > 0 then
		result.points = (phpSDKAffected(sql, "UPDATE ??_character SET Points = Points + ? WHERE Id = ?", prefix, points, playerId) or 0) > 0
	end
	local slots = math.floor(tonumber(data.slots) or 21)
	for _, it in ipairs(type(data.items) == "table" and data.items or {}) do
		local name, amount = tostring(it.item or ""), math.floor(tonumber(it.amount) or 0)
		local info = sql:queryFetchSingle("SELECT Tasche, stack_max, max_items FROM ??_inventory_items WHERE Objektname = ?", prefix, name)
		local given = false
		if info and amount > 0 then
			local stackMax = math.max(1, tonumber(info.stack_max) or 1)
			local rows = sql:queryFetch("SELECT id, Objekt, Platz, Menge, Value FROM ??_inventory_slots WHERE PlayerId = ? AND Tasche = ?", prefix, playerId, info.Tasche) or {}
			local total, used, stacks, space = 0, {}, {}, 0
			for _, s in ipairs(rows) do
				used[tonumber(s.Platz)] = true
				if s.Objekt == name then
					total = total + tonumber(s.Menge)
					if tostring(s.Value or "") == "" and tonumber(s.Menge) < stackMax then
						stacks[#stacks + 1] = s
						space = space + stackMax - tonumber(s.Menge)
					end
				end
			end
			local free = {}
			for place = 0, slots - 1 do
				if not used[place] then free[#free + 1] = place end
			end
			if total + amount <= tonumber(info.max_items) and math.ceil(math.max(0, amount - space) / stackMax) <= #free then
				local left = amount
				for _, s in ipairs(stacks) do
					if left <= 0 then break end
					local add = math.min(left, stackMax - tonumber(s.Menge))
					sql:queryExec("UPDATE ??_inventory_slots SET Menge = ? WHERE id = ?", prefix, tonumber(s.Menge) + add, s.id)
					left = left - add
				end
				for _, place in ipairs(free) do
					if left <= 0 then break end
					sql:queryExec("INSERT INTO ??_inventory_slots (PlayerId, Menge, Objekt, Platz, Tasche, Value, WearLevel) VALUES (?, ?, ?, ?, ?, '', 0)", prefix, playerId, math.min(left, stackMax), name, place, info.Tasche)
					left = left - math.min(left, stackMax)
				end
				given = true
			end
		end
		result.items[#result.items + 1] = {item = name, amount = amount, ok = given}
	end
	local weaponList = type(data.weapons) == "table" and data.weapons or {}
	if #weaponList > 0 then
		local row = sql:queryFetchSingle("SELECT GunBox FROM ??_character WHERE Id = ?", prefix, playerId)
		local box = row and row.GunBox and fromJSON(row.GunBox) or {}
		box = type(box) == "table" and box or {}
		local vip = data.vip == true or data.vip == 1
		for _, wp in ipairs(weaponList) do
			local weaponId, ammo = math.floor(tonumber(wp.weapon) or 0), math.floor(tonumber(wp.ammo) or 0)
			local given = false
			if row and weaponId > 0 and weaponId ~= 38 and ammo > 0 then
				for i = 1, 6 do
					local key = tostring(i)
					box[key] = box[key] or {WeaponId = 0, Amount = 0, VIP = i >= 4}
					if not given and tonumber(box[key].WeaponId) == 0 and (not box[key].VIP or vip) then
						box[key].WeaponId, box[key].Amount = weaponId, ammo
						given = true
					end
				end
			end
			result.weapons[#result.weapons + 1] = {weapon = weaponId, ammo = ammo, ok = given}
		end
		if row then
			sql:queryExec("UPDATE ??_character SET GunBox = ? WHERE Id = ?", prefix, toJSON(box), playerId)
		end
	end
	return result
end

function phpSDKModBan(adminId, targetId, action, days, reason)
	targetId, adminId = tonumber(targetId), tonumber(adminId)
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	if action == "add" then
		days = math.floor(tonumber(days) or -1)
		if days < 0 or days > 3650 then return {status = "ERROR", error = "INVALID_DURATION"} end
		ModdingCheck:getSingleton():addBan(targetId, adminId, days, tostring(reason or ""))
	elseif action == "remove" then
		ModdingCheck:getSingleton():removeBan(targetId)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	return {status = "SUCCESS"}
end

function phpSDKPunishEntry(adminId, targetId, action, data)
	targetId, adminId = tonumber(targetId), tonumber(adminId) or 0
	data = type(data) == "table" and data or {}
	if not targetId then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local prefix = sqlLogs:getPrefix()
	if action == "add" then
		local punishType, reason = tostring(data.type or ""), tostring(data.reason or "")
		if punishType == "" or reason == "" then return {status = "ERROR", error = "INVALID"} end
		sqlLogs:queryExec("INSERT INTO ??_Punish (UserId, AdminId, Type, Reason, InternalMessage, Duration, Date) VALUES (?, ?, ?, ?, ?, ?, NOW())",
			prefix, targetId, adminId, punishType, reason, tostring(data.internal or ""), math.max(0, math.floor(tonumber(data.duration) or 0)))
		return {status = "SUCCESS"}
	end
	local row = sqlLogs:queryFetchSingle("SELECT * FROM ??_Punish WHERE Id = ? AND UserId = ?", prefix, tonumber(data.id), targetId)
	if not row then return {status = "ERROR", error = "UNKNOWN_PUNISH"} end
	if action == "edit" then
		local reason, duration, internal = tostring(data.reason or ""), math.max(0, math.floor(tonumber(data.duration) or 0)), tostring(data.internal or "")
		local deletedAt = tostring(data.deletedAt or "")
		sqlLogs:queryExec("UPDATE ??_Punish SET Reason = ?, Duration = ?, InternalMessage = ?, DeletedAt = NULLIF(?, '') WHERE Id = ?", prefix, reason, duration, internal, deletedAt, row.Id)
	elseif action == "purge" then
		sqlLogs:queryExec("DELETE FROM ??_Punish WHERE Id = ?", prefix, row.Id)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	return {status = "SUCCESS"}
end

function phpSDKPlayerHistory(adminId, targetId, action, data)
	targetId = tonumber(targetId)
	data = type(data) == "table" and data or {}
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local prefix = sql:getPrefix()
	if action == "add" then
		if data.type ~= "faction" and data.type ~= "company" then return {status = "ERROR", error = "INVALID_TYPE"} end
		sql:queryExec("INSERT INTO ??_player_history (UserId, InviterId, UninviterId, ElementType, ElementId, InternalReason, ExternalReason, HighestRank, UninviteRank, JoinDate, LeaveDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULLIF(?, ''))",
			prefix, targetId, tonumber(data.inviter) or 0, tonumber(data.uninviter) or 0, data.type, tonumber(data.elementId) or 0, tostring(data.internal or ""), tostring(data.external or ""),
			tonumber(data.highestRank) or 0, tonumber(data.uninviteRank) or 0, tostring(data.join or ""), tostring(data.leave or ""))
		return {status = "SUCCESS"}
	end
	local row = sql:queryFetchSingle("SELECT Id FROM ??_player_history WHERE Id = ? AND UserId = ?", prefix, tonumber(data.id), targetId)
	if not row then return {status = "ERROR", error = "UNKNOWN_ENTRY"} end
	if action == "edit" then
		sql:queryExec("UPDATE ??_player_history SET JoinDate = ?, LeaveDate = NULLIF(?, ''), HighestRank = ?, UninviteRank = ?, ExternalReason = ?, InternalReason = ? WHERE Id = ?",
			prefix, tostring(data.join or ""), tostring(data.leave or ""), tonumber(data.highestRank) or 0, tonumber(data.uninviteRank) or 0, tostring(data.external or ""), tostring(data.internal or ""), row.Id)
	elseif action == "delete" then
		sql:queryExec("DELETE FROM ??_player_history WHERE Id = ?", prefix, row.Id)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	return {status = "SUCCESS"}
end

function phpSDKAntiCheatWhitelist(adminId, targetId, codes)
	targetId = tonumber(targetId)
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local list = {}
	for _, code in ipairs(type(codes) == "table" and codes or {}) do
		if tonumber(code) then list[#list + 1] = math.floor(tonumber(code)) end
	end
	if #list > 0 then
		sql:queryExec("INSERT INTO ??_account_anticheat_whitelist (PlayerId, Bypass) VALUES (?, ?) ON DUPLICATE KEY UPDATE Bypass = VALUES(Bypass)", sql:getPrefix(), targetId, toJSON(list))
	else
		sql:queryExec("DELETE FROM ??_account_anticheat_whitelist WHERE PlayerId = ?", sql:getPrefix(), targetId)
	end
	local anticheat = AntiCheat:getSingleton()
	anticheat.m_AntiCheatWhitelist = {}
	for _, info in pairs(sql:queryFetch("SELECT Serial, Bypass FROM ??_account_anticheat_whitelist w INNER JOIN ??_account_to_serial a on w.PlayerId = a.PlayerId", sql:getPrefix(), sql:getPrefix()) or {}) do
		anticheat.m_AntiCheatWhitelist[info.Serial] = info.Bypass ~= "" and fromJSON(info.Bypass) or {}
	end
	return {status = "SUCCESS"}
end

function phpSDKScreenshotDelete(adminId, ids)
	local deleted = 0
	for _, id in ipairs(type(ids) == "table" and ids or {ids}) do
		if tonumber(id) then
			sql:queryExec("DELETE FROM ??_account_screenshot WHERE Id = ?", sql:getPrefix(), tonumber(id))
			deleted = deleted + 1
		end
	end
	return {status = "SUCCESS", deleted = deleted}
end

function phpSDKAdminLog(adminId, text)
	StatisticsLogger:getSingleton():addAdminAction(tonumber(adminId) or 0, "ControlPanel", tostring(text or ""):sub(1, 255))
	return {status = "SUCCESS"}
end

function phpSDKOrgLimits(adminId, groupType, groupId, players, vehicles, models)
	groupId, players, vehicles = tonumber(groupId), math.floor(tonumber(players) or -1), math.floor(tonumber(vehicles) or -1)
	local tbl = ({faction = "factions", company = "companies"})[groupType]
	if not tbl or not groupId then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	if players < 0 or players > 500 or vehicles < 0 or vehicles > 500 then return {status = "ERROR", error = "INVALID_LIMIT"} end
	local limits = {}
	for model, amount in pairs(type(models) == "table" and models or {}) do
		if tonumber(model) and tonumber(amount) then limits[tostring(math.floor(tonumber(model)))] = math.floor(tonumber(amount)) end
	end
	sql:queryExec("UPDATE ??_" .. tbl .. " SET PlayerLimit = ?, MaxVehicles = ?, VehicleLimits = ? WHERE Id = ?", sql:getPrefix(), players, vehicles, toJSON(limits), groupId)
	return phpSDKOrgReloadLimits(groupType, groupId)
end

function phpSDKFCVehicle(adminId, action, data)
	data = type(data) == "table" and data or {}
	local prefix = sql:getPrefix()
	local ownerType = ({faction = 2, company = 3})[data.groupType]
	local ownerId, id = tonumber(data.groupId), tonumber(data.id) or 0
	if not ownerType or not ownerId then return {status = "ERROR", error = "UNKNOWN_GROUP"} end
	local old = id > 0 and sql:queryFetchSingle("SELECT Id, ShopId, Tunings FROM ??_fc_vehicle_shop_veh WHERE Id = ? AND OwnerType = ? AND OwnerId = ?", prefix, id, ownerType, ownerId)
	if id > 0 and not old then return {status = "ERROR", error = "UNKNOWN_VEHICLE"} end
	if action == "delete" then
		sql:queryExec("DELETE FROM ??_fc_vehicle_shop_veh WHERE Id = ?", prefix, id)
		phpSDKFCShopReload(old.ShopId)
		return {status = "SUCCESS"}
	elseif action ~= "save" then
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	local shopId, model, price = tonumber(data.shop), tonumber(data.model), math.floor(tonumber(data.price) or -1)
	if not shopId or not model or price < 0 then return {status = "ERROR", error = "INVALID"} end
	local handling = tostring(data.handling or "")
	local els = tostring(data.els or "")
	local tunings = old and fromJSON(old.Tunings or "") or nil
	tunings = type(tunings) == "table" and tunings or (type(data.tunings) == "table" and data.tunings or {})
	tunings.Color1, tunings.Color2 = data.color1, data.color2
	if old then
		sql:queryExec("UPDATE ??_fc_vehicle_shop_veh SET ShopId = ?, Model = ?, Price = ?, Description = ?, Handling = NULLIF(?, ''), ELSPreset = NULLIF(?, ''), Tunings = ? WHERE Id = ?",
			prefix, shopId, model, price, tostring(data.description or ""), handling, els, toJSON(tunings), id)
		if tonumber(old.ShopId) ~= shopId then phpSDKFCShopReload(old.ShopId) end
	else
		sql:queryExec("INSERT INTO ??_fc_vehicle_shop_veh (Model, ShopId, Price, Description, OwnerId, OwnerType, Tunings, Handling, ELSPreset) VALUES (?, ?, ?, ?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, ''))",
			prefix, model, shopId, price, tostring(data.description or ""), ownerId, ownerType, toJSON(tunings), handling, els)
	end
	phpSDKFCShopReload(shopId)
	return {status = "SUCCESS"}
end

function phpSDKBadName(adminId, action, id, name)
	id, name = tonumber(id) or 0, tostring(name or "")
	if action == "save" then
		if not name:match("^%*?[%w_]+%*?$") or #name < 2 or #name > 50 then return {status = "ERROR", error = "INVALID_NAME"} end
		if id > 0 then
			sql:queryExec("UPDATE ??_bad_names SET Name = ? WHERE Id = ?", sql:getPrefix(), name, id)
		else
			sql:queryExec("INSERT INTO ??_bad_names (Name) VALUES (?)", sql:getPrefix(), name)
		end
	elseif action == "delete" then
		sql:queryExec("DELETE FROM ??_bad_names WHERE Id = ?", sql:getPrefix(), id)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	return phpSDKReloadBadNames()
end

function phpSDKSetAdminRank(adminId, targetId, rank)
	targetId, rank = tonumber(targetId), tonumber(rank)
	if not targetId or not Account.getNameFromId(targetId) then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	if not rank or rank < 0 then return {status = "ERROR", error = "INVALID_RANK"} end
	local player = Player.getFromId(targetId)
	if player and isElement(player) then return {status = "ERROR", error = "ONLINE"} end
	sql:queryExec("UPDATE ??_account SET `Rank` = ? WHERE Id = ?", sql:getPrefix(), math.floor(rank), targetId)
	return {status = "SUCCESS"}
end

function phpSDKServerSetting(adminId, index, value, desc, reload)
	index = tostring(index or "")
	local row = sql:queryFetchSingle("SELECT Id FROM ??_settings WHERE `Index` = ?", sql:getPrefix(), index)
	if not row then return {status = "ERROR", error = "UNKNOWN_SETTING"} end
	if desc == nil then
		sql:queryExec("UPDATE ??_settings SET Value = ? WHERE Id = ?", sql:getPrefix(), tostring(value or ""), row.Id)
	else
		sql:queryExec("UPDATE ??_settings SET Value = ?, `Desc` = NULLIF(?, '') WHERE Id = ?", sql:getPrefix(), tostring(value or ""), tostring(desc), row.Id)
	end
	if reload == true or reload == 1 then
		return phpSDKReloadServerSettings()
	end
	return {status = "SUCCESS"}
end

function phpSDKModBlacklist(adminId, action, sha256, md5)
	sha256, md5 = tostring(sha256 or ""), tostring(md5 or "")
	if not sha256:match("^%x+$") or #sha256 ~= 64 or not md5:match("^%x+$") or #md5 ~= 32 then return {status = "ERROR", error = "INVALID_HASH"} end
	if action == "block" then
		if not sql:queryFetchSingle("SELECT 1 AS Found FROM ??_mod_blacklist WHERE SHA256 = ? OR MD5 = ?", sql:getPrefix(), sha256, md5) then
			sql:queryExec("INSERT INTO ??_mod_blacklist (SHA256, MD5) VALUES (?, ?)", sql:getPrefix(), sha256, md5)
		end
	elseif action == "unblock" then
		sql:queryExec("DELETE FROM ??_mod_blacklist WHERE SHA256 = ? OR MD5 = ?", sql:getPrefix(), sha256, md5)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	ModdingCheck:getSingleton():loadBans(true)
	return {status = "SUCCESS"}
end

function phpSDKStateEvidenceEdit(adminId, action, id, data)
	id, data = tonumber(id) or 0, type(data) == "table" and data or {}
	local result = {status = "SUCCESS", id = id}
	if action == "delete" then
		sql:queryExec("DELETE FROM ??_state_evidence WHERE Id = ?", sql:getPrefix(), id)
	elseif action == "save" then
		local evidenceType, amount = tostring(data.type or ""), math.floor(tonumber(data.amount) or 0)
		if evidenceType == "" or amount < 1 or amount > 100000 then return {status = "ERROR", error = "INVALID"} end
		if id > 0 then
			sql:queryExec("UPDATE ??_state_evidence SET Type = ?, Object = ?, Amount = ? WHERE Id = ?", sql:getPrefix(), evidenceType, tostring(data.object or ""), amount, id)
		else
			local _, _, insertId = dbPoll(dbQuery(sql.m_DBHandle, "INSERT INTO ??_state_evidence (Type, Object, Amount, UserId, Timestamp) VALUES (?, ?, ?, ?, UNIX_TIMESTAMP())", sql:getPrefix(), evidenceType, tostring(data.object or ""), amount, tonumber(adminId) or 0), -1)
			result.id = insertId
		end
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	if StateEvidence:isInstantiated() then StateEvidence:getSingleton():loadObjectData() end
	return result
end

function phpSDKMultiAccount(adminId, action, id, data)
	id, data = tonumber(id) or 0, type(data) == "table" and data or {}
	if action == "delete" then
		sql:queryExec("DELETE FROM ??_account_multiaccount WHERE ID = ?", sql:getPrefix(), id)
		return {status = "SUCCESS"}
	elseif action ~= "save" then
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	local serial = tostring(data.serial or ""):upper()
	if not serial:match("^%x+$") or #serial ~= 32 then return {status = "ERROR", error = "INVALID_SERIAL"} end
	local linked = {}
	for _, accountId in ipairs(type(data.accounts) == "table" and data.accounts or {}) do
		if tonumber(accountId) then linked[#linked + 1] = math.floor(tonumber(accountId)) end
	end
	if #linked < 2 then return {status = "ERROR", error = "TOO_FEW_ACCOUNTS"} end
	local allow = (data.allowCreate == true or data.allowCreate == 1) and 1 or 0
	if id > 0 then
		sql:queryExec("UPDATE ??_account_multiaccount SET Serial = ?, LinkedTo = ?, allowCreate = ? WHERE ID = ?", sql:getPrefix(), serial, toJSON(linked), allow, id)
	else
		sql:queryExec("INSERT INTO ??_account_multiaccount (Serial, LinkedTo, allowCreate, Admin, Timestamp) VALUES (?, ?, ?, ?, UNIX_TIMESTAMP())", sql:getPrefix(), serial, toJSON(linked), allow, tonumber(adminId) or 0)
	end
	return {status = "SUCCESS"}
end

function phpSDKAdminPoll(adminId, action, data)
	adminId, data = tonumber(adminId), type(data) == "table" and data or {}
	if action == "vote" then
		local pollId = tonumber(data.pollId)
		if not adminId or not pollId then return {status = "ERROR", error = "INVALID"} end
		sql:queryExec("DELETE FROM ??_admin_poll_vote WHERE PollId = ? AND AdminId = ?", sql:getPrefix(), pollId, adminId)
		sql:queryExec("INSERT INTO ??_admin_poll_vote (PollId, AdminId, Vote, CreatedAt) VALUES (?, ?, ?, NOW())", sql:getPrefix(), pollId, adminId, (data.agree == true or data.agree == 1) and 1 or 0)
		return {status = "SUCCESS"}
	elseif action == "finish" then
		sql:queryExec("UPDATE ??_admin_poll SET FinishedAt = NOW(), UpdatedAt = NOW() WHERE FinishedAt IS NULL", sql:getPrefix())
		return {status = "SUCCESS"}
	elseif action == "create" then
		local title = tostring(data.title or "")
		if title == "" then return {status = "ERROR", error = "INVALID"} end
		sql:queryExec("UPDATE ??_admin_poll SET FinishedAt = NOW(), UpdatedAt = NOW() WHERE FinishedAt IS NULL", sql:getPrefix())
		local _, _, insertId = dbPoll(dbQuery(sql.m_DBHandle, "INSERT INTO ??_admin_poll (Title, URL, AdminId, CreatedAt, UpdatedAt) VALUES (?, ?, ?, NOW(), NOW())", sql:getPrefix(), title, tostring(data.url or ""):sub(1, 255), adminId or 0), -1)
		return {status = "SUCCESS", id = insertId}
	end
	return {status = "ERROR", error = "UNKNOWN_ACTION"}
end

local phpSDKMapColumns = {"Type", "Model", "PosX", "PosY", "PosZ", "RotX", "RotY", "RotZ", "ScaleX", "ScaleY", "ScaleZ", "Interior", "Dimension", "Breakable", "Collision", "Doublesided", "Textures", "LodEnabled", "Radius", "Creator"}

function phpSDKMapImport(adminId, data)
	data = type(data) == "table" and data or {}
	local prefix = sql:getPrefix()
	local objects = type(data.objects) == "table" and data.objects or {}
	if #objects == 0 then return {status = "ERROR", error = "NO_OBJECTS"} end
	local mapId = tonumber(data.targetId) or 0
	if mapId > 0 then
		if not sql:queryFetchSingle("SELECT Id FROM ??_map_editor_maps WHERE Id = ?", prefix, mapId) then return {status = "ERROR", error = "UNKNOWN_MAP"} end
		sql:queryExec("DELETE FROM ??_map_editor_objects WHERE MapId = ?", prefix, mapId)
	else
		local name = tostring(data.name or "")
		if #name < 3 or #name > 100 then return {status = "ERROR", error = "INVALID_NAME"} end
		if sql:queryFetchSingle("SELECT Id FROM ??_map_editor_maps WHERE Name = ?", prefix, name) then return {status = "ERROR", error = "NAME_TAKEN"} end
		local _, _, insertId = dbPoll(dbQuery(sql.m_DBHandle, "INSERT INTO ??_map_editor_maps (Name, Creator, SaveObjects, Activated, Deactivatable, Category) VALUES (?, ?, ?, ?, ?, NULLIF(?, ''))", prefix, name,
			tonumber(data.creator) or tonumber(adminId) or 0, tonumber(data.saveObjects) or 1, tonumber(data.activated) or 0, tonumber(data.deactivatable) or 1, tostring(data.category or "")), -1)
		mapId = tonumber(insertId)
		if not mapId then return {status = "ERROR", error = "INSERT_FAILED"} end
	end
	local placeholders = {}
	for i = 1, #phpSDKMapColumns do placeholders[i] = "NULLIF(?, '')" end
	local query = ("INSERT INTO ??_map_editor_objects (MapId, %s) VALUES (?, %s)"):format(table.concat(phpSDKMapColumns, ", "), table.concat(placeholders, ", "))
	for _, object in ipairs(objects) do
		local values = {}
		for i, column in ipairs(phpSDKMapColumns) do
			local value = type(object) == "table" and object[column]
			values[i] = (value == nil or value == false) and "" or tostring(value)
		end
		sql:queryExec(query, prefix, mapId, unpack(values))
	end
	return {status = "SUCCESS", id = mapId, objects = #objects}
end

function phpSDKTexture(adminId, action, data)
	data = type(data) == "table" and data or {}
	local prefix = sql:getPrefix()
	if action == "status" then
		local id, status = tonumber(data.id), tonumber(data.status)
		if not id or not status or status < 0 or status > 3 then return {status = "ERROR", error = "INVALID"} end
		sql:queryExec("UPDATE ??_textureshop SET Status = ?, Admin = ? WHERE Id = ?", prefix, status, tonumber(adminId) or 0, id)
	elseif action == "add" then
		local userId, name, image, model = tonumber(data.userId), tostring(data.name or ""), tostring(data.image or ""), tonumber(data.model) or 0
		if not userId or #name < 3 or #name > 60 or not image:match("^https?://") then return {status = "ERROR", error = "INVALID"} end
		sql:queryExec("INSERT INTO ??_textureshop (UserId, Name, Image, Model, Status, Public, Admin, Date, Earnings) VALUES (?, ?, ?, ?, 0, ?, 0, NOW(), 0)",
			prefix, userId, name, image, model, (data.public == true or data.public == 1) and 1 or 0)
	elseif action == "delete" then
		local id, userId = tonumber(data.id), tonumber(data.userId)
		if not id or not userId then return {status = "ERROR", error = "INVALID"} end
		sql:queryExec("DELETE FROM ??_textureshop WHERE Id = ? AND UserId = ? AND Status <> 2", prefix, id, userId)
	else
		return {status = "ERROR", error = "UNKNOWN_ACTION"}
	end
	return {status = "SUCCESS"}
end

function phpSDKStorageCleanup(adminId, area, file)
	file = tostring(file or "")
	if not file:match("^[%w%.%-_]+$") then return {status = "ERROR", error = "INVALID_FILE"} end
	local result, rows
	if area == "screenshots" then
		result, rows = dbPoll(dbQuery(sql.m_DBHandle, "DELETE FROM ??_account_screenshot WHERE Image = ?", sql:getPrefix(), file), -1)
	elseif area == "textures" then
		result, rows = dbPoll(dbQuery(sql.m_DBHandle, "DELETE FROM ??_textureshop WHERE Image LIKE ?", sql:getPrefix(), "%/uploads/textures/" .. file), -1)
	else
		return {status = "ERROR", error = "UNKNOWN_AREA"}
	end
	return {status = "SUCCESS", deleted = result and tonumber(rows) or 0}
end

local phpSDKEditPlayerColumns = {money = "Money", points = "Points", playTime = "PlayTime", paNote = "PaNote", weaponLevel = "WeaponLevel", vehicleLevel = "VehicleLevel",
	skinLevel = "SkinLevel", jobLevel = "JobLevel", fishingLevel = "FishingLevel", drivingLicense = "HasDrivingLicense", bikeLicense = "HasBikeLicense",
	truckLicense = "HasTruckLicense", pilotsLicense = "HasPilotsLicense"}

function phpSDKEditPlayerOffline(adminId, targetId, action, data)
	targetId, data = tonumber(targetId), type(data) == "table" and data or {}
	local result = function(status, err) return {status = status, error = err} end
	if not targetId then return result("ERROR", "UNKNOWN_PLAYER") end
	local prefix = sql:getPrefix()
	local ownerType = tonumber(data.ownerType) or 1
	if ownerType == 1 then
		local player = Player.getFromId(targetId)
		if player and isElement(player) then return result("ERROR", "TARGET_ONLINE") end
	end
	if action == "stats" then
		for key, column in pairs(phpSDKEditPlayerColumns) do
			local value = data[key]
			if value ~= nil then
				value = (value == true and 1) or (value == false and 0) or tonumber(value)
				if value then sql:queryExec(("UPDATE ??_character SET `%s` = ? WHERE Id = ?"):format(column), prefix, math.floor(value), targetId) end
			end
		end
		if tonumber(data.bank) then
			sql:queryExec("UPDATE ??_bank_accounts SET Money = ? WHERE OwnerType = 1 AND OwnerId = ?", prefix, math.floor(tonumber(data.bank)), targetId)
		end
	elseif action == "weapons" then
		local row = sql:queryFetchSingle("SELECT Weapons FROM ??_character WHERE Id = ?", prefix, targetId)
		local list = row and row.Weapons and fromJSON(row.Weapons) or {}
		list = type(list) == "table" and list or {}
		local keep = {}
		if type(data.give) == "table" then
			local weaponId, ammo = math.floor(tonumber(data.give[1]) or 0), math.floor(tonumber(data.give[2]) or 0)
			for _, w in ipairs(list) do
				if type(w) == "table" and getSlotFromWeapon(tonumber(w[1]) or 0) ~= getSlotFromWeapon(weaponId) then keep[#keep + 1] = w end
			end
			keep[#keep + 1] = {weaponId, ammo}
		elseif not data.all then
			local remove = {}
			for _, id in ipairs(type(data.weapons) == "table" and data.weapons or {}) do remove[tonumber(id) or -1] = true end
			for _, w in ipairs(list) do
				if type(w) == "table" and not remove[tonumber(w[1]) or 0] then keep[#keep + 1] = w end
			end
		end
		sql:queryExec("UPDATE ??_character SET Weapons = ? WHERE Id = ?", prefix, toJSON(keep), targetId)
	elseif action == "vehicle" then
		local vehicleId = tonumber(data.vehicleId)
		local row = vehicleId and sql:queryFetchSingle("SELECT Tunings FROM ??_vehicles WHERE Id = ? AND OwnerType = ? AND OwnerId = ?", prefix, vehicleId, ownerType, targetId)
		if not row then return result("ERROR", "NOT_FOUND") end
		local tunings = row.Tunings and fromJSON(row.Tunings) or {}
		tunings = type(tunings) == "table" and tunings or {}
		tunings.Color1, tunings.Color2 = data.color1, data.color2
		sql:queryExec("UPDATE ??_vehicles SET Model = ?, Fuel = ?, Mileage = ?, Tunings = ? WHERE Id = ?", prefix, tonumber(data.model), tonumber(data.fuel) or 0, tonumber(data.mileage) or 0, toJSON(tunings), vehicleId)
	elseif action == "trunk" then
		local trunk = sql:queryFetchSingle("SELECT t.* FROM ??_vehicles v JOIN ??_vehicle_trunks t ON t.Id = v.TrunkId WHERE v.Id = ? AND v.OwnerType = ? AND v.OwnerId = ?", prefix, prefix, tonumber(data.vehicleId), ownerType, targetId)
		if not trunk then return result("ERROR", "NO_TRUNK") end
		local slot, column, value = math.floor(tonumber(data.slot) or 0), nil, nil
		local decode = function(json) local t = json and fromJSON(json) return type(t) == "table" and t or {} end
		if data.op == "addItem" then
			slot = 0
			for i = 1, 4 do
				local s = decode(trunk["ItemSlot" .. i])
				if slot == 0 and ((s.Item or "none") == "none" or (tonumber(s.Amount) or 0) <= 0) then slot = i end
			end
			if slot == 0 then return result("ERROR", "TRUNK_FULL") end
			column, value = "ItemSlot" .. slot, {Item = tostring(data.item or ""), Amount = math.floor(tonumber(data.amount) or 0), Value = tostring(data.value or "")}
		elseif data.op == "removeItem" and slot >= 1 and slot <= 4 then
			column, value = "ItemSlot" .. slot, {Item = "none", Amount = 0, Value = ""}
		elseif data.op == "addWeapon" then
			slot = 0
			for i = 1, 2 do
				if slot == 0 and (tonumber(decode(trunk["WeaponSlot" .. i]).WeaponId) or 0) == 0 then slot = i end
			end
			if slot == 0 then return result("ERROR", "TRUNK_FULL_WEAPON") end
			column, value = "WeaponSlot" .. slot, {WeaponId = math.floor(tonumber(data.weapon) or 0), Amount = math.floor(tonumber(data.amount) or 0)}
		elseif data.op == "removeWeapon" and slot >= 1 and slot <= 2 then
			column, value = "WeaponSlot" .. slot, {WeaponId = 0, Amount = 0}
		else
			return result("ERROR", "UNKNOWN_ACTION")
		end
		sql:queryExec(("UPDATE ??_vehicle_trunks SET %s = ? WHERE Id = ?"):format(column), prefix, toJSON(value), trunk.Id)
	elseif action == "inventory" then
		local item, amount = tostring(data.item or ""), math.floor(tonumber(data.amount) or 0)
		local info = sql:queryFetchSingle("SELECT Tasche, stack_max, max_items, MaxWear FROM ??_inventory_items WHERE Objektname = ?", prefix, item)
		if not info then return result("ERROR", "UNKNOWN_ITEM") end
		local rows = sql:queryFetch("SELECT id, Platz, Menge FROM ??_inventory_slots WHERE PlayerId = ? AND Objekt = ? ORDER BY Platz", prefix, targetId, item) or {}
		local have, stack = 0, math.max(1, tonumber(info.stack_max) or 1)
		for _, r in ipairs(rows) do have = have + tonumber(r.Menge) end
		if amount > 0 then
			if have + amount > tonumber(info.max_items) then return result("ERROR", "ITEM_MAX") end
			local used, free, space = {}, 0, 0
			for _, r in ipairs(sql:queryFetch("SELECT Platz FROM ??_inventory_slots WHERE PlayerId = ? AND Tasche = ?", prefix, targetId, info.Tasche) or {}) do used[tonumber(r.Platz)] = true end
			for place = 0, 20 do if not used[place] then free = free + 1 end end
			for _, r in ipairs(rows) do space = space + math.max(0, stack - tonumber(r.Menge)) end
			if math.ceil(math.max(0, amount - space) / stack) > free then return result("ERROR", "INVENTORY_FULL") end
			local rest = amount
			for _, r in ipairs(rows) do
				if rest > 0 and tonumber(r.Menge) < stack then
					local add = math.min(stack - tonumber(r.Menge), rest)
					sql:queryExec("UPDATE ??_inventory_slots SET Menge = Menge + ? WHERE id = ?", prefix, add, r.id)
					rest = rest - add
				end
			end
			local wear = (tonumber(info.MaxWear) or 0) > 0 and tostring(math.floor(tonumber(info.MaxWear))) or ""
			for place = 0, 20 do
				if rest > 0 and not used[place] then
					local put = math.min(stack, rest)
					sql:queryExec("INSERT INTO ??_inventory_slots (PlayerId, Objekt, Platz, Menge, Tasche, Value, WearLevel) VALUES (?, ?, ?, ?, ?, '', NULLIF(?, ''))", prefix, targetId, item, place, put, info.Tasche, wear)
					rest = rest - put
				end
			end
		else
			if have < -amount then return result("ERROR", "NOT_ENOUGH") end
			local rest = -amount
			for i = #rows, 1, -1 do
				if rest > 0 then
					local take = math.min(tonumber(rows[i].Menge), rest)
					if take == tonumber(rows[i].Menge) then
						sql:queryExec("DELETE FROM ??_inventory_slots WHERE id = ?", prefix, rows[i].id)
					else
						sql:queryExec("UPDATE ??_inventory_slots SET Menge = Menge - ? WHERE id = ?", prefix, take, rows[i].id)
					end
					rest = rest - take
				end
			end
		end
	elseif action == "gunbox" then
		local slot = math.floor(tonumber(data.slot) or 0)
		if slot < 1 or slot > 6 then return result("ERROR", "UNKNOWN_SLOT") end
		local row = sql:queryFetchSingle("SELECT GunBox FROM ??_character WHERE Id = ?", prefix, targetId)
		local box = row and row.GunBox and fromJSON(row.GunBox) or {}
		box = type(box) == "table" and box or {}
		local weaponId = math.floor(tonumber(data.weapon) or 0)
		box[tostring(slot)] = {WeaponId = weaponId, Amount = weaponId > 0 and math.floor(tonumber(data.amount) or 0) or 0, VIP = slot >= 4}
		sql:queryExec("UPDATE ??_character SET GunBox = ? WHERE Id = ?", prefix, toJSON(box), targetId)
	else
		return result("ERROR", "UNKNOWN_ACTION")
	end
	return result("SUCCESS")
end

function phpSDKGiveQRAchievementOffline(playerId, achievementId)
	playerId, achievementId = tonumber(playerId), tonumber(achievementId)
	if not playerId or not achievementId then return {status = "ERROR", error = "INVALID"} end
	local player = Player.getFromId(playerId)
	if player and isElement(player) then return {status = "ERROR", error = "TARGET_ONLINE"} end
	local row = sql:queryFetchSingle("SELECT Achievements FROM ??_character WHERE Id = ?", sql:getPrefix(), playerId)
	if not row then return {status = "ERROR", error = "UNKNOWN_PLAYER"} end
	local list = row.Achievements and fromJSON(row.Achievements) or nil
	list = type(list) == "table" and list or {["0"] = false}
	if list[tostring(achievementId)] then return {status = "SUCCESS", already = true} end
	list[tostring(achievementId)] = true
	local exp = tonumber((sql:queryFetchSingle("SELECT exp FROM ??_achievements WHERE id = ?", sql:getPrefix(), achievementId) or {}).exp) or 0
	sql:queryExec("UPDATE ??_character SET Achievements = ?, Points = Points + ? WHERE Id = ?", sql:getPrefix(), toJSON(list), exp, playerId)
	return {status = "SUCCESS", already = false}
end
