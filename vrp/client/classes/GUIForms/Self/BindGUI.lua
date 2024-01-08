BindGUI = inherit(GUIForm)
inherit(Singleton, BindGUI)

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
	["group"] = "Firma/Gang"
}

BindGUI.Functions = {
	["say"] = "Chat (/say)",
	["s"] = "schreien (/s)",
	["l"] = "flüstern (/l)",
	["t"] = "Fraktion (/t)",
	["me"] = "me (/me)",
	["u"] = "Unternehmen (/u)",
	["f"] = "Firma/Gang (/f)",
	["b"] = "Bündnis (/b)",
	--["g"] = "Beamten (/g)",
}

MAX_PARAMETER_LENGTH = 37
MAX_PARAMETER_LENGTH_MANAGE = 62

addRemoteEvents{"bindReceive"}

function BindGUI:constructor()
	GUIWindow.updateGrid()	
	self.m_Width = grid("x", 17)
	self.m_Height = grid("y", 15)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Binds", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_Grid = GUIGridGridList:new(1, 2, 16, 7, self)
	self.m_Grid:addColumn("Funktion", 0.15)
	self.m_Grid:addColumn("Text", 0.52)
	self.m_Grid:addColumn("Tasten", 0.28)

	self.m_Binds = {}
	self.m_Footer = {}

	self.m_AddBindButton = GUIGridButton:new(11, 1, 6, 1, _"neuen Bind hinzufügen", self.m_Window):setBackgroundColor(Color.Green)
  	self.m_AddBindButton.onLeftClick = function()
		self:changeFooter("new")
		self.m_Footer["new"]["NewTextDE"]:setText("")
		self.m_Footer["new"]["NewTextEN"]:setText("")
		self.m_Footer["new"]["AddNewBindButton"]:setVisible(true)
		self.m_Footer["new"]["EditBindButton"]:setVisible(false)
		self.m_Footer["local"]["DeleteBindButton"]:setVisible(false)
		self.m_SelectedBindLabelDE:setText("")
		self.m_SelectedBindLabelEN:setText("")
	end

	self.m_SelectedBindLabelDE = GUIGridLabel:new(1, 9, 16, 1, "", self.m_Window):setColor(Color.Accent)
	self.m_SelectedBindLabelEN = GUIGridLabel:new(1, 10, 16, 1, "", self.m_Window):setColor(Color.Accent)

	--default Bind
	self.m_Footer["default"] = {}

	--Local Bind
	self.m_Footer["local"] = {}

	self.m_Footer["local"]["Key1"] = GUIGridLabel:new(1, 12, 7, 1, "Taste 1:", self.m_Window)
	self.m_Footer["local"]["Key2"] = GUIGridLabel:new(10, 12, 7, 1, "Taste 2:", self.m_Window)
	self.m_Footer["local"]["HelpChanger"] = GUIGridChanger:new(1, 13, 7, 1, self.m_Window):setBackgroundColor(Color.Accent)
	for index, name in pairs(BindGUI.Modifiers) do
		self.m_Footer["local"]["HelpChanger"]:addItem(name)
	end
	self.m_Footer["local"]["PlusLabel"] = GUIGridLabel:new(8, 13, 2, 1, " + ", self.m_Window):setAlign("center")
	self.m_Footer["local"]["SelectedButton"] = GUIGridButton:new(10, 13, 7, 1, " ", self.m_Window):setBackgroundColor(Color.Accent):setFontSize(1.2)
  	self.m_Footer["local"]["SelectedButton"].onLeftClick = function () self:waitForKey() end
	self.m_Footer["local"]["SaveBindButton"] = GUIGridButton:new(1, 14, 5, 1, "Speichern", self.m_Window):setBackgroundColor(Color.Green)
	self.m_Footer["local"]["SaveBindButton"].onLeftClick = function () self:saveBind() end
	self.m_Footer["local"]["DeleteBindButton"] = GUIGridButton:new(7, 14, 5, 1, "Bind Löschen", self.m_Window):setBackgroundColor(Color.Red)
	self.m_Footer["local"]["DeleteBindButton"].onLeftClick = function () self:deleteBind() end
	self.m_Footer["local"]["ChangeBindButton"] = GUIGridButton:new(12, 14, 5, 1, "Bind ändern", self.m_Window):setBackgroundColor(Color.Orange)
	self.m_Footer["local"]["ChangeBindButton"].onLeftClick = function () self:editBind() end

	--Remote Bind
	self.m_Footer["remote"] = {}
	self.m_Footer["remote"]["CopyButton"] = GUIGridButton:new(1, 14, 16, 1, "Diesen Bind verwenden", self.m_Window):setBackgroundColor(Color.Green)
	self.m_Footer["remote"]["CopyButton"].onLeftClick = function () self:copyBind() end


	--New Bind
	self.m_Footer["new"] = {}
	self.m_Footer["new"]["FunctionLabel"] = GUIGridLabel:new(1, 14, 3, 1, "Funktion:", self.m_Window)
	self.m_Footer["new"]["FunctionChanger"] = GUIGridChanger:new(5, 14, 5, 1, self.m_Window):setBackgroundColor(Color.Accent)
	for index, name in pairs(BindGUI.Functions) do
		self.m_Footer["new"]["FunctionChanger"]:addItem(name)
	end
	self.m_Footer["new"]["GermanMsgLabel"] = GUIGridLabel:new(1, 10, 16, 1, "Nachricht (Deutsch):", self.m_Window)
	self.m_Footer["new"]["NewTextDE"] = GUIGridEdit:new(1, 11, 16, 1, self.m_Window)
	self.m_Footer["new"]["EnglishMsgLabel"] = GUIGridLabel:new(1, 12, 16, 1, "Nachricht (Englisch):", self.m_Window)
	self.m_Footer["new"]["NewTextEN"] = GUIGridEdit:new(1, 13, 16, 1, self.m_Window)
	self.m_Footer["new"]["AddNewBindButton"] = GUIGridButton:new(11, 14, 5, 1, "Hinzufügen", self.m_Window):setBackgroundColor(Color.Green):setVisible(false)
	self.m_Footer["new"]["AddNewBindButton"].onLeftClick = function () self:editAddBind() end
	self.m_Footer["new"]["EditBindButton"] = GUIGridButton:new(11, 14, 5, 1, "Ändern", self.m_Window):setBackgroundColor(Color.Orange):setVisible(false)
	self.m_Footer["new"]["EditBindButton"].onLeftClick = function () self:editAddBind(self.m_SelectedBind) end

	for index, footer in pairs(self.m_Footer) do
		if index ~= "default" then
			for i, v in pairs(footer) do
				v:setVisible(false)
			end
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

	self.m_Grid:addItemNoClick("Deine Binds", "", "")
	self:loadLocalBinds()

	triggerServerEvent("bindRequestPerOwner", localPlayer, "faction")
	triggerServerEvent("bindRequestPerOwner", localPlayer, "company")
	triggerServerEvent("bindRequestPerOwner", localPlayer, "group")
end

function BindGUI:loadLocalBinds()
	local keys, item
	local binds = BindManager:getSingleton():getBinds()

	for index, data in pairs(binds) do
		local tMessage = data.action.parameters
		if (localPlayer:getLocale() == "en" or (not data.action.parameters or data.action.parameters == "")) 
			and data.action.parametersEN and data.action.parametersEN ~= "" then
			tMessage = data.action.parametersEN
		end

		if not data.keys or #data.keys == 0 then
			keys = "-"
		elseif #data.keys == 1 then
			keys = BindGUI.Modifiers[data.keys[1]] and BindGUI.Modifiers[data.keys[1]] or data.keys[1]:upper()
		else
			keys = table.concat({BindGUI.Modifiers[data.keys[1]] and BindGUI.Modifiers[data.keys[1]] or data.keys[1]:upper(), BindGUI.Modifiers[data.keys[2]] and BindGUI.Modifiers[data.keys[2]] or data.keys[2]:upper()}, " + ")
		end
		item = self.m_Grid:addItem(data.action.name, string.short(tMessage or "", MAX_PARAMETER_LENGTH), keys)
		item.index = index
		item.type = "local"
		item.action =  data.action.name
		item.parameterDE =  data.action.parameters
		item.parameterEN =  data.action.parametersEN
		item.onLeftClick = bind(self.onBindSelect, self, item, index)
	end
end

function BindGUI:addBackButton(callBack)
	if self.m_Window then
		self.m_Window:addBackButton(function () callBack() delete(self) end)
	end
end

function BindGUI:waitForKey ()
    self.m_Footer["local"]["SelectedButton"]:setText("...")
    addEventHandler("onClientKey", root, self.m_onKeyBind)
end

function BindGUI:copyBind()
	local item = self.m_SelectedBind
	if item and item.type and item.type == "server" then
		BindManager:getSingleton():addBind(item.action, item.parameterDE, item.parameterEN)
		self:loadBinds()
	else
		ErrorBox:new(_"Keine Bind ausgewählt!")
	end
end

function BindGUI:Event_onReceive(type, id, binds)
	local item
	self.m_Grid:addItemNoClick(BindGUI.Headers[type], "", "")
	for id, data in pairs(binds) do
		local tMessage = data["Message"]
		if localPlayer:getLocale() == "en" and data["MessageEN"] and data["MessageEN"] ~= "" then
			tMessage = data["MessageEN"]
		end

		item = self.m_Grid:addItem(data["Func"], string.short(tMessage or "", MAX_PARAMETER_LENGTH), "-")
		item.type = "server"
		item.action =  data["Func"]
		item.parameterDE =  data["Message"]
		item.parameterEN =  data["MessageEN"]
		item.onLeftClick = bind(self.onBindSelect, self, item)
	end
end

function BindGUI:changeFooter(target)
	for index, footer in pairs(self.m_Footer) do
		if index == target then
			for i, v in pairs(footer) do
				v:setVisible(true)
			end
		else
			for i, v in pairs(footer) do
				v:setVisible(false)
			end
		end
	end
end

function BindGUI:onBindSelect(item, index)
    self.m_SelectedBind = item
	self.m_SelectedBindLabelDE:setText(("Text (Deutsch): %s"):format(item.parameterDE or "-"))
	self.m_SelectedBindLabelEN:setText(("Text (English): %s"):format(item.parameterEN or "-"))
	if item.type == "local" then
		self:changeFooter("local")
		if BindManager:getSingleton().m_Binds[index] and BindManager:getSingleton().m_Binds[index].keys then
			if BindManager:getSingleton().m_Binds[index].keys[1] then
				local key1 = BindManager:getSingleton().m_Binds[index].keys[1]
				if BindGUI.Modifiers[key1] then
					self.m_Footer["local"]["HelpChanger"]:setSelectedItem(BindGUI.Modifiers[key1])
				else
					self.m_Footer["local"]["SelectedButton"]:setText(key1:upper())
				end
			end
			if BindManager:getSingleton().m_Binds[index].keys[2] then
				local key2 = BindManager:getSingleton().m_Binds[index].keys[2]
				self.m_Footer["local"]["SelectedButton"]:setText(key2:upper())
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
				self.m_Footer["local"]["SelectedButton"]:setText(key:upper())
			else
				ErrorBox:new(_"Keine Belegung in der Liste ausgewählt!")
			end
			removeEventHandler("onClientKey", root, self.m_onKeyBind)
		end
    end
end

function BindGUI:saveBind()
	if self.m_Footer["local"]["SelectedButton"]:getText() == "" or self.m_Footer["local"]["SelectedButton"]:getText() == " " then return end
	if self.m_SelectedBind and self.m_SelectedBind.index and self.m_SelectedBind.type == "local" then
		local index = self.m_SelectedBind.index
		local helper = table.find(BindGUI.Modifiers, self.m_Footer["local"]["HelpChanger"]:getSelectedItem())
		local key = self.m_Footer["local"]["SelectedButton"]:getText():lower()
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
	self:changeFooter("new")

	self.m_Footer["new"]["AddNewBindButton"]:setVisible(false)
	self.m_Footer["new"]["EditBindButton"]:setVisible(true)

	local item = self.m_SelectedBind
	self.m_Footer["new"]["FunctionChanger"]:setSelectedItem(BindGUI.Functions[item.action])
	self.m_Footer["new"]["NewTextDE"]:setText(item.parameterDE or "")
	self.m_Footer["new"]["NewTextEN"]:setText(item.parameterEN or "")
	self.m_Footer["new"]["AddNewBindButton"]:setText("Ändern")
	self.m_SelectedBindLabelDE:setText("")
	self.m_SelectedBindLabelEN:setText("")
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
	local parametersDE = self.m_Footer["new"]["NewTextDE"]:getText() or ""
	local parametersEN = self.m_Footer["new"]["NewTextEN"]:getText() or ""
	local name = table.find(BindGUI.Functions, self.m_Footer["new"]["FunctionChanger"]:getSelectedItem())

	if parametersDE == "" and parametersEN == "" then
		return ErrorBox:new(_"Gib mindestens einen Text!")
	end

	if item and item.type ~= "local" and parametersEN:len() <= 1 then
		return ErrorBox:new(_"Gibt einen englischen Text an!")
	end 

	if name then
		if item then
			if BindManager:getSingleton():editBind(item.index, name, parametersDE, parametersEN) then
				SuccessBox:new(_"Bind geändert!")
			else
				ErrorBox:new(_"Bind konnte nicht geändert werden!")
			end
		else
			BindManager:getSingleton():addBind(name, parametersDE, parametersEN)
			SuccessBox:new(_"Bind hinzugefügt! Du kannst nun die Tasten belegen!")
		end
		self:loadBinds()

		self:changeFooter("default")
	else
		ErrorBox:new(_"Gib einen Text an!")
	end
end

BindManageGUI = inherit(GUIForm)
inherit(Singleton, BindManageGUI)

function BindManageGUI:constructor(ownerType)
	GUIWindow.updateGrid()	
	
	self.m_OwnerType = ownerType
	
	self.m_Width = grid("x", 17)
	self.m_Height = grid("y", 15)
	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Binds verwalten", true, true, self)
	self.m_Window:deleteOnClose(true)

	self.m_Grid = GUIGridGridList:new(1, 2, 16, 7, self)
	self.m_Grid:addColumn("Funktion", 0.2)
	self.m_Grid:addColumn("Text", 0.8)

	self.m_Footer = {}

	self.m_AddBindButton = GUIGridButton:new(11, 1, 6, 1, _"neuen Bind hinzufügen", self.m_Window):setBackgroundColor(Color.Green)
  	self.m_AddBindButton.onLeftClick = function()
		self:changeFooter("new")
		self.m_Footer["new"]["NewTextDE"]:setText("")
		self.m_Footer["new"]["NewTextEN"]:setText("")
		self.m_Footer["new"]["AddNewBindButton"]:setVisible(true)
		self.m_Footer["new"]["EditBindButton"]:setVisible(false)
		self.m_Footer["new"]["DeleteBindButton"]:setVisible(false)
	end

	self.m_SelectedBindLabel = GUIGridLabel:new(1, 9, 16, 1, "", self.m_Window):setColor(Color.Accent)

	--default Bind
	self.m_Footer["default"] = {}

	--New Bind
	self.m_Footer["new"] = {}
	self.m_Footer["new"]["FunctionLabel"] = GUIGridLabel:new(1, 14, 3, 1, "Funktion:", self.m_Window)
	self.m_Footer["new"]["FunctionChanger"] = GUIGridChanger:new(5, 14, 4, 1, self.m_Window):setBackgroundColor(Color.Accent)
	for index, name in pairs(BindGUI.Functions) do
		self.m_Footer["new"]["FunctionChanger"]:addItem(name)
	end
	self.m_Footer["new"]["GermanMsgLabel"] = GUIGridLabel:new(1, 10, 16, 1, "Nachricht (Deutsch):", self.m_Window)
	self.m_Footer["new"]["NewTextDE"] = GUIGridEdit:new(1, 11, 16, 1, self.m_Window)
	self.m_Footer["new"]["EnglishMsgLabel"] = GUIGridLabel:new(1, 12, 16, 1, "Nachricht (Englisch):", self.m_Window)
	self.m_Footer["new"]["NewTextEN"] = GUIGridEdit:new(1, 13, 16, 1, self.m_Window)
	self.m_Footer["new"]["AddNewBindButton"] = GUIGridButton:new(9, 14, 4, 1, "Speichern", self.m_Window):setBackgroundColor(Color.Green):setVisible(false)
	self.m_Footer["new"]["AddNewBindButton"].onLeftClick = function () self:editAddBind() end
	self.m_Footer["new"]["EditBindButton"] = GUIGridButton:new(9, 14, 4, 1, "Ändern", self.m_Window):setBackgroundColor(Color.Orange):setVisible(false)
	self.m_Footer["new"]["EditBindButton"].onLeftClick = function () self:editAddBind(self.m_SelectedBind) end
	self.m_Footer["new"]["DeleteBindButton"] = GUIGridButton:new(13, 14, 4, 1, "Löschen", self.m_Window):setBackgroundColor(Color.Orange):setVisible(false)
	self.m_Footer["new"]["DeleteBindButton"].onLeftClick = function () self:deleteBind() end

	for index, footer in pairs(self.m_Footer) do
		if index ~= "default" then
			for i, v in pairs(footer) do
				v:setVisible(false)
			end
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
			for i, v in pairs(footer) do
				v:setVisible(true)
			end
		else
			for i, v in pairs(footer) do
				v:setVisible(false)
			end
		end
	end
end

function BindManageGUI:Event_onReceive(type, id, binds)
	self.m_Binds = binds
	self.m_Grid:clear()
	self.m_Grid:addItemNoClick(BindGUI.Headers[type], "")
	for id, data in pairs(binds) do
		local tMessage = data["Message"]
		if localPlayer:getLocale() == "en" and data["MessageEN"] and data["MessageEN"] ~= "" then
			tMessage = data["MessageEN"]
		end

		local item = self.m_Grid:addItem(data["Func"], string.short(tMessage or "", MAX_PARAMETER_LENGTH_MANAGE))
		item.action =  data["Func"]
		item.parameter =  data["Message"]
		item.parameterEN =  data["MessageEN"]
		item.id = id
		item.onLeftClick = bind(self.onBindSelect, self, item)
	end
end

function BindManageGUI:editAddBind(item)
	local parametersDE = self.m_Footer["new"]["NewTextDE"]:getText()
	local parametersEN = self.m_Footer["new"]["NewTextEN"]:getText()
	local name = table.find(BindGUI.Functions, self.m_Footer["new"]["FunctionChanger"]:getSelectedItem())
	if parametersEN:len() >= 1 and name then
		if item and item.id then
			triggerServerEvent("bindEditServerBind", localPlayer, self.m_OwnerType, item.id, name, parametersDE, parametersEN)
		else
			triggerServerEvent("bindAddServerBind", localPlayer, self.m_OwnerType, name, parametersDE, parametersEN)
		end
		self:changeFooter("default")
	else
		ErrorBox:new(_"Du brauchst einen englischen Text")
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
	self.m_Footer["new"]["FunctionChanger"]:setSelectedItem(BindGUI.Functions[item.action])
	self.m_Footer["new"]["NewTextDE"]:setText(item.parameter or "")
	self.m_Footer["new"]["NewTextEN"]:setText(item.parameterEN or "")
	self.m_Footer["new"]["EditBindButton"]:setVisible(true)
	self.m_Footer["new"]["DeleteBindButton"]:setVisible(true)
	self.m_Footer["new"]["AddNewBindButton"]:setVisible(false)
end
