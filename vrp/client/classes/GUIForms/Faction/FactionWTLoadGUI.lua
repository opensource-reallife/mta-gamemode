-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/FactionWTLoadGUI.lua
-- *  PURPOSE:     Faction Weapon Shop GUI class
-- *
-- ****************************************************************************
FactionWTLoadGUI = inherit(WeaponOrderGUI)
inherit(Singleton, FactionWTLoadGUI)

addRemoteEvents{"showFactionWTLoadGUI", "updateFactionWeaponTruckShopGUI"}

function FactionWTLoadGUI:constructor()
	self.m_MaxLoad = WEAPONTRUCK_MAX_LOAD
	self.m_MaxLoadPerBox = math.floor(self.m_MaxLoad/8)
	self.m_BoxContent = {}
	for i = 1, 8 do
		self.m_BoxContent[i] = {}
	end

	WeaponOrderGUI.constructor(self, _"Waffentruck beladen", _"Beladen")

	triggerServerEvent("factionReceiveWeaponTruckShopInfos", localPlayer)
end

function FactionWTLoadGUI:getBudget()
	return self.m_MaxLoad
end

function FactionWTLoadGUI:loadProducts(validWeapons, depotWeaponsMax, depotWeapons)
	self.m_DepotWeaponsMax = depotWeaponsMax
	for weaponId, allowed in pairs(validWeapons) do
		if allowed == true then
			local info, stock = depotWeaponsMax[weaponId], depotWeapons[weaponId]
			local icon = FileModdingHelper:getSingleton():getWeaponImage(weaponId)
			self:addProduct({kind = "Waffe", id = weaponId, name = WEAPON_NAMES[weaponId], icon = icon, group = "Waffen", stock = stock["Waffe"], limit = info["Waffe"], price = info["WaffenPreis"], step = 1})
			if info["Magazine"] > 0 and not THROWABLE_WEAPONS[weaponId] and not NO_MUNITION_WEAPONS[weaponId] then
				self:addProduct({kind = "Munition", id = weaponId, name = WEAPON_NAMES[weaponId].." Munition", icon = Inventory:getSingleton():getAmmoIcon(weaponId), group = "Munition", stock = stock["Munition"], limit = info["Magazine"], price = info["MagazinPreis"], step = getWeaponClipSize(weaponId)})
			end
		end
	end
	table.sort(self.m_Products, function(a, b)
		if a.group ~= b.group then return a.group > b.group end
		return a.name < b.name
	end)
	self:refresh()
end

function FactionWTLoadGUI:getBoxCost(index)
	local sum = 0
	for weaponId, data in pairs(self.m_BoxContent[index]) do
		sum = sum + (data["Waffe"] or 0) * self.m_DepotWeaponsMax[weaponId]["WaffenPreis"]
		sum = sum + (data["Munition"] or 0) * self.m_DepotWeaponsMax[weaponId]["MagazinPreis"]
	end
	return sum
end

function FactionWTLoadGUI:onAdded(product, amount)
	local added = 0
	for index in ipairs(self.m_BoxContent) do
		local free = math.floor((self.m_MaxLoadPerBox - self:getBoxCost(index)) / product.price)
		local put = math.min(free, amount - added)
		if put > 0 then
			local box = self.m_BoxContent[index]
			box[product.id] = box[product.id] or {}
			box[product.id][product.kind] = (box[product.id][product.kind] or 0) + put
			added = added + put
		end
		if added >= amount then break end
	end
	return added
end

function FactionWTLoadGUI:onRemoved(product, amount)
	for index, box in ipairs(self.m_BoxContent) do
		if box[product.id] then
			box[product.id][product.kind] = nil
		end
	end
end

function FactionWTLoadGUI:submit()
	triggerServerEvent("onWeaponTruckLoad", root, self.m_BoxContent)
end

addEventHandler("updateFactionWeaponTruckShopGUI", root, function(validWeapons, depotWeaponsMax, depotWeapons)
	if FactionWTLoadGUI:isInstantiated() then
		FactionWTLoadGUI:getSingleton():loadProducts(validWeapons, depotWeaponsMax, depotWeapons)
	end
end)

addEventHandler("showFactionWTLoadGUI", root, function()
	if FactionWTLoadGUI:isInstantiated() then
		delete(FactionWTLoadGUI:getSingleton())
	end
	FactionWTLoadGUI:new()
end)
