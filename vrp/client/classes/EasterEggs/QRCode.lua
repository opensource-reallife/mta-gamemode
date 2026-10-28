EasterEgg.QRCode = inherit(GUIForm3D)
inherit(Singleton, EasterEgg.QRCode)

function EasterEgg.QRCode:constructor()
	GUIForm3D.constructor(self, Vector3(1478.666, -1774.049, 9.748), 0, Vector3(0, 0, 90), Vector2(2, 2), Vector2(300, 300), 15)
end

function EasterEgg.QRCode:onStreamIn(surface)
	-- QR-Code kommt vom ControlPanel (CP-Token wie beim WebPanel); der Scan-Link darin vergibt dort das Achievement
	self.m_Url = (CP_WEB_PATH .. "/qr.php?token=%s"):format(localPlayer:getCpToken())
	GUIWebView:new(0, 0, 300, 300, self.m_Url, true, surface)
end
