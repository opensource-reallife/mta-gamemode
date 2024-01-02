-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/SANNews/SANNewsAdsOverViewGUI.lua
-- *  PURPOSE:     SAN News Ads Overview GUI class
-- *
-- ****************************************************************************

SANNewsAdsOverviewGUI = inherit(GUIForm)
inherit(Singleton, SANNewsAdsOverviewGUI)

function SANNewsAdsOverviewGUI:constructor(theAds)
    if theAds then 
        self.m_sanNewsAds = theAds
    else
        return
    end

    self.m_ChangesMade = {}
    self.m_currentCustomerID = false

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

	self.m_TabPanel = GUITabPanel:new(0, 0, self.m_Width, self.m_Height, self)
	self.m_CloseButton = GUIButton:new(self.m_Width-30, 0, 30, 30, FontAwesomeSymbols.Close, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Red):setHoverColor(Color.White):setFontSize(1)
	self.m_CloseButton.onLeftClick = function() self:close() end

	self.m_BackButton = GUIButton:new(self.m_Width-60, 0, 30, 30, FontAwesomeSymbols.Left, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Accent):setHoverColor(Color.White):setFontSize(1)
	self.m_BackButton.onLeftClick = function() self:close() CompanyGUI:getSingleton():show() Cursor:show() end

    self.m_CustomerList = GUIGridList:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.3, self.m_Height*0.75, self)
	self.m_CustomerList:addColumn(_"Derzeitige Kunden:", 1)
	
    local item
    for k,v in pairs(self.m_sanNewsAds["theAds"]) do
        item = self.m_CustomerList:addItem(self.m_sanNewsAds["theAds"][k]["customerName"])
        item.onLeftClick = function () 
            self:onCustomerChange(k)
        end
    end

    self.m_CustomerAdd = GUIButton:new(self.m_Width*0.02, self.m_Height*0.80, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Plus, self):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Kunde hinzufügen", "button", true)
    self.m_CustomerAdd.onLeftClick = function()
		self:close()
        local currentCustomers = {}
        for k, v in pairs(self.m_sanNewsAds["theAds"]) do 
            currentCustomers[k] = {
                customerName = self.m_sanNewsAds["theAds"][k]["customerName"],
                customerUniqueID = self.m_sanNewsAds["theAds"][k]["customerUniqueID"],
                customerType = self.m_sanNewsAds["theAds"][k]["customerType"]
            }
        end
        if SANNewsAdsNewCustomerGUI:isInstantiated() then
            delete(SANNewsAdsNewCustomerGUI:getSingleton())
        end
        SANNewsAdsNewCustomerGUI:new(currentCustomers)
	end

    self.m_CustomerRemove = GUIButton:new(self.m_Width*0.17, self.m_Height*0.80, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Minus, self):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Ausgewählten Kunden entfernen", "button", true):setEnabled(false)
    self.m_CustomerRemove.onLeftClick = function ()
        ShortMessageQuestion:new(
            _"Willst du den ausgewählten Kunden samt aller Daten entfernen?",
            function()
                if self.m_currentCustomerID then 
                    if tonumber(self.m_currentCustomerID) ~= nil then
                        triggerServerEvent("sanNewsRemoveCustomerFromClient", localPlayer, self.m_currentCustomerID)
                    end
                    self:close()
                else
                    return
                end
            end,
            function()
                return
            end
        )
    end

    self.m_RefreshCustomerList = GUIButton:new(self.m_Width*0.02, self.m_Height*0.89, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Refresh, self):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Kundendaten neu laden", "button", true)
    self.m_RefreshCustomerList.onLeftClick = function ()
        self:close()
        triggerServerEvent("sanNewsAdsRefreshCustomers", localPlayer)
    end
    
    self.m_AdSettings = GUIButton:new(self.m_Width*0.17, self.m_Height*0.89, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Cogs, self):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Einstellungen", "button", true)
    self.m_AdSettings.onLeftClick = function ()
        self:close()
        local settings = {self.m_sanNewsAds["theSettings"]["AdsMainTimer"], self.m_sanNewsAds["theSettings"]["AdsActive"]}
        if SANNewsAdsSettingsGUI:isInstantiated() then
            delete(SANNewsAdsSettingsGUI:getSingleton())
        end
        SANNewsAdsSettingsGUI:new(settings)
    end
end

function SANNewsAdsOverviewGUI:onCustomerChange(customerID)
        
    if self.m_bg then delete(self.m_bg) end
    self.m_bg = GUIRectangle:new(self.m_Width*0.34, self.m_Height*0.02, self.m_Width*0.66, self.m_Height*0.96, tocolor(0, 0, 0, 0), self)

    self.m_currentCustomerID = customerID
    self.m_CustomerRemove:setEnabled(true)

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.07, self.m_sanNewsAds["theAds"][customerID]["customerName"], self.m_bg)

    self.m_isActive = GUICheckbox:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width*0.35, self.m_Height*0.04, _"Werbung aktiv", self.m_bg)
		self.m_isActive:setFont(VRPFont(25))
		self.m_isActive:setFontSize(1)
		self.m_isActive:setChecked(self.m_sanNewsAds["theAds"][customerID]["isActive"])
		self.m_isActive.onChange = function (state)
			self.m_sanNewsAds["theAds"][customerID]["isActive"] = state
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
      	end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.15, self.m_Width*0.8, self.m_Height*0.05, _"Preis je geschalteter Werbung in $:", self.m_bg)
    self.m_currentMoney = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.20, self.m_Width * 0.6, self.m_Height*0.06, self.m_bg):setText(self.m_sanNewsAds["theAds"][customerID]["moneyPerAd"])
    self.m_currentMoney.onChange = function ()
        if self.m_currentMoney then 
            self.m_sanNewsAds["theAds"][customerID]["moneyPerAd"] = tonumber(self.m_currentMoney:getText())
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.29, self.m_Width*0.8, self.m_Height*0.05, _"Mindestanzahl von Spielern, damit Werbung geschaltet wird:", self.m_bg)
    
    self.m_minPlayers = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.34, self.m_Width*0.6, self.m_Height*0.06, self.m_bg)
	local minPlayerChangerOptions = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,25,30}
    
    local theFocusNumber = 0
    for i=1, #minPlayerChangerOptions do 
        self.m_minPlayers:addItem(minPlayerChangerOptions[i])
        if minPlayerChangerOptions[i] == self.m_sanNewsAds["theAds"][customerID]["minPlayersOnlineToDeliverAds"] then 
            theFocusNumber = i
        end
	end
    self.m_minPlayers:setIndex(theFocusNumber)

	self.m_minPlayers.onChange = function ()
        if self.m_minPlayers then 
            self.m_sanNewsAds["theAds"][customerID]["minPlayersOnlineToDeliverAds"] = self.m_minPlayers:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.43, self.m_Width*0.8, self.m_Height*0.05, _"Zeit zw. Werbezeilen (in Sek):", self.m_bg)
    
    self.m_speedOfDelivery = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.48, self.m_Width*0.25, self.m_Height*0.06, self.m_bg)
	local speedOfDeliveryChangerOptions = {1,2,3,4,5}

    local theFocusNumberSpeedOfDelivery = 1
    for i=1, #speedOfDeliveryChangerOptions do 
        self.m_speedOfDelivery:addItem(speedOfDeliveryChangerOptions[i])
        if speedOfDeliveryChangerOptions[i] == self.m_sanNewsAds["theAds"][customerID]["deliveringSpeed"] then 
            theFocusNumberSpeedOfDelivery = i
        end
	end
    self.m_speedOfDelivery:setIndex(theFocusNumberSpeedOfDelivery)
    
    self.m_speedOfDelivery.onChange = function ()
        if self.m_speedOfDelivery then 
            self.m_sanNewsAds["theAds"][customerID]["deliveringSpeed"] = self.m_speedOfDelivery:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.33, self.m_Height*0.43, self.m_Width*0.8, self.m_Height*0.05, _"Max. Werbeschaltungen pro Tag:", self.m_bg)
    self.m_maxPerDay = GUIChanger:new(self.m_Width*0.33, self.m_Height*0.48, self.m_Width*0.25, self.m_Height*0.06, self.m_bg)
    local maxPerDayChangerOptions = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

    local theFocusNumberMaxPerDay = 0
    for i=1, #maxPerDayChangerOptions do 
        self.m_maxPerDay:addItem(maxPerDayChangerOptions[i])
        if maxPerDayChangerOptions[i] == self.m_sanNewsAds["theAds"][customerID]["maxPerDay"] then 
            theFocusNumberMaxPerDay = i 
        end
    end
    self.m_maxPerDay:setIndex(theFocusNumberMaxPerDay)

    self.m_maxPerDay.onChange = function ()
        if self.m_maxPerDay then 
            self.m_sanNewsAds["theAds"][customerID]["maxPerDay"] = self.m_maxPerDay:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.57, self.m_Width*0.8, self.m_Height*0.05, _"Werbung schalten zwischen (24-Stunden-Zählung):", self.m_bg)
    self.m_startTime = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.62, self.m_Width*0.13, self.m_Height*0.06, self.m_bg)
	local startTimeChangerOptions = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
    
    local theFocusNumberStartTime = 0
    for i=1, #startTimeChangerOptions do 
        self.m_startTime:addItem(startTimeChangerOptions[i])
        if startTimeChangerOptions[i] == self.m_sanNewsAds["theAds"][customerID]["adStartTimeEveryDay"] then 
            theFocusNumberStartTime = i
        end
	end
    self.m_startTime:setIndex(theFocusNumberStartTime)
    
    self.m_startTime.onChange = function ()
        if self.m_startTime then 
            self.m_sanNewsAds["theAds"][customerID]["adStartTimeEveryDay"] = self.m_startTime:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end
    
    self.m_endTime = GUIChanger:new(self.m_Width*0.2, self.m_Height*0.62, self.m_Width*0.13, self.m_Height*0.06, self.m_bg)
    local endTimeChangerOptions = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
    
    local theFocusNumberEndTime = 0
    for i=1, #endTimeChangerOptions do 
        self.m_endTime:addItem(endTimeChangerOptions[i])
        if endTimeChangerOptions[i] == self.m_sanNewsAds["theAds"][customerID]["adEndTimeEveryDay"] then 
            theFocusNumberEndTime = i
        end
	end
    self.m_endTime:setIndex(theFocusNumberEndTime)
	
    self.m_endTime.onChange = function ()
        if self.m_endTime then 
            self.m_sanNewsAds["theAds"][customerID]["adEndTimeEveryDay"] = self.m_endTime:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.71, self.m_Width*0.8, self.m_Height*0.05, _"Anzahl bisher geschalteter Werbungen: " .. self.m_sanNewsAds["theAds"][customerID]["timesDelivered"], self.m_bg)
    GUILabel:new(self.m_Width*0.02, self.m_Height*0.76, self.m_Width*0.8, self.m_Height*0.05, _"Letzte Werbeschaltung: " .. self.m_sanNewsAds["theAds"][customerID]["lastDeliveryDate"] .. ", " .. self.m_sanNewsAds["theAds"][customerID]["lastDeliveryTime"], self.m_bg)

    self.m_customizeAdsButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.83, self.m_Width*0.29, self.m_Height*0.07, _"Werbezeilen anpassen", self.m_bg):setBarEnabled(true)
	self.m_customizeAdsButton.onLeftClick = function()
		self:close()
        local customizeAdsTable = {
            customerName = self.m_sanNewsAds["theAds"][customerID]["customerName"],
            DE = self.m_sanNewsAds["theAds"][customerID]["adText"],
            EN = self.m_sanNewsAds["theAds"][customerID]["adTextEN"]
        }
        if SANNewsAdsGUI:isInstantiated() then
		 	delete(SANNewsAdsGUI:getSingleton())
		end
		SANNewsAdsGUI:new(customizeAdsTable, customerID)
	end

    self.m_saveChanges = GUIButton:new(self.m_Width*0.33, self.m_Height*0.83, self.m_Width*0.29, self.m_Height*0.07, _"Änderungen speichern", self.m_bg):setBarEnabled(true)
    self.m_saveChanges.onLeftClick = function()

        if tonumber(self.m_currentMoney:getText()) == nil or tonumber(self.m_currentMoney:getText()) < 0 then 
            ErrorBox:new(_"Fehlerhafte Eingabe im Preis-Feld.")
            return 
        end

        if next(self.m_ChangesMade) == nil then
            self:close()
            CompanyGUI:getSingleton():show()
            Cursor:show()
            return
        end

        local sendTable = {}

        for k, v in pairs(self.m_ChangesMade) do 
            if tonumber(self.m_sanNewsAds["theAds"][k]["moneyPerAd"]) == nil or tonumber(self.m_sanNewsAds["theAds"][k]["moneyPerAd"]) < 0 then 
                ErrorBox:new(_"Fehlerhafte Eingabe im Preis-Feld.")
                return
            end
            sendTable[k] = {
                custID = self.m_sanNewsAds["theAds"][k]["customerID"],
                isActive = self.m_sanNewsAds["theAds"][k]["isActive"],
                moneyPerAd = self.m_sanNewsAds["theAds"][k]["moneyPerAd"],
                minPlayersOnlineToDeliverAds = self.m_sanNewsAds["theAds"][k]["minPlayersOnlineToDeliverAds"],
                deliveringSpeed = self.m_sanNewsAds["theAds"][k]["deliveringSpeed"],
                adStartTimeEveryDay = self.m_sanNewsAds["theAds"][k]["adStartTimeEveryDay"],
                adEndTimeEveryDay = self.m_sanNewsAds["theAds"][k]["adEndTimeEveryDay"],
                maxPerDay = self.m_sanNewsAds["theAds"][k]["maxPerDay"]
            }
        end

        triggerServerEvent("sanNewsAdsSaveSettingsForCustomerFromClient", localPlayer, sendTable)

        self.m_ChangesMade = {}

        self:close()
        CompanyGUI:getSingleton():show()
        Cursor:show()
	end
end