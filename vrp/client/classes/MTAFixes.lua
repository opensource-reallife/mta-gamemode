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

	--bindKey("steer_forward", "down", bind(self.fixBikeSpeedBug, self))
	bindKey("horn", "down", bind(self.fixHydraulicsOxygenBug, self))
	bindKey("forwards", "down", bind(self.fixRunSpeedBug, self))
	bindKey("backwards", "down", bind(self.fixRunSpeedBug, self))
end

function MTAFixes:fixRunSpeedBug()
	if localPlayer:getMoveState() == "sprint" and localPlayer:getTask("secondary", 0) == "TASK_SIMPLE_FIGHT" then
		localPlayer:setControlState("sprint", false)
	end
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