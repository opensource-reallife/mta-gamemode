-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Inventory/Inventory.lua
-- *  PURPOSE:     Inventory class
-- *
-- ****************************************************************************

Inventory = inherit(GUIForm)
inherit(Singleton, Inventory)
addRemoteEvents{"loadPlayerInventarClient", "syncInventoryFromServer", "forceInventoryRefresh", "closeInventory", "flushInventory"}
Inventory.Color = {
	TabHover  = rgb(50, 200, 255);
	TabNormal = rgb(50, 50, 50);
	ItemsBackground = rgb(50, 50, 50);
	ItemBackground  = rgb(97, 129, 140);
	ItemBackgroundHover = rgb(50, 200, 255);
	ItemBackgroundHoverDelete = rgb(200, 0, 0);
}

Inventory.TabList = {}

Inventory.RarityColor = {}
Inventory.RarityName = {}

addRemoteEvents{"inventoryReceivedMessage"}
addEventHandler("inventoryReceivedMessage", root, function(title, received, left, receivedHeader, leftHeader)
	local lines = {}
	if received and #received > 0 then
		lines[#lines + 1] = receivedHeader or _"Erhalten:"
		for _index, entry in ipairs(received) do
			lines[#lines + 1] = "  + "..entry
		end
	end
	if left and #left > 0 then
		lines[#lines + 1] = leftHeader or _"Nicht aufgenommen:"
		for _index, entry in ipairs(left) do
			lines[#lines + 1] = "  - "..entry
		end
	end
	if #lines == 0 then return end
	local success = received and #received > 0
	ShortMessage:new(table.concat(lines, "\n"), title, success and {60, 118, 61} or {178, 35, 33}, 8000)
	playSound(success and "files/audio/Success.mp3" or "files/audio/Message.mp3")
end)

function Inventory.setRarities(rarities)
	if type(rarities) ~= "table" then return end
	local colors, names = {}, {}
	for id, rarity in pairs(rarities) do
		id = tonumber(id)
		if id and type(rarity) == "table" and type(rarity.color) == "table" then
			colors[id] = tocolor(rarity.color[1] or 255, rarity.color[2] or 255, rarity.color[3] or 255)
			names[id] = rarity.name
		end
	end
	Inventory.RarityColor = colors
	Inventory.RarityName = names
end

local SCALE, TOP, WIDTH, HEIGHT, LIST_X, LIST_Y, LIST_WIDTH, DETAIL_X, DETAIL_WIDTH

local function s(value)
	return math.floor(value * SCALE)
end

function Inventory.getScale()
	return math.max(1, math.min(screenWidth / 1920, screenHeight / 1080))
end

function Inventory.scaleTitleBar(window, scale)
	local height = math.floor(30 * scale)
	local width = window.m_Width
	window.m_TitlebarDummy:setSize(width, height)
	window.m_TitleBarAccentStripe:setPosition(0, height)
	window.m_TitleLabel:setSize(width, height)
	window.m_TitleLabel:setFont(VRPFont(math.floor(28 * scale)))
	window.m_TitleLabel:setFontSize(1)
	if window.m_CloseButton then
		window.m_CloseButton:setSize(height, height)
		window.m_CloseButton:setPosition(width - height, 0)
		window.m_CloseButton:setFont(FontAwesome(math.floor(20 * scale)))
	end
end

function Inventory.fitText(text, width, fontHeight)
	local font = getVRPFont(VRPFont(fontHeight))
	if dxGetTextWidth(text, 1, font) <= width then return text end
	while #text > 1 and dxGetTextWidth(text.."..", 1, font) > width do
		text = utf8.sub(text, 1, utf8.len(text) - 1)
	end
	return text..".."
end

function Inventory:constructor()
	SCALE = Inventory.getScale()
	WIDTH, HEIGHT = s(980), s(560)
	TOP = s(32)
	LIST_X, LIST_Y, LIST_WIDTH = s(10), TOP + s(120), s(710)
	DETAIL_X, DETAIL_WIDTH = s(730), s(240)

	GUIForm.constructor(self, screenWidth/2 - WIDTH/2, screenHeight/2 - HEIGHT/2, WIDTH, HEIGHT)
	self.m_Window = GUIWindow:new(0, 0, WIDTH, HEIGHT, _"Inventar", true, true, self)
	Inventory.scaleTitleBar(self.m_Window, SCALE)
	self.m_Window:deleteOnClose(false)
	self.m_Window.closeCallback = function() self:hide() end
	self.m_CurrentTab = 1
	self.m_Items = {}
	self.m_Weight, self.m_MaxWeight = 0, 0

	self.m_TabButtons = {}

	self.m_WeightBar = GUIProgressBar:new(s(10), TOP + s(38), WIDTH-s(20), s(28), self.m_Window)
	self.m_WeightBar:setFontSize(1):setFont(VRPFont(s(26))):setColor(Color.White)
	self.m_WeightInfo = GUILabel:new(s(10), TOP + s(67), s(500), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)
	self.m_WeightState = GUILabel:new(WIDTH-s(510), TOP + s(67), s(500), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1):setAlignX("right")

	self.m_SearchText = ""
	self.m_Search = GUIEdit:new(s(10), TOP + s(91), s(300), s(26), self.m_Window)
	self.m_Search:setCaption(_"Suche in allen Tabs")
	self.m_Search.onChange = function()
		self.m_SearchText = utf8.lower(self.m_Search:getText() or "")
		self:loadItems()
	end

	self.m_SortMode = core:get("Inventory", "SortMode", "name")
	self.m_SortButton = GUIButton:new(s(320), TOP + s(91), s(190), s(26), self:getSortLabel(), self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBarEnabled(false):setBackgroundColor(Color.PrimaryNoClick)
	self.m_SortButton.onLeftClick = function() self:nextSortMode() end

	self:loadFavorites()

	self.m_DetailImageBackground = GUIRectangle:new(DETAIL_X, LIST_Y, s(54), s(54), tocolor(0, 0, 0, 200), self.m_Window)
	self.m_DetailImage = GUIImage:new(DETAIL_X+s(5), LIST_Y+s(5), s(44), s(44), "files/images/Other/noImg.png", self.m_Window)
	self.m_DetailName = GUILabel:new(DETAIL_X+s(60), LIST_Y, DETAIL_WIDTH-s(60), s(34), "", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	self.m_DetailGroup = GUILabel:new(DETAIL_X+s(60), LIST_Y+s(34), DETAIL_WIDTH-s(90), s(20), "", self.m_Window):setFont(VRPFont(s(20))):setFontSize(1)
	self.m_FavoriteButton = GUIButton:new(DETAIL_X+DETAIL_WIDTH-s(26), LIST_Y+s(30), s(26), s(24), FontAwesomeSymbols.Star, self.m_Window):setFont(FontAwesome(s(16))):setFontSize(1):setBarEnabled(false):setBackgroundColor(Color.PrimaryNoClick)
	self.m_FavoriteButton.onLeftClick = function() self:toggleFavorite() end
	self.m_DetailInfo = GUILabel:new(DETAIL_X, LIST_Y+s(60), DETAIL_WIDTH, s(80), "", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setMultiline(true)
	self.m_DetailStats = GUILabel:new(DETAIL_X, LIST_Y+s(142), DETAIL_WIDTH, s(150), "", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setMultiline(true)

	self.m_UseButton = GUIButton:new(DETAIL_X, HEIGHT-s(114), DETAIL_WIDTH, s(32), _"Benutzen", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	self.m_UseButton.onLeftClick = bind(self.useSelected, self)
	self.m_SecondaryButton = GUIButton:new(DETAIL_X, HEIGHT-s(78), DETAIL_WIDTH, s(28), _"Alternativ", self.m_Window):setFont(VRPFont(s(22))):setFontSize(1):setBackgroundColor(Color.PrimaryNoClick)
	self.m_SecondaryButton.onLeftClick = bind(self.useSelectedSecondary, self)
	self.m_GiveButton = GUIButton:new(DETAIL_X, HEIGHT-s(46), DETAIL_WIDTH/2-s(3), s(32), _"Geben", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1)
	self.m_GiveButton.onLeftClick = bind(self.giveSelected, self)
	self.m_DropButton = GUIButton:new(DETAIL_X+DETAIL_WIDTH/2+s(3), HEIGHT-s(46), DETAIL_WIDTH/2-s(3), s(32), _"Wegwerfen", self.m_Window):setFont(VRPFont(s(26))):setFontSize(1):setBackgroundColor(Color.Red)
	self.m_DropButton.onLeftClick = bind(self.dropSelected, self)

	self.m_ViewMode = core:get("Inventory", "ViewMode", "list")
	self.m_ViewButton = GUIButton:new(s(516), TOP + s(91), s(30), s(26), "", self.m_Window):setFont(FontAwesome(s(16))):setFontSize(1):setBarEnabled(false):setBackgroundColor(Color.PrimaryNoClick)
	self:updateViewButton()
	self.m_ViewButton.onLeftClick = function()
		self:setViewMode(self.m_ViewMode == "tiles" and "list" or "tiles")
	end

	self.m_Overloaded = true
	self.m_OverloadTimer = setTimer(bind(self.applyOverload, self), 500, 0)

	addEventHandler("loadPlayerInventarClient", root, bind(self.Event_loadPlayerInventarClient, self))
	addEventHandler("syncInventoryFromServer", root, bind(self.Event_syncInventoryFromServer, self))
	addEventHandler("forceInventoryRefresh", root, bind(self.Event_forceInventoryRefresh, self))
	addEventHandler("closeInventory", root, bind(self.hide, self))

	self:hide()
end

function Inventory:buildTabs(tabs)
	for _index, button in ipairs(self.m_TabButtons) do
		delete(button)
	end
	self.m_TabButtons = {}
	Inventory.TabList = {}

	local tabWidth = WIDTH / math.max(1, #tabs)
	for id, tab in ipairs(tabs) do
		Inventory.TabList[id] = {name = tab.name, lists = {{title = "Item", categories = {[tab.key] = true}}}}
		local button = GUIButton:new(tabWidth*(id-1), TOP, tabWidth, s(30), _(tab.name), self.m_Window):setBarEnabled(false)
		button:setColor(Color.White):setBackgroundColor(Color.Primary):setFontSize(1):setFont(VRPFont(s(25)))
		button.Stripe = GUIRectangle:new(0, s(28), tabWidth, s(2), Color.Clear, button)
		button.onLeftClick = function() self:setTab(id) end
		self.m_TabButtons[id] = button
	end
	if #tabs > 0 then
		self:setTab(1)
	end
end

function Inventory:Event_syncInventoryFromServer(bag, items, itemData, weight, maxWeight, rarities)
	Inventory.setRarities(rarities)
	self.m_Bag = bag
	self.m_Items = items or {}
	if itemData then self.m_ItemData = itemData end
	self.m_Weight = weight or 0
	self.m_MaxWeight = maxWeight or 0
	self:applyOverload()
	if self.Show then
		self:loadItems()
	end
end

function Inventory:isOverloadExempt()
	return localPlayer:getPublicSync("supportMode") and localPlayer:getRank() >= RANK.Supporter
end

function Inventory:applyOverload()
	local overloaded = self.m_MaxWeight > 0 and self.m_Weight > self.m_MaxWeight + 0.0001 and not self:isOverloadExempt()
	if overloaded then
		toggleControl("sprint", false)
		toggleControl("jump", false)
	elseif self.m_Overloaded then
		toggleControl("sprint", true)
		toggleControl("jump", true)
	end
	self.m_Overloaded = overloaded
end

function Inventory:Event_loadPlayerInventarClient(slots, itemData, tabs, rarities)
	Inventory.setRarities(rarities)
	self.m_Slots = slots
	self.m_ItemData = itemData
	self:buildTabs(tabs or {})
end

function Inventory:Event_forceInventoryRefresh()
	self:hide()
	self:show()
end

function Inventory:toggle()
	if self.Show then
		self:hide()
	else
		self:show()
	end
end

function Inventory:getItemData()
	return self.m_ItemData
end

function Inventory:getItems()
	return self.m_Items
end

function Inventory:getBagData()
	return self.m_Bag
end

function Inventory:setTab(id)
	self.m_CurrentTab = id
	for tabId, button in ipairs(self.m_TabButtons) do
		button.Stripe:setColor(tabId == id and Color.Accent or Color.Clear)
	end
	self.m_SelectedId = nil
	self:buildLists()
	self:loadItems()
end

function Inventory:getSortLabel()
	if self.m_SortMode == "amount" then
		return _"Sortierung: Menge"
	elseif self.m_SortMode == "weight" then
		return _"Sortierung: Gewicht"
	end
	return _"Sortierung: Name"
end

function Inventory:nextSortMode()
	self.m_SortMode = self.m_SortMode == "name" and "amount" or self.m_SortMode == "amount" and "weight" or "name"
	core:set("Inventory", "SortMode", self.m_SortMode)
	self.m_SortButton:setText(self:getSortLabel())
	self:loadItems()
end

function Inventory:loadFavorites()
	self.m_Favorites = {}
	for itemId in tostring(core:get("Inventory", "Favorites", "")):gmatch("%d+") do
		self.m_Favorites[tonumber(itemId)] = true
	end
end

function Inventory:saveFavorites()
	local ids = {}
	for itemId in pairs(self.m_Favorites) do
		ids[#ids + 1] = tostring(itemId)
	end
	core:set("Inventory", "Favorites", table.concat(ids, ","))
end

function Inventory:isFavorite(itemName)
	local data = self.m_ItemData[itemName]
	return data and self.m_Favorites[data["Id"]] == true
end

function Inventory:toggleFavorite()
	local row = self.m_SelectedId and self.m_Items[self.m_SelectedId]
	if not row then return end
	local itemId = self.m_ItemData[row["Objekt"]]["Id"]
	self.m_Favorites[itemId] = not self.m_Favorites[itemId] or nil
	self:saveFavorites()
	self:loadItems()
end

function Inventory:getWeightPreview(itemName, amount)
	local data = self.m_ItemData and self.m_ItemData[itemName]
	if not data then return "", Color.White end
	local weight = self.m_Weight + (data["DienstItem"] == 1 and 0 or data["Gewicht"]) * math.max(0, tonumber(amount) or 0)
	return _("Danach: %.2f / %.2f kg", weight, self.m_MaxWeight), weight > self.m_MaxWeight and Color.LightRed or Color.White
end

function Inventory:setViewMode(mode)
	self.m_ViewMode = mode
	core:set("Inventory", "ViewMode", mode)
	self:updateViewButton()
	self:buildLists()
	self:loadItems()
end

function Inventory:updateViewButton()
	local tiles = self.m_ViewMode == "tiles"
	self.m_ViewButton:setText(tiles and FontAwesomeSymbols.ThLarge or FontAwesomeSymbols.List)
	self.m_ViewButton:setTooltip(tiles and _"Ansicht: Kacheln" or _"Ansicht: Liste", "bottom")
end

function Inventory:destroyLists()
	for _index, list in ipairs(self.m_Lists or {}) do
		if list.grid then delete(list.grid) end
		if list.area then delete(list.area) end
		if list.background then delete(list.background) end
	end
	self.m_Lists = {}
	self.m_Tiles = {}
	self.m_LastSignature = nil
end

function Inventory:buildLists()
	self:destroyLists()

	local tab = Inventory.TabList[self.m_CurrentTab]
	if not tab then return end

	local definition = tab.lists[1]
	local height = HEIGHT - LIST_Y - s(10)

	if self.m_ViewMode == "tiles" then
		local background = GUIRectangle:new(LIST_X, LIST_Y, LIST_WIDTH, height, tocolor(0, 0, 0, 180), self.m_Window)
		local area = GUIScrollableArea:new(LIST_X, LIST_Y, LIST_WIDTH, height, LIST_WIDTH, 1, true, false, self.m_Window, LIST_Y)
		self.m_Lists[1] = {area = area, background = background, categories = definition.categories}
		return
	end

	local grid = GUIGridList:new(LIST_X, LIST_Y, LIST_WIDTH, height, self.m_Window, nil, definition.lineColor, s(30))
	local amountShare, weightShare = 0.12, 0.14
	local iconShare = s(34) / LIST_WIDTH
	local nameShare = 1 - iconShare - amountShare - weightShare - 15 / LIST_WIDTH
	grid:addColumn("", iconShare)
	grid:addColumn(Inventory.fitText(_(definition.title), LIST_WIDTH*nameShare - s(8), s(24)), nameShare)
	grid:addColumn(_"Menge", amountShare)
	grid:addColumn(_"Gewicht", weightShare)
	grid:setFont(VRPFont(s(24)))
	self.m_Lists[1] = {grid = grid, categories = definition.categories, nameWidth = LIST_WIDTH*nameShare - s(8)}
end

function Inventory:getDisplayName(row)
	local itemName = row["Objekt"]
	local value = tonumber(row["Value"])
	if self:getItemId(itemName) == 64 and value and SkinInfo[value] then
		return _(SkinInfo[value][1])
	elseif self:getItemId(itemName) == 123 and value and FurnitureInfo[value] then
		return _(FurnitureInfo[value][1])
	end
	return _(itemName)
end

function Inventory:getItemIcon(row)
	if row["WeaponIcon"] then
		return FileModdingHelper:getSingleton():getWeaponImage(row["WeaponIcon"]) or "files/images/Other/noImg.png"
	end
	local data = self.m_ItemData[row["Objekt"]]
	local value = tonumber(row["Value"])
	if data["WaffenId"] then
		return FileModdingHelper:getSingleton():getWeaponImage(data["WaffenId"]) or "files/images/Other/noImg.png"
	elseif self:getItemId(row["Objekt"]) == 64 and value and fileExists(("files/images/Skins/head/%d.png"):format(value)) then
		return ("files/images/Skins/head/%d.png"):format(value)
	elseif data["Icon"] and data["Icon"] ~= "" then
		return "files/images/Inventory/items/"..data["Icon"]
	end
	return "files/images/Other/noImg.png"
end

function Inventory:getAmmoIcon(weaponId)
	for itemName, data in pairs(self.m_ItemData or {}) do
		if data["MunitionFuer"] == weaponId then
			return self:getItemIcon({["Objekt"] = itemName})
		end
	end
	return "files/images/Other/noImg.png"
end

function Inventory:getRowWeight(row)
	local data = self.m_ItemData[row["Objekt"]]
	if data["DienstItem"] == 1 or row["Value"] == "duty" then return 0 end
	return data["Gewicht"] * row["Menge"]
end

function Inventory:getRowExpiry(row)
	local data = self.m_ItemData[row["Objekt"]]
	if data["VerfallAm"] then return data["VerfallAm"] end
	if data["VerfallTage"] then return tonumber(row["Value"]) end
	return false
end

function Inventory:isWeaponArmed(weaponId)
	return getPedWeapon(localPlayer, getSlotFromWeapon(weaponId)) == weaponId
end

function Inventory:getRounds(weaponId)
	local amount = 0
	for id, row in pairs(self.m_Items) do
		if self.m_ItemData[row["Objekt"]]["MunitionFuer"] == weaponId then
			amount = amount + row["Menge"]
		end
	end
	return amount
end

function Inventory:getRowFlags(row)
	local data = self.m_ItemData[row["Objekt"]]
	local flags = ""
	if data["WaffenId"] then
		if self:isWeaponArmed(data["WaffenId"]) then
			flags = flags.." [Hand]"
		end
		if not THROWABLE_WEAPONS[data["WaffenId"]] and not NO_MUNITION_WEAPONS[data["WaffenId"]] and self:getRounds(data["WaffenId"]) == 0 then
			flags = flags.." [Leer]"
		end
	end
	if row["Value"] == "duty" then
		flags = flags.." [Dienst]"
	end
	local expiry = self:getRowExpiry(row)
	if expiry then
		flags = flags..(" [%d T.]"):format(math.max(0, math.ceil((expiry - getRealTime().timestamp) / 86400)))
	end
	return flags
end

function Inventory:getGroupedRows(categories)
	local groups, order = {}, {}
	for id, row in pairs(self.m_Items) do
		local data = self.m_ItemData[row["Objekt"]]
		local visible = data and categories[data["Kategorie"]]
		if data and self.m_SearchText ~= "" then
			visible = utf8.lower(self:getDisplayName(row)):find(self.m_SearchText, 1, true)
		end
		if visible then
			local favorite = self:isFavorite(row["Objekt"])
			local groupName = favorite and "Favoriten" or data["Gruppe"]
			if not groups[groupName] then
				groups[groupName] = {weight = 0, rows = {}}
				order[#order + 1] = groupName
			end
			local group = groups[groupName]
			group.rows[#group.rows + 1] = id
			group.weight = group.weight + self:getRowWeight(row)
			group.rank = favorite and 0 or math.min(group.rank or 3, data["WaffenId"] and 1 or data["MunitionFuer"] and 3 or 2)
		end
	end
	table.sort(order, function(a, b)
		if groups[a].rank ~= groups[b].rank then return groups[a].rank < groups[b].rank end
		return a < b
	end)
	for _index, groupName in ipairs(order) do
		table.sort(groups[groupName].rows, function(a, b)
			local rowA, rowB = self.m_Items[a], self.m_Items[b]
			if self.m_SortMode == "amount" and rowA["Menge"] ~= rowB["Menge"] then
				return rowA["Menge"] > rowB["Menge"]
			elseif self.m_SortMode == "weight" and self:getRowWeight(rowA) ~= self:getRowWeight(rowB) then
				return self:getRowWeight(rowA) > self:getRowWeight(rowB)
			end
			if rowA["Objekt"] ~= rowB["Objekt"] then
				return rowA["Objekt"] < rowB["Objekt"]
			end
			return a < b
		end)
	end
	return order, groups
end

function Inventory:getSignature(order, groups)
	local parts = {}
	for _index, groupName in ipairs(order) do
		parts[#parts + 1] = groupName
		for _rowIndex, id in ipairs(groups[groupName].rows) do
			local row = self.m_Items[id]
			parts[#parts + 1] = ("%s|%s|%s|%s|%s|%s"):format(id, row["Objekt"], row["Menge"], tostring(row["Value"]), tostring(row["WearLevel"]), self:getRowFlags(row))
		end
	end
	return table.concat(parts, ";")
end

function Inventory:selectRow(id)
	local previous = self.m_Tiles and self.m_Tiles[self.m_SelectedId]
	if previous then previous:setColor(Color.Primary) end
	self.m_SelectedId = id
	local current = self.m_Tiles and self.m_Tiles[id]
	if current then current:setColor(Color.Accent) end
	self:updateDetail()
end

function Inventory:renderGrid(list, order, groups)
	list.grid:clear()
	for _index, groupName in ipairs(order) do
		local group = groups[groupName]
		list.grid:addItemNoClick(_(groupName), "", "", ("%.2f"):format(group.weight)):setFont(VRPFont(s(24)))
		for _rowIndex, id in ipairs(group.rows) do
			local row = self.m_Items[id]
			local flags = self:getRowFlags(row)
			local flagWidth = flags ~= "" and dxGetTextWidth(flags, 1, getVRPFont(VRPFont(s(24)))) or 0
			local name = Inventory.fitText(self:getDisplayName(row), list.nameWidth - flagWidth, s(24))
			local item = list.grid:addItem(self:getItemIcon(row), name..flags, row["Menge"], ("%.2f"):format(self:getRowWeight(row)))
			item:setColumnToImage(1, true, s(30))
			item:setFont(VRPFont(s(24)))
			local rarity = Inventory.RarityColor[self.m_ItemData[row["Objekt"]]["Seltenheit"]]
			if rarity then
				item:setColumnColor(2, rarity)
			end
			item.onLeftClick = function() self:selectRow(id) end
			item.onLeftDoubleClick = function() self:useRow(id) end
			item.onRightClick = function()
				list.grid:onInternalSelectItem(item)
				self:useRowSecondary(id)
			end
			if id == self.m_SelectedId then
				list.grid:onInternalSelectItem(item)
			end
		end
	end
end

function Inventory:createTile(area, id, x, y, width, height)
	local row = self.m_Items[id]
	local data = self.m_ItemData[row["Objekt"]]
	local tile = GUIRectangle:new(x, y, width, height, id == self.m_SelectedId and Color.Accent or Color.Primary, area)
	self.m_Tiles[id] = tile

	GUIImage:new((width - s(44)) / 2, s(4), s(44), s(44), self:getItemIcon(row), tile)

	local name = Inventory.fitText(self:getDisplayName(row), width - s(6), s(20))
	local nameLabel = GUILabel:new(s(3), s(50), width - s(6), s(18), name, tile):setFont(VRPFont(s(20))):setFontSize(1):setAlignX("center")
	local rarity = Inventory.RarityColor[data["Seltenheit"]]
	if rarity then nameLabel:setColor(rarity) end

	GUILabel:new(s(3), s(68), width - s(6), s(16), ("%.2f kg"):format(self:getRowWeight(row)), tile):setFont(VRPFont(s(18))):setFontSize(1):setAlignX("center")

	local flags = self:getRowFlags(row):gsub("^ ", "")
	if flags ~= "" then
		GUILabel:new(s(3), s(84), width - s(6), s(16), Inventory.fitText(flags, width - s(6), s(17)), tile):setFont(VRPFont(s(17))):setFontSize(1):setAlignX("center"):setColor(Color.Orange)
	end

	if row["Menge"] > 1 then
		local text = tostring(row["Menge"])
		local badgeWidth = dxGetTextWidth(text, 1, getVRPFont(VRPFont(s(18)))) + s(6)
		GUIRectangle:new(width - badgeWidth, 0, badgeWidth, s(16), Color.Background, tile)
		GUILabel:new(width - badgeWidth, 0, badgeWidth, s(16), text, tile):setFont(VRPFont(s(18))):setFontSize(1):setAlignX("center")
	end

	if data["MaxWear"] and row["WearLevel"] then
		local progress = math.max(0, math.min(1, row["WearLevel"] / data["MaxWear"]))
		GUIRectangle:new(0, height - s(4), width, s(4), Color.Background, tile)
		GUIRectangle:new(0, height - s(4), width * progress, s(4), tocolor(255 * (1 - progress), 255 * progress, 0), tile)
	end

	tile.onHover = function()
		if self.m_SelectedId ~= id then tile:setColor(Color.PrimaryNoClick) end
	end
	tile.onUnhover = function()
		if self.m_SelectedId ~= id then tile:setColor(Color.Primary) end
	end
	tile.onLeftClick = function() self:selectRow(id) end
	tile.onRightClick = function() self:useRowSecondary(id) end
	tile.onLeftDoubleClick = function() self:useRow(id) end
	for _index, child in ipairs(tile.m_Children) do
		child.onLeftDoubleClick = tile.onLeftDoubleClick
	end
end

function Inventory:renderTiles(list, order, groups)
	local area = list.area
	area:clear()
	self.m_Tiles = {}

	local margin, gap = s(6), s(6)
	local usable = LIST_WIDTH - margin*2 - s(6)
	local columns = math.max(1, math.floor((usable + gap) / (s(96) + gap)))
	local tileWidth = (usable - gap*(columns-1)) / columns
	local tileHeight = s(106)
	local y = margin

	for _index, groupName in ipairs(order) do
		local group = groups[groupName]
		GUILabel:new(margin, y, usable - s(90), s(22), _(groupName), area):setFont(VRPFont(s(22))):setFontSize(1):setColor(Color.Accent)
		GUILabel:new(margin + usable - s(90), y, s(90), s(22), ("%.2f kg"):format(group.weight), area):setFont(VRPFont(s(22))):setFontSize(1):setColor(Color.Accent):setAlignX("right")
		y = y + s(26)

		for rowIndex, id in ipairs(group.rows) do
			local column = (rowIndex - 1) % columns
			local line = math.floor((rowIndex - 1) / columns)
			self:createTile(area, id, margin + column*(tileWidth + gap), y + line*(tileHeight + gap), tileWidth, tileHeight)
		end
		y = y + math.ceil(#group.rows / columns) * (tileHeight + gap) + s(4)
	end

	area:resize(LIST_WIDTH, math.max(1, y))
end

function Inventory:loadItems()
	if not self.m_ItemData or not self.m_Lists or not self.m_Lists[1] or not Inventory.TabList[self.m_CurrentTab] then return end

	local list = self.m_Lists[1]
	local order, groups = self:getGroupedRows(list.categories)
	local signature = self:getSignature(order, groups)
	if signature ~= self.m_LastSignature then
		self.m_LastSignature = signature
		if list.area then
			self:renderTiles(list, order, groups)
		else
			self:renderGrid(list, order, groups)
		end
	end

	self:updateWeight()
	self:updateDetail()
end

function Inventory:updateWeight()
	local weight, maxWeight = self.m_Weight, self.m_MaxWeight
	local ratio = maxWeight > 0 and weight / maxWeight or 0
	local tabWeight = 0
	local categories = {}
	for _index, definition in ipairs(Inventory.TabList[self.m_CurrentTab].lists) do
		for category in pairs(definition.categories) do categories[category] = true end
	end
	for id, row in pairs(self.m_Items) do
		if categories[self.m_ItemData[row["Objekt"]]["Kategorie"]] then
			tabWeight = tabWeight + self:getRowWeight(row)
		end
	end

	self.m_WeightBar:setText(_("Gewicht: %.2f / %.2f kg", weight, maxWeight))
	self.m_WeightBar:setProgress(math.min(100, math.max(0, ratio*100)))
	self.m_WeightBar:setForegroundColor(ratio >= 1 and Color.Red or ratio >= 0.85 and Color.Orange or Color.Accent)
	self.m_WeightInfo:setText(_("Davon %s: %.2f kg", _(Inventory.TabList[self.m_CurrentTab].name), tabWeight))
	if ratio > 1 then
		self.m_WeightState:setText(self:isOverloadExempt() and _"Überlast: im Support-Modus ohne Sperre" or _"Überlast: kein Sprinten und Springen"):setColor(Color.LightRed)
	else
		self.m_WeightState:setText(_("Noch %.2f kg frei", math.max(0, maxWeight - weight))):setColor(ratio >= 1 and Color.LightRed or ratio >= 0.85 and Color.Orange or Color.White)
	end
end

function Inventory:getUseLabel(data, row)
	if data["WaffenId"] then
		return self:isWeaponArmed(data["WaffenId"]) and _"Wegstecken" or _"Ausrüsten"
	elseif data["Kategorie"] == "wear" then
		return _"Anziehen / Ablegen"
	elseif data["Kategorie"] == "place" then
		return _"Platzieren"
	end
	return _"Benutzen"
end

function Inventory:updateDetail()
	local row = self.m_SelectedId and self.m_Items[self.m_SelectedId]
	local enabled = row ~= nil and row ~= false
	self.m_UseButton:setEnabled(enabled)
	self.m_SecondaryButton:setVisible(false)
	self.m_UseButton:setPosition(DETAIL_X, HEIGHT-s(82))
	self.m_GiveButton:setEnabled(false)
	self.m_DropButton:setEnabled(false)
	self.m_FavoriteButton:setVisible(enabled)

	if not row then
		self.m_SelectedId = nil
		self.m_DetailImage:setImage("files/images/Other/noImg.png")
		self.m_DetailName:setText(_"Kein Item gewählt"):setColor(Color.White)
		self.m_DetailGroup:setText("")
		self.m_DetailInfo:setText(_"Wähle links ein Item aus.")
		self.m_DetailStats:setText("")
		return
	end

	local data = self.m_ItemData[row["Objekt"]]
	local isAmmo = data["MunitionFuer"] ~= nil
	self.m_DetailImage:setImage(self:getItemIcon(row))
	self.m_DetailName:setText(self:getDisplayName(row)):setColor(Inventory.RarityColor[data["Seltenheit"]] or Color.White)
	self.m_DetailGroup:setText(_(data["Gruppe"]))
	self.m_FavoriteButton:setBackgroundColor(self:isFavorite(row["Objekt"]) and Color.Orange or Color.PrimaryNoClick)
	local info = data["Info"] ~= "" and _(data["Info"]) or ""
	if data["WaffenId"] then info = _("GTA-Waffe mit der ID %d.", data["WaffenId"]) end
	if isAmmo then info = _("Munition für %s. Passt in keine andere Waffe.", WEAPON_NAMES[data["MunitionFuer"]]) end
	if (self:getItemId(row["Objekt"]) == 114 or self:getItemId(row["Objekt"]) == 54) and tonumber(row["Value"]) then
		info = _("%s (%s übrig)", info, tonumber(row["Value"]))
	end
	self.m_DetailInfo:setText(info)

	local stats = {
		_("%s %.2f kg", isAmmo and _"Je Schuss:" or _"Je Stück:", (data["DienstItem"] == 1 or row["Value"] == "duty") and 0 or data["Gewicht"]),
		_("%s %d", isAmmo and _"Schuss:" or _"Menge:", row["Menge"]),
		_("Gesamt: %.2f kg", self:getRowWeight(row)),
	}
	if Inventory.RarityName[data["Seltenheit"]] then
		stats[#stats + 1] = _("Seltenheit: %s", _(Inventory.RarityName[data["Seltenheit"]]))
	end
	local expiry = self:getRowExpiry(row)
	if expiry then
		local time = getRealTime(expiry)
		stats[#stats + 1] = _("Verfällt: %02d.%02d.%04d", time.monthday, time.month + 1, time.year + 1900)
	end
	if data["WaffenId"] and not THROWABLE_WEAPONS[data["WaffenId"]] then
		stats[#stats + 1] = _("Waffenslot: %d", getSlotFromWeapon(data["WaffenId"]))
		if not NO_MUNITION_WEAPONS[data["WaffenId"]] then
			stats[#stats + 1] = _("Munition: %d Schuss", self:getRounds(data["WaffenId"]))
		end
	end
	if isAmmo then
		stats[#stats + 1] = _("Passt zu: %s", WEAPON_NAMES[data["MunitionFuer"]])
	end
	if data["MaxWear"] and row["WearLevel"] then
		stats[#stats + 1] = _("Verschleiß: %d / %d", row["WearLevel"], data["MaxWear"])
	end
	if data["DienstItem"] == 1 or row["Value"] == "duty" then
		stats[#stats + 1] = _"Dienst-Item: wiegt nichts"
	end
	self.m_DetailStats:setText(table.concat(stats, "\n"))

	local armed = data["WaffenId"] and self:isWeaponArmed(data["WaffenId"]) and not THROWABLE_WEAPONS[data["WaffenId"]]
	self.m_UseButton:setText(self:getUseLabel(data, row))
	self.m_UseButton:setEnabled(not isAmmo)
	local hasSecondary = data["HatAlternativ"] == true
	self.m_SecondaryButton:setVisible(hasSecondary)
	self.m_SecondaryButton:setText(data["AlternativText"] and _(data["AlternativText"]) or _"Alternativ")
	self.m_UseButton:setPosition(DETAIL_X, hasSecondary and HEIGHT-s(114) or HEIGHT-s(82))
	self.m_GiveButton:setEnabled(data["Handel"] == 1 and row["Value"] ~= "duty" and data["DienstItem"] ~= 1 and not armed)
	self.m_DropButton:setEnabled(data["Wegwerf"] == 1 and not armed)
end

function Inventory:isBlocked(message)
	if localPlayer:getData("isTied") or localPlayer:getPublicSync("cuffed") or localPlayer:getData("Admin:IsFrozen") then
		ErrorBox:new(message)
		return true
	end
	return false
end

function Inventory:useSelected()
	local row = self.m_SelectedId and self.m_Items[self.m_SelectedId]
	if not row or self:isBlocked(_"Du kannst derzeit nichts benutzen.") then return end
	triggerServerEvent("onPlayerItemUseServer", localPlayer, self.m_SelectedId, row["Tasche"], row["Objekt"], row["Platz"], self.m_ItemData[row["Objekt"]]["Verbraucht"] == 1)
end

function Inventory:useSelectedSecondary()
	local row = self.m_SelectedId and self.m_Items[self.m_SelectedId]
	if not row or self:isBlocked(_"Du kannst derzeit nichts benutzen.") then return end
	triggerServerEvent("onPlayerSecondaryItemUseServer", localPlayer, self.m_SelectedId, row["Tasche"], row["Objekt"], row["Platz"])
end

function Inventory:useRow(id)
	self:selectRow(id)
	if self.m_UseButton:isEnabled() then
		self:useSelected()
	end
end

function Inventory:useRowSecondary(id)
	self:selectRow(id)
	local row = self.m_Items[id]
	if row and self.m_ItemData[row["Objekt"]]["HatAlternativ"] == true then
		self:useSelectedSecondary()
	end
end

function Inventory:dropSelected()
	local id = self.m_SelectedId
	local row = id and self.m_Items[id]
	if not row or self:isBlocked(_"Du kannst derzeit nichts wegwerfen.") then return end

	local drop = function(amount)
		triggerServerEvent("throwItem", localPlayer, false, row["Tasche"], id, row["Platz"], row["Objekt"], amount)
	end
	if row["Menge"] > 1 then
		ItemAmountBox:new(_"Wegwerfen", _("Wie viel %s möchtest du wegwerfen?", row["Objekt"]), row["Menge"], drop)
	else
		QuestionBox:new(_("Möchtest du %s wirklich wegwerfen?", row["Objekt"]), function() drop(1) end)
	end
end

function Inventory:giveSelected()
	local row = self.m_SelectedId and self.m_Items[self.m_SelectedId]
	if not row or self:isBlocked(_"Du kannst derzeit nichts geben.") then return end

	local players, names = {}, {}
	for _index, player in ipairs(getElementsByType("player", root, true)) do
		if player ~= localPlayer and (player.position - localPlayer.position).length <= 10 then
			players[#players + 1] = player
			names[#names + 1] = player:getName()
		end
	end
	if #players == 0 then
		ErrorBox:new(_"Es ist kein Spieler in der Nähe.")
		return
	end

	ChangerBox:new(_"Geben", _("%s geben an:", row["Objekt"]), names, function(index)
		local target = players[index]
		if not isElement(target) then return end
		local send = function(amount)
			triggerServerEvent("requestTrade", localPlayer, "Item", target, row["Objekt"], amount, 0, row["Value"] ~= "" and row["Value"] or nil)
		end
		if row["Menge"] > 1 then
			ItemAmountBox:new(_"Geben", _("Wie viel %s möchtest du geben?", row["Objekt"]), row["Menge"], send)
		else
			send(1)
		end
	end)
end

function Inventory:onShow()
	showCursor(true)
	triggerServerEvent("refreshInventory", localPlayer)
	self.Show = true
	self:loadItems()
end

function Inventory:onHide()
	showCursor(false)
	self.Show = false
	self.m_SearchText = ""
	self.m_Search:setText("")
end

function Inventory:getItemName(itemId)
	if type(itemId) ~= "number" then return itemId end
	for itemName, data in pairs(self.m_ItemData or {}) do
		if data["Id"] == itemId then
			return itemName
		end
	end
	return false
end

function Inventory:getItemId(itemName)
	local data = self.m_ItemData and self.m_ItemData[itemName]
	return data and data["Id"] or false
end

function Inventory:getItemAmount(item)
	triggerServerEvent("refreshInventory", localPlayer)
	item = self:getItemName(item)
	local amount = 0
	for index, itemInv in pairs(self.m_Items) do
		if itemInv["Objekt"] == item then
			amount = amount + itemInv["Menge"]
		end
	end
	return amount
end
