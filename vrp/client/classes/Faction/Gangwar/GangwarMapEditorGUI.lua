GangwarMapEditorGUI = inherit(GUIForm)
inherit(Singleton, GangwarMapEditorGUI)
addRemoteEvents{"GangwarMapEditor:receiveData"}

function GangwarMapEditorGUI:constructor()
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 23)
	self.m_Height = grid("y", 11)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Gangwar-Map-Editor", true, true, self)

	self.m_InfoLabel = GUIGridLabel:new(1, 1, 22, 1, "", self.m_Window)

	self.m_AreaList = GUIGridGridList:new(1, 2, 10, 8, self.m_Window)
	self.m_AreaList:addColumn(_"Gebiet", 0.4)
	self.m_AreaList:addColumn(_"Objekte", 0.2)
	self.m_AreaList:addColumn(_"Bearbeiter", 0.4)

	self.m_EditButton = GUIGridButton:new(1, 10, 5, 1, _"Map bearbeiten", self.m_Window):setBackgroundColor(Color.Green)
	self.m_EditButton.onLeftClick = function()
		local item = self.m_AreaList:getSelectedItem()
		if not item or not item.m_AreaId then
			ErrorBox:new(_"Kein Gebiet ausgewählt!")
			return
		end
		triggerServerEvent("GangwarMapEditor:editArea", localPlayer, item.m_AreaId)
		delete(self)
	end

	self.m_LeaveButton = GUIGridButton:new(6, 10, 5, 1, _"Editor verlassen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_LeaveButton.onLeftClick = function()
		triggerServerEvent("MapEditor:forceCloseEditor", localPlayer)
		delete(self)
	end

	self.m_ObjectGrid = GUIGridGridList:new(12, 2, 11, 6, self.m_Window)
	self.m_ObjectGrid:addColumn(_"ID", 0.15)
	self.m_ObjectGrid:addColumn(_"Name", 0.5)
	self.m_ObjectGrid:addColumn(_"Ersteller", 0.35)

	self.m_EditObjectButton = GUIGridButton:new(12, 8, 5, 1, _"Bearbeiten", self.m_Window):setBackgroundColor(Color.Green)
	self.m_EditObjectButton.onLeftClick = function()
		local object = self:getSelectedObject()
		if object then
			MapEditor:getSingleton():selectObject(object, "ObjectSetter")
		end
	end

	self.m_DeleteObjectButton = GUIGridButton:new(18, 8, 5, 1, _"Löschen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_DeleteObjectButton.onLeftClick = function()
		local object = self:getSelectedObject()
		if object then
			triggerServerEvent("MapEditor:removeObject", object)
			MapEditor:getSingleton():abortPlacing()
			self:requestObjects()
		end
	end

	self.m_BoundingBoxButton = GUIGridButton:new(12, 9, 5, 1, _"Rahmen für alle", self.m_Window):setBackgroundColor(Color.Orange)
	self.m_BoundingBoxButton.onLeftClick = function()
		local state = not MapEditor:getSingleton():areAllBoundingBoxesEnabled()
		MapEditor:getSingleton():setAllBoundingBoxesEnabled(state)
		InfoBox:new(_("Der Begrenzungsrahmen ist nun für alle Objekte der Map %s!", state and _"aktiviert" or _"deaktiviert"))
	end

	self.m_ShowAllButton = GUIGridButton:new(18, 9, 5, 1, _"Alle auf Karte", self.m_Window):setBackgroundColor(Color.Orange)
	self.m_ShowAllButton.onLeftClick = function()
		self:removeMarks()
		for key, data in ipairs(self.m_ObjectTable or {}) do
			self:markObject(data[1])
		end
	end

	self.m_RefreshButton = GUIGridButton:new(12, 10, 11, 1, _"Objekte aktualisieren", self.m_Window)
	self.m_RefreshButton.onLeftClick = function()
		self:requestObjects()
	end

	self.m_Blips = {}
	self.m_RemoveMarksBind = bind(self.removeMarks, self)
	self.m_ObjectReceiveBind = bind(self.receiveObjects, self)
	addEventHandler("MapEditorMapGUI:sendObjectsToClient", root, self.m_ObjectReceiveBind)
end

function GangwarMapEditorGUI:destructor()
	removeEventHandler("MapEditorMapGUI:sendObjectsToClient", root, self.m_ObjectReceiveBind)
	self:removeMarks()
	if MapEditor:isInstantiated() then
		MapEditor:getSingleton():selectObject()
	end
	GUIForm.destructor(self)
end

function GangwarMapEditorGUI:setData(areas, currentAreaId, currentMapId)
	local selected = self.m_AreaList:getSelectedItem()
	local selectedId = selected and selected.m_AreaId or currentAreaId
	self.m_AreaList:clear()

	local currentName
	for key, area in ipairs(areas) do
		local item = self.m_AreaList:addItem(area.name, area.hasMap and tostring(area.objects) or _"Keine Map", area.editors)
		item.m_AreaId = area.id
		if area.id == currentAreaId then
			currentName = area.name
			item:setColumnColor(1, Color.Accent)
		end
		if area.attacked then
			item:setColumnColor(3, Color.Orange)
		end
		if area.id == selectedId then
			self.m_AreaList:onInternalSelectItem(item)
		end
	end

	self.m_InfoLabel:setText(currentName and _("Du bearbeitest gerade: %s", currentName) or _"Wähle ein Gebiet, um dessen Map zu bearbeiten.")
	self.m_LeaveButton:setEnabled(currentAreaId ~= nil)

	self.m_CurrentMapId = currentMapId
	self:requestObjects()
end

function GangwarMapEditorGUI:requestObjects()
	self.m_ObjectGrid:clear()
	self.m_ObjectTable = {}
	if self.m_CurrentMapId then
		triggerServerEvent("MapEditor:requestObjectInfos", localPlayer, self.m_CurrentMapId)
	end
end

function GangwarMapEditorGUI:receiveObjects(objectTable)
	self.m_ObjectGrid:clear()
	self.m_ObjectTable = objectTable
	for key, data in ipairs(objectTable) do
		local object = data[1]
		if isElement(object) then
			local model = object:getModel()
			local item = self.m_ObjectGrid:addItem(key, MapEditor:getSingleton():getWorldModelName(model) or model, data[2] or "-")
			item.m_Object = object
			item.onLeftClick = function()
				nextframe(function()
					if isElement(object) then
						MapEditor:getSingleton():selectObject(object, "normal")
					end
				end)
			end
		end
	end
end

function GangwarMapEditorGUI:getSelectedObject()
	local item = self.m_ObjectGrid:getSelectedItem()
	if not item or not isElement(item.m_Object) then
		ErrorBox:new(_"Kein Objekt ausgewählt!")
		return
	end
	return item.m_Object
end

function GangwarMapEditorGUI:markObject(object)
	if not isElement(object) then
		return
	end
	local x, y = getElementPosition(object)
	self.m_Blips[#self.m_Blips+1] = Blip:new("Marker.png", x, y, 3000, {255, 255, 0}, {255, 255, 0})

	if isTimer(self.m_RemoveMarksTimer) then killTimer(self.m_RemoveMarksTimer) end
	self.m_RemoveMarksTimer = setTimer(self.m_RemoveMarksBind, 10000, 1)
end

function GangwarMapEditorGUI:removeMarks()
	if isTimer(self.m_RemoveMarksTimer) then killTimer(self.m_RemoveMarksTimer) end
	for key, blip in pairs(self.m_Blips) do
		delete(blip)
	end
	self.m_Blips = {}
end

addEventHandler("GangwarMapEditor:receiveData", root,
	function(areas, currentAreaId, open, currentMapId)
		if not GangwarMapEditorGUI:isInstantiated() then
			if not open then return end
			GangwarMapEditorGUI:new()
		end
		GangwarMapEditorGUI:getSingleton():setData(areas, currentAreaId, currentMapId)
	end
)
