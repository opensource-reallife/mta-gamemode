GangwarNpcGUI = inherit(GUIForm)

function GangwarNpcGUI:constructor(data)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 26)
	self.m_Height = grid("y", 14)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Gangwar", true, true, self)
	self.m_Data = data

	local listY = 2
	if data.mode == "regular" then
		GUIGridLabel:new(1, 1, 16, 1, _"Reguläre Attackzeit", self.m_Window)
		local maxAttacks = data.maxAttacks or 0
		self.m_AttackBar = GUIGridProgressBar:new(1, 2, 16, 1, self.m_Window)
		listY = 3
		self.m_AttackBar:setProgress(maxAttacks > 0 and math.min(100, data.attacksLeft/maxAttacks*100) or 0)
		self.m_AttackBar:setText(_("%d / %d Attacks übrig", data.attacksLeft, maxAttacks))
	else
		GUIGridLabel:new(1, 1, 24, 1, self:getStatusText(), self.m_Window)
	end
	self.m_RefreshButton = GUIGridButton:new(25, 1, 1, 1, FontAwesomeSymbols.Refresh, self.m_Window):setFont(FontAwesome(15)):setFontSize(1):setBarEnabled(false)
	self.m_RefreshButton.onLeftClick = bind(self.onRefreshClick, self)

	self.m_AreaList = GUIGridGridList:new(1, listY, 16, 14 - listY, self.m_Window)
	self.m_AreaList:addColumn(_"Gebiet", 0.35)
	self.m_AreaList:addColumn(_"Besitzer", 0.2)
	self.m_AreaList:addColumn(_"Status", 0.45)
	self.m_AreaList:setSortable({_"Gebiet", _"Besitzer", _"Status"})
	self.m_AreaList.sortList = function() end
	self.m_AreaList.onInternalLeftClick = function(grid, cx, cy) self:onHeaderClick(cx, cy) end
	self.m_AreaList.m_SortColumnIndex = GangwarNpcGUI.SortColumn
	self.m_AreaList.m_SortColumnDirection = GangwarNpcGUI.SortDirection
	self.m_AreaMap = GUIGridMiniMap:new(18, 2, 8, 8, self.m_Window)
	self:fillAreaList(GangwarNpcGUI.SelectedAreaId)

	local session = data.session
	local canAttack = data.canStart and data.mode ~= "closed" and not session
	self.m_AttackButton = GUIGridButton:new(18, 10, 8, 1, data.mode == "given" and _"Attack anfragen" or _"Angreifen", self.m_Window)
	self.m_AttackButton:setBackgroundColor(Color.Orange)
	self.m_AttackButton:setEnabled(canAttack and true or false)
	self.m_AttackButton.onLeftClick = bind(self.onAttackClick, self)

	local isPrepare = session and session.phase == "prepare"
	self.m_PickButton = GUIGridButton:new(18, 11, 8, 1, _"Einteilen", self.m_Window)
	self.m_PickButton:setEnabled(isPrepare and session.canPick or false)
	self.m_PickButton.onLeftClick = function()
		triggerServerEvent("Gangwar:requestPickData", localPlayer)
		delete(self)
	end

	self.m_EnterButton = GUIGridButton:new(18, 12, 8, 1, _"Eintreten", self.m_Window):setBackgroundColor(Color.Green)
	self.m_EnterButton:setEnabled(isPrepare and not session.entered and not session.eliminated and (session.picked or session.pickOpen) or false)
	self.m_EnterButton.onLeftClick = function()
		triggerServerEvent("Gangwar:enter", localPlayer)
		delete(self)
	end

	local isBattle = session and session.phase == "battle"
	self.m_LateButton = GUIGridButton:new(18, 13, 8, 1, _"Nachjoin anfragen", self.m_Window)
	self.m_LateButton:setEnabled(isBattle and not session.entered or false)
	self.m_LateButton.onLeftClick = function()
		triggerServerEvent("Gangwar:requestLateJoin", localPlayer)
		delete(self)
	end
end

function GangwarNpcGUI:destructor()
	GangwarNpcGUI.Current = nil
	GUIForm.destructor(self)
end

function GangwarNpcGUI:fillAreaList(selectedAreaId)
	self.m_AreaList:clear()
	self:addAreaGroup(_"Laufende Gangwars", function(area) return area.running end, selectedAreaId)
	self:addAreaGroup(_"Gebiete", function(area) return not area.running and not area.own and not area.locked end, selectedAreaId)
	self:addAreaGroup(_"Eigene Gebiete", function(area) return not area.running and area.own end, selectedAreaId)
	self:addAreaGroup(_"Noch nicht attackierbar", function(area) return not area.running and area.locked end, selectedAreaId)
	self.m_AreaList:anyChange()
end

function GangwarNpcGUI:addAreaGroup(title, filter, selectedAreaId)
	local entries = {}
	for key, area in ipairs(self.m_Data.areas) do
		if filter(area) then
			entries[#entries + 1] = {area = area, index = key}
		end
	end
	if #entries == 0 then return end

	table.sort(entries, function(a, b) return self:compareAreas(a, b) end)
	self.m_AreaList:addItemNoClick(title, "", ""):setColumnColor(1, Color.Accent)
	for key, entry in ipairs(entries) do
		local area = entry.area
		local item = self.m_AreaList:addItem(area.name, area.owner, area.blocked or _"Attackierbar")
		item.m_Area = area
		item.onLeftClick = function() self:showPreview(area) end
		if not area.blocked then
			item:setColumnColor(3, Color.Green)
		end
		if area.id == selectedAreaId then
			self.m_AreaList:onInternalSelectItem(item)
			self:showPreview(area)
		end
	end
end

function GangwarNpcGUI:showPreview(area)
	if not area.x or not area.y then return end
	self.m_AreaMap.m_Blips = {}
	self.m_AreaMap:setMapPosition(area.x, area.y)
	self.m_AreaMap:addBlip("Marker.png", area.x, area.y)
end

function GangwarNpcGUI:getAreaSortValue(area, column)
	local values = {area.name, area.owner, area.blocked or _"Attackierbar"}
	return tostring(values[column]):lower()
end

function GangwarNpcGUI:compareAreas(a, b)
	local column = self.m_AreaList.m_SortColumnIndex
	local direction = self.m_AreaList.m_SortColumnDirection
	if column and direction ~= "none" then
		local valueA, valueB = self:getAreaSortValue(a.area, column), self:getAreaSortValue(b.area, column)
		if valueA ~= valueB then
			if direction == "up" then
				return valueA < valueB
			end
			return valueA > valueB
		end
	end
	return a.index < b.index
end

function GangwarNpcGUI:onHeaderClick(cx, cy)
	local list = self.m_AreaList
	local posX, posY = list:getPosition(true)
	if cy - posY > list.m_ItemHeight then return end

	local clicked, width = false, 0
	for id, column in ipairs(list.m_Columns) do
		if cx - posX < width then break end
		clicked = id
		width = width + column.width * list.m_Width + 5
	end
	if not clicked then return end

	if list.m_SortColumnIndex == clicked then
		list.m_SortColumnDirection = ({up = "down", down = "none", none = "up"})[list.m_SortColumnDirection]
	else
		list.m_SortColumnIndex = clicked
		list.m_SortColumnDirection = "up"
	end
	GangwarNpcGUI.SortColumn = list.m_SortColumnIndex
	GangwarNpcGUI.SortDirection = list.m_SortColumnDirection

	local item = list:getSelectedItem()
	self:fillAreaList(item and item.m_Area.id or nil)
end

function GangwarNpcGUI:onRefreshClick()
	local item = self.m_AreaList:getSelectedItem()
	GangwarNpcGUI.SelectedAreaId = item and item.m_Area.id or nil
	triggerServerEvent("Gangwar:requestNpcData", localPlayer)
end

function GangwarNpcGUI:getStatusText()
	local data = self.m_Data
	if data.session then
		local phase = data.session.phase == "prepare" and _"Aufbauphase" or (data.session.phase == "battle" and _"Attackphase" or _"Endphase")
		return _("%s gegen %s um %s: %s, noch %d:%02d", data.session.attacker, data.session.defender, data.session.area, phase, math.floor(data.session.time/60), data.session.time%60)
	elseif data.mode == "regular" then
		return _("Reguläre Attackzeit: Noch %d Attacks für deine Fraktion.", data.attacksLeft)
	elseif data.mode == "given" then
		return _"Die reguläre Attackzeit ist vorbei. Attacks müssen freigegeben werden."
	end
	return _"Zurzeit sind keine Attacks möglich."
end

function GangwarNpcGUI:onAttackClick()
	local item = self.m_AreaList:getSelectedItem()
	if not item then
		ErrorBox:new(_"Bitte wähle ein Gebiet aus!")
		return
	end
	if item.m_Area.blocked then
		ErrorBox:new(item.m_Area.blocked)
		return
	end

	local area = item.m_Area
	GangwarPickGUI.open({
		title = area.name,
		members = self.m_Data.members,
		picks = {self.m_Data.playerId},
		lockedId = self.m_Data.playerId,
		canModify = true,
		maxPlayers = self.m_Data.maxPlayers,
	}, _"Attack starten", function(ids)
		triggerServerEvent("Gangwar:startAttack", localPlayer, area.id, ids)
	end)
	delete(self)
end
