QuestManager = inherit(Singleton)

function QuestManager:constructor()
	-- Only add if clientside script is necessary
	self.m_Quests = {
		[2] = QuestPhotography,
		[4] = QuestSantaKill,
		[5] = QuestPhotography,
		[6] = QuestPackageFind,
		[10] = QuestPhotography,
		[11] = QuestPhotography,
	}
	self.m_ShortMessage = {}

	local ped = Ped.create(9, Vector3(1468.11, -1766.50, 18.80), 268)
	ped:setData("NPC:Immortal", true)
	ped:setFrozen(true)
	ped.SpeakBubble = SpeakBubble3D:new(ped, _"Tägliche Aufgabe", _"Klicke mich an!")
	setElementData(ped, "clickable", true)
	ped:setData("onClickEvent", function()
		triggerServerEvent("questShowDaily", localPlayer)
	end)

	addRemoteEvents{"questAddPlayer", "questRemovePlayer", "questOpenGUI"}
	addEventHandler("questAddPlayer", root, bind(self.addPlayer, self))
	addEventHandler("questRemovePlayer", root, bind(self.removePlayer, self))
	addEventHandler("questOpenGUI", root, bind(self.openGUI, self))
end

function QuestManager:addPlayer(questId, name, description, ...)
	self.m_ShortMessage[questId] = ShortMessage:new(_("%s\nKlicke hier um die Quest abzubrechen!", description), _("Quest: %s", name), {150, 0, 0}, -1, function() triggerServerEvent("questShortMessageClick", localPlayer, questId) end)
	if self.m_Quests[questId] then
		self.m_Quests[questId]:new(questId, name, description, ...)
	end
end

function QuestManager:removePlayer(questId)
	if self.m_ShortMessage[questId] then self.m_ShortMessage[questId]:delete() end
	if self.m_Quests[questId] then self.m_Quests[questId]:delete() end
end

function QuestManager:openGUI(questId, name, description, reward)
	QuestGUI:new(questId, name, description, reward)
end
