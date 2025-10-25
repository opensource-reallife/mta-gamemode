DrivingSchool = inherit(Company)
DrivingSchool.LicenseCosts = {["car"] = 2500, ["bike"] = 1500, ["truck"] = 6000, ["heli"] = 25000, ["plane"] = 25000 }
DrivingSchool.TypeNames = {["car"] = "Autoführerschein", ["bike"] = "Motorradschein", ["truck"] = "LKW-Schein", ["heli"] = "Helikopterschein", ["plane"] = "Flugschein"}
DrivingSchool.m_LessonVehicles = {}
DrivingSchool.testRoute = {
	["car"] = {
		{1807.22, -1712.35, 13.03},
		{1821.64, -1738.12, 13.04},
		{1820.06, -1814.89, 13.06},
		{1924.91, -1934.03, 13.04},
		{1959.62, -1972.99, 13.05},
		{1958.93, -2021.41, 13.04},
		{1935.31, -2050.51, 13.04},
		{1849.92, -2050.31, 13.04},
		{1820.35, -2087.81, 13.04},
		{1819.87, -2130.43, 13.04},
		{1788.46, -2164.38, 13.04},
		{1580.27, -2123.66, 31.29},
		{1531.90, -1932.20, 16.57},
		{1504.32, -1869.66, 13.04},
		{1353.35, -1860.91, 13.04},
		{1309.18, -1748.84, 13.04},
		{1276.06, -1709.55, 13.04},
		{1072.05, -1709.69, 13.03},
		{1039.25, -1667.26, 13.03},
		{1039.62, -1609.36, 13.04},
		{894.90, -1569.32, 13.04},
		{859.62, -1588.50, 13.04},
		{823.44, -1596.38, 13.38},
		{774.98, -1562.62, 13.38},
		{799.38, -1425.27, 13.05},
		{799.23, -1359.54, 13.04},
		{840.71, -1328.91, 13.12},
		{1029.08, -1329.18, 13.03},
		{1086.83, -1283.50, 13.08},
		{1196.48, -1322.74, 13.05},
		{1250.64, -1407.97, 12.66},
		{1376.86, -1407.86, 13.04},
		{1398.66, -1438.87, 13.38},
		{1489.56, -1443.60, 13.03},
		{1628.55, -1443.43, 13.04},
		{1655.08, -1479.97, 13.04},
		{1686.98, -1594.06, 13.04},
		{1795.63, -1614.03, 13.02},
		{1818.31, -1642.01, 13.03},
		{1765.62, -1694.52, 13.02}
	},
	["bike"] = {
		{1807.22, -1712.35, 13.03},
		{1821.64, -1738.12, 13.04},
		{1820.06, -1814.89, 13.06},
		{1924.91, -1934.03, 13.04},
		{1959.62, -1972.99, 13.05},
		{1958.93, -2021.41, 13.04},
		{1935.31, -2050.51, 13.04},
		{1849.92, -2050.31, 13.04},
		{1820.35, -2087.81, 13.04},
		{1819.87, -2130.43, 13.04},
		{1788.46, -2164.38, 13.04},
		{1580.27, -2123.66, 31.29},
		{1531.90, -1932.20, 16.57},
		{1504.32, -1869.66, 13.04},
		{1353.35, -1860.91, 13.04},
		{1309.18, -1748.84, 13.04},
		{1276.06, -1709.55, 13.04},
		{1072.05, -1709.69, 13.03},
		{1039.25, -1667.26, 13.03},
		{1039.62, -1609.36, 13.04},
		{894.90, -1569.32, 13.04},
		{859.62, -1588.50, 13.04},
		{823.44, -1596.38, 13.38},
		{774.98, -1562.62, 13.38},
		{799.38, -1425.27, 13.05},
		{799.23, -1359.54, 13.04},
		{840.71, -1328.91, 13.12},
		{1029.08, -1329.18, 13.03},
		{1086.83, -1283.50, 13.08},
		{1196.48, -1322.74, 13.05},
		{1250.64, -1407.97, 12.66},
		{1376.86, -1407.86, 13.04},
		{1398.66, -1438.87, 13.38},
		{1489.56, -1443.60, 13.03},
		{1628.55, -1443.43, 13.04},
		{1655.08, -1479.97, 13.04},
		{1686.98, -1594.06, 13.04},
		{1795.63, -1614.03, 13.02},
		{1818.31, -1642.01, 13.03},
		{1765.62, -1694.52, 13.02}
	},
	["truck"] = {
		{1807.22, -1712.35, 13.03},
		{1819.28, -1769.49, 14.01},
		{1819.37, -1908.91, 14.02},
		{1928.49, -1934.70, 14.01},
		{1959.29, -1970.24, 14.09},
		{1959.13, -2075.06, 14.01},
		{1978.31, -2112.47, 13.99},
		{2075.69, -2112.54, 13.96},
		{2208.66, -2178.83, 13.99},
		{2281.83, -2252.24, 14.08},
		{2288.38, -2307.85, 14.00},
		{2309.31, -2348.70, 14.02},
		{2222.17, -2512.56, 14.02},
		{2344.61, -2665.94, 14.13},
		{2493.96, -2510.77, 14.14},
		{2636.83, -2506.22, 14.12},
		{2686.39, -2477.08, 14.14},
		{2668.72, -2402.53, 14.08},
		{2534.55, -2327.88, 23.21},
		{2272.68, -2066.37, 14.00},
		{2221.00, -1878.74, 14.01},
		{2209.05, -1730.41, 14.04},
		{2170.38, -1749.74, 14.01},
		{1856.10, -1749.78, 14.01},
		{1824.09, -1733.15, 14.01},
		{1765.62, -1694.52, 13.02}
	},
	["heli"] = {
		{1878.98, -1855.18, 34.07},
		{1983.00, -2082.12, 38.73},
		{2071.87, -2426.97, 39.61},
		{1885.80, -2574.13, 40.17},
		{1488.88, -2592.73, 39.87},
		{1230.44, -2595.19, 42.02},
		{896.39, -2484.75, 44.84},
		{821.97, -2225.34, 40.67},
		{729.54, -1985.05, 46.59},
		{726.06, -1677.58, 46.89},
		{731.89, -1475.77, 53.71},
		{973.64, -1243.17, 60.87},
		{1204.29, -1093.63, 74.93},
		{1438.98, -992.42, 75.20},
		{1649.84, -1053.55, 83.46},
		{1835.20, -1085.76, 72.28},
		{2275.98, -1147.61, 53.98},
		{2512.87, -1467.77, 58.78},
		{2643.35, -1729.19, 41.26},
		{2388.31, -1852.49, 39.75},
		{2063.06, -1851.97, 44.14},
		{1793.62, -1716.05, 19.62}
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
		client:sendError(_("Du hast die Theorieprüfung bereits bestanden!", client))
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
		client:sendError(_("Du hast abgebrochen oder nicht bestanden! Versuche die Prüfung erneut!", client))
	end
end

function DrivingSchool:Event_startAutomaticTest(type)
	if not client.m_HasTheory then
		client:sendError(_("Du hast die Theorieprüfung noch nicht bestanden!", client))
		return
	end

	if #self:getOnlinePlayers() >= 3 then
		client:sendError(_("Es sind genügend Fahrlehrer online!", client))
		return
	end

	local valid = {["car"]= true, ["bike"] = true, ["truck"] = true, ["heli"] = true}
	if not valid[type] then return end

	if type == "car" and client.m_HasDrivingLicense then
		client:sendError(_("Du hast bereits den Autoführerschein!", client))
		return
	end

	if type == "bike" and client.m_HasBikeLicense then
		client:sendError(_("Du hast bereits den Motorradführerschein!", client))
		return
	end

	if type == "truck" and client.m_HasTruckLicense then
		client:sendError(_("Du hast bereits den LKW-Führerschein!", client))
		return
	end

	if type == "heli" and client.m_HasPilotsLicense then
		client:sendError(_("Du hast bereits den Pilotenschein!", client))
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
		player:setPublicSync("inDrivingLession", false)
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
		veh = TemporaryVehicle.create(487, 1780.11, -1715.12, 19.81, 180)
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
	player:setPublicSync("inDrivingLession", true)

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
		outputChatBox(_("%s sagt: Mit #C8C800'X'#C8C8C8 schaltest du den Motor an.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 2000, 1, _("%s sagt: Anschließend mit #C8C800'L'#C8C8C8 die Lichter.", player, name), player, 200, 200, 200, true)
		if player.m_AutoTestMode == "bike" then
			setTimer(outputChatBox, 4000, 1, _("%s sagt: Nun ziehe deinen Helm an.", player, name), player, 200, 200, 200)
		else
			setTimer(outputChatBox, 4000, 1, _("%s sagt: Nun Anschnallen mit #C8C800'M'#C8C8C8.", player, name), player, 200, 200, 200, true)
		end
		setTimer(outputChatBox, 6000, 1, _("%s sagt: Mit den Tasten #C8C800'W'#C8C8C8, #C8C800'A'#C8C8C8, #C8C800'S'#C8C8C8 und #C8C800'D'#C8C8C8 bewegst du das Fahrzeug.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 8000, 1, _("%s sagt: Die Schranke öffnest du mit #C8C800'H'#C8C8C8. Bitte schließe diese nachher wieder.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 10000, 1, _("%s sagt: Und abgeht es! Vergiss nicht den Limiter mit der Taste #C8C800'K'#C8C8C8 auf #C8C80080 km/h#C8C8C8 einzustellen.", player, name), player, 200, 200, 200, true)

		setTimer(function()
			if not isElement(veh) then
				sourceTimer:destroy()
				return
			end
			if veh:getSpeed() >= 85 then
				veh.m_SpeedingPoints = veh.m_SpeedingPoints + 1
				outputChatBox(_("%s sagt: Du fährst zu schnell! Das gibt einen Fehlerpunkt!", player, name), player, 200, 200, 200)
				if veh.m_SpeedingPoints < 5 then
					if veh.m_SpeedingPoints == 1 then
						setTimer(outputChatBox, 2000, 1, _("%s sagt: Vergiss nicht den Limiter mit der Taste #C8C800'K'#C8C8C8 auf #C8C80080 km/h#C8C8C8 einzustellen!", player, name, veh.m_SpeedingPoints), player, 200, 200, 200, true)
						setTimer(outputChatBox, 4000, 1, _("%s sagt: Solltest du #C8C8005#C8C8C8 Fehlerpunkte bekommen, fällst du durch!", player, name), player, 200, 200, 200, true)
					else
						setTimer(outputChatBox, 2000, 1, _("%s sagt: Damit hast du jetzt schon #C8C800%s#C8C8C8 Fehlerpunkte!", player, name, veh.m_SpeedingPoints), player, 200, 200, 200, true)
					end
				else
					setTimer(outputChatBox, 2000, 1, _("%s sagt: Das wars! Durchgefallen!", player, name), player, 200, 200, 200)
					setTimer(destroyElement, 2000, 1, veh)
				end
			end
		end, 4000, 0, veh, name)
	else
		player:sendInfo(_("Fliege die vorgesehene Strecke ohne deinen Helikopter zu beschädigen!", player))
		outputChatBox(_("%s sagt: Mit #C8C800'X'#C8C8C8 schaltest du den Motor an.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 2000, 1, _("%s sagt: Mit #C8C800'W'#C8C8C8 lässt du den Helikopter steigen, mit #C8C800'S'#C8C8C8 lässt du ihn sinken.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 4000, 1, _("%s sagt: ... und mit den #C8C800Pfeiltasten#C8C8C8 neigst du den Helikopter, damit er sich bewegt.", player, name), player, 200, 200, 200, true)
		setTimer(outputChatBox, 6000, 1, _("%s sagt: Los geht's!", player, name), player, 200, 200, 200)
	end

	addEventHandler("onVehicleExit", veh,
		function(player, seat)
			if seat ~= 0 then return end
			if not source.m_IsFinished then
				player:sendError(_("Du hast das Fahrzeug verlassen und die Prüfung abgebrochen!", player))
			end
			if DrivingSchool.m_LessonVehicles[player] == source then
				DrivingSchool.m_LessonVehicles[player] = nil
				if source.m_NPC then
					destroyElement(source.m_NPC)
				end
				destroyElement(source)
			end
			player:setPublicSync("inDrivingLession", false)
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
			player:setPublicSync("inDrivingLession", false)
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
						player:sendError(_("Du hast die Prüfung nicht bestanden!", player))
					end
					if source.m_NPC then
						if isElement(source.m_NPC) then
							destroyElement(source.m_NPC)
						end
					end
				end
				player:setPublicSync("inDrivingLession", false)
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
end

function DrivingSchool:onHitRouteMarker()
	if DrivingSchool.m_LessonVehicles[client] then
		local veh = DrivingSchool.m_LessonVehicles[client]
		veh.m_CurrentNode = veh.m_CurrentNode + 1
		if veh.m_CurrentNode <= #DrivingSchool.testRoute[veh.m_TestMode] then
			client:triggerEvent("DrivingLesson:setMarker",DrivingSchool.testRoute[veh.m_TestMode][veh.m_CurrentNode], veh)
		else
			veh.m_IsFinished = true
			if getElementHealth(veh) >= 600 then
				if veh.m_TestMode == "car" then
					client.m_HasDrivingLicense = true
				elseif veh.m_TestMode == "bike" then
					client.m_HasBikeLicense = true
				elseif veh.m_TestMode == "truck" then
					client.m_HasTruckLicense = true
				else
					client.m_HasPilotsLicense = true
				end
				client:sendSuccess(_("Du hast die Prüfung bestanden und dein Fahrzeug ist in einem ausreichenden Zustand!", client))
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:setPublicSync("inDrivingLession", false)
				client:triggerEvent("DrivingLesson:endLesson")
			else
				client:sendError(_("Da dein Fahrzeug zu beschädigt war, hast du nicht bestanden!", client))
				if veh.m_NPC then
					destroyElement(veh.m_NPC)
				end
				destroyElement(veh)
				DrivingSchool.m_LessonVehicles[client] = nil
				client:setPublicSync("inDrivingLession", false)
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

