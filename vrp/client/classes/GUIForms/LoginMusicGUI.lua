LoginMusicGUI = inherit(GUIForm)
inherit(Singleton, GUIForm)

function LoginMusicGUI:constructor()
	GUIForm.constructor(self, 0, 0, screenWidth, screenHeight)
	self:launchMusic()
end

function LoginMusicGUI:launchMusic()
	if core:get("Login", "LoginMusic", true) then
		self.m_MusicText = GUILabel:new(0, screenHeight - 28, screenWidth, 24, _"Drücke 'm', um die Musik zu stoppen!", self):setAlignX("center")
		self.m_Music = playSound(INGAME_WEB_PATH .. "/ingame/DownloadMusic.mp3", true)
		self.m_Music:setVolume(0.3)
	else
		self.m_MusicText = GUILabel:new(0, screenHeight - 28, screenWidth, 24, _"Drücke 'm', um die Musik zu starten!", self):setAlignX("center")
	end
	
	self.m_StopMusicFunc = function()
		if self.m_Music then
			destroyElement(self.m_Music)
			self.m_Music = nil
			self.m_MusicText:setText(_"Drücke 'm', um die Musik zu starten!")
			core:set("Login", "LoginMusic", false)
			self:bind("m", self.m_StartMusicFunc)
		end
	end

	self.m_StartMusicFunc = function()
		if not self.m_Music then
			self.m_Music = playSound(INGAME_WEB_PATH .. "/ingame/DownloadMusic.mp3", true)
			self.m_Music:setVolume(0.3)
			self.m_MusicText:setText(_"Drücke 'm', um die Musik zu stoppen!")
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

function LoginMusicGUI:virtual_destructor()
	if self.m_Music and isElement(self.m_Music) then
		stopSound(self.m_Music)
	end
end