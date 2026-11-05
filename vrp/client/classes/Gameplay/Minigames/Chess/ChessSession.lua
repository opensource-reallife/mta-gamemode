ChessSession = inherit(Singleton)

function ChessSession:constructor()
	addRemoteEvents{"onClientChessStart", "onClientChessStop", "onClientChessUpdate"}
	addEventHandler("onClientChessStart", localPlayer, bind(ChessSession.Event_startGame, self))
	addEventHandler("onClientChessUpdate", localPlayer, bind(ChessSession.Event_updateGame, self))
	addEventHandler("onClientChessStop", localPlayer, bind(ChessSession.Event_endGame, self))
end

function ChessSession:clear()
	if self.m_ChessGraphics then
		delete(self.m_ChessGraphics)
	end
	self.m_ChessGraphics = nil
	localPlayer.m_InChessGame = false
end

function ChessSession:sendMove(from, to, promo)
	triggerServerEvent("onServerGetChessMove", localPlayer, from, to, promo)
end

function ChessSession:surrender()
	triggerServerEvent("onServerGetSurrender", localPlayer)
end

function ChessSession:Event_startGame(data)
	self:clear()
	localPlayer.m_InChessGame = true
	self.m_ChessGraphics = ChessGraphics:new(data.color, data.white, data.black)
	self.m_ChessGraphics:updateGame(data)
end

function ChessSession:Event_updateGame(data)
	if self.m_ChessGraphics then
		self.m_ChessGraphics:updateGame(data)
		if data.notation then
			playSound("files/audio/chess/move.ogg")
		end
	end
end

function ChessSession:Event_endGame(winner, reason, times)
	if self.m_ChessGraphics then
		self.m_ChessGraphics:showResult(winner, reason, times)
	end
end

function ChessSession:destructor()

end
