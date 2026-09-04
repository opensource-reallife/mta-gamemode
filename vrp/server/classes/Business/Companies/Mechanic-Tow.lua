MechanicTow = inherit(Company)
addRemoteEvents{"mechanicRepair", "mechanicRepairConfirm", "mechanicRepairCancel", "mechanicDetachFuelTank", "mechanicTakeFuelNozzle", "mechanicRejectFuelNozzle", "mechanicTakeVehicle", "mechanicOpenTakeGUI", "mechanicVehicleRequestFill", "mechanicAttachBike", "mechanicDetachBike", "mechanicWreckTruckStart"}

MechanicTow.SpawnPositions = {
	{904.833, -1183.605, 16, 180},
	{900.833, -1183.605, 16, 180},
}

MechanicTow.WreckPositions = {
	{549, Vector3(2279.96, -1221.82, 23.74), 341.48}, -- Jefferson
	{542, Vector3(1822.29, -1176.24, 23.42), 67.06}, -- Glen Park
	{566, Vector3(1925.51, -1522.42, 3.13), 257.66}, -- Idlewood
	{466, Vector3(1873.29, -1849.98, 13.32), 208.13}, -- Idlewood
	{560, Vector3(2182.29, -1911.52, 13.26), 158.20}, -- Willowfield
	{543, Vector3(2584.96, -1779.13, 1.39), 339.54}, -- Ganton
	{589, Vector3(2730.65, -1186.91, 69.14), 173.78}, -- Los Flores
	{579, Vector3(1139.53, -1722.54, 13.67), 146.50}, -- Conference Center
	{492, Vector3(1010.04, -1447.67, 13.30), 41.05}, -- Market
	{467, Vector3(537.75, -1680.38, 18.52), 219.09}, -- Rodeo
	{410, Vector3(194.65, -1466.71, 12.62), 355.75}, -- Rodeo
	{496, Vector3(389.15, -1148.55, 77.87), 319.31}, -- Richman
	{436, Vector3(694.81, -1012.89, 51.68), 7.84}, -- Richman
	{429, Vector3(1200.12, -633.20, 103.72), 313.16}, -- Red County
	{506, Vector3(1656.06, -982.49, 37.80), 247.95}, -- Mulholland Intersection
}

function MechanicTow:constructor()
	self.m_PendingQuestions = {}
	self.m_TowedWrecks = 0

	local safe = createObject(2332, 857.594, -1182.628, 17.569, 0, 0, 270)
	safe:setScale(0.7)
	self:setSafe(safe)

	self.m_TowColShape = createColRectangle(861.296, -1258.862, 14, 17)

	local blip = Blip:new("CarLot.png", 913.83, -1234.65, root, 400)
	blip:setOptionalColor({150, 150, 150})
	blip:setDisplayText("Autohof", BLIP_CATEGORY.VehicleMaintenance)

	local id = self:getId()
	local blip = Blip:new("House.png", 857.594, -1182.628, {company = id}, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

	self.m_FillAccept = bind(MechanicTow.FillAccept, self)
	self.m_FillDecline = bind(MechanicTow.FillDecline, self)
	self.m_BankAccountServer = BankServer.get("company.mechanic")

	addEventHandler("onColShapeHit", self.m_TowColShape, bind(self.onEnterTowLot, self))
	addEventHandler("onColShapeLeave", self.m_TowColShape, bind(self.onLeaveTowLot, self))
	addEventHandler("mechanicRepair", root, bind(self.Event_mechanicRepair, self))
	addEventHandler("mechanicRepairConfirm", root, bind(self.Event_mechanicRepairConfirm, self))
	addEventHandler("mechanicRepairCancel", root, bind(self.Event_mechanicRepairCancel, self))
	addEventHandler("mechanicDetachFuelTank", root, bind(self.Event_mechanicDetachFuelTank, self))
	addEventHandler("mechanicTakeFuelNozzle", root, bind(self.Event_mechanicTakeFuelNozzle, self))
	addEventHandler("mechanicRejectFuelNozzle", root, bind(self.Event_mechanicRejectFuelNozzle, self))
	addEventHandler("mechanicVehicleRequestFill", root, bind(self.Event_mechanicVehicleRequestFill, self))
	addEventHandler("mechanicTakeVehicle", root, bind(self.Event_mechanicTakeVehicle, self))
	addEventHandler("mechanicOpenTakeGUI", root, bind(self.VehicleTakeGUI, self))
	addEventHandler("mechanicAttachBike", root, bind(self.Event_mechanicAttachBike, self))
	addEventHandler("mechanicDetachBike", root, bind(self.Event_mechanicDetachBike, self))
	addEventHandler("onTrailerAttach", root, bind(self.onAttachVehicleToTow, self))
	addEventHandler("onTrailerDetach", root, bind(self.onDetachVehicleFromTow, self))
	addEventHandler("mechanicWreckTruckStart", root, bind(self.Event_mechanicWreckTruckStart, self))

	PlayerManager:getSingleton():getQuitHook():register(bind(self.onPlayerQuit, self))

	self.m_WreckBind = bind(self.onWreckTimerUp, self)
	self:onWreckTimerUp()
end

function MechanicTow:destuctor()
end

function MechanicTow:onPlayerQuit(player)
	if isElement(player.mechanic_fuelNozzle) then
		player.mechanic_fuelNozzle:destroy()
	end
end

function MechanicTow:respawnVehicle(vehicle)
	outputDebug("Respawning vehicle in mechanic base")
	local occs = vehicle:getOccupants()
	if occs then
		for i, occ in pairs(occs) do
			occ:removeFromVehicle()
		end
	end
	if vehicle.m_RcVehicleUser then
		for i, player in pairs(vehicle.m_RcVehicleUser) do
			vehicle:toggleRC(player, player:getData("RcVehicle"), false, true)
			player:removeFromVehicle()
		end
	end
	if instanceof(vehicle, FactionVehicle, true) then -- respawn faction vehicles immediately
		vehicle:respawn(true, true)
		vehicle:getFaction():transferMoney(self, 1500, "Fahrzeug freigekauft", "Company", "VehicleFreeBought", {silent = true, allowNegative = true})
		vehicle:getFaction():sendShortMessage(("Das Fahrzeug %s (%s) wurde vom M&T abgeschleppt und für %s an eurer Basis respawned!"):format(vehicle:getName(), vehicle:getPlateText(), toMoneyString(1500)))
	elseif instanceof(vehicle, CompanyVehicle, true) then
		vehicle:respawn(true, true)
		vehicle:getCompany():transferMoney(self, 1500, "Fahrzeug freigekauft", "Company", "VehicleFreeBought", {silent = true, allowNegative = true})
		vehicle:getCompany():sendShortMessage(("Das Fahrzeug %s (%s) wurde vom M&T abgeschleppt und für %s an eurer Basis respawned!"):format(vehicle:getName(), vehicle:getPlateText(), toMoneyString(1500)))
	else 
		if instanceof(vehicle, GroupVehicle, true) then
			GroupManager.Map[vehicle:getOwner()]:transferMoney({"company", self:getId(), true, true}, 500, "Mech&Tow Abschleppkosten", "Company", "VehicleTowed")
		end
		if instanceof(vehicle, PermanentVehicle, true) then
			Async.create( -- player:load()/:save() needs a aynchronous execution
				function()
					local player, isOffline = DatabasePlayer.get(vehicle:getOwner())

					if isOffline then
						player:load()
					end

					player:transferBankMoney({"company", self:getId(), true, true}, 500, "Mech&Tow Abschleppkosten", "Company", "VehicleTowed")

					if isOffline then
						delete(player)
					end
				end
			)()
		end
		
		vehicle:setPositionType(VehiclePositionType.Mechanic)
		vehicle:setDimension(PRIVATE_DIMENSION_SERVER)
	end
	vehicle:fix()
end

function MechanicTow:VehicleTakeGUI(vehicleType)
	local vehicleTable = {}

	if vehicleType == "permanentVehicle" then
		vehicleTable = VehicleManager:getSingleton():getPlayerVehicles(client)
	elseif vehicleType == "groupVehicle" then
		local group = client:getGroup()
		if not group then client:sendError(_("Du bist in keiner Gruppe!", client)) return end
		vehicleTable = group:getVehicles()
	end

	-- Get a list of vehicles that need manual repairing
	local vehicles = {}
	for _, vehicle in pairs(vehicleTable) do
		if vehicle:getPositionType() == VehiclePositionType.Mechanic then
			table.insert(vehicles, vehicle)
		end
	end

	if #vehicles > 0 then
		-- Open "vehicle take GUI"
		-- Todo: Probably better: Trigger a vehicle table with different vehicle types and add specific tabs to VehicleTakeGUI
		client:triggerEvent("vehicleTakeMarkerGUI", vehicles, "mechanicTakeVehicle")
	else
		client:sendInfo(_("Keine abholbaren Fahrzeuge vorhanden!", client))
	end
end

function MechanicTow:Event_mechanicRepair()
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("Du bist nicht im Dienst!", client))
		return
	end

	local driver = source:getOccupant(0)
	if not driver then
		client:sendError(_("Jemand muss sich auf dem Fahrersitz befinden!", client))
		return
	end
	if driver == client then
		client:sendError(_("Steige aus deinem Fahrzeug aus und stelle dich dafür an die Motorhaube!", client))
		return
	end
	if source:getHealth() > 950 then
		client:sendError(_("Dieses Fahrzeug hat keine nennenswerten Beschädigungen!", client))
		return
	end

	if not source:isRepairAllowed() then
		client:sendError(_("Dieses Fahrzeug kann nicht repariert werden!", client))
		return
	end

	source.PendingMechanic = client
	local price = math.floor((1000 - getElementHealth(source))*0.5)

	if self.m_PendingQuestions[client] and not timestampCoolDown(self.m_PendingQuestions[client], 20) then
		client:sendError(_("Du kannst nur alle 20 Sekunden eine Reparatur-Anfrage stellen!", client))
		return
	end

	self.m_PendingQuestions[client] = getRealTime().timestamp
	QuestionBox:new(driver,  _("Darf %s dein Fahrzeug reparieren? Dies kostet dich zurzeit %d$!\nBeim nächsten Pay'n'Spray zahlst du einen Aufschlag von +33%%!", driver, getPlayerName(client), price), "mechanicRepairConfirm", "mechanicRepairCancel", client, 20, source)
end

function MechanicTow:Event_mechanicRepairConfirm(vehicle)
	local price = math.floor((1000 - getElementHealth(vehicle))*0.5)
	if source:getBankMoney() >= price then
		vehicle:fix()
		source:transferBankMoney(self.m_BankAccountServer, price, "Mech&Tow Reparatur", "Company", "Repair")

		if vehicle.PendingMechanic then
			if source ~= vehicle.PendingMechanic then
				self.m_PendingQuestions[vehicle.PendingMechanic] = getRealTime().timestamp

				self.m_BankAccountServer:transferMoney({vehicle.PendingMechanic, true}, price*0.3, "Reparatur", "Company", "Repair")
				vehicle.PendingMechanic:givePoints(2)
				vehicle.PendingMechanic:sendInfo(_("Du hast das Fahrzeug von %s erfolgreich repariert! Du hast %s$ verdient!", vehicle.PendingMechanic, getPlayerName(source), price*0.3))
				source:sendInfo(_("%s hat dein Fahrzeug erfolgreich repariert!", source, getPlayerName(vehicle.PendingMechanic)))

				self.m_BankAccountServer:transferMoney({"company", CompanyStaticId.MECHANIC, true, true}, price*0.6, "Reparatur", "Company", "Repair")
			else
				source:sendInfo(_("Du hat dein Fahrzeug erfolgreich repariert!", source))
			end
			vehicle.PendingMechanic = nil
		end
	else
		source:sendError(_("Du hast nicht genügend Geld! Benötigt werden %d$!", source, price))
	end
end

function MechanicTow:Event_mechanicRepairCancel(vehicle)
	if vehicle.PendingMechanic then
		vehicle.PendingMechanic:sendWarning(_("Der Reparaturvorgang wurde von der Gegenseite abgebrochen!", vehicle.PendingMechanic))
		vehicle.PendingMechanic = nil
	end
end

function MechanicTow:Event_mechanicTakeVehicle()
	if instanceof(source, GroupVehicle, true) then
		if not client:getGroup():transferMoney(self, 1000, "Fahrzeug freigekauft", "Company", "VehicleFreeBought") then
			client:sendError(_("In der Kasse deiner %s befindet sich nicht genügend Geld! (1000$)", client, client:getGroup():getType()))
			return false
		end
	else
		if client:getVehicleCountWithoutPrem() > client:getMaxVehicles() and not source:isPremiumVehicle() then
			local vehCount = 0
			for i, veh in pairs(client:getVehicles()) do
				if veh:getPositionType() == VehiclePositionType.World and not veh:isPremiumVehicle() then
					vehCount = vehCount + 1
				end
			end
			if vehCount >= client:getMaxVehicles() then
				client:sendError(_("Du hast nicht genug Platz, um ein Fahrzeug abzuholen", client))
				return false
			end
		end
		if not client:transferBankMoney(self, 1000, "Fahrzeug freigekauft", "Company", "VehicleFreeBought") then
			client:sendError(_("Du hast nicht genügend Geld! (1000$)", client))
			return false
		end
	end
	source:fix()

	-- Spawn vehicle in non-collision zone
	source:setPositionType(VehiclePositionType.World)
	source:setDimension(0)
	source:setInterior(0)
	local x, y, z, rotation = unpack(Randomizer:getRandomTableValue(MechanicTow.SpawnPositions))
	local text = "hinter dir"
	if source:isAirVehicle() and source:getModel() ~= 460 then
		x, y, z, rotation = 2008.82, -2453.75, 13, 120 -- ls airport east
		text = "am Flughafen in Los Santos"
	elseif source:isWaterVehicle() or source:getModel() == 460 then
		x, y, z, rotation = 2350.26, -2523.06, 0, 180 -- ls docks
		text = "an den Ocean Docks"
	end

	source:setPosition(x, y, z + source:getBaseHeight())
	source:setRotation(0, 0, rotation)
	client:sendSuccess(_("Fahrzeug freigekauft, es steht %s bereit! Das Geld wurde vom Konto abgezogen.", client, text))
end

function MechanicTow:isValidTowableVehicle(veh)
	return instanceof(veh, PermanentVehicle, true) or instanceof(veh, GroupVehicle, true) or instanceof(veh, FactionVehicle, true) or instanceof(veh, CompanyVehicle, true) or veh.burned
end

function MechanicTow:onEnterTowLot(hitElement)
	if getElementType(hitElement) ~= "player" then return end
	if hitElement:getCompany() ~= self then return end
	if hitElement:isCompanyDuty() ~= true then return end
	--if not hitElement.vehicle or not hitElement.vehicle.getCompany or hitElement.vehicle:getCompany() ~= self or (hitElement.vehicle:getModel() ~= 525 and hitElement.vehicle:getModel() ~= 417) then return end
	if not hitElement.vehicle or (hitElement.vehicle:getModel() ~= 525 and hitElement.vehicle:getModel() ~= 417) then return end

	local towingBike = hitElement.vehicle:getData("towingBike")
	if isElement(towingBike) then
		if towingBike:getOwnerType() == 3 and towingBike:getOwner() == 2 then return hitElement:sendError(_("Du kannst keine Fahrzeuge deines Unternehmens abschleppen!", hitElement)) end
		if towingBike.burned then
			if towingBike.Blip then
				towingBike.Blip:delete()
			end
			self:addLog(hitElement, "Abschlepp-Logs", ("hat ein Fahrzeug-Wrack (%s)  abgeschleppt!"):format(towingBike:getName()))
			towingBike:destroy()
			hitElement.vehicle:setData("towingBike", nil, true)
			hitElement:sendInfo(_("Du hast erfolgreich ein Fahrzeug-Wrack abgeschleppt!", hitElement))
			self.m_TowedWrecks = self.m_TowedWrecks + 1
		else
			towingBike:toggleRespawn(true)
			towingBike:setCollisionsEnabled(true)
			towingBike:detach()
			self:respawnVehicle(towingBike)

			towingBike:setData("towedByVehicle", nil, true)
			hitElement.vehicle:setData("towingBike", nil, true)

			StatisticsLogger:getSingleton():vehicleTowLogs(hitElement, towingBike)
			self:addLog(hitElement, "Abschlepp-Logs", ("hat ein Fahrzeug (%s) von %s abgeschleppt!"):format(towingBike:getName(), getElementData(towingBike, "OwnerName") or "Unbekannt"))
		end
		self.m_BankAccountServer:transferMoney(self, 500, "Fahrzeug abgeschleppt", "Company", "Towed")
		self.m_BankAccountServer:transferMoney({hitElement, true}, 250, "Fahrzeug abgeschleppt", "Company", "Towed")
	else
		hitElement.vehicle:setData("towingBike", nil, true)
	end

	hitElement.m_InTowLot = true
	hitElement:sendInfo(_("Du kannst hier abgeschleppte Fahrzeuge abladen!", hitElement))
end

function MechanicTow:sendWarning(text, header, withOffDuty, pos, ...)
	for k, player in pairs(self:getOnlinePlayers(false, not withOffDuty)) do
		player:sendWarning(_(text, player, ...), 30000, _(header, player))
	end
	if pos and pos.x then pos = {pos.x, pos.y, pos.z} end -- serialiseVector conversion
	if pos and pos[1] and pos[2] then
		local blip = Blip:new("Warning.png", pos[1], pos[2], {company = self:getId()}, 4000, BLIP_COLOR_CONSTANTS.Orange)
			blip:setDisplayText(header)
		if pos[3] then
			blip:setZ(pos[3])
		end
		setTimer(function()
			blip:delete()
		end, 30000, 1)
	end
end

function MechanicTow:onLeaveTowLot(hitElement)
	if getElementType(hitElement) ~= "player" then return end
	hitElement.m_InTowLot = nil
end

function MechanicTow:onAttachVehicleToTow(towTruck)
	local driver = getVehicleOccupant(towTruck)
	if driver and getElementType(driver) == "player" then
		if driver:getCompany() == self and driver:isCompanyDuty() then
			if towTruck:getModel() == 525 then --towTruck.getCompany and towTruck:getCompany() == self and towTruck:getModel() == 525 then
				if self:isValidTowableVehicle(source) then
					source:toggleRespawn(false)
					source.m_HasBeenUsed = 1 --disable despawn on logout
				else
					driver:sendInfo(_("Dieses Fahrzeug kann nicht abgeschleppt werden!", driver))
				end
			end
		end
	end
end

function MechanicTow:onDetachVehicleFromTow(towTruck, vehicle)
	local source = vehicle and vehicle or source
	source:toggleRespawn(true)

	local driver = getVehicleOccupant(towTruck)
	if driver and driver.m_InTowLot then
		if driver:getCompany() == self and driver:isCompanyDuty() then
			if towTruck:getModel() == 525 then --towTruck.getCompany and towTruck:getCompany() == self then
				if self:isValidTowableVehicle(source) then
					if source:getOwnerType() == 3 and source:getOwner() == 2 then return driver:sendError(_("Du kannst keine Fahrzeuge deines Unternehmens abschleppen!", driver)) end
					if not source.burned then
						self:respawnVehicle(source)
						driver:sendInfo(_("Das Fahrzeug ist nun abgeschleppt!", driver))
						StatisticsLogger:getSingleton():vehicleTowLogs(driver, source)
						self:addLog(driver, "Abschlepp-Logs", ("hat ein Fahrzeug (%s) von %s abgeschleppt!"):format(source:getName(), getElementData(source, "OwnerName") or "Unbekannt"))
					else
						if source.Blip then
							source.Blip:delete()
						end
						self:addLog(driver, "Abschlepp-Logs", ("hat ein Fahrzeug-Wrack (%s) abgeschleppt!"):format(source:getName()))
						source:destroy()
						driver:sendInfo(_("Du hast erfolgreich ein Fahrzeug-Wrack abgeschleppt!", driver))
						self.m_TowedWrecks = self.m_TowedWrecks + 1
					end
					self.m_BankAccountServer:transferMoney(self, 500, "Fahrzeug abgeschleppt", "Company", "Towed")
					self.m_BankAccountServer:transferMoney({driver, true}, 250, "Fahrzeug abgeschleppt", "Company", "Towed")
				else
					driver:sendWarning(_("Dieses Fahrzeug kann nicht abgeschleppt werden!", driver))
				end
			end
		end
	end
end

function MechanicTow:Event_mechanicDetachFuelTank(vehicle)
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("Du bist nicht im Dienst!", client))
		return
	end

	if vehicle.getCompany and vehicle:getCompany() == self then
		vehicle:detachTrailer()
	end
end

function MechanicTow:Event_mechanicTakeFuelNozzle(vehicle)
	if client:getCompany() ~= self then
		return
	end
	if not client:isCompanyDuty() then
		client:sendError(_("Du bist nicht im Dienst!", client))
		--return
	end

	if vehicle.getCompany and vehicle:getCompany() == self then
		if isElement(client.mechanic_fuelNozzle) then
			toggleControl(client, "fire", true)
			client:setPrivateSync("hasMechanicFuelNozzle", false)
			client:triggerEvent("closeFuelTankGUI")
			client:triggerEvent("forceCloseVehicleFuel")
			client.mechanic_fuelNozzle:destroy()
			return
		end

		if not vehicle.towingVehicle then return end

		client.mechanic_fuelNozzle = createObject(1909, client.position)
		client.mechanic_fuelNozzle:setData("attachedToVehicle", vehicle, true)
		client.mechanic_fuelNozzle.vehicle = vehicle
		exports.bone_attach:attachElementToBone(client.mechanic_fuelNozzle, client, 12, -0.03, 0.02, 0.05, 180, 320, 0)

		client:setPrivateSync("hasMechanicFuelNozzle", vehicle)
		client:triggerEvent("showFuelTankGUI", vehicle, vehicle:getFuel(), vehicle:getFuelTankSize(true))
		toggleControl(client, "fire", false)
	end
end

function MechanicTow:Event_mechanicRejectFuelNozzle()
	if isElement(client.mechanic_fuelNozzle) then
		toggleControl(client, "fire", true)
		client:setPrivateSync("hasMechanicFuelNozzle", false)
		client:triggerEvent("closeFuelTankGUI")
		client:triggerEvent("forceCloseVehicleFuel")
		client.mechanic_fuelNozzle:destroy()
		return
	end
end

function MechanicTow:Event_mechanicVehicleRequestFill(vehicle, fuel)
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then client:sendError(_("Du bist nicht im Dienst!", client)) return end
	if not vehicle then return end
	if not vehicle.controller then return end

	if vehicle.controller.fillRequest then
		client:sendError("Der Spieler hat bereits eine Anfrage bekommen")
		return
	end

	local fuel = vehicle:getFuel() + fuel > 100 and math.floor(100 - vehicle:getFuel()) or math.floor(fuel)
	local price = math.floor(fuel * 1.5)

	if fuel == 0 then
		client:sendError("Das Fahrzeug ist bereits vollgetankt!")
		return
	end

	local fuelTank = client:getPrivateSync("hasMechanicFuelNozzle")
	local fuelTrailer = vehicle:getModel()
	if (fuelTrailer == 611 and fuel > fuelTank:getFuel()*5) or (fuelTrailer == 584 and fuel > fuelTank:getFuel()*15) then
		client:sendError("Im Tankanhänger ist nicht genügend Benzin!")
		return
	end

	QuestionBox:new(vehicle.controller,  _("%s möchte dein Fahrzeug tanken. %s Liter zum Preis von %s$", vehicle.controller, client:getName(), fuel, price), self.m_FillAccept, self.m_FillDecline, client, 20, client, vehicle.controller, vehicle, fuel, price)
	client:sendInfo("Dem Spieler wurde dein Service angeboten..")
	vehicle.controller.fillRequest = true
end

function MechanicTow:FillAccept(player, target, vehicle, fuel, price)
	target.fillRequest = false

	local fuelTank = player:getPrivateSync("hasMechanicFuelNozzle")
	if fuelTank then
		local fuelTrailerId = fuelTank:getModel()

		if (fuelTrailerId == 611 and fuel > fuelTank:getFuel() * 5) or (fuelTrailerId == 584 and fuel > fuelTank:getFuel() * 15) then
			player:sendError("Im Tankanhänger ist nicht genügend Benzin!")
			return
		end

		if target:getBankMoney() >= price then
			target:transferBankMoney(self.m_BankAccountServer, price, "Mech&Tow tanken", "Company", "Refill")
			vehicle:setFuel(vehicle:getFuel() + fuel)

			self.m_BankAccountServer:transferMoney({player, true}, math.floor(price*0.3), "Mech&Tow tanken", "Company", "Refill")
			self.m_BankAccountServer:transferMoney(self, math.floor(price*0.7), "Tanken", "Company", "Refill")

			local fuelDiff
			if fuelTrailerId == 611 then
				fuelDiff = fuel / 5
			elseif fuelTrailerId == 584 then
				fuelDiff = fuel / 15
			end

			fuelTank:setFuel(fuelTank:getFuel() - fuelDiff)
			player:triggerEvent("updateFuelTankGUI", math.floor(fuelTank:getFuel()))
		else
			target:sendError(_("Du hast nicht genügend Geld! Benötigt werden %d$!", target, price))
			player:sendError(_("Der Spieler hat nicht genügend Geld!", player))
		end
	else
		player:sendError(_("Der Tankanhänger wurde nicht mehr erkannt, bitte Tankvorgang wiederholen!", player))
	end
end

function MechanicTow:FillDecline(player, target)
	target.fillRequest = false
	player:sendError(_("Der Spieler möchte deinen Service nicht nutzen.", player))
end

function MechanicTow:Event_mechanicAttachBike(vehicle)
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then return end
	if not client.vehicle then return end
	if client.vehicle:getData("towingBike") then return end
	if not VEHICLES_THAT_CAN_TOW_BIKES[client.vehicle:getModel()] then return end

	if vehicle and vehicle:isEmpty() then
		if self:isValidTowableVehicle(vehicle) then
			if not vehicle.m_HandBrake then
				vehicle:toggleRespawn(false)
				client.vehicle:setData("towingBike", vehicle, true)
				vehicle:setData("towedByVehicle", client.vehicle, true)

				-- Following is all cause of the animation. Shit happens..
				local object = createObject(1337, vehicle.position, vehicle.rotation)
				local diffRotation = client.vehicle.rotation.z - vehicle.rotation.z
				object:setAlpha(0)
				object:setCollisionsEnabled(false)

				vehicle:setCollisionsEnabled(false)
				vehicle:attach(object)

				client.vehicle:setFrozen(true)
				client.vehicle.m_DisableToggleHandbrake = true

				object:move(2500, client.vehicle.matrix:transformPosition(Vector3(0, -1.1, .8)), 0, 0, diffRotation + 90, "InOutQuad")

				client.vehicle.towTimer = setTimer(
					function(towTruck, bike, object)
						object:destroy()
						towTruck:setFrozen(false)
						towTruck.m_DisableToggleHandbrake = false
						bike:attach(towTruck, 0, -1.1, .8, 0, 0, 90)
						bike.m_HasBeenUsed = 1 --disable despawn on logout
					end, 2500, 1, client.vehicle, vehicle, object
				)
			else
				client:sendError(_("Du musst zuerst die Handbremse lösen!", client))
			end
		else
			client:sendError(_("Dieses %s kann nicht abgeschleppt werden!", client, vehicle:getVehicleType() == VehicleType.Bike and "Motorrad" or "Fahrrad"))
		end
	end
end

function MechanicTow:Event_mechanicDetachBike()
	if client:getCompany() ~= self then return end
	if not client:isCompanyDuty() then return end
	if not client.vehicle then return end

	if isTimer(client.vehicle.towTimer) then
		client:sendWarning("Bitte warte einen Moment während das Fahrzeug aufgeladen wird!")
		return
	end

	local towingBike = client.vehicle:getData("towingBike")
	if towingBike then
		towingBike:toggleRespawn(true)
		towingBike:detach()
		towingBike:setPosition(client.vehicle.matrix:transformPosition(Vector3(-2, 0, 0)))
		towingBike:setRotation(client.vehicle.rotation)
		towingBike:setCollisionsEnabled(true)

		towingBike:setData("towedByVehicle", nil, true)
		client.vehicle:setData("towingBike", nil, true)
	end
end

function MechanicTow:checkLeviathanTowing(player, vehicle)
	if player.vehicle and vehicle then
		self:onDetachVehicleFromTow(player.vehicle, vehicle)
	end
end

function MechanicTow:onWreckTimerUp()
	if table.size(self:getOnlinePlayers(true, true)) >= 1 then
		local wrecks = 0
		for k, vehicle in pairs(getElementsByType("vehicle")) do
			if vehicle.burned then wrecks = wrecks + 1 end
		end
		if wrecks < 3 then
			self:createRandomVehicleWreck()
		end
	end

	if isTimer(self.m_WreckTimer) then killTimer(self.m_WreckTimer) end
	self.m_WreckTimer = Timer(self.m_WreckBind, Randomizer:get(3, 7) * 60 * 1000, 1)
end

function MechanicTow:createRandomVehicleWreck()
	local model, pos, rot = unpack(Randomizer:getRandomTableValue(MechanicTow.WreckPositions))
	if not getElementsWithinRange(pos, 20, "vehicle", 0, 0)[1] and not getElementsWithinRange(pos, 100, "player", 0, 0)[1] then
		self:createVehicleWreck(model, pos, rot, color)
	end
end

function MechanicTow:createVehicleWreck(model, pos, rotZ, color)
	local tempVehicle = TemporaryVehicle.create(model, pos.x, pos.y, pos.z, rotZ)
	tempVehicle:setHealth(300)
	if color then
		tempVehicle:setColor(unpack(color))
	end
	tempVehicle:disableRespawn(true)
	tempVehicle:setLocked(true)
	tempVehicle:setData("Burned", true, true)
	tempVehicle.burned = true
	tempVehicle.Blip = Blip:new("CarShop.png", 0, 0, {company = CompanyStaticId.MECHANIC}, 400)
	tempVehicle.Blip:setColor({150, 150, 150}) -- gets deleted on tow
	tempVehicle.Blip:setDisplayText("Fahrzeug-Wrack")
	tempVehicle.Blip:attachTo(tempVehicle)

	local zone = getZoneName(pos).." - "..getZoneName(pos, true)
	CompanyManager:getSingleton():getFromId(CompanyStaticId.MECHANIC):sendWarning("Ein Fahrzeug-Wrack muss abgeschleppt werden! Position: %s", "Fahrzeug-Wrack", true, pos, zone)
	for i= 0, 5 do tempVehicle:setDoorState(i, chance(50) and 2 or 4) end
	tempVehicle:setWheelStates(chance(50) and 1 or 0, chance(50) and 1 or 0, chance(50) and 1 or 0, chance(50) and 1 or 0)
end

function MechanicTow:Event_mechanicWreckTruckStart()
	if source ~= client then return end
	local player = client

	local requiredWrecks = 3
	if requiredWrecks > self.m_TowedWrecks then
		return player:sendError(_("Es sind noch nicht genügend Fahrzeug-Wracks abgeschleppt worden! (%d/%d)", player, self.m_TowedWrecks, requiredWrecks))
	end

	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(player, "company", "startWreckTruck") then
		return player:sendError(_("Du bist nicht berechtigt einen Schrottplatz-Transport zu starten!", player))
	end

	if player:getCompany() and player:getCompany():getId() == CompanyStaticId.MECHANIC and player:isCompanyDuty() then
		self.m_TowedWrecks = self.m_TowedWrecks - requiredWrecks

		local start = Vector3(882.80, -1226.39, 17.27)
		local destination = Vector3(-1908.87, -1716.91, 21.76)

		local marker = createMarker(destination.x, destination.y, destination.z - 1, "cylinder", 5, 255, 0, 0, 122, player)
		local blip = Blip:new("Marker.png", destination.x, destination.y, player, 9999, BLIP_COLOR_CONSTANTS.Red)

		local vehicle = TemporaryVehicle.create(578, start.x, start.y, start.z + 0.5, 0)
		local color = companyColors[self:getId()]
		vehicle:addCountdownDestroy(10)
		vehicle:setColor(color.r, color.g, color.b, color.r, color.g, color.b)

		for i = 0, requiredWrecks - 1 do
			local wreck = createObject(3594, 0, 0, 0)
			wreck:attach(vehicle, 0, -1.7, 0.3 + i)
		end

		addEventHandler("onMarkerHit", marker, function(hitElement, matchingDimension)
			if matchingDimension and hitElement == vehicle then
				local driver = hitElement:getOccupant(0)
				if not source.m_SecondHit then
					driver:sendSuccess(_("Transport abgeschlossen! Fahre zurück, um deine Bezahlung zu erhalten!", driver))
					self:addLog(player, "Schrottplatz-Transport", "hat einen Schrottplatz-Transport abgeschlossen!")
					self.m_BankAccountServer:transferMoney(self, 3000, "Schrottplatz-Transport", "Company", "WreckTruck")
					for k, v in pairs(hitElement:getAttachedElements()) do
						v:destroy()
					end
					source:setPosition(start.x, start.y, start.z - 1)
					blip:setPosition(start)
					player:startNavigationTo(start)
					source.m_SecondHit = true
				else
					self.m_BankAccountServer:transferMoney({driver, true}, 750, "Schrottplatz-Transport", "Company", "WreckTruck")
					hitElement:destroy()
				end
			end
		end)
	
		addEventHandler("onElementDestroy", vehicle, function()
			if blip then blip:delete() end
			if marker then marker:destroy() end
			for k, v in pairs(source:getAttachedElements()) do
				v:destroy()
			end
		end)

		player:warpIntoVehicle(vehicle)
		player:sendInfo(_("Fahre zum auf der Karte markierten Schrottplatz!", player))
		player:startNavigationTo(destination)

		self:addLog(player, "Schrottplatz-Transport", "hat einen Schrottplatz-Transport gestartet!")
		self:sendShortMessage("Ein Schrottplatz-Transport wurde gestartet!")
	else
		player:sendError(_("Du bist nicht im Dienst deines Unternehmens aktiv!", player))
	end
end