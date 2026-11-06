-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemFood.lua
-- *  PURPOSE:     Food Item Super class
-- *
-- ****************************************************************************
ItemFood = inherit(Item)

function ItemFood:constructor()

end

function ItemFood:destructor()

end

function ItemFood:use(player)
	if player.isTasered or player.m_IsEating or JobBoxer:getSingleton():isPlayerBoxing(player) or player:isFrozen() then
		player:sendError(_("Du kannst das gerade nicht tun!", player))
		return false
	end

	local velX, velY, velZ = getElementVelocity(player)
	if math.round(math.abs((velX + velY + velZ) * 100)) ~= 0 and not player.vehicle then
		player:sendError(_("Du darfst dich nicht bewegen!", player))
		return false
	end

	local itemData = InventoryManager:getSingleton():getItemDataForItem(self:getName())
	local ItemSettings = itemData and itemData["Effekte"]
	if not ItemSettings then return false end

	if ItemSettings["Health"] and ItemSettings["Health"] > 0 then
		if (player:isInGangwar() or AdminEventManager:getSingleton().m_EventRunning and AdminEventManager:getSingleton().m_CurrentEvent:isPlayerInEvent(player)) and player:getArmor() == 0 then
			player:sendError(_("Du hast keine Schutzweste mehr!", player))
			return false
		end
	end
	
	if ItemSettings["Text"] then
		player:meChat(true, ItemSettings["Text"], self:getName(), true)
	end

	local block, animation, time = unpack(ItemSettings["Animation"] or {"FOOD", "EAT_BURGER", 4500})
	local item = false
	if not player.vehicle then
		player:setFrozen(true) --prevent the player from running forwards while laying on ground after fall

		if ItemSettings["Model"] then
			item = createObject(3027, 0, 0, 0)
			item:setDimension(player:getDimension())
			item:setInterior(player:getInterior())
		end

		if ItemSettings["CustomEvent"] then
			triggerClientEvent(ItemSettings["CustomEvent"], player, item)
		end

		nextframe(function() 
			player:setFrozen(false)
			player:setAnimation(block, animation, time, true, false, false)
			player.m_IsEating = true
			player:setData("isEating", true, true)
			if isElement(item) then
				item:setPosition(player:getPosition())
				item:setModel(ItemSettings["Model"])
				if ItemSettings["ModelScale"] then item:setScale(unpack(ItemSettings["ModelScale"])) end
				if ItemSettings["Attach"] then
					exports.bone_attach:attachElementToBone(item, player, unpack(ItemSettings["Attach"]))
				else
					exports.bone_attach:attachElementToBone(item, player, 12, 0, 0, 0, 0, -90, 0)
				end
			end
		end)
	end

	setTimer(function()
		if isElement(item) then item:destroy() end
		if not isElement(player) or getElementType(player) ~= "player" then return false end

		if ItemSettings["Alcohol"] and ItemSettings["Alcohol"] > 0 then
			player:incrementAlcoholLevel(ItemSettings["Alcohol"])
		end

		if ItemSettings["Health"] and ItemSettings["Health"] > 0 then
			player:setHealth(player:getHealth()+ItemSettings["Health"])
			StatisticsLogger:getSingleton():addHealLog(player, ItemSettings["Health"], "Item "..self:getName())
			player:checkLastDamaged() 
			DamageManager:getSingleton():clearPlayer(player)
		end

		if ItemSettings["GiveItem"] and player:getInventory():giveItemFromName(ItemSettings["GiveItem"], 1) then
			player:sendInfo(_("Du hast %s erhalten!", player, ItemSettings["GiveItem"]))
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
