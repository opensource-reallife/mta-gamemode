-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/SANNews/SANNewsAdsSettingsGUI.lua
-- *  PURPOSE:     SAN News Ads Settings GUI class
-- *
-- ****************************************************************************
SANNewsAdsSettingsGUI = inherit(GUIForm)
inherit(Singleton, SANNewsAdsSettingsGUI)

function SANNewsAdsSettingsGUI:constructor(settings)

    if settings then 
        self.m_Settings = settings
    else
        return
    end

    self.m_ChangesMade = false

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-130, 600, 260)

    self.m_TabPanel = GUITabPanel:new(0, 0, self.m_Width, self.m_Height, self)
	self.m_CloseButton = GUIButton:new(self.m_Width-30, 0, 30, 30, FontAwesomeSymbols.Close, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Red):setHoverColor(Color.White):setFontSize(1)
	self.m_CloseButton.onLeftClick = function() self:close() end

	self.m_BackButton = GUIButton:new(self.m_Width-60, 0, 30, 30, FontAwesomeSymbols.Left, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Accent):setHoverColor(Color.White):setFontSize(1)
	self.m_BackButton.onLeftClick = function() self:close() SANNewsAdsOverviewGUI:getSingleton():show() Cursor:show() end

    GUILabel:new(self.m_Width*0.02, self.m_Height*0.02, self.m_Width*0.8, self.m_Height*0.13, _"Einstellungen", self)
    
    GUILabel:new(self.m_Width*0.02, self.m_Height*0.20, self.m_Width*0.8, self.m_Height*0.1, _"Zeitintervall zwischen einzelnen Werbungen in Minuten:", self)
    
    local adIntervalOptions = {5,10,15,20,30,60,120}
    local theAdIntervalFocusNumber = 0
    self.m_adIntervalChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.31, self.m_Width*0.96, self.m_Height*0.12, self)
    for i = 1, #adIntervalOptions do 
        self.m_adIntervalChanger:addItem(adIntervalOptions[i])
        if adIntervalOptions[i] == self.m_Settings[1] then 
            theAdIntervalFocusNumber = i
        end
    end
    
    self.m_adIntervalChanger:setIndex(theAdIntervalFocusNumber)
    
    self.m_adIntervalChanger.onChange = function()
        self.m_Settings[1] = self.m_adIntervalChanger:getIndex()
        if not self.m_ChangesMade then
            self.m_ChangesMade = true 
        end
    end

    self.m_adsActiveCheckBox = GUICheckbox:new(self.m_Width*0.02, self.m_Height*0.50, self.m_Width*0.35, self.m_Height*0.07, _"Werbesystem aktiv", self)
    if self.m_Settings[2] == 1 then 
        self.m_adsActiveCheckBox:setChecked(true)
    else
        self.m_adsActiveCheckBox:setChecked(false)
    end

    self.m_adsActiveCheckBox.onChange = function (state)
        if state == true then 
            self.m_Settings[2] = 1  
        else
            self.m_Settings[2] = 0
        end
        if not self.m_ChangesMade then
            self.m_ChangesMade = true 
        end
    end

    self.m_saveSettingsButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.75, self.m_Width*0.96, self.m_Height*0.13, _"Speichern", self):setBarEnabled(true)

    self.m_saveSettingsButton.onLeftClick = function ()
        self:close()
        if self.m_ChangesMade then 
            triggerServerEvent("sanNewsAdSettings", localPlayer, self.m_Settings)
        else 
            SANNewsAdsOverviewGUI:getSingleton():show()
            Cursor:show()
        end
    end
end
