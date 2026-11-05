ChessGraphics = inherit(GUIForm)

local PADDING = 10
local TITLE_HEIGHT = 32
local PANEL_HEIGHT = 66
local BUTTON_HEIGHT = 36
local PROMOTIONS = {"q", "r", "b", "n"}
local COLOR_OVERLAY = tocolor(30, 30, 30)
local COLOR_LOW_TIME = tocolor(255, 110, 100)
local COLOR_WIN = tocolor(110, 220, 110)
local COLOR_LOSE = tocolor(240, 90, 80)
local COLOR_SURRENDER = tocolor(180, 60, 50)

function ChessGraphics:constructor(color, whiteName, blackName)
	local tileSize = math.floor(math.clamp(320, screenHeight*0.72, 640)/8)
	local boardSize = tileSize*8
	local sideWidth = screenWidth < 1024 and 200 or 250
	local width = boardSize + sideWidth + PADDING*3
	local height = TITLE_HEIGHT + boardSize + PADDING*2
	GUIForm.constructor(self, math.floor((screenWidth - width)/2), math.floor((screenHeight - height)/2), width, height)
	GUIForm.DoNotClose[self] = true

	self.m_Color = color
	self.m_TileSize = tileSize
	self.m_BoardSize = boardSize
	self.m_Moves = {}
	self.m_Board = ""
	self.m_Window = GUIWindow:new(0, 0, width, height, _"Schach", true, false, self)

	self:createBoard()

	local sideX, top = boardSize + PADDING*2, TITLE_HEIGHT + PADDING
	local buttonY = top + boardSize - BUTTON_HEIGHT
	local ownY = buttonY - PADDING - PANEL_HEIGHT
	local listY = top + PANEL_HEIGHT + PADDING
	local names = {w = whiteName, b = blackName}
	local opponent = color == "w" and "b" or "w"

	self.m_Panels = {
		[opponent] = self:createPanel(sideX, top, sideWidth, names[opponent]),
		[color] = self:createPanel(sideX, ownY, sideWidth, names[color]),
	}

	self.m_MoveList = GUIGridList:new(sideX, listY, sideWidth, ownY - PADDING - listY, self.m_Window)
	self.m_MoveList:addColumn("#", 0.16)
	self.m_MoveList:addColumn(_"Weiß", 0.38)
	self.m_MoveList:addColumn(_"Schwarz", 0.38)
	self.m_MoveCount = 0

	self.m_ActionButton = GUIButton:new(sideX, buttonY, sideWidth, BUTTON_HEIGHT, _"Aufgeben", self.m_Window)
	self.m_ActionButton:setBackgroundColor(COLOR_SURRENDER)
	self.m_ActionButton.onLeftClick = bind(ChessGraphics.onActionClick, self)

	self:createPromotionOverlay()
	self:createResultOverlay()

	self.m_ClockTimer = setTimer(bind(ChessGraphics.updateClocks, self), 200, 0)
end

function ChessGraphics:destructor()
	GUIForm.DoNotClose[self] = nil
	if isTimer(self.m_ClockTimer) then
		killTimer(self.m_ClockTimer)
	end
	if self.m_SurrenderTimer and isTimer(self.m_SurrenderTimer) then
		killTimer(self.m_SurrenderTimer)
	end
	GUIForm.destructor(self)
end

function ChessGraphics:createBoard()
	local flipped = self.m_Color == "b"
	self.m_Tiles = {}
	for row = 0, 7 do
		for col = 0, 7 do
			local rank = flipped and 7 - row or row
			local file = flipped and 7 - col or col
			local name = string.char(97 + file) .. (8 - rank)
			local tile = ChessTile:new(
				PADDING + col*self.m_TileSize, TITLE_HEIGHT + PADDING + row*self.m_TileSize, self.m_TileSize, name, (rank + file)%2 == 1,
				col == 0 and tostring(8 - rank) or false, row == 7 and string.char(97 + file) or false, self.m_Window, self
			)
			self.m_Tiles[rank*8 + file + 1] = tile
		end
	end
end

function ChessGraphics:createPanel(posX, posY, width, name)
	local background = GUIRectangle:new(posX, posY, width, PANEL_HEIGHT, Color.Primary, self.m_Window)
	return {
		background = background,
		name = GUILabel:new(8, 6, width - 16, 22, name, background),
		clock = GUILabel:new(8, 30, 84, 30, "", background),
		captured = ChessCapturedRow:new(96, 34, width - 104, 24, background),
	}
end

function ChessGraphics:createPromotionOverlay()
	local size = self.m_TileSize
	local width, height = size*4 + 16, size + 16 + BUTTON_HEIGHT + 8
	local posX = PADDING + (self.m_BoardSize - width)/2
	local posY = TITLE_HEIGHT + PADDING + (self.m_BoardSize - height)/2

	self.m_PromotionOverlay = GUIRectangle:new(posX, posY, width, height, COLOR_OVERLAY, self.m_Window)
	for i, promo in ipairs(PROMOTIONS) do
		local piece = self.m_Color == "w" and promo:upper() or promo
		local button = ChessTile:new(8 + (i - 1)*size, 8, size, promo, i%2 == 0, false, false, self.m_PromotionOverlay, self)
		button:setState(piece, false, true)
		button.onLeftClick = function()
			self:sendPromotion(promo)
		end
	end
	local cancel = GUIButton:new(8, size + 16, width - 16, BUTTON_HEIGHT, _"Abbrechen", self.m_PromotionOverlay)
	cancel.onLeftClick = function()
		self.m_Promotion = nil
		self.m_PromotionOverlay:setVisible(false)
	end
	self.m_PromotionOverlay:setVisible(false)
end

function ChessGraphics:createResultOverlay()
	local width, height = math.min(self.m_BoardSize*0.8, 400), 100
	local posX = PADDING + (self.m_BoardSize - width)/2
	local posY = TITLE_HEIGHT + PADDING + (self.m_BoardSize - height)/2

	self.m_ResultOverlay = GUIRectangle:new(posX, posY, width, height, COLOR_OVERLAY, self.m_Window)
	self.m_ResultTitle = GUILabel:new(8, 14, width - 16, 40, "", self.m_ResultOverlay):setAlignX("center")
	self.m_ResultReason = GUILabel:new(8, 58, width - 16, 26, "", self.m_ResultOverlay):setAlignX("center")
	self.m_ResultOverlay:setVisible(false)
end

function ChessGraphics:updateGame(data)
	self.m_Moves = data.moves or {}
	self.m_Selected = nil
	self.m_Promotion = nil
	self.m_PromotionOverlay:setVisible(false)
	self.m_Board = data.board
	self.m_From, self.m_To, self.m_Check = data.from, data.to, data.check

	self:refreshTiles()
	self:setClock(data.turn, data.time)

	self.m_Panels.w.captured:setPieces(data.captured.w)
	self.m_Panels.b.captured:setPieces(data.captured.b)
	self.m_Panels.w.background:setColor(data.turn == "w" and Color.Accent or Color.Primary)
	self.m_Panels.b.background:setColor(data.turn == "b" and Color.Accent or Color.Primary)
	self.m_Window:setTitleBarText(data.turn == self.m_Color and _"Schach - Du bist am Zug" or _"Schach - Dein Gegner ist am Zug")

	if data.notation then
		self:addNotation(data.mover, data.notation)
	end
end

function ChessGraphics:addNotation(mover, notation)
	if mover == "w" then
		self.m_MoveCount = self.m_MoveCount + 1
		self.m_LastMoveItem = self.m_MoveList:addItemNoClick(self.m_MoveCount .. ".", notation, "")
	elseif self.m_LastMoveItem then
		self.m_LastMoveItem:setColumnText(3, notation)
	end
	self.m_MoveList:scrollToItem(self.m_MoveCount)
end

function ChessGraphics:refreshTiles()
	local targets = self.m_Selected and self.m_Moves[self.m_Selected] or {}
	for index, tile in ipairs(self.m_Tiles) do
		local name = tile:getName()
		local piece = self.m_Board:sub(index, index)
		if piece == "." then
			piece = ""
		end

		local mark = false
		if name == self.m_Selected then
			mark = "selected"
		elseif targets[name] ~= nil then
			mark = piece ~= "" and "capture" or "target"
		elseif name == self.m_Check then
			mark = "check"
		elseif name == self.m_From or name == self.m_To then
			mark = "last"
		end
		tile:setState(piece, mark, self.m_Moves[name] ~= nil)
	end
end

function ChessGraphics:onTileClick(tile)
	if self.m_Over or self.m_Promotion then return end

	local name = tile:getName()
	local targets = self.m_Selected and self.m_Moves[self.m_Selected]
	if targets and targets[name] ~= nil then
		if targets[name] then
			self.m_Promotion = {from = self.m_Selected, to = name}
			self.m_PromotionOverlay:setVisible(true)
		else
			self:sendMove(self.m_Selected, name, "")
		end
		return
	end

	if self.m_Moves[name] and self.m_Selected ~= name then
		self.m_Selected = name
	else
		self.m_Selected = nil
	end
	self:refreshTiles()
end

function ChessGraphics:sendPromotion(promo)
	local promotion = self.m_Promotion
	if not promotion then return end

	self.m_Promotion = nil
	self.m_PromotionOverlay:setVisible(false)
	self:sendMove(promotion.from, promotion.to, promo)
end

function ChessGraphics:sendMove(from, to, promo)
	self.m_Moves = {}
	self.m_Selected = nil
	self:refreshTiles()
	ChessSession:getSingleton():sendMove(from, to, promo)
end

function ChessGraphics:setClock(turn, times)
	self.m_Turn = turn
	self.m_Times = times
	self.m_ClockTick = getTickCount()
	self:updateClocks()
end

function ChessGraphics:updateClocks()
	if not self.m_Times then return end

	for color, panel in pairs(self.m_Panels) do
		local left = self.m_Times[color]
		if color == self.m_Turn then
			left = math.max(left - (getTickCount() - self.m_ClockTick), 0)
		end
		local seconds = math.ceil(left/1000)
		local text = ("%d:%02d"):format(math.floor(seconds/60), seconds%60)
		if panel.clock:getText() ~= text then
			panel.clock:setText(text)
			panel.clock:setColor(seconds <= 30 and COLOR_LOW_TIME or Color.White)
		end
	end
end

function ChessGraphics:onActionClick()
	if self.m_Over then
		ChessSession:getSingleton():clear()
		return
	end

	if self.m_SurrenderArmed then
		self.m_SurrenderArmed = false
		ChessSession:getSingleton():surrender()
		return
	end

	self.m_SurrenderArmed = true
	self.m_ActionButton:setText(_"Wirklich aufgeben?")
	self.m_SurrenderTimer = setTimer(
		function()
			self.m_SurrenderArmed = false
			if not self.m_Over then
				self.m_ActionButton:setText(_"Aufgeben")
			end
		end, 3000, 1
	)
end

function ChessGraphics:showResult(winner, reason, times)
	self.m_Over = true
	self.m_Moves = {}
	self.m_Selected = nil
	self.m_Promotion = nil
	self.m_PromotionOverlay:setVisible(false)
	self:refreshTiles()
	self:setClock(false, times)

	self.m_Panels.w.background:setColor(Color.Primary)
	self.m_Panels.b.background:setColor(Color.Primary)
	self.m_Window:setTitleBarText(_"Schach")
	self.m_ActionButton:setText(_"Schließen")
	self.m_ActionButton:setBackgroundColor(Color.Accent)

	if winner == "draw" then
		self.m_ResultTitle:setText(_"Remis")
	elseif winner == self.m_Color then
		self.m_ResultTitle:setText(_"Du hast gewonnen!"):setColor(COLOR_WIN)
	else
		self.m_ResultTitle:setText(_"Du hast verloren!"):setColor(COLOR_LOSE)
	end
	self.m_ResultReason:setText(_(reason))
	self.m_ResultOverlay:setVisible(true)
end
