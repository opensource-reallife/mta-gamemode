BindGUI = inherit(GUIForm)

BindGUI.Modifiers = {
	[0] = "Ohne";
	["lalt"] = "Alt links",
	["ralt"] = "Alt rechts",
	["lctrl"] = "Strg links",
	["rctrl"] = "Strg rechts",
	["lshift"] = "Shift links",
	["rshift"] = "Shift rechts"
}

BindGUI.Headers = {
	["faction"] = "Fraktion",
	["company"] = "Unternehmen",
	["group"] = "Gruppe"
}

BindGUI.Functions = {
	["say"] = "Chat (/say)",
	["s"] = "schreien (/s)",
	["l"] = "flüstern (/l)",
	["me"] = "me (/me)",
	["t"] = "Fraktion (/t)",
	["u"] = "Unternehmen (/u)",
	["f"] = "Gruppe (/f)",
	["b"] = "Bündnis (/b)",
	["g"] = "Staat (/g)",
}

BindGUI.Languages = {
	["-"] = "Alle",
	["de"] = "Deutsch",
	["en"] = "Englisch",
}

MAX_PARAMETER_LENGTH = 26

addRemoteEvents{"bindReceive"}

function BindGUI:constructor()
	self.m_Modifiers = {}
	for k, v in pairs(BindGUI.Modifiers) do
		self.m_Modifiers[k] = _(v)
	end

	self.m_Functions = {}
	for k, v in pairs(BindGUI.Functions) do
		self.m_Functions[k] = _(v)
	end

	self.m_Headers = {}
	for k, v in pairs(BindGUI.Headers) do
		self.m_Headers[k] = _(v)
	end

	self.m_Languages = {}
	for k, v in pairs(BindGUI.Languages) do
		self.m_Languages[k] = _(v)
	end

	GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 500)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Binds", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_Grid = GUIGridList:new(self.m_Width*0.02, 40+self.m_Height*0.08, self.m_Width*0.96, self.m_Height*0.50, self)
	self.m_Grid:addColumn(_"Funktion", 0.15)
	self.m_Grid:addColumn(_"Text", 0.45)
	self.m_Grid:addColumn(_"Tasten", 0.25)
	self.m_Grid:addColumn(_"Sprache", 0.15)

	self.m_Footer = {}

	self.m_AddBindButton = GUIButton:new(self.m_Width*0.63, 40, self.m_Width*0.35, self.m_Height*0.07, _"Neuen Bind hinzufügen", self.m_Window):setBackgroundColor(Color.Green)
  	self.m_AddBindButton.onLeftClick = function()
		self:changeFooter("new")
		self.m_NewText:setText("")
		self.m_AddNewBindButton:setVisible(true)
		self.m_EditBindButton:setVisible(false)
	end

	self.m_SelectedBindLabel = GUILabel:new(self.m_Width*0.02, self.m_Height*0.66, self.m_Width*0.96, self.m_Height*0.055, "", self.m_Window):setColor(Color.Accent)

	--default Bind
	self.m_Footer["default"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)

	--Local Bind
	self.m_Footer["local"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)
	GUILabel:new(self.m_Width*0.02, self.m_Height*0.01, self.m_Width*0.25, self.m_Height*0.06, _"Taste 1:", self.m_Footer["local"])
	GUILabel:new(self.m_Width*0.325, self.m_Height*0.01, self.m_Width*0.2, self.m_Height*0.06, _"Taste 2:", self.m_Footer["local"])
	self.m_HelpChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.07, self.m_Width*0.25, self.m_Height*0.07, self.m_Footer["local"]):setBackgroundColor(Color.Accent)
	for index, name in pairs(self.m_Modifiers) do
		self.m_HelpChanger:addItem(name)
	end
	GUILabel:new(self.m_Width*0.28, self.m_Height*0.07, self.m_Width*0.07, self.m_Height*0.07, " + ", self.m_Footer["local"])
	self.m_SelectedButton = GUIButton:new(self.m_Width*0.325, self.m_Height*0.07, self.m_Width*0.18, self.m_Height*0.07, " ", self.m_Footer["local"]):setBackgroundColor(Color.Accent):setFontSize(1.2)
  	self.m_SelectedButton.onLeftClick = function () self:waitForKey() end
	self.m_SaveBindButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.16, self.m_Width*0.25, self.m_Height*0.07, _"Speichern", self.m_Footer["local"]):setBackgroundColor(Color.Green)
  	self.m_SaveBindButton.onLeftClick = function () self:saveBind() end
	self.m_DeleteBindButton = GUIButton:new(self.m_Width*0.73, self.m_Height*0.07, self.m_Width*0.25, self.m_Height*0.07, _"Bind löschen", self.m_Footer["local"]):setBackgroundColor(Color.Red)
  	self.m_DeleteBindButton.onLeftClick = function () self:deleteBind() end
	self.m_ChangeBindButton = GUIButton:new(self.m_Width*0.73, self.m_Height*0.16, self.m_Width*0.25, self.m_Height*0.07, _"Bind ändern", self.m_Footer["local"]):setBackgroundColor(Color.Orange)
  	self.m_ChangeBindButton.onLeftClick = function () self:editBind() end

	--Remote Bind
	self.m_Footer["remote"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)
	self.m_CopyButton = GUIButton:new(self.m_Width*0.02, self.m_Height*0.07, self.m_Width*0.35, self.m_Height*0.07, _"Diesen Bind verwenden", self.m_Footer["remote"]):setBackgroundColor(Color.Green)
  	self.m_CopyButton.onLeftClick = function () self:copyBind() end

	--New Bind
	self.m_Footer["new"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)
	self.m_FunctionChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.16, self.m_Width*0.3, self.m_Height*0.07, self.m_Footer["new"]):setBackgroundColor(Color.Accent)
	for index, name in pairs(self.m_Functions) do
		self.m_FunctionChanger:addItem(name)
	end
	self.m_LangChanger = GUIChanger:new(self.m_Width*0.36, self.m_Height*0.16, self.m_Width*0.3, self.m_Height*0.07, self.m_Footer["new"]):setBackgroundColor(Color.Accent)
	for index, name in pairs(self.m_Languages) do
		self.m_LangChanger:addItem(name)
	end
	GUILabel:new(self.m_Width*0.02, self.m_Height*0.01, self.m_Width*0.75, self.m_Height*0.06, _"Nachricht / Funktion / Sprache:", self.m_Footer["new"])
	self.m_NewText = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.07, self.m_Width*0.96, self.m_Height*0.07, self.m_Footer["new"])
	self.m_AddNewBindButton = GUIButton:new(self.m_Width*0.72, self.m_Height*0.16, self.m_Width*0.25, self.m_Height*0.07, _"Hinzufügen", self.m_Footer["new"]):setBackgroundColor(Color.Green):setVisible(false)
  	self.m_AddNewBindButton.onLeftClick = function () self:editAddBind() end
	self.m_EditBindButton = GUIButton:new(self.m_Width*0.72, self.m_Height*0.16, self.m_Width*0.25, self.m_Height*0.07, _"Ändern", self.m_Footer["new"]):setBackgroundColor(Color.Orange):setVisible(false)
  	self.m_EditBindButton.onLeftClick = function () self:editAddBind(self.m_SelectedBind) end

	for index, footer in pairs(self.m_Footer) do
		if index ~= "default" then
			footer:setVisible(false)
		end
	end

	self.m_onKeyBind = bind(self.onKeyPressed, self)
	self:loadBinds()

    addEventHandler("bindReceive", root, bind(self.Event_onReceive, self))
end

function BindGUI:onShow()
	SelfGUI:getSingleton():addWindow(self)
end

function BindGUI:loadBinds()
	self.m_Grid:clear()

	self.m_Grid:addItemNoClick(_"Deine Binds", "", "")
	self:loadLocalBinds()

	triggerServerEvent("bindRequestPerOwner", localPlayer, "faction")
	triggerServerEvent("bindRequestPerOwner", localPlayer, "company")
	triggerServerEvent("bindRequestPerOwner", localPlayer, "group")
end

function BindGUI:loadLocalBinds()
	local keys, item
	local binds = BindManager:getSingleton():getBinds()

	for index, data in pairs(binds) do
		if not data.keys or #data.keys == 0 then
			keys = "-"
		elseif #data.keys == 1 then
			keys = self.m_Modifiers[data.keys[1]] and self.m_Modifiers[data.keys[1]] or data.keys[1]:upper()
		else
			keys = table.concat({self.m_Modifiers[data.keys[1]] and self.m_Modifiers[data.keys[1]] or data.keys[1]:upper(), self.m_Modifiers[data.keys[2]] and self.m_Modifiers[data.keys[2]] or data.keys[2]:upper()}, " + ")
		end
		item = self.m_Grid:addItem(data.action.name, string.short(data.action.parameters, MAX_PARAMETER_LENGTH), keys, data.action.lang or "-")
		item.index = index
		item.type = "local"
		item.action =  data.action.name
		item.parameter =  data.action.parameters
		item.lang = data.action.lang or "-"
		item.onLeftClick = bind(self.onBindSelect, self, item, index)
	end
end

function BindGUI:addBackButton(callBack)
	if self.m_Window then
		self.m_Window:addBackButton(function () callBack() delete(self) end)
	end
end

function BindGUI:waitForKey ()
    self.m_SelectedButton:setText("...")
    addEventHandler("onClientKey", root, self.m_onKeyBind)
end

function BindGUI:copyBind()
	local item = self.m_SelectedBind
	if item and item.type and item.type == "server" then
		BindManager:getSingleton():addBind(item.action, item.parameter, item.lang)
		self:loadBinds()
	else
		ErrorBox:new(_"Kein Bind ausgewählt!")
	end
end

function BindGUI:Event_onReceive(type, id, binds)
	local item
	self.m_Grid:addItemNoClick(self.m_Headers[type], "", "")
	for id, data in pairs(binds) do
		item = self.m_Grid:addItem(data["Func"], string.short(data["Message"], MAX_PARAMETER_LENGTH), "-", data["Lang"] or "-")
		item.type = "server"
		item.action = data["Func"]
		item.parameter = data["Message"]
		item.lang = data["Lang"] or "-"
		item.onLeftClick = bind(self.onBindSelect, self, item)
	end
end

function BindGUI:changeFooter(target)
	for index, footer in pairs(self.m_Footer) do
		if index == target then
			footer:setVisible(true)
		else
			footer:setVisible(false)
		end
	end
end

function BindGUI:onBindSelect(item, index)
    self.m_SelectedBind = item
	self.m_SelectedBindLabel:setText(("Text: %s"):format(item.parameter))
	if item.type == "local" then
		self:changeFooter("local")
		if BindManager:getSingleton().m_Binds[index] and BindManager:getSingleton().m_Binds[index].keys then
			if BindManager:getSingleton().m_Binds[index].keys[1] then
				local key1 = BindManager:getSingleton().m_Binds[index].keys[1]
				if self.m_Modifiers[key1] then
					self.m_HelpChanger:setSelectedItem(self.m_Modifiers[key1])
				else
					self.m_SelectedButton:setText(key1:upper())
				end
			end
			if BindManager:getSingleton().m_Binds[index].keys[2] then
				local key2 = BindManager:getSingleton().m_Binds[index].keys[2]
				self.m_SelectedButton:setText(key2:upper())
			end
		end

	else
		self:changeFooter("remote")
	end
end

function BindGUI:onKeyPressed(key, press)
    if press == false then
		if not table.find(KeyBindings.DisallowedKeys, key:lower()) then
			if self.m_SelectedBind and self.m_SelectedBind.index then
				self.m_SelectedButton:setText(key:upper())
			else
				ErrorBox:new(_"Keine Belegung in der Liste ausgewählt!")
			end
			removeEventHandler("onClientKey", root, self.m_onKeyBind)
		end
    end
end

function BindGUI:saveBind()
	if self.m_SelectedButton:getText() == "" or self.m_SelectedButton:getText() == " " then return end
	if self.m_SelectedBind and self.m_SelectedBind.index and self.m_SelectedBind.type == "local" then
		local index = self.m_SelectedBind.index
		local helper = table.find(self.m_Modifiers, self.m_HelpChanger:getSelectedItem())
		local key = self.m_SelectedButton:getText():lower()
		local result = false
		if helper == 0 then
			result = BindManager:getSingleton():changeKey(index, key)
		else
			result = BindManager:getSingleton():changeKey(index, key, helper)
		end

		if result then
			self:loadBinds()
			SuccessBox:new(_"Bind erfolgreich geändert!")
		else
			ErrorBox:new(_"Bind konnte nicht gespeichert werden!")
		end
	else
		ErrorBox:new(_"Keine Belegung in der Liste ausgewählt!")
	end
end

function BindGUI:editBind()
	self.m_AddNewBindButton:setVisible(false)
	self.m_EditBindButton:setVisible(true)
	self:changeFooter("new")
	local item = self.m_SelectedBind
	self.m_FunctionChanger:setSelectedItem(self.m_Functions[item.action])
	self.m_LangChanger:setSelectedItem(self.m_Languages[item.lang])
	self.m_NewText:setText(item.parameter)
	self.m_AddNewBindButton:setText("Ändern")
end

function BindGUI:deleteBind()
	if self.m_SelectedBind and self.m_SelectedBind.index and self.m_SelectedBind.type == "local" then
		local index = self.m_SelectedBind.index
		if BindManager:getSingleton():removeBind(index) then
			self:loadBinds()
			SuccessBox:new(_"Bind gelöscht!")
		else
			ErrorBox:new(_"Bind konnte nicht gelöscht werden!")
		end
	else
		ErrorBox:new(_"Keine Belegung in der Liste ausgewählt!")
	end
end

function BindGUI:editAddBind(item)
	local parameters = self.m_NewText:getText()
	local name = table.find(self.m_Functions, self.m_FunctionChanger:getSelectedItem())
	local lang = table.find(self.m_Languages, self.m_LangChanger:getSelectedItem())
	if parameters:len() >= 1 and name then
		if item then
			if BindManager:getSingleton():editBind(item.index, name, parameters, lang) then
				SuccessBox:new(_"Bind geändert!")
			else
				ErrorBox:new(_"Bind konnte nicht geändert werden!")
			end
		else
			BindManager:getSingleton():addBind(name, parameters, lang)
			SuccessBox:new(_"Bind hinzugefügt! Du kannst nun die Tasten belegen!")
		end
		self:loadBinds()

		self:changeFooter("default")
	end
end

BindManageGUI = inherit(GUIForm)

function BindManageGUI:constructor(ownerType)
	self.m_Modifiers = {}
	for k, v in pairs(BindGUI.Modifiers) do
		self.m_Modifiers[k] = _(v)
	end

	self.m_Functions = {}
	for k, v in pairs(BindGUI.Functions) do
		self.m_Functions[k] = _(v)
	end

	self.m_Headers = {}
	for k, v in pairs(BindGUI.Headers) do
		self.m_Headers[k] = _(v)
	end

	self.m_Languages = {}
	for k, v in pairs(BindGUI.Languages) do
		self.m_Languages[k] = _(v)
	end

	GUIForm.constructor(self, screenWidth/2-300, screenHeight/2-230, 600, 460)

	self.m_OwnerType = ownerType

	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Binds verwalten", true, true, self)
	self.m_Window:deleteOnClose(true)
	self.m_Grid = GUIGridList:new(self.m_Width*0.02, 40+self.m_Height*0.08, self.m_Width*0.96, self.m_Height*0.595, self)
	self.m_Grid:addColumn("Funktion", 0.2)
	self.m_Grid:addColumn("Text", 0.6)
	self.m_Grid:addColumn("Sprache", 0.2)

	self.m_AddBindButton = GUIButton:new(self.m_Width*0.63, 40, self.m_Width*0.35, self.m_Height*0.07, _"Neuen Bind hinzufügen", self.m_Window):setBackgroundColor(Color.Green)
  	self.m_AddBindButton.onLeftClick = function()
		self:changeFooter("new")
		self.m_NewText:setText("")
		self.m_AddNewBindButton:setVisible(true)
		self.m_EditBindButton:setVisible(false)
		self.m_DeleteBindButton:setVisible(false)
	end

	self.m_Footer = {}

	--default Bind
	self.m_Footer["default"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)

	--New/Edit Bind
	self.m_Footer["new"] = GUIElement:new(0, 40+self.m_Height*0.66, self.m_Width, self.m_Height*0.4-40, self.m_Window)
	GUILabel:new(self.m_Width*0.02, self.m_Height*0.01, self.m_Width*0.75, self.m_Height*0.06, "Nachricht / Funktion / Sprache:", self.m_Footer["new"])
	self.m_NewText = GUIEdit:new(self.m_Width*0.02, self.m_Height*0.07, self.m_Width*0.96, self.m_Height*0.07, self.m_Footer["new"])
	self.m_FunctionChanger = GUIChanger:new(self.m_Width*0.02, self.m_Height*0.16, self.m_Width*0.28, self.m_Height*0.07, self.m_Footer["new"]):setBackgroundColor(Color.Accent)
	for index, name in pairs(self.m_Functions) do
		self.m_FunctionChanger:addItem(name)
	end
	self.m_LangChanger = GUIChanger:new(self.m_Width*0.31, self.m_Height*0.16, self.m_Width*0.25, self.m_Height*0.07, self.m_Footer["new"]):setBackgroundColor(Color.Accent)
	for index, name in pairs(self.m_Languages) do
		self.m_LangChanger:addItem(name)
	end
	self.m_AddNewBindButton = GUIButton:new(self.m_Width*0.78, self.m_Height*0.16, self.m_Width*0.2, self.m_Height*0.07, "Speichern", self.m_Footer["new"]):setBackgroundColor(Color.Green):setVisible(false)
  	self.m_AddNewBindButton.onLeftClick = function () self:editAddBind() end
	self.m_EditBindButton = GUIButton:new(self.m_Width*0.57, self.m_Height*0.16, self.m_Width*0.2, self.m_Height*0.07, "Ändern", self.m_Footer["new"]):setBackgroundColor(Color.Orange):setVisible(false)
  	self.m_EditBindButton.onLeftClick = function () self:editAddBind(self.m_SelectedBind) end
	self.m_DeleteBindButton = GUIButton:new(self.m_Width*0.78, self.m_Height*0.16, self.m_Width*0.2, self.m_Height*0.07, "Löschen", self.m_Footer["new"]):setBackgroundColor(Color.Red):setVisible(false)
  	self.m_DeleteBindButton.onLeftClick = function () self:deleteBind() end

	for index, footer in pairs(self.m_Footer) do
		if index ~= "default" then
			footer:setVisible(false)
		end
	end

    addEventHandler("bindReceive", root, bind(self.Event_onReceive, self))
	triggerServerEvent("bindRequestPerOwner", localPlayer, self.m_OwnerType)
end

function BindManageGUI:addBackButton(callBack)
	if self.m_Window then
		self.m_Window:addBackButton(function () callBack() delete(self) end)
	end
end

function BindManageGUI:changeFooter(target)
	for index, footer in pairs(self.m_Footer) do
		if index == target then
			footer:setVisible(true)
		else
			footer:setVisible(false)
		end
	end
end

function BindManageGUI:Event_onReceive(type, id, binds)
	self.m_Grid:clear()
	self.m_Grid:addItemNoClick(self.m_Headers[type], "")
	for id, data in pairs(binds) do
		local item = self.m_Grid:addItem(data["Func"], string.short(data["Message"], MAX_PARAMETER_LENGTH + 6), data["Lang"] or "-")
		item.action = data["Func"]
		item.parameter = data["Message"]
		item.lang = data["Lang"] or "-"
		item.id = id
		item.onLeftClick = bind(self.onBindSelect, self, item)
	end
end

function BindManageGUI:editAddBind(item)
	local parameters = self.m_NewText:getText()
	local name = table.find(self.m_Functions, self.m_FunctionChanger:getSelectedItem())
	local lang = table.find(self.m_Languages, self.m_LangChanger:getSelectedItem())
	if parameters:len() >= 1 and name then
		if item and item.id then
			triggerServerEvent("bindEditServerBind", localPlayer, self.m_OwnerType, item.id, name, parameters, lang)
		else
			triggerServerEvent("bindAddServerBind", localPlayer, self.m_OwnerType, name, parameters, lang)
		end
		self:changeFooter("default")
	end
end

function BindManageGUI:deleteBind()
	if self.m_SelectedBind and self.m_SelectedBind.id then
		triggerServerEvent("bindDeleteServerBind", localPlayer, self.m_OwnerType, self.m_SelectedBind.id)
	end
	self:changeFooter("default")
end

function BindManageGUI:onBindSelect(item)
    self.m_SelectedBind = item
	self:changeFooter("new")
	self.m_FunctionChanger:setSelectedItem(self.m_Functions[item.action])
	self.m_NewText:setText(item.parameter)
	self.m_EditBindButton:setVisible(true)
	self.m_DeleteBindButton:setVisible(true)
	self.m_AddNewBindButton:setVisible(false)
end