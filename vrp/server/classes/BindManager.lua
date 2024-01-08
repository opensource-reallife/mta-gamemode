-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/BindManager.lua
-- *  PURPOSE:     Responsible for managing binds
-- *
-- ****************************************************************************
BindManager = inherit(Singleton)

function BindManager:constructor()
    self.m_Binds = {}
	self.m_BindTranslations = {}
	self.m_BindsPerOwner = {}
	self:loadBinds()

	addRemoteEvents{"bindTrigger", "bindRequestPerOwner", "bindEditServerBind", "bindAddServerBind", "bindDeleteServerBind"}
    addEventHandler("bindTrigger", root, bind(self.Event_OnBindTrigger, self))
    addEventHandler("bindRequestPerOwner", root, bind(self.Event_requestBindsPerOwner, self))
    addEventHandler("bindEditServerBind", root, bind(self.Event_editBind, self))
    addEventHandler("bindAddServerBind", root, bind(self.Event_addBind, self))
    addEventHandler("bindDeleteServerBind", root, bind(self.Event_deleteBind, self))


end

function BindManager:Event_OnBindTrigger(name, parameters, parametersEN)
	local translatableBind = true
	local old = self.m_BindTranslations[parameters]

	if (not parameters or parameters == "") and (not parametersEN or parametersEN == "") then
		return -- empty message
	end

	if parameters and parameters ~= "" then
		if (not self.m_BindTranslations[parameters] or self.m_BindTranslations[parameters] ~= parametersEN) and parametersEN and parametersEN ~= "" then
			self.m_BindTranslations[parameters] = parametersEN
		end
	else
		parameters = parametersEN
		translatableBind = false
	end

    if name == "say" then
        PlayerManager:getSingleton():playerChat(parameters, 0, translatableBind)
	elseif name == "me" then
		client:meChat(false, parameters, false, false, translatableBind)
	elseif name == "s" then
		PlayerManager:getSingleton():sendPlayerScream(client, parameters, translatableBind)
	elseif name == "l" then
		PlayerManager:getSingleton():sendPlayerWhisper(client, parameters, translatableBind)
	elseif name == "t" then
		if client.m_Faction then
			if client.m_Faction:getId() >= 1 and client.m_Faction:getId() <= 3 then
				if client.m_Faction and client.m_Faction:isStateFaction() then
					FactionState:getSingleton():sendStateChatMessage(client, parameters, translatableBind)
				end
			else
				client.m_Faction:sendChatMessage(client, parameters, translatableBind)
			end
		end
	elseif name == "f" then
		if client.m_Group then
			client.m_Group:sendChatMessage(client, parameters, translatableBind)
		end
	elseif name == "u" then
		if client:getCompany() then
			client:getCompany():sendChatMessage(client, parameters, translatableBind)
		end
	elseif name == "b" then
		if client.m_Faction then
			local bndFaction = client.m_Faction:getAllianceFaction()
			if bndFaction then
				client.m_Faction:sendBndChatMessage(client, parameters, bndFaction, translatableBind)
				bndFaction:sendBndChatMessage(client, parameters, bndFaction, translatableBind)
			else
				client:sendError(_("Eure Allianz hat kein Bündnis!", client))
			end
		end
	--[[elseif name == "g" then
		client:meChat(false, true, parameters)]]
	else
        executeCommandHandler(name, client, parameters)
    end

	self.m_BindTranslations[parameters] = old
end

function BindManager:loadBinds(id)
	local result = sql:queryFetch("SELECT * FROM ??_binds", sql:getPrefix())
    local i = 0
	for k, row in ipairs(result) do
		self.m_Binds[row.Id] = {
			["Func"] = row.Func,
			["Message"] = row.Message,
			["MessageEN"] = row.MessageEN,
		}
		if row.MessageEN and row.MessageEN ~= "" then
			self.m_BindTranslations[row.Message] = row.MessageEN
		end
		if not self.m_BindsPerOwner[row.OwnerType] then self.m_BindsPerOwner[row.OwnerType] = {} end
		if not self.m_BindsPerOwner[row.OwnerType][row.Owner] then self.m_BindsPerOwner[row.OwnerType][row.Owner] = {} end
		self.m_BindsPerOwner[row.OwnerType][row.Owner][row.Id] = self.m_Binds[row.Id]
		i = i+1
	end
	--outputDebugString(i.." Server-Binds geladen!")
end

function BindManager:Event_requestBindsPerOwner(ownerType)
	local owner = self:getOwner(client, ownerType)
	if not owner then return end
	local ownerId = owner:getId()
	if not ownerId then return end

	if self.m_BindsPerOwner[ownerType] and self.m_BindsPerOwner[ownerType][ownerId] then
		client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
	end
end

function BindManager:getOwner(player, type)
	if type == "faction" then
		return player:getFaction()
	elseif type == "company" then
		return player:getCompany()
	elseif type == "group" then
		return player:getGroup()
	end
	return false
end

function BindManager:isManager(player, type)
	local owner = self:getOwner(player, type)
	if owner then
		if type == "faction" then
			return owner:getPlayerRank(player) >= FactionRank.Manager
		elseif type == "company" then
			return owner:getPlayerRank(player) >= CompanyRank.Manager
		elseif type == "group" then
			return owner:getPlayerRank(player) >= GroupRank.Manager
		end
	end
end

function BindManager:Event_editBind(ownerType, id, func, message, messageEN)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, ownerType, "editBinds") then
		client:sendError(_("Du bist nicht berechtigt Binds zu editieren!", client))
		return
	end
	id = tonumber(id)
	local owner = self:getOwner(client, ownerType)
	local ownerId = owner:getId()
	if not owner or not ownerId then
		client:sendError("Internal Error: Bind Owner not found")
		return
	end
	if self.m_BindsPerOwner[ownerType][ownerId][id] and self.m_Binds[id] then
		self.m_Binds[id] = {
			["Func"] = func,
			["Message"] = message,
			["MessageEN"] = messageEN
		}
		if message ~= "" then
			self.m_BindTranslations[message] = messageEN
		end

		self.m_BindsPerOwner[ownerType][ownerId][id] = self.m_Binds[id]
		sql:queryExec("UPDATE ??_binds SET Func = ?, Message = ?, MessageEN = ?, Creator = ? WHERE Id = ?", sql:getPrefix(), func, message, messageEN, client:getId(), id)
		client:sendSuccess(_("Bind erfolgreich geändert!", client))
	else
		client:sendError(_("Bind nicht gefunden!", client))
	end
	client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
end

function BindManager:Event_deleteBind(ownerType, id)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, ownerType, "editBinds") then
		client:sendError(_("Du bist nicht berechtigt Binds zu löschen!", client))
		return
	end
	id = tonumber(id)
	local owner = self:getOwner(client, ownerType)
	local ownerId = owner:getId()
	if not owner or not ownerId then
		client:sendError("Internal Error: Bind Owner not found")
		return
	end
	if self.m_BindsPerOwner[ownerType][ownerId][id] and self.m_Binds[id] then
		self.m_BindTranslations[self.m_Binds[id]["Message"]] = nil
		self.m_Binds[id] = nil
		self.m_BindsPerOwner[ownerType][ownerId][id] = nil
		sql:queryExec("DELETE FROM ??_binds WHERE Id = ?", sql:getPrefix(), id)
		client:sendSuccess(_("Bind erfolgreich gelöscht!", client))
	else
		client:sendError(_("Bind nicht gefunden!", client))
	end
	client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
end

function BindManager:Event_addBind(ownerType, func, message, messageEN)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, ownerType, "editBinds") then
		client:sendError(_("Du bist nicht berechtigt Binds hinzuzufügen!", client))
		return
	end
	local owner = self:getOwner(client, ownerType)
	local ownerId = owner:getId()
	if not owner or not ownerId then
		client:sendError("Internal Error: Bind Owner not found")
		return
	end
	if not self.m_BindsPerOwner[ownerType] then self.m_BindsPerOwner[ownerType] = {} end
	if not self.m_BindsPerOwner[ownerType][ownerId] then self.m_BindsPerOwner[ownerType][ownerId] = {} end
	sql:queryExec("INSERT INTO ??_binds (OwnerType, Owner, Func, Message, MessageEN, Creator) VALUES (?, ?, ?, ?, ?, ?)", sql:getPrefix(), ownerType, ownerId, func, message, messageEN, client:getId())
	local id = sql:lastInsertId()
	self.m_Binds[id] = {
			["Func"] = func,
			["Message"] = message,
			["MessageEN"] = messageEN
		}
	self.m_BindsPerOwner[ownerType][ownerId][id] = self.m_Binds[id]
	if message ~= "" then
		self.m_BindTranslations[message] = messageEN
	end
	client:sendSuccess(_("Bind erfolgreich hinzugefügt!", client))
	client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
end

function BindManager:translateBind(string, player)
	if player:getLocale() == "de" then
		return string
	end
	return self.m_BindTranslations[string] or string
end

function BindManager:getTranslation(string)
	return self.m_BindTranslations[string] or string
end