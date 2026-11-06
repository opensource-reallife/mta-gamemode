AdminInventoryGUI = inherit(GUIForm)
inherit(Singleton, AdminInventoryGUI)

addRemoteEvents{"adminShowInventoryView"}

function AdminInventoryGUI:constructor(playerName, sections)
	local scale = Inventory.getScale()
	local function s(value)
		return math.floor(value * scale)
	end
	self.s = s
	local width, height = s(900), s(540)
	self.m_ListWidth = s(590)

	GUIForm.constructor(self, screenWidth/2 - width/2, screenHeight/2 - height/2, width, height)
	self.m_Window = GUIWindow:new(0, 0, width, height, _("Inventar von %s (nur Ansicht)", playerName), true, true, self)
	Inventory.scaleTitleBar(self.m_Window, scale)
	self.m_Window:deleteOnClose(true)

	self.m_Sections = sections

	self.m_SectionGrid = GUIGridList:new(s(10), s(40), s(280), height-s(50), self.m_Window, nil, nil, s(30))
	self.m_SectionGrid:addColumn(_"Bereich", 0.62)
	self.m_SectionGrid:addColumn(_"kg", 0.32)
	self.m_SectionGrid:setFont(VRPFont(s(22)))

	self.m_Summary = GUILabel:new(s(300), s(40), self.m_ListWidth, s(26), "", self.m_Window):setFont(VRPFont(s(24))):setFontSize(1)

	self.m_RowGrid = GUIGridList:new(s(300), s(68), self.m_ListWidth, height-s(78), self.m_Window, nil, nil, s(30))
	local iconShare = s(34) / self.m_ListWidth
	self.m_NameShare = 1 - iconShare - 0.14 - 0.14 - 15 / self.m_ListWidth
	self.m_RowGrid:addColumn("", iconShare)
	self.m_RowGrid:addColumn(_"Item", self.m_NameShare)
	self.m_RowGrid:addColumn(_"Menge", 0.14)
	self.m_RowGrid:addColumn(_"Gewicht", 0.14)
	self.m_RowGrid:setFont(VRPFont(s(24)))

	for index, section in ipairs(sections) do
		local capacity = section.capacity > 0 and ("%.1f/%d"):format(section.weight, section.capacity) or ("%.1f"):format(section.weight)
		local item = self.m_SectionGrid:addItem(Inventory.fitText(section.title, s(165), s(22)), capacity)
		item:setFont(VRPFont(s(22)))
		item.onLeftClick = function() self:showSection(index) end
		if index == 1 then
			self.m_SectionGrid:onInternalSelectItem(item)
		end
	end
	self:showSection(1)
end

function AdminInventoryGUI:showSection(index)
	local section = self.m_Sections[index]
	if not section then return end
	local s = self.s
	local inventory = Inventory:getSingleton()

	if section.capacity > 0 then
		self.m_Summary:setText(_("%s: %.2f / %d kg", section.title, section.weight, section.capacity))
	else
		self.m_Summary:setText(_("%s: %.2f kg", section.title, section.weight))
	end

	table.sort(section.rows, function(a, b) return a["Objekt"] < b["Objekt"] end)
	self.m_RowGrid:clear()
	local nameWidth = self.m_ListWidth * self.m_NameShare - s(8)
	for _index, row in ipairs(section.rows) do
		local weight = inventory:getRowWeight(row)
		local item = self.m_RowGrid:addItem(inventory:getItemIcon(row), Inventory.fitText(inventory:getDisplayName(row), nameWidth, s(24)), row["Menge"], ("%.2f"):format(weight))
		item:setColumnToImage(1, true, s(30))
		item:setFont(VRPFont(s(24)))
	end
end

addEventHandler("adminShowInventoryView", root, function(playerName, sections)
	if AdminInventoryGUI:isInstantiated() then
		delete(AdminInventoryGUI:getSingleton())
	end
	AdminInventoryGUI:new(playerName, sections)
end)
