-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/Items/Wearables/WearableShirt.lua
-- *  PURPOSE:     Wearable Shirts
-- *
-- ****************************************************************************
WearableShirt = inherit( Item )

--{model, bone, x, y, z, rx, ry, rz, scale, doublesided, texture},
--3,0,-0.1325,0.145,0,0,0,1
WearableShirt.objectTable =
{
	[60] = {3916, 0.05, 0.05, 1.22, 0, 0,-90, "Schutzweste", false},
	[61] = {3915,0.145,-0.1325,1,0,0,0, "Tragetasche", true},
}

function WearableShirt:constructor()
	self.m_Shirts = {}
end

function WearableShirt:destructor()

end

function WearableShirt:use(player, itemId, bag, place, itemName)
	local wearableId = self:getId()
	local inventory = player:getInventory()
	local value = inventory:getItemValueByBag( bag, place)
	if player.m_PrisonTime > 0 then player:sendError(_("Im Prison nicht erlaubt!", player)) return end
	if player.m_JailTime > 0 then player:sendError(_("Im Gefängnis nicht erlaubt!", player)) return end
	if value then --// for texture usage later

	end
	if not player.m_IsWearingShirt and not player.m_Shirt then --// if the player clicks onto the Shirt without currently wearing one
		if InventoryManager:getSingleton():getItemDataForItem(itemName)["DienstItem"] == 1 and not (player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty()) then
			player:sendError(_("Du bist nicht im Dienst! Das Item wurde abgenommen.", player))
			player:getInventory():removeAllItem(self:getName())
			return
		end
		if isElement(player.m_Shirt) then
			destroyElement(player.m_Shirt)
		end
		local x,y,z = getElementPosition(player)
		local dim = getElementDimension(player)
		local int = getElementInterior(player)
		local model, zOffset, yOffset, scale, rotX, rotZ = WearableShirt.objectTable[wearableId][1] or WearableShirt.objectTable[60][1],  WearableShirt.objectTable[wearableId][2] or WearableShirt.objectTable[60][2], WearableShirt.objectTable[wearableId][3] or WearableShirt.objectTable[60][3], WearableShirt.objectTable[wearableId][4] or WearableShirt.objectTable[60][4], WearableShirt.objectTable[wearableId][5] or WearableShirt.objectTable[60][5],  WearableShirt.objectTable[wearableId][6] or WearableShirt.objectTable[60][6]
		local rotY =  WearableShirt.objectTable[wearableId][7] or WearableShirt.objectTable[60][7]
		local obj = createObject(model,x,y,z)
		local objName =  WearableShirt.objectTable[wearableId][8]
		local bIsConceal = WearableShirt.objectTable[wearableId][9]
		local bConcealOutput = false
		if bIsConceal then
			for i = 3,7 do
				if getPedWeapon(player,i) ~= 0 then
					bConcealOutput = true
					break
				end
			end
		end
		setElementDimension(obj, dim)
		setElementInterior(obj, int)
		setObjectScale(obj, scale)
		setElementDoubleSided(obj,true)
		exports.bone_attach:attachElementToBone(obj, player, 3, 0, yOffset, zOffset, rotX , rotY, rotZ)
		player.m_Shirt = obj
		player.m_IsWearingShirt = itemName
		player:meChat(true, "zieht %s an!", objName, true)
		setElementData(player,"CanWeaponBeConcealed",bIsConceal)
		if bConcealOutput then
			player:meChat(true, "versteckt einige Waffen in seiner %s!", objName, true)
		end
		if bIsConceal then
			triggerEvent("WeaponAttach:concealWeapons", player)
		end
		if wearableId == 60 then
			obj:setData("isProtectingChest", true)
			if not player.m_KevlarShotsCount then
				player.m_KevlarShotsCount = 0
			end
		end
	elseif player.m_IsWearingShirt == itemName and player.m_Shirt then --// if the player clicks onto the same Shirt once more remove it
		destroyElement(player.m_Shirt)
		self.m_Shirts[player] = nil
		player.m_IsWearingShirt = false
		player.m_Shirt = false
		player:meChat(true, "setzt %s ab!", WearableShirt.objectTable[wearableId][8], true)
		setElementData(player,"CanWeaponBeConcealed",false)
		triggerEvent("WeaponAttach:unconcealWeapons", player)
	else --// else the player must have clicked on another Shirt otherwise this instance of the class would have not been called
		if InventoryManager:getSingleton():getItemDataForItem(itemName)["DienstItem"] == 1 and not (player:getFaction() and player:getFaction():isStateFaction() and player:isFactionDuty()) then
			player:sendError(_("Du bist nicht im Dienst! Das Item wurde abgenommen.", player))
			player:getInventory():removeAllItem(self:getName())
			return
		end
		if isElement(player.m_Shirt) then
			destroyElement(player.m_Shirt)
		end
		local x,y,z = getElementPosition(player)
		local model, zOffset, yOffset, scale, rotX, rotZ  = WearableShirt.objectTable[wearableId][1] or WearableShirt.objectTable[60][1],  WearableShirt.objectTable[wearableId][2] or WearableShirt.objectTable[60][2], WearableShirt.objectTable[wearableId][3] or WearableShirt.objectTable[60][3], WearableShirt.objectTable[wearableId][4] or WearableShirt.objectTable[60][4], WearableShirt.objectTable[wearableId][5] or WearableShirt.objectTable[60][5],  WearableShirt.objectTable[wearableId][6] or WearableShirt.objectTable[60][6]
		local rotY =  WearableShirt.objectTable[wearableId][7] or WearableShirt.objectTable[60][7]
		local obj = createObject(model,x,y,z)
		local dim = getElementDimension(player)
		local int = getElementInterior(player)
		local objName =  WearableShirt.objectTable[wearableId][8]
		local bIsConceal = WearableShirt.objectTable[wearableId][9]
		local bConcealOutput = false
		if bIsConceal then
			for i = 3,7 do
				if getPedWeapon(player,i) ~= 0 then
					bConcealOutput = true
					break
				end
			end
		end
		if bIsConceal then
			triggerEvent("WeaponAttach:concealWeapons", player)
		end
		if bConcealOutput then
			player:meChat(true, "versteckt einige Waffen in seiner %s!", objName, true)
		end
		setElementDimension(obj, dim)
		setElementInterior(obj, int)
		setObjectScale(obj, scale)
		setElementDoubleSided(obj,true)
		setElementData(player,"CanWeaponBeConcealed", bIsConceal)
		if wearableId == 60 then
			obj:setData("isProtectingChest", true)
		end
		exports.bone_attach:attachElementToBone(obj, player, 3, 0, yOffset, zOffset, rotX, rotY, rotZ)
		player.m_Shirt = obj
		player.m_IsWearingShirt = itemName
		player:meChat(true, "zieht %s an!", objName, true)
	end
end

function WearableShirt:destroyShirt(player)
	destroyElement(player.m_Shirt)
	self.m_Shirts[player] = nil
	player.m_IsWearingShirt = false
	player.m_Shirt = false
	player:meChat(true, "setzt %s ab!", WearableShirt.objectTable[self:getId()][8], true)
	setElementData(player,"CanWeaponBeConcealed",false)
	triggerEvent("WeaponAttach:unconcealWeapons", player)
end