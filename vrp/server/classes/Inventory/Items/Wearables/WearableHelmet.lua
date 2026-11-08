-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/Items/Wearables/WearableHelmet.lua
-- *  PURPOSE:     Wearable Helmets
-- *
-- ****************************************************************************
WearableHelmet = inherit( Item )

WearableHelmet.objectTable =
{
	[56] = {2052, 0.05, 0.05, 1, 5, 180, "Integral-Helm",true},
	[57] = {1924, 0.09, 0.02, 0.9, 10, 180,"Motocross-Helm",true},
	[58] = {3911,0.1, 0, 1, 0, 180, "Biker-Helm",false},
	[69] = {3911,0.1, 0.05, 0.95, 10, 180, "Einsatzhelm",false},
	[59] = {3890,0, 0.15, 0.8, 0, 90, "Gasmaske",true},
	[72] = {1934, 0, 0, 1, 0, 180, "Hasenohren", true},
	[40] = {1936, 0.14, 0, 1, 0, 90, "Weihnachtsmütze", true},
	[93] = {902, 0.1, 0, 0.2, 0, 90, "Stern", true},
	[112] = {2107, -0.6, -0.003, 1, 0, 90, "Lebkuchen-Maske", true},
	[173] = {1935, 0.05, 0, 0.8, 0, 180, "Kürbishut", true},
}


function WearableHelmet:constructor()
	self.m_Helmets = {}
end

function WearableHelmet:destructor()

end

function WearableHelmet:use(player, itemId, bag, place, itemName)
	local wearableId = self:getId()
	local inventory = player:getInventory()
	local value = inventory:getItemValueByBag( bag, place)
	if player.m_PrisonTime > 0 then player:sendError(_("Im Prison nicht erlaubt!", player)) return end
	if player.m_JailTime > 0 then player:sendError(_("Im Gefängnis nicht erlaubt!", player)) return end
	if value then --// for texture usage later

	end
	if not player.m_IsWearingHelmet and not player.m_Helmet then --// if the player clicks onto the helmet without currently wearing one
		if InventoryManager:getSingleton():getItemDataForItem(itemName)["DienstItem"] == 1 and not (player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty()) then
			player:sendError(_("Du bist nicht im Dienst! Das Item wurde abgenommen.", player))
			player:getInventory():removeAllItem(self:getName())
			return
		end
		if isElement(player.m_Helmet) then
			destroyElement(player.m_Helmet)
		end
		if player.m_HelmetPutOnTimer then if isTimer(player.m_HelmetPutOnTimer) then killTimer(player.m_HelmetPutOnTimer) end end
		local x,y,z = getElementPosition(player)
		local dim = getElementDimension(player)
		local int = getElementInterior(player)
		local model, zOffset, yOffset, scale, rotX, rotZ  = WearableHelmet.objectTable[wearableId][1] or WearableHelmet.objectTable[56][1],  WearableHelmet.objectTable[wearableId][2] or WearableHelmet.objectTable[56][2], WearableHelmet.objectTable[wearableId][3] or WearableHelmet.objectTable[56][3], WearableHelmet.objectTable[wearableId][4] or WearableHelmet.objectTable[56][4], WearableHelmet.objectTable[wearableId][5] or WearableHelmet.objectTable[56][5],  WearableHelmet.objectTable[wearableId][6] or WearableHelmet.objectTable[56][6]
		local obj = createObject(model,x,y,z)
		local objName =  WearableHelmet.objectTable[wearableId][7]
		local isFaceConcealed = WearableHelmet.objectTable[wearableId][8]
		setElementDimension(obj, dim)
		setElementInterior(obj, int)
		setObjectScale(obj, scale)
		setElementDoubleSided(obj,true)
		setPedAnimation(player, "goggles", "goggles_put_on", 500, false, false, false)
		exports.bone_attach:attachElementToBone(obj, player, 12, 0, yOffset, zOffset, rotX, 0, rotZ+90)
		player.m_HelmetPutOnTimer = setTimer(function() if player and isElement(player) and obj and isElement(obj) then exports.bone_attach:attachElementToBone(obj, player, 1, 0, yOffset, zOffset, rotX, 0, rotZ); setPedAnimation(player, nil) end end, 500, 1)
		player.m_Helmet = obj
		player.m_IsWearingHelmet = itemName
		player:meChat(true, "zieht %s an!", objName, true)
		player:setData("isFaceConcealed", isFaceConcealed)
		if wearableId == 69 then
			obj:setData("isProtectingHeadshot", true)
		elseif wearableId == 72 then
			player:giveAchievement(90) -- Trage die tollen Hasenohren
		end
		player:triggerEvent("onClientToggleHelmet", true, wearableId)
		player:setPublicSync("HelmetItem", wearableId)
	elseif player.m_IsWearingHelmet == itemName and player.m_Helmet then --// if the player clicks onto the same helmet once more remove it
		destroyElement(player.m_Helmet)
		self.m_Helmets[player] = nil
		player.m_IsWearingHelmet = false
		player.m_Helmet = false
		player:setData("isFaceConcealed", false)
		if player.m_HelmetPutOnTimer then if isTimer(player.m_HelmetPutOnTimer) then killTimer(player.m_HelmetPutOnTimer) end end
		player:meChat(true, "setzt %s ab!", WearableHelmet.objectTable[wearableId][7], true)
		player:triggerEvent("onClientToggleHelmet", false, wearableId)
		player:setPublicSync("HelmetItem", false)
	else --// else the player must have clicked on another helmet otherwise this instance of the class would have not been called
		if InventoryManager:getSingleton():getItemDataForItem(itemName)["DienstItem"] == 1 and (not player:getFaction() or not player:getFaction():isStateFaction() or not player:isFactionDuty()) then
			player:sendError(_("Du bist nicht im Dienst! Das Item wurde abgenommen.", player))
			player:getInventory():removeAllItem(self:getName())
			return
		end
		if isElement(player.m_Helmet) then
			destroyElement(player.m_Helmet)
		end
		local x,y,z = getElementPosition(player)
		local model, zOffset, yOffset, scale, rotX, rotZ  = WearableHelmet.objectTable[wearableId][1] or WearableHelmet.objectTable[56][1],  WearableHelmet.objectTable[wearableId][2] or WearableHelmet.objectTable[56][2], WearableHelmet.objectTable[wearableId][3] or WearableHelmet.objectTable[56][3], WearableHelmet.objectTable[wearableId][4] or WearableHelmet.objectTable[56][4], WearableHelmet.objectTable[wearableId][5] or WearableHelmet.objectTable[56][5],  WearableHelmet.objectTable[wearableId][6] or WearableHelmet.objectTable[56][6]
		local obj = createObject(model,x,y,z)
		local dim = getElementDimension(player)
		local int = getElementInterior(player)
		local objName =  WearableHelmet.objectTable[wearableId][7]
		local isFaceConcealed = WearableHelmet.objectTable[wearableId][8]
		if player.m_HelmetPutOnTimer then if isTimer(player.m_HelmetPutOnTimer) then killTimer(player.m_HelmetPutOnTimer) end end
		setElementDimension(obj, dim)
		setElementInterior(obj, int)
		setObjectScale(obj, scale)
		setElementDoubleSided(obj,true)
		setPedAnimation(player, "goggles", "goggles_put_on", 500, false, false, false)
		exports.bone_attach:attachElementToBone(obj, player, 12, 0, yOffset, zOffset, rotX, 0, rotZ+90)
		player.m_HelmetPutOnTimer = setTimer(function() if player and isElement(player) and obj and isElement(obj) then exports.bone_attach:attachElementToBone(obj, player, 1, 0, yOffset, zOffset, rotX, 0, rotZ); setPedAnimation(player, nil) end end, 500, 1)
		player.m_Helmet = obj
		player.m_IsWearingHelmet = itemName
		player:meChat(true, "zieht %s an!", objName, true)
		player:setData("isFaceConcealed", isFaceConcealed)
		if wearableId == 69 then
			obj:setData("isProtectingHeadshot", true)
		end
		player:triggerEvent("onClientToggleHelmet", true, wearableId)
		player:setPublicSync("HelmetItem", wearableId)
	end
end