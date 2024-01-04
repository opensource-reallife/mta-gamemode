-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Company/SANNews/SANNewsAdsNewCustomerGUI.lua
-- *  PURPOSE:     SAN News Ads New Customer GUI class
-- *
-- ****************************************************************************
SANNewsAdsNewCustomerGUI = inherit(GUIForm)
inherit(Singleton, SANNewsAdsNewCustomerGUI)

addRemoteEvents{"sanNewsAdsReceiveSearchedPlayers", "sanNewsAdsReceiveSearchedGroups"}

function SANNewsAdsNewCustomerGUI:constructor(theCurrentCustomers)
    addEventHandler("sanNewsAdsReceiveSearchedPlayers", root,
    function(resultPlayers)
        self:insertSearchResult(resultPlayers)
    end
    )
    
    addEventHandler("sanNewsAdsReceiveSearchedGroups", root,
    function(resultGroups)
        self:insertSearchResultGroup(resultGroups)
    end
    )

    if theCurrentCustomers then 
        self.m_currentCustomers = theCurrentCustomers 
    else
        return
    end

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

    self.m_SANNewsNewCustomer = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"SAN News", false, true, self)
    self.m_SANNewsNewCustomer:addBackButton(function () SANNewsAdsOverviewGUI:getSingleton():show() end)
    self.m_SANNewsNewCustomer:deleteOnClose(true)

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.11, _"Kunde hinzufügen", self.m_SANNewsNewCustomer)
    GUILabel:new(self.m_Width*0.02, self.m_Height*0.15, self.m_Width*0.8, self.m_Height*0.07, _"Kundentyp wählen:", self.m_SANNewsNewCustomer)
    self.m_typeOfCustomer = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.22, self.m_Width*0.96, self.m_Height*0.06, self.m_SANNewsNewCustomer)
    local customerTypes = {"Faction","Company","Group","Player"}

    for i=1, #customerTypes do 
        self.m_typeOfCustomer:addItem(customerTypes[i])
	end
    self.m_typeOfCustomer:setIndex(1)
    
    self:onCustomerTypeChange("Faction")

    self.m_typeOfCustomer.onChange = function ()
        local k = self.m_typeOfCustomer:getIndex()
        self:onCustomerTypeChange(k)
    end
end

function SANNewsAdsNewCustomerGUI:onCustomerTypeChange(customerType)

    if self.m_bg then delete(self.m_bg) end
    self.m_bg = GUIRectangle:new(self.m_Width*0.0, self.m_Height*0.30, self.m_Width*1, self.m_Height*0.70, tocolor(0, 0, 0, 0), self.m_SANNewsNewCustomer)

    if customerType == "Faction" then 
        GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.07, _"Fraktion wählen:", self.m_bg)
        self.m_factionChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width*0.96, self.m_Height*0.06, self.m_bg)

        local factionList = FactionManager:getSingleton():getFactionNames()
        for k, v in pairs(factionList) do 
            self.m_factionChanger:addItem(factionList[k])
        end
        self.m_factionChanger:setIndex(1)

        local currentName = self.m_factionChanger:getIndex()
        self.m_currentFaction = FactionManager:getSingleton():getFromName(currentName)
        self.m_factionID = self.m_currentFaction:getId()

        self.m_factionChanger.onChange = function ()
            local currentName = self.m_factionChanger:getIndex()
            self.m_currentFaction = FactionManager:getSingleton():getFromName(currentName)
            self.m_factionID = self.m_currentFaction:getId()
        end

        self.m_factionButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.55, self.m_Width*0.96, self.m_Height*0.07, _"Kunde hinzufügen", self.m_bg)
        self.m_factionButton.onLeftClick = function ()
            for k, v in pairs(self.m_currentCustomers) do 
                if self.m_factionID == self.m_currentCustomers[k]["customerUniqueID"] and self.m_currentCustomers[k]["customerType"] == "Faction" then 
                    ErrorBox:new(_"Die gewählte Fraktion ist bereits Kunde.")
                    return
                end
            end
            triggerServerEvent("sanNewsCreateNewCustomerFromClient", localPlayer, "Faction", self.m_factionID)
            self:close()
        end

    elseif customerType == "Company" then 
        self.m_companyID = false 
        self.m_companyName = false

        GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.07, _"Unternehmen wählen:", self.m_bg)
        self.m_companyChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width*0.96, self.m_Height*0.06, self.m_bg)
        
        local companyList = CompanyManager:getSingleton():getCompanyNames()
        for k, v in ipairs(companyList) do 
            self.m_companyChanger:addItem(companyList[k])
        end
        self.m_companyChanger:setIndex(1)
        
        local currentName = self.m_companyChanger:getIndex()
        self.m_currentCompany = CompanyManager:getSingleton():getFromName(currentName)
        self.m_companyID = self.m_currentCompany:getId()

        self.m_companyChanger.onChange = function ()
            local currentName = self.m_companyChanger:getIndex()
            self.m_currentCompany = CompanyManager:getSingleton():getFromName(currentName)
            self.m_companyID = self.m_currentCompany:getId()
        end

        self.m_companyButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.55, self.m_Width*0.96, self.m_Height*0.07, _"Kunde hinzufügen", self.m_bg)
        self.m_companyButton.onLeftClick = function ()
            for k, v in pairs(self.m_currentCustomers) do 
                if self.m_companyID == self.m_currentCustomers[k]["customerUniqueID"] and self.m_currentCustomers[k]["customerType"] == "Company" then 
                    ErrorBox:new(_"Das gewählte Unternehmen ist bereits Kunde.")
                    return
                end
            end
            triggerServerEvent("sanNewsCreateNewCustomerFromClient", localPlayer, "Company", self.m_companyID)
            self:close()
        end

    elseif customerType == "Group" then 
        self.m_groupID = false

        GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.96, self.m_Height*0.07, _"Suche nach einer Firma/Gang (mind. 3 Buchstaben eingeben):", self.m_bg)
        
        self.m_groupList = GUIGridList:new(self.m_Width*0.02, self.m_Height*0.16, self.m_Width*0.8, self.m_Height*0.4, self.m_bg)
 	    self.m_groupList:addColumn(_"Gefundene Firmen/Gangs:", 1)

        self.m_groupButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.6, self.m_Width*0.96, self.m_Height*0.07, _"Kunde hinzufügen", self.m_bg)
        self.m_groupButton:setEnabled(false)
        
        self.m_groupSearchField = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width * 0.8, self.m_Height*0.06, self.m_bg)

        self.m_groupSearchButton = GUIButton:new(self.m_Width*0.85, self.m_Height*0.09, self.m_Width*0.1, self.m_Height*0.06, _"Suche", self.m_bg)

        self.m_groupSearchButton.onLeftClick = function ()
            if #self.m_groupSearchField:getText() >= 3 then
                triggerServerEvent("SanNewsAdsSearchGroup", localPlayer, self.m_groupSearchField:getText())
            else
                ErrorBox:new(_"Weniger als 3 Zeichen in der Suchzeile eingegeben.")
            end
        end

        self.m_groupButton.onLeftClick = function() 
            for k, v in pairs(self.m_currentCustomers) do 
                if self.m_groupID == self.m_currentCustomers[k]["customerUniqueID"] and self.m_currentCustomers[k]["customerType"] == "Group" then 
                    ErrorBox:new(_"Die gewählte Gruppe ist bereits Kunde.")
                    return
                end
            end
            triggerServerEvent("sanNewsCreateNewCustomerFromClient", localPlayer, "Group", self.m_groupID)
            self:close()
        end

    elseif customerType == "Player" then 
        self.m_playerID = false

        GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.96, self.m_Height*0.07, _"Suche nach einem Spieler (mind. 3 Buchstaben eingeben):", self.m_bg)
        
        self.m_playerList = GUIGridList:new(self.m_Width*0.02, self.m_Height*0.16, self.m_Width*0.8, self.m_Height*0.4, self.m_bg)
 	    self.m_playerList:addColumn(_"Gefundene Spieler:", 1)

        self.m_playerButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.6, self.m_Width*0.96, self.m_Height*0.07, _"Kunde hinzufügen", self.m_bg)
        self.m_playerButton:setEnabled(false)
        
        self.m_playerSearchField = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.09, self.m_Width * 0.8, self.m_Height*0.06, self.m_bg)

        self.m_playerSearchButton = GUIButton:new(self.m_Width*0.85, self.m_Height*0.09, self.m_Width*0.1, self.m_Height*0.06, _"Suche", self.m_bg)

        self.m_playerSearchButton.onLeftClick = function ()
            if #self.m_playerSearchField:getText() >= 3 then
                triggerServerEvent("SanNewsAdsSearchPlayer", localPlayer, self.m_playerSearchField:getText())
            else
                ErrorBox:new(_"Weniger als 3 Zeichen in der Suchzeile eingegeben.")
            end
        end

        self.m_playerButton.onLeftClick = function ()
            for k, v in pairs(self.m_currentCustomers) do 
                if self.m_playerID == self.m_currentCustomers[k]["customerUniqueID"] and self.m_currentCustomers[k]["customerType"] == "Player" then 
                    ErrorBox:new(_"Der gewählte Spieler ist bereits Kunde.")
                    return
                end
            end
            triggerServerEvent("sanNewsCreateNewCustomerFromClient", localPlayer, "Player", self.m_playerID)
            self:close()
        end
    else
    end
end

function SANNewsAdsNewCustomerGUI:insertSearchResultGroup(resultGroups)
	if not self.m_groupList then return end
    self.m_groupList:clear()
    for index, pname in pairs(resultGroups) do
		local item = self.m_groupList:addItem(pname)
		item.name = pname
		item.onLeftClick = function ()
            self.m_groupID = index 
            self.m_groupButton:setEnabled(true)
		end
	end
end

function SANNewsAdsNewCustomerGUI:insertSearchResult(resultPlayers)
	if not self.m_playerList then return end
    self.m_playerList:clear()
    for index, pname in pairs(resultPlayers) do
		local item = self.m_playerList:addItem(pname)
		item.name = pname
		item.onLeftClick = function ()
            self.m_playerID = index 
            self.m_playerButton:setEnabled(true)
		end
	end
end
