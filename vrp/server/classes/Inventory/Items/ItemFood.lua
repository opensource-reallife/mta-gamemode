-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemFood.lua
-- *  PURPOSE:     Food Item Super class
-- *
-- ****************************************************************************
ItemFood = inherit(Item)

ItemFood.Settings = {
	["Burger"] = {["Health"] = 40, ["Hunger"] = 40, ["Model"] = 2880, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Pizza"] = {["Health"] = 40, ["Hunger"] = 40, ["Model"] = 2881, ["Text"] = "isst ein Stück %s!", ["Animation"] = {"FOOD", "EAT_PIZZA", 4500}},
	["Pilz"] = {["Health"] = 10, ["Hunger"] = 10, ["Model"] = 1882, ["ModelScale"] = 0.7, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.05, 0, -90, 0}},
	["Zigarette"] = {["Health"] = 0, ["Hunger"] = 0, ["Model"] = 3027, ["Text"] = "raucht eine %s!", ["Animation"] = {"smoking", "M_SMKSTND_LOOP", 11500}, ["Attach"] = {11, 0, 0.07, 0.15, 0, -90, 90}, ["CustomEvent"] = "smokeEffect" },
	["Donut"] = {["Health"] = 30, ["Hunger"] = 30, ["Model"] = 1915, ["ModelScale"] = 1.2, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["Attach"] = {12, 0, 0.05, 0.15, 0, -90, 90}},
	["Keks"] = {["Health"] = 100, ["Hunger"] = 100, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Apfel"] = {["Health"] = 20, ["Hunger"] = 20, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Zombie-Burger"] = {["Health"] = 60, ["Hunger"] = 60, ["Model"] = 2880, ["Text"] = "isst einen %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["CustomEvent"] = "bloodFx"},
	["Kuheuter mit Pommes"] = {["Health"] = 60, ["Hunger"] = 60, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}, ["CustomEvent"] = "bloodFx"},
	["Suessigkeiten"] = {["Health"] = 5, ["Hunger"] = 5, ["Text"] = "nascht leckere %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Zuckerstange"] = {["Health"] = 5, ["Hunger"] = 5, ["Text"] = "nascht eine %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Wuerstchen"] = {["Health"] = 60, ["Hunger"] = 60, ["Text"] = "isst heiße %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["Lebkuchen"] = {["Health"] = 40, ["Hunger"] = 40, ["Text"] = "isst %s!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
	["KöderDummy"] = {["Health"] = 2, ["Hunger"] = 2, ["Text"] = "isst einen Wurm!", ["Animation"] = {"FOOD", "EAT_BURGER", 4500}},
}

function ItemFood:constructor()

end

function ItemFood:destructor()

end

function ItemFood:use(player)
	if player.isTasered then return false end
	if player.m_IsEating then player:sendError(_("Du kannst das gerade nicht tun!", player)) return false end
	if AdminEventManager:getSingleton().m_EventRunning and AdminEventManager:getSingleton().m_CurrentEvent:isPlayerInEvent(player) and getPedArmor(player) == 0 then player:sendError(_("Du hast keine Schutzweste mehr!", player)) return false end
	if player:isInGangwar() and player:getArmor() == 0 then player:sendError(_("Du hast keine Schutzweste mehr!", player)) return false end
	if JobBoxer:getSingleton():isPlayerBoxing(player) == true then player:sendError(_("Du darfst dich während des Boxkampfes nicht heilen!", player)) return false end
	if math.round(math.abs(player.velocity.z*100)) ~= 0 and not player.vehicle then player:sendError(_("Du kannst in der Luft nichts essen!", player)) return false end

	local ItemSettings = ItemFood.Settings[self:getName()]

	player:meChat(true, ItemSettings["Text"], self:getName(), true)
	StatisticsLogger:getSingleton():addHealLog(client, ItemSettings["Health"], "Item "..self:getName())
	
	player:checkLastDamaged() 

	DamageManager:getSingleton():clearPlayer(player)

	local block, animation, time = unpack(ItemSettings["Animation"])
	local item = false
	if not player.vehicle then
		player:setFrozen(true) --prevent the player from running forwards when eating while laying on ground after fall

		if ItemSettings["Model"] then
			item = createObject(ItemSettings["Model"], 0, 0, 0)
			item:setDimension(player:getDimension())
			item:setInterior(player:getInterior())
		
			if ItemSettings["ModelScale"] then item:setScale(ItemSettings["ModelScale"]) end
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
		end)
	end
	setTimer(
		function()
			if isElement(item) then item:destroy() end
			if not isElement(player) or getElementType(player) ~= "player" then return false end
			player:setHealth(player:getHealth()+ItemSettings["Health"])
			player:setHunger(player:getHunger()+ItemSettings["Hunger"])
			player:setAnimation()
			player.m_IsEating = nil
			player:setData("isEating", nil, true)
		end, time, 1
	)

	return true
end
