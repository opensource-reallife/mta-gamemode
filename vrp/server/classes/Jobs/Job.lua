-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Jobs/Job.lua
-- *  PURPOSE:     Abstract job class
-- *
-- ****************************************************************************
Job = inherit(Singleton)

function Job:constructor()
	self.m_DontEndOnVehicleDestroy = false
	self.m_OnJobVehicleDestroyBind = bind(self.onJobVehicleDestroy, self)
	self.m_Multiplicator = 0
end

function Job:getId()
	return self.m_Id
end

function Job:setId(Id)
	self.m_Id = Id
end

function Job:getMultiplicator()
	return self.m_Multiplicator / 100 + 1
end

function Job:setMultiplicator(mult)
	self.m_Multiplicator = mult
end

function Job:requireVehicle(player)
	return player:getJob() == self
end

function Job:registerJobVehicle(player, vehicle, countdown, stopJobOnDestroy)
	if isElement(player.jobVehicle) then
		destroyElement(player.jobVehicle)
	end
	player.jobVehicle = vehicle
	vehicle.jobPlayer = player
	setElementData(vehicle, "JobVehicle", true)

	addEventHandler("onVehicleStartEnter",vehicle, function(vehPlayer, seat)
		if seat==0 and vehPlayer ~= player then
			vehPlayer:sendError(_("Du kannst nicht in dieses Job-Fahrzeug!", vehPlayer))
			cancelEvent()
		end
	end)

	if countdown then
		vehicle:addCountdownDestroy(10)
	end

	if stopJobOnDestroy then
		addEventHandler("onVehicleExplode", vehicle, self.m_OnJobVehicleDestroyBind)
		addEventHandler("onElementDestroy", vehicle, self.m_OnJobVehicleDestroyBind, false)
	end
end

function Job:onJobVehicleDestroy()
	for key, obj in pairs(source:getAttachedElements()) do
		if obj:getAttachedElements() then
			for key2, obj2 in pairs(obj:getAttachedElements()) do
				obj2:destroy()
			end
		end

		obj:destroy()
	end

	removeEventHandler("onElementDestroy", source, self.m_OnJobVehicleDestroyBind)
	removeEventHandler("onVehicleExplode", source, self.m_OnJobVehicleDestroyBind)
	local player = source.jobPlayer

	if not self.m_DontEndOnVehicleDestroy then
		nextframe( -- Workaround to avoid Stack Overflow
			function()
				if player and player.setJob then
					player:setJob(nil)
				end
			end
		)
	end
end

function Job:destroyJobVehicle(player)
	if player.jobVehicle and isElement(player.jobVehicle) then
		destroyElement(player.jobVehicle)
	end
end

function Job:sendMessage(message, ...)
	for k, player in pairs(getElementsByType("player")) do
		if player:getJob() == self then
			player:sendMessage(_("[JOB] ", player).._(message, player, ...), 0, 0, 255)
		end
	end
end

function Job:countPlayers()
	local count = 0
	for k, player in pairs(getElementsByType("player")) do
		if player:getJob() == self then
			count = count + 1
		end
	end

	return count
end

Job.start = pure_virtual