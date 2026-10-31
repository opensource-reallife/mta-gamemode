-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/HelpGUI.lua
-- *  PURPOSE:     HelpGUI GUI
-- *
-- ****************************************************************************
HelpGUI = inherit(GUIForm)
inherit(Singleton, HelpGUI)

function HelpGUI:constructor()
	GUIWindow.updateGrid()
	self.m_Width = grid("x", 28)
	self.m_Height = grid("y", 16)

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)


	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Hilfe", true, true, self)
	self.m_Window:addTitlebarButton(FontAwesomeSymbols.Home, bind(self.internalBrowserNavigateHome, self))
	self.m_Window:addTitlebarButton(FontAwesomeSymbols.Expand, bind(self.openFullScreen, self))

	-- "https://forum.openreallife.net/exo-api?token=%s"
	self.m_WebView = GUIGridWebView:new(1, 1, 27, 15, (CP_WEB_PATH .. "/ingame.php?to=lexicon&token=%s"):format(localPlayer:getCpToken()), true, self.m_Window)
	self.m_WebView.onDocumentReady = bind(self.onBrowserReady, self)
end

function HelpGUI:openFullScreen()
	local url = self.m_BrowserReady and self.m_WebView:getUnderlyingBrowser():getURL() or CP_WEB_PATH .. "/lexicon.php"
	delete(self)
	WebBrowser:new(url)
end

function HelpGUI:internalBrowserNavigateHome()
	if not self.m_BrowserReady then return false end
	self.m_WebView:loadURL(CP_WEB_PATH .. (self.m_Embed and "/lexicon.php?ingame=1" or "/lexicon.php"))
end


function HelpGUI:onBrowserReady(url)
	self.m_BrowserReady = true
	if type(url) == "string" and not url:find(CP_WEB_PATH, 1, true) then
		self:internalBrowserNavigateHome()
		return
	end
	if self.m_RequestedPage then
		self.m_WebView:loadURL(self.m_RequestedPage)
		self.m_RequestedPage = nil
	end
end

function HelpGUI:openLexiconPage(url)
	self.m_Embed = true
	local absoluteUrl = ("%s/ingame.php?to=lexicon&forum=%s&token=%s"):format(CP_WEB_PATH, url, localPlayer:getCpToken())

	if self.m_BrowserReady then --load URL
		self.m_WebView:loadURL(absoluteUrl)
	else -- save url for when browser got created
		self.m_RequestedPage = absoluteUrl
	end
end

function HelpGUI:select(title)
	if self.m_Items[title] then
		self.m_Grid:onInternalSelectItem(self.m_Items[title])
		self.m_Items[title].onLeftClick()
	end
end

function HelpGUI:isBackgroundBlurred()
	return true
end
