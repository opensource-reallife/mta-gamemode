-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/MapEditor/MapEditorMapGUI.lua
-- *  PURPOSE:     Map Editor Map GUI class
-- *
-- ****************************************************************************

MapEditorMapGUI = inherit(GUIForm)
inherit(Singleton, MapEditorMapGUI)
addRemoteEvents{"MapEditorMapGUI:sendInfos", "MapEditorMapGUI:sendObjectsToClient"}

function MapEditorMapGUI:constructor()
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 22)
	self.m_Height = grid("y", 14)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, false)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Map Editor: Map Verwaltung", true, true, self)
	
	self.m_FilterLabel = GUIGridLabel:new(1, 1, 3, 1, _"Filter:", self.m_Window)
	self.m_FilterCombobox = GUIGridCombobox:new(4, 1, 7, 1, "Kategorie auswählen", self.m_Window)
	self.m_FilterCombobox.onLeftClick = function() self.m_GridList:setVisible(not self.m_GridList:isVisible()) end
    self.m_FilterCombobox.onSelectItem = bind(self.onFilterComboboxSelectItem, self)

	self.m_GridList = GUIGridGridList:new(1, 2, 10, 10, self.m_Window)
	self.m_GridList:addColumn("ID", 0.1)
	self.m_GridList:addColumn("Name", 0.3)
	self.m_GridList:addColumn("Status", 0.25)
	self.m_GridList:addColumn("Kategorie", 0.35)
	
	self.m_EditMap = GUIGridButton:new(1, 12, 5, 1, "Bearbeiten", self.m_Window)
	self.m_MapStatus = GUIGridButton:new(6, 12, 5, 1, "Deaktivieren", self.m_Window)

	self.m_EditingPlayers = GUIGridButton:new(1, 13, 10, 1, "Derzeit bearbeitende Spieler", self.m_Window)
	
	self.m_Headline = GUIGridLabel:new(11, 1, 11, 1, "Informationen zu Map", self.m_Window):setHeader()

	self.m_EditMapSettings = GUIGridButton:new(18, 1, 4, 1, "Map Einstellungen", self.m_Window)
	
	self.m_NameLabel = GUIGridLabel:new(11, 2, 11, 1, "Name: -", self.m_Window)
	self.m_CreatorLabel = GUIGridLabel:new(11, 3, 11, 1, "Ersteller: -", self.m_Window)
	self.m_ObjectGrid = GUIGridGridList:new(11, 4, 11, 5, self.m_Window)
	
	self.m_ObjectGrid:addColumn("Typ", 0.1)
	self.m_ObjectGrid:addColumn("ID", 0.1)
	self.m_ObjectGrid:addColumn("Name", 0.45)
	self.m_ObjectGrid:addColumn("Ersteller", 0.35)

	self.m_EditObject = GUIGridButton:new(11, 9, 5, 1, "Bearbeiten", self.m_Window):setBackgroundColor(Color.Green)
	self.m_DeleteObject = GUIGridButton:new(17, 9, 5, 1, "Löschen", self.m_Window):setBackgroundColor(Color.Red)
	
	self.m_ShowBoundingBox = GUIGridButton:new(11, 10, 5, 1, "Rahmen für Alle anzeigen", self.m_Window):setBackgroundColor(Color.Orange)
	self.m_ShowAllObjects = GUIGridButton:new(17, 10, 5, 1, "Alle auf Karte anzeigen", self.m_Window):setBackgroundColor(Color.Orange)
	
	self.m_CreateNewLabel = GUIGridLabel:new(11, 11, 5, 1, "Generell", self.m_Window):setHeader()
	self.m_NewNameLabel = GUIGridEdit:new(11, 12, 6, 1, self.m_Window):setCaption("Name"):setMaxLength(30)
	self.m_CreateNewButton = GUIGridButton:new(17, 12, 5, 1, "Map anlegen", self.m_Window):setBackgroundColor(Color.Green)
	self.m_NewCategoryNameLabel = GUIGridEdit:new(11, 13, 6, 1, self.m_Window):setCaption("Name"):setMaxLength(30)
	self.m_CreateNewCategoryButton = GUIGridButton:new(17, 13, 5, 1, "Kategorie anlegen", self.m_Window):setBackgroundColor(Color.Green)

	
	self.m_EditMap.onLeftClick = function()
		if localPlayer:getRank() >= ADMIN_RANK_PERMISSION["openMapEditor"] then
			self:startMapEditing(localPlayer)
		else
			ErrorBox:new("Du bist nicht berechtigt!")
		end
	end

	self.m_EditMap.onRightClick = function()
		if localPlayer:getRank() >= ADMIN_RANK_PERMISSION["remoteOpenMapEditor"] then
			InviteGUI:new(
				function(player)
					self:startMapEditing(player)
				end, "mapeditor"
			)
		else
			ErrorBox:new("Du bist nicht berechtigt!")
		end
	end

	self.m_MapStatus.onLeftClick = function()
		if not self.m_GridList:getSelectedItem() then
			ErrorBox:new("Keine Map ausgewählt!")
			return
		end
		local id = tonumber(self.m_GridList:getSelectedItem():getColumnText(1))
		triggerServerEvent("MapEditor:setMapStatus", localPlayer, id)
	end

	self.m_EditingPlayers.onLeftClick = function()
		if localPlayer:getRank() < ADMIN_RANK_PERMISSION["openMapEditor"] then
			ErrorBox:new("Du bist nicht berechtigt!")
			return
		end
		self:close()
		MapEditorEditingPlayersGUI:new()
	end

	self.m_EditMapSettings.onLeftClick = function()
		if localPlayer:getRank() < ADMIN_RANK_PERMISSION["setMapStatus"] then
			ErrorBox:new("Du bist nicht berechtigt!")
			return
		end
		if not self.m_GridList:getSelectedItem() then
			ErrorBox:new("Keine Map ausgewählt!")
			return
		end
		local id = tonumber(self.m_GridList:getSelectedItem():getColumnText(1))
		MapEditorMapSettingsGUI:new(id, self.m_MapInfos[id])
	end

	self.m_ShowBoundingBox.onLeftClick = function()
		local state = not MapEditor:getSingleton():areAllBoundingBoxesEnabled()
		MapEditor:getSingleton():setAllBoundingBoxesEnabled(state)
		InfoBox:new(("Der Begrenzungsrahmen ist nun für alle Objekte der Map %s!"):format(state and "aktiviert" or "deaktiviert"))
	end

	self.m_ShowAllObjects.onLeftClick = function()
		self:removeMarks()
		for key, data in ipairs(self.m_ObjectTable) do
			self:markObject(data[1])
		end
	end

	self.m_CreateNewButton.onLeftClick = function()
		if #self.m_NewNameLabel:getText() < 5 then
			ErrorBox:new("Bitte gib der Map einen vernünftigen Namen!")
			return
		end
		triggerServerEvent("MapEditor:createNewMap", localPlayer, self.m_NewNameLabel:getText())
	end

	self.m_CreateNewCategoryButton.onLeftClick = function()
		triggerServerEvent("MapEditor:createNewCategory", localPlayer, self.m_NewCategoryNameLabel:getText())
	end

	self.m_EditObject.onLeftClick = function()
		if self.m_ObjectGrid:getSelectedItem() then
			MapEditor:getSingleton():selectObject(self.m_ObjectTable[self.m_ObjectGrid:getSelectedItem():getColumnText(2)][1], "ObjectSetter")
		end
	end

	self.m_DeleteObject.onLeftClick = function()
		if self.m_ObjectGrid:getSelectedItem() and self.m_ObjectGrid:getSelectedItem():getColumnText(1) == FontAwesomeSymbols.Plus then
			triggerServerEvent("MapEditor:removeObject", self.m_ObjectTable[self.m_ObjectGrid:getSelectedItem():getColumnText(2)][1])
			MapEditor:getSingleton():abortPlacing()
			self.m_ObjectGrid:clear()
			triggerServerEvent("MapEditor:requestObjectInfos", localPlayer, tonumber(self.m_GridList:getSelectedItem():getColumnText(1)))
		else
			triggerServerEvent("MapEditor:restoreWorldModel", localPlayer, tonumber(self.m_GridList:getSelectedItem():getColumnText(1)), tonumber(self.m_ObjectGrid:getSelectedItem():getColumnText(2)))
			self.m_ObjectGrid:clear()
			MapEditor:getSingleton():selectObject()
			triggerServerEvent("MapEditor:requestObjectInfos", localPlayer, tonumber(self.m_GridList:getSelectedItem():getColumnText(1)))
		end
	end

	self.m_Blips = {}
    
    self.m_ReceiveBind = bind(self.receiveInfos, self)
	addEventHandler("MapEditorMapGUI:sendInfos", root, self.m_ReceiveBind)
	
	self.m_ObjectReceiveBind = bind(self.receiveObjectInfos, self)
	addEventHandler("MapEditorMapGUI:sendObjectsToClient", root, self.m_ObjectReceiveBind)

	self.m_RemoveMarksBind = bind(self.removeMarks, self)

	triggerServerEvent("MapEditor:requestMapInfos", localPlayer)
end

function MapEditorMapGUI:destructor()
    GUIForm.destructor(self)
	removeEventHandler("MapEditorMapGUI:sendInfos", root, self.m_ReceiveBind)
	MapEditor:getSingleton():selectObject()
end

function MapEditorMapGUI:receiveInfos(mapTable, categories)
	self.m_GridList:clear()
	self.m_MapInfos = mapTable
	for key, infoTable in pairs(mapTable) do
		local item = self.m_GridList:addItem(key, string.short(infoTable[1], 13), infoTable[3] == 1 and "aktiviert" or "deaktiviert", MapEditor:getSingleton():getCategorieNameFromId(infoTable[6]) or "Keine")
		item.category = infoTable[6]
		item.onLeftClick = function()
			self.m_ObjectGrid:clear()
			self.m_Headline:setText(("Informationen zu Map #%s"):format(key))
			self.m_NameLabel:setText(("Name: %s"):format(infoTable[1]))
			self.m_CreatorLabel:setText(("Ersteller: %s"):format(infoTable[2]))
			self.m_MapStatus:setText(infoTable[3] == 1 and "Deaktivieren" or "Aktivieren")
			self.m_MapStatus:setBackgroundColor(infoTable[3] == 1 and Color.Red or Color.Green)
			triggerServerEvent("MapEditor:requestObjectInfos", localPlayer, key)
		end

	end

	self.m_FilterCombobox:clear()
	self.m_FilterCombobox:addItem("Alle")
	self.m_FilterCombobox:addItem("Ohne Kategorie")
	for i, v in pairs(MapEditor:getSingleton():getAllCategories()) do
		self.m_FilterCombobox:addItem(v)
	end
	self.m_FilterCombobox:setSelectedItem(1)
end

function MapEditorMapGUI:receiveObjectInfos(objectTable, removalsTable)
	self.m_ObjectTable = objectTable
	local objects = MapEditor:getSingleton():getObjectXML()
    
	for key, data in ipairs(objectTable) do
		local objectModel = data[1]:getModel()

		local item = self.m_ObjectGrid:addItem(FontAwesomeSymbols.Plus, key, objectModel, data[2])
		item:setColumnFont(1, FontAwesome(20), 1)
		item.onLeftClick = function()
			nextframe(function() MapEditor:getSingleton():selectObject(self.m_ObjectTable[self.m_ObjectGrid:getSelectedItem():getColumnText(2)][1], "normal") end)
		end
		local objectName = MapEditor:getSingleton():getWorldModelName(objectModel) or "-none-"
		item:setColumnText(3, objectName)
	end
	for key, data in pairs(removalsTable) do
		local objectModel = data.worldModelId
		local item = self.m_ObjectGrid:addItem(FontAwesomeSymbols.Erase, key, objectModel, data.creator)
		item:setColumnFont(1, FontAwesome(20), 1)
		item.onLeftClick = function()
			nextframe(function() MapEditor:getSingleton():selectObject(data) end)
		end
		local objectName = MapEditor:getSingleton():getWorldModelName(objectModel) or "-none- [Low LOD]"
		item:setColumnText(3, objectName)
	end
end

function MapEditorMapGUI:markObject(object)
	if not isElement(object) then
		return
	end

	local x, y = getElementPosition(object)
	self.m_Blips[#self.m_Blips+1] = Blip:new("Marker.png", x, y, 3000, {255, 255, 0}, {255, 255, 0})

	if isTimer(self.m_RemoveMarksTimer) then killTimer(self.m_RemoveMarksTimer) end
	self.m_RemoveMarksTimer = setTimer(self.m_RemoveMarksBind, 10000, 1)
end

function MapEditorMapGUI:removeMarks()
	if isTimer(self.m_RemoveMarksTimer) then killTimer(self.m_RemoveMarksTimer) end
	for k, v in pairs(self.m_Blips) do 
		delete(v)
	end
	self.m_Blips = {}
end

function MapEditorMapGUI:startMapEditing(player)
	if not self.m_GridList:getSelectedItem() then
		ErrorBox:new("Keine Map ausgewählt!")
		return
	end
	local id = tonumber(self.m_GridList:getSelectedItem():getColumnText(1))
	triggerServerEvent("MapEditor:startMapEditing", localPlayer, player, id)
end

function MapEditorMapGUI:onFilterComboboxSelectItem(item)
	local index = table.find(self.m_FilterCombobox.m_List:getItems(), item)
	self.m_GridList:setVisible(true)
	self.m_GridList:clear()
	for key, infoTable in pairs(self.m_MapInfos) do
		if index == 1 or (index == 2 and infoTable[6] == 0) or infoTable[6] == index - 2 then
			local item = self.m_GridList:addItem(key, string.short(infoTable[1], 13), infoTable[3] == 1 and "aktiviert" or "deaktiviert", MapEditor:getSingleton():getCategorieNameFromId(infoTable[6]) or "Keine")

			item.onLeftClick = function()
				self.m_ObjectGrid:clear()
				self.m_Headline:setText(("Informationen zu Map #%s"):format(key))
				self.m_NameLabel:setText(("Name: %s"):format(infoTable[1]))
				self.m_CreatorLabel:setText(("Ersteller: %s"):format(infoTable[2]))
				self.m_MapStatus:setText(infoTable[3] == 1 and "Deaktivieren" or "Aktivieren")
				self.m_MapStatus:setBackgroundColor(infoTable[3] == 1 and Color.Red or Color.Green)
				triggerServerEvent("MapEditor:requestObjectInfos", localPlayer, key)
			end
		end
	end
	
	--[[for i, item in pairs(self.m_GridList:getItems()) do
		if index ~= 1 and item.category ~= index - 1 then
			item:setVisible(false)
		else
			item:setVisible(true)
		end
	end]]
end