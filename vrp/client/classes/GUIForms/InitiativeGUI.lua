InitiativeGUI = inherit(GUIForm)
inherit(Singleton, InitiativeGUI)
addRemoteEvents{"receiveInitiatives"}

function InitiativeGUI:constructor(rangeElement)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 12)
	self.m_Height = grid("y", 9)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true, false, rangeElement)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Wöchentliche Initiative", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_CurrentLabel = GUIGridLabel:new(1, 1, 11, 1, "", self.m_Window):setColor(Color.Accent):setHeader(true)

	self.m_GridList = GUIGridGridList:new(1, 2, 5, 7, self.m_Window)
	self.m_GridList:addColumn(_"Initiativen", 1)

	GUIGridLabel:new(6, 2, 6, 1, _"Beschreibung:", self.m_Window):setAlign("left", "top"):setHeader()
	self.m_DescriptionLabel = GUIGridLabel:new(6, 3, 6, 1, "", self.m_Window):setAlign("left", "top")

	GUIGridLabel:new(6, 5, 6, 1, _"Abgegebene Stimmen:", self.m_Window):setAlign("left", "top"):setHeader()
	self.m_VotesLabel = GUIGridLabel:new(6, 6, 6, 1, "", self.m_Window):setAlign("left", "top")

	self.m_VoteButton = GUIGridButton:new(6, 8, 6, 1, _"Abstimmen", self.m_Window):setBarEnabled(true):setBackgroundColor(Color.Green)
	self.m_VoteButton.onLeftClick = function()
        local item = self.m_GridList:getSelectedItem()
        if not item then
            ErrorBox:new(_"Wähle zuerst eine Initiative aus!")
        else
            triggerServerEvent("registerInitiativeVote", localPlayer, item.Id)
            triggerServerEvent("requestInitiatives", localPlayer)
        end
	end

    self.m_Bind = bind(self.Event_receiveInitiatives, self)
    addEventHandler("receiveInitiatives", localPlayer, self.m_Bind)
    triggerServerEvent("requestInitiatives", localPlayer)
end

function InitiativeGUI:Event_receiveInitiatives(initiatives)
    self.m_GridList:clear()
    self.m_DescriptionLabel:setText(_"Wähle zuerst eine Initiative aus!")
    self.m_VotesLabel:setText(" - ")
    self.m_VoteButton:setVisible(false)

    for id, data in pairs(initiatives) do
        local item = self.m_GridList:addItem(_(data[1]))
        item.Id = id
        item.onLeftClick = function()
			self.m_DescriptionLabel:setText(_(data[2]))
			self.m_VotesLabel:setText(data[4])
            self.m_VoteButton:setVisible(true)
		end

        if data[3] or (id == 1 and self.m_CurrentLabel:getText() == "") then
            self.m_CurrentLabel:setText(_("Aktuell: %s", data[1]))
        end
    end
end

function InitiativeGUI:destructor()
    removeEventHandler("receiveInitiatives", localPlayer, self.m_Bind)
    GUIForm.destructor(self)
end