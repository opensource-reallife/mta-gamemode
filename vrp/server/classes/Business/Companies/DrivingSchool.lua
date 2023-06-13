DrivingSchool = inherit(Company)
DrivingSchool.LicenseCosts = {["car"] = 4500, ["bike"] = 2000, ["truck"] = 10000, ["heli"] = 50000, ["plane"] = 50000 }
DrivingSchool.TypeNames = {["car"] = "Autoführerschein", ["bike"] = "Motorradschein", ["truck"] = "LKW-Schein", ["heli"] = "Helikopterschein", ["plane"] = "Flugschein"}
DrivingSchool.m_LessonVehicles = {}
DrivingSchool.testRoute = {
	["car"] = {
		{1806.29, -1687.84, 13.25},
		{1819.07, -1731.14, 13.27},
		{1819.21, -1818.76, 13.29},
		{1704.19, -1809.78, 13.25},
		{1674.89, -1864.63, 13.27},
		{1499.44, -1869.84, 13.27},
		{1328.22, -1850.77, 13.27},
		{1315.00, -1733.50, 13.27},
		{1260.38, -1709.84, 13.27},
		{1053.04, -1709.66, 13.27},
		{1039.95, -1587.41, 13.27},
		{900.87, -1569.73, 13.27},
		{808.03, -1659.74, 13.27},
		{655.32, -1669.98, 14.18},
		{635.81, -1607.80, 15.49},
		{468.02, -1583.13, 25.02},
		{445.27, -1479.28, 30.46},
		{402.85, -1420.90, 33.54},
		{522.77, -1341.80, 15.50},
		{653.06, -1322.03, 13.22},
		{901.69, -1328.63, 13.36},
		{944.82, -1235.68, 16.40},
		{1039.35, -1223.26, 16.61},
		{1060.50, -1163.54, 23.61},
		{1142.91, -1150.95, 23.54},
		{1372.66, -1143.99, 23.54},
		{1599.35, -1163.39, 23.79},
		{1831.95, -1183.70, 23.52},
		{1845.42, -1278.20, 13.27},
		{1842.56, -1509.14, 13.25},
		{1762.27, -1694.62, 14.00}
	},
	["bike"] = {
		{1807.23, -1711.17, 13.37},
		{1819.17, -1753.05, 12.90},
		{1820.86, -1933.01, 12.90},
		{2082.02, -1933.41, 12.84},
		{2094.92, -1752.94, 12.92},
		{2115.08, -1569.45, 25.23},
		{2115.61, -1386.82, 23.35},
		{2303.24, -1386.58, 23.38},
		{2305.24, -1151.58, 26.30},
		{2138.03, -1088.30, 23.86},
		{1943.69, -1023.41, 32.67},
		{1707.73, -981.72, 37.08},
		{1383.66, -938.60, 33.71},
		{1352.24, -1033.03, 25.71},
		{1525.52, -1043.50, 23.15},
		{1575.50, -1159.39, 23.44},
		{1843.98, -1183.23, 23.16},
		{1845.64, -1458.91, 12.92},
		{1819.40, -1593.57, 12.88},
		{1819.12, -1686.76, 13.38},
		{1762.27, -1694.62, 14.00}
	},
	["truck"] = {
		{1806.83, -1687.40, 12.94},
		{1824.41, -1671.12, 12.95},
		{1853.14, -1483.02, 14.00},
		{2095.44, -1467.71, 24.43},
		{2110.20, -1604.71, 24.21},
		{2078.99, -1879.49, 13.97},
		{2233.51, -1896.98, 12.94},
		{2311.30, -1956.08, 14.00},
		{2229.53, -1969.76, 13.99},
		{2221.46, -2021.59, 12.91},
		{2270.17, -2070.71, 14.00},
		{2200.33, -2159.44, 12.96},
		{2101.04, -2262.88, 12.94},
		{2172.21, -2359.40, 14.00},
		{2162.36, -2476.91, 14.00},
		{2209.62, -2497.97, 14.03},
		{2313.82, -2352.12, 14.01},
		{2287.82, -2300.19, 12.94},
		{2284.68, -2248.37, 12.88},
		{2185.87, -2148.65, 12.94},
		{1977.92, -2107.49, 13.99},
		{1964.26, -1916.84, 14.01},
		{1964.47, -1768.24, 14.00},
		{1837.82, -1749.58, 14.01},
		{1807.52, -1711.69, 12.93},
		{1762.27, -1694.62, 14.00}
	},
	["heli"] = {
		{1651.56, -1729.75, 43.38},
		{1327.79, -1730.02, 43.04},
		{1310.11, -1575.86, 43.04},
		{1349.55, -1399.87, 42.97},
		{1106.99, -1392.60, 43.12},
		{804.73, -1393.98, 43.14},
		{650.62, -1397.89, 43.04},
		{625.97, -1534.58, 44.72},
		{651.80, -1674.67, 44.15},
		{796.70, -1676.98, 43.01},
		{819.15, -1641.51, 43.04},
		{1019.96, -1574.58, 43.04},
		{1048.16, -1516.02, 43.04},
		{1065.41, -1419.91, 43.08},
		{1060.16, -1276.25, 43.40},
		{1060.41, -1161.71, 43.36},
		{1323.85, -1148.96, 43.3},
		{1444.42, -1163.26, 43.31},
		{1451.98, -1285.99, 43.04},
		{1700.87, -1305.06, 43.10},
		{1712.74, -1427.98, 43.04},
		{1468.86, -1438.64, 43.04},
		{1427.40, -1577.95, 43.02},
		{1515.72, -1595.33, 43.03},
		{1527.44, -1718.88, 43.04},
		{1592.89, -1734.80, 43.38},
		{1793.60, -1715.12, 29.79}
	}
}

addRemoteEvents{"drivingSchoolCallInstructor", "drivingSchoolStartTheory", "drivingSchoolPassTheory", "drivingSchoolStartAutomaticTest", "drivingSchoolHitRouteMarker",	"drivingSchoolStartLessionQuestion", "drivingSchoolEndLession", "drivingSchoolReceiveTurnCommand", "drivingSchoolReduceSTVO", "drivingSchoolBuyLicense"}

function DrivingSchool:constructor()
	InteriorEnterExit:new(Vector3(1778.92, -1721.45, 13.37), Vector3(-2026.93, -103.89, 1035.17), 90, 180, 3, 0, false)
	InteriorEnterExit:new(Vector3(1778.78, -1709.76, 13.37), Vector3(-2029.75, -119.3, 1035.17), 0, 0, 3, 0, false)

	local leftDoor = createObject(3051, -2028.4250, -113.2535, 1035.1999, 0, 0, 284.6610)
	leftDoor:setScale(0.25, 1, 0.75)
	leftDoor:setInterior(3)
	leftDoor:setCollisionsEnabled(false)
	local rightDoor = createObject(3051, -2027.5666, -113.2525, 1035.1999, 0, 0, 284.6610)
	rightDoor:setScale(0.25, 1, 0.75)
	rightDoor:setInterior(3)
	rightDoor:setCollisionsEnabled(false)
	local elevator = Elevator:new()
	elevator:addStation("Dach - Heliports", Vector3(1765.87, -1718.25, 19.88), 180, 0, 0)
	elevator:addStation("Innenraum", Vector3(-2028.02, -113.8, 1035.17), 176, 3, 0)

	Gate:new(968, Vector3(1810.675, -1716, 13.19), Vector3(0, 90, 180), Vector3(1810.675, -1716, 13.19), Vector3(0, 0, 180), false).onGateHit = bind(self.onBarrierHit, self)
	Gate:new(968, Vector3(1811.2, -1691.275, 13.19), Vector3(0, 90, 90), Vector3(1811.2, -1691.275, 13.19), Vector3(0, 0, 90), false).onGateHit = bind(self.onBarrierHit, self)

    self.m_OnQuit = bind(self.Event_onQuit,self)
	self.m_StartLession = bind(self.startLession, self)
	self.m_DiscardLession = bind(self.discardLession, self)
	self.m_BankAccountServer = BankServer.get("company.driving_school")

    local safe = createObject(2332, -2032.70, -113.70, 1036.20)
    safe:setInterior(3)
	self:setSafe(safe)

	local id = self:getId()
	local blip = Blip:new("DrivingSchool.png", 1778.92, -1721.45, root, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

	self.m_CurrentLessions = {}

	addEventHandler("drivingSchoolCallInstructor", root, bind(DrivingSchool.Event_callInstructor, self))
	addEventHandler("drivingSchoolStartTheory", root, bind(DrivingSchool.Event_startTheory, self))
	addEventHandler("drivingSchoolPassTheory", root, bind(DrivingSchool.Event_passTheory, self))

	addEventHandler("drivingSchoolStartAutomaticTest", root, bind(DrivingSchool.Event_startAutomaticTest, self))
	addEventHandler("drivingSchoolHitRouteMarker", root, bind(DrivingSchool.onHitRouteMarker, self))
	addEventHandler("drivingSchoolStartLessionQuestion", root, bind(DrivingSchool.Event_startLessionQuestion, self))

    addEventHandler("drivingSchoolEndLession", root, bind(DrivingSchool.Event_endLession, self))
    addEventHandler("drivingSchoolReceiveTurnCommand", root, bind(DrivingSchool.Event_receiveTurnCommand, self))
	addEventHandler("drivingSchoolReduceSTVO", root, bind(DrivingSchool.Event_reduceSTVO, self))

	addEventHandler("drivingSchoolBuyLicense", root, bind(DrivingSchool.buyPlayerLicense, self))
end

function DrivingSchool:destructor()
end

function DrivingSchool:onVehicleEnter(vehicle, player, seat)
	if seat == 0 then return end
	if not self.m_CurrentLessions[player] then return end

	if self.m_CurrentLessions[player].vehicle ~= vehicle then
		self.m_CurrentLessions[player].vehicle = vehicle
		self.m_CurrentLessions[player].startMileage = vehicle:getMileage()
		player:setPrivateSync("instructorData", {vehicle = vehicle, startMileage = vehicle:getMileage()})
	end
end

function DrivingSchool:onBarrierHit(player)
	if player.vehicle and player.vehicle.m_IsAutoLesson then
		return true
	end

	if player:getCompany() ~= self then
		return false
	end

	return true
end

function DrivingSchool:Event_callInstructor()
	client:sendInfo(_("Die Fahrschule wurde kontaktiert. Ein Fahrlehrer wird sich bald bei dir melden!",client))
	self:sendShortMessage(_("Der Spieler %s sucht einen Fahrlehrer! Bitte melden!", client, client.name))
end

function DrivingSchool:Event_startTheory(ped)
	if client.m_HasTheory then
		client:sendWarning(_("Du hast die Theorieprüfung bereits bestanden!", client))
		return
	end

	QuestionBox:new(client, _("Möchtest du die Theorie-Prüfung starten? Kosten: 300$", client),
		function(player)
			if not player:transferMoney(self.m_BankAccountServer, 300, "Fahrschule Theorie", "Company", "License") then
				player:sendError(_("Du hast nicht genug Geld dabei!", player))
				return
			end

			player:triggerEvent("showDrivingSchoolTest", ped)
		end,
		function() end,
		false, false,
		client
	)
end

function DrivingSchool:Event_passTheory(pass)
	if pass then
		client.m_HasTheory = true
		client:sendInfo(_("Du kannst nun die praktische Prüfung machen!", client))
	else
		client:sendInfo(_("Du hast abgebrochen oder nicht bestanden! Versuche die Prüfung erneut!", client))
	end
end

function DrivingSchool:Event_startAutomaticTest(type)
	if not client.m_HasTheory then
		client:sendWarning(_("Du hast die Theorieprüfung noch nicht bestanden!", client))
		return
	end

	if #self:getOnlinePlayers() >= 3 then
		client:sendWarning(_("Es sind genügend Fahrlehrer online!", client))
		return
	end

	local valid = {["car"]= true, ["bike"] = true, ["truck"] = true, ["heli"] = true}
	if not valid[type] then return end

	if type == "car" and client.m_HasDrivingLicense then
		client:sendWarning(_("Du hast bereits den Autoführerschein", client))
		return
	end

	if type == "bike" and client.m_HasBikeLicense then
		client:sendWarning(_("Du hast bereits den Motorradführerschein", client))
		return
	end

	if type == "truck" and client.m_HasTruckLicense then
		client:sendWarning(_("Du hast bereits den LKW-Führerschein", client))
		return
	end

	if type == "heli" and client.m_HasPilotsLicense then
		client:sendWarning(_("Du hast bereits den Pilotenschein", client))
		return
	end

	QuestionBox:new(client, _("Möchtest du die automatische Fahrprüfung starten? Kosten: %s$", client, DrivingSchool.LicenseCosts[type]),
		function(player, type)
			if player:getMoney() <  DrivingSchool.LicenseCosts[type] then
				player:sendError(_("Du hast nicht genug Geld dabei!", player))
				return
			end
			player:transferMoney(self.m_BankAccountServer, DrivingSchool.LicenseCosts[type], ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")

			player.m_AutoTestMode = type
			self:startAutomaticTest(player, type)
		end,
		function() end,
		false, false,
		client, type
	)
end

function DrivingSchool:checkPlayerLicense(player, type)
	if type == "car" then
		return player.m_HasDrivingLicense
	elseif type == "bike" then
		return player.m_HasBikeLicense
	elseif type == "truck" then
		return player.m_HasTruckLicense
	elseif type == "heli" then
		return player.m_HasPilotsLicense
	elseif type == "plane" then
		return player.m_HasPilotsLicense
	end
end

function DrivingSchool:setPlayerLicense(player, type, bool)
	if type == "car" then
		player.m_HasDrivingLicense = bool
	elseif type == "bike" then
		player.m_HasBikeLicense = bool
	elseif type == "truck" then
		player.m_HasTruckLicense = bool
	elseif type == "heli" then
		player.m_HasPilotsLicense = bool
	elseif type == "plane" then
		player.m_HasPilotsLicense = bool
	end
end

function DrivingSchool:getLessionFromStudent(player)
	for index, key in pairs(self.m_CurrentLessions) do
		if key["target"] == player then return key end
	end
	return false
end

function DrivingSchool:startAutomaticTest(player, type)
	if DrivingSchool.m_LessonVehicles[player] then
		player:triggerEvent("DrivingLesson:endLesson")
		if DrivingSchool.m_LessonVehicles[player].m_NPC then
			if isElement(DrivingSchool.m_LessonVehicles[player].m_NPC ) then
				destroyElement(DrivingSchool.m_LessonVehicles[player].m_NPC)
			end
		end
		destroyElement(DrivingSchool.m_LessonVehicles[player])
	end

	local veh = nil
	if type == "heli" then
		veh = TemporaryVehicle.create(487, 1793.60, -1715.12, 19.79, 180)
	else
		veh = TemporaryVehicle.create((type == "car" and 410) or (type == "bike" and 586) or 578, 1762.27, -1694.62, 14.00, 270)
	end

	veh:setColor(1, 1, 1, 1)
	veh.m_Driver = player
	veh.m_CurrentNode = 1
	veh.m_IsAutoLesson = true
	veh.m_TestMode = type
	veh.m_SpeedingPoints = 0

	player:setInterior(0)
	player:warpIntoVehicle(veh)
	player:setCameraTarget(player)

	local randomName =	{"Nero Soliven", "Kempes Waldemar", "Avram Vachnadze", "Klaus Schweiger", "Luca Pasqualini", "Peter Schmidt", "Mohammed Vegas", "Isaha Rosenberg"}
	local name = randomName[math.random(1, #randomName)]

	veh.m_NPC = createPed(295, 1765.50, -1687.10, 15.37)
	veh.m_NPC:setData("NPC:Immortal", true, true)
	veh.m_NPC:setData("isBuckeled", true, true)
	veh.m_NPC:setData("Ped:fakeNameTag", name, true)
	veh.m_NPC:setData("isDrivingCoach", true)
	veh.m_NPC:warpIntoVehicle(veh, 1)

	if player.m_AutoTestMode ~= "heli" then
		player:sendInfo(_("Fahre die vorgesehene Strecke ohne dein Fahrzeug zu beschädigen!", player))
		outputChatBox(_("%s sagt: Mit 'X' schaltest du den Motor an.", player, name), player, 200, 200, 200)
		setTimer(outputChatBox, 2000, 1, _("%s sagt: Anschließend mit 'L' die Lichter.", player, name), player, 200, 200, 200)
		if player.m_AutoTestMode == "bike" then
			setTimer(outputChatBox, 4000, 1, _("%s sagt: Ziehe deinen Helm an.", player, name), player, 200, 200, 200)
		else
			setTimer(outputChatBox, 4000, 1, _("%s sagt: Nun Anschnallen mit 'M'.", player, name), player, 200, 200, 200)
		end
		setTimer(outputChatBox, 6000, 1, _("%s sagt: Mit den Tasten 'W', 'A', 'S' und 'D' bewegst du das Fahrzeug.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 8000, 1, _("%s sagt: Die Schranke öffnest du mit #C8C800'H'#C8C8C8. Bitte schließe diese nachher wieder.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 10000, 1, _("%s sagt: Und abgeht es! Vergiss nicht den Limiter mit der Taste 'K' anzuschalten.", player, name), player, 200, 200, 200)
	else
		player:sendInfo(_("Fliege die vorgesehene Strecke ohne deinen Helikopter zu beschädigen!", player))
		setTimer(outputChatBox, 2000, 1, _("%s sagt: Mit 'X' schaltest du den Motor an.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 4000, 1, _("%s sagt: Mit 'W' lässt du den Helikopter steigen, mit 'S' lässt du ihn sinken.", player, name), player, 200, 200, 200)
		setTimer(outputChatBox, 6000, 1, _("%s sagt: ... und mit den Pfeiltasten neigst du den Helikopter, damit er sich bewegt.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 8000, 1, _("%s sagt: Los geht's!", player, name), player, 200, 200, 200, true)
	end

	addEventHandler("onVehicleExit", veh,
		function(player, seat)
			if seat ~= 0 then return end
			if not source.m_IsFinished then
				player:sendError(_("Du hast das Fahrzeug verlassen und die Prüfung beendet!", player))
			end
			if DrivingSchool.m_LessonVehicles[player] == source then
				DrivingSchool.m_LessonVehicles[player] = nil
				if source.m_NPC then
					destroyElement(source.m_NPC)
				end
				destroyElement(source)
			end
			player:triggerEvent("DrivingLesson:endLesson")
			fadeCamera(player, false, 0.5)
			setTimer(setElementPosition, 1000, 1, player, 1778.88, -1706.73, 13.37)
			setTimer(setElementRotation, 1000, 1, player, 0, 0, 0)
			setTimer(fadeCamera, 1500, 1, player, true, 0.5)
		end
	)

	addEventHandler("onVehicleExplode",veh,
		function()
			local player = getVehicleOccupant(source)
			if DrivingSchool.m_LessonVehicles[player] == source then
			local alreadyFinished = source.m_IsFinished
				DrivingSchool.m_LessonVehicles[player] = nil
				if source.m_NPC then
					destroyElement(source.m_NPC)
				end
				destroyElement(source)
			end
			player:triggerEvent("DrivingLesson:endLesson")
			fadeCamera(player, false, 0.5)
			setTimer(setElementPosition, 1000, 1, player, 1778.88, -1706.73, 13.37)
			setTimer(setElementRotation, 1000, 1, player, 0, 0, 0)
			setTimer(fadeCamera, 1500, 1, player, true, 0.5)
			if not alreadyFinished then
				player:sendError(_("Du hast das Fahrzeug zerstört!", player))
			end
		end
	)

	addEventHandler("onElementDestroy", veh,
		function()
			local player = getVehicleOccupant(source)
			if player then
				if DrivingSchool.m_LessonVehicles[player] == source then
					DrivingSchool.m_LessonVehicles[player] = nil
					if not source.m_IsFinished then
						player:sendError(_("Du hast das Fahrzeug verlassen und die Prüfung beendet!", player))
					end
					if source.m_NPC then
						if isElement(source.m_NPC) then
							destroyElement(source.m_NPC)
						end
					end
				end
				player:triggerEvent("DrivingLesson:endLesson")
				fadeCamera(player, false, 0.5)
				setTimer(setElementPosition, 1000, 1, player, 1778.88, -1706.73, 13.37)
				setTimer(setElementRotation, 1000, 1, player, 0, 0, 0)
				setTimer(fadeCamera, 1500, 1, player, true, 0.5)
			end
		end, false
	)

	player:triggerEvent("DrivingLesson:setMarker", DrivingSchool.testRoute[veh.m_TestMode][veh.m_CurrentNode], veh)
	DrivingSchool.m_LessonVehicles[player] = veh

	setTimer(function(veh)
		if not isElement(veh) then
			sourceTimer:destroy()
			return
		end
		if veh:getSpeed() >= 85 then
			veh.m_Driver:sendWarning(_("Du fährst zu schnell! Du fällst durch die Prüfung, wenn du zu oft zu schnell fährst!", veh.m_Driver))
			veh.m_SpeedingPoints = veh.m_SpeedingPoints + 1
		end
	end, 5000, 0, veh)
end

function DrivingSchool:onHitRouteMarker()
	if DrivingSchool.m_LessonVehicles[client] then
		local veh = DrivingSchool.m_LessonVehicles[client]
		veh.m_CurrentNode = veh.m_CurrentNode + 1
		if veh.m_CurrentNode <= #DrivingSchool.testRoute[veh.m_TestMode] then
			client:triggerEvent("DrivingLesson:setMarker",DrivingSchool.testRoute[veh.m_TestMode][veh.m_CurrentNode], veh)
		else
			veh.m_IsFinished = true
			if getElementHealth(veh) >= 600 and veh.m_SpeedingPoints <= 5 then
				if veh.m_TestMode == "car" then
					client.m_HasDrivingLicense = true
				elseif veh.m_TestMode == "bike" then
					client.m_HasBikeLicense = true
				elseif veh.m_TestMode == "truck" then
					client.m_HasTruckLicense = true
				else
					client.m_HasPilotsLicense = true
				end
				client:sendInfo(_("Du hast die Prüfung bestanden und dein Fahrzeug ist in einem ausreichenden Zustand!", client))
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:triggerEvent("DrivingLesson:endLesson")
			else
				if veh.m_SpeedingPoints > 5 then
					client:sendError(_("Da du zu oft zu schnell warst, hast du nicht bestanden!", client))
				else
					client:sendError(_("Da dein Fahrzeug zu beschädigt war, hast du nicht bestanden!", client))
				end
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:triggerEvent("DrivingLesson:endLesson")
			end
		end
	end
end

function DrivingSchool:Event_startLessionQuestion(target, type)
    local costs = DrivingSchool.LicenseCosts[type]
    if costs and target then
        if not self:checkPlayerLicense(target, type) then
			if target.m_HasTheory then
				if target:getMoney() >= costs then
					if not target:getPublicSync("inDrivingLession") then
						if not self.m_CurrentLessions[client] then
							QuestionBox:new(target, _("Der Fahrlehrer %s möchte mit dir die %s Prüfung starten!\nDiese kostet %d$! Möchtest du die Prüfung starten?", target, client.name, DrivingSchool.TypeNames[type], costs), self.m_StartLession, self.m_DiscardLession, client, 10, client, target, type)
						else
							client:sendError(_("Du bist bereits in einer Fahrprüfung!", client))
						end
					else
						client:sendError(_("Der Spieler %s ist bereits in einer Prüfung!", client, target.name))
					end
				else
					client:sendError(_("Der Spieler %s hat nicht genug Geld dabei! (%d$)", client, target.name, costs))
				end
			else
                client:sendError(_("Der Spieler %s muss erst die theoretische Fahrprüfung bestehen!", client, target.name))
			end
		else
			client:sendError(_("Der Spieler %s hat den %s bereits!", client, target.name, DrivingSchool.TypeNames[type]))
		end
    else
        client:sendError(_("Interner Fehler: Argumente falsch @DrivingSchool:Event_startLessionQuestion!", client))
    end
end

function DrivingSchool:discardLession(instructor, target, type)
    instructor:sendError(_("Der Spieler %s hat die %s Prüfung abgelehnt!", instructor, target.name, DrivingSchool.TypeNames[type]))
    target:sendError(_("Du hast die %s Prüfung mit %s abgelehnt!", target, DrivingSchool.TypeNames[type], instructor.name))
end

function DrivingSchool:startLession(instructor, target, type)
    local costs = DrivingSchool.LicenseCosts[type]
    if costs and target then
        if self:checkPlayerLicense(target, type) == false then
            if target:getMoney() >= costs then
                if not target:getPublicSync("inDrivingLession") == true then
                    if not self.m_CurrentLessions[instructor] then
                        self.m_CurrentLessions[instructor] = {
                            ["target"] = target,
							["type"] = type,
							["instructor"] = instructor,
							["vehicle"] = false,
							["startMileage"] = false,
						}

						target:transferMoney(self.m_BankAccountServer, costs, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")
						self.m_BankAccountServer:transferMoney({self, nil, true}, costs*0.85, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")
						self.m_BankAccountServer:transferMoney(instructor, costs*0.15, ("%s-Prüfung"):format(DrivingSchool.TypeNames[type]), "Company", "License")

                        target:setPublicSync("inDrivingLession",true)
                        instructor:sendInfo(_("Du hast die %s Prüfung mit %s gestartet!", instructor, DrivingSchool.TypeNames[type], target.name))
                        target:sendInfo(_("Fahrlehrer %s hat die %s Prüfung mit dir gestartet, Folge seinen Anweisungen!", target, instructor.name, DrivingSchool.TypeNames[type]))
                        target:triggerEvent("showDrivingSchoolStudentGUI", DrivingSchool.TypeNames[type])
                        instructor:triggerEvent("showDrivingSchoolInstructorGUI", DrivingSchool.TypeNames[type], target)
						self:addLog(instructor, "Fahrschule", ("hat eine %s Prüfung mit %s gestartet!"):format(DrivingSchool.TypeNames[type], target:getName()))
                        addEventHandler("onPlayerQuit", instructor, self.m_OnQuit)
                        addEventHandler("onPlayerQuit", target, self.m_OnQuit)
                    else
                        instructor:sendError(_("Du bist bereits in einer Fahrprüfung!", instructor))
                    end
                else
                    instructor:sendError(_("Der Spieler %s ist bereits in einer Prüfung!", instructor, target.name))
                    target:sendError(_("Du bist bereits in einer Prüfung!", target))
                end
            else
                instructor:sendError(_("Der Spieler %s hat nicht genug Geld dabei! (%d$)", instructor, target.name, costs))
                target:sendError(_("Du hast nicht genug Geld dabei! (%d$)", target, costs))
            end
        else
            instructor:sendError(_("Der Spieler %s hat den %s bereits!", instructor, target.name, DrivingSchool.TypeNames[type]))
            target:sendError(_("Du hast den %s bereits!", target, DrivingSchool.TypeNames[type]))
        end
    else
        instructor:sendError(_("Interner Fehler: Argumente falsch @DrivingSchool:Event_startLession!", instructor))
    end
end

function DrivingSchool:Event_onQuit()
    if self.m_CurrentLessions[source] then
        local lession = self.m_CurrentLessions[source]
		self:Event_endLession(lession["target"], false, source)
        lession["target"]:sendError(_("Der Fahrlehrer %s ist offline gegangen!",lession["target"], source.name))
    elseif self:getLessionFromStudent(source) then
        local lession = self:getLessionFromStudent(source)
        self:Event_endLession(source, false, lession["instructor"])
        lession["instructor"]:sendError(_("Der Fahrschüler %s ist offline gegangen!",lession["instructor"], source.name))
    end
end

function DrivingSchool:Event_endLession(target, success, clientServer)
    if not client and clientServer then client = clientServer end
    local type = self.m_CurrentLessions[client]["type"]
    if success == true then
		local vehicle = self.m_CurrentLessions[client].vehicle
		if not vehicle then return end

		local startMileage = self.m_CurrentLessions[client].startMileage
		local mileageDiff = math.round((vehicle:getMileage()-startMileage)/1000, 1)

		if mileageDiff < 2 then
			client:sendWarning("Du musst mindestens 2km mit dem Fahrschüler fahren!")
			return
		end

        self:setPlayerLicense(target, type, true)
        target:sendInfo(_("Du hast die %s Prüfung erfolgreich bestanden und den Schein erhalten!",target, DrivingSchool.TypeNames[type]))
        client:sendInfo(_("Du hast die %s Prüfung mit %s erfolgreich beendet!",client, DrivingSchool.TypeNames[type], target.name))
    	self:addLog(client, "Fahrschule", ("hat die %s Prüfung mit %s erfolgreich beendet (%s km)!"):format(DrivingSchool.TypeNames[type], target:getName(), mileageDiff))
	else
        target:sendError(_("Du hast die %s Prüfung nicht geschaft! Viel Glück beim nächsten Mal!",target, DrivingSchool.TypeNames[type]))
        client:sendInfo(_("Du hast die %s Prüfung mit %s abgebrochen!",client, DrivingSchool.TypeNames[type], target.name))
		self:addLog(client, "Fahrschule", ("hat die %s Prüfung mit %s abgebrochen!"):format(DrivingSchool.TypeNames[type], target:getName()))
    end

	target:removeFromVehicle()
    target:triggerEvent("hideDrivingSchoolStudentGUI")
    client:triggerEvent("hideDrivingSchoolInstructorGUI")
    removeEventHandler("onPlayerQuit", client, self.m_OnQuit)
    removeEventHandler("onPlayerQuit", target, self.m_OnQuit)
    target:setPublicSync("inDrivingLession", false)
    self.m_CurrentLessions[client] = nil
end

function DrivingSchool:Event_receiveTurnCommand(turnCommand, arg)
    local target = self.m_CurrentLessions[client]["target"]
    if target then
        target:triggerEvent("drivingSchoolChangeDirection", turnCommand, arg)
    end
end

function DrivingSchool:Event_reduceSTVO(category, amount)
	if tonumber(client:getSTVO(category)) < tonumber(amount) then
		client:sendError(_("Du hast nicht so viele STVO-Punkte!", client))
		return false
	end

	local stvoPricing = 250 * amount

	if not client:transferMoney(self.m_BankAccountServer, stvoPricing, "STVO-Punkte abbauen", "Driving School", "ReduceSTVO") then
		client:sendError(_("Du hast nicht genügend Geld! ("..tostring(stvoPricing).."$)", client))
		return false
	end

	client:setSTVO(category, client:getSTVO(category) - amount)
	self.m_BankAccountServer:transferMoney({self, nil, true}, stvoPricing*0.85, "STVO-Punkte abbauen", "Driving School", "ReduceSTVO")
	triggerClientEvent(client, "hideDrivingSchoolReduceSTVO", resourceRoot)
end

function DrivingSchool:buyPlayerLicense(type)
    local costs = DrivingSchool.LicenseCosts[type]*1.25
	if not client then return end
    if costs and client then
        if not self:checkPlayerLicense(client, type) then
			if client:getMoney() >= costs then
				QuestionBox:new(client, _("Möchtest du den %s kaufen? Kosten: %d$ (25 Prozent mehr als bei einem Fahrlehrer)", client, DrivingSchool.TypeNames[type], costs),
					function(player)
						client:sendInfo(_("Du hast den %sschein gekauft.", client, DrivingSchool.TypeNames[type]))
						client:transferMoney(self.m_BankAccountServer, costs, ("%s-Führerschein"):format(DrivingSchool.TypeNames[type]), "Company", "License")
						self:setPlayerLicense(client, type, true)
					end
				)
			else
				client:sendError(_("Du hast nicht genug Geld dabei! (%d$)", client, costs))
			end
		else
			client:sendError(_("Du hast den den %s bereits!", client, DrivingSchool.TypeNames[type]))
		end
    else
        client:sendError(_("Interner Fehler: Argumente falsch @DrivingSchool:buyPlayerLicense!", client, client.name))
    end
end

