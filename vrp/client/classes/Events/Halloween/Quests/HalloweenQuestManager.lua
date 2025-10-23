-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/HalloweenQuestManager.lua
-- *  PURPOSE:     Halloween Quest Manager
-- *
-- ****************************************************************************

HalloweenQuestManager = inherit(Singleton)
addRemoteEvents{"Halloween:sendQuestState"}

function HalloweenQuestManager:constructor()
    addEventHandler("Halloween:sendQuestState", root, bind(self.receiveQuestState, self))

	self.m_QuestPed = Ped.create(14, 930.69, -1123.8, 23.98)
	self.m_QuestPed:setData("NPC:Immortal", true)
	self.m_QuestPed:setFrozen(true)
	self.m_QuestPed.SpeakBubble = SpeakBubble3D:new(self.m_QuestPed, "Halloween", _"Geschichten vergangener Zeit")
	self.m_QuestPed.SpeakBubble:setBorderColor(Color.Orange)
	self.m_QuestPed.SpeakBubble:setTextColor(Color.Orange)
	setElementData(self.m_QuestPed, "clickable", true)
	self.m_QuestPed:setData("onClickEvent", 
		function()
			HalloweenQuestManager:getSingleton():requestQuestState()
		end
	)

    -- Ghost Cleaner Questline
	addEventHandler("onClientPlayerWeaponSwitch", root, bind(self.onClientPlayerWeaponSwitch, self))
	addEventHandler("onClientPlayerWeaponFire", root, bind(self.onClientPlayerWeaponFire, self))

	self.m_Quests = {
		ZombieSurvivalQuest,
		GhostFinderQuest,
		GhostKillerQuest,
		BigSmokeQuest,
		KillBigSmokeQuest,
		GhostMeetingQuest,
		TotemQuest,
		TotemCleanseQuest,
		PriestQuest,
	}

	self.m_WastedBind = bind(self.abortQuest, self)

    CustomModelManager:getSingleton():loadImportTXD("files/models/events/halloween/shotgspa.txd", 362)
	CustomModelManager:getSingleton():loadImportDFF("files/models/events/halloween/shotgspa.dff", 362)
	WEAPON_NAMES[38] = "Geistvertreiber"
end

function HalloweenQuestManager:requestQuestState()
	if not self.m_Quest then
		triggerServerEvent("Halloween:requestQuestState", localPlayer)
	else
		if self.m_Quest:isSucceeded() then
			self.m_Quest:endQuest()
			delete(self.m_Quest)
			self.m_Quest = nil
			triggerServerEvent("Halloween:requestQuestUpdate", localPlayer, self.m_QuestState+1)
			removeEventHandler("onClientPlayerWasted", localPlayer, self.m_WastedBind)
		else
			DialogGUI:new(false,
				"Wie läuft es mit der Aufgabe, die ich dir gegeben habe?"
			)
		end
	end
end

function HalloweenQuestManager:receiveQuestState(quest)
	self.m_QuestState = quest
	self:startQuest(self.m_QuestState)
end

function HalloweenQuestManager:startQuest()
	local day = getRealTime().yearday - EVENT_HALLOWEEN_START_DAY
	local questId = self.m_QuestState + 1
	local quest = self.m_Quests[questId]

	if not quest then
		DialogGUI:new(false,
			"Merkwürdig diese Ereignisse hier, nicht wahr?",
			"Naja, danke für all deine Hilfe!"
		)
		return
	elseif day < questId - 1 then
		DialogGUI:new(false,
			"Ich glaube es ist noch nicht vorbei...",
			"Komme doch morgen wieder!"
		)
		return
	end

	self.m_Quest = quest:new()
	self.m_Quest:startQuest()
	addEventHandler("onClientPlayerWasted", localPlayer, self.m_WastedBind)
end

function HalloweenQuestManager:abortQuest()
	if self.m_Quest and not self.m_Quest.m_IgnoreWasted then
		delete(self.m_Quest)
		self.m_Quest = nil
		ErrorBox:new(_"Quest fehlgeschlagen!")
		removeEventHandler("onClientPlayerWasted", localPlayer, self.m_WastedBind)
	end
end

function HalloweenQuestManager:onClientPlayerWeaponSwitch(prevSlot, newSlot)
    local worldSoundsToDisable = {11, 12, 13, 14, 15, 16, 19, 20, 63}
	if getPedWeapon(localPlayer, newSlot) == 38 then
		for key, worldSound in ipairs(worldSoundsToDisable) do
			setWorldSoundEnabled(5, worldSound, false)
		end
	else
		for key, worldSound in ipairs(worldSoundsToDisable) do
			setWorldSoundEnabled(5, worldSound, true)
		end
	end
end

function HalloweenQuestManager:onClientPlayerWeaponFire(weapon)
	if weapon == 38 then
		local x, y, z = getPedWeaponMuzzlePosition(source)
		local sound = playSound3D("files/audio/halloween/laser.mp3", x, y, z)
		sound:setMaxDistance(75)
		sound:setVolume(2)
		sound:setDimension(source:getDimension())
	end
end