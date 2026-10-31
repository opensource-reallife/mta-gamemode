LoginMusicGUI = inherit(GUIForm)
inherit(Singleton, LoginMusicGUI)

function LoginMusicGUI:constructor()
	GUIForm.constructor(self, 0, 0, screenWidth, screenHeight)
	self:launchMusic()
end

function LoginMusicGUI:launchMusic()
	self.m_Muted = not core:get("Login", "LoginMusic", true)
	self.m_MusicText = GUILabel:new(0, screenHeight - 28, screenWidth, 24, "", self):setAlignX("center")
	self.m_Music = playSound(INGAME_WEB_PATH .. "/ingame/DownloadMusic.mp3", true)
	if self.m_Music then self.m_Music:setVolume(self.m_Muted and 0 or 0.3) end
	self:updateText()

	self.m_StopMusicFunc = function()
		if not self.m_Muted then
			self.m_Muted = true
			if self.m_Music and isElement(self.m_Music) then self.m_Music:setVolume(0) end
			self:updateText()
			core:set("Login", "LoginMusic", false)
			self:bind("m", self.m_StartMusicFunc)
		end
	end

	self.m_StartMusicFunc = function()
		if self.m_Muted then
			self.m_Muted = false
			if self.m_Music and isElement(self.m_Music) then self.m_Music:setVolume(0.3) end
			self:updateText()
			core:set("Login", "LoginMusic", true)
			self:bind("m", self.m_StopMusicFunc)
		end
	end

	if core:get("Login", "LoginMusic", true) then
		self:bind("m", self.m_StopMusicFunc)
	else
		self:bind("m", self.m_StartMusicFunc)
	end
end

function LoginMusicGUI:updateText()
	self.m_MusicText:setText(self.m_Muted and _"Drücke 'm', um die Musik zu starten!" or _"Drücke 'm', um die Musik zu stoppen!")
end

function LoginMusicGUI:virtual_destructor()
	if self.m_Music and isElement(self.m_Music) then
		stopSound(self.m_Music)
	end
end