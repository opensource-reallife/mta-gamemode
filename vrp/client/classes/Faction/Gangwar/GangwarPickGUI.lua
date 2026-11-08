GangwarPickGUI = inherit(GUIForm)

function GangwarPickGUI.open(data, submitText, callback)
	if GangwarPickGUI.Current then
		delete(GangwarPickGUI.Current)
	end
	GangwarPickGUI.Current = GangwarPickGUI:new(data, submitText, callback)
end

function GangwarPickGUI:constructor(data, submitText, callback)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 16)
	self.m_Height = grid("y", 12)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _("Spielereinteilung - %s", data.title), true, true, self)

	self.m_Members = data.members
	self.m_Names = {}
	for key, member in ipairs(data.members) do
		self.m_Names[member.id] = member
	end
	self.m_Picks = {}
	for key, id in ipairs(data.picks) do
		self.m_Picks[#self.m_Picks + 1] = id
	end
	self.m_MaxPlayers = data.maxPlayers
	self.m_CanModify = data.canModify
	self.m_LockedId = data.lockedId
	self.m_Callback = callback

	GUIGridLabel:new(1, 1, 11, 1, _"Reihenfolge = Save-Reihenfolge: Wer oben steht, wird zuletzt gesaved.", self.m_Window)
	self.m_SubmitButton = GUIGridButton:new(12, 1, 4, 1, submitText, self.m_Window):setBackgroundColor(Color.Green)
	self.m_SubmitButton:setEnabled(data.canModify)
	self.m_SubmitButton.onLeftClick = bind(self.onSubmitClick, self)

	self.m_MemberList = GUIGridGridList:new(1, 2, 7, 10, self.m_Window)
	self.m_MemberList:addColumn(_"Mitglieder", 0.7)
	self.m_MemberList:addColumn(_"Status", 0.3)

	self.m_AddButton = GUIGridButton:new(8, 2, 1, 3, FontAwesomeSymbols.Right, self.m_Window):setFont(FontAwesome(15)):setFontSize(1):setBarEnabled(false)
	self.m_AddButton:setBackgroundColor(tocolor(2, 45, 16, 255))
	self.m_AddButton:setEnabled(data.canModify)
	self.m_AddButton.onLeftClick = bind(self.onAddClick, self)

	self.m_RemoveButton = GUIGridButton:new(8, 5, 1, 3, FontAwesomeSymbols.Left, self.m_Window):setFont(FontAwesome(15)):setFontSize(1):setBarEnabled(false)
	self.m_RemoveButton:setBackgroundColor(tocolor(66, 3, 4, 255))
	self.m_RemoveButton:setEnabled(data.canModify)
	self.m_RemoveButton.onLeftClick = bind(self.onRemoveClick, self)

	self.m_UpButton = GUIGridButton:new(8, 8, 1, 2, FontAwesomeSymbols.Double_Up, self.m_Window):setFont(FontAwesome(15)):setFontSize(1):setBarEnabled(false)
	self.m_UpButton:setEnabled(data.canModify)
	self.m_UpButton.onLeftClick = function() self:moveSelected(-1) end

	self.m_DownButton = GUIGridButton:new(8, 10, 1, 2, FontAwesomeSymbols.Double_Down, self.m_Window):setFont(FontAwesome(15)):setFontSize(1):setBarEnabled(false)
	self.m_DownButton:setEnabled(data.canModify)
	self.m_DownButton.onLeftClick = function() self:moveSelected(1) end

	self.m_PickList = GUIGridGridList:new(9, 2, 7, 10, self.m_Window)
	self.m_PickList:addColumn(_"Eingeteilt", 1)

	self:refresh()
end

function GangwarPickGUI:destructor()
	GangwarPickGUI.Current = nil
	GUIForm.destructor(self)
end

function GangwarPickGUI:isPicked(id)
	for key, pickId in ipairs(self.m_Picks) do
		if pickId == id then
			return key
		end
	end
	return false
end

function GangwarPickGUI:refresh(selectedId)
	self.m_MemberList:clear()
	for key, member in ipairs(self.m_Members) do
		if not self:isPicked(member.id) then
			local item = self.m_MemberList:addItem(member.name, member.online and _"Online" or _"Offline")
			item.m_Id = member.id
			item.onLeftDoubleClick = function() self:addPick(member.id) end
			if not member.online then
				item:setColumnColor(2, Color.LightGrey)
			end
		end
	end

	self.m_PickList:clear()
	for key, id in ipairs(self.m_Picks) do
		local member = self.m_Names[id]
		local item = self.m_PickList:addItem(("• %d  %s%s"):format(key, member and member.name or tostring(id), (member and not member.online) and " (Offline)" or ""))
		item.m_Id = id
		item.onLeftDoubleClick = function() self:removePick(id) end
		if id == selectedId then
			self.m_PickList:onInternalSelectItem(item)
		end
	end
end

function GangwarPickGUI:addPick(id)
	if not self.m_CanModify or self:isPicked(id) then return end
	if #self.m_Picks >= self.m_MaxPlayers then
		ErrorBox:new(_("Es können höchstens %d Spieler eingeteilt werden!", self.m_MaxPlayers))
		return
	end
	self.m_Picks[#self.m_Picks + 1] = id
	self:refresh()
end

function GangwarPickGUI:removePick(id)
	if not self.m_CanModify then return end
	if id == self.m_LockedId then
		ErrorBox:new(_"Wer den Angriff gestartet hat, bleibt eingeteilt. Nur die Reihenfolge lässt sich ändern.")
		return
	end
	local index = self:isPicked(id)
	if index then
		table.remove(self.m_Picks, index)
		self:refresh()
	end
end

function GangwarPickGUI:moveSelected(direction)
	local item = self.m_PickList:getSelectedItem()
	if not item then return end
	local index = self:isPicked(item.m_Id)
	local target = index and index + direction
	if not target or target < 1 or target > #self.m_Picks then return end
	self.m_Picks[index], self.m_Picks[target] = self.m_Picks[target], self.m_Picks[index]
	self:refresh(item.m_Id)
end

function GangwarPickGUI:onAddClick()
	local item = self.m_MemberList:getSelectedItem()
	if item then
		self:addPick(item.m_Id)
	end
end

function GangwarPickGUI:onRemoveClick()
	local item = self.m_PickList:getSelectedItem()
	if item then
		self:removePick(item.m_Id)
	end
end

function GangwarPickGUI:onSubmitClick()
	self.m_Callback(self.m_Picks)
	delete(self)
end
