-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/BindManager.lua
-- *  PURPOSE:     Responsible for managing binds
-- *
-- ****************************************************************************
BindManager = inherit(Singleton)
BindManager.filePath = "binds.json"


function BindManager:constructor()
    self.m_PressedKeys = {}
	self.m_Cooldown = 0

    addEventHandler("onClientKey", root, bind(self.Event_OnClientKey, self))
    --[[ DEBUG:
	addEventHandler("onClientRender", root, function()
        local keys = {}

        for k, v in pairs(self.m_PressedKeys) do
            if v then
                table.insert(keys, k)
            end
        end

        dxDrawText(table.concat(keys, " "), 100, 500)
    end)
	]]
	self:loadLocalBinds()
end

function BindManager:destructor()
	self:saveLocalBinds()
end

function BindManager:Event_OnClientKey(button, pressOrRelease)
	if GUIInputControl.ms_CurrentInputFocus or isChatBoxInputActive() or isConsoleActive() then -- Textboxes
		return
	end

	if table.find(KeyBindings.DisallowedKeys, button:lower()) then return end
	self.m_PressedKeys[button] = pressOrRelease

	if self:CheckForBind(button) then
        cancelEvent()
    end
end

function BindManager:getBinds()
	return self.m_Binds
end

function BindManager:changeKey(index, key1, key2)
	if index and self.m_Binds[index] then
		if key2 then
			self.m_Binds[index].keys = {key2, key1}
		else
			self.m_Binds[index].keys = {key1}
		end
		return true
	end
	return false
end

function BindManager:removeBind(index)
	if index and self.m_Binds[index] then
		self.m_Binds[index] = nil
		return true
	end
	return false
end

function BindManager:addBind(action, parameters, lang)
	table.insert(self.m_Binds, {
        keys = {
        },
        action = {
            name = action,
            parameters = parameters,
			lang = lang
        }
    })
end


function BindManager:editBind(index, action, parameters, lang)
	if index and self.m_Binds[index] then
		self.m_Binds[index].action = {
				name = action,
				parameters = parameters,
				lang = lang
			}
		return true
	end
	return false
end


function BindManager:CheckForBind(key)
    local bindTrigerred = false
	local counter = 0

	if getTickCount() >= self.m_Cooldown then
		for k, v in pairs(self.m_Binds) do
			if #v.keys > 0 and table.find(v.keys, key) then
				local allKeysPressed = 0

				for _, key in pairs(v.keys) do
					if self.m_PressedKeys[key] then
						allKeysPressed = allKeysPressed + 1
					end
				end

				if allKeysPressed == table.size(v.keys) then
					if counter <= table.size(TranslationManager.ms_AvailableTranslations) then
						Timer(function()
							triggerServerEvent("bindTrigger", localPlayer, v.action.name, v.action.parameters, v.action.lang)
						end, (CHAT_MSG_REPEAT_COOLDOWN + 50) * counter, 1)
					end

					counter = counter + 1
					bindTrigerred = true
				end
			end
		end
		self.m_Cooldown = getTickCount() + ((CHAT_MSG_REPEAT_COOLDOWN + 50) * counter)
	end

	return bindTrigerred
end

function BindManager:loadLocalBinds()
	if not fileExists(BindManager.filePath) then
		fileClose(fileCreate(BindManager.filePath))
	end

	local fileHandle = fileOpen(BindManager.filePath, true)
	local text = fileRead(fileHandle, fileGetSize(fileHandle))
	local bindTable = fromJSON(text) or {}
	fileClose(fileHandle)

	self.m_Binds = {}

	for _, bind in pairs(bindTable) do
		if bind.action.lang == localPlayer:getLocale() then
			table.insert(self.m_Binds, bind)
		end
	end

	for _, bind in pairs(bindTable) do
		if bind.action.lang ~= localPlayer:getLocale() then
			table.insert(self.m_Binds, bind)
		end
	end
end

function BindManager:saveLocalBinds()
	if fileExists(BindManager.filePath) then
		fileDelete(BindManager.filePath)
	end
	fileClose(fileCreate(BindManager.filePath))

	local fileHandle = fileOpen(BindManager.filePath, false)

	fileWrite(fileHandle, toJSON(self.m_Binds, false, "tabs"))
	fileClose(fileHandle)
end
