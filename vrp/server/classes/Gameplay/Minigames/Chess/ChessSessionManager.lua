ChessSessionManager = inherit(Singleton)

addRemoteEvents{"onServerGetChessMove", "onServerGetSurrender", "chessQuestion", "chessQuestionAccept", "chessQuestionDecline"}

local GAME_TIME = 6*60
local REQUEST_TIMEOUT = 60*1000

function ChessSessionManager:constructor()
	self.m_Map = {}
	addEventHandler("onServerGetChessMove", root, bind(ChessSessionManager.Event_GetChessMove, self))
	addEventHandler("onServerGetSurrender", root, bind(ChessSessionManager.Event_GetSurrender, self))
	addEventHandler("chessQuestion", root, bind(ChessSessionManager.Event_Question, self))
	addEventHandler("chessQuestionAccept", root, bind(ChessSessionManager.Event_QuestionAccept, self))
	addEventHandler("chessQuestionDecline", root, bind(ChessSessionManager.Event_QuestionDecline, self))
end

function ChessSessionManager:destructor()

end

function ChessSessionManager:Event_newGame(player1, player2)
	if player1 == player2 then return end
	if self:getPlayerGame(player1) or self:getPlayerGame(player2) then
		player1:sendError(_("Du oder dein Gegner spielt bereits Schach!", player1))
		player2:sendError(_("Du oder dein Gegner spielt bereits Schach!", player2))
		return
	end
	self.m_Map[#self.m_Map + 1] = ChessSession:new(#self.m_Map + 1, {player1, player2}, GAME_TIME)
end

function ChessSessionManager:removeReference(obj)
	for i = #self.m_Map, 1, -1 do
		if obj == self.m_Map[i] then
			table.remove(self.m_Map, i)
		end
	end
end

function ChessSessionManager:Event_GetChessMove(from, to, promo)
	if client and client == source then
		local game = self:getPlayerGame(client)
		if game then
			game:movePiece(client, from, to, promo)
		end
	end
end

function ChessSessionManager:Event_GetSurrender()
	if client and client == source then
		local game = self:getPlayerGame(client)
		if game then
			game:surrender(client)
		end
	end
end

function ChessSessionManager:Event_Question(target)
	if not client or not isElement(target) or getElementType(target) ~= "player" or target == client then return end
	if self:getPlayerGame(client) or self:getPlayerGame(target) then
		client:sendError(_("Du oder dein Gegner spielt bereits Schach!", client))
		return
	end
	if client.chessRequestTarget == target and getTickCount() - client.chessRequestTick < REQUEST_TIMEOUT then
		client:sendError(_("Du hast dem Spieler bereits eine Anfrage gesendet", client))
		return
	end
	client:sendShortMessage(_("Du hast eine Schach-Anfrage an %s gesendet!", client, target:getName()))
	client.chessRequestTarget = target
	client.chessRequestTick = getTickCount()
	target:triggerEvent("onAppDashboardGameInvitation", client, "Schach", "chessQuestionAccept", "chessQuestionDecline", client)
end

function ChessSessionManager:Event_QuestionAccept(host)
	if not client or not isElement(host) or host.chessRequestTarget ~= client then return end
	host.chessRequestTarget = nil
	self:Event_newGame(host, client)
end

function ChessSessionManager:Event_QuestionDecline(host)
	if not client or not isElement(host) or host.chessRequestTarget ~= client then return end
	host.chessRequestTarget = nil
	host:sendError(_("Der Spieler %s hat abgelehnt!", host, client:getName()))
end

function ChessSessionManager:getPlayerGame(player)
	for index = 1, #self.m_Map do
		if self.m_Map[index]:isThisPlayer(player) then
			return self.m_Map[index]
		end
	end
	return false
end
