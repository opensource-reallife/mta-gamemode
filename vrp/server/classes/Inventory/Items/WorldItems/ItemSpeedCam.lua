-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Inventory/ItemSpeedCam.lua
-- *  PURPOSE:     Speed Cam item class
-- *
-- ****************************************************************************
ItemSpeedCam = inherit(Item)
ItemSpeedCam.Map = {}

local MAX_SPEEDCAMS = 5
local COST_FACTOR = 5 -- 1km/h = 5$
local MIN_RANK = 2
local ALLOWED_SPEED = 80

function ItemSpeedCam:constructor()

end

function ItemSpeedCam:destructor()

end

function ItemSpeedCam:use(player)
	if player:getFaction() and player:getFaction():getId() == 1 and player:isFactionDuty() then
		if self:count() < MAX_SPEEDCAMS then
			if PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "faction", "useSpeedCam") then
				local result = self:startObjectPlacing(player,
					function(item, position, rotation)
						if item ~= self or not position then return end

						local worldItem = FactionWorldItem:new(self, player:getFaction(), position, rotation, false, player)
						worldItem:setFactionSuperOwner(true)
						--worldItem:setMinRank(MIN_RANK)

						player:getInventory():removeItem(self:getName(), 1)

						local object = worldItem:getObject()
						setElementData(object, "earning", 0)
						ItemSpeedCam.Map[#ItemSpeedCam.Map+1] = object


						object.col = worldItem:attach(createColTube(position, 12, 5))
						object.col.object = object
						self.m_func = bind(self.onColShapeHit, self)
						addEventHandler("onColShapeHit", object.col, self.m_func )

						object.radarDetectorCol = worldItem:attach(createColSphere(position, 100))
						self.m_RadarDetectorFunc = bind(self.onRadarDetectorColShapeHit, self)
						addEventHandler("onColShapeHit", object.radarDetectorCol, self.m_RadarDetectorFunc)

						local pos = player:getPosition()
						FactionState:getSingleton():sendShortMessage(_("%s hat einen Blitzer bei %s/%s aufgestellt!", player, player:getName(), getZoneName(pos), getZoneName(pos, true)))
						StatisticsLogger:getSingleton():itemPlaceLogs( player, "Blitzer", pos.x..","..pos.y..","..pos.z)
					end
				)
			else
				player:sendError(_("Du bist nicht berechtigt Blitzer aufzustellen!", player))
			end
		else
			player:sendError(_("Es sind bereits %d/%d Anlagen aufgestellt!", player, self:count(), MAX_SPEEDCAMS))
		end
	else
		player:sendError(_("Du bist nicht berechtigt! Das Item wurde abgenommen!", player))
		player:getInventory():removeAllItem(self:getName())
	end
end

function ItemSpeedCam:count()
	local count = 0
	for index, cam in pairs(ItemSpeedCam.Map) do
		count = count + 1
	end
	return count
end

function ItemSpeedCam:onColShapeHit(element, dim)
	if dim then
		if element:getType() == "vehicle" then
			if element:getSpeed() > ALLOWED_SPEED + 5 then
				if element:getOccupant() then
					local player = element:getOccupant()
					if player:getFaction() and (player:getFaction():isStateFaction() or player:getFaction():isRescueFaction()) and player:isFactionDuty() then return end
					local speed = math.floor(element:getSpeed())
					local costs = (speed-ALLOWED_SPEED)*COST_FACTOR

					local vehType = nil

					if element:getVehicleType() == VehicleType.Automobile then
						vehType = "Driving"
					elseif element:getVehicleType() == VehicleType.Bike then
						vehType = "Bike"
					end

					--give stvo points
					local stvoPoints = 0
					local oldSTVO = player:getSTVO(vehType)
					local newSTVO = 0
					if (vehType == "Driving" and player:hasDrivingLicense()) or (vehType == "Bike" and player:hasBikeLicense()) then
						if element:getSpeed() >= 90 and element:getSpeed() < 120 then
							stvoPoints = 3
							newSTVO = oldSTVO + stvoPoints
							player:setSTVO(vehType, newSTVO)
						elseif element:getSpeed() >= 120 then
							stvoPoints = 6
							newSTVO = oldSTVO + stvoPoints
							player:setSTVO(vehType, newSTVO)
						end

						if newSTVO > 0 then
							outputChatBox(_("Du hast %d STVO-Punkt/e erhalten! Gesamt: %d", player, stvoPoints, newSTVO), player, 255, 255, 0)
							outputChatBox(_("Grund: Rasen innerhalb der Stadt (%s km/h)", player, speed), player, 255, 255, 0 )

							local msg = ("Blitzer: %s hat %d STVO-Punkt/e wegen Rasen innerhalb der Stadt (%s km/h) erhalten!"):format(player:getName(), stvoPoints, speed)
							FactionState:getSingleton():addLog(player, "STVO", ("hat %s STVO-Punkte wegen Rasen innerhalb der Stadt (%s km/h) erhalten!"):format(stvoPoints, speed))
							FactionState:getSingleton():sendMessage(msg, 255,0,0)
						end
					else
						costs = costs * 3
					end

					player:transferBankMoney({FactionManager:getSingleton():getFromId(1), nil, true}, costs, "Blitzer-Strafe", "Gameplay", "Speedcam")
					player:sendShortMessage(_("Du wurdest mit %d km/h geblitzt!\nStrafe: %d$", player, speed, costs), "SA Police Department")

					player:giveAchievement(62)
					if speed > 180 then
						player:giveAchievement(63)
					end

					if player:getCompany() and player:isCompanyDuty() and player:getCompany():getId() == CompanyStaticId.SANNEWS then
						if element:getModel() == 582 then
							player:giveAchievement(99) -- Rasender Reporter
						end
					end

					setElementData(source.object, "earning", getElementData(source.object, "earning") + costs)
				end
			end
		end
	end
end

function ItemSpeedCam:onRadarDetectorColShapeHit(element, dim)
	if dim then
		if element:getType() == "vehicle" and instanceof(element, PermanentVehicle) then
			if element:getOccupant() and element:hasRadarDetector() then
				local player = element:getOccupant()
				player:sendWarning(_("Achtung! Das Radarwarngerät meldet einen Blitzer in der Nähe!", player))
			end
		end
	end
end

function ItemSpeedCam:removeFromWorld(player, worlditem)
	local object = worlditem:getObject()
	for index, cam in pairs(ItemSpeedCam.Map) do
		if cam == object then
			table.remove(ItemSpeedCam.Map, index)
		end
	end
end
