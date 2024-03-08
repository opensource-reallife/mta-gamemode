-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Phone/AppSettings.lua
-- *  PURPOSE:     Phone settings app class
-- *
-- ****************************************************************************
AppSettings = inherit(PhoneApp)

function AppSettings:constructor()
	PhoneApp.constructor(self, _"Einstellungen", "IconSettings.png")
end

function AppSettings:onOpen(form)
	self.m_Label = GUILabel:new(10, 10, 200, 50, _"Einstellungen", form)
	self.m_Label:setColor(Color.Black)

	GUILabel:new(10, 65, 200, 20, _"Handy", form):setColor(Color.Black)
	self.m_PhoneChanger = GUIChanger:new(10, 85, 200, 30, form)
	self.m_PhoneChanger.onChange =
		function(modelName)
			local modelId = PHONE_MODELS[modelName]
			Phone:getSingleton():setPhone(modelId)
			core:getConfig():set("Phone", "PhoneModel", modelId)
		end

	for _, model in pairs(PHONE_MODELS) do
		if type(model) == "table" then
			self.m_PhoneChanger:addItem(model.Name)
		end
	end

	local currentModelId = Phone:getSingleton().m_Phone
	self.m_PhoneChanger:setSelectedItem(PHONE_MODELS[currentModelId].Name)

	GUILabel:new(10, 130, 200, 20, _"Hintergrund", form):setColor(Color.Black)
	self.m_BackgroundChanger = GUIChanger:new(10, 150, 200, 30, form)
	self.m_BackgroundChanger.onChange =
		function(text)
			Phone:getSingleton():setBackground(text)
			core:getConfig():set("Phone", "Background", text)
		end

	local backgrounds = {"Xperia_X", "Google_Pixel", "iOS_7", "iOS_10", "Nexus", "Xperia_Z3", "OnePlus_3T"}
	for _, background in pairs(backgrounds) do
		self.m_BackgroundChanger:addItem(background)
	end

	if core:get("Phone", "Background") then
		self.m_BackgroundChanger:setSelectedItem(core:get("Phone", "Background"))
	end

	GUILabel:new(10, 195, 200, 20, _"Klingelton", form):setColor(Color.Black)
	self.m_RingtoneChanger = GUIChanger:new(10, 215, 200, 30, form)
	self.m_RingtoneChanger.onChange =
		function(text)
			self:stopRingtone()

			local path = ("files/audio/Ringtones/Klingelton%s.mp3"):format(text:gsub(".* ", ""))
			self.m_Sound = playSound(path)

			core:getConfig():set("Phone", "Ringtone", path)
		end

	local items = {}
	for i = 1, 14 do
		local path = ("files/audio/Ringtones/Klingelton%s.mp3"):format(i)
		items[path] = self.m_RingtoneChanger:addItem(_("Klingelton %d", i))
	end

	local selected = core:getConfig():get("Phone", "Ringtone", "files/audio/Ringtones/Klingelton1.mp3")
	if items[selected] then
		self.m_RingtoneChanger:setIndex(items[selected], true)
	end

	self.m_ShowSkinCheckbox = GUICheckbox:new(10, 265, 300, 20, _"Skin bei Anruf anzeigen", form):setFont(VRPFont(25)):setFontSize(1)
	self.m_ShowSkinCheckbox.onChange =
		function(state)
			core:getConfig():set("Phone", "ShowSkin", state)
		end
	local selected = core:getConfig():get("Phone", "ShowSkin", true)
	if selected then
		self.m_ShowSkinCheckbox:setChecked(true)
	end

	local margin = 35
	if fileExists(CUSTOM_RINGSOUND_PATH) then
		self.m_CustomRingtoneCheckbox = GUICheckbox:new(10, 265 + margin, 300, 20, _"Eigenen Klingelton benutzen", form):setFont(VRPFont(25)):setFontSize(1)
		self.m_CustomRingtoneCheckbox:setChecked(true)
		self.m_CustomRingtoneCheckbox:setEnabled(false)
		margin = margin + 35
	end

	if fileExists(CUSTOM_PHONE_BACKGROUND_PATH) then
		self.m_CustomRingtoneCheckbox = GUICheckbox:new(10, 265 + margin, 300, 20, _"Eigenen Hintergrund benutzen", form):setFont(VRPFont(25)):setFontSize(1)
		self.m_CustomRingtoneCheckbox:setChecked(true)
		self.m_CustomRingtoneCheckbox:setEnabled(false)
		margin = margin + 35
	end

	if fileExists(CUSTOM_PHONE_MODEL_PATH) then
		self.m_CustomRingtoneCheckbox = GUICheckbox:new(10, 265 + margin, 300, 20, _"Eigenes Modell benutzen", form):setFont(VRPFont(25)):setFontSize(1)
		self.m_CustomRingtoneCheckbox:setChecked(true)
		self.m_CustomRingtoneCheckbox:setEnabled(false)
		margin = margin + 35
	end
end

function AppSettings:onClose()
	if self.m_Sound and isElement(self.m_Sound) then
		destroyElement(self.m_Sound)
	end
end

function AppSettings:stopRingtone()
	if self.m_Sound and isElement(self.m_Sound) then
		destroyElement(self.m_Sound)
	end
end
