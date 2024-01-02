-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/SANNews/SANNewsAdsGUI.lua
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

    GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

	self.m_TabPanel = GUITabPanel:new(0, 0, self.m_Width, self.m_Height, self)
	self.m_CloseButton = GUIButton:new(self.m_Width-30, 0, 30, 30, FontAwesomeSymbols.Close, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Red):setHoverColor(Color.White):setFontSize(1)
	self.m_CloseButton.onLeftClick = function() self:close() end

	self.m_BackButton = GUIButton:new(self.m_Width-60, 0, 30, 30, FontAwesomeSymbols.Left, self):setFont(FontAwesome(20)):setBarEnabled(false):setBackgroundColor(Color.Clear):setBackgroundHoverColor(Color.Accent):setHoverColor(Color.White):setFontSize(1)
	self.m_BackButton.onLeftClick = function() self:close() SANNewsAdsOverviewGUI:getSingleton():show() Cursor:show() end

    self.m_CustomerName = GUILabel:new(self.m_Width*0.05, self.m_Height*0.03, self.m_Width*0.7, self.m_Height*0.1, _"Kunde: " .. self.m_AdData["customerName"], self)

    GUILabel:new(self.m_Width*0.05, self.m_Height*0.12, self.m_Width*0.8, self.m_Height*0.06, _"Sprache wählen:", self)
    self.m_AdLanguageChanger = GUIChanger:new(self.m_Width*0.05, self.m_Height*0.18, self.m_Width*0.9, self.m_Height*0.06, self)
    
    local adLanguages = {"DE", "EN"}
    for i = 1, #adLanguages do 
        self.m_AdLanguageChanger:addItem(adLanguages[i])
    end
    self.m_AdLanguageChanger:setIndex(1)

    self:onAdLanguageChange("DE")

    self.m_AdLanguageChanger.onChange = function ()
        self:onAdLanguageChange(self.m_AdLanguageChanger:getIndex())
    end

    self.m_TheOKButton = GUIButton:new(self.m_Width*0.05, self.m_Height*0.88, self.m_Width*0.28, self.m_Height*0.07, _"Änderungen speichern", self)
    self.m_TheOKButton.onLeftClick = function()
        self:close()
        local sendTable = {
            DE = self.m_AdData["DE"],
            EN = self.m_AdData["EN"],
            customerID = self.m_AdData["customerID"]
        }
        triggerServerEvent("sanNewsGetAdDataFromClient", localPlayer, sendTable)
        SANNewsAdsOverviewGUI:getSingleton():show()
        Cursor:show()
	end
end

function SANNewsAdsGUI:onAdLanguageChange(adLanguage)
    if self.m_bg then delete(self.m_bg) end
    self.m_bg = GUIRectangle:new(self.m_Width*0.0, self.m_Height*0.20, self.m_Width*1, self.m_Height*0.65, tocolor(0, 0, 0, 0), self)

    if adLanguage == "DE" then 
        self.m_AdLineOneLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.05, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "1:", self.m_bg)
        self.m_sanNewsEditLineOne = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.11, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["DE"][1]):setMaxLength(240)
        self.m_sanNewsEditLineOne.onChange = function ()
            self.m_AdData["DE"][1] = self.m_sanNewsEditLineOne:getText()       
        end
        self.m_AdLineTwoLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.17, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "2:", self.m_bg)
        self.m_sanNewsEditLineTwo = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.23, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["DE"][2]):setMaxLength(240)
        self.m_sanNewsEditLineTwo.onChange = function ()
            self.m_AdData["DE"][2] = self.m_sanNewsEditLineTwo:getText()       
        end
        self.m_AdLineThreeLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.29, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "3:", self.m_bg)
        self.m_sanNewsEditLineThree = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.35, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["DE"][3]):setMaxLength(240)
        self.m_sanNewsEditLineThree.onChange = function ()
            self.m_AdData["DE"][3] = self.m_sanNewsEditLineThree:getText()       
        end
        self.m_AdLineFourLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.41, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "4:", self.m_bg)
        self.m_sanNewsEditLineFour = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.47, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["DE"][4]):setMaxLength(240)
        self.m_sanNewsEditLineFour.onChange = function ()
            self.m_AdData["DE"][4] = self.m_sanNewsEditLineFour:getText()       
        end
        self.m_AdLineFiveLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.53, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "5:", self.m_bg)
        self.m_sanNewsEditLineFive = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.59, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["DE"][5]):setMaxLength(240)
        self.m_sanNewsEditLineFive.onChange = function ()
            self.m_AdData["DE"][5] = self.m_sanNewsEditLineFive:getText()       
        end
    elseif adLanguage == "EN" then 
        self.m_AdLineOneLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.05, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "1:", self.m_bg)
        self.m_sanNewsEditLineOne = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.11, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["EN"][1]):setMaxLength(240)
        self.m_sanNewsEditLineOne.onChange = function ()
            self.m_AdData["EN"][1] = self.m_sanNewsEditLineOne:getText()       
        end
        self.m_AdLineTwoLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.17, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "2:", self.m_bg)
        self.m_sanNewsEditLineTwo = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.23, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["EN"][2]):setMaxLength(240)
        self.m_sanNewsEditLineTwo.onChange = function ()
            self.m_AdData["EN"][2] = self.m_sanNewsEditLineTwo:getText()       
        end
        self.m_AdLineThreeLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.29, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "3:", self.m_bg)
        self.m_sanNewsEditLineThree = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.35, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["EN"][3]):setMaxLength(240)
        self.m_sanNewsEditLineThree.onChange = function ()
            self.m_AdData["EN"][3] = self.m_sanNewsEditLineThree:getText()       
        end
        self.m_AdLineFourLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.41, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "4:", self.m_bg)
        self.m_sanNewsEditLineFour = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.47, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["EN"][4]):setMaxLength(240)
        self.m_sanNewsEditLineFour.onChange = function ()
            self.m_AdData["EN"][4] = self.m_sanNewsEditLineFour:getText()       
        end
        self.m_AdLineFiveLabel = GUILabel:new(self.m_Width*0.05, self.m_Height*0.53, self.m_Width*0.25, self.m_Height*0.06, _"Werbezeile " .. "5:", self.m_bg)
        self.m_sanNewsEditLineFive = GUIEdit:new(self.m_Width*0.05, self.m_Height*0.59, self.m_Width * 0.9, self.m_Height*0.05, self.m_bg):setText(self.m_AdData["EN"][5]):setMaxLength(240)
        self.m_sanNewsEditLineFive.onChange = function ()
            self.m_AdData["EN"][5] = self.m_sanNewsEditLineFive:getText()       
        end
    else
        return
    end
end
