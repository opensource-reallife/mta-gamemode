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
				local ammoItem = InventoryManager:getSingleton():getAmmoItemName(self.m_WeaponID)
				if not ammoItem or not player:getInventory():giveItem(InventoryManager:getSingleton():getItemId(ammoItem), self.m_Ammo) then
					return
				end
				player:sendSuccess(_("Du hast die Munition erhalten!", player))
			else
				if player:getInventory() and not player:getInventory():canCarryWeapon(self.m_WeaponID, self.m_Ammo) then
					player:sendError(_("Die Waffe ist zu schwer für dich!", player))
					return
				end
				giveWeapon(player, self.m_WeaponID, self.m_Ammo, true)
				player:sendSuccess(_("Du hast die Waffe erhalten!", player))
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
	elseif not player:getInventory():giveItem(InventoryManager:getSingleton():getItemId(self.m_ItemName), self.m_Amount, self.m_Value, false, self.m_WearLevel) then
		return
	else
		player:sendSuccess(_("Du hast %dx %s aufgehoben!", player, self.m_Amount, self.m_ItemName))
	end

	player:meChat(true, "kniet sich nieder und hebt %s auf!", self.m_ItemName, true)
	setPedAnimation(player, "misc", "pickup_box", 500, false, false, false)
	setTimer(setPedAnimation, 1000, 1, player, "carry", "crry_prtial", 200, false)
	setTimer(setPedAnimation, 1200, 1, player, false)
	delete(self)
end
