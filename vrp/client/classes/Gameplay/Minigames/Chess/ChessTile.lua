ChessTile = inherit(GUIElement)

CHESS_PIECE_IMAGES = {
	K = "files/images/Chess/King.png", Q = "files/images/Chess/Queen.png", R = "files/images/Chess/Rook.png",
	B = "files/images/Chess/Bishop.png", N = "files/images/Chess/Knight.png", P = "files/images/Chess/Pawn.png",
	k = "files/images/Chess/KingB.png", q = "files/images/Chess/QueenB.png", r = "files/images/Chess/RookB.png",
	b = "files/images/Chess/BishopB.png", n = "files/images/Chess/KnightB.png", p = "files/images/Chess/PawnB.png",
}

local COLOR_LIGHT = tocolor(232, 218, 190)
local COLOR_DARK = tocolor(128, 98, 74)
local COLOR_LAST_LIGHT = tocolor(214, 210, 130)
local COLOR_LAST_DARK = tocolor(170, 160, 84)
local COLOR_SELECTED = tocolor(96, 170, 214)
local COLOR_HOVER = tocolor(150, 196, 224)
local COLOR_TARGET = tocolor(112, 176, 96)
local COLOR_CAPTURE = tocolor(214, 104, 88)
local COLOR_CHECK = tocolor(204, 52, 44)

function ChessTile:constructor(posX, posY, size, name, dark, rankLabel, fileLabel, parent, board)
	GUIElement.constructor(self, posX, posY, size, size, parent)
	self.m_Name = name
	self.m_Dark = dark
	self.m_RankLabel = rankLabel
	self.m_FileLabel = fileLabel
	self.m_Board = board
	self.m_Piece = ""
	self.m_Mark = false
	self.m_Selectable = false
	self.m_LabelFont = getVRPFont(VRPFont(math.max(size*0.32, 14)))
end

function ChessTile:setState(piece, mark, selectable)
	if self.m_Piece ~= piece or self.m_Mark ~= mark or self.m_Selectable ~= selectable then
		self.m_Piece = piece
		self.m_Mark = mark
		self.m_Selectable = selectable
		self:anyChange()
	end
end

function ChessTile:getName()
	return self.m_Name
end

function ChessTile:getPiece()
	return self.m_Piece
end

function ChessTile:isHighlightable()
	return self.m_Selectable or self.m_Mark == "target" or self.m_Mark == "capture"
end

function ChessTile:onHover()
	if self:isHighlightable() then
		self:anyChange()
	end
end

function ChessTile:onUnhover()
	if self:isHighlightable() then
		self:anyChange()
	end
end

function ChessTile:onLeftClick()
	self.m_Board:onTileClick(self)
end

function ChessTile:getBackgroundTileColor()
	local mark = self.m_Mark
	if mark == "selected" then return COLOR_SELECTED end
	if mark == "check" then return COLOR_CHECK end
	if mark == "capture" then return COLOR_CAPTURE end
	if mark == "target" and self.m_Hover then return COLOR_TARGET end
	if self.m_Selectable and self.m_Hover then return COLOR_HOVER end
	if mark == "last" then return self.m_Dark and COLOR_LAST_DARK or COLOR_LAST_LIGHT end
	return self.m_Dark and COLOR_DARK or COLOR_LIGHT
end

function ChessTile:drawThis()
	local x, y, size = math.floor(self.m_AbsoluteX), math.floor(self.m_AbsoluteY), self.m_Width

	dxSetBlendMode("modulate_add")
	dxDrawRectangle(x, y, size, size, self:getBackgroundTileColor())

	if self.m_Mark == "target" and not self.m_Hover then
		local dot = math.floor(size*0.26)
		dxDrawRectangle(x + (size - dot)/2, y + (size - dot)/2, dot, dot, COLOR_TARGET)
	end

	local textColor = self.m_Dark and COLOR_LIGHT or COLOR_DARK
	if self.m_RankLabel then
		dxDrawText(self.m_RankLabel, x + 3, y + 1, x + size, y + size, textColor, 1, self.m_LabelFont, "left", "top")
	end
	if self.m_FileLabel then
		dxDrawText(self.m_FileLabel, x, y, x + size - 3, y + size - 1, textColor, 1, self.m_LabelFont, "right", "bottom")
	end

	if CHESS_PIECE_IMAGES[self.m_Piece] then
		dxDrawImage(x, y, size, size, CHESS_PIECE_IMAGES[self.m_Piece])
	end
	dxSetBlendMode("blend")
end


ChessCapturedRow = inherit(GUIElement)

function ChessCapturedRow:constructor(posX, posY, width, height, parent)
	GUIElement.constructor(self, posX, posY, width, height, parent)
	self.m_Pieces = ""
end

function ChessCapturedRow:setPieces(pieces)
	if self.m_Pieces ~= pieces then
		self.m_Pieces = pieces
		self:anyChange()
	end
end

function ChessCapturedRow:drawThis()
	local count = #self.m_Pieces
	if count == 0 then return end

	local size = self.m_Height
	local step = count > 1 and math.min(size*0.6, (self.m_Width - size)/(count - 1)) or 0

	dxSetBlendMode("modulate_add")
	for i = 1, count do
		dxDrawImage(self.m_AbsoluteX + (i - 1)*step, self.m_AbsoluteY, size, size, CHESS_PIECE_IMAGES[self.m_Pieces:sub(i, i)])
	end
	dxSetBlendMode("blend")
end
