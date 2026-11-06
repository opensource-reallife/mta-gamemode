PickupWeaponManager = inherit(Singleton) 
local LAST_USE_CHECK = 500
local LAST_BIND_CHECK = 2000

function PickupWeaponManager:constructor() 
	addEventHandler("onClientColShapeHit", root, bind(self.Event_onPickupHit, self))
	self.m_SpinObjects = {}
	for _index, object in ipairs(getElementsByType("object", root, true)) do
		if getElementData(object, "pickupSpin") then
			self.m_SpinObjects[object] = true
		end
	end
	addEventHandler("onClientElementStreamIn", root, function()
		if getElementType(source) == "object" and getElementData(source, "pickupSpin") then
			self.m_SpinObjects[source] = true
		end
	end)
	addEventHandler("onClientElementDataChange", root, function(dataName)
		if dataName == "pickupSpin" and getElementType(source) == "object" and isElementStreamedIn(source) then
			self.m_SpinObjects[source] = true
		end
	end)
	addEventHandler("onClientElementStreamOut", root, function()
		self.m_SpinObjects[source] = nil
	end)
	addEventHandler("onClientElementDestroy", root, function()
		self.m_SpinObjects[source] = nil
	end)
	addEventHandler("onClientPreRender", root, function()
		local rotation = (getTickCount() * 0.12) % 360
		for object in pairs(self.m_SpinObjects) do
			setElementRotation(object, 0, 0, rotation)
		end
	end)
	self.m_KeyBind = bind(self.checkKey, self)
	bindKey("m", "down", self.m_KeyBind)	-- for m+alt and alt+n
	bindKey("n", "down", self.m_KeyBind)	-- for m+alt and alt+n
	bindKey("lalt", "down", self.m_KeyBind) -- for alt+m and alt+n
end

function PickupWeaponManager:destructor() 
	
end

function PickupWeaponManager:Event_onPickupHit( player, dimension) 
	if dimension then 
		if getElementType(player) == "player" and player == localPlayer then 
			if not getPedOccupiedVehicle(player) then 
				if getElementData(source, "pickupWeapon") then
					self.m_HitWeaponPickup = source
					ShortMessage:new(("Drücke Links-Alt + M um %s aufzuheben!"):format(getElementData(source, "pickupLabel") or "die Waffe"), "Gegenstand auf dem Boden")
				end
			end
		end
	end
end

function PickupWeaponManager:checkKey(key)
	if ( key == "m" and getKeyState("lalt")) or (key == "lalt" and getKeyState("m"))  then
		if self.m_HitWeaponPickup and isElement(self.m_HitWeaponPickup) and not getPedOccupiedVehicle(localPlayer) then 
			self:Event_onTryPickupWeapon()
		end
	elseif ( key == "n" and getKeyState("lalt")) or (key == "lalt" and getKeyState("n"))  then
		if localPlayer:getFaction() and (localPlayer:getFaction():isStateFaction() or localPlayer:getFaction():isRescueFaction()) and localPlayer:getPublicSync("Faction:Duty") then return ErrorBox:new(_"Du darfst im Dienst keine Waffen wegwerfen.") end
		if localPlayer:isDead() then return end
		if localPlayer:getData("isInDeathMatch") then return end
		local weapon = getPedWeapon(localPlayer)
		if weapon == 0 then return end
		if not RESTRICTED_WEAPONS[weaponId] then
			self:Event_onDropWeapon()
		else
			ErrorBox:new(_"Du kannst diese Waffe nicht wegwerfen!")
		end
	end
end

function PickupWeaponManager:Event_onTryPickupWeapon() 
	if self.m_HitWeaponPickup and isElement(self.m_HitWeaponPickup) then 
		local x, y, z = getElementPosition(localPlayer) 
		local px, py, pz = getElementPosition(self.m_HitWeaponPickup) 
		local dist = getDistanceBetweenPoints3D(x, y, z, px, py, pz) 
		local now = getTickCount() 
		if dist <= 5 then 
			if not self.m_LastPickup or ( self.m_LastPickup+LAST_USE_CHECK <= now ) then
				triggerServerEvent("onPlayerHitPickupWeapon", localPlayer, self.m_HitWeaponPickup)
				self.m_LastPickup = now
			end
		end
	end
end

function PickupWeaponManager:Event_onDropWeapon() 
	local x, y, z = getElementPosition(localPlayer) 
	local dim = getElementDimension(localPlayer)
	local int = getElementInterior(localPlayer)
	local weapon  = getPedWeapon(localPlayer)
	local ammo  = getPedTotalAmmo(localPlayer) 
	triggerServerEvent("onPlayerDropWeapon", localPlayer, {x, y, z, int, dim, weapon, ammo})
end