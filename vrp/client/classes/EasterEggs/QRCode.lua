EasterEgg.QRCode = inherit(GUIForm3D)
inherit(Singleton, EasterEgg.QRCode)

function EasterEgg.QRCode:constructor()
	GUIForm3D.constructor(self, Vector3(1478.666, -1774.049, 9.748), 0, Vector3(0, 0, 90), Vector2(2, 2), Vector2(300, 300), 15)
end

function EasterEgg.QRCode:onStreamIn(surface)
	local json = toJSON({["sId"] = localPlayer:getSessionId(), ["id"] = localPlayer:getPrivateSync("Id"), ["name"] = localPlayer:getName()}, true)
	self.m_Url = (INGAME_WEB_PATH .. "/ingame/qr/qr.php?size=300x300&text=" .. INGAME_WEB_PATH .. "/ingame/qr/result.php?data=%s"):format(json:sub(2, #json-1))
	outputDebug(self.m_Url)
	GUIWebView:new(0, 0, 300, 300, self.m_Url, true, surface)
end
