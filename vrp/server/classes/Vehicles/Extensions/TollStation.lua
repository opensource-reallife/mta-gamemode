-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Vehicle/TollStation.lua
-- *  PURPOSE:     Toll Station Class
-- *
-- ****************************************************************************
TollStation = inherit(Object)

function TollStation:constructor(Name, BarrierPos, BarrierRot, PedPos, PedRot, type)
	self.m_Name = Name or "Unknown"
	self.m_Barrier = VehicleBarrier:new(BarrierPos, BarrierRot, 2.5, type, 1500)
	self.m_Barrier.onBarrierHit = bind(self.onBarrierHit, self)

	self.m_Ped = GuardActor:new(PedPos)
	self.m_Ped:giveWeapon(31, 999999999, true)
	self.m_Ped:setArmor(100)
	self.m_Ped:setRotation(PedRot)
	self.m_Ped:setFrozen(true)
	self.m_RespawnPos = PedPos
	self.m_RespawnRot = PedRot
	addEventHandler("onPedWasted", self.m_Ped, bind(self.onPedWasted, self))
	addEventHandler("onElementDestroy", self.m_Ped, bind(self.onPedDestroy, self))
	addEventHandler("onElementStartSync", self.m_Ped, bind(self.onPedStartSync, self))
end

function TollStation:destructor()
end

function TollStation:checkRequirements(player)
	-- Step 1: Check for State Duty
		if player:getFaction() then
			local faction = player:getFaction()
			if faction:isStateFaction() or faction:isRescueFaction() then
				if player:isFactionDuty() then
					player:sendShortMessage(_("Willkommen bei der Maut-Station %s! Da du Staats-Dienstlich unterwegs bist, darfst du kostenlos passieren! Gute Fahrt.", player, self.m_Name), _("Maut-Station: %s", player, self.m_Name), {125, 0, 0})
					return true
				end
			end
		end

		if player:getInventory():getItemAmount("Mautpass") > 0 then
			player:sendShortMessage(_("Willkommen bei der Maut-Station %s! Da du einen Mautpass besitzt, darfst du kostenlos passieren! Gute Fahrt.", player, self.m_Name), _("Maut-Station: %s", player, self.m_Name), {125, 0, 0})
			return true
		end

	return false
end

function TollStation:getBarrier()
	return self.m_Barrier
end

function TollStation:onBarrierHit(player)
	if player.vehicle and player:getOccupiedVehicleSeat() == 0 then
		if not self.m_Ped:isDead() then
			local veh = player.vehicle
			for seat, occupant in pairs(veh:getOccupants()) do
				if occupant:getWanteds() > 0 then
					for i, faction in pairs(FactionState:getSingleton():getFactions()) do
						faction:sendShortMessage(("Ein Beamter der Maut-Station %s meldet die Sichtung des Flüchtigen %s!"):format(self.m_Name, occupant:getName()), 10000)
					end
				end
			end

			local vehicleElements = getAttachedElements(player.vehicle)
			local vehicleElementsCount = 0

			if vehicleElements then
				for i, element in pairs(vehicleElements) do
					if element:getModel() == 2912 then
						vehicleElementsCount = vehicleElementsCount + 1
					end
				end
			end

			if
				player:getFaction()
				and not player:getFaction():isStateFaction()
				and (
					player:getPlayerAttachedObject()
					or vehicleElementsCount > 0
				)
				or
				not player:getFaction()
				and (
					player:getPlayerAttachedObject()
					or vehicleElementsCount > 0
				)
			then
				for i, faction in pairs(FactionState:getSingleton():getFactions()) do
					faction:sendShortMessage(("Ein Beamter der Maut-Station %s meldet die Sichtung eines auffälligen Transport!"):format(self.m_Name), 10000)
				end
			end

			if player:getOccupiedVehicleSeat() == 0 then
				if self:checkRequirements(player) then -- Check for Toll Pass
					return true
				else
					if player.m_BuyTollFunc then
						unbindKey(player, TOLL_PAY_KEY, "down", player.m_BuyTollFunc)
						player.m_BuyTollFunc = nil
					end

					player:sendShortMessage(_("Willkommen bei der Maut-Station %s! Drücke auf '%s' um ein Ticket zu kaufen!\nDu kannst dir aber auch an einem 24/7 einen Mautpass kaufen, dann fährst du unkompliziert und schnell durch die Maut-Stationen!", player, self.m_Name, TOLL_PAY_KEY:upper()), _("Maut-Station: %s", player, self.m_Name), {125, 0, 0})

					player.m_BuyTollFunc = bind(self.buyToll, self, player)
					bindKey(player, TOLL_PAY_KEY, "down", player.m_BuyTollFunc)
				end
			end
		else
			player:sendError(_("Diese Maut-Station ist derzeit geschlossen!", player))
		end
	end

	return false
end

function TollStation:buyToll(player)
	if isElement(player) then
		if (player:getPosition() - self.m_Barrier.m_Barrier:getPosition()).length <= 10 then
			if player:getBankMoney() >= TOLL_KEY_COSTS then
				player:transferBankMoney({FactionManager:getSingleton():getFromId(1), nil, true}, TOLL_KEY_COSTS, "Mautstation", "Gameplay", "Toll")
				self.m_Barrier:toggleBarrier(player, true)
				player:sendShortMessage(_("Vielen Dank. Wir wünschen dir eine gute Fahrt!", player), _("Maut-Station: %s", player, self.m_Name), {125, 0, 0})
			else
				player:sendError(_("Du hast zu wenig Geld auf deinem Bankkonto! (%s$)", player, TOLL_KEY_COSTS))
			end
		end

		unbindKey(player, TOLL_PAY_KEY, "down", player.m_BuyTollFunc)
		player.m_BuyTollFunc = nil
	end
end

function TollStation:onPedWasted(totalAmmo, killer)
	local killer = killer
	local wanteds = WANTED_AMOUNT_MURDER_TOLLSTATION
	if killer then
		if killer:getType() == "vehicle" then
			killer = killer:getOccupant()
		end

		if killer:getType() == "player" then
			if killer and killer:getFaction():isStateFaction() and killer:isFactionDuty() then return end
			outputDebug(("%s killed a Ped at %s"):format(killer:getName(), self.m_Name))

			-- Give Wanteds
			setTimer(function()
				killer:sendWarning(_("Deine illegalen Aktivitäten wurden von einem Augenzeugen an das SAPD gemeldet!", killer))
				killer:giveWanteds(wanteds)
				killer:sendMessage(_("Verbrechen begangen: %s, %d Wanted/s", killer, _("Mord", killer), wanteds), 255, 255, 0)
			end, math.random(2000, 10000), 1)

			-- Send the News to the San News Company
			CompanyManager:getSingleton():getFromId(CompanyStaticId.SANNEWS):sendShortMessage(("Ein Beamter an der Maut-Station %s wurde erschossen! Die Station bleibt bis auf weiteres geschlossen."):format(self.m_Name), 10000)

			self.m_Ped.m_Dead = true
			-- Create Rescue Team mission
			self.m_Ped:setAnimation("wuzi","cs_dead_guy", -1, true, false, false, true)
			FactionRescue:getSingleton():createPedDeathPickup(self.m_Ped, "Zollbeamter")
			self.m_Ped.m_AbortRescueTimer = setTimer(function()
				self.m_Ped:destroy()
			end, TOLL_PED_RESPAWN_TIME, 1)
		end
	end
end

function TollStation:onPedDestroy()
	if self.m_Ped.m_AbortRescueTimer and isTimer(self.m_Ped.m_AbortRescueTimer) then killTimer(self.m_Ped.m_AbortRescueTimer) end
	if self.m_Ped.m_DeathPickup then FactionRescue:getSingleton():removePedDeathPickup(self.m_Ped) end
	self.m_Ped = GuardActor:new(self.m_RespawnPos)
	self.m_Ped:giveWeapon(31, 999999999, true)
	self.m_Ped:setArmor(100)
	self.m_Ped:setRotation(self.m_RespawnRot)
	self.m_Ped:setFrozen(true)
	addEventHandler("onPedWasted", self.m_Ped, bind(self.onPedWasted, self))
	addEventHandler("onElementDestroy", self.m_Ped, bind(self.onPedDestroy, self))
	addEventHandler("onElementStartSync", self.m_Ped, bind(self.onPedStartSync, self))
end

function TollStation:onPedStartSync()
	if self.m_Ped:isDead() then
		self.m_Ped:setAnimation("wuzi","cs_dead_guy", -1, true, false, false, true)
	end
end

TollStation.Map = {}

function TollStation.initializeAll()
	for i, data in pairs(TOLL_STATIONS) do
		TollStation.Map[#TollStation.Map+1] = TollStation:new(data.Name, data.BarrierData.pos, data.BarrierData.rot, data.PedData.pos, data.PedData.rot, data.Type)
	end
end

function TollStation.openAll()
	for i, tollstation in pairs(TollStation.Map) do
		tollstation:getBarrier():open()
	end
end

function TollStation.closeAll()
	for i, tollstation in pairs(TollStation.Map) do
		tollstation:getBarrier():close()
	end
end
