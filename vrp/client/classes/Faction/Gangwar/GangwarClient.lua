-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/GangwarAttack.lua
-- *  PURPOSE:     Gangwar Client Class
-- *
-- ****************************************************************************
GangwarClient = inherit(Singleton)
addRemoteEvents{"Gangwar:enterWorld", "Gangwar:leaveWorld", "GangwarPick:status", "GangwarPick:statusClose", "GangwarMenu:open", "Gangwar:requestQuestion", "Gangwar:requestClose", "GangwarNpc:open", "GangwarPick:open", "GangwarVehicle:open", "GangwarVehicle:close"}

GANGWAR_ATTACK_PAUSE = 1
UNIX_TIMESTAMP_24HRS = 86400

local REPLACED_MODELS = {
	{model = 4012, dff = ":floors-los-santos/4012.dff"},
	{model = 3983, dff = ":floors-los-santos/3983.dff", col = ":floors-los-santos/3983.col"},
}

function GangwarClient:constructor()
	self.m_Questions = {}
	self.m_ServerRemovals = {}
	addEventHandler("Gangwar:enterWorld", localPlayer, bind(self.Event_enterWorld, self))
	addEventHandler("Gangwar:leaveWorld", localPlayer, bind(self.Event_leaveWorld, self))
	addEventHandler("GangwarPick:status", localPlayer, bind(self.Event_pickStatus, self))
	addEventHandler("GangwarPick:statusClose", localPlayer, bind(self.Event_pickStatusClose, self))
	addEventHandler("GangwarMenu:open", localPlayer, bind(self.Event_openMenu, self))
	addEventHandler("Gangwar:requestQuestion", localPlayer, bind(self.Event_requestQuestion, self))
	addEventHandler("Gangwar:requestClose", localPlayer, bind(self.Event_requestClose, self))
	addEventHandler("GangwarNpc:open", localPlayer, bind(self.Event_openNpc, self))
	addEventHandler("GangwarPick:open", localPlayer, bind(self.Event_openPick, self))
	addEventHandler("GangwarVehicle:open", localPlayer, bind(self.Event_openVehicles, self))
	addEventHandler("GangwarVehicle:close", localPlayer, bind(self.Event_closeVehicles, self))
end

function GangwarClient:Event_enterWorld(list)
	if list then
		self.m_ServerRemovals = list
	end
	if self.m_RestoredModels then return end

	self.m_RestoredModels = {}
	for key, entry in ipairs(self.m_ServerRemovals) do
		self.m_RestoredModels[#self.m_RestoredModels + 1] = entry
	end
	for key, entry in ipairs(WorldModelRegistry.getOutdoorEntries()) do
		self.m_RestoredModels[#self.m_RestoredModels + 1] = entry
	end
	for key, entry in ipairs(self.m_RestoredModels) do
		WorldModelRegistry.RawRestore(entry[1], entry[2], entry[3], entry[4], entry[5], entry[6])
	end
	self:restoreReplacedModels()
end

function GangwarClient:restoreReplacedModels()
	local resource = getResourceFromName("floors-los-santos")
	if not resource or getResourceState(resource) ~= "running" then return end

	self.m_RestoredReplacedModels = {}
	for key, entry in ipairs(REPLACED_MODELS) do
		entry.dffElement = entry.dffElement or engineLoadDFF(entry.dff)
		if entry.col then
			entry.colElement = entry.colElement or engineLoadCOL(entry.col)
		end
		if entry.dffElement and (not entry.col or entry.colElement) then
			if entry.col then
				engineRestoreCOL(entry.model)
			end
			engineRestoreModel(entry.model)
			table.insert(self.m_RestoredReplacedModels, entry)
		end
	end
end

function GangwarClient:applyReplacedModels()
	for key, entry in ipairs(self.m_RestoredReplacedModels or {}) do
		engineReplaceModel(entry.dffElement, entry.model, true)
		if entry.colElement then
			engineReplaceCOL(entry.colElement, entry.model)
		end
	end
	self.m_RestoredReplacedModels = nil
end

function GangwarClient:Event_leaveWorld()
	if not self.m_RestoredModels then return end
	for key, entry in ipairs(self.m_RestoredModels) do
		WorldModelRegistry.RawRemove(entry[1], entry[2], entry[3], entry[4], entry[5], entry[6])
	end
	self.m_RestoredModels = nil
	self:applyReplacedModels()
	self:Event_closeVehicles()
end

function GangwarClient:updatePickedMessage(status, isPicked, isEntered)
	if not isPicked then
		self:closePickedMessage()
		return
	end
	local text = isEntered and _("Du bist im Gangwar um %s dabei. Warte auf den Start der Attackphase!", status.area) or _("Du bist für den Gangwar im Gebiet %s eingeteilt. Melde dich beim Gangwar-NPC deiner Fraktion!", status.area)
	if self.m_PickedMessage then
		self.m_PickedMessage:setText(text)
	else
		self.m_PickedMessage = ShortMessage:new(text, "Gangwar", nil, -1, nil, nil, nil, nil, true)
	end
end

function GangwarClient:closePickedMessage()
	if self.m_PickedMessage then
		delete(self.m_PickedMessage)
		self.m_PickedMessage = nil
	end
end

function GangwarClient:Event_pickStatus(status, isPicked, isEntered)
	self:updatePickedMessage(status, isPicked, isEntered)
	local text = _"Klicken zum Öffnen (F4)"
	if #status.entries == 0 then
		text = text .. "\n• " .. _"Noch niemand eingeteilt"
	end
	for key, entry in ipairs(status.entries) do
		text = text .. ("\n• %s%s"):format(entry.name, entry.entered and _" (dabei)" or "")
	end
	if not self.m_PickMessage then
		self.m_PickMessage = ShortMessage:new(text, _("Einteilung - %s", status.area), tocolor(140, 40, 0), -1, function()
			triggerServerEvent("Gangwar:requestPickData", localPlayer)
		end, nil, nil, nil, true)
	else
		self.m_PickMessage:setText(text)
	end
end

function GangwarClient:Event_pickStatusClose()
	self:closePickedMessage()
	if self.m_PickMessage then
		delete(self.m_PickMessage)
		self.m_PickMessage = nil
	end
	if GangwarPickGUI.Current then
		delete(GangwarPickGUI.Current)
	end
end

function GangwarClient:toggleMenu()
	local isOpen = false
	for key, gui in ipairs({GangwarMenuGUI, GangwarVehicleGUI, GangwarPickGUI}) do
		if gui.Current then
			delete(gui.Current)
			isOpen = true
		end
	end
	if not isOpen then
		triggerServerEvent("Gangwar:requestMenu", localPlayer)
	end
end

function GangwarClient:Event_openMenu(info)
	if GangwarMenuGUI.Current then
		delete(GangwarMenuGUI.Current)
	end
	GangwarMenuGUI.Current = GangwarMenuGUI:new(info)
end

function GangwarClient:Event_requestQuestion(id, text, timeout)
	self:Event_requestClose(id)
	if timeout then
		local message = ShortMessage:new(_("%s\n(Linksklick = Annehmen, Rechtsklick = Ablehnen)", text), _"Gangwar", Color.Accent, timeout, nil, function()
			self.m_Questions[id] = nil
		end)
		message.onLeftClick = function()
			self.m_Questions[id] = nil
			triggerServerEvent("Gangwar:answerRequest", localPlayer, id, true)
			delete(message)
		end
		message.onRightClick = function()
			self.m_Questions[id] = nil
			triggerServerEvent("Gangwar:answerRequest", localPlayer, id, false)
			delete(message)
		end
		self.m_Questions[id] = message
		return
	end
	self.m_Questions[id] = QuestionBox:new(text,
		function()
			self.m_Questions[id] = nil
			triggerServerEvent("Gangwar:answerRequest", localPlayer, id, true)
		end,
		function()
			self.m_Questions[id] = nil
			triggerServerEvent("Gangwar:answerRequest", localPlayer, id, false)
		end
	)
end

function GangwarClient:Event_requestClose(id)
	if self.m_Questions[id] then
		delete(self.m_Questions[id])
		self.m_Questions[id] = nil
	end
end

function GangwarClient:Event_openNpc(data)
	if GangwarNpcGUI.Current then
		delete(GangwarNpcGUI.Current)
	end
	GangwarNpcGUI.Current = GangwarNpcGUI:new(data)
end

function GangwarClient:Event_openPick(data)
	GangwarPickGUI.open(data, _"Einteilen", function(ids)
		triggerServerEvent("Gangwar:submitPick", localPlayer, ids)
	end)
end

function GangwarClient:Event_openVehicles(list, carsLeft, carsTotal)
	if GangwarVehicleGUI.Current then
		GangwarVehicleGUI.Current:fill(list, carsLeft, carsTotal)
	else
		GangwarVehicleGUI.Current = GangwarVehicleGUI:new(list, carsLeft, carsTotal)
	end
end

function GangwarClient:Event_closeVehicles()
	if GangwarVehicleGUI.Current then
		delete(GangwarVehicleGUI.Current)
	end
end
