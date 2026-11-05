ChessSession = inherit(Object)

local PIECE_LETTERS = {k = "K", q = "D", r = "T", b = "L", n = "S", p = ""}

function ChessSession:constructor(id, players, time)
	self.m_ID = id
	self.m_Players = players
	self.m_TimeLeft = {w = time*1000, b = time*1000}
	self.m_Captured = {w = "", b = ""}
	self.m_Game = ChessLogic.newGame()
	self.m_QuitEvent = bind(ChessSession.Event_onPlayerQuit, self)
	addEventHandler("onPlayerQuit", players[1], self.m_QuitEvent)
	addEventHandler("onPlayerQuit", players[2], self.m_QuitEvent)

	self:startClock()
	local data = self:createUpdate()
	data.white, data.black = players[1]:getName(), players[2]:getName()
	for i, player in ipairs(players) do
		data.color = i == 1 and "w" or "b"
		data.moves = data.color == data.turn and ChessLogic.moveMap(self.m_Game.state) or {}
		player:triggerEvent("onClientChessStart", data)
	end
end

function ChessSession:destructor()
	ChessSessionManager:getSingleton():removeReference(self)
	removeEventHandler("onPlayerQuit", self.m_Players[1], self.m_QuitEvent)
	removeEventHandler("onPlayerQuit", self.m_Players[2], self.m_QuitEvent)
	self:killClock()
end

function ChessSession:isThisPlayer(player)
	return self.m_Players[1] == player or self.m_Players[2] == player
end

function ChessSession:getColor(player)
	return self.m_Players[1] == player and "w" or "b"
end

function ChessSession:getOpponentColor(player)
	return self.m_Players[1] == player and "b" or "w"
end

function ChessSession:startClock()
	self.m_TurnStart = getTickCount()
	self.m_ClockTimer = setTimer(bind(ChessSession.onTimeEnd, self), math.max(self.m_TimeLeft[self.m_Game.state.turn], 50), 1)
end

function ChessSession:killClock()
	if self.m_ClockTimer and isTimer(self.m_ClockTimer) then
		killTimer(self.m_ClockTimer)
	end
	self.m_ClockTimer = nil
end

function ChessSession:stopClock(color)
	self:killClock()
	self.m_TimeLeft[color] = math.max(self.m_TimeLeft[color] - (getTickCount() - self.m_TurnStart), 0)
end

function ChessSession:getTimes()
	local turn = self.m_Game.state.turn
	local times = {w = self.m_TimeLeft.w, b = self.m_TimeLeft.b}
	if self.m_ClockTimer then
		times[turn] = math.max(times[turn] - (getTickCount() - self.m_TurnStart), 0)
	end
	return times
end

function ChessSession:createUpdate()
	local state = self.m_Game.state
	local check = ChessLogic.isInCheck(state, state.turn) and ChessLogic.toName(ChessLogic.kingIndex(state, state.turn)) or false
	return {
		board = ChessLogic.boardString(state),
		turn = state.turn,
		check = check,
		from = self.m_LastFrom or false,
		to = self.m_LastTo or false,
		time = self:getTimes(),
		captured = self.m_Captured,
		moves = {},
	}
end

function ChessSession:sendUpdate(data, finished)
	for i, player in ipairs(self.m_Players) do
		local color = i == 1 and "w" or "b"
		data.moves = (not finished and color == data.turn) and ChessLogic.moveMap(self.m_Game.state) or {}
		player:triggerEvent("onClientChessUpdate", data)
	end
end

function ChessSession:getNotation(result)
	local text
	if result.castle then
		text = result.to:sub(1, 1) == "g" and "0-0" or "0-0-0"
	else
		text = PIECE_LETTERS[result.piece:lower()] .. result.from .. (result.captured ~= "" and "x" or "-") .. result.to
		if result.promo ~= "" then
			text = text .. "=" .. PIECE_LETTERS[result.promo]
		end
	end
	if result.reason == "Schachmatt" then
		return text .. "#"
	end
	local state = self.m_Game.state
	return ChessLogic.isInCheck(state, state.turn) and text .. "+" or text
end

function ChessSession:movePiece(player, from, to, promo)
	local color = self:getColor(player)
	if self.m_Game.state.turn ~= color then return end

	local result = ChessLogic.play(self.m_Game, from, to, promo)
	if not result then
		player:triggerEvent("onClientChessUpdate", self:createResync())
		return
	end

	self:stopClock(color)
	self.m_LastFrom, self.m_LastTo = result.from, result.to
	if result.captured ~= "" then
		self.m_Captured[color] = self.m_Captured[color] .. result.captured
	end
	if not result.winner then
		self:startClock()
	end

	local data = self:createUpdate()
	data.mover = color
	data.notation = self:getNotation(result)
	self:sendUpdate(data, result.winner ~= nil)

	if result.winner then
		self:endGame(result.winner, result.reason)
	end
end

function ChessSession:createResync()
	local data = self:createUpdate()
	data.moves = ChessLogic.moveMap(self.m_Game.state)
	return data
end

function ChessSession:surrender(player)
	self:endGame(self:getOpponentColor(player), "Kapitulation")
end

function ChessSession:onTimeEnd()
	self.m_ClockTimer = nil
	local turn = self.m_Game.state.turn
	self.m_TimeLeft[turn] = 0
	self:endGame(turn == "w" and "b" or "w", "Zeit abgelaufen")
end

function ChessSession:endGame(winnerColor, reason)
	if self.m_Ended then return end
	self.m_Ended = true
	self:killClock()

	for _, player in ipairs(self.m_Players) do
		player:triggerEvent("onClientChessStop", winnerColor, reason, self.m_TimeLeft)
	end

	local winner = winnerColor == "w" and self.m_Players[1] or winnerColor == "b" and self.m_Players[2] or false
	if winner and ((self.m_Players[1]:getRank() >= RANK.Administrator and winner == self.m_Players[2]) or (self.m_Players[2]:getRank() >= RANK.Administrator and winner == self.m_Players[1])) then
		winner:giveAchievement(113)
	end
	delete(self)
end

function ChessSession:Event_onPlayerQuit()
	self:endGame(self:getOpponentColor(source), "Gegner hat das Spiel verlassen")
end
