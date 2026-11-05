-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ScoreboardGUI.lua
-- *  PURPOSE:     Scoreboard class
-- *
-- ****************************************************************************
ScoreboardGUI = inherit(GUIForm)
inherit(Singleton, ScoreboardGUI)

function ScoreboardGUI:constructor()
	local top = screenWidth*0.65*0.06
	GUIForm.constructor(self, screenWidth/2-(screenWidth*0.65/2), screenHeight/2-screenHeight*0.3+top, screenWidth*0.65, screenHeight*0.6-top, false, true)

	self.m_Scale = math.max(0.8, screenHeight/1080)
	self.m_RowHeight = math.floor(24*self.m_Scale)
	self.m_SmallHeight = math.floor(18*self.m_Scale)
	self.m_SideWidth = math.floor(math.max(self.m_Width*0.17, 150))
	self.m_BodyY = 0
	self.m_BodyHeight = self.m_Height

	self.m_Rect = GUIRectangle:new(0, self.m_BodyY, self.m_Width - self.m_SideWidth, self.m_BodyHeight, tocolor(0, 0, 0, 200), self)
	self.m_Side = GUIRectangle:new(self.m_Width - self.m_SideWidth, self.m_BodyY, self.m_SideWidth, self.m_BodyHeight, tocolor(35, 35, 35, 215), self)

	local pad = 10
	local closeSize = math.floor(26*self.m_Scale)
	local logoWidth = math.floor((self.m_SideWidth - 2*pad)*0.75)
	local logoHeight = logoWidth/2.3
	self.m_Pad, self.m_CloseSize, self.m_LogoHeight = pad, closeSize, logoHeight
	self.m_Logo = GUIImage:new((self.m_SideWidth - logoWidth)/2, pad, logoWidth, logoHeight, "files/images/LogoNoFont.png", self.m_Side)
	self.m_CloseButton = GUIButton:new(self.m_SideWidth - closeSize - pad + 4, pad + logoHeight + 6, closeSize, closeSize, FontAwesomeSymbols.Close, self.m_Side):setFont(FontAwesome(math.floor(18*self.m_Scale))):setBackgroundColor(Color.Clear):setBarEnabled(false):setBackgroundHoverColor(Color.Red):setHoverColor(Color.White):setFontSize(1)
	self.m_CloseButton.onLeftClick = function() self:close() end
	self.m_CloseButton:setVisible(false)

	local infoY = pad + logoHeight + 6
	self.m_PlayerCount = GUILabel:new(pad, infoY, self.m_SideWidth - 2*pad - closeSize, self.m_RowHeight, "", self.m_Side):setAlignY("center")
	self.m_SideLine = GUIRectangle:new(pad, infoY + self.m_RowHeight + 6, self.m_SideWidth - 2*pad, 2, Color.Accent, self.m_Side)
	self.m_CountStartY = infoY + self.m_RowHeight + 14

	local hintY = self.m_BodyHeight - pad - self.m_SmallHeight*3
	self.m_CountEndY = hintY - pad
	self.m_Hint = GUILabel:new(pad, hintY, self.m_SideWidth - 2*pad, self.m_SmallHeight, "", self.m_Side):setColor(Color.LightGrey)
	self.m_Hint2 = GUILabel:new(pad, hintY + self.m_SmallHeight, self.m_SideWidth - 2*pad, self.m_SmallHeight, _"Rechtsklick: Aktionen", self.m_Side):setColor(Color.LightGrey)
	self.m_Legend = GUILabel:new(pad, hintY + self.m_SmallHeight*2, self.m_SideWidth - 2*pad, self.m_SmallHeight, _"Rot = AFK / GW · Gelb = Knast", self.m_Side):setColor(Color.LightGrey)

	self.m_Grid = GUIGridList:new(10, 8, self.m_Rect.m_Width - 20, self.m_BodyHeight - 16, self.m_Rect)
	self.m_Grid:setFont(VRPFont(self.m_RowHeight))
	self.m_Grid:setItemHeight(self.m_RowHeight)
	self.m_Grid:setColor(Color.Clear)
	self.m_Grid:setColumnBackgroundColor(Color.Clear)
	self.m_Grid:addColumn("", 0.03)
	self.m_Grid:addColumn(_"Name", 0.28)
	self.m_Grid:addColumn(_"Fraktion", 0.115)
	self.m_Grid:addColumn("", 0)
	self.m_Grid:addColumn(_"Unternehmen", 0.17)
	self.m_Grid:addColumn(_"Gruppe", 0.155)
	self.m_Grid:addColumn(_"Spielzeit", 0.12)
	self.m_Grid:addColumn(_"Ping", 0.075)
	self.m_Grid:setSortable{_"Name", _"Fraktion", _"Unternehmen", _"Gruppe", _"Spielzeit"} --We can't sort Ping (Ping can be a number and also a string)
	self.m_Grid.onSelectItem = function() self:closeMenu() self:updateRowColors() end

	self.m_OldWeaponSlot = localPlayer:getWeaponSlot()

	self.m_ScrollBind = bind(self.onScoreBoardScroll, self)
	self.m_RightClickBind = bind(self.onRightClickKey, self)
	self.m_CursorHook = bind(self.onCursorToggle, self)
	self.m_ClickBind = bind(self.onClick, self)
end

function ScoreboardGUI:onShow()
	toggleControl("next_weapon", false)
	toggleControl("previous_weapon", false)
	toggleControl("action", false)
	setPedControlState("action", false)
	self.m_OldWeaponSlot = localPlayer:getWeaponSlot()
	self.m_Pinned = false
	self.m_CloseButton:setVisible(false)
	self.m_Hint:setText(_("%s: Mauszeiger", core:get("KeyBindings", "KeyToggleCursor", "b"):upper()))
	self:refresh()
	self.m_Timer = setTimer(bind(self.refresh, self), 15000, 0)
	self.m_Showing = true
	bindKey("mouse_wheel_up", "down", self.m_ScrollBind)
	bindKey("mouse_wheel_down", "down", self.m_ScrollBind)
	self.m_RightClickDown = false
	bindKey("mouse2", "both", self.m_RightClickBind)
	Cursor:getHook():register(self.m_CursorHook)

	RadioGUI:getSingleton():setControlEnabled(false)
end

function ScoreboardGUI:onHide()
	if self.m_Timer and isTimer(self.m_Timer) then killTimer(self.m_Timer) end
	if not NoDm:getSingleton().m_NoDm then
		toggleControl("next_weapon", true)
		toggleControl("previous_weapon", true)
		toggleControl("action", true)
	end
	unbindKey("mouse_wheel_up", "down", self.m_ScrollBind)
	unbindKey("mouse_wheel_down", "down", self.m_ScrollBind)
	unbindKey("mouse2", "both", self.m_RightClickBind)
	Cursor:getHook():unregister(self.m_CursorHook)
	self:closeMenu()
	self.m_Pinned = false
	RadioGUI:getSingleton():setControlEnabled(true)
	self.m_Showing = false
end

function ScoreboardGUI:hide()
	self.m_Pinned = false
	self:setVisible(false)
end

function ScoreboardGUI:close()
	self:hide()
	if isCursorShowing() then
		Cursor:toggleCursor(nil, "up")
	end
end

function ScoreboardGUI:isPinned()
	return self.m_Pinned
end

function ScoreboardGUI:onTabReleased()
	if not self:isVisible() then return end

	if isCursorShowing() then
		self.m_Pinned = true
		self.m_CloseButton:setVisible(true)
		self.m_Hint:setText(_"Tab: schließen")
	else
		self:hide()
	end
end

function ScoreboardGUI:onCursorToggle(state)
	if not state then
		self:closeMenu()
		if self.m_Pinned then
			self:hide()
		end
	end
end

function ScoreboardGUI:onRightClickKey(key, state)
	if state == "down" then
		self.m_RightClickDown = not isCursorShowing()
	elseif self.m_RightClickDown then
		self.m_RightClickDown = false
		nextframe(function()
			if self.m_Showing and not isCursorShowing() then
				Cursor:toggleCursor(key, "down")
			end
		end)
	end
end

function ScoreboardGUI:onScoreBoardScroll(key)
	if key == "mouse_wheel_up" then
		self.m_Grid.m_ScrollArea:onInternalMouseWheelUp()
	elseif key == "mouse_wheel_down" then
		self.m_Grid.m_ScrollArea:onInternalMouseWheelDown()
	end
end

function ScoreboardGUI:refresh()
	local scrollPosX, scrollPosY = self.m_Grid.m_ScrollArea:getScrollPosition()
	local scrollAreaDocumentSize_old = self.m_Grid.m_ScrollArea.m_DocumentHeight
	local scrollAreaHeight = self.m_Grid.m_ScrollArea.m_Height

	self.m_Grid:clear()
	self.m_Players = {}
	self.m_CompanyCount = {}
	self.m_CompanyAFKCount = {}
	self.m_FactionCount = {}
	self.m_FactionAFKCount = {}

	for k, player in pairs(getElementsByType("player")) do
		local factionId = player:getFaction() and not player:getFaction():isInsurgentFaction() and player:getFaction():getId() or 0 -- not = Count Insurgent as civilian (Insurgent = Civilian)
		local companyId = player:getCompany() and player:getCompany():getId() or 0
		table.insert(self.m_Players, {player, factionId})

		if not self.m_FactionCount[factionId] then self.m_FactionCount[factionId] = 0 end
		if not self.m_FactionAFKCount[factionId] then self.m_FactionAFKCount[factionId] = 0 end

		self.m_FactionCount[factionId] = self.m_FactionCount[factionId] + 1
		if player:isAFK() then
			self.m_FactionAFKCount[factionId] = self.m_FactionAFKCount[factionId] + 1
		end

		if companyId ~= 0 then
			if not self.m_CompanyCount[companyId] then self.m_CompanyCount[companyId] = 0 end
			if not self.m_CompanyAFKCount[companyId] then self.m_CompanyAFKCount[companyId] = 0 end

			self.m_CompanyCount[companyId] = self.m_CompanyCount[companyId] + 1
			if player:isAFK() then
				self.m_CompanyAFKCount[companyId] = self.m_CompanyAFKCount[companyId] + 1
			end
		end
	end

	local isRescue = localPlayer:getFaction() and localPlayer:getFaction():isRescueFaction()
	self.m_Grid:setColumnText(4, isRescue and _"FMS" or "")
	self.m_Grid.m_Columns[2].width = isRescue and 0.24 or 0.28
	self.m_Grid.m_Columns[4].width = isRescue and 0.04 or 0

	table.sort(self.m_Players, function (a, b) return (a[2] < b[2]) end)
	self:insertPlayers()

	local scrollAreaDocumentSize_new = self.m_Grid.m_ScrollArea.m_DocumentHeight
	if scrollPosY ~= 0 and scrollAreaDocumentSize_old > scrollAreaDocumentSize_new and math.abs(scrollPosY) > scrollAreaDocumentSize_new - scrollAreaHeight then
		scrollPosY = (scrollPosY / (scrollAreaDocumentSize_old - scrollAreaHeight) * scrollAreaDocumentSize_new) + scrollAreaHeight
		if math.abs(scrollPosY) < scrollAreaHeight or scrollPosY > 0 then
			scrollPosY = 0
		end
	end

	self.m_Grid.m_ScrollArea:setScrollPosition(scrollPosX, scrollPosY)

	if not self.m_CountRows then
		local factions, companies = 0, 0
		for id in pairs(FactionManager.Map) do if id ~= 13 then factions = factions + 1 end end
		for id in ipairs(CompanyManager.Map) do if id ~= 1 then companies = companies + 1 end end
		self.m_CountRows = {}
		self.m_CountHeaders = {}
		local minRow = math.floor(self.m_RowHeight*0.8)
		local rows = factions + companies + 3.5
		local available = self.m_CountEndY - self.m_CountStartY
		if minRow*rows - available > self.m_LogoHeight/2 then
			self.m_CountColumns = 2
			rows = math.ceil((factions + 1)/2) + math.ceil(companies/2) + 2.5
		else
			self.m_CountColumns = 1
		end
		local shrink = math.min(self.m_LogoHeight/2, math.max(0, minRow*rows - available))
		if shrink > 0 then
			self:shrinkLogo(shrink)
		end
		self.m_CountRowHeight = math.min(self.m_CountColumns == 2 and math.floor(self.m_RowHeight*0.85) or self.m_RowHeight, math.floor((self.m_CountEndY - self.m_CountStartY) / rows))
	end
	self.m_CountY = self.m_CountStartY
	self.m_CountIndex = 0

	self:addCountHeader("factions", _"Fraktionen")
	self:addPlayerCount(_"Zivilisten", self.m_FactionCount[0] or 0, self.m_FactionAFKCount[0] or 0, tocolor(255, 255, 255))

	for id, faction in pairs(FactionManager.Map) do
		if id ~= 13 then -- Hide Insurgent count (Insurgent = Civilian)
			local color = faction:getColor()
			self:addPlayerCount(faction:getShortName(), self.m_FactionCount[id] or 0, self.m_FactionAFKCount[id] or 0, tocolor(color.r, color.g, color.b))
		end
	end

	self.m_CountY = self.m_CountY + self.m_CountRowHeight*0.5
	self:addCountHeader("companies", _"Unternehmen")
	for id, company in ipairs(CompanyManager.Map) do
		if id ~= 1 then -- Hide Driving School count
			local color = company:getColor()
			self:addPlayerCount(company:getShortName(), self.m_CompanyCount[id] or 0, self.m_CompanyAFKCount[id] or 0, tocolor(color.r, color.g, color.b))
		end
	end

	self.m_PlayerCount:setText(_("%d Spieler online", #getElementsByType("player")))
end

function ScoreboardGUI:shrinkLogo(shrink)
	local logoHeight = self.m_LogoHeight - shrink
	self.m_Logo:setSize(logoHeight*2.3, logoHeight)
	self.m_Logo:setPosition((self.m_SideWidth - logoHeight*2.3)/2, self.m_Pad)
	for _, element in pairs({self.m_PlayerCount, self.m_CloseButton, self.m_SideLine}) do
		local x, y = element:getPosition()
		element:setPosition(x, y - shrink)
	end
	self.m_LogoHeight = logoHeight
	self.m_CountStartY = self.m_CountStartY - shrink
end

function ScoreboardGUI:addCountHeader(key, text)
	if not self.m_CountHeaders[key] then
		self.m_CountHeaders[key] = GUILabel:new(10, self.m_CountY, self.m_SideWidth - 20, self.m_CountRowHeight, text, self.m_Side):setAlignY("center"):setColor(Color.LightGrey)
	end
	self.m_CountY = self.m_CountY + self.m_CountRowHeight
	self.m_SectionY = self.m_CountY
	self.m_SectionIndex = 0
end

function ScoreboardGUI:addPlayerCount(name, value, valueAFK, color)
	self.m_CountIndex = self.m_CountIndex + 1
	local row = self.m_CountRows[self.m_CountIndex]

	local h = self.m_CountRowHeight
	local column = self.m_SectionIndex % self.m_CountColumns
	local y = self.m_SectionY + math.floor(self.m_SectionIndex/self.m_CountColumns)*h

	if not row then
		local width = (self.m_SideWidth - 20)/self.m_CountColumns
		local x = 10 + column*width
		local font = getVRPFont(VRPFont(h))
		local valueWidth = dxGetTextWidth(self.m_CountColumns == 1 and "99 (9 AFK)" or "99", 1, font)
		local nameWidth = width - 8 - valueWidth - 6
		row = {
			stripe = GUIRectangle:new(x, y + h*0.2, 3, h*0.6, color, self.m_Side),
			name = GUILabel:new(x + 8, y, nameWidth, h, self:fitWidth(name, nameWidth, font), self.m_Side):setAlignY("center"),
			value = GUILabel:new(x + width - valueWidth - 4, y, valueWidth, h, "", self.m_Side):setAlignX("right"):setAlignY("center"),
		}
		self.m_CountRows[self.m_CountIndex] = row
	end

	local textColor = value > 0 and Color.White or tocolor(115, 115, 115)
	row.name:setColor(textColor)
	row.value:setColor(textColor)
	if valueAFK == 0 or self.m_CountColumns == 2 then
		row.value:setText(tostring(value))
	else
		row.value:setText(("%d (%d AFK)"):format(value, valueAFK))
	end

	self.m_SectionIndex = self.m_SectionIndex + 1
	self.m_CountY = self.m_SectionY + math.ceil(self.m_SectionIndex/self.m_CountColumns)*h
end

function ScoreboardGUI:fitText(text, columnIndex)
	return self:fitWidth(text, self.m_Grid:getColumnWidth(columnIndex)*self.m_Grid.m_Width - 8, self.m_Grid:getFont())
end

function ScoreboardGUI:fitWidth(text, width, font)
	if dxGetTextWidth(text, 1, font) <= width then return text end
	while utf8.len(text) > 1 and dxGetTextWidth(text .. "…", 1, font) > width do
		text = utf8.sub(text, 1, utf8.len(text) - 1)
	end
	return text .. "…"
end

function ScoreboardGUI:fitName(name)
	local width = self.m_Grid:getColumnWidth(2)*self.m_Grid.m_Width - 8
	local minHeight = math.ceil(self.m_RowHeight*0.75)
	for height = self.m_RowHeight, minHeight, -1 do
		if dxGetTextWidth(name, 1, getVRPFont(VRPFont(height))) <= width then
			return name, height
		end
	end
	return self:fitWidth(name, width, getVRPFont(VRPFont(minHeight))), minHeight
end

function ScoreboardGUI:insertPlayers()
	self.m_OwnItem = nil

	for index, playerTable in ipairs(self.m_Players) do
		local player = playerTable[1]
		local isLoggedIn = not player:getName():find("Gast_")

		local playtime = ("%d:%.2d"):format(math.floor(player:getPlayTime()/60), (player:getPlayTime() - math.floor(player:getPlayTime()/60)*60))

		local ping
		if player:isAFK() then
			ping = "AFK"
		elseif player:isInJail() then
			ping = "Knast"
		elseif player:getPublicSync("gangwarParticipant") then
			ping = "GW"
		else
			ping = player:getPing().."ms"
		end

		local gname = player:getGroupName()
		if gname == "" or #gname == 0 then
			gname = "–"
		end

		local name = (player.getPublicSync and (player:getPublicSync("supportMode") or player:getPublicSync("ticketsupportMode")) and ("[%s] %s"):format(RANKSCOREBOARD[player.getPublicSync and player:getPublicSync("Rank") or 3] or "Support", player:getName())) or player:getName()
		local nameHeight
		name, nameHeight = self:fitName(name)
		local hasFaction = player:getFaction() and not player:getFaction():isInsurgentFaction()

		local item = self.m_Grid:addItem(
			(isLoggedIn and player:isPremium()) and "files/images/Nametag/premium.png" or "files/images/Textures/Other/trans.png",
			name,
			isLoggedIn and (hasFaction and player:getFaction():getShortName() or "–") or "-", -- not = Dont show player as Insurgent (Insurgent = Civilian)
			isLoggedIn and ((localPlayer:getFaction() and localPlayer:getFaction():isRescueFaction()) and (player:getFaction() and player:getFaction():isRescueFaction() and player:getRadioStatus() or "-")) or "",
			isLoggedIn and (player:getCompany() and player:getCompany():getShortName() or "–") or "-",
			isLoggedIn and self:fitText(gname, 6) or "-",
			isLoggedIn and playtime or "-",
			ping or " - "
		)
		item:setColumnToImage(1, true, item.m_Height)
		item:setFont(VRPFont(self.m_RowHeight))
		item:setColumnFont(2, VRPFont(nameHeight), 1)
		item.m_Player = player
		item.onRightClick = function(item, cx, cy) self:openMenu(item, cx, cy) end

		if player == localPlayer then
			self.m_OwnItem = item
		end

		if not hasFaction then
			item:setColumnColor(3, tocolor(140, 140, 140))
		end
		if not player:getCompany() then
			item:setColumnColor(5, tocolor(140, 140, 140))
		end
		if gname == "–" then
			item:setColumnColor(6, tocolor(140, 140, 140))
		end

		if hasFaction then
			local color = player:getFaction():getColor()
			if not player:getPublicSync("Faction:Duty") then -- Dont show player faction color when off duty
				item:setColumnColor(3, tocolor(255, 255, 255))
			else
				item:setColumnColor(3, tocolor(color.r, color.g, color.b))
			end

			if (localPlayer:getFaction() and localPlayer:getFaction():isRescueFaction()) and (player:getFaction() and player:getFaction():isRescueFaction()) then
				if tonumber(player:getRadioStatus()) and FMS_STATUS_COLORS[tonumber(player:getRadioStatus())] then
					local colorFMS = FMS_STATUS_COLORS[tonumber(player:getRadioStatus())]
					item:setColumnColor(4, tocolor(colorFMS[1], colorFMS[2], colorFMS[3]))
				end
			end
		end

		if player:getCompany() and player:getPublicSync("Company:Duty") then
			local color = player:getCompany():getColor()
			item:setColumnColor(5, tocolor(color.r, color.g, color.b))
		end

		if player.getPublicSync and player:getPublicSync("supportMode") or player:getPublicSync("ticketsupportMode") then
			item:setColumnColor(2, tocolor(unpack(RANKCOLORS[player.getPublicSync and player:getPublicSync("Rank") or 3])))
		end

		if player:getGroupType() then
			if player:getGroupType() == "Gang" then
				item:setColumnColor(6, Color.Red)
			elseif player:getGroupType() == "Firma" then
				item:setColumnColor(6, Color.Accent)
			end
		end

		if ping == "AFK" then
			item:setColumnColor(8, Color.Red)
		elseif ping == "Knast" then
			item:setColumnColor(8, Color.Yellow)
		elseif ping == "GW" then
			item:setColumnColor(8, Color.Red)
		end
	end

	self:updateRowColors()
end

function ScoreboardGUI:updateRowColors()
	if self.m_OwnItem and self.m_Grid:getSelectedItem() ~= self.m_OwnItem then
		self.m_OwnItem:setBackgroundColor(tocolor(139, 102, 229, 70))
	end
end

function ScoreboardGUI:openMenu(item, cx, cy)
	self:closeMenu()
	if not isElement(item.m_Player) then return end

	self.m_Grid:onInternalSelectItem(item)
	self:updateRowColors()

	local x, y = self:getPosition(true)
	self.m_Menu = ScoreboardMouseMenu:new(cx - x, cy - y, item.m_Player, self)
	if not self.m_ClickHandlerAdded then
		addEventHandler("onClientClick", root, self.m_ClickBind)
		self.m_ClickHandlerAdded = true
	end
end

function ScoreboardGUI:performChecks()
	if self.m_Menu and self.m_Menu.m_Visible then
		self.m_Menu:updateInput()
	end
	for k, v in ipairs(self.m_Children) do
		if v ~= self.m_Menu and v.m_Visible and v.updateInput then
			v:updateInput()
		end
	end
end

function ScoreboardGUI:onClick(button, state, cx, cy)
	if button ~= "left" or state ~= "down" or not self.m_Menu then return end

	local x, y = self:getPosition(true)
	local mx, my = self.m_Menu:getPosition()
	if cx < x + mx or cy < y + my or cx > x + mx + self.m_Menu.m_Width or cy > y + my + self.m_Menu.m_Height then
		self:closeMenu()
	end
end

function ScoreboardGUI:closeMenu()
	if self.m_Menu then
		delete(self.m_Menu)
	end
	self.m_Menu = nil
	if self.m_ClickHandlerAdded then
		removeEventHandler("onClientClick", root, self.m_ClickBind)
		self.m_ClickHandlerAdded = false
	end
end

function ScoreboardGUI:onMenuClosed(menu)
	if self.m_Menu == menu then
		self.m_Menu = nil
	end
end
