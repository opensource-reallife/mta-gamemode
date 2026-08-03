QuestGUI = inherit(GUIForm)
inherit(Singleton, QuestGUI)

function QuestGUI:constructor(questId, name, description, reward)
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 9)
	self.m_Height = grid("y", 8)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true, false, localPlayer.position)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _("Quest: %s", name), true, true, self)
	self.m_Window:deleteOnClose(true)

	local rewardString = ""
	outputDebugString(reward)
	for k, v in ipairs(reward) do
		rewardString = rewardString .. v[2] .. " " .. _(v[1])
		if reward[k+1] then
			rewardString = rewardString .. ", "
		end
	end

	GUIGridLabel:new(1, 1, 8, 1, _"Beschreibung", self.m_Window):setAlign("left", "top"):setHeader()
	GUIGridLabel:new(1, 2, 8, 1, description, self.m_Window):setAlign("left", "top")
	GUIGridLabel:new(1, 4, 8, 1, _"Belohnung", self.m_Window):setAlign("left", "top"):setHeader()
	GUIGridLabel:new(1, 5, 8, 1, rewardString, self.m_Window):setAlign("left", "top")

	self.m_StartQuest = GUIGridButton:new(1, 7, 8, 1, _"Quest starten", self.m_Window)
	self.m_StartQuest.onLeftClick = function()
		triggerServerEvent("questStartClick", localPlayer, questId)
		delete(self)
	end
end