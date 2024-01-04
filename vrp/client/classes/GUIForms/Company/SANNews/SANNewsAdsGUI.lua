-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/Company/SANNews/SANNewsAdsGUI.lua
-- *  PURPOSE:     SAN News Ads GUI class
-- *
-- ****************************************************************************
SANNewsAdsGUI = inherit(GUIForm)
inherit(Singleton, SANNewsAdsGUI)

function SANNewsAdsGUI:constructor(customizeAdsTable, customerID)

    if not customizeAdsTable then 
        return
    end
    if not customerID then 
        return
    end
    
    self.m_AdData = customizeAdsTable
    self.m_AdData["customerID"] = customerID
    self.m_ChangesMade = false

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

    self.m_SANNewsAds = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"SAN News", false, true, self)
    self.m_SANNewsAds:addBackButton(function () SANNewsAdsOverviewGUI:getSingleton():show() end)
    self.m_SANNewsAds:deleteOnClose(true)

    self.m_CustomerName = GUILabel:new(self.m_Width*0.05, self.m_Height*0.03, self.m_Width*0.7, self.m_Height*0.1, _"Kunde: " .. self.m_AdData["customerName"], self.m_SANNewsAds)

    GUILabel:new(self.m_Width*0.05, self.m_Height*0.12, self.m_Width*0.8, self.m_Height*0.06, _"Sprache wählen:", self.m_SANNewsAds)
    self.m_AdLanguageChanger = GUIChanger:new(self.m_Width*0.05, self.m_Height*0.18, self.m_Width*0.9, self.m_Height*0.06, self.m_SANNewsAds)
    
    local adLanguages = {"DE", "EN"}
    for i = 1, #adLanguages do 
        self.m_AdLanguageChanger:addItem(adLanguages[i])
    end
    self.m_AdLanguageChanger:setIndex(1)

    self:onAdLanguageChange("DE")

    self.m_AdLanguageChanger.onChange = function ()
        self:onAdLanguageChange(self.m_AdLanguageChanger:getIndex())
    end

    self.m_TheOKButton = GUIButton:new(self.m_Width*0.05, self.m_Height*0.88, self.m_Width*0.28, self.m_Height*0.07, _"Änderungen speichern", self.m_SANNewsAds)
    self.m_TheOKButton.onLeftClick = function()
        self:close()
        if self.m_ChangesMade then
            local sendTable = {
                DE = self.m_AdData["DE"],
                EN = self.m_AdData["EN"],
                customerID = self.m_AdData["customerID"]
            }
            triggerServerEvent("sanNewsGetAdDataFromClient", localPlayer, sendTable)
            self.m_ChangesMade = false
        end
        SANNewsAdsOverviewGUI:getSingleton():show()
        Cursor:show()
	end
end

function SANNewsAdsGUI:onAdLanguageChange(adLanguage)
    if self.m_bg then delete(self.m_bg) end
    self.m_bg = GUIRectangle:new(self.m_Width*0.0, self.m_Height*0.20, self.m_Width*1, self.m_Height*0.65, tocolor(0, 0, 0, 0), self.m_SANNewsAds)

    self.m_AdLineOneLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.05, self.m_Width*0.25, self.m_Height*0.06, _("Werbezeile %s", "1:"), self.m_bg)
        self.m_sanNewsEditLineOne = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.11, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData[adLanguage][1]):setMaxLength(240)
        self.m_sanNewsEditLineOne.onChange = function ()
            self.m_AdData[adLanguage][1] = self.m_sanNewsEditLineOne:getText()
            self.m_ChangesMade = true      
        end
        self.m_AdLineTwoLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.17, self.m_Width*0.25, self.m_Height*0.06, _("Werbezeile %s", "2:"), self.m_bg)
        self.m_sanNewsEditLineTwo = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.23, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData[adLanguage][2]):setMaxLength(240)
        self.m_sanNewsEditLineTwo.onChange = function ()
            self.m_AdData[adLanguage][2] = self.m_sanNewsEditLineTwo:getText()
            self.m_ChangesMade = true
        end
        self.m_AdLineThreeLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.29, self.m_Width*0.25, self.m_Height*0.06, _("Werbezeile %s", "3:"), self.m_bg)
        self.m_sanNewsEditLineThree = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.35, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData[adLanguage][3]):setMaxLength(240)
        self.m_sanNewsEditLineThree.onChange = function ()
            self.m_AdData[adLanguage][3] = self.m_sanNewsEditLineThree:getText()
            self.m_ChangesMade = true
        end
        self.m_AdLineFourLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.41, self.m_Width*0.25, self.m_Height*0.06, _("Werbezeile %s", "4:"), self.m_bg)
        self.m_sanNewsEditLineFour = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.47, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData[adLanguage][4]):setMaxLength(240)
        self.m_sanNewsEditLineFour.onChange = function ()
            self.m_AdData[adLanguage][4] = self.m_sanNewsEditLineFour:getText()
            self.m_ChangesMade = true
        end
        self.m_AdLineFiveLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.53, self.m_Width*0.25, self.m_Height*0.06, _("Werbezeile %s", "5:"), self.m_bg)
        self.m_sanNewsEditLineFive = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.59, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData[adLanguage][5]):setMaxLength(240)
        self.m_sanNewsEditLineFive.onChange = function ()
            self.m_AdData[adLanguage][5] = self.m_sanNewsEditLineFive:getText()
            self.m_ChangesMade = true
        end
end
