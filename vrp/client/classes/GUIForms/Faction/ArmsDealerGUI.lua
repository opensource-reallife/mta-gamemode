-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ArmsDealerGUI.lua
-- *  PURPOSE:     Arrest GUI class
-- *
-- ****************************************************************************
ArmsDealerGUI = inherit(WeaponOrderGUI)
inherit(Singleton, ArmsDealerGUI)

addRemoteEvents{"openArmsDealerGUI", "updateFactionArmsDealerShopGUI"}

function ArmsDealerGUI:constructor(type)
	self.m_Type = type
	self.m_MaxCosts = 0
	self.m_WeaponIds = {}
	self.m_EquipmentIds = {}

	WeaponOrderGUI.constructor(self, _"Waffenlieferung", _"Beladen")

	triggerServerEvent("factionReceiveArmsDealerShopInfos", localPlayer)
end

function ArmsDealerGUI:loadProducts(specialWeapons, depotWeaponsMax, depotWeapons, depotEquipmentMax, depotEquipments)
	for weaponId, allowed in pairs(specialWeapons["Weapons"] or {}) do
		if allowed == true then
			local info, stock = depotWeaponsMax[weaponId], depotWeapons[weaponId]
			local icon = FileModdingHelper:getSingleton():getWeaponImage(weaponId)
			self.m_WeaponIds[#self.m_WeaponIds + 1] = weaponId
			self:addProduct({kind = "Waffe", id = weaponId, name = WEAPON_NAMES[weaponId], icon = icon, group = "Waffen", stock = stock["Waffe"], limit = info["Waffe"], price = info["WaffenPreis"], step = 1})
			self.m_MaxCosts = self.m_MaxCosts + math.max(0, info["Waffe"] - stock["Waffe"]) * info["WaffenPreis"]
			if info["Magazine"] > 0 and not THROWABLE_WEAPONS[weaponId] and not NO_MUNITION_WEAPONS[weaponId] then
				self:addProduct({kind = "Munition", id = weaponId, name = WEAPON_NAMES[weaponId].." Munition", icon = Inventory:getSingleton():getAmmoIcon(weaponId), group = "Munition", stock = stock["Munition"], limit = info["Magazine"], price = info["MagazinPreis"], step = getWeaponClipSize(weaponId)})
				self.m_MaxCosts = self.m_MaxCosts + math.max(0, info["Magazine"] - stock["Munition"]) * info["MagazinPreis"]
			end
		end
	end

	for item, allowed in pairs(specialWeapons["Equipment"] or {}) do
		if allowed == true then
			local info = depotEquipmentMax[item]
			local weaponKey = item == "Fallschirm" and 46 or item
			self.m_EquipmentIds[#self.m_EquipmentIds + 1] = item
			self:addProduct({kind = "Count", id = item, name = WEAPON_NAMES[weaponKey], icon = FileModdingHelper:getSingleton():getWeaponImage(weaponKey), group = "Ausrüstung", stock = depotEquipments[item] or 0, limit = -1, perDrop = info["MaxPerAirDrop"], price = info["Price"], step = 1})
			self.m_MaxCosts = self.m_MaxCosts + info["MaxPerAirDrop"] * info["Price"]
		end
	end

	table.sort(self.m_Products, function(a, b)
		if a.group ~= b.group then return a.group > b.group end
		return a.name < b.name
	end)
	self:refresh()
end

function ArmsDealerGUI:getMaxAddable(product)
	if product.perDrop then
		return math.max(0, product.perDrop - self.m_Cart[product.key])
	end
	return WeaponOrderGUI.getMaxAddable(self, product)
end

function ArmsDealerGUI:isFull(product)
	if product.perDrop then
		return self.m_Cart[product.key] >= product.perDrop
	end
	return WeaponOrderGUI.isFull(self, product)
end

function ArmsDealerGUI:submit()
	local cart = {["Weapon"] = {}, ["Equipment"] = {}}
	for _index, weaponId in ipairs(self.m_WeaponIds) do
		cart["Weapon"][weaponId] = {
			["Waffe"] = self.m_Cart["Waffe:"..tostring(weaponId)] or 0,
			["Munition"] = self.m_Cart["Munition:"..tostring(weaponId)] or 0,
		}
	end
	for _index, item in ipairs(self.m_EquipmentIds) do
		cart["Equipment"][item] = {["Count"] = self.m_Cart["Count:"..tostring(item)] or 0}
	end
	triggerServerEvent("checkoutArmsDealerCart", root, cart, self.m_MaxCosts)
end

addEventHandler("updateFactionArmsDealerShopGUI", root, function(...)
	if ArmsDealerGUI:isInstantiated() then
		ArmsDealerGUI:getSingleton():loadProducts(...)
	end
end)

addEventHandler("openArmsDealerGUI", root, function(type)
	if ArmsDealerGUI:isInstantiated() then
		delete(ArmsDealerGUI:getSingleton())
	end
	ArmsDealerGUI:new(type)
end)
