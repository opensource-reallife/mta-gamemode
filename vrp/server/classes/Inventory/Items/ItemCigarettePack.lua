-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/Items/ItemCigarettePack.lua
-- *  PURPOSE:     Item Cigarette Pack Class
-- *
-- ****************************************************************************
ItemCigarettePack = inherit(Item)

function ItemCigarettePack:constructor()
end

function ItemCigarettePack:destructor()
end

function ItemCigarettePack:use(player, itemId, bag, place, itemName)
	local inventory = player:getInventory()
	local cigarettesLeft = (tonumber(player:getInventory():getItemValueByBag(bag, place)) or 20) - 1

	if ItemManager.Map["Zigarette"]:use(player) then
		player:sendMessage(_("#4F4F65%d/20 Zigaretten übrig!", player, cigarettesLeft))
		
		player.m_LessHunger = true
		if isTimer(player.m_CigaretteEffectExpire) then player.m_CigaretteEffectExpire:destroy() end
		player.m_CigaretteEffectExpire = Timer(function()
			if isElement(player) and player:getType() == "player" then 
				player.m_LessHunger = false
			end
		end, 20*60*1000, 1)

		if chance(20) then
			player:setHealth(player:getHealth() - Randomizer:get(2, 8))
			player:setChoking(true)
			nextframe(function() player:setChoking(false) end)
		end

		if cigarettesLeft >= 1 then
			inventory:setItemValueByBag(bag, place, cigarettesLeft)
		else
			inventory:removeItemFromPlace(bag, place, 1)
		end
	end
end