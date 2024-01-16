-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/QuestionBoxExtended.lua
-- *  PURPOSE:     Question box Extended class
-- *
-- ****************************************************************************
QuestionBoxExtended = inherit(GUIForm)
inherit(Singleton, QuestionBoxExtended)

function QuestionBoxExtended:constructor(text, firstButtonText, secondButtonText, firstButtonCallback, secondButtonCallback, rangeElement, range)
	GUIForm.constructor(self, screenWidth/2 - screenWidth*0.4/2, screenHeight/2 - screenHeight*0.18/2, screenWidth*0.4, screenHeight*0.18, true, false, rangeElement, range)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Frage", true, true, self)
	GUILabel:new(self.m_Width*0.01, self.m_Height*0.22, self.m_Width*0.98, self.m_Height*0.55, text, self.m_Window):setFont(VRPFont(self.m_Height*0.17))
	self.m_FirstButton = GUIButton:new(self.m_Width*0.1, self.m_Height*0.75, self.m_Width*0.35, self.m_Height*0.2, _"Ja", self.m_Window):setBackgroundColor(Color.Green)
	self.m_SecondButton = GUIButton:new(self.m_Width*0.55, self.m_Height*0.75, self.m_Width*0.35, self.m_Height*0.2, _"Nein", self.m_Window):setBackgroundColor(Color.Red)

    if firstButtonText then 
    self.m_FirstButton:setText(firstButtonText)
    end 
    if secondButtonText then
        self.m_SecondButton:setText(secondButtonText)
    end

	self.m_FirstButtonCallBack = firstButtonCallback
	self.m_SecondButtonCallBack = secondButtonCallback

	self.m_FirstButton.onLeftClick = function() if self.m_FirstButtonCallBack then self.m_FirstButtonCallBack() end delete(self) end
	self.m_SecondButton.onLeftClick = function() if self.m_SecondButtonCallBack then self.m_SecondButtonCallBack() end delete(self) end
end

function QuestionBoxExtended:destructor()
	GUIForm.destructor(self)
end
