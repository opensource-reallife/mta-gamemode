ItemAmountBox = inherit(GUIForm)

function ItemAmountBox:constructor(title, text, maxAmount, callback)
	local scale = Inventory.getScale()
	local function s(value)
		return math.floor(value * scale)
	end
	local width = s(380)
	local textWidth = dxGetTextWidth(text, 1, getVRPFont(VRPFont(s(24))))
	local textHeight = math.ceil(textWidth * 1.1 / (width - s(20))) * s(24)
	local offset = textHeight - s(24)
	local height = s(180) + offset

	GUIForm.constructor(self, screenWidth/2 - width/2, screenHeight/2 - height/2, width, height)
	self.m_MaxAmount = maxAmount
	self.m_Callback = callback

	self.m_Window = GUIWindow:new(0, 0, width, height, title, true, true, self)
	Inventory.scaleTitleBar(self.m_Window, scale)
	self.m_Window:deleteOnClose(true)

	GUILabel:new(s(10), s(38), width-s(20), textHeight, text, self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setMultiline(true)
	GUILabel:new(s(10), s(62) + offset, width-s(20), s(20), _("Du hast %d Stück.", maxAmount), self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)

	self.m_Amount = GUIEdit:new(s(10), s(90) + offset, s(110), s(32), self.m_Window):setNumeric(true, true)
	self.m_Amount:setText("1")

	local buttons = {{"1", 1}, {_"Hälfte", math.max(1, math.floor(maxAmount / 2))}, {_"Alle", maxAmount}}
	for index, button in ipairs(buttons) do
		local element = GUIButton:new(s(125) + (index - 1) * s(83), s(90) + offset, s(78), s(32), button[1], self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
		element.onLeftClick = function() self.m_Amount:setText(tostring(button[2])) end
	end

	self.m_Confirm = GUIButton:new(s(10), s(134) + offset, width-s(20), s(34), _"Bestätigen", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1):setBackgroundColor(Color.Green)
	self.m_Confirm.onLeftClick = function() self:confirm() end
end

function ItemAmountBox:confirm()
	local amount = math.floor(tonumber(self.m_Amount:getText()) or 0)
	if amount <= 0 or amount > self.m_MaxAmount then
		ErrorBox:new(_("Bitte gib eine Menge von 1 bis %d ein!", self.m_MaxAmount))
		return
	end
	local callback = self.m_Callback
	delete(self)
	callback(amount)
end
