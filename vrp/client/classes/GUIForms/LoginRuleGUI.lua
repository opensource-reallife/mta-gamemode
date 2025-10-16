LoginRuleGUI = inherit(GUIForm)
inherit(Singleton, LoginRuleGUI)

function LoginRuleGUI:constructor()
	GUIWindow.updateGrid()			-- initialise the grid function to use a window
	self.m_Width = grid("x", 16) 	-- width of the window
	self.m_Height = grid("y", 16) 	-- height of the window

	GUIForm.constructor(self, screenWidth/2-self.m_Width/2, screenHeight/2-self.m_Height/2, self.m_Width, self.m_Height, true)
	self.m_Window = GUIWindow:new(0, 0, self.m_Width, self.m_Height, _"Regelwerk", true, true, self)

	self.m_Browser = GUIGridWebView:new(1, 1, 15, 15, "https://forum.openreallife.net/cms/index.php?board/24-regeln/", true, self.m_Window)
end

function LoginRuleGUI:destructor()
	GUIForm.destructor(self)
end