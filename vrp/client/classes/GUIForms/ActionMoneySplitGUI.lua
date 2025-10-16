-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ActionMoneySplitGUI.lua
-- *  PURPOSE:     ActionMoneySplitGUI Class
-- *
-- ****************************************************************************
ActionMoneySplitGUI = inherit(GUIForm)
inherit(Singleton, ActionMoneySplitGUI)


addRemoteEvents{"sendActionMoneySplitData"}
function ActionMoneySplitGUI:constructor()
    GUIWindow.updateGrid()
    self.m_Width = grid("x", 14)
    self.m_Height = grid("y", 11)

    GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Aktionsbeteiligung", true, true, self)
	self.m_Window:addBackButton(function () FactionGUI:getSingleton():show() delete(self) end)

	self.m_Changes = {}

    self.m_Label = {}
	self.m_Label["WeaponTruck"] = GUIGridLabel:new(1, 2, 5, 1, _"Waffentruck", self.m_Window)
	self.m_Label["StateEvidenceTruck"] = GUIGridLabel:new(1, 3, 5, 1, _"Geldtruck", self.m_Window)
	self.m_Label["BankRobbery"] = GUIGridLabel:new(1, 4, 5, 1, _"Bankraub", self.m_Window)
	self.m_Label["JewelryStoreRobbery"] = GUIGridLabel:new(1, 5, 5, 1, _"Juwelierraub", self.m_Window)

	self.m_LabelCurrentValue = {}
	self.m_LabelCurrentValue["WeaponTruck"] = GUIGridLabel:new(6, 2, 2, 1, "", self.m_Window)
	self.m_LabelCurrentValue["StateEvidenceTruck"] = GUIGridLabel:new(6, 3, 2, 1, "", self.m_Window)
	self.m_LabelCurrentValue["BankRobbery"] = GUIGridLabel:new(6, 4, 2, 1, "", self.m_Window)
	self.m_LabelCurrentValue["JewelryStoreRobbery"] = GUIGridLabel:new(6, 5, 2, 1, "", self.m_Window)

    self.m_Slider = {}
    self.m_Slider["WeaponTruck"] = GUIGridSlider:new(8, 2, 5, 1, self.m_Window)
    self.m_Slider["StateEvidenceTruck"] = GUIGridSlider:new(8, 3, 5, 1, self.m_Window)
	self.m_Slider["BankRobbery"] = GUIGridSlider:new(8, 4, 5, 1, self.m_Window)
	self.m_Slider["JewelryStoreRobbery"] = GUIGridSlider:new(8, 5, 5, 1, self.m_Window)

	for i, v in pairs(self.m_Slider) do
		v.m_RoundOffset = 0
		v.onUpdate = function(value)
			local realState = (value > self.m_MaxStates[i] and self.m_MaxStates[i]) or (value < 0 and 0) or value
			self.m_Changes[i] = realState

			if self.m_LabelCurrentValue[i] then
				self.m_LabelCurrentValue[i]:setText(("%s%%"):format(realState))
			end
		end
	end

	self.m_SaveButton = GUIGridButton:new(8, 10, 6, 1, _"Speichern", self.m_Window):setBackgroundColor(Color.Green)
	self.m_SaveButton.onLeftClick = bind(self.sendChanges, self)


	triggerServerEvent("actionMoneySplitRequestSplitData", localPlayer)

	addEventHandler("sendActionMoneySplitData", root, bind(self.loadData, self))
end

function ActionMoneySplitGUI:loadData(data)
	self.m_CurrentStates = data["currentStates"]
	self.m_MaxStates = data["maxStates"]
	self.m_MaxSplitPerPlayer  = data["maxSplitPerPlayer"]

	local currentStates = data["currentStates"]
	local maxStates = data["maxStates"]
	local maxSplitPerPlayer = data["maxSplitPerPlayer"]

	for i, v in pairs(self.m_Slider) do
		v:setRange(0, self.m_MaxStates[i] or 0)
		local currentState = currentStates[i]
		local realState = not currentState and 0 or (currentState > maxStates[i] and maxStates[i]) or (currentState < 0 and 0) or currentState

		v:setValue(realState)

		if self.m_LabelCurrentValue[i] then
			self.m_LabelCurrentValue[i]:setText(("%s%%"):format(realState))
		end
	end
end

function ActionMoneySplitGUI:sendChanges()
	triggerServerEvent("actionMoneySplitChangeSplits", localPlayer, self.m_Changes)
end