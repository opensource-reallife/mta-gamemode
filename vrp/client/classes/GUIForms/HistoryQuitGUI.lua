-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/GUIForms/HistoryQuitGUI.lua
-- *  PURPOSE:     History Quit GUI
-- *
-- ****************************************************************************
HistoryQuitGUI = inherit(GUIForm)

function HistoryQuitGUI:constructor(callBack)
	GUIForm.constructor(self, screenWidth/2 - screenWidth*0.4/2, screenHeight/2 - screenHeight*0.22/2, screenWidth*0.4, screenHeight*0.14)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Kündigen", true, true, self)
	self.m_ReasonQuitLabel = GUILabel:new(self.m_Width*0.02, self.m_Height*0.26, self.m_Width*0.96, self.m_Height*0.18, _"Grund", self.m_Window):setFont(VRPFont(self.m_Height*0.18))
	self.m_ReasonQuit = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.48, self.m_Width*0.96, self.m_Height*0.18, self.m_Window):setMaxLength(128)

	self.m_YesButton = GUIButton:new(self.m_Width*0.13, self.m_Height*0.72, self.m_Width*0.29, self.m_Height*0.22, _"Kündigen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_NoButton = GUIButton:new(self.m_Width*0.58, self.m_Height*0.72, self.m_Width*0.29, self.m_Height*0.22, _"Abbrechen", self.m_Window)--:setBackgroundColor(Color.Red)

	self.m_YesButton.onLeftClick = function()
		if self.m_ReasonQuit.m_Text == "" then
			ErrorBox:new(_"Du musst einen Grund angeben!")
			return
		end
        
        if callBack then
            callBack(self.m_ReasonQuit.m_Text)
        end
		delete(self)
	end

	self.m_NoButton.onLeftClick = function() delete(self) end
end
