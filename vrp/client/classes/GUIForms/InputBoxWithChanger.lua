-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/InputBoxWithChanger.lua
-- *  PURPOSE:     Inputbox with Changer for admin gui class
-- *
-- ****************************************************************************
InputBoxWithChanger = inherit(GUIForm)

function InputBoxWithChanger:constructor(title, text, input, items, callback)
    GUIWindow.updateGrid()
	self.m_Width = grid("x", 18)
	self.m_Height = grid("y", 5)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, title, true, true, self)
	GUIGridLabel:new(1, 1, 15, 1, text, self.m_Window):setFont(VRPFont(30))
	self.m_InputBox = GUIGridEdit:new(1, 2, 17, 1, self.m_Window)
	self.m_Changer = GUIGridChanger:new(1, 3, 17, 1, self.m_Window)
	local item
	self.m_itemTable = {}
	for index, v in pairs(items) do
		item = self.m_Changer:addItem(v)
		self.m_itemTable[v] = index
	end
	self.m_SubmitButton = GUIGridButton:new(1, 4, 7, 1, _"Bestätigen", self.m_Window):setBackgroundColor(Color.Green)

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