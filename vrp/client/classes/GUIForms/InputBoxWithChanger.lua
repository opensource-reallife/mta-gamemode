-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/InputBoxWithChanger.lua
-- *  PURPOSE:     Inputbox with Changer for admin gui class
-- *
-- ****************************************************************************
InputBoxWithChanger = inherit(GUIForm)

function InputBoxWithChanger:constructor(title, text, input, items, callback)
	GUIForm.constructor(self, screenWidth/2 - 707/2, screenHeight/2 - 218/2, 707, 218)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, title, true, true, self)
	GUILabel:new(14, 39, 692, 30, text, self.m_Window)
	self.m_InputBox = GUIGridEdit:new(1, 2.5, 5, 1, self.m_Window)
	self.m_Changer = GUIGridChanger:new(1, 4, 5, 1, self.m_Window)
	local item
	self.m_itemTable = {}
	for index, v in pairs(items) do
		item = self.m_Changer:addItem(v)
		self.m_itemTable[v] = index
	end
	self.m_SubmitButton = GUIButton:new(7, 164, 247, 35, _"Bestätigen", self.m_Window):setBackgroundColor(Color.Green)

	self.m_SubmitButton.onLeftClick = function()
		if callback then
			callback(self.m_InputBox:getText(), self:getSelectedIndex())
		end
		delete(self)
	end
end

function InputBoxWithChanger:getSelectedIndex()
	local name = self.m_Changer:getIndex()
	return name
end