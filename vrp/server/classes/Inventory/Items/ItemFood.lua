-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemFood.lua
-- *  PURPOSE:     Food Item Super class
-- *
-- ****************************************************************************
ItemFood = inherit(Item)

ItemFood.Settings = {
	-- Food
	["Burger"] = {["Health"] = 40, ["Hunger"] = 40, ["Model"] = 2880, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Pizza"] = {["Health"] = 40, ["Hunger"] = 40, ["Model"] = 2881, ["Text"] = "isst ein Stück %s!", ["Animation"] = {"FOOD", "EAT_PIZZA", 4500}},
	["Pilz"] = {["Health"] = 10, ["Hunger"] = 10, ["Model"] = 1882, ["ModelScale"] = {0.7}, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.05, 0, -90, 0}},
	["Zigarette"] = {["Health"] = 0, ["Hunger"] = 0, ["Model"] = 3027, ["Text"] = "raucht eine %s!", ["Animation"] = {"smoking", "M_SMKSTND_LOOP", 11500}, ["Attach"] = {11, 0, 0.07, 0.15, 0, -90, 90}, ["CustomEvent"] = "smokeEffect" },
	["Donut"] = {["Health"] = 30, ["Hunger"] = 30, ["Model"] = 1915, ["ModelScale"] = {1.2}, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.15, 0, -90, 90}},
	["Keks"] = {["Health"] = 100, ["Hunger"] = 100, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Apfel"] = {["Health"] = 20, ["Hunger"] = 20, ["Model"] = 3105, ["ModelScale"] = {1.4}, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.08, 0, -90, 90}},
	["Zombie-Burger"] = {["Health"] = 60, ["Hunger"] = 60, ["Model"] = 2880, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["CustomEvent"] = "bloodFx"},
	["Kuheuter mit Pommes"] = {["Health"] = 60, ["Hunger"] = 60, ["Model"] = 2806, ["ModelScale"] = {0.2, 0.1, 0.55}, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}, ["CustomEvent"] = "bloodFx"},
	["Suessigkeiten"] = {["Health"] = 5, ["Hunger"] = 5, ["Text"] = "nascht leckere %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Zuckerstange"] = {["Health"] = 5, ["Hunger"] = 5, ["Text"] = "nascht eine %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Wuerstchen"] = {["Health"] = 60, ["Hunger"] = 60, ["Model"] = 3103, ["ModelScale"] = {2.5, 0.5, 0.5}, ["Text"] = "isst heiße %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, -0.015, 0.03, 0.1, 0, 0, 0}},
	["Lebkuchen"] = {["Health"] = 40, ["Hunger"] = 40, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["KöderDummy"] = {["Health"] = 2, ["Hunger"] = 2, ["Text"] = "isst einen Wurm!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Frittiertes Hähnchen"] = {["Health"] = 50, ["Hunger"] = 50, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Pommes"] = {["Health"] = 5, ["Hunger"] = 5, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	-- Alcohol
	["Bier"] = {["Health"] = 0, ["Model"] = 1486, ["Text"] = "trinkt ein %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 0.25, ["Attach"] = {12, -0.05, 0.05, 0.09, 0, -90, 0}},
	["Whiskey"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 1.2, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Sex on the Beach"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 0.5, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Pina Colada"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 0.7, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Monster"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 2.1, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Shot"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 1.4, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Cuba-Libre"] = {["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 0.8, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
	["Gluehwein"] =	{["Health"] = 0, ["Model"] = 1455, ["Text"] = "trinkt einen %s!", ["Animation"] = {"BAR", "dnk_stndM_loop", 4500}, ["Alcohol"] = 0.4, ["Attach"] = {12, 0, 0.05, 0.1, 0, -90, 0}},
}

function ItemFood:constructor()

end

function ItemFood:destructor()

end

function ItemFood:use(player)
	if player.isTasered or player.m_IsEating or JobBoxer:getSingleton():isPlayerBoxing(player) then
		player:sendError(_("Du kannst das gerade nicht tun!", player))
		return false
	end

	local velX, velY, velZ = getElementVelocity(player)
	if math.round(math.abs((velX + velY + velZ) * 100)) ~= 0 and not player.vehicle then
		player:sendError(_("Du darfst dich nicht bewegen!", player))
		return false
	end

	if (player:isInGangwar() or AdminEventManager:getSingleton().m_EventRunning and AdminEventManager:getSingleton().m_CurrentEvent:isPlayerInEvent(player)) and player:getArmor() == 0 then
		player:sendError(_("Du hast keine Schutzweste mehr!", player))
		return false
	end

	local ItemSettings = ItemFood.Settings[self:getName()]

	player:meChat(true, ItemSettings["Text"], self:getName(), true)
	if ItemSettings["Health"] and ItemSettings["Health"] > 0 then
		StatisticsLogger:getSingleton():addHealLog(client, ItemSettings["Health"], "Item "..self:getName())
		player:checkLastDamaged() 
		DamageManager:getSingleton():clearPlayer(player)
	end

	local block, animation, time = unpack(ItemSettings["Animation"])
	local item = false
	if not player.vehicle then
		player:setFrozen(true) --prevent the player from running forwards while laying on ground after fall

		if ItemSettings["Model"] then
			item = createObject(3027, 0, 0, 0)
			item:setDimension(player:getDimension())
			item:setInterior(player:getInterior())
		
			if ItemSettings["ModelScale"] then item:setScale(unpack(ItemSettings["ModelScale"])) end
			if ItemSettings["Attach"] then
				exports.bone_attach:attachElementToBone(item, player, unpack(ItemSettings["Attach"]))
			else
				exports.bone_attach:attachElementToBone(item, player, 12, 0, 0, 0, 0, -90, 0)
			end
		end

		if ItemSettings["CustomEvent"] then
			triggerClientEvent(ItemSettings["CustomEvent"], player, item)
		end

		nextframe(function() 
			player:setFrozen(false)
			player:setAnimation(block, animation, time, true, false, false)
			player.m_IsEating = true
			player:setData("isEating", true, true)
			if item then item:setModel(ItemSettings["Model"]) end
		end)
	end

	setTimer(function()
		if isElement(item) then item:destroy() end
		if not isElement(player) or getElementType(player) ~= "player" then return false end

		if ItemSettings["Alcohol"] and ItemSettings["Alcohol"] > 0 then
			player:incrementAlcoholLevel(ItemSettings["Alcohol"])
			if self:getName() == "Bier" then
				if player:getInventory():giveItem("Flasche", 1) then
					player:sendInfo(_("Du hast eine leere Flasche erhalten!", player))
				end
			end
		end

		if ItemSettings["Health"] and ItemSettings["Health"] > 0 then
			player:setHealth(player:getHealth()+ItemSettings["Health"])
		end

		if ItemSettings["Hunger"] and ItemSettings["Hunger"] > 0 then
			player:setHunger(player:getHunger()+ItemSettings["Hunger"])
		end

		player:setAnimation()
		player.m_IsEating = nil
		player:setData("isEating", nil, true)
	end, time, 1)

	return true
end
