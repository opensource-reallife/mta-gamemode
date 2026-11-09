PickupWeapon = inherit(Object)
PickupWeapon.Map = { }
local PICKUP_ANIMATION_BLOCK, PICKUP_ANIMATION_NAME = "misc", "pickup_box"
local AMMO_PICKUP_MODEL = 2061
local WEAPON_PICKUP_SCALE = 1.5

function PickupWeapon:constructor(x, y, z, int, dim, weapon, ammo, owner, ignoreHours, attachToPlayer, xOffset, yOffset, ammoOnly)
	if WEAPON_MODELS_WORLD[weapon] then
		self.m_WeaponID = weapon
		self.m_Ammo = ammo
		self.m_AmmoOnly = ammoOnly
		if owner then
			self.m_Owner = owner.m_Id
			if owner:getFaction() then
				self.m_OwnerFaction = owner:getFaction()
			end
		end
		self.m_IgnoreHoursPlayed = ignoreHours
		local ammoItem = ammoOnly and InventoryManager:getSingleton():getAmmoItemName(weapon)
		self:createEntity(ammoOnly and AMMO_PICKUP_MODEL or WEAPON_MODELS_WORLD[weapon], x, y, z, int, dim, ammoItem and ("%dx %s"):format(ammo, ammoItem) or (ammoOnly and "die Munition" or "die Waffe"), not ammoOnly and WEAPON_PICKUP_SCALE)
	end
end

function PickupWeapon.getBlockReason(player, itemName, amount)
	local inventory = player:getInventory()
	if not inventory then return false end
	local limit = inventory:getItemLimitSpace(itemName)
	if amount > limit then
		return limit <= 0 and _("Limit erreicht", player) or _("Limit erreicht, nur noch %d möglich", player, limit)
	end
	if not inventory:canCarry(itemName, amount) then
		return _("zu schwer, noch %.2f kg frei", player, math.max(0, inventory:getFreeCarryWeight()))
	end
	return false
end

function PickupWeapon:createEntity(model, x, y, z, int, dim, label, scale)
	self.m_Object = createObject(model, x, y, z)
	if scale then setObjectScale(self.m_Object, scale) end
	setElementCollisionsEnabled(self.m_Object, false)
	setElementData(self.m_Object, "pickupSpin", true)
	setElementDoubleSided(self.m_Object, true)
	setElementDimension(self.m_Object, dim)
	setElementInterior(self.m_Object, int)
	self.m_Entity = createColSphere(x, y, z, 1)
	setElementDimension(self.m_Entity, dim)
	setElementInterior(self.m_Entity, int)
	self.m_Entity.m_DroppedWeapon = true
	setElementData(self.m_Entity, "pickupWeapon", true)
	setElementData(self.m_Entity, "pickupLabel", label)
	PickupWeaponManager.Map[self.m_Entity] = self
end

function PickupWeapon:pickup(player)
	if player and isElement(player) then
		if ((player:getPlayTime() / 60) >= 3) or self.m_IgnoreHoursPlayed then
			local onDuty = player:isFactionDuty() and player:getFaction():isStateFaction()
			if onDuty then
				if self.m_AmmoOnly then
					StateEvidence:getSingleton():addMunitionToEvidence(player, self.m_WeaponID, self.m_Ammo)
				else
					StateEvidence:getSingleton():addWeaponWithMunitionToEvidence(player, self.m_WeaponID, self.m_Ammo)
				end
			elseif self.m_AmmoOnly then
				local manager = InventoryManager:getSingleton()
				local ammoItem = manager:getAmmoItemName(self.m_WeaponID)
				local entry = _("%d Schuss %s", player, self.m_Ammo, WEAPON_NAMES[self.m_WeaponID] or ammoItem or "")
				local reason = ammoItem and PickupWeapon.getBlockReason(player, ammoItem, self.m_Ammo)
				if reason then
					manager:sendReceivedMessage(player, _("Aufheben", player), {}, {("%s (%s)"):format(entry, reason)})
					return
				end
				if not ammoItem or not player:getInventory():giveItem(manager:getItemId(ammoItem), self.m_Ammo) then
					return
				end
				manager:sendReceivedMessage(player, _("Aufgehoben", player), {entry}, {})
			else
				local name = WEAPON_NAMES[self.m_WeaponID] or ""
				local entry = (self.m_Ammo > 0 and not THROWABLE_WEAPONS[self.m_WeaponID]) and _("1x %s mit %d Schuss", player, name, self.m_Ammo) or _("%dx %s", player, THROWABLE_WEAPONS[self.m_WeaponID] and math.max(self.m_Ammo, 1) or 1, name)
				if player:getInventory() and not player:getInventory():canCarryWeapon(self.m_WeaponID, self.m_Ammo) then
					InventoryManager:getSingleton():sendReceivedMessage(player, _("Aufheben", player), {}, {_("%s (zu schwer, noch %.2f kg frei)", player, entry, math.max(0, player:getInventory():getFreeCarryWeight()))})
					return
				end
				giveWeapon(player, self.m_WeaponID, self.m_Ammo, true)
				InventoryManager:getSingleton():sendReceivedMessage(player, _("Aufgehoben", player), {entry}, {})
			end
			player:meChat(true, "kniet sich nieder und hebt %s auf!", self.m_AmmoOnly and "Munition" or "eine Waffe")
			setPedAnimation(player, PICKUP_ANIMATION_BLOCK, PICKUP_ANIMATION_NAME, 500, false, false, false)
			setTimer(setPedAnimation, 1000, 1, player, "carry", "crry_prtial", 200, false)
			setTimer(setPedAnimation, 1200, 1, player, false)
			delete(self)
		else
			player:sendError(_("Du benötigst dafür mindestens %d Spielstunden!", player, 3))
		end
	end
end

function PickupWeapon:destructor()
	if isElement(self.m_Object) then
		destroyElement(self.m_Object)
	end
	if self.m_Entity then
		if isElement(self.m_Entity) then
			destroyElement(self.m_Entity)
		end
	end
end

PickupItem = inherit(PickupWeapon)

local ITEM_PICKUP_MODEL = 1210

function PickupItem:constructor(x, y, z, int, dim, itemName, amount, value, owner, wearLevel)
	local data = InventoryManager:getSingleton():getItemDataForItem(itemName)
	self.m_ItemName = itemName
	self.m_Amount = amount
	self.m_Value = value ~= "" and value or nil
	self.m_WearLevel = wearLevel
	self:createEntity((data["ModelID"] and data["ModelID"] ~= 0) and data["ModelID"] or ITEM_PICKUP_MODEL, x, y, z, int, dim, ("%dx %s"):format(amount, itemName))
end

function PickupItem:pickup(player)
	if not player or not isElement(player) then return end

	if (player:getPlayTime() / 60) < 3 then
		player:sendError(_("Du benötigst dafür mindestens %d Spielstunden!", player, 3))
		return
	end

	if player:isFactionDuty() and player:getFaction():isStateFaction() then
		if not FactionState:getSingleton():isItemIllegal(self.m_ItemName) then
			player:sendError(_("Dieses Item ist nicht illegal!", player))
			return
		end
		StateEvidence:getSingleton():addItemToEvidence(player, self.m_ItemName, self.m_Amount)
	else
		local manager = InventoryManager:getSingleton()
		local entry = _("%dx %s", player, self.m_Amount, _(self.m_ItemName, player))
		local reason = PickupWeapon.getBlockReason(player, self.m_ItemName, self.m_Amount)
		if reason then
			manager:sendReceivedMessage(player, _("Aufheben", player), {}, {("%s (%s)"):format(entry, reason)})
			return
		end
		if not player:getInventory():giveItem(manager:getItemId(self.m_ItemName), self.m_Amount, self.m_Value, false, self.m_WearLevel) then
			return
		end
		manager:sendReceivedMessage(player, _("Aufgehoben", player), {entry}, {})
	end

	player:meChat(true, "kniet sich nieder und hebt %s auf!", self.m_ItemName, true)
	setPedAnimation(player, "misc", "pickup_box", 500, false, false, false)
	setTimer(setPedAnimation, 1000, 1, player, "carry", "crry_prtial", 200, false)
	setTimer(setPedAnimation, 1200, 1, player, false)
	delete(self)
end
