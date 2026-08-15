QuestManager = inherit(Singleton)

function QuestManager:constructor()
	-- Also add it client side if the quest requires a clientside script
	-- The client side quest automatically starts on startQuestForPlayer if the class is setted on clientside Questmanager
	self.m_QuestData = {
		[1] = {
			["Name"] = "Weihnachts-Bodyguard",
			["Description"] = "Bringe den Weihnachtsmann zum markierten Ort!",
			["Type"] = "Christmas",
			["Class"] = QuestNPCTransport,
			["Reward"] = { {"Päckchen", 7}, {"Zuckerstange", 10}, {"Punkte", 200} }
		},
		[2] = {
			["Name"] = "Weihnachtsmann-Foto",
			["Description"] = "Finde den Weihnachtsmann in Los Santos und schieße ein Foto von ihm!",
			["Type"] = "Christmas",
			["Class"] = QuestPhotography,
			["Reward"] = { {"Päckchen", 5}, {"Zuckerstange", 7}, {"Punkte", 100} }
		},
		[3] = {
			["Name"] = "Päckchen-Transport",
			["Description"] = "Liefere die Päckchen an den angezeigten Ort! Pass gut auf den Anhänger auf!",
			["Type"] = "Christmas",
			["Class"] = QuestPackageTransport,
			["Reward"] = { {"Päckchen", 7}, {"Zuckerstange", 10}, {"Punkte", 200} }
		},
		[4] = {
			["Name"] = "Weihnachts-Morde",
			["Description"] = "Suche die Einbrecher in den orange markierten Gegenden und bringe sie um!",
			["Type"] = "Christmas",
			["Class"] = QuestSantaKill,
			["Reward"] = { {"Päckchen", 10}, {"Zuckerstange", 15}, {"Punkte", 300} }
		},
		[5] = {
			["Name"] = "Fotograf",
			["Description"] = "Schieße ein Foto mit mindestens einem Spieler darauf!",
			["Class"] = QuestPhotography,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100} }
		},
		[6] = {
			["Name"] = "Päckchen-Finder",
			["Description"] = "Finde fünf Päckchen und klicke diese an!",
			["Type"] = "Christmas",
			["Class"] = QuestPackageFind,
			["Reward"] = { {"Päckchen", 5}, {"Zuckerstange", 7}, {"Punkte", 150} }
		},
		[7] = {
			["Name"] = "Glücksrad-Master",
			["Description"] = "Drehe drei mal an einem Glücksrad!",
			["Type"] = "Christmas",
			["Class"] = QuestFortuneWheel,
			["Reward"] = { {"Päckchen", 3}, {"Zuckerstange", 5}, {"Punkte", 100} }
		},
		[8] = {
			["Name"] = "Feierabend",
			["Description"] = "Heute gibt es nichts zu erledigen! Hier deine Belohnung!",
			["Class"] = QuestNoQuest,
			["Reward"] = { {"Dollar", 500}, {"Punkte", 50} }
		},
		[9] = {
			["Name"] = "Riesenradfahrer",
			["Description"] = "Fahre mit dem Riesenrad, bis die Gondel wieder an den Treppen anhält!",
			["Class"] = QuestFerrisRide,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100} }
		},
		[10] = {
			["Name"] = "Mützen-Fotograf",
			["Description"] = "Schieße ein Foto mit mindestens einem Spieler, der eine Weihnachtsmütze trägt!",
			["Type"] = "Christmas",
			["Class"] = QuestPhotography,
			["Reward"] = { {"Päckchen", 5}, {"Zuckerstange", 7}, {"Punkte", 150} }
		},
		[11] = {
			["Name"] = "Team-Fotograf",
			["Description"] = "Schieße ein Foto mit mindestens einem Teammitglied!",
			["Class"] = QuestPhotography,
			["Reward"] = { {"Dollar", 1500}, {"Punkte", 150} }
		},
		[12] = {
			["Name"] = "Gärtner",
			["Description"] = "Pflanze fünf Pflanzen an!",
			["Class"] = QuestGrowablePlant,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100}, {"Apfelbaum-Samen", 2}, {"Weed-Samen", 2}, {"Blumen-Samen", 1} }
		},
		[13] = {
			["Name"] = "Spielsüchtig",
			["Description"] = "Spiele drei mal an einem Spielautomaten im Casino!",
			["Class"] = QuestSlotmachine,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100} }
		},
		[14] = {
			["Name"] = "Angler",
			["Description"] = "Stelle deine Angelfähigkeiten unter Beweis und angle zehn Fische!",
			["Class"] = QuestFishing,
			["Reward"] = { {"Dollar", 1500}, {"Punkte", 150}, {"Köder", 10} }
		},
		[15] = {
			["Name"] = "Tourist",
			["Description"] = "Besuche den markierten Ort auf der Karte!",
			["Class"] = QuestSightseeing,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100} }
		},
		[16] = {
			["Name"] = "Guter Samariter",
			["Description"] = "Gib einem Obdachlosen etwas zu essen!",
			["Class"] = QuestBeggarHelp,
			["Reward"] = { {"Dollar", 1000}, {"Punkte", 100}, {"Zigarettenpackung", 1} }
		}
	}

	addRemoteEvents{"questStartClick", "questShortMessageClick", "questShowDaily"}
	addEventHandler("questStartClick", root, bind(self.onStartClick, self))
	addEventHandler("questShortMessageClick", root, bind(self.onShortMessageClick, self))
	addEventHandler("questShowDaily", root, bind(self.showDaily, self))

	PlayerManager:getSingleton():getQuitHook():register(bind(self.onPlayerQuit, self))
	PlayerManager:getSingleton():getWastedHook():register(bind(self.onPlayerQuit, self))
	PlayerManager:getSingleton():getAFKHook():register(bind(self.onPlayerQuit, self))

	self.m_Quests = {}
	for questId, questData in ipairs(self.m_QuestData) do
		if questData["Type"] == "Christmas" and not EVENT_CHRISTMAS_MARKET then
		else
			self.m_Quests[questId] = questData["Class"]:new(questId, questData)
		end
	end
	self.m_DailyQuest = Randomizer:getRandomTableValue(self.m_Quests).m_QuestId
	self.m_QuestProgress = {}
	self.m_LastShown = {}
end

function QuestManager:startQuestForPlayer(questId, player)
	if not self.m_Quests[questId] then
		return false
	end

	if table.find(self.m_Quests[questId]:getPlayers(), player) then
		player:sendError(_("Du hast die Quest bereits gestartet!", player))
		return
	end

	if self.m_Quests[questId]:isQuestDone(player) then
		player:sendError(_("Du hast die Quest bereits abgeschlossen!", player))
		return
	end

	local currentQuest = self.m_LastShown[player]
	if currentQuest and currentQuest == questId then
		self.m_Quests[questId]:addPlayer(player)
	end
end

function QuestManager:endQuestForPlayer(questId, player)
	self.m_Quests[questId]:removePlayer(player)
end

function QuestManager:onStartClick(questId)
	if not self.m_Quests[questId] then
		client:sendError(_("Quest nicht verfügbar!", client))
		return false
	end
	self:startQuestForPlayer(questId, client)
end

function QuestManager:showQuest(questId, player)
	if not self.m_Quests[questId] then
		player:sendError(_("Quest nicht verfügbar!", player))
		return false
	end
	self.m_LastShown[player] = questId
	self.m_Quests[questId]:onClick(player)
end

function QuestManager:showDaily(player)
	if not player then player = client end
	self:showQuest(self.m_DailyQuest, player)
end

function QuestManager:onShortMessageClick(questId)
	QuestionBox:new(client, _("Möchtest du die Quest '%s' abbrechen? Du kannst sie jederzeit wieder starten.", client, _(self.m_Quests[questId].m_Name, client)),
	function()
		self:endQuestForPlayer(questId, client)
	end,
	function()
		self:endQuestForPlayer(questId, client)
		self:startQuestForPlayer(questId, client)
	end)
end

function QuestManager:onPlayerQuit(player)
	for questId, quest in pairs(self.m_Quests) do
		if table.find(quest:getPlayers(), player) then
			self:endQuestForPlayer(questId, player)
		end
	end
	self.m_LastShown[player] = nil
end