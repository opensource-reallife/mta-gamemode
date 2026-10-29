EasterEgg.QRCode = inherit(GUIForm3D)
inherit(Singleton, EasterEgg.QRCode)

function EasterEgg.QRCode:constructor()
	GUIForm3D.constructor(self, Vector3(1478.666, -1774.049, 9.748), 0, Vector3(0, 0, 90), Vector2(2, 2), Vector2(300, 300), 15)
end

function EasterEgg.QRCode:onStreamIn(surface)
	if localPlayer:getCpToken() == "" then
		if isTimer(self.m_WaitTimer) then killTimer(self.m_WaitTimer) end
		self.m_WaitTimer = setTimer(function() if self.m_CacheArea == surface then self:onStreamIn(surface) end end, 2000, 1)
		return
	end
	self.m_Url = (CP_WEB_PATH .. "/qr.php?token=%s"):format(localPlayer:getCpToken())
	GUIWebView:new(0, 0, 300, 300, self.m_Url, true, surface)
end

function EasterEgg.QRCode:onStreamOut()
	if isTimer(self.m_WaitTimer) then killTimer(self.m_WaitTimer) end
end
