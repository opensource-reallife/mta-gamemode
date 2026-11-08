GangwarMenuGUI = inherit(GUIForm)

function GangwarMenuGUI:constructor(info)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 10)
	self.m_Height = grid("y", 6)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Gangwar", true, true, self)

	local isPrepare = info.phase == "prepare"
	local phase = isPrepare and _"Aufbauphase" or (info.phase == "battle" and _"Attackphase" or _"Endphase")
	GUIGridLabel:new(1, 1, 9, 1, _("%s gegen %s um %s", info.attacker, info.defender, info.area), self.m_Window)
	GUIGridLabel:new(1, 2, 9, 1, _("%s: noch %d:%02d", phase, math.floor(info.time/60), info.time%60), self.m_Window)

	self.m_VehicleButton = GUIGridButton:new(1, 3, 9, 1, _"Fahrzeug spawnen", self.m_Window)
	self.m_VehicleButton:setEnabled(isPrepare and info.entered or false)
	self.m_VehicleButton.onLeftClick = function()
		triggerServerEvent("Gangwar:requestVehicleMenu", localPlayer)
		delete(self)
	end

	self.m_PickButton = GUIGridButton:new(1, 4, 9, 1, info.canPick and _"Einteilung bearbeiten" or _"Einteilung ansehen", self.m_Window)
	self.m_PickButton:setEnabled(isPrepare)
	self.m_PickButton.onLeftClick = function()
		triggerServerEvent("Gangwar:requestPickData", localPlayer)
		delete(self)
	end

	self.m_LeaveButton = GUIGridButton:new(1, 5, 9, 1, _"Gangwar verlassen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_LeaveButton:setEnabled(info.entered or false)
	self.m_LeaveButton.onLeftClick = function()
		local text = isPrepare and _"Gangwar verlassen? Du kannst in der Aufbauphase wieder beitreten." or (info.phase == "battle" and _"Gangwar verlassen? Du scheidest damit endgültig aus." or _"Gangwar verlassen?")
		QuestionBox:new(text, function()
			triggerServerEvent("Gangwar:leave", localPlayer)
		end)
		delete(self)
	end
end

function GangwarMenuGUI:destructor()
	GangwarMenuGUI.Current = nil
	GUIForm.destructor(self)
end
