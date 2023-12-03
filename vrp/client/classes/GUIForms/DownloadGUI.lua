DownloadGUI = inherit(GUIForm)
inherit(Singleton, DownloadGUI)

function DownloadGUI:constructor()
	GUIForm.constructor(self, 0, 0, screenWidth, screenHeight)

	self.m_Logo = GUIImage:new(screenWidth/2 - 350/2, screenHeight/2 - 200/2 - 120, 350, 167, "files/images/Logo.png", self)
	self.m_Text = GUILabel:new(0, screenHeight/2 - 150/2 + 50, screenWidth, 50, _"Bitte warte, bis die erforderlichen Spielinhalte bereit sind...", self):setAlignX("center"):setFont(VRPFont(40))
	if screenWidth < 1024 then
		self.m_ResolutionWarning = GUILabel:new(0, screenHeight - 200, screenWidth, 20, _"Bitte erhöhe deine Auflösung, um Darstellungsfehler zu vermeiden!", self):setAlignX("center"):setFont(VRPFont(30)):setColor(Color.Red)
	end
	if core:get("Login", "LoginMusic", true) then
		self.m_MusicText = GUILabel:new(0, screenHeight - 30, screenWidth, 30, _"Drücke 'm', um die Musik zu stoppen!", self):setAlignX("center")
	else
		self.m_MusicText = GUILabel:new(0, screenHeight - 30, screenWidth, 30, _"Drücke 'm', um die Musik zu starten!", self):setAlignX("center")
	end
	self.m_ProgressBar = GUIProgressBar:new(screenWidth/2 - 500/2, screenHeight/2 - 150/2 + 110, 500, 30, self)

	self:launchMusic()
end

function DownloadGUI:launchMusic()
	if not self:isVisible() then return end
	if core:get("Login", "LoginMusic", true) then
		self.m_Music = playSound(INGAME_WEB_PATH .. "/ingame/DownloadMusic.mp3", true)
		self.m_Music:setVolume(0.3)
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

function DownloadGUI:onProgress(p, fullSize)
	self.m_ProgressBar:setProgress(tonumber(p) or 0)

	local downloadedSize = (tonumber(p) or 0)*(fullSize/100)
	self:setStateText(("%.2fMB / %.2fMB"):format(downloadedSize/1024/1024, fullSize/1024/1024))
end

function DownloadGUI:onWrite(files)
	self.m_ProgressBar:setProgress(100)
	self:setStateText(_("Schreibe %d Dateien auf Festplatte...", files))
end

function DownloadGUI:setStateText(text)
	self.m_ProgressBar:setText(text)
end

function DownloadGUI:onComplete()
	core:ready()
	if self.m_Music and isElement(self.m_Music) then
		stopSound(self.m_Music)
	end
	fadeCamera(true)
	self:fadeOut(750)
	setTimer(
		function()
			self:setVisible(false)
			local pwhash = core:get("Login", "password", "")
			local username = core:get("Login", "username", "")
			lgi = LoginGUI:new(username, pwhash)
		end,
	200, 1)
	delete(self)
end
