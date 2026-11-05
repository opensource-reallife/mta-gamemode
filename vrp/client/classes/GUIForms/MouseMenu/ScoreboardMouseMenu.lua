-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/MouseMenu/ScoreboardMouseMenu.lua
-- *  PURPOSE:     Scoreboard player mouse menu class
-- *
-- ****************************************************************************
ScoreboardMouseMenu = inherit(GUIMouseMenu)

function ScoreboardMouseMenu:constructor(posX, posY, player, scoreboard, adminMode)
	GUIMouseMenu.constructor(self, posX, posY, 300, 1, scoreboard)

	self.m_Scoreboard = scoreboard
	self.m_ItemHeight = math.floor(30*scoreboard.m_Scale)
	self.m_PosX, self.m_PosY = posX, posY
	self:setElement(player)

	if player:getFaction() and not player:getFaction():isInsurgentFaction() then
		local color = player:getFaction():getColor()
		self:addItem(("%s (%s)"):format(player:getName(), player:getFaction():getShortName())):setTextColor(rgb(color.r, color.g, color.b))
	else
		self:addItem(player:getName()):setTextColor(Color.White)
	end

	if adminMode then
		self:addAdminItems(player)
	else
		self:addPlayerItems(player)
	end

	self:adjustWidth()
	self:fitInto()
end

function ScoreboardMouseMenu:destructor()
	if self.m_Scoreboard then
		self.m_Scoreboard:onMenuClosed(self)
	end
	GUIElement.destructor(self)
end

function ScoreboardMouseMenu:addItem(text, callback)
	local h = self.m_ItemHeight
	self.m_Height = (#self.m_Items+1)*h
	local item
	if callback then
		item = GUIMouseMenuItem:new(0, #self.m_Items*h, self.m_Width, h, text, self)
		item.onLeftClick = function(item) callback(item, self.m_Element) delete(self) end
	else
		item = GUIMouseMenuNoClickItem:new(0, #self.m_Items*h, self.m_Width, h, text, self)
	end

	table.insert(self.m_Items, item)

	return item
end

function ScoreboardMouseMenu:fitInto()
	self.m_Width = self.m_Items[1] and self.m_Items[1].m_Width or self.m_Width
	local maxX = self.m_Scoreboard.m_Width - self.m_Width
	local maxY = self.m_Scoreboard.m_Height - self.m_Height
	self:setPosition(math.max(0, math.min(self.m_PosX, maxX)), math.max(0, math.min(self.m_PosY, maxY)))
end

function ScoreboardMouseMenu:addPlayerItems(player)
	if player ~= localPlayer then
		self:addItem(_"Anrufen",
			function()
				if not isElement(player) then return end
				local app = Phone:getSingleton():getAppByClass(AppCall)
				if app:isBusy() then
					ErrorBox:new(_"Du telefonierst gerade!")
					return
				end
				self.m_Scoreboard:hide()
				app:startCall("player", player)
			end
		):setIcon(FontAwesomeSymbols.Phone)

		self:addItem(_"Geld überweisen",
			function()
				if not isElement(player) then return end
				local phone = Phone:getSingleton()
				if phone:getAppByClass(AppCall):isBusy() then
					ErrorBox:new(_"Du telefonierst gerade!")
					return
				end
				self.m_Scoreboard:hide()
				if not phone:isOn() then
					WarningBox:new(_"Dein Handy ist ausgeschaltet!")
					return
				end
				phone:onShow()
				phone:closeAllApps()
				local app = phone:getAppByClass(AppBank)
				phone:openApp(app)
				if app.m_TabPanel and app.m_TransferToEdit then
					app.m_TabPanel:setTab(2)
					app.m_TransferToEdit:setText(player:getName())
				end
			end
		):setIcon(FontAwesomeSymbols.Money)
	end

	self:addItem(_"Name kopieren",
		function()
			if not isElement(player) then return end
			setClipboard(player:getName())
			InfoBox:new(_"Name in die Zwischenablage kopiert.")
		end
	):setIcon(FontAwesomeSymbols.Copy)

	if localPlayer:getRank() >= RANK.Supporter and player ~= localPlayer then
		self:addItem(_"Admin >>>",
			function()
				if not isElement(player) then return end
				local scoreboard = self.m_Scoreboard
				scoreboard.m_Menu = ScoreboardMouseMenu:new(self.m_PosX, self.m_PosY, player, scoreboard, true)
			end
		):setIcon(FontAwesomeSymbols.Shield)
	end
end

function ScoreboardMouseMenu:addAdminItem(func, text, icon, callback)
	if localPlayer:getRank() < (ADMIN_RANK_PERMISSION[func] or RANK.Projektleiter) then return end
	self:addItem(text, callback):setIcon(icon)
end

function ScoreboardMouseMenu:addAdminItems(player)
	local simple = function(func)
		return function()
			if isElement(player) then
				triggerServerEvent("adminPlayerFunction", root, func, player)
			end
		end
	end

	self:addAdminItem("goto", _"hin porten", FontAwesomeSymbols.Right, simple("goto"))
	self:addAdminItem("gethere", _"her porten", FontAwesomeSymbols.Left, simple("gethere"))
	self:addAdminItem("spect", _"specten", FontAwesomeSymbols.Video, simple("spect"))
	self:addAdminItem("freeze", _"ent/freezen", FontAwesomeSymbols.Hands, simple("freeze"))

	self:addAdminItem("rkick", _"kicken", FontAwesomeSymbols.SignOut,
		function()
			if not isElement(player) then return end
			self.m_Scoreboard:hide()
			InputBox:new(_("Spieler %s kicken", player:getName()),
				_("Aus welchem Grund möchtest du den Spieler %s vom Server kicken?", player:getName()),
				function (reason)
					if reason then
						triggerServerEvent("adminPlayerFunction", root, "rkick", player, reason)
					else
						ErrorBox:new(_"Kein Grund angegeben!")
					end
				end)
		end
	)

	self:addAdminItem("prison", _"ins Prison", FontAwesomeSymbols.Lock,
		function()
			if not isElement(player) then return end
			self.m_Scoreboard:hide()
			AdminInputBox:new(_("Spieler %s ins Prison schicken", player:getName()), _"Dauer in Minuten:",
				function (reason, duration)
					if reason and duration then
						triggerServerEvent("adminPlayerFunction", root, "prison", player, reason, duration)
					else
						ErrorBox:new(_"Kein Grund oder Dauer angegeben!")
					end
				end)
		end
	)

	self:addAdminItem("timeban", _"Timeban", FontAwesomeSymbols.Clock,
		function()
			if not isElement(player) then return end
			self.m_Scoreboard:hide()
			AdminInputBox:new(_("Spieler %s time bannen", player:getName()), _"Dauer in Stunden:",
				function (reason, duration)
					if reason and duration then
						triggerServerEvent("adminPlayerFunction", root, "timeban", player, reason, duration)
					else
						ErrorBox:new(_"Kein Grund oder Dauer angegeben!")
					end
				end)
		end
	)

	self:addAdminItem("permaban", _"Permaban", FontAwesomeSymbols.Ban,
		function()
			if not isElement(player) then return end
			self.m_Scoreboard:hide()
			InputBox:new(_("Spieler %s permanent Bannen", player:getName()),
				_("Aus welchem Grund möchtest du den Spieler %s permanent bannen?", player:getName()),
				function (reason)
					if reason then
						triggerServerEvent("adminPlayerFunction", root, "permaban", player, reason)
					end
				end)
		end
	)

	self:addAdminItem("warn", _"Warns verwalten", FontAwesomeSymbols.Bell,
		function()
			if not isElement(player) then return end
			self.m_Scoreboard:hide()
			WarnManagement:new(player, "online")
		end
	)

	self:addItem(_"<<< Zurück",
		function()
			if not isElement(player) then return end
			local scoreboard = self.m_Scoreboard
			scoreboard.m_Menu = ScoreboardMouseMenu:new(self.m_PosX, self.m_PosY, player, scoreboard)
		end
	):setIcon(FontAwesomeSymbols.Double_Left)
end
