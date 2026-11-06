-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Shops/ShopManager.lua
-- *  PURPOSE:     Shop Manager Class
-- *
-- ****************************************************************************
ShopManager = inherit(Singleton)
ShopManager.Map = {}
ShopManager.VehicleShopsMap = {}
ShopManager.FCVehicleShopsMap = {}
ShopManager.ShopVehicle = {}

function ShopManager:constructor()
	self:loadShops()
	self:loadVehicleShops()
	self:loadFCVehicleShops()

	addRemoteEvents{"foodShopBuyMenu", "shopBuyItem", "shopBuyWeapon", "shopBuyClothes", "vehicleBuy", "shopOpenGUI", "shopBuy", "shopSell",
	"barBuyDrink", "barShopMusicChange", "barShopMusicStop", "barShopStartStripper", "barShopStopStripper", "shopRestockStart",
	"shopOpenBankGUI", "shopBankDeposit", "shopBankWithdraw", "shopOnTattooSelection", "ammunationBuyItem", "onAmmunationAppOrder", 
	"requestVehicleShops", "editVehicleShop", "onVehicleShopOpen","barRequestShopItems", "barRentStrippers", "buyFCVehicle"}

	addEventHandler("foodShopBuyMenu", root, bind(self.foodShopBuyMenu, self))
	addEventHandler("shopBuyItem", root, bind(self.buyItem, self))
	addEventHandler("shopBuyWeapon", root, bind(self.buyWeaponFromItemShop, self))
	addEventHandler("barBuyDrink", root, bind(self.barBuyDrink, self))
	addEventHandler("vehicleBuy", root, bind(self.vehicleBuy, self))

	addEventHandler("shopBuy", root, bind(self.buy, self))
	addEventHandler("shopSell", root, bind(self.sell, self))
	addEventHandler("shopOpenBankGUI", root, bind(self.openBankGui, self))
	addEventHandler("shopBankDeposit", root, bind(self.deposit, self))
	addEventHandler("shopBankWithdraw", root, bind(self.withdraw, self))
	addEventHandler("shopBuyClothes", root, bind(self.buyClothes, self))

	addEventHandler("shopRestockStart", root, bind(self.restockStart, self))

	addEventHandler("ammunationBuyItem", root, bind(self.buyWeapon, self))
	addEventHandler("onAmmunationAppOrder",root, bind(self.onAmmunationAppOrder, self))

	addEventHandler("shopOnTattooSelection", root, bind(self.onTattooSelection, self))

	addEventHandler("barShopMusicChange", root, bind(self.barMusicChange, self))
	addEventHandler("barShopMusicStop", root, bind(self.barMusicStop, self))
	--addEventHandler("barShopStartStripper", root, bind(self.barStartStripper, self))
	addEventHandler("barShopStopStripper", root, bind(self.barStopStripper, self))
	addEventHandler("barRequestShopItems", root, bind(self.barRequestShopItems, self))
	addEventHandler("barRentStrippers", root, bind(self.barRentStripper, self))
	addEventHandler("requestVehicleShops", root, bind(self.onRequestVehicleShops, self))
	addEventHandler("editVehicleShop", root, bind(self.editShopVehicle, self))
	addEventHandler("buyFCVehicle", root, bind(self.buyFCVehicle, self))
	addEventHandler("shopOpenGUI", root, function(id)
		if ShopManager.Map[id] then
			ShopManager.Map[id]:onItemMarkerHit(client, true)
		else
			client:sendError(_("Invalid Shop ID!", client))
		end
	end)

	addEventHandler("onVehicleShopOpen", root, function() 
		if client and client.m_VehicleShop then 
			client.m_VehicleShop:Event_onShopOpen(client)
		end
	end)
end

function ShopManager:destructor()
	for index, shop in pairs(ShopManager.Map) do
		shop:save()
	end
	for index, shop in pairs(ShopManager.VehicleShopsMap) do
		shop:save()
	end
end

function ShopManager:loadShops()
	local result = sql:queryFetch("SELECT * FROM ??_shops", sql:getPrefix())
    for k, row in ipairs(result) do
		if not SHOP_TYPES[row.Type] then outputDebug("Error Loading Shop ID "..row.Id.." | Invalid Type") return end
		if not SHOP_TYPES[row.Type]["disabled"] then
			--local newName = SHOP_TYPES[row.Type]["Name"].." "..getZoneName(row.PosX, row.PosY, row.PosZ)
			--sql:queryExec("UPDATE ??_shops SET Name = ? WHERE Id = ?", sql:getPrefix(), newName ,row.Id)
			local instance = SHOP_TYPES[row.Type]["Class"]:new(row.Id, row.Name, Vector3(row.PosX, row.PosY, row.PosZ), row.Rot, SHOP_TYPES[row.Type], row.Dimension, row.RobAble, row.Money, row.LastRob, row.Owner, row.Price, row.OwnerType, row.Stock, row.LastRestock)
			ShopManager.Map[row.Id] = instance
			if row.Blip and row.Blip ~= "" then
				local b = instance:addBlip(row.Blip)
				if row.Type == 1 then b:setOptionalColor({252,235,184}) end --Burger Shot
				if row.Type == 2 then b:setOptionalColor({186, 142, 98}) end --Cluckin Bell
				if row.Type == 3 then b:setOptionalColor({170, 150, 100}) end --Pizza Stack
				if row.Type == 4 then b:setOptionalColor({123, 63, 0}) end --Rusty Brown
			end
		end
	end

	self.m_RestockPed = NPC:new(17, 260.78, 10.45, 2.44, 100)
	ElementInfo:new(self.m_RestockPed, "Shop-Lieferant", 1.3)
	self.m_RestockPed:setImmortal(true)
	self.m_RestockPed:setFrozen(true)
	self.m_RestockPed:setData("clickable",true,true)
	addEventHandler("onElementClicked", self.m_RestockPed, function(button, state, player)
		if button == "left" and state == "down" then
			if getDistanceBetweenPoints3D(self.m_RestockPed:getPosition(), player:getPosition()) >= 10 then
				return
			end
			local group = player:getGroup()
			if not group then
				player:sendError(_("Du bist in keiner Gruppe!", player))
				return
			end
			if group:getType() ~= "Firma" then
				player:sendError(_("Du bist in keiner Gruppe mit dem Typ Firma!", player))
				return
			end
			QuestionBox:new(player, _("Möchtest du eine Shop-Lieferung für %d$ starten?", player, SHOP_RESTOCK_COST), "shopRestockStart", nil, false, false, source)
		end
	end)

	self.m_RestockNonCollisionCol = createColSphere(260.78, 10.45, 2.44, 15)
	self.m_RestockNonCollisionCol:setData("NonCollisionArea", {players = true}, true)

	self.m_RestockBlip = Blip:new("RcShop.png", 260.78, 10.45, {groupType = "Firma"})
	self.m_RestockBlip:setDisplayText("Shop-Lieferant", BLIP_CATEGORY.Other)
end

function ShopManager:loadVehicleShops()
	local result = sql:queryFetch("SELECT * FROM ??_vehicle_shops", sql:getPrefix())
    for k, row in ipairs(result) do
		local instance = VehicleShop:new(row.Id, row.Name, row.Marker, row.NPC, row.Spawn, row.Image, row.Owner, row.Price, row.Money, toboolean(row.RandomizeStock))
		ShopManager.VehicleShopsMap[row.Id] = instance
		if row.Blip then
			instance:addBlip(row.Blip)
		end
	end

	local result = sql:queryFetch("SELECT * FROM ??_vehicle_shop_veh", sql:getPrefix())
    for k, row in ipairs(result) do
		if getVehicleType(row.Model) == VehicleType.Automobile or getVehicleType(row.Model) == VehicleType.Bike then
			table.insert(ShopManager.ShopVehicle, row.Model)
		end
		local shop = self:getFromId(row.ShopId, true)
		shop:addVehicle(row.Id, row.Model, row.Name, row.Category, row.Price, row.Level, Vector3(row.X, row.Y, row.Z), Vector3(row.RX, row.RY, row.RZ), row.TemplateId, row.CurrentStock, row.MaxStock)
	end
end

function ShopManager:loadFCVehicleShops()
    local result = sql:queryFetch("SELECT * FROM ??_fc_vehicle_shops", sql:getPrefix())
    for _, row in ipairs(result) do
        local active = false

        if row.Factions and row.Factions ~= "" then
            local factions = fromJSON(row.Factions)
            if factions then
                for _, fid in ipairs(factions) do
                    if FactionManager:getSingleton():getFromId(fid) then
                        active = true
                        break
                    end
                end
            end
        end

        if not active and row.Companies and row.Companies ~= "" then
            local companies = fromJSON(row.Companies)
            if companies then
                for _, cid in ipairs(companies) do
                    if CompanyManager:getSingleton():getFromId(cid) then
                        active = true
                        break
                    end
                end
            end
        end

        if active then
            ShopManager.FCVehicleShopsMap[row.Id] = FCVehicleShop:new(
                row.Id,
                row.Name,
                row.NPC,
                row.VehicleSpawn,
                row.AircraftSpawn,
                row.BoatSpawn,
                row.Factions,
                row.Companies
            )
        end
    end
end

function ShopManager:getFromId(id, vehicle)
	if vehicle == true then
		return ShopManager.VehicleShopsMap[id]
	else
		return ShopManager.Map[id]
	end
end

function ShopManager:onRequestVehicleShops()
	client:triggerEvent("onReceiveVehicleShops", ShopManager.VehicleShopsMap)
end

function ShopManager:vehicleBuy(shopId, vehicleModel, vehicleIndex)
	if client:isDead() then return false end
	if not self:getFromId(shopId, true) then return end
	self:getFromId(shopId, true):buyVehicle(client, vehicleModel, vehicleIndex)
end

function ShopManager:foodShopBuyMenu(shopId, menu)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop.m_Menues[menu] then
		if client:getMoney() >= shop.m_Menues[menu]["Price"] then
			client:setHealth(client:getHealth() + shop.m_Menues[menu]["Health"])
			client:setHunger(client:getHunger() + shop.m_Menues[menu]["Hunger"])
			StatisticsLogger:getSingleton():addHealLog(client, shop.m_Menues[menu]["Health"], "Shop "..shop.m_Menues[menu]["Name"])
			client:checkLastDamaged() 
			local bankServer = BankServer.get("shop.food")
			client:transferMoney(bankServer, shop.m_Menues[menu]["Price"], "Essen", "Gameplay", "Food")
			if shop.m_Stock > 0 then
				bankServer:transferMoney(shop.m_BankAccount, shop.m_Menues[menu]["Price"]*0.8, "Essen", "Gameplay", "Food")
				shop.m_Stock = math.max(0, shop.m_Stock - 1)
			end
			client:sendInfo(_("%s wünscht guten Appetit!", client, _(shop.m_Name, client)))
		else
			client:sendError(_("Du hast nicht genug Geld dabei!", client))
		end
	else
		client:sendError(_("Internal Error! Menu not found!", client))
	end
end

function ShopManager:buyItem(shopId, item, amount)
	if client:isDead() then return false end
	if not item then return end
	if not amount then amount = 1 end
	local shop = self:getFromId(shopId)
	if shop.m_Items[item] then
		if ItemManager:getSingleton():getInstance(item) and ItemManager:getSingleton():getInstance(item).canBuy then
			local state, reason = ItemManager:getSingleton():getInstance(item):canBuy(client, item)
			if not state then
				client:sendError(tostring(reason))
				return false
			end
		end

		if client:getMoney() >= shop.m_Items[item]*amount then
			local value
			if item == "Kanne" then
				value = 10
			elseif item == "Mautpass" then
				value = getRealTime().timestamp + 30*24*60*60
			end

			if client:getInventory():giveItemFromName(item, amount, value) then
				local bankServer = BankServer.get("shop.item")
				client:transferMoney(bankServer, shop.m_Items[item]*amount, "Item-Einkauf", "Gameplay", "Item")
				if shop.m_Stock > 0 then
					bankServer:transferMoney(shop.m_BankAccount, shop.m_Items[item]*amount*0.8, "Item-Einkauf", "Gameplay", "Item")
					shop.m_Stock = math.max(0, shop.m_Stock - amount)
				end
				client:sendInfo(_("%s bedankt sich für deinen Einkauf!", client, shop.m_Name))
			else
				--client:sendError(_("Die maximale Anzahl dieses Items beträgt %d!", client, client:getInventory():getMaxItemAmount(item)))
				return
			end
		else
			client:sendError(_("Du hast nicht genug Geld dabei!", client))
			return
		end
	else
		client:sendError(_("Internal Error! Item not found!", client))
		return
	end
end

function ShopManager:buyClothes(shopId, typeId, clotheId)
	if client:isDead() then return false end
	if not typeId then return end
	if not clotheId then return end
	local shop = self:getFromId(shopId)
	local clothesData = CJ_CLOTHES[CJ_CLOTHE_TYPES[typeId]][clotheId]
	if shop then
		if clothesData then
			if client:getMoney() >= clothesData.Price then
				client:removeClothesPermanently(typeId)
				if clotheId >= 0 then
					local texture, model = getClothesByTypeIndex(typeId, clotheId)
					client:addClothesPermanently(texture, model, typeId)
				end
				client:giveAchievement(23)
				client:sendInfo(_("%s bedankt sich für deinen Einkauf!", client, _(shop.m_Name, client)))
				if clothesData.Price > 0 then
					client:transferMoney(shop.m_BankAccount, clothesData.Price, "Kleidungs-Kauf", "Gameplay", "Clothes")
				end
			else
				client:sendError(_("Du hast nicht genug Geld dabei!", client))
				return
			end
		else
			client:sendError(_("Internal Error! Clothe not found!", client))
			return
		end
	else
		client:sendError(_("Internal Error! Shop not found!", client))
		return
	end
end

function ShopManager:buyWeaponFromItemShop(shopId, weaponId)
	if client:isDead() then return false end
	if not weaponId then return end
	local shop = self:getFromId(shopId)
	if shop then
		if MIN_WEAPON_LEVELS[weaponId] <= client:getWeaponLevel() then
			local price = shop.m_WeaponItems[weaponId]

			if client:getMoney() >= price then
				local ammo = 20 --getWeaponProperty(weaponId, "pro", "maximum_clip_ammo") or 1 doesn't work with the camera, at least not for me - MasterM

				if not client:getInventory():canCarryWeapon(weaponId, ammo) then
					client:sendError(_("Das ist zu schwer für dich!", client))
					return
				end

				if client:getWeapon(getSlotFromWeapon(weaponId)) == 0 then
					client:giveWeapon(weaponId, ammo)
					reloadPedWeapon(client)

					StatisticsLogger:addAmmunationLog(client, "Shop", toJSON({[weaponId] = ammo}), price)
					local bankServer = BankServer.get("shop.item")
					client:transferMoney(bankServer, price, "Shop-Einkauf", "Gameplay", "Weapon")
					if shop.m_Stock > 0 then
						bankServer:transferMoney(shop.m_BankAccount, price*0.8, "Shop-Einkauf", "Gameplay", "Weapon")
						shop.m_Stock = math.max(0, shop.m_Stock - 1)
					end
					client:sendInfo(_("%s bedankt sich für deinen Einkauf!", client, _(shop.m_Name, client)))
				else
					client:sendError(_("Du hast bereits ein/e(n) %s auf dem Platz der/des %s!", client, WEAPON_NAMES[client:getWeapon(getSlotFromWeapon(weaponId))], WEAPON_NAMES[weaponId]))
				end
			else
				client:sendError(_("Du hast nicht genug Geld dabei!", client))
				return
			end
		else
			client:sendError(_("Dein Waffenlevel ist zu niedrig!",client))
		end
	else
		client:sendError(_("Internal Error! Shop not found!", client))
		return
	end
end

function ShopManager:buyWeapon(shopId, itemType, weaponId, amount)
	if client:isDead() then return false end
	if not itemType then return end
	if not weaponId then return end
	if amount <= 0 then return end
	local shop = self:getFromId(shopId)
	if shop then
		if MIN_WEAPON_LEVELS[weaponId] <= client:getWeaponLevel() then
			local price
			if itemType == "Weapon" or itemType == "Vest" then
				price = shop.m_Weapons[weaponId]
				amount = 1
			elseif itemType == "Magazine" then
				if not hasPedThisWeaponInSlots(client, weaponId) then
					client:sendError(_("Du hast nicht die passende Waffe für diese Munition!", client))
					return false
				end
				price = shop.m_Magazines[weaponId].price*amount
			end
			if client:getMoney() >= price then
				local weaponAmount = shop.m_Magazines[weaponId] and shop.m_Magazines[weaponId].amount*amount or 1
				if itemType ~= "Vest" and not client:getInventory():canCarryWeapon(weaponId, weaponAmount) then
					client:sendError(_("Das ist zu schwer für dich!", client))
					return
				end

				if itemType == "Vest" then
					client:setArmor(100)
				else
					client:giveWeapon(weaponId, weaponAmount)
					reloadPedWeapon(client)
				end

				StatisticsLogger:addAmmunationLog(client, "Shop", toJSON({[weaponId] = weaponAmount}), price)
				client:transferMoney(shop.m_BankAccount, price, "Ammu-Nation Einkauf", "Gameplay", "Weapon")
			else
				client:sendError(_("Du hast nicht genug Geld dabei!", client))
				return
			end
		else
			client:sendError(_("Dein Waffenlevel ist zu niedrig!",client))
		end
	else
		client:sendError(_("Internal Error! Shop not found!", client))
		return
	end
end

function ShopManager:onTattooSelection(shopId, typeId)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:onTattoSelection(client, typeId)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
		return
	end
end

function ShopManager:barBuyDrink(shopId, item, amount)
	if client:isDead() then return false end
	if not item then return end
	if not amount then amount = 1 end
	local shop = self:getFromId(shopId)
	if shop.m_Items[item] then
		if client:getMoney() >= shop.m_Items[item]*amount then
			local bankServer = BankServer.get("shop.bar")
			client:transferMoney(bankServer, shop.m_Items[item]*amount, "Item-Einkauf", "Gameplay", "Item")
			if shop.m_Stock > 0 then
				bankServer:transferMoney(shop.m_BankAccount, shop.m_Items[item]*amount*0.8, "Item-Einkauf", "Gameplay", "Item")
				shop.m_Stock = math.max(0, shop.m_Stock - amount)
			end
			client:sendInfo(_("%s bedankt sich für deinen Einkauf!", client, _(shop.m_Name, client)))

			local instance = ItemManager.Map[item]
			if instance.use then
				if instance:use(client, itemId, bag, place, item) == false then
					return false
				end
			end
		else
			client:sendError(_("Du hast nicht genug Geld dabei!", client))
			return
		end
	else
		client:sendError(_("Internal Error! Item not found!", client))
		return
	end
end

function ShopManager:barMusicChange(shopId, stream)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:changeMusic(client, stream)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:barMusicStop(shopId)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:stopMusic(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

--[[function ShopManager:barStartStripper(shopId)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:startStripper(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end]]

function ShopManager:barRentStripper(shopId, minutes)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:rentStrippers(client, minutes)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:barStopStripper(shopId)
	if client:isDead() then return false end
	local shop = self:getFromId(shopId)
	if shop then
		shop:stopStripper(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:barRequestShopItems(shopId)
	local shop = self:getFromId(shopId)
	if shop then
		shop:requestBarShopItems(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:buy(shopId)
	local shop = self:getFromId(shopId)
	if shop then
		shop:buy(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:sell(shopId)
	local shop = self:getFromId(shopId)
	if shop then
		shop:sell(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:deposit(amount, shopId)
	local shop = self:getFromId(shopId)
	if shop then
    	if not amount then return end

		if client:getMoney() < amount then
			client:sendError(_("Du hast nicht genügend Geld!", client))
			return
		end

		client:transferMoney(shop.m_BankAccount, amount, "Shop-Einlage", "Shop", "Deposit")
		shop.m_Owner:addLog(client, "Kasse", "hat "..toMoneyString(amount).." in die Shop-Kasse gelegt! ("..shop:getName()..")")
		shop:refreshBankGui(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:withdraw(amount, shopId)
	local shop = self:getFromId(shopId)
	if shop then
		if not amount then return end

		if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "group", "withdrawBIZMoney") then
			client:sendError(_("Du bist nicht berechtigt Geld von Shops abzuheben!", client))
			-- Todo: Report possible cheat attempt
			return
		end

		if shop:getMoney() < amount then
			client:sendError(_("In der Shop-Kasse befindet sich nicht genügend Geld!", client))
			return
		end

		shop.m_BankAccount:transferMoney(client, amount, "Shop-Auslage", "Shop", "Deposit")
		shop.m_Owner:addLog(client, "Kasse", "hat "..toMoneyString(amount).." aus der Shop-Kasse genommen! ("..shop:getName()..")")
		shop:refreshBankGui(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:openBankGui(shopId)
	local shop = self:getFromId(shopId)
	if shop then
		shop:openBankGui(client)
	else
		client:sendError(_("Internal Error! Shop not found!", client))
	end
end

function ShopManager:getPlayerWeapons(player)
	local playerWeapons = {}
	for i=1, 12 do
		if getPedWeapon(player,i) > 0 then
			playerWeapons[getPedWeapon(player,i)] = true
		end
	end
	return playerWeapons
end

function ShopManager:onAmmunationAppOrder(weaponTable)
	if client:getInterior() > 0 or client:getDimension() > 0 or client.m_JailTime > 0 or client:getData("inAdminPrison") then
		client:sendError(_("Du kannst hier nicht bestellen!",client))
		return
	end

	local totalAmount = 0
	local canBuyWeapons = true
	for weaponID,v in pairs(weaponTable) do
		for typ,amount in pairs(weaponTable[weaponID]) do
			if amount > 0 then
				if typ == "Waffe" then
					totalAmount = totalAmount + AmmuNationInfo[weaponID].Weapon * amount
				elseif typ == "Munition" then
					totalAmount = totalAmount + AmmuNationInfo[weaponID].Magazine.price * amount
				end
				if client:getWeaponLevel() < MIN_WEAPON_LEVELS[weaponID] then
					canBuyWeapons = false
				end
			end
		end
	end
	if canBuyWeapons then
		totalAmount = totalAmount * AMMUNATION_APP_MULTIPLICATOR
		if client:getBankMoney() >= totalAmount then
			if totalAmount > 0 then
				client:transferBankMoney(BankServer.get("shop.ammunation"), totalAmount, "Ammu-Nation Bestellung", "Shop", "Ammunation")
				StatisticsLogger:getSingleton():addAmmunationLog(client, "Bestellung", toJSON(weaponTable), totalAmount)
				self:createOrder(client, weaponTable)
			else
				client:sendError(_("Du hast keine Artikel im Warenkorb!",client))
			end
		else
			client:sendError(_("Du hast nicht ausreichend Geld auf deinem Bankkonto! (%d$)",client, totalAmount))
		end
	else
		-- Possible Cheat attempt?
		client:sendError(_("An Internal Error occured!", client))
	end
end

function ShopManager:createOrder(player, weaponTable)
	local x, y, z = getElementPosition ( player )
	y = y - 2
	x = x - 2
	local dropObject = createObject ( 2903, x, y, z+6.3+15 )
	setElementCollisionsEnabled(dropObject, false)
	moveObject(dropObject, 9000, x, y, z+6.3 )
	setTimer(destroyElement, 10000, 1, dropObject )
	local order = self:prepareOrder(weaponTable)
	setTimer(function(x, y, z)
		local crate = createObject(3014, x, y, z)
		setElementCollisionsEnabled(crate, false)
		setElementData(crate, "pickupSpin", true)
		local pickup = createColSphere(x, y, z, 1)
		addEventHandler("onColShapeHit", pickup, function(hitElement, matchingDimension)
			if matchingDimension and getElementType(hitElement) == "player" and not hitElement:getOccupiedVehicle() then
				local taken = self:giveWeaponsFromOrder(hitElement, order)
				if next(taken) then
					StatisticsLogger:getSingleton():addAmmunationLog(hitElement, "Pickup", toJSON(taken), 0)
				end
				if not next(order) then
					destroyElement(crate)
					destroyElement(pickup)
				end
			end
		end)
		setTimer(function()
			if isElement(pickup) then
				destroyElement(crate)
				destroyElement(pickup)
				if isElement(player) then
					player:sendWarning(_("Der Rest deiner Ammu-Nation Bestellung ist verschwunden!", player))
				end
			end
		end, 30 * 60 * 1000, 1)
	end, 10000, 1, x, y, z)
end

function ShopManager:prepareOrder(weaponTable)
	local order = {}
	for weaponID, entry in pairs(weaponTable) do
		local weapons, magazines = entry["Waffe"] or 0, entry["Munition"] or 0
		if weaponID == 0 then
			if weapons > 0 then
				order[weaponID] = {weapon = true, rounds = 0}
			end
		elseif weapons > 0 or magazines > 0 then
			local mag = getWeaponProperty(weaponID, "pro", "maximum_clip_ammo") or 1
			order[weaponID] = {
				weapon = weapons > 0 and not THROWABLE_WEAPONS[weaponID],
				rounds = NO_MUNITION_WEAPONS[weaponID] and 0 or math.floor(((weapons > 0 and 1 or 0) + magazines) * mag)
			}
		end
	end
	return order
end

function ShopManager:giveWeaponsFromOrder(player, order)
	local manager = InventoryManager:getSingleton()
	local inventory = player:getInventory()
	local context = isInventoryWeaponContext(player)
	local free = (not context or inventory:getDutyValue()) and math.huge or inventory:getFreeCarryWeight()
	local playerWeapons = self:getPlayerWeapons(player)
	local received, left, taken = {}, {}, {}

	local getWeight = function(itemName)
		return itemName and manager:getItemDataForItem(itemName)["Gewicht"] or 0
	end

	for weaponID, entry in pairs(order) do
		if weaponID == 0 then
			player:setArmor(100)
			received[#received + 1] = _("1 Schutzweste", player)
			taken[weaponID] = {Waffe = 1}
			order[weaponID] = nil
		else
			local name = WEAPON_NAMES[weaponID]
			local throwable = THROWABLE_WEAPONS[weaponID]
			local weaponWeight = getWeight(manager:getWeaponItemName(weaponID))
			local unitWeight = throwable and weaponWeight or getWeight(manager:getAmmoItemName(weaponID))
			local hasWeapon = playerWeapons[weaponID] or (context and inventory:hasWeapon(weaponID))
			local giveNow = entry.weapon and not hasWeapon and weaponWeight <= free + 0.0001
			local rounds = 0

			if giveNow then
				free = free - weaponWeight
			end
			if throwable or hasWeapon or giveNow then
				rounds = entry.rounds
				if unitWeight > 0 then
					rounds = math.max(0, math.min(rounds, math.floor((free + 0.0001) / unitWeight)))
				end
				free = free - unitWeight * rounds
			end

			if giveNow or rounds > 0 then
				giveWeapon(player, weaponID, NO_MUNITION_WEAPONS[weaponID] and 1 or rounds)
				taken[weaponID] = {Waffe = giveNow and 1 or 0, Schuss = rounds}
			end
			if giveNow then
				entry.weapon = false
				received[#received + 1] = _("1 %s", player, name)
			end
			if rounds > 0 then
				entry.rounds = entry.rounds - rounds
				received[#received + 1] = throwable and _("%d %s", player, rounds, name) or _("%d Schuss %s", player, rounds, name)
			end

			if entry.weapon then
				left[#left + 1] = hasWeapon and _("1 %s (du hast bereits eine)", player, name) or _("1 %s (zu schwer)", player, name)
			end
			if entry.rounds > 0 then
				if throwable then
					left[#left + 1] = _("%d %s (zu schwer)", player, entry.rounds, name)
				else
					left[#left + 1] = (hasWeapon or giveNow) and _("%d Schuss %s (zu schwer)", player, entry.rounds, name) or _("%d Schuss %s (du hast keine passende Waffe)", player, entry.rounds, name)
				end
			end
			if not entry.weapon and entry.rounds <= 0 then
				order[weaponID] = nil
			end
		end
	end

	if #received > 0 then
		player:sendSuccess(_("Du hast erhalten: %s", player, table.concat(received, ", ")))
	end
	if #left > 0 and (#received > 0 or getTickCount() - (player.m_LastOrderNotice or -5000) >= 5000) then
		player.m_LastOrderNotice = getTickCount()
		player:sendError(_("Das bleibt hier liegen: %s", player, table.concat(left, ", ")))
	end
	return taken
end

function ShopManager:editShopVehicle( shop, model, index, property, value) 
	if ShopManager.VehicleShopsMap[shop] and ShopManager.VehicleShopsMap[shop].m_VehicleList[model] and ShopManager.VehicleShopsMap[shop].m_VehicleList[model][index] then
		ShopManager.VehicleShopsMap[shop]:setProperty(model, index, property, value, client)
		client:triggerEvent("onReceiveVehicleShops", ShopManager.VehicleShopsMap)
	else 
		client:sendError(_("Ein Fehler ist aufgetreten, Fahrzeug nicht gefunden!", client))
	end
end

function ShopManager:buyFCVehicle(shop, vehicleId)
	ShopManager.FCVehicleShopsMap[shop]:buyVehicle(client, vehicleId)
end

function ShopManager:restockStart()
	local player = source
	if getDistanceBetweenPoints3D(self.m_RestockPed:getPosition(), player:getPosition()) >= 10 then
		player:sendError(_("Du bist zu weit entfernt!", player))
		return
	end
	local group = player:getGroup()
	if not group then
		player:sendError(_("Du bist in keiner Gruppe!", player))
		return
	end
	if group:getType() ~= "Firma" then
		player:sendError(_("Du bist in keiner Gruppe mit dem Typ Firma!", player))
		return
	end
	if isElement(player.m_RestockVehicle) then
		player:sendError(_("Du belieferst aktuell schon ein Geschäft!", player))
		return
	end
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "group", "restockBIZ") then
		player:sendError(_("Dazu bist du nicht berechtigt!", player))
		return
	end
	if player:isFactionDuty() or player:isCompanyDuty() then
		player:sendError(_("Du darfst nicht im Dienst sein!", player))
		return
	end
	if player:isInVehicle() then
		player:sendError(_("Steige zuerst aus deinem Fahrzeug aus!", player))
		return
	end
	for i, shop in pairs(group:getShops()) do
		if shop.m_Stock < 100 then
			if group:getMoney() >= SHOP_RESTOCK_COST then
				local vehicle = TemporaryVehicle.create(440, 264.06, 15.09, 2.56, 100)
				player.m_RestockVehicle = vehicle
				vehicle.m_RestockVehicle = true
				player:warpIntoVehicle(vehicle)
				vehicle:addCountdownDestroy(10)
				addEventHandler("onVehicleStartEnter", vehicle, function(vehPlayer, seat)
					if seat == 0 and vehPlayer ~= player then
						vehPlayer:sendError(_("Du kannst nicht in dieses Fahrzeug einsteigen!", vehPlayer))
						cancelEvent()
					end
				end)
				group:transferMoney(BankServer.get("gameplay.shop_restock"), SHOP_RESTOCK_COST, "Shop-Lieferung", "Shop", "Restock")
				group:sendShortMessage(("%s hat eine Shop-Lieferung für %s gestartet!"):format(player:getName(), toMoneyString(SHOP_RESTOCK_COST)))
				group:addLog(player, "Immobilien", ("hat eine Shop-Lieferung für %s gestartet!"):format(toMoneyString(SHOP_RESTOCK_COST)))
				return
			else
				player:sendError(_("In der Gruppenkasse befindet sich nicht genügend Geld!", player))
			end
		end
	end
	player:sendError(_("Es gibt aktuell kein Geschäft, welches beliefert werden kann!", player))
end