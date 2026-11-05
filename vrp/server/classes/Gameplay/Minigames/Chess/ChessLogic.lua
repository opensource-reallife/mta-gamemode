ChessLogic = {}

ChessLogic.START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

local WHITE_PIECES = {P = true, N = true, B = true, R = true, Q = true, K = true}
local BLACK_PIECES = {p = true, n = true, b = true, r = true, q = true, k = true}
local KNIGHT_STEPS = {{-2, -1}, {-2, 1}, {-1, -2}, {-1, 2}, {1, -2}, {1, 2}, {2, -1}, {2, 1}}
local KING_STEPS = {{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}
local DIAGONAL_STEPS = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
local STRAIGHT_STEPS = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
local SLIDER_STEPS = {b = DIAGONAL_STEPS, r = STRAIGHT_STEPS, q = KING_STEPS}
local PROMOTIONS = {"q", "r", "b", "n"}
local CASTLE_SQUARES = {[60] = "KQ", [4] = "kq", [63] = "K", [56] = "Q", [7] = "k", [0] = "q"}

local function colorOf(piece)
	if WHITE_PIECES[piece] then return "w" end
	if BLACK_PIECES[piece] then return "b" end
	return ""
end

local function pieceOf(color, pieceType)
	return color == "w" and pieceType:upper() or pieceType
end

local function pieceAt(board, row, col)
	if row >= 0 and row < 8 and col >= 0 and col < 8 then
		return board[row*8 + col]
	end
	return nil
end

function ChessLogic.toIndex(name)
	if type(name) ~= "string" or not name:match("^[a-h][1-8]$") then return nil end
	return (8 - tonumber(name:sub(2, 2)))*8 + name:byte(1) - 97
end

function ChessLogic.toName(index)
	return string.char(97 + index%8) .. (8 - math.floor(index/8))
end

function ChessLogic.parse(fen)
	local rows, turn, castle, ep, half, full = fen:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
	local board, index = {}, 0
	for char in rows:gmatch("[^/]") do
		local empty = tonumber(char)
		if empty then
			for i = 1, empty do
				board[index] = ""
				index = index + 1
			end
		else
			board[index] = char
			index = index + 1
		end
	end
	return {board = board, turn = turn, castle = castle == "-" and "" or castle, ep = ep == "-" and -1 or ChessLogic.toIndex(ep), half = tonumber(half), full = tonumber(full)}
end

function ChessLogic.boardString(state)
	local parts = {}
	for index = 0, 63 do
		parts[index + 1] = state.board[index] == "" and "." or state.board[index]
	end
	return table.concat(parts)
end

function ChessLogic.positionKey(state)
	return ChessLogic.boardString(state) .. " " .. state.turn .. " " .. state.castle .. " " .. state.ep
end

function ChessLogic.isAttacked(board, index, by)
	local row, col = math.floor(index/8), index%8
	local pawnRow = by == "w" and row + 1 or row - 1
	local pawn, knight, king = pieceOf(by, "p"), pieceOf(by, "n"), pieceOf(by, "k")
	if pieceAt(board, pawnRow, col - 1) == pawn or pieceAt(board, pawnRow, col + 1) == pawn then
		return true
	end
	for _, step in ipairs(KNIGHT_STEPS) do
		if pieceAt(board, row + step[1], col + step[2]) == knight then return true end
	end
	for _, step in ipairs(KING_STEPS) do
		if pieceAt(board, row + step[1], col + step[2]) == king then return true end
	end
	local queen = pieceOf(by, "q")
	for pieceType, steps in pairs({b = DIAGONAL_STEPS, r = STRAIGHT_STEPS}) do
		local slider = pieceOf(by, pieceType)
		for _, step in ipairs(steps) do
			local r, c = row + step[1], col + step[2]
			local piece = pieceAt(board, r, c)
			while piece == "" do
				r, c = r + step[1], c + step[2]
				piece = pieceAt(board, r, c)
			end
			if piece == slider or piece == queen then return true end
		end
	end
	return false
end

function ChessLogic.kingIndex(state, color)
	local king = pieceOf(color, "k")
	for index = 0, 63 do
		if state.board[index] == king then return index end
	end
	return nil
end

function ChessLogic.isInCheck(state, color)
	local king = ChessLogic.kingIndex(state, color)
	return king ~= nil and ChessLogic.isAttacked(state.board, king, color == "w" and "b" or "w")
end

local function addPawnMoves(moves, state, from, row, col, me, them)
	local board = state.board
	local dir = me == "w" and -1 or 1
	local lastRow = me == "w" and 0 or 7
	local startRow = me == "w" and 6 or 1
	local function push(to)
		if math.floor(to/8) == lastRow then
			for _, promo in ipairs(PROMOTIONS) do
				moves[#moves + 1] = {from, to, promo}
			end
		else
			moves[#moves + 1] = {from, to, ""}
		end
	end
	local nextRow = row + dir
	if nextRow < 0 or nextRow > 7 then return end
	local one = nextRow*8 + col
	if board[one] == "" then
		push(one)
		local two = (row + 2*dir)*8 + col
		if row == startRow and board[two] == "" then
			moves[#moves + 1] = {from, two, ""}
		end
	end
	for _, dc in ipairs({-1, 1}) do
		local c = col + dc
		if c >= 0 and c <= 7 then
			local to = nextRow*8 + c
			if colorOf(board[to]) == them or to == state.ep then
				push(to)
			end
		end
	end
end

local function addCastleMoves(moves, state, from, me, them)
	local board = state.board
	local home = me == "w" and 60 or 4
	if from ~= home or ChessLogic.isAttacked(board, home, them) then return end
	local rook = pieceOf(me, "r")
	if state.castle:find(pieceOf(me, "k"), 1, true) and board[home + 1] == "" and board[home + 2] == "" and board[home + 3] == rook
		and not ChessLogic.isAttacked(board, home + 1, them) and not ChessLogic.isAttacked(board, home + 2, them) then
		moves[#moves + 1] = {from, home + 2, ""}
	end
	if state.castle:find(pieceOf(me, "q"), 1, true) and board[home - 1] == "" and board[home - 2] == "" and board[home - 3] == "" and board[home - 4] == rook
		and not ChessLogic.isAttacked(board, home - 1, them) and not ChessLogic.isAttacked(board, home - 2, them) then
		moves[#moves + 1] = {from, home - 2, ""}
	end
end

local function addStepMoves(moves, board, from, row, col, me, steps, slide)
	for _, step in ipairs(steps) do
		local r, c = row + step[1], col + step[2]
		local target = pieceAt(board, r, c)
		while target ~= nil and colorOf(target) ~= me do
			moves[#moves + 1] = {from, r*8 + c, ""}
			if not slide or target ~= "" then break end
			r, c = r + step[1], c + step[2]
			target = pieceAt(board, r, c)
		end
	end
end

function ChessLogic.pseudoMoves(state)
	local board, me = state.board, state.turn
	local them = me == "w" and "b" or "w"
	local moves = {}
	for from = 0, 63 do
		local piece = board[from]
		if colorOf(piece) == me then
			local row, col = math.floor(from/8), from%8
			local pieceType = piece:lower()
			if pieceType == "p" then
				addPawnMoves(moves, state, from, row, col, me, them)
			elseif pieceType == "n" then
				addStepMoves(moves, board, from, row, col, me, KNIGHT_STEPS, false)
			elseif pieceType == "k" then
				addStepMoves(moves, board, from, row, col, me, KING_STEPS, false)
				addCastleMoves(moves, state, from, me, them)
			else
				addStepMoves(moves, board, from, row, col, me, SLIDER_STEPS[pieceType], true)
			end
		end
	end
	return moves
end

function ChessLogic.make(state, move)
	local from, to, promo = move[1], move[2], move[3]
	local board = {}
	for index = 0, 63 do
		board[index] = state.board[index]
	end
	local piece, me = board[from], state.turn
	local pieceType = piece:lower()
	local capture = board[to] ~= ""
	if pieceType == "p" and to == state.ep then
		board[to + (me == "w" and 8 or -8)] = ""
		capture = true
	end
	board[to] = promo ~= "" and pieceOf(me, promo) or piece
	board[from] = ""
	if pieceType == "k" and math.abs(to - from) == 2 then
		local rookFrom, rookTo = from - 4, from - 1
		if to > from then
			rookFrom, rookTo = from + 3, from + 1
		end
		board[rookTo] = board[rookFrom]
		board[rookFrom] = ""
	end
	local castle = state.castle
	for index, rights in pairs(CASTLE_SQUARES) do
		if from == index or to == index then
			castle = castle:gsub("[" .. rights .. "]", "")
		end
	end
	return {
		board = board,
		turn = me == "w" and "b" or "w",
		castle = castle,
		ep = (pieceType == "p" and math.abs(to - from) == 16) and math.floor((from + to)/2) or -1,
		half = (pieceType == "p" or capture) and 0 or state.half + 1,
		full = state.full + (me == "b" and 1 or 0),
	}
end

function ChessLogic.legalMoves(state)
	local legal = {}
	for _, move in ipairs(ChessLogic.pseudoMoves(state)) do
		if not ChessLogic.isInCheck(ChessLogic.make(state, move), state.turn) then
			legal[#legal + 1] = move
		end
	end
	return legal
end

function ChessLogic.isInsufficient(state)
	local rest = {}
	for index = 0, 63 do
		local piece = state.board[index]
		if piece ~= "" and piece:lower() ~= "k" then
			rest[#rest + 1] = piece:lower()
		end
	end
	return #rest == 0 or (#rest == 1 and (rest[1] == "b" or rest[1] == "n"))
end

function ChessLogic.newGame()
	local state = ChessLogic.parse(ChessLogic.START)
	return {state = state, positions = {[ChessLogic.positionKey(state)] = 1}}
end

function ChessLogic.moveMap(state)
	local map = {}
	for _, move in ipairs(ChessLogic.legalMoves(state)) do
		local from = ChessLogic.toName(move[1])
		map[from] = map[from] or {}
		map[from][ChessLogic.toName(move[2])] = move[3] ~= ""
	end
	return map
end

function ChessLogic.play(game, fromName, toName, promo)
	local from, to = ChessLogic.toIndex(fromName), ChessLogic.toIndex(toName)
	if not from or not to then return false end
	local wanted
	for _, move in ipairs(ChessLogic.legalMoves(game.state)) do
		if move[1] == from and move[2] == to and (move[3] == "" or move[3] == promo) then
			wanted = move
			break
		end
	end
	if not wanted then return false end

	local state = game.state
	local piece = state.board[from]
	local captured = state.board[to]
	if captured == "" and piece:lower() == "p" and to == state.ep then
		captured = state.board[to + (state.turn == "w" and 8 or -8)]
	end
	local nextState = ChessLogic.make(state, wanted)
	game.state = nextState

	local key = ChessLogic.positionKey(nextState)
	game.positions[key] = (game.positions[key] or 0) + 1

	local result = {from = fromName, to = toName, promo = wanted[3], piece = piece, captured = captured, castle = piece:lower() == "k" and math.abs(to - from) == 2}
	if #ChessLogic.legalMoves(nextState) == 0 then
		if ChessLogic.isInCheck(nextState, nextState.turn) then
			result.winner, result.reason = state.turn, "Schachmatt"
		else
			result.winner, result.reason = "draw", "Patt"
		end
	elseif nextState.half >= 100 then
		result.winner, result.reason = "draw", "50-Züge-Regel"
	elseif game.positions[key] >= 3 then
		result.winner, result.reason = "draw", "Dreifache Wiederholung"
	elseif ChessLogic.isInsufficient(nextState) then
		result.winner, result.reason = "draw", "Zu wenig Material für ein Matt"
	end
	return result
end
