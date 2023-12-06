-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/MTAFixes.lua
-- *  PURPOSE:     MTA fixes class
-- *
-- ****************************************************************************
MTAFixes = inherit(Singleton)

function MTAFixes:constructor()
	self:dft_pathnode_teleport()
	self:fixRunSpeedBug()
	--bindKey("steer_forward", "down", bind(self.fixBikeSpeedBug, self))
	bindKey("horn", "down", bind(self.fixHydraulicsOxygenBug, self))
end

function MTAFixes:fixRunSpeedBug()
	self.m_RunSpeedBugIsMovingLeft = false
	self.m_RunSpeedBugIsMovingRight = false
	self.m_RunSpeedBugIsSprinting = false
	self.m_RunSpeedBugIsAiming = false

	bindKey("aim_weapon", "down", function()
		self.m_RunSpeedBugIsAiming = true
	end)
	bindKey("aim_weapon", "up", function()
		self.m_RunSpeedBugIsAiming = false
	end)

	bindKey("jump", "down", function()
		self.m_RunSpeedBugIsJumping = true
	end)
	bindKey("jump", "up", function()
		self.m_RunSpeedBugIsJumping = false
	end)

	bindKey("right", "down", function()
		self.m_RunSpeedBugIsMovingRight = true
	end)
	bindKey("right", "up", function()
		self.m_RunSpeedBugIsMovingRight = false
	end)

	bindKey("left", "down", function()
		self.m_RunSpeedBugIsMovingLeft = true
	end)
	bindKey("left", "up", function()
		self.m_RunSpeedBugIsMovingLeft = false
	end)

	bindKey("sprint", "down", function()
		self.m_RunSpeedBugIsSprinting = true
	end)
	bindKey("sprint", "up", function()
		self.m_RunSpeedBugIsSprinting = false
	end)

	bindKey("forwards", "down", function()
		local isBlocking = self.m_RunSpeedBugIsAiming == self.m_RunSpeedBugIsJumping

		if isBlocking and self.m_RunSpeedBugIsSprinting and self.m_RunSpeedBugIsMovingLeft or self.m_RunSpeedBugIsMovingRight then
			toggleAllControls(false)
			Timer(function() toggleAllControls(true) end, 300, 1)
		end
	end)
end

function MTAFixes:dft_pathnode_teleport()
	--[[
		GTA teleports the player to the closest pedestrian path node if the line of sight between the ped and the vehicle is not clear.
		This collides (for whatever reason) with our attached container object.
		
		GTA Code:
		if (!isLineOfSightClear(vecVehiclePosition, vecPedPosition, true, false, false, true, false, false)) // Checks the line of sight for buildings and objects
			WarpPedToClosestPathNode(pPed, posZ, pVehicle, 1.0f);
			
		Address (gta_sa.exe): 0x647CD6
		NOTE: Nopping the jnz at 0x647CE0 fixes the problem, but disables this mechanism entirely
		==> Lua Fix: Let's teleport the player back
	]]
	
	addEventHandler("onClientPlayerVehicleExit", localPlayer,
		function(vehicle, seat)
			-- Enable the fix for the DFT-30 (if objects are attached)
			if getElementModel(vehicle) == 578 and #getAttachedElements(vehicle) > 0 then
				local x, y, z = getPositionFromElementOffset(vehicle, -2.15 * (seat == 0 and 1 or -1), 3.6, -0.63)
				setElementPosition(localPlayer, x, y, z)
			end
		end
	)
end

-- Fix bike speed bug caused by spamming steer_forward by disabling steer_forward when on ground
function MTAFixes:fixBikeSpeedBug()
	if localPlayer.vehicle and localPlayer.vehicle.vehicleType == "Bike" and localPlayer.vehicle:isWheelOnGround("front_left") or localPlayer.vehicle:isWheelOnGround("rear_left") then
		toggleControl("steer_forward", false)
	else
		toggleControl("steer_forward", true)
	end
end

-- Fix oxygen replenishment bug when using hydraulics on seabed by disabling horn (= hydraulics) when in water
function MTAFixes:fixHydraulicsOxygenBug()
	if localPlayer.vehicle and localPlayer.vehicle.inWater then
		toggleControl("horn", false)
	else
		toggleControl("horn", true)
	end
end