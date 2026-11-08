GangwarReview = inherit(Singleton)
addRemoteEvents{"GangwarReview:show"}

local BEST_PLAYER_COUNT = 3
local FONT_HEIGHT = 24
local TITLE_BRIGHTNESS_LIMIT = 160

function GangwarReview:constructor()
	addEventHandler("GangwarReview:show", localPlayer, bind(self.Event_show, self))
end

function GangwarReview:getSideValue(side, own)
	if side.id == own.factionId then
		return _("%s (deine Fraktion)", side.name)
	end
	return side.name
end

function GangwarReview:getBestLines(best)
	local lines = {}
	for index = 1, math.min(BEST_PLAYER_COUNT, #best) do
		local entry = best[index]
		local text = _("%d. %s (%s) - %d Damage, %d Kills", index, entry.name, entry.faction, entry.damage, entry.kills)
		if index == 1 and entry.damage > 0 then
			text = text .. " (MVP)"
		end
		lines[#lines + 1] = {value = text}
	end
	return lines
end

function GangwarReview:fitValue(value, width, font)
	if dxGetTextWidth(value, 1, font) <= width then return value end
	while utf8.len(value) > 1 and dxGetTextWidth(value .. "…", 1, font) > width do
		value = utf8.sub(value, 1, utf8.len(value) - 1)
	end
	return value .. "…"
end

function GangwarReview:prepareLines(lines)
	local font = getVRPFont(VRPFont(FONT_HEIGHT))
	local boldFont = getVRPFont(VRPFont(FONT_HEIGHT, Fonts.EkMukta_Bold))
	local width = HUDRadar:getSingleton():getWidth() - 8
	local plainLines = {}
	for index, line in ipairs(lines) do
		line.label = line.label or ""
		line.labelWidth = line.label ~= "" and dxGetTextWidth(line.label .. " ", 1, boldFont) or 0
		line.value = self:fitValue(line.value or "", width - line.labelWidth, font)
		plainLines[index] = line.value ~= "" and line.value or " "
	end
	return table.concat(plainLines, "\n")
end

function GangwarReview:getTitleTextColor(color, alpha)
	local brightness = color.r*0.299 + color.g*0.587 + color.b*0.114
	if brightness > TITLE_BRIGHTNESS_LIMIT then
		return tocolor(0, 0, 0, alpha)
	end
	return tocolor(255, 255, 255, alpha)
end

function GangwarReview:drawLines(message, lines, title, titleColor)
	ShortMessage.drawThis(message)

	local font = getVRPFont(VRPFont(FONT_HEIGHT))
	local boldFont = getVRPFont(VRPFont(FONT_HEIGHT, Fonts.EkMukta_Bold))

	local x = message.m_AbsoluteX + 4
	local y = message.m_AbsoluteY
	dxDrawText(title, x, y - 2, x + message.m_Width, y + 16, self:getTitleTextColor(titleColor, message.m_Alpha), message:getFontSize(), font, "left", "top", false, true)
	y = y + (message.m_TitleHeight or 0)
	local lineHeight = dxGetFontHeight(message:getFontSize(), font)
	local color = tocolor(255, 255, 255, message.m_Alpha)
	for index, line in ipairs(lines) do
		if line.label ~= "" then
			local labelColor = line.isHeader and Color.changeAlpha(Color.Accent, message.m_Alpha) or color
			dxDrawText(line.label, x, y, x + message.m_Width, y + lineHeight, labelColor, message:getFontSize(), boldFont)
		end
		if line.value ~= "" then
			local valueColor = line.isValueAccent and Color.changeAlpha(Color.Accent, message.m_Alpha) or color
			dxDrawText(line.value, x + line.labelWidth, y, x + message.m_Width, y + lineHeight, valueColor, message:getFontSize(), font)
		end
		y = y + lineHeight
	end
end

function GangwarReview:Event_show(review, own)
	local lines = {
		{label = _"Gebiet:", value = review.area, isHeader = true, isValueAccent = true},
		{label = _"Angreifer:", value = self:getSideValue(review.attacker, own)},
		{label = _"Verteidiger:", value = self:getSideValue(review.defender, own)},
		{label = _"Dauer:", value = _("%d:%02d Minuten", math.floor(review.duration/60), review.duration%60)},
		{},
		{label = _"Eigene Stats", isHeader = true},
		{label = _"Schaden:", value = _("%d (%d$)", own.damage, own.moneyDamage)},
		{label = _"Kills:", value = _("%d (%d$)", own.kills, own.moneyKill)},
		{},
		{label = _"Bestenliste", isHeader = true},
	}
	for key, line in ipairs(self:getBestLines(review.best)) do
		lines[#lines + 1] = line
	end
	lines[#lines + 1] = {}
	lines[#lines + 1] = {value = _"Zum Schließen anklicken"}

	local text = self:prepareLines(lines)
	local color = own.color
	local title = _"Rückblick - Gangwar"
	local message = ShortMessage:new(text, title, {color.r, color.g, color.b}, -1)
	message.m_Text = ""
	message.m_Title = ""
	message.drawThis = function(element)
		self:drawLines(element, lines, title, color)
	end
end
