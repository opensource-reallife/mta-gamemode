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
	self.m_BindsPerOwner = {}
	self:loadBinds()

	addRemoteEvents{"bindTrigger", "bindRequestPerOwner", "bindEditServerBind", "bindAddServerBind", "bindDeleteServerBind"}
    addEventHandler("bindTrigger", root, bind(self.Event_OnBindTrigger, self))
    addEventHandler("bindRequestPerOwner", root, bind(self.Event_requestBindsPerOwner, self))
    addEventHandler("bindEditServerBind", root, bind(self.Event_editBind, self))
    addEventHandler("bindAddServerBind", root, bind(self.Event_addBind, self))
    addEventHandler("bindDeleteServerBind", root, bind(self.Event_deleteBind, self))


end

function BindManager:Event_OnBindTrigger(name, parameters, lang)
	if lang == "-" then lang = false end
	if lang and lang ~= client:getLocale() then
		client:sendMessage(("[%s] %s (%s): %s"):format(lang, client:getName(), name, parameters), 150, 150, 150)
	end

    if name == "say" then
        PlayerManager:getSingleton():playerChat(parameters, 0, lang)
	elseif name == "s" then
		PlayerManager:getSingleton():playerScream(client, parameters, lang)
	elseif name == "l" then
		PlayerManager:getSingleton():playerWhisper(client, parameters, lang)
	elseif name == "me" then
		client:meChat(false, parameters, false, false, lang)
	elseif name == "t" then
		local faction = client:getFaction()
		if faction then
			faction:sendChatMessage(client, parameters, lang)
		end
	elseif name == "u" then
		local company = client:getCompany()
		if company then
			company:sendChatMessage(client, parameters, lang)
		end
	elseif name == "f" then
		local group = client:getGroup()
		if group then
			group:sendChatMessage(client, parameters, lang)
		end
	elseif name == "b" then
		local faction = client:getFaction()
		if faction then
			local bndFaction = faction:getAllianceFaction()
			if bndFaction then
				faction:sendBndChatMessage(faction, parameters, bndFaction, lang)
				bndFaction:sendBndChatMessage(faction, parameters, bndFaction, lang)
			else
				self:sendError(_("Eure Allianz hat kein Bündnis!", self))
			end
		end
	elseif name == "g" then
		local faction = client:getFaction()
		if faction and faction:isStateFaction() then
			FactionState:getSingleton():sendStateChatMessage(faction, parameters, lang)
		end
    else
		client:sendError("Nicht implementiert!")
	end
end

function BindManager:loadBinds(id)
	local result = sql:queryFetch("SELECT * FROM ??_binds", sql:getPrefix())
    local i = 0
	for k, row in ipairs(result) do
		self.m_Binds[row.Id] = {
			["Func"] = row.Func,
			["Message"] = row.Message,
			["Lang"] = row.Lang
		}
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

function BindManager:Event_editBind(ownerType, id, func, message, lang)
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
			["Lang"] = lang
		}
		self.m_BindsPerOwner[ownerType][ownerId][id] = self.m_Binds[id]
		sql:queryExec("UPDATE ??_binds SET Func = ?, Message = ?, Lang = ?, Creator = ? WHERE Id = ?", sql:getPrefix(), func, message, lang, client:getId(), id)
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
		self.m_Binds[id] = nil
		self.m_BindsPerOwner[ownerType][ownerId][id] = nil
		sql:queryExec("DELETE FROM ??_binds WHERE Id = ?", sql:getPrefix(), id)
		client:sendSuccess(_("Bind erfolgreich gelöscht!", client))
	else
		client:sendError(_("Bind nicht gefunden!", client))
	end
	client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
end

function BindManager:Event_addBind(ownerType, func, message, lang)
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
	sql:queryExec("INSERT INTO ??_binds (OwnerType, Owner, Func, Message, Creator) VALUES (?, ?, ?, ?, ?)", sql:getPrefix(), ownerType, ownerId, func, message, client:getId())
	local id = sql:lastInsertId()
	self.m_Binds[id] = {
			["Func"] = func,
			["Message"] = message,
			["Lang"] = lang
		}
	self.m_BindsPerOwner[ownerType][ownerId][id] = self.m_Binds[id]
	client:sendSuccess(_("Bind erfolgreich hinzugefügt!", client))
	client:triggerEvent("bindReceive", ownerType, ownerId, self.m_BindsPerOwner[ownerType][ownerId])
end
