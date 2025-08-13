-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Admin/AdminPremiumGUI.lua
-- *  PURPOSE:     Admin Premium GUI class
-- *
-- ****************************************************************************

AdminPremiumGUI = inherit(GUIForm)
inherit(Singleton, AdminPremiumGUI)

addRemoteEvents{"AdminPremiumGUI:Open"}

function AdminPremiumGUI:constructor()
    GUIWindow.updateGrid()
    self.m_Width = grid("x", 25)
	self.m_Height = grid("y", 15)

    GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)

    self.m_OpenWindows = {}
    self.m_HistoryUsers = {}
    self.m_HistoryTypes = {}
    self.m_HistoryDescriptions = {}
    self.m_HistoryDates = {}

    self.m_TabPanel = GUITabPanel:new(0, 0, self.m_Width, self.m_Height, self)
	self.m_TabPanel.onTabChanged = bind(self.TabPanel_TabChanged, self)

    self.m_CloseButton = GUIButton:new(self.m_Width-30, 0, 30, 30, FontAwesomeSymbols.Close, self):setBarEnabled(false):setFont(FontAwesome(20)):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Red):setHoverColor(Color.White):setFontSize(1)
	self.m_CloseButton.onLeftClick = function() self:close() end

    -- All Tabs
    --local tabGeneral = self.m_TabPanel:addTab(_("Allgemein"))
    local tabUser = self.m_TabPanel:addTab(_("Spieler"))
    local tabVehicles = self.m_TabPanel:addTab(_("Fahrzeuge"))
    local tabCoupons = self.m_TabPanel:addTab(_("Gutscheine"))
    local tabHistory = self.m_TabPanel:addTab(_("Historie"))

    --self.m_TabGeneral = tabGeneral
    self.m_TabUsers = tabUser
    self.m_TabVehicles = tabVehicles
    self.m_TabCoupons = tabCoupons
    self.m_TabHistory = tabHistory

    -- Tab: General
    --[[
    Zeige Anzahl der Premium Spieler an; Aktiv, inaktiv oder nie gehabt
    Zeige Anzahl der Premium Fahrzeuge an; Abgeholt, verfügbar
    Zeige Anzahl der Gutscheine an; Eingelöst, abgelaufen, verfügbar
    ]]
    -- self.m_GeneralRectangle = GUIGridEmptyRectangle:new(1, 0.25, 10, 2.5, 1, Color.White, tabGeneral)
    -- self.PremiumUsersLabel = GUIGridLabel:new(1.25, 0.5, 6, 1, _"Premium Spieler:", tabGeneral):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    -- self.PremiumVehiclesLabel = GUIGridLabel:new(1.25, 1, 6, 1, _"Premium Fahrzeuge:", tabGeneral):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    -- self.PremiumCouponsLabel = GUIGridLabel:new(1.25, 1.5, 6, 1, _"Gutscheine:", tabGeneral):setFont(VRPFont(26, Fonts.EkMukta_Bold))


    -- Tab: Users
    self.m_PlayerSearch = GUIGridEdit:new(1, 0.8, 5.2, 1, tabUser)
	self.m_PlayerSearch.onChange = function () self:searchPlayer() end

    GUILabel:new(10, 10, 200, 20, _"Suche:", tabUser)
	self.m_PlayersGrid = GUIGridList:new(10, 70, 200, 440, tabUser)
	self.m_PlayersGrid:addColumn(_"Spieler", 1)
	self.m_RefreshButton = GUIGridButton:new(1, 13, 1, 1, FontAwesomeSymbols.Refresh, tabUser):setBarEnabled(false):setFont(FontAwesome(15))
	self.m_RefreshButton.onLeftClick = function ()
		self:refreshOnlinePlayers()
	end

    self.m_InformationRectangle = GUIGridEmptyRectangle:new(6.25, 0.25, 10, 4, 1, Color.White, tabUser)
    self.m_NameLabel = GUIGridLabel:new(6.5, -1, 7, 4, _("Name:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    self.m_VIPLabel = GUIGridLabel:new(6.5, -0.5, 7, 4, _("VIP:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    self.m_VIPUntilLabel = GUIGridLabel:new(6.5, 0, 7, 4, _("VIP bis:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    self.m_CouponsUsed = GUIGridLabel:new(6.5, 0.5, 7, 4, _("Gutscheine eingelöst:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    self.m_PremVehicles = GUIGridLabel:new(6.5, 1, 7, 4, _("Premium Fahrzeuge:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))
    self.m_ORDollar = GUIGridLabel:new(6.5, 1.5, 7, 4, _("OR-Dollar:"), tabUser):setFont(VRPFont(26, Fonts.EkMukta_Bold))

    self.m_NameValueLabel = GUIGridLabel:new(11, -1, 7, 4, _("-"), tabUser)
    self.m_VIPValueLabel = GUIGridLabel:new(11, -0.5, 7, 4, _("-"), tabUser)
    self.m_VIPUntilValueLabel = GUIGridLabel:new(11, 0, 7, 4, _("-"), tabUser)
    self.m_CouponsValueUsed = GUIGridLabel:new(11, 0.5, 7, 4, _("-"), tabUser)
    self.m_PremValueVehicles = GUIGridLabel:new(11, 1, 7, 4, _("-"), tabUser)
    self.m_ORDollarValue = GUIGridLabel:new(11, 1.5, 7, 4, _("-"), tabUser)

    --### Give VIP Button
    self.m_GiveVIPButton = GUIGridButton:new(6.5, 4.5, 4.5, 1, _"VIP geben", tabUser):setBackgroundColor(Color.Green):setEnabled(false)
    self.m_GiveVIPButton.onLeftClick = function()
        if self.m_SelectedPlayer then
            InputBox:new(
                _("%s : VIP geben", self.m_SelectedPlayer:getName()), _("Gebe die Dauer des VIPs in Tagen an:"), function(text)
                --triggerServerEvent
            end)
        else
            ErrorBox:new(_("Bitte wähle einen Spieler aus!"))
        end
    end

    --### Remove VIP Button
    self.m_RemoveVIPButton = GUIGridButton:new(6.5, 5.5, 4.5, 1, _"VIP entziehen", tabUser):setBackgroundColor(Color.Red):setEnabled(false)
    self.m_RemoveVIPButton.onLeftClick = function()
        if self.m_SelectedPlayer then
            QuestionBox:new(_("Möchtest du dem Spieler: %s sein VIP entziehen?", self.m_SelectedPlayer:getName()), function()
                --triggerServerEvent
            end)
        else
            ErrorBox:new(_("Bitte wähle einen Spieler aus!"))
        end
    end

    --### Give OR Dollar Button
    self.m_GiveORDollarButton = GUIGridButton:new(11, 4.5, 4.5, 1, _"OR-Dollar geben", tabUser):setBackgroundColor(Color.Green):setEnabled(false)
    self.m_GiveORDollarButton.onLeftClick = function()
        if self.m_SelectedPlayer then
            InputBox:new(_("%s: OR-Dollar geben", self.m_SelectedPlayer:getName()), _("Gebe die Anzahl der OR-Dollar an, die du geben möchtest:"), function(text)
                --triggerServerEvent
            end)
        else
            ErrorBox:new(_("Bitte wähle einen Spieler aus!"))
        end
    end

    --### Remove OR Dollar Button
    self.m_RemoveORDollarButton = GUIGridButton:new(11, 5.5, 4.5, 1, _"OR-Dollar entziehen", tabUser):setBackgroundColor(Color.Red):setEnabled(false)
    self.m_RemoveORDollarButton.onLeftClick = function()
        if self.m_SelectedPlayer then
            InputBox:new(_("%s: OR-Dollar entziehen", self.m_SelectedPlayer:getName()), _("Gebe die Anzahl der OR-Dollar an, die du entziehen möchtest:"), function()
                --triggerServerEvent
            end)
        else
            ErrorBox:new(_("Bitte wähle einen Spieler aus!"))
        end
    end

    --### Manage Coupons Button
    self.m_ManageCouponButton = GUIGridButton:new(6.5, 6.5, 4.5, 1, _"Gutscheine verwalten", tabUser):setBackgroundColor(Color.Orange):setEnabled(false)
    self.m_ManageCouponButton.onLeftClick = function()
        AdminManageCouponGUI:new(self.m_SelectedPlayer)
    end
    --[[
    Zeige eingelöste Gutscheine an
    Zeige nicht eingelöste Gutscheine an
    Löse einen Gutschein für den Spieler ein
    ]]

    --### Manage Premium Vehicles Button
    self.m_PremVehiclesButton = GUIGridButton:new(11, 6.5, 4.5, 1, _"Premium Fahrzeuge", tabUser):setBackgroundColor(Color.Orange):setEnabled(false)
    self.m_PremVehiclesButton.onLeftClick = function()
        AdminManagePremiumVehiclesGUI:new(self.m_SelectedPlayer)
    end
    --[[
    Zeige alle Premium Fahrzeuge an, die ein Spieler besitzt
    Zeige alle Premium Fahrzeuge an, die ein Spieler abholen kann
    Erstelle ein neues Premium Fahrzeug für den Spieler, was abholbar ist
    Lösche ein Premium Fahrzeug von dem Spieler
    ]]

    -- Tab: Vehicles
    --[[
    Zeige alle Premium Fahrzeuge an, die ein Spieler besitzt
    Zeige alle Premium Fahrzeuge an, die ein Spieler abholen kann
    ]]

    -- Tab: Coupons
    self.m_CouponsGridList = GUIGridList:new(10, 10, 625, 500, tabCoupons)
    self.m_CouponsGridList:addColumn(_("Gutschein"), 0.15)
    self.m_CouponsGridList:addColumn(_("Beschreibung"), 0.35)
    self.m_CouponsGridList:addColumn(_("Läuft ab"), 0.25)
    self.m_CouponsGridList:addColumn(_("Eingelöst"), 0.1)

    self.m_CouponsGridList:setSortable{_"Gutschein", _"Beschreibung", _"Datum", _"Eingelöst"}
    self.m_CouponsGridList:setSortColumn(_"Gutschein", "up")

    self.m_CouponsCreateButton = GUIGridIconButton:new(1, 13, FontAwesomeSymbols.Plus, tabCoupons):setBackgroundColor(Color.Green):setTooltip(_("Neuen Coupon erstellen"))
    self.m_CouponsCreateButton.onLeftClick = function()
    end

    self.m_CouponsDeleteButton = GUIGridIconButton:new(2, 13, FontAwesomeSymbols.Trash, tabCoupons):setBackgroundColor(Color.Red):setTooltip(_("Coupon löschen"))
    self.m_CouponsDeleteButton.onLeftClick = function()
    end

    self.m_CouponsRefreshButton = GUIGridIconButton:new(3, 13, FontAwesomeSymbols.Refresh, tabCoupons):setBackgroundColor(Color.Accent):setTooltip(_("Coupons neu laden"))
    self.m_CouponsRefreshButton.onLeftClick = function()
    end

    -- Test Items
    self.m_CouponsGridList:addItem(_("newbie"), _("Das ist ein Test Gutschein"), "∞", _("2 / ∞"))
    self.m_CouponsGridList:addItem(_("snake"), _("Juter Rücken"), "06.11.2025", _("2 / 10"))
    self.m_CouponsGridList:addItem(_("morris"), _("morris"), "Abgelaufen", _("10 / 10")):setBackgroundColor(Color.Red)

    --[[
    Wenn der Coupon abgelaufen ist oder die maximale Anzahl genutzt wurde, dann:
    Zeige den Coupon in rot an

    Zeige alle Coupons, ob abgelaufen oder nicht
    Zeige eingelöste Coupons in der Historie
    ]]

    -- Tab: History / Logs
    --[[
    Zeige alle Premium Aktionen an, die ein Spieler durchgeführt hat
    Zeige alle Premium Aktionen an, die ein Admin durchgeführt hat

    Beschreibung: (Typ: Gutschein, Fahrzeug, VIP, OR-Dollar), AdminName + ID, Erstellt am
    ]]
    self.m_HistoryGridList = GUIGridList:new(10, 55, 950, 300, tabHistory)
    self.m_HistoryGridList:addColumn(_("Datum"), 0.2)
    self.m_HistoryGridList:addColumn(_("Beschreibung"), 0.7)
    self.m_HistoryGridList:addColumn(_("Typ"), 0.2)   

	self.m_HistoryGridList:setSortable{_"Datum", _"Typ"}
	self.m_HistoryGridList:setSortColumn(_"Datum", "down")

    self.m_FilterLabel = GUIGridLabel:new(1, 0.25, 2, 1, _"Filter:", tabHistory)
    self.m_FilterCombobox = GUIGridCombobox:new(2.25, 0.25, 5, 1, _"Test", tabHistory) 

    self.m_HistroySearchLabel = GUIGridLabel:new(1, 0.25, 2, 1, _"Filter:", tabHistory)
    self.m_HistroySearchEdit = GUIGridEdit:new(10, 30, 200, 30, tabHistory)

    -- Test Items
    self.m_HistoryGridList:addItem("01.02.2020 12:00", _("Hat den Coupon: newbie erstellt!"), _("Coupon"))
    self.m_HistoryGridList:addItem("01.02.2021 12:00", _("Hat dem Spieler: Nilszh VIP gegeben!"), _("VIP"))
    self.m_HistoryGridList:addItem("01.02.2022 12:00", _("Das ist ein Test"), _("Vehicle"))
    self.m_HistoryGridList:addItem("01.02.2023 12:00", _("Das ist ein Test"), _("Coupon"))
    self.m_HistoryGridList:addItem("01.02.2024 12:00", _("Das ist ein Test"), _("Vehicle"))
    self.m_HistoryGridList:addItem("01.02.2025 12:00", _("Das ist ein Test"), _("VIP"))
end

-- function AdminPremiumGUI:loadData(vip, vipuntil, coupons, premvehicles, ordollar)
--     self.m_VIP = vip
--     self.m_VIPUntil = vipuntil
--     self.m_Coupons = coupons
--     self.m_PremVehicles = premvehicles
--     self.m_ORDollar = ordollar
-- end

-- addEventHandler("AdminPremiumGUI:SendData", root, function()
--     if (AdminPremiumGUI:isInstantiated()) then
--         AdminPremiumGUI:getSingleton():loadData(vip, vipuntil, coupons, premvehicles, ordollar)
--     end
-- end)

function AdminPremiumGUI:addDataToHistoryGridlist (player, type, description, date)
    self.m_HistoryUsers = player
    self.m_HistoryTypes = type
    self.m_HistoryDescriptions = description
    self.m_HistoryDates = date

    for i, v in pairs(self.m_HistoryUsers) do
        local player = self.m_HistoryUsers[i]
        local type = self.m_HistoryTypes[i]
        local description = self.m_HistoryDescriptions[i]
        local date = self.m_HistoryDates[i]

        if not isElement(player) then
            player = _("Unbekannt")
        end

        if not type or type == "" then
            type = _("Unbekannt")
        end

        if not description or description == "" then
            description = _("Keine Beschreibung")
        end

        if not date or date == "" then
            date = _("Unbekannt")
        end
    end
    local item = self.m_HistoryGridList:addItem(_(name), _(type), _(description), date)
end

function AdminPremiumGUI:searchPlayer()
    self:refreshOnlinePlayers()
end

function AdminPremiumGUI:refreshOnlinePlayers()
	local players = getElementsByType("player")
	table.sort(players, function(a, b) return a.name < b.name  end)

    self.m_NameValueLabel:setText(_("-"))
    self.m_VIPValueLabel:setText(_("-"))
    self.m_VIPUntilValueLabel:setText(_("-"))
    self.m_CouponsValueUsed:setText(_("-"))
    self.m_PremValueVehicles:setText(_("-"))
    self.m_ORDollarValue:setText(_("-"))

    self.m_GiveVIPButton:setEnabled(false)
    self.m_RemoveVIPButton:setEnabled(false)
    self.m_GiveORDollarButton:setEnabled(false)
    self.m_RemoveORDollarButton:setEnabled(false)
    self.m_ManageCouponButton:setEnabled(false)
    self.m_PremVehiclesButton:setEnabled(false)

	self.m_PlayersGrid:clear()
	for key, playeritem in ipairs(players) do
		if #self.m_PlayerSearch:getText() < 3 or string.find(string.lower(playeritem:getName()), string.lower(self.m_PlayerSearch:getText())) then
			local item = self.m_PlayersGrid:addItem(playeritem:getName())
			item.player = playeritem
			item.onLeftClick = function()
				self:onSelectPlayer(playeritem)
                self.m_GiveVIPButton:setEnabled(true)
                self.m_RemoveVIPButton:setEnabled(true)
                self.m_GiveORDollarButton:setEnabled(true)
                self.m_RemoveORDollarButton:setEnabled(true)
                self.m_ManageCouponButton:setEnabled(true)
                self.m_PremVehiclesButton:setEnabled(true)
			end
		end
	end
end

function AdminPremiumGUI:TabPanel_TabChanged(tabId)
	if tabId == self.m_TabUsers.TabIndex then
		self:refreshOnlinePlayers()
	end
end

function AdminPremiumGUI:onSelectPlayer(player)
    if not isElement(player) then
        ErrorBox:new(_"Der Spieler ist nicht mehr online!")
        return
    end

    if not player:getPublicSync("Money") then
		ErrorBox:new(_"Der Spieler ist nicht eingeloggt!")
		return
	end
    
    self.m_NameValueLabel:setText(_("%s (ID: %i)", player:getName(), player:getId()))
    self.m_VIPValueLabel:setText(_("%s", player:getName()))
    self.m_VIPUntilValueLabel:setText(_("%s", player:getName()))
    self.m_CouponsValueUsed:setText(_("%s", player:getName()))
    self.m_PremValueVehicles:setText(_("%s", player:getName()))
    self.m_ORDollarValue:setText(_("%s", player:getName()))

    self.m_SelectedPlayer = player
end

addEventHandler("AdminPremiumGUI:Open", localPlayer, function() 
	if localPlayer:getRank() >= RANK.Administrator then
		AdminPremiumGUI:new()
	end
end)