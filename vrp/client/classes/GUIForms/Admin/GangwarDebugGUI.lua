-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/GangwarDebugGUI.lua
-- *  PURPOSE:     Gangwar Debug GUI class
-- *
-- ****************************************************************************
GangwarDebugGUI = inherit(GUIForm)
addRemoteEvents{"gangwarAdminData", "gangwarRefresh"}

function GangwarDebugGUI:constructor(gui)
	GUIWindow.updateGrid(true)
	self.m_Width = grid("x", 24)
	self.m_Height = grid("y", 13)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Gangwar-Menü", true, true, self)
	if gui then
		self.m_Window:addBackButton(function() delete(self) gui:getSingleton():show() end)
	end

	self.m_Tabs, self.m_TabPanel = self.m_Window:addTabPanel({_"Gebiete", _"Attacks", _"Fahrzeuge", _"Fraktionen"})
	self.m_TabPanel:updateGrid()
	self:createAreaTab(self.m_Tabs[1])
	self:createAttackTab(self.m_Tabs[2])
	self:createVehicleTab(self.m_Tabs[3])
	self:createFactionTab(self.m_Tabs[4])

	self.m_DataBind = bind(self.Event_data, self)
	self.m_RefreshBind = bind(self.Event_refresh, self)
	addEventHandler("gangwarAdminData", root, self.m_DataBind)
	addEventHandler("gangwarRefresh", root, self.m_RefreshBind)
	self:Event_refresh()
end

function GangwarDebugGUI:destructor()
	removeEventHandler("gangwarAdminData", root, self.m_DataBind)
	removeEventHandler("gangwarRefresh", root, self.m_RefreshBind)
	GUIForm.destructor(self)
end

function GangwarDebugGUI:addSection(x, y, text, parent)
	GUIGridLabel:new(x, y, 10, 1, text, parent):setColor(Color.Accent)
end

function GangwarDebugGUI:addAction(x, y, symbol, text, parent, callback)
	local button = GUIGridIconButton:new(x, y, symbol, parent)
	button.onLeftClick = callback
	GUIGridLabel:new(x + 1, y, 4, 1, text, parent)
	return button
end

function GangwarDebugGUI:addAreaAction(x, y, symbol, text, callback)
	return self:addAction(x, y, symbol, text, self.m_Tabs[1], function()
		local item = self.m_AreaList:getSelectedItem()
		if not item then
			ErrorBox:new(_"Bitte wähle ein Gebiet aus!")
			return
		end
		callback(item.m_Area)
	end)
end

function GangwarDebugGUI:addEditAction(x, y, symbol, text, field)
	return self:addAreaAction(x, y, symbol, text, function(area)
		QuestionBox:new(_("%s für das Gebiet %s wirklich ausführen?", text, area.name), function()
			triggerServerEvent("adminGangwarEditArea", localPlayer, area.id, field)
		end)
	end)
end

function GangwarDebugGUI:createAreaTab(tab)
	self.m_AreaList = GUIGridGridList:new(1, 1, 12, 7, tab)
	self.m_AreaList:addColumn(_"Gebiet", 0.45)
	self.m_AreaList:addColumn(_"Besitzer", 0.25)
	self.m_AreaList:addColumn(_"Status", 0.3)
	self.m_AreaList:setSortable({_"Gebiet", _"Besitzer", _"Status"})
	self.m_AreaMap = GUIGridMiniMap:new(1, 8, 12, 5, tab)

	self.m_Info = GUIGridLabel:new(14, 1, 10, 2, _"Wähle links ein Gebiet aus.", tab)

	self:addSection(14, 3, _"Gebiet", tab)
	self:addAction(14, 4, FontAwesomeSymbols.Plus, _"Neues Gebiet", tab, function()
		InputBox:new(_"Neues Gebiet", _"Name des Gebiets (entsteht an deiner Position):", function(name)
			triggerServerEvent("adminGangwarCreateArea", localPlayer, name)
		end)
	end)
	self:addAreaAction(19, 4, FontAwesomeSymbols.Pencil, _"Name ändern", function(area)
		InputBox:new(_"Name ändern", _"Neuer Name:", function(name)
			triggerServerEvent("adminGangwarEditArea", localPlayer, area.id, "name", name)
		end)
	end)
	self:addEditAction(14, 5, FontAwesomeSymbols.Check, _"Aktiv an/aus", "active")

	self:addSection(14, 6, _"Position (an deiner Stelle)", tab)
	self:addEditAction(14, 7, FontAwesomeSymbols.Location_Dot, _"Flagge setzen", "flag")
	self:addEditAction(14, 8, FontAwesomeSymbols.Crosshair, _"Ecke 1 setzen", "corner1")
	self:addEditAction(19, 8, FontAwesomeSymbols.Crosshair, _"Ecke 2 setzen", "corner2")

	self:addSection(14, 9, _"Verwaltung", tab)
	self:addAreaAction(14, 10, FontAwesomeSymbols.Group, _"Besitzer setzen", function(area)
		ChangerBox:new(_"Fraktion für das Gebiet", _"Bitte wähle die gewünschte Fraktion aus:", FactionManager:getSingleton():getFactionNames(), function(factionId)
			triggerServerEvent("adminGangwarSetAreaOwner", localPlayer, area.id, factionId)
		end)
	end)
	self:addAreaAction(19, 10, FontAwesomeSymbols.Unlock, _"Freigeben", function(area)
		InputBox:new(_"Freigeben", _"In wie vielen Stunden? (0 = sofort)", function(hours)
			hours = tonumber(hours) or 0
			triggerServerEvent("adminGangwarResetArea", localPlayer, area.id, hours > 0 and getRealTime().timestamp + hours*3600 or 0)
		end, true)
	end)
	self:addAreaAction(14, 11, FontAwesomeSymbols.Car, _"Burritos an Flagge", function(area)
		InputBox:new(_"Burritos an der Flagge", _"Anzahl der Burritos an der Flagge:", function(amount)
			triggerServerEvent("adminGangwarEditArea", localPlayer, area.id, "cars", amount)
		end, true)
	end)
end

function GangwarDebugGUI:createAttackTab(tab)
	self.m_AttackList = GUIGridGridList:new(1, 1, 23, 11, tab)
	self.m_AttackList:addColumn(_"Status", 0.14)
	self.m_AttackList:addColumn(_"Gebiet", 0.26)
	self.m_AttackList:addColumn(_"Angreifer", 0.2)
	self.m_AttackList:addColumn(_"Verteidiger", 0.2)
	self.m_AttackList:addColumn(_"Sieger", 0.2)

	self.m_RefreshButton = GUIGridIconButton:new(1, 12, FontAwesomeSymbols.Refresh, tab)
	self.m_RefreshButton.onLeftClick = bind(self.Event_refresh, self)
	self.m_InvalidButton = GUIGridButton:new(19, 12, 5, 1, _"Ungültig erklären", tab):setBackgroundColor(Color.Red)
	self.m_InvalidButton.onLeftClick = bind(self.onInvalidClick, self)
end

function GangwarDebugGUI:createVehicleTab(tab)
	self.m_BanScope = 0
	self.m_ScopeList = GUIGridGridList:new(1, 1, 9, 12, tab)
	self.m_ScopeList:addColumn(_"Gilt für", 1)

	self.m_BanList = GUIGridGridList:new(11, 1, 13, 11, tab)
	self.m_BanList:addColumn(_"Fahrzeug", 0.6)
	self.m_BanList:addColumn(_"Status", 0.4)

	self.m_BanButton = GUIGridButton:new(19, 12, 5, 1, _"Sperren / Erlauben", tab)
	self.m_BanButton.onLeftClick = function()
		local item = self.m_BanList:getSelectedItem()
		if not item then
			ErrorBox:new(_"Bitte wähle ein Fahrzeug aus!")
			return
		end
		self:toggleBan(item.m_Model)
	end
end

function GangwarDebugGUI:toggleBan(model)
	triggerServerEvent("adminGangwarToggleBan", localPlayer, self.m_BanScope, model)
end

function GangwarDebugGUI:addScopeItem(text, scope)
	local item = self.m_ScopeList:addItem(text)
	item.onLeftClick = function()
		self.m_BanScope = scope
		self:refreshBanList()
	end
	if scope == self.m_BanScope then
		self.m_ScopeList:onInternalSelectItem(item)
	end
end

function GangwarDebugGUI:refreshBanScopes()
	self.m_ScopeList:clear()
	self:addScopeItem(_"Alle Gebiete", 0)
	for key, area in ipairs(self.m_BanAreas) do
		self:addScopeItem(area.name, area.id)
	end
end

function GangwarDebugGUI:refreshBanList()
	local global, local_ = {}, {}
	for key, model in ipairs(self.m_GlobalBans) do
		global[model] = true
	end
	for key, area in ipairs(self.m_BanAreas) do
		if area.id == self.m_BanScope then
			for bannedKey, model in ipairs(area.banned) do
				local_[model] = true
			end
		end
	end

	self.m_BanList:clear()
	for key, vehicle in ipairs(self.m_BanVehicles) do
		local status = _"Erlaubt"
		if global[vehicle.model] then
			status = _"Überall gesperrt"
		elseif local_[vehicle.model] then
			status = _"Hier gesperrt"
		end
		local item = self.m_BanList:addItem(vehicle.name, status)
		item.m_Model = vehicle.model
		item.onLeftDoubleClick = function() self:toggleBan(vehicle.model) end
		if global[vehicle.model] or local_[vehicle.model] then
			item:setColumnColor(2, Color.Red)
		end
	end
end

function GangwarDebugGUI:createFactionTab(tab)
	self.m_FactionList = GUIGridGridList:new(1, 1, 14, 12, tab)
	self.m_FactionList:addColumn(_"Fraktion", 0.4)
	self.m_FactionList:addColumn(_"Gangwar-Spawn", 0.6)

	self:addSection(16, 1, _"An deiner Position setzen", tab)
	self:addFactionAction(16, 2, FontAwesomeSymbols.Location_Dot, _"Gangwar-NPC", "adminGangwarSetNpc", tab)
	self:addFactionAction(16, 3, FontAwesomeSymbols.Home, _"Gangwar-Spawn", "adminGangwarSetSpawn", tab)
end

function GangwarDebugGUI:addFactionAction(x, y, symbol, text, event, tab)
	return self:addAction(x, y, symbol, text, tab, function()
		local item = self.m_FactionList:getSelectedItem()
		if not item then
			ErrorBox:new(_"Bitte wähle eine Fraktion aus!")
			return
		end
		QuestionBox:new(_("%s der Fraktion %s wirklich an deine Position setzen?", text, item.m_FactionName), function()
			triggerServerEvent(event, localPlayer, item.m_FactionId)
		end)
	end)
end

function GangwarDebugGUI:Event_refresh()
	triggerServerEvent("adminGangwarGetData", localPlayer)
end

function GangwarDebugGUI:selectArea(area)
	local nextAttack = area.lastAttack + GANGWAR_ATTACK_PAUSE*UNIX_TIMESTAMP_24HRS
	self.m_Info:setText(_("%s: Burritos an der Flagge: %d\nAttackierbar ab: %s", area.name, area.cars, getOpticalTimestamp(nextAttack)))
	self.m_AreaMap.m_Blips = {}
	self.m_AreaMap:setMapPosition(area.x, area.y)
	self.m_AreaMap:addBlip("Marker.png", area.x, area.y)
end

function GangwarDebugGUI:Event_data(areas, running, finished, factions, vehicles, globalBans)
	self.m_BanAreas, self.m_BanVehicles, self.m_GlobalBans = areas, vehicles, globalBans
	self:refreshBanScopes()
	self:refreshBanList()

	local selected = self.m_AreaList:getSelectedItem()
	local selectedId = selected and selected.m_Area.id
	self.m_AreaList:clear()
	for key, area in ipairs(areas) do
		local status = area.attacked and _"Attackiert" or (area.active and _"Aktiv" or _"Inaktiv")
		local item = self.m_AreaList:addItem(area.name, area.owner, status)
		item.m_Area = area
		item.onLeftClick = function() self:selectArea(area) end
		if area.id == selectedId then
			self.m_AreaList:onInternalSelectItem(item)
			self:selectArea(area)
		end
	end

	self.m_AttackList:clear()
	for key, attack in ipairs(running) do
		local item = self.m_AttackList:addItem(attack.phase == "prepare" and _"Aufbau" or _"Attack", attack.area, attack.attacker, attack.defender, "-")
		item.m_Kind, item.m_Id = "running", attack.slot
	end
	for key, attack in ipairs(finished) do
		local item = self.m_AttackList:addItem(attack.invalid and _"Ungültig" or _"Beendet", attack.area, attack.attacker, attack.defender, attack.winner)
		item.m_Kind, item.m_Id = "finished", attack.index
	end

	local selectedFaction = self.m_FactionList:getSelectedItem()
	local selectedFactionId = selectedFaction and selectedFaction.m_FactionId
	self.m_FactionList:clear()
	for key, faction in ipairs(factions) do
		local item = self.m_FactionList:addItem(faction.name, faction.hasSpawn and _"Eigener Punkt" or _"Navigationspunkt")
		item.m_FactionId = faction.id
		item.m_FactionName = faction.name
		if faction.id == selectedFactionId then
			self.m_FactionList:onInternalSelectItem(item)
		end
	end
end

function GangwarDebugGUI:onInvalidClick()
	local item = self.m_AttackList:getSelectedItem()
	if not item then
		ErrorBox:new(_"Bitte wähle einen Attack aus!")
		return
	end
	QuestionBox:new(_"Diesen Attack wirklich für ungültig erklären?", function()
		triggerServerEvent("adminGangwarInvalidate", localPlayer, item.m_Kind, item.m_Id)
	end)
end
