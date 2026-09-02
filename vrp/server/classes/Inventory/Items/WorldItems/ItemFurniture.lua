-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemFurniture.lua
-- *  PURPOSE:     Furniture item class
-- *
-- ****************************************************************************
ItemFurniture = inherit(Item)

function ItemFurniture:use(player, itemId, bag, place, itemName)
	local itemCount = 0
	if WorldItem.Map[player:getId()] then
		for modelId, objects in pairs(WorldItem.Map[player:getId()]) do
			for object, worldItem in pairs(objects) do
				if worldItem:getItem():getName() == "Einrichtung" then
					itemCount = itemCount + 1
				end
			end
		end
	end
	
	if itemCount >= MAX_FURNITURE_PER_PLAYER then
		player:sendError(_("Du kannst maximal %s Einrichtungsgegenstände platzieren!", player, MAX_FURNITURE_PER_PLAYER))
		return false
	end

	local house = HouseManager:getSingleton():getPlayerHouse(player)
	local int = player:getInterior() 
	local dim = player:getDimension()
	if house and HOUSE_INTERIOR_TABLE[house.m_InteriorID][1] == int and house.m_Id == dim then
		local inventory = player:getInventory()
		local model = tonumber(inventory:getItemValueByBag(bag, place))
		local result = self:startObjectPlacing(player, function(item, position, rotation)
			if item ~= self or not position then return end
			player:getInventory():removeItemFromPlace(bag, place, 1)
			StatisticsLogger:getSingleton():itemPlaceLogs(player, "Einrichtung", position.x..","..position.y..","..position.z)
			local worldObject = PlayerWorldItem:new(self, player:getId(), position, rotation, false, player:getId(), true, false, model)
			worldObject:setInterior(int) 
			worldObject:setDimension(dim)
		end, false, model)
	else
		player:sendError("Du kannst nur in deinem Haus Einrichtung platzieren!")
	end
end