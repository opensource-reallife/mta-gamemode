-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/KeyBindManager.lua
-- *  PURPOSE:     KeyBindings Mangager class
-- *
-- ****************************************************************************
KeyBinds = inherit(Singleton)

function KeyBinds:constructor()
	self.m_TogglePhone = bind(self.togglePhone, self)
	self.m_HelpMenu = bind(self.helpMenu, self)
	self.m_AnimationMenu = bind(self.animationMenu, self)
	self.m_PolicePanel = bind(self.policePanel, self)
	self.m_RadioCommunication = bind(self.radioCommunication, self)
	self.m_SelfMenu = bind(self.selfMenu, self)
	self.m_ScoreboardTrigger = bind(self.scoreboardGUI, self)
	self.m_CustomMap = bind(self.customMap, self)
	self.m_Inventory = bind(self.inventory, self)
	self.m_SpeedLimit = bind(HUDSpeedo.Bind_SpeedLimit, HUDSpeedo:getSingleton())
	self.m_CruiseControl = bind(HUDSpeedo.Bind_CruiseControl, HUDSpeedo:getSingleton())
	self.m_VehiclePickUp = bind(LocalPlayer.vehiclePickUp, localPlayer)
	self.m_VehicleELS = bind(self.vehicleELS, self)
	self.m_Entrance = bind(self.tryEnterEntrance, self)
	self.m_PoliceMegaphone = bind(self.usePoliceMegaphone, self)
	self.m_InfraredVehicle = bind(self.toggleInfrared, self)
	self.m_ToggleDisplays = bind(self.toggleDisplay, self)
	self.m_ToggleHeliDriveBy = bind(self.toggleHelicopterDriveBy, self)
	self.m_ToggleObjectPickup = bind(self.toggleObjectPickup, self)
	self.m_BobberBar = bind(self.bobberBar, self)
	self.m_ThrowFishingRod = bind(self.throwFishingRod, self)
	
	self.m_ThermalLightKey = bind(self.thermalLightKey, self)
	self.m_ThermaControlModeKey = bind(self.thermalControlKey, self)
	self.m_ThermalModeKey = bind(self.thermalModeKey, self)
	self.m_ThermalSpeedKey = bind(self.thermalSpeedKey, self)

	self.m_Keys = {
		["general"] = {
			-- Allgemein
			["KeyEntranceUse"]			= {["defaultKey"] = "f", 		["name"] = "Betreten", 						["category"] = "Allgemein", 	["func"] = self.m_Entrance, ["trigger"] = "up"};
			["KeyToggleCursor"]			= {["defaultKey"] = "b", 		["name"] = "Mauszeiger", 					["category"] = "Allgemein", 	["load"] = function () Cursor:loadBind() end, ["unload"] = function () Cursor:unloadBind() end};
			["KeyTogglePhone"]			= {["defaultKey"] = "u", 		["name"] = "Handy", 						["category"] = "Allgemein", 	["func"] = self.m_TogglePhone};
			["KeyToggleSelfGUI"]		= {["defaultKey"] = "F2", 		["name"] = "Self-Menü", 					["category"] = "Allgemein", 	["func"] = self.m_SelfMenu};
			["KeyToggleHelpGUI"]		= {["defaultKey"] = "F1", 		["name"] = "Hilfe-Menü", 					["category"] = "Allgemein", 	["func"] = self.m_HelpMenu};
			["KeyToggleAnimationMenu"]	= {["defaultKey"] = "F3", 		["name"] = "Animations-Menü", 				["category"] = "Allgemein", 	["func"] = self.m_AnimationMenu};
			["KeyToggleScoreboard"]		= {["defaultKey"] = "TAB", 		["name"] = "Spielerliste", 					["category"] = "Allgemein", 	["func"] = self.m_ScoreboardTrigger, ["trigger"] = "both"};
			["KeyToggleCustomMap"]		= {["defaultKey"] = "F11", 		["name"] = "Karte", 						["category"] = "Allgemein", 	["func"] = self.m_CustomMap};
			["KeyToggleInventory"]		= {["defaultKey"] = "i", 		["name"] = "Inventar", 						["category"] = "Allgemein", 	["func"] = self.m_Inventory};
			["KeyChairSitDown"]			= {["defaultKey"] = "l", 		["name"] = "Hinsetzen (auf Objekte)", 		["category"] = "Allgemein", 	["func"] = function() if localPlayer.vehicle then return false end if localPlayer:getWorldObject() then triggerServerEvent("onPlayerChairSitDown", localPlayer, localPlayer:getWorldObject()) end end};
			["KeyToggleDisplay"]		= {["defaultKey"] = "ralt", 	["name"] = "Anzeigen an/aus", 				["category"] = "Allgemein", 	["func"] = self.m_ToggleDisplays};
			["KeyCinemaVideoGUI"] 		= {["defaultKey"] = "x", 		["name"] = "Kino Videoverwaltung öffnen", 	["category"] = "Allgemein", 	["func"] = function() if CinemaLobby:isInstantiated() then CinemaLobby:getSingleton():openVideoGUI() end end, ["trigger"] = "down"};
			["KeyToggleHouseGarage"] 	= {["defaultKey"] = "h", 		["name"] = "Haus Garage benutzen", 			["category"] = "Allgemein", 	["func"] = function() triggerServerEvent("toggleGarageState",localPlayer) end, ["trigger"] = "down"};
			["KeyObjectPickup"]		 	= {["defaultKey"] = "n", 		["name"] = "Objekt aufheben / ablegen", 	["category"] = "Allgemein", 	["func"] = self.m_ToggleObjectPickup, ["trigger"] = "down"};
			["KeyToggleGate"]			= {["defaultKey"] = "h", 		["name"] = "Tore benutzen", 				["category"] = "Allgemein", 	["func"] = function() if getElementHealth(localPlayer) > 0 and not localPlayer.m_LastGateInteraction or (getTickCount()-localPlayer.m_LastGateInteraction) > 100 then triggerServerEvent("onPlayerTryGateOpen",localPlayer) localPlayer.m_LastGateInteraction = getTickCount() end end, ["trigger"] = "down"};

			-- Fraktion
			["KeyTogglePolicePanel"]	= {["defaultKey"] = "F4", 		["name"] = "Polizei-Computer", 				["category"] = "Fraktion", 		["func"] = self.m_PolicePanel};
			["KeyToggleRadioComm"]		= {["defaultKey"] = "F5", 		["name"] = "Funkgerät (Staat)", 			["category"] = "Fraktion", 		["func"] = self.m_RadioCommunication};
			["KeyTriggerChaseSound"]	= {["defaultKey"] = "2", 		["name"] = "Polizei-Megafon", 				["category"] = "Fraktion", 		["func"] = self.m_PoliceMegaphone, ["trigger"] = "down"};
			["KeyNeedhelp"] 			= {["defaultKey"] = "N/A", 		["name"] = "Hilferuf senden (Fraktion)", 	["category"] = "Fraktion", 		["func"] = function() triggerServerEvent("factionPlayerNeedhelp",localPlayer) end, ["trigger"] = "down"};
			
			-- Fahrzeuge
			["KeyIndicatorLeft"]		= {["defaultKey"] = ",", 		["name"] = "Blinker Links", 				["category"] = "Fahrzeug", 		["func"] = function() Indicator:getSingleton():switchIndicatorState("left") end};
			["KeyIndicatorRight"]		= {["defaultKey"] = ".", 		["name"] = "Blinker Rechts",				["category"] = "Fahrzeug", 		["func"] = function() Indicator:getSingleton():switchIndicatorState("right") end};
			["KeyIndicatorWarn"]		= {["defaultKey"] = "-", 		["name"] = "Warnblinkanlage", 				["category"] = "Fahrzeug", 		["func"] = function() Indicator:getSingleton():switchIndicatorState("warn") end};
			["KeySpeedLimit"]			= {["defaultKey"] = "k", 		["name"] = "Tempolimiter", 					["category"] = "Fahrzeug", 		["func"] = self.m_SpeedLimit, ["trigger"] = "both"};
			["KeyCruisingContro"]		= {["defaultKey"] = "c", 		["name"] = "Cruise-Control", 				["category"] = "Fahrzeug", 		["func"] = self.m_CruiseControl, ["trigger"] = "both"};
			["KeyVehiclePickUp"]	 	= {["defaultKey"] = "x", 		["name"] = "An Boot/Fahrzeug festhalten", 	["category"] = "Fahrzeug", 		["func"] = self.m_VehiclePickUp, ["trigger"] = "down"};
			["KeyToggleVehicleEngine"]	= {["defaultKey"] = "x", 		["name"] = "Fahrzeug Motor", 				["category"] = "Fahrzeug", 		["func"] = function() if localPlayer.vehicle then localPlayer.vehicle:toggleEngine() end end, ["trigger"] = "down"};
			["KeyToggleVehicleLight"]	= {["defaultKey"] = "l", 		["name"] = "Fahrzeug Licht", 				["category"] = "Fahrzeug", 		["func"] = function() if localPlayer.vehicle then localPlayer.vehicle:toggleLight() end end, ["trigger"] = "down"};
			["KeyToggleVehicleBrake"]	= {["defaultKey"] = "g", 		["name"] = "Handbremse", 					["category"] = "Fahrzeug", 		["func"] = function() if localPlayer.vehicle then localPlayer.vehicle:toggleHandbrake() end end, ["trigger"] = "down"};
			["KeyToggleVehicleELS"]		= {["defaultKey"] = "z", 		["name"] = "Rundumleuchten", 				["category"] = "Fahrzeug", 		["func"] = self.m_VehicleELS, ["trigger"] = "down"};
			["KeyToggleSeatbelt"]		= {["defaultKey"] = "m", 		["name"] = "An/Abschnallen", 				["category"] = "Fahrzeug", 		["func"] = function() if getPedOccupiedVehicle(localPlayer) then triggerServerEvent("toggleSeatBelt",localPlayer) end end, ["trigger"] =  "up"};

			-- Flugzeug
			["KeyToggleShamalInteior"] 	= {["defaultKey"] = "rctrl", 	["name"] = "Shamal Interior betreten", 		["category"] = "Flugzeug", 		["func"] = function() if localPlayer:getData("VSE:IsPassenger") and localPlayer:getData("VSE:Vehicle"):getModel() == 519 then triggerServerEvent("toggleShamalInterior", localPlayer:getData("VSE:Vehicle")) end end, ["trigger"] = "down"};

			-- Helikopter
			["KeyMagnetUse"]		 	= {["defaultKey"] = "lctrl", 	["name"] = "Magnet benutzen (Leviathan)", 	["category"] = "Helikopter", 	["func"] = function() if localPlayer.vehicle and localPlayer.vehicle:getModel() == 417 then localPlayer.vehicle:magnetVehicleCheck() end end, ["trigger"] = "down"};
			["KeyToggleInfrared"]		= {["defaultKey"] = "mouse2", 	["name"] = "Infrarot-Kamera", 				["category"] = "Helikopter", 	["func"] = self.m_InfraredVehicle, ["trigger"] = "down"};
			["KeyToggleHeliDriveby"] 	= {["defaultKey"] = "rshift", 	["name"] = "Auf Kufen stellen", 			["category"] = "Helikopter", 	["func"] = self.m_ToggleHeliDriveBy, ["trigger"] = "down"};
			["KeyToggleThermalLight"] 	= {["defaultKey"] = "h", 		["name"] = "Thermalkamera-Scheinwerfer", 	["category"] = "Helikopter", 	["func"] = self.m_ThermalLightKey, ["trigger"] = "down"};
			["KeyToggleThermalLock"] 	= {["defaultKey"] = "mouse1", 	["name"] = "Thermalkamera-Kontrollmodus", 	["category"] = "Helikopter", 	["func"] = self.m_ThermaControlModeKey, ["trigger"] = "down"};
			["KeyToggleThermalMode"] 	= {["defaultKey"] = "m", 		["name"] = "Thermalkamera-Suchmodus", 		["category"] = "Helikopter", 	["func"] = self.m_ThermalModeKey, ["trigger"] = "down"};
			["KeyToggleThermalSpeed"] 	= {["defaultKey"] = "lalt", 	["name"] = "Thermalkamera umschalten", 		["category"] = "Helikopter", 	["func"] = self.m_ThermalSpeedKey, ["trigger"] = "down"};

			-- Waffen
			["KeyToggleReddot"]			= {["defaultKey"] = "N/A", 		["name"] = "Rotpunktvisir umschalten", 		["category"] = "Waffe", 		["func"] = function() HUDUI:getSingleton().m_RedDot = not HUDUI:getSingleton().m_RedDot end, ["trigger"] = "up"};
			["KeyToggleTaser"]			= {["defaultKey"] = "o", 		["name"] = "Taser ziehen", 					["category"] = "Waffe", 		["func"] = function() if localPlayer:getFaction() and localPlayer:getFaction():isStateFaction() and localPlayer:getPublicSync("Faction:Duty") then triggerServerEvent("onPlayerItemUseServer", localPlayer, false, false, "Taser") end end, ["trigger"] = "down"};
			
			-- Angeln
			["KeyBobberBar"]		 	= {["defaultKey"] = "mouse1", 	["name"] = "Fisch fangen (Minigame)", 		["category"] = "Angeln", 		["func"] = self.m_BobberBar, ["trigger"] = "both"};
			["KeyThrowFishingRod"]		= {["defaultKey"] = "mouse1", 	["name"] = "Angel auswerfen / einziehen", 	["category"] = "Angeln", 		["func"] = self.m_ThrowFishingRod, ["trigger"] = "both"};
		},
		["FMS"] = {},


		--Disabled cause of MTA Bug #9178
	--  ["KeyChatFaction"]         = {["defaultKey"] = "1", ["name"] = "Chat: Fraktion", ["func"] = "chatbox", ["extra"] = "Fraktion"};
	--  ["KeyChatCompany"]         = {["defaultKey"] = "2", ["name"] = "Chat: Unternehmen", ["func"] = "chatbox", ["extra"] = "Unternehmen"};
	--  ["KeyChatGroup"]           = {["defaultKey"] = "3", ["name"] = "Chat: Gruppe", ["func"] = "chatbox", ["extra"] = "Gruppe"};
	}

	for i = 1, 6 do
		self.m_Keys["FMS"]["KeyStatusFMS"..i] = {["defaultKey"] = "N/A", ["name"] = "Status "..i, ["category"] = "", ["func"] = function() triggerServerEvent("factionRescueChangeRadioStatus", localPlayer, i) end, ["trigger"] = "down"};
	end

	bindKey("handbrake", "up", function() if isPedInVehicle(localPlayer) and getElementData(localPlayer.vehicle, "Handbrake") then setPedControlState("handbrake", true) end end)

	self:unloadBinds()
	self:loadBinds()
end

function KeyBinds:loadBinds()
	--outputChatBox("-------------", 0,255,0)
	for index, category in pairs(self.m_Keys) do
		for i, key in pairs(category) do
			--if key["func"] == "chatbox" then
				--local trigger = key["trigger"] or "down"
				--local keyName = core:get("KeyBindings", index, key["defaultKey"])
				--outputChatBox("Bind: Key: "..keyName.." Trigger: "..trigger.." Func: "..tostring(key["func"].." Extra: "..key["extra"]))
			--end
			if not key["load"] then
				bindKey(core:get("KeyBindings", i, key["defaultKey"]), key["trigger"] or "down", key["func"], key["extra"])
			else
				key["load"]()
			end
		end
	end
	--outputChatBox("-------------", 0,255,0)

end

function KeyBinds:unloadBinds()
	--outputChatBox("-------------", 255,0,0)
	for index, category in pairs(self.m_Keys) do
		for i, key in pairs(category) do
			--if key["func"] == "chatbox" then
			--	local trigger = key["trigger"] or "down"
			--	local keyName = core:get("KeyBindings", index, key["defaultKey"])
			--	outputChatBox("Unbind: Key: "..keyName.." Trigger: "..trigger.." Func: "..tostring(key["func"].." Extra: "..key["extra"]))
			--end
			if not key["unload"] then
				unbindKey(core:get("KeyBindings", i, key["defaultKey"]), key["trigger"] or "down", key["func"])
			else
				key["unload"]()
			end
		end
	end
--	outputChatBox("-------------", 255,0,0)
end

function KeyBinds:changeKey(keyName, newKey)
	self:unloadBinds()
	core:set("KeyBindings", keyName, newKey)
	self:loadBinds()
end

function KeyBinds:getBindsList(type)
	return self.m_Keys[type]
end

function KeyBinds:inventory()
	Inventory:getSingleton():toggle()
end

function KeyBinds:togglePhone()
	Phone:getSingleton():toggle()
end

function KeyBinds:customMap()
	CustomF11Map:getSingleton():toggle()
end

function KeyBinds:selfMenu()
	--[[
			elseif CompanyGUI:getSingleton():isVisible() then
		CompanyGUI:getSingleton():close()
	elseif FactionGUI:getSingleton():isVisible() then
		FactionGUI:getSingleton():close()
	elseif GroupGUI:getSingleton():isVisible() then
		GroupGUI:getSingleton():close()
	elseif TicketGUI:getSingleton():isVisible() then
		TicketGUI:getSingleton():close()
	elseif AdminGUI:getSingleton():isVisible() then
		AdminGUI:getSingleton():close()
	elseif MigratorPanel:getSingleton():isVisible() then
		MigratorPanel:getSingleton():close()
	elseif KeyBindings:getSingleton():isVisible() then
		KeyBindings:getSingleton():close()
	]]

	local doNotOpen = false
	local selfGUI = SelfGUI:getSingleton()
	for i, instance in pairs(selfGUI.m_OpenWindows) do
		if instance:isVisible() then
			instance:close()
			doNotOpen = true
		else -- in this case the player used the back button, so we just can remove it
			SelfGUI:getSingleton():removeWindow(self)
		end
	end

	if not doNotOpen then
		local selfGUI = SelfGUI:getSingleton()
		if selfGUI:isVisible() then
			selfGUI:close()
		else
			selfGUI:open()
		end
	end
end

function KeyBinds:animationMenu()
	if not localPlayer:isInVehicle() then

		if CustomAnimationGUI:isInstantiated() then
			return delete(CustomAnimationGUI:getSingleton())
		end

		if WalkingstyleGUI:isInstantiated() then
			return delete(WalkingstyleGUI:getSingleton())
		end

		if AnimationGUI:isInstantiated() then
			return delete(AnimationGUI:getSingleton())
		end

		AnimationGUI:new()
	end
end

function KeyBinds:policePanel()
	local isValidCop = (localPlayer:getFactionId() == 1 or localPlayer:getFactionId() == 2 or localPlayer:getFactionId() == 3) and localPlayer:getPublicSync("Faction:Duty")
	if not PolicePanel:isInstantiated() and isValidCop then --create new only if player is cop
		PolicePanel:new()
		return true
	end
	if PolicePanel:getSingleton():isVisible() or isValidCop then -- hide it anytime, show it only if player is cop
		PolicePanel:getSingleton():toggle()	
		PolicePanel:getSingleton():updateCurrentView()
	end
end

function KeyBinds:toggleInfrared() 
	if localPlayer.vehicle then
		if not VehicleInfrared:isInstantiated() then 
			triggerServerEvent("VehicleInfrared:onUse", localPlayer)
		else 
			triggerServerEvent("VehicleInfrared:onStop", localPlayer)
		end
	end
end

function KeyBinds:toggleHelicopterDriveBy() 
	if not VehicleInfrared:isInstantiated() and (not self.m_LastHeliTrigger or getTickCount() > self.m_LastHeliTrigger) then 
		self.m_LastHeliTrigger = getTickCount() + 200
		HelicopterDrivebyManager:getSingleton():tryDriveby()
	end
end

function KeyBinds:thermalLightKey() 
	if VehicleInfrared:isInstantiated() then
		VehicleInfrared:getSingleton():key("light")
	end
end

function KeyBinds:thermalControlKey() 
	if VehicleInfrared:isInstantiated() then
		VehicleInfrared:getSingleton():key("control")
	end
end

function KeyBinds:thermalModeKey() 
	if VehicleInfrared:isInstantiated() then
		VehicleInfrared:getSingleton():key("mode")
	end
end

function KeyBinds:thermalSpeedKey() 
	if VehicleInfrared:isInstantiated() then
		VehicleInfrared:getSingleton():key("slow")
	end
end

function KeyBinds:radioCommunication() 
	if not RadioCommunicationGUI:isInstantiated() and localPlayer:isRadioCommunicationAllowed() then
		RadioCommunicationGUI:new()
		return true
	end
	if RadioCommunicationGUI:isInstantiated() then
		delete(RadioCommunicationGUI:getSingleton())	
	end
end

function KeyBinds:helpMenu()
	if not HelpGUI:isInstantiated() then
		HelpGUI:new()
	else
		delete(HelpGUI:getSingleton())
	end
end

function KeyBinds:scoreboardGUI(_, keyState)
	if keyState == "down" then
		ScoreboardGUI:getSingleton():setVisible(true):bringToFront()
	else
		ScoreboardGUI:getSingleton():setVisible(false)
	end
end

function KeyBinds:toggleDisplay() 
	localPlayer.m_DisplayMode = not localPlayer.m_DisplayMode
	core:set("HUD", "ToggleQuickDisplay", localPlayer.m_DisplayMode)
end

function KeyBinds:vehicleELS(__, keyState)
	if localPlayer.vehicle and localPlayer.vehicle.m_ELSPreset then 
		if localPlayer.vehicleSeat == 0 then
			if VehicleELS:getSingleton():isEnabled() then
				triggerServerEvent("vehicleELSToggleRequest",localPlayer.vehicle, not localPlayer.vehicle.m_ELSActive) 
				if localPlayer.vehicle.towedByVehicle and localPlayer.vehicle.towedByVehicle.m_ELSPreset and localPlayer.vehicle.towedByVehicle:getCategory() == 2 then -- trailer
					triggerServerEvent("vehicleELSToggleRequest",localPlayer.vehicle.towedByVehicle, not localPlayer.vehicle.towedByVehicle.m_ELSActive) 
				end
			else
				WarningBox:new(_"Um die Rundumleuchten zu sehen musst du diese in den Einstellungen (F2) aktivieren.")
			end
		end
	end
end

function KeyBinds:tryEnterEntrance( __, keystate)
	if keystate == "up" then
		if not localPlayer.m_LastTryEntrance or localPlayer.m_LastTryEntrance+500 <= getTickCount() then
			if localPlayer:getPublicSync("TeleporterPickup") and isElement(localPlayer:getPublicSync("TeleporterPickup")) then 
				if Vector3(localPlayer:getPosition() - localPlayer:getPublicSync("TeleporterPickup"):getPosition()):getLength() < 3 then
					triggerServerEvent("onTryEnterTeleporter", localPlayer)
				end
			end
			if localPlayer:getPrivateSync("EntranceId") then
				triggerEvent("onTryEnterance", localPlayer)
			end
			if localPlayer.m_Entrance and localPlayer.m_Entrance:check() then
				if localPlayer.m_Entrance.m_Text == _"AUFZUG" then
					triggerServerEvent("onTryElevator", localPlayer)
				elseif localPlayer.m_Entrance.m_Text == _"HAUS" then
					triggerServerEvent("houseRequestGUI", localPlayer)
				elseif localPlayer.m_Entrance.m_Text == _"FAHRZEUGE" then 
					triggerServerEvent("onTryVehicleSpawner", localPlayer)
				elseif localPlayer.m_Entrance.m_Text == _"VERSCHROTTUNG" then 
					triggerServerEvent("VehicleScrapper:onVehicleScrapRequest", localPlayer)
				elseif localPlayer.m_Entrance.m_Text == _"FAHRZEUGKAUF" then 
					triggerServerEvent("onVehicleShopOpen", localPlayer)
				elseif localPlayer.m_Entrance.m_Text == _"HOCHHAUS" then
					triggerServerEvent("Skyscraper:requestGUI", localPlayer)
				else
					triggerServerEvent("GroupPropertyClientInput", localPlayer) 
					triggerServerEvent("clientTryEnterEntrance", localPlayer)
				end
			end
			localPlayer.m_LastTryEntrance = getTickCount()
		end
	end
end

function KeyBinds:usePoliceMegaphone()
	if not self.m_LastMegaphoneUsage then self.m_LastMegaphoneUsage = 0 end
	if getTickCount() - self.m_LastMegaphoneUsage < 7000 then
		return
	end

	if localPlayer:getFaction() and localPlayer:getFaction():isStateFaction() then
		if localPlayer:getPublicSync("Faction:Duty") then 
			if localPlayer.vehicle and getElementData(localPlayer.vehicle, "StateVehicle") and localPlayer == localPlayer.vehicle.controller then
				self.m_LastMegaphoneUsage = getTickCount()
				triggerServerEvent("PoliceAnnouncements:triggerChaseSound", localPlayer, localPlayer.vehicle) 
			end 
		end
	end
end

function KeyBinds:toggleObjectPickup()
	triggerServerEvent("toggleObjectPickup", localPlayer)
end

function KeyBinds:bobberBar(_, keyState)
	if BobberBar:isInstantiated() then
		BobberBar:getSingleton():handleClick(nil, keyState)
	end
end

function KeyBinds:throwFishingRod(_, keyState)
	if FishingRod:isInstantiated() then
		FishingRod:getSingleton():handleClick(nil, keyState)
	end
end

--[[
addCommandHandler("checkKeys",function()
	local keyTable = { "mouse1", "mouse2", "mouse3", "mouse4", "mouse5", "mouse_wheel_up", "mouse_wheel_down", "arrow_l", "arrow_u",
	 "arrow_r", "arrow_d", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
	 "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "num_0", "num_1", "num_2", "num_3", "num_4", "num_5",
	 "num_6", "num_7", "num_8", "num_9", "num_mul", "num_add", "num_sep", "num_sub", "num_div", "num_dec", "F1", "F2", "F3", "F4", "F5",
	 "F6", "F7", "F8", "F9", "F10", "F11", "F12", "backspace", "tab", "lalt", "ralt", "enter", "space", "pgup", "pgdn", "end", "home",
	 "insert", "delete", "lshift", "rshift", "lctrl", "rctrl", "[", "]", "pause", "capslock", "scroll", ";", ",", "-", ".", "/", "#", "\\", "=" }
	 outputChatBox("Bounded chatbox command keys: ", 255, 255, 0)
	for _,key in ipairs(keyTable)do --loop through keyTable
		local commands = getCommandsBoundToKey(key, "down")
		if commands and type(commands) == "table" then
			for command, state in pairs (commands) do
				if command == "chatbox" then
					outputChatBox(key..": "..command)
				end
			end
		end
	end
end)
]]
