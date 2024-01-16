-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Company/SANNews/SANNewsAdsOverViewGUI.lua
-- *  PURPOSE:     SAN News Ads Overview GUI class
-- *
-- ****************************************************************************

SANNewsAdsOverviewGUI = inherit(GUIForm)
inherit(Singleton, SANNewsAdsOverviewGUI)

function SANNewsAdsOverviewGUI:constructor(Ads)
    if Ads then 
        self.m_SanNewsAds = Ads
    else
        return
    end

    addRemoteEvents{"updateAdData"}
	addEventHandler("updateAdData", root, bind(self.UpdateAdData, self))

    self.m_ChangesMade = {}
    self.m_currentCustomerID = false

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

    self.m_SANNewsAdsOverview = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"SAN News", false, true, self)
    self.m_SANNewsAdsOverview:addBackButton(function () CompanyGUI:getSingleton():show() end)
    self.m_SANNewsAdsOverview:deleteOnClose(true)

    self.m_CustomerList = GUIGridList:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.3, self.m_Height*0.75, self.m_SANNewsAdsOverview)
	self.m_CustomerList:addColumn(_"Derzeitige Kunden:", 1)
	
    local item
    for k,v in pairs(self.m_SanNewsAds["Ads"]) do
        item = self.m_CustomerList:addItem(self.m_SanNewsAds["Ads"][k]["customerName"])
        item.onLeftClick = function () 
            self:onCustomerChange(k)
        end
    end
    
    self.m_CustomerAdd = GUIButton:new(self.m_Width*0.02, self.m_Height*0.80, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Plus, self.m_SANNewsAdsOverview):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Kunde hinzufügen", "button", true)
    self.m_CustomerAdd:setEnabled(PermissionsManager:getSingleton():hasPlayerPermissionsTo("company", "editAds"))
    self.m_CustomerAdd.onLeftClick = function()
		self:close()
        local currentCustomers = {}
        for k, v in pairs(self.m_SanNewsAds["Ads"]) do 
            currentCustomers[k] = {
                customerName = self.m_SanNewsAds["Ads"][k]["customerName"],
                customerUniqueID = self.m_SanNewsAds["Ads"][k]["customerUniqueID"],
                customerType = self.m_SanNewsAds["Ads"][k]["customerType"]
            }
        end
        if SANNewsAdsNewCustomerGUI:isInstantiated() then
            delete(SANNewsAdsNewCustomerGUI:getSingleton())
        end
        SANNewsAdsNewCustomerGUI:new(currentCustomers)
	end

    self.m_CustomerRemove = GUIButton:new(self.m_Width*0.18, self.m_Height*0.80, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Minus, self.m_SANNewsAdsOverview):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Ausgewählten Kunden entfernen", "button", true):setEnabled(false)
    self.m_CustomerRemove.onLeftClick = function ()
        QuestionBox:new(
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

    self.m_RefreshCustomerList = GUIButton:new(self.m_Width*0.02, self.m_Height*0.89, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Refresh, self.m_SANNewsAdsOverview):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Kundendaten neu laden", "button", true)
    self.m_RefreshCustomerList.onLeftClick = function ()
        self:close()
        triggerServerEvent("sanNewsAdsRefreshCustomers", localPlayer)
    end
    
    self.m_AdSettings = GUIButton:new(self.m_Width*0.18, self.m_Height*0.89, self.m_Width*0.14, self.m_Height*0.07, FontAwesomeSymbols.Cogs, self.m_SANNewsAdsOverview):setFont(FontAwesome(20)):setBarEnabled(false):setTooltip(_"Einstellungen", "button", true)
    self.m_AdSettings:setEnabled(PermissionsManager:getSingleton():hasPlayerPermissionsTo("company", "editAds"))
    self.m_AdSettings.onLeftClick = function ()
        self:close()
        local settings = {self.m_SanNewsAds["Settings"]["AdsMainTimer"], self.m_SanNewsAds["Settings"]["AdsActive"]}
        if SANNewsAdsSettingsGUI:isInstantiated() then
            delete(SANNewsAdsSettingsGUI:getSingleton())
        end
        SANNewsAdsSettingsGUI:new(settings)
    end
end

function SANNewsAdsOverviewGUI:onCustomerChange(customerID)
        
    if self.m_bg then delete(self.m_bg) end
    self.m_bg = GUIRectangle:new(self.m_Width*0.34, self.m_Height*0.02, self.m_Width*0.66, self.m_Height*0.96, tocolor(0, 0, 0, 0), self.m_SANNewsAdsOverview)

    self.m_currentCustomerID = customerID
    self.m_CustomerRemove:setEnabled(PermissionsManager:getSingleton():hasPlayerPermissionsTo("company", "editAds"))

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.07, self.m_SanNewsAds["Ads"][customerID]["customerName"], self.m_bg)

    self.m_IsPaymentAccepted = GUILabel:new(self.m_Width*0.33, self.m_Height*0.09, self.m_Width*0.30, self.m_Height*0.05, _"", self.m_bg)
    
    if self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"] > 0 then 
        if self.m_SanNewsAds["Ads"][customerID]["paymentAcceptance"]["paymentAccepted"] == 1 then 
            self.m_IsPaymentAccepted:setText(_"Zahlung autorisiert.")
        else 
            self.m_IsPaymentAccepted:setText(_"Zahlung nicht autorisiert.")
            self.m_IsPaymentAccepted:setColor(Color.Red)
        end
    end

    self.m_isActive = GUICheckbox:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width*0.35, self.m_Height*0.04, _"Werbung aktiv", self.m_bg)
		self.m_isActive:setFont(VRPFont(25))
		self.m_isActive:setFontSize(1)
		self.m_isActive:setChecked(self.m_SanNewsAds["Ads"][customerID]["isActive"])
		self.m_isActive.onChange = function (state)
			self.m_SanNewsAds["Ads"][customerID]["isActive"] = state
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
      	end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.15, self.m_Width*0.6, self.m_Height*0.05, _"Preis je geschalteter Werbung in $:", self.m_bg)
    self.m_currentMoney = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.20, self.m_Width*0.6, self.m_Height*0.06, self.m_bg):setText(self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"]):setMaxLength(5)
    self.m_currentMoney.onChange = function ()
        if self.m_currentMoney then 
            self.m_SanNewsAds["Ads"][customerID]["moneyPerAd"] = tonumber(self.m_currentMoney:getText())
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.29, self.m_Width*0.8, self.m_Height*0.05, _"Mindestanzahl von Spielern, damit Werbung geschaltet wird:", self.m_bg)
    
    self.m_minPlayers = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.34, self.m_Width*0.6, self.m_Height*0.06, self.m_bg)
	local minPlayerChangerOptions = SN_AD_MIN_NUMBER_OF_PLAYERS_ONLINE_TO_DELIVER_AD_OPTIONS
    
    local theFocusNumber = 0
    for i=1, #minPlayerChangerOptions do 
        self.m_minPlayers:addItem(minPlayerChangerOptions[i])
        if minPlayerChangerOptions[i] == self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"] then 
            theFocusNumber = i
        end
	end
    self.m_minPlayers:setIndex(theFocusNumber)

	self.m_minPlayers.onChange = function ()
        if self.m_minPlayers then 
            self.m_SanNewsAds["Ads"][customerID]["minPlayersOnlineToDeliverAds"] = self.m_minPlayers:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.43, self.m_Width*0.8, self.m_Height*0.05, _"Zeit zw. Werbezeilen (in Sek):", self.m_bg)
    
    self.m_speedOfDelivery = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.48, self.m_Width*0.25, self.m_Height*0.06, self.m_bg)
	local speedOfDeliveryChangerOptions = SN_AD_INTERVAL_BETWEEN_AD_LINES_IN_SECONDS_OPTIONS

    local theFocusNumberSpeedOfDelivery = 1
    for i=1, #speedOfDeliveryChangerOptions do 
        self.m_speedOfDelivery:addItem(speedOfDeliveryChangerOptions[i])
        if speedOfDeliveryChangerOptions[i] == self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"] then 
            theFocusNumberSpeedOfDelivery = i
        end
	end
    self.m_speedOfDelivery:setIndex(theFocusNumberSpeedOfDelivery)
    
    self.m_speedOfDelivery.onChange = function ()
        if self.m_speedOfDelivery then 
            self.m_SanNewsAds["Ads"][customerID]["deliveringSpeed"] = self.m_speedOfDelivery:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.33, self.m_Height*0.43, self.m_Width*0.8, self.m_Height*0.05, _"Max. Werbeschaltungen pro Tag:", self.m_bg)
    self.m_maxPerDay = GUIChanger:new(self.m_Width*0.33, self.m_Height*0.48, self.m_Width*0.25, self.m_Height*0.06, self.m_bg)
    local maxPerDayChangerOptions = SN_AD_MAX_NUMBER_OF_AD_PER_DAY_PER_CUSTOMER_OPTIONS

    local theFocusNumberMaxPerDay = 0
    for i=1, #maxPerDayChangerOptions do 
        self.m_maxPerDay:addItem(maxPerDayChangerOptions[i])
        if maxPerDayChangerOptions[i] == self.m_SanNewsAds["Ads"][customerID]["maxPerDay"] then 
            theFocusNumberMaxPerDay = i 
        end
    end
    self.m_maxPerDay:setIndex(theFocusNumberMaxPerDay)

    self.m_maxPerDay.onChange = function ()
        if self.m_maxPerDay then 
            self.m_SanNewsAds["Ads"][customerID]["maxPerDay"] = self.m_maxPerDay:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.57, self.m_Width*0.8, self.m_Height*0.05, _"Werbung schalten zwischen (24-Stunden-Zählung):", self.m_bg)
    self.m_startTime = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.62, self.m_Width*0.13, self.m_Height*0.06, self.m_bg)
	local startTimeChangerOptions = SN_AD_TIME_HOUR_OPTIONS
    
    local theFocusNumberStartTime = 0
    for i=1, #startTimeChangerOptions do 
        self.m_startTime:addItem(startTimeChangerOptions[i])
        if startTimeChangerOptions[i] == self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"] then 
            theFocusNumberStartTime = i
        end
	end
    self.m_startTime:setIndex(theFocusNumberStartTime)
    
    self.m_startTime.onChange = function ()
        if self.m_startTime then 
            self.m_SanNewsAds["Ads"][customerID]["adStartTimeEveryDay"] = self.m_startTime:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end
    
    self.m_endTime = GUIChanger:new(self.m_Width*0.2, self.m_Height*0.62, self.m_Width*0.13, self.m_Height*0.06, self.m_bg)
    local endTimeChangerOptions = SN_AD_TIME_HOUR_OPTIONS
    
    local theFocusNumberEndTime = 0
    for i=1, #endTimeChangerOptions do 
        self.m_endTime:addItem(endTimeChangerOptions[i])
        if endTimeChangerOptions[i] == self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"] then 
            theFocusNumberEndTime = i
        end
	end
    self.m_endTime:setIndex(theFocusNumberEndTime)
	
    self.m_endTime.onChange = function ()
        if self.m_endTime then 
            self.m_SanNewsAds["Ads"][customerID]["adEndTimeEveryDay"] = self.m_endTime:getIndex()
            if not self.m_ChangesMade[customerID] then
                self.m_ChangesMade[customerID] = true
            end
        end
    end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.69, self.m_Width*0.8, self.m_Height*0.05, _("Anzahl bisher geschalteter Werbungen: %s", self.m_SanNewsAds["Ads"][customerID]["timesDelivered"]), self.m_bg)
    GUILabel:new(self.m_Width*0.02, self.m_Height*0.74, self.m_Width*0.8, self.m_Height*0.05, _("Letzte Werbeschaltung: %s, %s", self.m_SanNewsAds["Ads"][customerID]["lastDeliveryDate"], self.m_SanNewsAds["Ads"][customerID]["lastDeliveryTime"]), self.m_bg)

    self.m_customizeAdsButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.80, self.m_Width*0.29, self.m_Height*0.07, _"Werbezeilen anpassen", self.m_bg):setBarEnabled(true)
    self.m_customizeAdsButton.onLeftClick = function()
		self:close()
        local customizeAdsTable = {
            customerName = self.m_SanNewsAds["Ads"][customerID]["customerName"],
            DE = self.m_SanNewsAds["Ads"][customerID]["adText"],
            EN = self.m_SanNewsAds["Ads"][customerID]["adTextEN"]
        }
        if SANNewsAdsGUI:isInstantiated() then
		 	delete(SANNewsAdsGUI:getSingleton())
		end
		SANNewsAdsGUI:new(customizeAdsTable, customerID)
	end

    self.m_saveChanges = GUIButton:new(self.m_Width*0.33, self.m_Height*0.80, self.m_Width*0.29, self.m_Height*0.07, _"Änderungen speichern", self.m_bg):setBarEnabled(true)
    self.m_saveChanges:setEnabled(PermissionsManager:getSingleton():hasPlayerPermissionsTo("company", "editAds"))
    self.m_saveChanges.onLeftClick = function()

        if tonumber(self.m_currentMoney:getText()) == nil or tonumber(self.m_currentMoney:getText()) < 0 then 
            ErrorBox:new(_"Fehlerhafte Eingabe im Preis-Feld.")
            return 
        end

        if next(self.m_ChangesMade) == nil then
            return
        end

        local sendTable = {}

        for k, v in pairs(self.m_ChangesMade) do 
            if tonumber(self.m_SanNewsAds["Ads"][k]["moneyPerAd"]) == nil or tonumber(self.m_SanNewsAds["Ads"][k]["moneyPerAd"]) < 0 then 
                ErrorBox:new(_"Fehlerhafte Eingabe im Preis-Feld.")
                return
            end
            sendTable[k] = {
                custID = self.m_SanNewsAds["Ads"][k]["customerID"],
                isActive = self.m_SanNewsAds["Ads"][k]["isActive"],
                moneyPerAd = self.m_SanNewsAds["Ads"][k]["moneyPerAd"],
                minPlayersOnlineToDeliverAds = self.m_SanNewsAds["Ads"][k]["minPlayersOnlineToDeliverAds"],
                deliveringSpeed = self.m_SanNewsAds["Ads"][k]["deliveringSpeed"],
                adStartTimeEveryDay = self.m_SanNewsAds["Ads"][k]["adStartTimeEveryDay"],
                adEndTimeEveryDay = self.m_SanNewsAds["Ads"][k]["adEndTimeEveryDay"],
                maxPerDay = self.m_SanNewsAds["Ads"][k]["maxPerDay"]
            }
        end

        triggerServerEvent("sanNewsAdsSaveSettingsForCustomerFromClient", localPlayer, sendTable)

        self.m_ChangesMade = {}
	end

    self.m_ForceAdButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.88, self.m_Width*0.29, self.m_Height*0.07, _"Schaltung erzwingen", self.m_bg):setBarEnabled(true)
    self.m_ForceAdButton.onLeftClick = function() 
        QuestionBoxExtended:new(
            _"Soll die Werbung kostenpflichtig (nur wenn Bedingungen erfüllt sind: wird als reguläre Werbeschaltung gezählt) oder kostenlos geschaltet werden?", _"Kostenpflichtig", _"Kostenlos",
            function()
                if self.m_currentCustomerID then 
                    if tonumber(self.m_currentCustomerID) ~= nil then 
                        triggerServerEvent("sanNewsForceAd", localPlayer, self.m_currentCustomerID, true)
                    end
                end
            end,
            function()
                if self.m_currentCustomerID then 
                    if tonumber(self.m_currentCustomerID) ~= nil then 
                        triggerServerEvent("sanNewsForceAd", localPlayer, self.m_currentCustomerID, false)
                    end
                end
            end
        )
    end
end

function SANNewsAdsOverviewGUI:UpdateAdData(data)
    if data then 
        self.m_SanNewsAds = data 
    else
        return 
    end
    if self.m_currentCustomerID then 
        self:onCustomerChange(self.m_currentCustomerID)
    end
end