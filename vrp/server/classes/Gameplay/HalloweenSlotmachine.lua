-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/HalloweenSlotmachine.lua
-- *  PURPOSE:     HalloweenSlotmachine class
-- *
-- ****************************************************************************
HalloweenSlotmachine = inherit(Object)
HalloweenSlotmachine.Slots = {
	[1] = "VIP",
	[2] = "Pumpkin",
	[3] = "Vehicle",
	[4] = "Money",
	[5] = "Pumpkins",
	[6] = "Sweets",
}
slot_machines = {}

function HalloweenSlotmachine:constructor(x, y, z, rx, ry, rz, int, dim)
	if not int then
		int = 0
	end
	if not dim then
		dim = 0
	end

	self.ms_Settings = {}

	-- Methods
	self.m_ResultFunc = bind(self.doResult, self)
	self.m_ResetFunc = bind(self.reset, self)
	self.m_StartFunc = bind(self.startPlayer, self)
	self.m_HebelClickFunc = function(btn, state, player)
		local dist = getDistanceBetweenPoints3D(source:getPosition(), player:getPosition())
		if dist <= 5 then
			if btn == "left" and state == "down" then
				self:startPlayer(player)
			end
		end
	end;
	-- Instances

	self.m_Objects = {}

	self.m_Objects.rolls = {}
	-- self.hebel
	-- self.wood
	-- self.gun
	self.canSpin = true

	self.ms_Settings.iconNames = {
		[900] = HalloweenSlotmachine.Slots[1],
		[1100] = HalloweenSlotmachine.Slots[1],
		[1300] = HalloweenSlotmachine.Slots[2],
		[1400] = HalloweenSlotmachine.Slots[4],
		[1500] = HalloweenSlotmachine.Slots[4],
		[1600] = HalloweenSlotmachine.Slots[4],
		[1700] = HalloweenSlotmachine.Slots[6],
		[1800] = HalloweenSlotmachine.Slots[3],
		[1900] = HalloweenSlotmachine.Slots[6],
		[2000] = HalloweenSlotmachine.Slots[4],
		[2100] = HalloweenSlotmachine.Slots[6],
		[2300] = HalloweenSlotmachine.Slots[6],
		[2140] = HalloweenSlotmachine.Slots[5],
	}

	-- Objects
	-- HalloweenSlotmachine


	self.m_Objects.slotmachine = createObject(2325, x, y, z, rx, ry, rz)
	self.m_Objects.slotmachine:setData("Halloween", true, true)
	self.m_BankAccountServer = BankServer.get("event.halloween")

	setObjectScale(self.m_Objects.slotmachine, 2)

	slot_machines[self.m_Objects.slotmachine] = self.m_Objects.slotmachine;
	-- Rolls

	for i = 1, 3, 1 do
		self.m_Objects.rolls[i] = createObject(2347, x, y, z)
		setElementData(self.m_Objects.rolls[i], "HalloweenSlotmachine", true)
		setObjectScale(self.m_Objects.rolls[i], 2)
		attachElements(self.m_Objects.rolls[i], self.m_Objects.slotmachine, -0.45+i/4, 0, 0)
	end

	-- Lever ( Hebel )

	self.m_Objects.hebel = createObject(1319, x, y, z)
	attachElements(self.m_Objects.hebel, self.m_Objects.slotmachine, 0.9, -0.3, 0, 50, 0, rz*(360)/90)
	setElementFrozen(self.m_Objects.hebel, true)
	setElementData(self.m_Objects.hebel, "SLOTMACHINE:LEVER", true)
	self.m_Objects.hebel:setData("clickable", true, true)

	-- Wood

	self.m_Objects.wood = createObject(3260, x, y, z)
	setObjectScale(self.m_Objects.wood, 0.7)
	attachElements(self.m_Objects.wood, self.m_Objects.slotmachine, 0, 0.5, -0.5)


	-- Dimension and Interior

	for index, object in pairs(self.m_Objects) do
		if type(object) == "table" then
			for index, e1 in pairs(object) do
				setElementInterior(e1, int)
				setElementDimension(e1, dim)
			end
		else
			setElementInterior(object, int)
			setElementDimension(object, dim)
		end
	end

--	outputDebugString("[CALLING] HalloweenSlotmachine: Constructor")

	-- Events --
	addEventHandler("onElementClicked", self.m_Objects.hebel, self.m_HebelClickFunc)
	setElementData(self.m_Objects.hebel, "SLOTMACHINE:ID", self) -- Store the Object in the element data
end

-- ///////////////////////////////
-- ///// reset		 		//////
-- ///// Returns: bool		//////
-- ///////////////////////////////

function HalloweenSlotmachine:reset()
	if self.canSpin == false then
		self.canSpin = true

		return true;
	end
end

-- Premium
-- Vehicle
-- 5 Pumpkins
-- Money
-- 1 Pumpkin
-- Sweets

function HalloweenSlotmachine:calculateSpin()
	local spinTable = {
		1100, -- Premium -- "increased"
		1800, -- Vehicle
		1800, -- Vehicle
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		2140, -- 5 Pumpkins
		1500, -- Money
		1600, -- Money
		2000, -- Money
		1600, -- Money
		1400, -- Money
		1500, -- Money
		1500, -- Money
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1300, -- 1 Pumpkin
		1700, -- Sweets
		1900, -- Sweets
		2100, -- Sweets
		2300, -- Sweets
		1700, -- Sweets
		1700, -- Sweets
		1900, -- Sweets
		2100, -- Sweets
	}

	local rotation = spinTable[Randomizer:get(1, #spinTable)]
	return rotation, self.ms_Settings.iconNames[rotation]
end

function HalloweenSlotmachine:moveLever(player)
	local x, y, z = getElementPosition(self.m_Objects.hebel)
	local _, _, _, rx, ry, rz = getElementAttachedOffsets(self.m_Objects.hebel)
	local _, _, rz = getElementRotation(self.m_Objects.slotmachine)
	detachElements(self.m_Objects.hebel)

	setElementPosition(self.m_Objects.hebel, x, y, z)
	setElementRotation(self.m_Objects.hebel, rx, ry, rz)

	moveObject(self.m_Objects.hebel, 450, x, y, z, 50, 0, 0, "InQuad")

	setTimer(
		function()
			moveObject(self.m_Objects.hebel, 450, x, y, z, -50, 0, 0, "InQuad")
		end, 450, 1
	)

	local int, dim = self.m_Objects.slotmachine:getInterior(), self.m_Objects.slotmachine:getDimension()
	setTimer(triggerClientEvent, 150, 1, root, "onSlotmachineSoundPlay", root, x, y, z, "start_machine", int, dim)


	setTimer(function() self:spin(player) end, 500, 1, player)

	return true;
end

function HalloweenSlotmachine:spin(player)
	local ergebnis = {}
	for i = 1, 3, 1 do
		local grad, icon = self:calculateSpin()
		local x, y, z = getElementPosition(self.m_Objects.rolls[i])
		local _, _, _, rx, ry, rz = getElementAttachedOffsets(self.m_Objects.rolls[i])
		rx, _, _ = getElementRotation(self.m_Objects.rolls[i])
		_, _, rz = getElementRotation(self.m_Objects.slotmachine)

		if isElementAttached(self.m_Objects.rolls[i]) then
			detachElements(self.m_Objects.rolls[i])

			setElementPosition(self.m_Objects.rolls[i], x, y, z)
			setElementRotation(self.m_Objects.rolls[i], rx, ry, rz)

		end

		moveObject(self.m_Objects.rolls[i], 2500+(i*600), x, y, z, grad, 0, 0, "InQuad")

		ergebnis[i] = icon
	end

	setTimer(self.m_ResultFunc, 4100, 1, ergebnis, player)
	return true;
end

function HalloweenSlotmachine:checkRolls()
	for i = 1, 3, 1 do
		local x, y, z = getElementPosition(self.m_Objects.rolls[i])
		if not isElementAttached(self.m_Objects.rolls[i]) then
			local rx, ry, _ = getElementRotation(self.m_Objects.rolls[i])

			moveObject(self.m_Objects.rolls[i], 100, x, y, z, -rx, 0, 0, "InQuad")
		end
	end
end

function HalloweenSlotmachine:start(player)
	if self.canSpin == true then
		self.canSpin = false;
		self:checkRolls()
		setTimer(function()
			self:moveLever(player)
		end, 100, 1)
	end
end

function HalloweenSlotmachine:giveWin(player, name, x, y, z)
	if name == "Trostpreis" then
		local rnd = Randomizer:get(50, 100)
		player:sendInfo(_("Du hast %d$ gewonnen!", player, rnd))
		self.m_BankAccountServer:transferMoney(player, rnd, "HalloweenSlotmachine", "Event", "Halloween")

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_stuff")
		StatisticsLogger:addCasino(player, "Money", rnd)
	elseif name == "Money" then
		local rnd = Randomizer:get(2500, 7500)
		player:sendInfo(_("Du hast %d$ gewonnen!", player, rnd))
		self.m_BankAccountServer:transferMoney(player, rnd, "HalloweenSlotmachine", "Event", "Halloween")

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_stuff")
		StatisticsLogger:addCasino(player, name, rnd)
	elseif name == "Pumpkin" then
		local amount = 5
		player:sendInfo(_("Du hast %d Kürbisse gewonnen!", player, amount))
		player:getInventory():giveItem("Kürbis", amount)

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_stuff")
		StatisticsLogger:addCasino(player, "Pumpkins", amount)
	elseif name == "Pumpkins" then
		local amount = 20
		player:sendInfo(_("Du hast %d Kürbisse gewonnen!", player, amount))
		player:getInventory():giveItem("Kürbis", amount)

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_stuff")
		StatisticsLogger:addCasino(player, name, amount)
	elseif name == "Premium" then
		player:sendInfo(_("Du hast einen Monat Premium gewonnen! Gratulation!", player))
		player.m_Premium:giveEventMonth()

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_jackpot")
		StatisticsLogger:addCasino(player, name, 1)
	elseif name == "Sweets" then
        local amount = 35
		player:sendInfo(_("Du hast 35 Süßigkeiten gewonnen!", player))
		player:getInventory():giveItem("Suessigkeiten", amount)

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_stuff")
		StatisticsLogger:addCasino(player, name, amount)
	elseif name == "Vehicle" then
		local vehicleData = { id=463, name="Freeway", spawnPosX=957.79, spawnPosY=-1115.1, spawnPosZ=23.23, spawnPosXR=0, spawnPosYR=0, spawnPosZR=180 }

		player:sendInfo(_("Du hast einen %s gewonnen! Gückwunsch!", player, vehicleData.name))
		local vehicle = VehicleManager:getSingleton():createNewVehicle(player, VehicleTypes.Player, vehicleData.id, vehicleData.spawnPosX, vehicleData.spawnPosY, vehicleData.spawnPosZ, vehicleData.spawnPosXR, vehicleData.spawnPosYR, vehicleData.spawnPosZR, 0, -1, -1, 0)
		if vehicle then
			warpPedIntoVehicle(player, vehicle)
			player:triggerEvent("vehicleBought")
		else
			player:sendMessage(_("Fehler beim Erstellen des Fahrzeugs. Bitte benachrichtige einen Admin!", player), 255, 0, 0)
		end

		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_jackpot")
		StatisticsLogger:addCasino(player, name, 1)
	else
		player:sendError(_("Unbekannter Gewinn! %s", player, name))
	end
end

function HalloweenSlotmachine:doResult(ergebnis, player)
	local x, y, z = getElementPosition(self.m_Objects.slotmachine)

	local result = {}
	for index, name in pairs(HalloweenSlotmachine.Slots) do
		result[name] = 0
	end

	for _, data in pairs(ergebnis) do
		result[data] = result[data]+1
	end

	if result["VIP"] == 3 then
		self:giveWin(player, "Premium", x, y, z)
	elseif result["Pumpkin"] == 3 then
		self:giveWin(player, "Pumpkin", x, y, z)
	elseif result["Vehicle"] == 3 then
		self:giveWin(player, "Vehicle", x, y, z)
	elseif result["Money"] == 3 then
		self:giveWin(player, "Money", x, y, z)
	elseif result["Pumpkins"] == 3 then
		self:giveWin(player, "Pumpkins", x, y, z)
	elseif result["Sweets"] == 3 then
		self:giveWin(player, "Sweets", x, y, z)
	elseif result["VIP"] == 2 or result["Pumpkin"] == 2 or result["Vehicle"] == 2 or result["Money"] == 2 or result["Pumpkins"] == 2 or result["Sweets"] == 2 then
		self:giveWin(player, "Trostpreis", x, y, z)
	else
		player:sendInfo(_("Du hast leider nichts gewonnen!", player))
		triggerClientEvent(root, "onSlotmachineSoundPlay", root, x, y, z, "win_nothing")
	end

	setTimer(self.m_ResetFunc, 1500, 1)
end

function HalloweenSlotmachine:startPlayer(player)
	if not self.canSpin then return end

	local amount = 2
	if player:getInventory():removeItem("Kürbis", amount) then
		self:start(player)
	else
		player:sendWarning(_("Du brauchst %s Kürbisse, um spielen zu können", player, amount))
	end
end