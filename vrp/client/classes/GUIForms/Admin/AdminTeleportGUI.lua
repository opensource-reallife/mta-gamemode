AdminTeleportGUI = inherit(GUIForm)
inherit(Singleton, AdminTeleportGUI)

addRemoteEvents{"AdminTeleportGUI:Open", "AdminTeleportGUI:SendData"}

function AdminTeleportGUI:constructor(tp, cats)
    GUIWindow.updateGrid()
	self.m_Width = grid("x", 22)
	self.m_Height = grid("y", 15)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Teleportieren", true, true, self)

	self.m_ChangerIdToCatId = {}

	self.m_TeleportPoints = {}
	self.m_TeleportCategories = {}

	self.m_CategoryChanger = GUIGridChanger:new(1, 1, 10, 1, self.m_Window)
	self.m_CategoryChanger.onChange = function(item, index)
		self.m_TeleportGridList:clear()
		for i, v in pairs(self.m_TeleportPoints) do
			if (v.category == self.m_ChangerIdToCatId[index] or self.m_ChangerIdToCatId[index] == -1) then
				self:addIeleportPointToGridlist(i, v, self.m_TeleportCategories[v.category]);
			end
		end
	end

	self.m_TeleportGridList = GUIGridGridList:new(1, 2, 10, 12, self.m_Window)
	self.m_TeleportGridList:addColumn(_"Name", 0.35)
	self.m_TeleportGridList:addColumn(_"Shortcuts", 0.35)
	self.m_TeleportGridList:addColumn(_"Kategorie", 0.3)
	self.m_TeleportGridList:setSortable{_"Name", _"Shortcuts", _"Kategorie"}
	self.m_TeleportGridList:setSortColumn(_"Name", "up")
	
	self.m_InformationRectangle = GUIGridEmptyRectangle:new(12, 1, 10, 13, 1, Color.White, self.m_Window)
	self.m_TeleportPointLocation = GUIGridMiniMap:new(14, 2, 6, 6, self.m_Window)
	self.m_TeleportPointLocation:setMapPosition(100, 100)
	
	self.m_NameLabel = GUIGridLabel:new(13, 8, 3, 1, _"Name:", self.m_Window)
	self.m_ShortcutsLabel = GUIGridLabel:new(13, 8.5, 3, 1, _"Shortcuts:", self.m_Window)
	self.m_CategoryLabel = GUIGridLabel:new(13, 9, 3, 1, _"Kategorie:", self.m_Window)
	self.m_PosXLabel = GUIGridLabel:new(13, 10, 3, 1, _"PosX:", self.m_Window)
	self.m_PosYLabel = GUIGridLabel:new(13, 10.5, 3, 1, _"PosY:", self.m_Window)
	self.m_PosZLabel = GUIGridLabel:new(13, 11, 3, 1, _"PosZ:", self.m_Window)
	self.m_InteriorLabel = GUIGridLabel:new(13, 11.5, 3, 1, _"Interior:", self.m_Window)
	self.m_DimensionLabel = GUIGridLabel:new(13, 12, 3, 1, _"Dimension:", self.m_Window)

	self.m_NameValueLabel = GUIGridLabel:new(16, 8, 7, 1, _"", self.m_Window)
	self.m_ShortcutsValueLabel = GUIGridLabel:new(16, 8.5, 7, 1, _"", self.m_Window)
	self.m_CategoryValueLabel = GUIGridLabel:new(16, 9, 7, 1, _"", self.m_Window)
	self.m_PosXValueLabel = GUIGridLabel:new(16, 10, 7, 1, _"", self.m_Window)
	self.m_PosYValueLabel = GUIGridLabel:new(16, 10.5, 7, 1, _"", self.m_Window)
	self.m_PosZValueLabel = GUIGridLabel:new(16, 11, 7, 1, _"", self.m_Window)
	self.m_InteriorValueLabel = GUIGridLabel:new(16, 11.5, 7, 1, _"", self.m_Window)
	self.m_DimensionValueLabel = GUIGridLabel:new(16, 12, 7, 1, _"", self.m_Window)

    self.m_TeleportButton = GUIGridButton:new(17.5, 12.5, 4, 1, _"Teleportieren", self.m_Window)

	self.m_EditButton = GUIGridButton:new(1, 14, 4, 1, _"Bearbeiten", self.m_Window):setBackgroundColor(Color.Orange):setEnabled(false)
	self.m_EditButton.onLeftClick = function()
		local item = self.m_TeleportGridList:getSelectedItem()
		if (not item) then
			return ErrorBox:new(_"Wähle einen Teleportpunkt aus.")
		end
		local tpName = item.tpName
		AdminTeleportEditGUI:new(self.m_TeleportPoints, self.m_TeleportCategories, table.merge(self.m_TeleportPoints[tpName], {["name"] = tpName}))
	end

	-- self.m_CreateTeleportPointLabel = GUIGridLabel:new(6, 14, 5, 1, _"Neuen TP Punkt erstellen:", self.m_Window)
	-- self.m_CreateTeleportPointEdit = GUIGridEdit:new(11, 14, 5, 1, self.m_Window)
	self.m_CreateButton = GUIGridButton:new(7, 14, 4, 1, _"Erstellen", self.m_Window):setBackgroundColor(Color.Green):setEnabled(false)
	self.m_CreateButton.onLeftClick = function()
		AdminTeleportCreateGUI:new(self.m_TeleportPoints, self.m_TeleportCategories)
	end

	self.m_CategoryManageButton = GUIGridButton:new(18, 14, 4, 1, _"Kategorien verwalten", self.m_Window):setBackgroundColor(Color.Orange):setEnabled(false)
	self.m_CategoryManageButton.onLeftClick = function()
		AdminTeleportCategoryGUI:new(self.m_TeleportCategories)
	end

	if localPlayer:getRank() >= RANK.Administrator then
		self.m_EditButton:setEnabled(true)
		self.m_CreateButton:setEnabled(true)
	end
	if localPlayer:getRank() >= RANK.Developer then
		self.m_CategoryManageButton:setEnabled(true)
	end

	self:loadData(tp, cats)
end

function AdminTeleportGUI:loadData(tp, cats)
	local tpPoints, tpCats = tp, cats

	self.m_TeleportPoints = tp;
	self.m_TeleportCategories = cats;

	self.m_CategoryChanger:clear()
	local itemId = self.m_CategoryChanger:addItem("Keine")
	self.m_ChangerIdToCatId[itemId] = -1

	for id, name in pairs(tpCats) do 
		local itemId = self.m_CategoryChanger:addItem(name);
		self.m_ChangerIdToCatId[itemId] = id
	end

	self.m_TeleportGridList:clear()
	for i, v  in pairs(tpPoints) do
		self:addIeleportPointToGridlist(i, v, tpCats[v.category])
	end

	if (AdminTeleportCategoryGUI:isInstantiated()) then
		AdminTeleportCategoryGUI:getSingleton():loadData(cats)
	end
end

function AdminTeleportGUI:addIeleportPointToGridlist(name, data, catName)
	local v = data
	local shortCuts = table.concat(v.shortcuts, ", ");
	local item = self.m_TeleportGridList:addItem(_(name), string.short(shortCuts, 16), catName and _(catName) or "-")
	local pos = normaliseVector(v.pos)

	item.tpName = name
	item.onLeftClick = function()
		self.m_TeleportPointLocation:setMapPosition(pos.x, pos.y)
		self.m_TeleportPointLocation:addBlip("Marker.png", pos.x, pos.y)

		self.m_NameValueLabel:setText(_(name))
		self.m_ShortcutsValueLabel:setText(string.short(shortCuts, 30)):setTooltip(shortCuts)
		self.m_CategoryValueLabel:setText(catName and _(catName) or "-")
		self.m_PosXValueLabel:setText(math.round(pos.x, 0))
		self.m_PosYValueLabel:setText(math.round(pos.y, 0))
		self.m_PosZValueLabel:setText(math.round(pos.z, 0))
		self.m_InteriorValueLabel:setText(v.interior)
		self.m_DimensionValueLabel:setText(v.dimension)
		self.m_TeleportButton.onLeftClick = function()
			triggerServerEvent("adminTeleportPlayer", localPlayer, localPlayer, "tp", v.shortcuts[1])
		end
	end
end

addEventHandler("AdminTeleportGUI:Open", localPlayer, function(tp, cats) 
	if localPlayer:getRank() >= RANK.Clanmember then
		AdminTeleportGUI:new(tp, cats)
	end
end)

addEventHandler("AdminTeleportGUI:SendData", localPlayer, function(tp, cats)
	if (AdminTeleportGUI:isInstantiated()) then
		AdminTeleportGUI:getSingleton():loadData(tp, cats)
	end
end)




----------------- Create Teleport Point -------------------
AdminTeleportCreateGUI = inherit(GUIForm)
inherit(Singleton, AdminTeleportCreateGUI)

function AdminTeleportCreateGUI:constructor(tp, cats)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 15)
	self.m_Height = grid("y", 10)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Teleportpunkt erstellen", true, true, self)

	self.m_NameLabel = GUIGridLabel:new(1, 1, 3, 1, _"Name:", self.m_Window)
	self.m_NameEdit = GUIGridEdit:new(5, 1, 10, 1, self.m_Window)

	self.m_Shortcutsabel = GUIGridLabel:new(1, 2, 3, 1, _"Shortcuts:", self.m_Window)
	self.m_ShortcutsEdit = GUIGridEdit:new(5, 2, 10, 1, self.m_Window):setCaption("Shortcuts mit komma trennen (x,y,z)")
	

	self.m_CategoryLabel = GUIGridLabel:new(1, 3, 3, 1, _"Kategorie:", self.m_Window)
	self.m_CategoryChanger = GUIGridChanger:new(5, 3, 10, 1, self.m_Window)
	self.m_CategoryChanger:addItem(_"Keine")
	for i, v in pairs(cats) do
		self.m_CategoryChanger:addItem(_(v))
	end

	self.m_PosXLabel = GUIGridLabel:new(1, 4, 3, 1, _"PosX:", self.m_Window)
	self.m_PosXEdit = GUIGridEdit:new(5, 4, 10, 1, self.m_Window):setText(localPlayer.position.x):setNumeric(true, false)

	self.m_PosYLabel = GUIGridLabel:new(1, 5, 3, 1, _"PosY:", self.m_Window)
	self.m_PosYEdit = GUIGridEdit:new(5, 5, 10, 1, self.m_Window):setText(localPlayer.position.y):setNumeric(true, false)

	self.m_PosZLabel = GUIGridLabel:new(1, 6, 3, 1, _"PosZ:", self.m_Window)
	self.m_PosZEdit = GUIGridEdit:new(5, 6, 10, 1, self.m_Window):setText(localPlayer.position.z):setNumeric(true, false)

	self.m_InteriorLabel = GUIGridLabel:new(1, 7, 3, 1, _"Interior:", self.m_Window)
	self.m_InteriorEdit = GUIGridEdit:new(5, 7, 10, 1, self.m_Window):setText(localPlayer.interior):setNumeric(true, true)

	self.m_DimensionLabel = GUIGridLabel:new(1, 8, 3, 1, _"Dimension:", self.m_Window)
	self.m_DimensionEdit = GUIGridEdit:new(5, 8, 10, 1, self.m_Window):setText(localPlayer.dimension):setNumeric(true, true)

	self.m_CreateButton = GUIGridButton:new(1, 9, 6, 1, _"Erstellen", self.m_Window):setBackgroundColor(Color.Green)
	self.m_CreateButton.onLeftClick = function()
		if (self.m_NameEdit:getText().length == 0) then
			return;
		end

		if (not tp[self.m_NameEdit:getText()]) then
			triggerServerEvent("adminCreateTeleportPoint", localPlayer, self.m_NameEdit:getText(), 
				self.m_ShortcutsEdit:getText(),
				table.find(cats, self.m_CategoryChanger:getSelectedItem()) or -1,
				self.m_PosXEdit:getText(), 
				self.m_PosYEdit:getText(), 
				self.m_PosZEdit:getText(),
				self.m_InteriorEdit:getText(),
				self.m_DimensionEdit:getText()
			)
			self:delete();
		else
			ErrorBox:new(_"Name exisitiert bereits!")
		end
	end

	self.m_CancelButton = GUIGridButton:new(9, 9, 6, 1, _"Abbrechen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_CancelButton.onLeftClick = function()
		self:delete();
	end
end






----------------- Edit Teleport Point -------------------
AdminTeleportEditGUI = inherit(GUIForm)
inherit(Singleton, AdminTeleportEditGUI)

function AdminTeleportEditGUI:constructor(tp, cats, currentTp)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 15)
	self.m_Height = grid("y", 10)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Teleportpunkt bearbeiten", true, true, self)

	self.m_NameLabel = GUIGridLabel:new(1, 1, 3, 1, _"Name:", self.m_Window)
	self.m_NameEdit = GUIGridEdit:new(5, 1, 10, 1, self.m_Window):setText(currentTp.name)

	self.m_Shortcutsabel = GUIGridLabel:new(1, 2, 3, 1, _"Shortcuts:", self.m_Window)
	self.m_ShortcutsEdit = GUIGridEdit:new(5, 2, 10, 1, self.m_Window):setCaption("Shortcuts mit komma trennen (x,y,z)"):setText(table.concat(currentTp.shortcuts, ","))
	

	self.m_CategoryLabel = GUIGridLabel:new(1, 3, 3, 1, _"Kategorie:", self.m_Window)
	self.m_CategoryChanger = GUIGridChanger:new(5, 3, 10, 1, self.m_Window)
	self.m_CategoryChanger:addItem(_"Keine")
	for i, v in pairs(cats) do
		self.m_CategoryChanger:addItem(_(v))
	end
	self.m_CategoryChanger:setSelectedItem(cats[currentTp.category])

	self.m_PosXLabel = GUIGridLabel:new(1, 4, 3, 1, _"PosX:", self.m_Window)
	self.m_PosXEdit = GUIGridEdit:new(5, 4, 10, 1, self.m_Window):setText(currentTp.pos.x):setNumeric(true, false)

	self.m_PosYLabel = GUIGridLabel:new(1, 5, 3, 1, _"PosY:", self.m_Window)
	self.m_PosYEdit = GUIGridEdit:new(5, 5, 10, 1, self.m_Window):setText(currentTp.pos.y):setNumeric(true, false)

	self.m_PosZLabel = GUIGridLabel:new(1, 6, 3, 1, _"PosZ:", self.m_Window)
	self.m_PosZEdit = GUIGridEdit:new(5, 6, 10, 1, self.m_Window):setText(currentTp.pos.z):setNumeric(true, false)

	self.m_InteriorLabel = GUIGridLabel:new(1, 7, 3, 1, _"Interior:", self.m_Window)
	self.m_InteriorEdit = GUIGridEdit:new(5, 7, 10, 1, self.m_Window):setText(currentTp.interior):setNumeric(true, true)

	self.m_DimensionLabel = GUIGridLabel:new(1, 8, 3, 1, _"Dimension:", self.m_Window)
	self.m_DimensionEdit = GUIGridEdit:new(5, 8, 10, 1, self.m_Window):setText(currentTp.dimension):setNumeric(true, true)

	self.m_SaveButton = GUIGridButton:new(1, 9, 6, 1, _"Speichern", self.m_Window):setBackgroundColor(Color.Green)
	self.m_SaveButton.onLeftClick = function()
		if (tp[self.m_NameEdit:getText()] and self.m_NameEdit:getText() ~= currentTp.name) then
			return ErrorBox:new(_"Name exisitiert bereits!")
		end

		triggerServerEvent("adminEditTeleportPoint", localPlayer, currentTp.id, self.m_NameEdit:getText(), 
			self.m_ShortcutsEdit:getText(),
			table.find(cats, self.m_CategoryChanger:getSelectedItem()) or -1,
			self.m_PosXEdit:getText(), 
			self.m_PosYEdit:getText(), 
			self.m_PosZEdit:getText(),
			self.m_InteriorEdit:getText(),
			self.m_DimensionEdit:getText()
		)
		self:delete();
	end

	self.m_DeleteButton = GUIGridButton:new(9, 9, 6, 1, _"Löschen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_DeleteButton.onLeftClick = function()
		QuestionBox:new(_("Möchtest du den Teleportpunkt %s wirklich löschen?", currentTp.name), function()
			triggerServerEvent("adminDeleteTeleportPoint", localPlayer, currentTp.id)
			self:delete();
		end)
	end
end







----------------- Edit Teleport Point -------------------
AdminTeleportCategoryGUI = inherit(GUIForm)
inherit(Singleton, AdminTeleportCategoryGUI)

function AdminTeleportCategoryGUI:constructor(cats)

	GUIWindow.updateGrid()
	self.m_Width = grid("x", 10)
	self.m_Height = grid("y", 15)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Teleportieren", true, true, self)

	self.m_Categories = cats

	self.m_CategorieGrid = GUIGridGridList:new(1, 1, 9, 10, self.m_Window)
	self.m_CategorieGrid:addColumn(_"Id", 0.2)
	self.m_CategorieGrid:addColumn(_"Name", 0.8)
	for i, v in pairs(self.m_Categories) do
		local item = self.m_CategorieGrid:addItem(i, _(v))
		item.catName = v
		item.catId = i
	end


	self.m_ChangeNameButton = GUIGridButton:new(1, 11, 9, 1, _"Namen ändern", self.m_Window)
	self.m_ChangeNameButton.onLeftClick = function()
		local selectedItem = self.m_CategorieGrid:getSelectedItem()
		if (not selectedItem) then
			return ErrorBox:new(_"Wähle eine Kategorie aus.")
		end

		InputBox:new(_("%s umbennen", selectedItem.catName) ,_"Wie möchtest du die Kategorie nennen?", function(text)
				if (table.find(self.m_Categories, selectedItem.catName, true)) then
					return ErrorBox:new(_("Kategorie mit dem Namen existiert bereits."))
				end
				triggerServerEvent("adminEditTeleportCategory", localPlayer, selectedItem.catId, selectedItem.catName, text)
			end
		)
	end
	
	self.m_DeleteButton = GUIGridButton:new(1, 13, 9, 1, _"Löschen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_DeleteButton.onLeftClick = function()
		local selectedItem = self.m_CategorieGrid:getSelectedItem()
		if (not selectedItem) then
			return ErrorBox:new(_"Wähle eine Kategorie aus.")
		end
		QuestionBox:new(_("Möchtest du die Kategorie %s wirklich löschen?", selectedItem.catName), function()
				triggerServerEvent("adminDeleteTeleportCategory", localPlayer, selectedItem.catId)
			end
		)
	end
	self.m_CreateButton = GUIGridButton:new(1, 14, 9, 1, _"Erstellen", self.m_Window):setBackgroundColor(Color.Green)
	self.m_CreateButton.onLeftClick = function()
		InputBox:new(_("Kategorie erstellen") ,_"Wie soll die Kategorie heißen?", function(text)
			if (string.len(text) == 0) then
				return ErrorBox:new(_"Der Name darf nicht leer sein!")
			end
			triggerServerEvent("adminCreateTeleportCategory", localPlayer, text)
		end)
	end
end

function AdminTeleportCategoryGUI:loadData(cats)
	self.m_Categories = cats
	self.m_CategorieGrid:clear()

	for i, v in pairs(self.m_Categories) do
		local item = self.m_CategorieGrid:addItem(i, _(v))
		item.catName = v
		item.catId = i
	end
end