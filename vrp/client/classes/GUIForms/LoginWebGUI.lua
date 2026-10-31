LoginWebGUI = inherit(GUIForm)
inherit(Singleton, LoginWebGUI)

addEvent("loginWebReady")
addEvent("loginWebLogin")
addEvent("loginWebRegister")
addEvent("loginWebCheck")
addEvent("loginWebPassword")
addEvent("loginWebView")
addEvent("loginWebRules")
addEvent("loginWebLocale")
addEvent("loginWebMusic")
addEvent("loginWebForgot")
addEvent("loginWebTicket")
addEvent("loginWebCopy")
addEvent("loginWebSetEmail")

function LoginWebGUI:constructor(savedName, savedPW)
	LoginGUI.startCameraDrive()
	showChat(false)
	setPlayerHudComponentVisible("radar",false)

	self.m_SavedName = savedName ~= "" and savedName or nil
	self.m_SavedPW = savedPW ~= "" and savedPW or nil
	self.m_Queue = {}

	GUIForm.constructor(self, 0, 0, screenWidth, screenHeight, true)
	self.m_WebView = GUIWebView:new(0, 0, screenWidth, screenHeight, "http://mta/local/files/html/login.htm", true, self)
	self.m_Browser = self.m_WebView:getUnderlyingBrowser()

	addEventHandler("loginWebReady", self.m_Browser, bind(self.Event_ready, self))
	addEventHandler("loginWebLogin", self.m_Browser, bind(self.Event_login, self))
	addEventHandler("loginWebRegister", self.m_Browser, bind(self.Event_register, self))
	addEventHandler("loginWebCheck", self.m_Browser, function(field, value) triggerServerEvent("accountRegisterCheck", localPlayer, field, value) end)
	addEventHandler("loginWebPassword", self.m_Browser, function(pw, seq) triggerServerEvent("accountPasswordCheck", localPlayer, hash("sha1", pw), seq) end)
	addEventHandler("loginWebView", self.m_Browser, function(view) if view == "register" then self:checkRegister() end end)
	addEventHandler("loginWebRules", self.m_Browser, function() if self:checkExternalWebsitesActivated() then LoginRuleGUI:new() end end)
	addEventHandler("loginWebLocale", self.m_Browser, bind(self.Event_locale, self))
	addEventHandler("loginWebMusic", self.m_Browser, function()
		local music = LoginMusicGUI:getSingleton()
		if music.m_Muted then music.m_StartMusicFunc() else music.m_StopMusicFunc() end
	end)
	addEventHandler("loginWebForgot", self.m_Browser, function(who) triggerServerEvent("accountPasswordForgot", localPlayer, who) end)
	addEventHandler("loginWebTicket", self.m_Browser, function(name, text, email, notify, oldSerial) triggerServerEvent("accountGuestTicket", localPlayer, name, text, email, notify, oldSerial) end)
	addEventHandler("loginWebSetEmail", self.m_Browser, function(email) triggerServerEvent("accountSetEmail", localPlayer, email) end)
	addEventHandler("loginWebCopy", self.m_Browser, function(text)
		setClipboard(text)
		ShortMessage:new(_"In die Zwischenablage kopiert.", nil, Color.Green, 3000)
	end)

	if DEBUG and self.m_SavedName and self.m_SavedPW then
		self:Event_login(self.m_SavedName, "", true, true)
	end
end

function LoginWebGUI:virtual_destructor()
	if LoginMusicGUI:getSingleton() then LoginMusicGUI:getSingleton():delete() end
	LoginGUI.stopCameraDrive()
	Cursor:hide(true)
end

function LoginWebGUI:call(func, data)
	if not self.m_Ready then
		table.insert(self.m_Queue, {func, data})
		return
	end
	self.m_Browser:executeJavascript(("LoginUI.%s(%s)"):format(func, toJSON(data or {}, true):sub(2, -2)))
end

function LoginWebGUI:Event_ready()
	self.m_Ready = true
	self:call("init", {name = self.m_SavedName or "", saved = self.m_SavedPW and true or false, locale = localPlayer:getLocale(), project = PROJECT_NAME})
	for _, v in ipairs(self.m_Queue) do
		self:call(v[1], v[2])
	end
	self.m_Queue = {}
end

function LoginWebGUI:Event_login(name, pw, save, useSaved)
	if self.m_LoggingIn then return end
	if not self:checkExternalWebsitesActivated() then
		self:call("busy", {state = false})
		return
	end
	self.m_LoginName = name
	self.m_SaveLogin = save == true or save == "true" or save == "1"

	if (useSaved == true or useSaved == "true" or useSaved == "1") and self.m_SavedPW then
		triggerServerEvent("accountlogin", root, name, "", self.m_SavedPW, nil, true)
	else
		triggerServerEvent("accountlogin", root, name, pw, nil, self.m_SaveLogin, true)
	end
	self:setLoggingIn(true)
end

function LoginWebGUI:Event_register(name, pw, email, referrer)
	if self.m_LoggingIn then return end
	if not self:checkExternalWebsitesActivated() then
		self:call("busy", {state = false})
		return
	end
	self.m_SaveLogin = false
	triggerServerEvent("accountregister", root, name, pw, email, referrer)
	self:setLoggingIn(true)
end

function LoginWebGUI:Event_locale(locale)
	core:set("HUD", "locale", locale == "en" and "en" or "de")
	localPlayer:setLocale(core:get("HUD", "locale"))
	triggerServerEvent("playerLocale", localPlayer, localPlayer:getLocale())
	ShortMessage:new(_"Bitte verbinde dich erneut, damit die Änderung ihre volle Wirkung zeigt!", _"Sprachänderung", Color.DarkLightBlue)
	LoginMusicGUI:getSingleton():updateText()
end

function LoginWebGUI:initClose(callback)
	self:call("close")
	setTimer(function()
		self:delete()
		if callback then callback() end
	end, 300, 1)
end

function LoginWebGUI:checkRegister()
	triggerServerEvent("checkRegisterAllowed", localPlayer)
end

function LoginWebGUI:checkExternalWebsitesActivated()
	if getBrowserSettings().RemoteEnabled == false then
		ErrorBox:new(_"Bitte aktiviere in den Einstellungen unter Webbrowser die Option Externe Webseiten aktivieren!")
		return false
	end
	return true
end

function LoginWebGUI:setLoggingIn(state)
	self.m_LoggingIn = state
	self:call("busy", {state = state})

	if state then
		self.m_UpdateTimer = setTimer(bind(self.updateTexts, self), 250, 0)
	else
		if self.m_UpdateTimer and isTimer(self.m_UpdateTimer) then killTimer(self.m_UpdateTimer) end
		self.m_QueuePosition = nil
		self.m_ConnectionAttempt = nil
	end
end

function LoginWebGUI:updateTexts()
	local text = ""
	if self.m_QueuePosition and self.m_QueuePosition > 1 then
		text = _("Position in Warteschlange: %d", self.m_QueuePosition)
	elseif self.m_ConnectionAttempt and self.m_ConnectionAttempt > 0 then
		text = _("Verbindung zum Forum fehlgeschlagen! (%d/%d)\nVersuche erneut%s", self.m_ConnectionAttempt-1, FORUM_MAX_CONNECTION_ATTEMPTS-1, "...")
	end
	if text ~= self.m_StatusText then
		self.m_StatusText = text
		self:call("status", {text = text})
	end
end

addEvent("receiveRegisterAllowed", true)
addEventHandler("receiveRegisterAllowed", root,
	function(state, name)
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():call("serial", {allowed = state, name = name or ""})
		end
	end
)

addEvent("receiveRegisterCheck", true)
addEventHandler("receiveRegisterCheck", root,
	function(field, value, ok, code, extra)
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():call("check", {field = field, value = value, ok = ok, code = code or "", extra = extra or ""})
		end
	end
)

addEvent("receivePasswordCheck", true)
addEventHandler("receivePasswordCheck", root,
	function(seq, count)
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():call("pwned", {seq = tonumber(seq) or 0, count = count})
		end
	end
)

addEvent("receiveGuestTicket", true)
addEventHandler("receiveGuestTicket", root,
	function(ok, ref, code)
		if not LoginWebGUI:isInstantiated() then return end
		if not ok then
			local texts = {
				name = _"Gib den Namen deines Accounts an (3–22 Zeichen).",
				text = _"Beschreibe dein Problem in mindestens 10 Zeichen.",
				email = _"Die E-Mail-Adresse ist ungültig.",
				wait = _"Du hast gerade erst ein Ticket erstellt. Versuche es später erneut.",
			}
			ErrorBox:new(texts[ref] or _"Das Ticket konnte nicht erstellt werden. Versuche es später erneut.")
		end
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():call("ticket", {ok = ok and true or false, ref = ok and ref or "", code = ok and code or "", url = CP_WEB_PATH .. "/ticket"})
		end
	end
)

addEvent("receivePasswordForgot", true)
addEventHandler("receivePasswordForgot", root,
	function(ok, wait)
		if not LoginWebGUI:isInstantiated() then return end
		if not ok then
			ErrorBox:new(tonumber(wait) and _("Zu viele Anfragen. Versuche es in %d Minuten erneut.", tonumber(wait)) or _"Die Anfrage hat nicht geklappt. Versuche es später erneut.")
		end
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():call("forgot", {ok = ok and true or false})
		end
	end
)

addEvent("loginNeedReset", true)
addEventHandler("loginNeedReset", root,
	function(name)
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():setLoggingIn(false)
			LoginWebGUI:getSingleton():call("needreset", {name = name or ""})
		end
	end
)

addEvent("loginNeedEmail", true)
addEventHandler("loginNeedEmail", root,
	function()
		if LoginWebGUI:isInstantiated() then
			LoginWebGUI:getSingleton():setLoggingIn(false)
			LoginWebGUI:getSingleton():call("needemail")
		end
	end
)

addEvent("receiveSetEmail", true)
addEventHandler("receiveSetEmail", root,
	function(ok, code)
		if LoginWebGUI:isInstantiated() then
			if ok then
				LoginWebGUI:getSingleton():setLoggingIn(true)
			else
				LoginWebGUI:getSingleton():call("setemail", {ok = false, code = code or "email_invalid"})
			end
		end
	end
)

addEvent("loginfailed", true)
addEventHandler("loginfailed", root,
	function(text)
		if not LoginWebGUI:isInstantiated() then return end
		ErrorBox:new(text)
		LoginWebGUI:getSingleton():setLoggingIn(false)
	end
)
addEvent("registerfailed", true)
addEventHandler("registerfailed", root,
	function(text)
		if not LoginWebGUI:isInstantiated() then return end
		ErrorBox:new(text)
		LoginWebGUI:getSingleton():setLoggingIn(false)
	end
)

addEvent("closeLogin", true)
addEventHandler("closeLogin", root,
	function()
		if not LoginWebGUI:isInstantiated() then return end
		LoginWebGUI:getSingleton():initClose()
	end
)

addEvent("loginInformationUpdate", true)
addEventHandler("loginInformationUpdate", root,
	function(queuePosition, connectionAttempt)
		if LoginWebGUI:isInstantiated() then
			if connectionAttempt == true then
				LoginWebGUI:getSingleton():setLoggingIn(false)
				ErrorBox:new(_"Verbindung zum Forum nicht möglich!")
				return
			end
			LoginWebGUI:getSingleton().m_QueuePosition = queuePosition
			LoginWebGUI:getSingleton().m_ConnectionAttempt = connectionAttempt
		end
	end
)

addEvent("loginsuccess", true)
addEventHandler("loginsuccess", root,
	function(pwhash)
		if not LoginWebGUI:isInstantiated() then return end
		local lgi = LoginWebGUI:getSingleton()

		if lgi.m_SaveLogin and pwhash then
			core:set("Login", "username", lgi.m_LoginName)
			core:set("Login", "password", pwhash)
		else
			core:set("Login", "password", "")
		end

		core:afterLogin()
		lgi:setLoggingIn(false)
		lgi:initClose()

		-- Disclaimer for non-german players
		if localPlayer:getLocale() ~= "de" then
			ShortMessage:new("Please note that the English translation is still being worked on. If a translation is missing, you will be shown the German text instead.", "Disclaimer", Color.Red, 10000)
		end
	end
)