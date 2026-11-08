-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/GangwarAttack.lua
-- *  PURPOSE:     Gangwar HUD
-- *
-- ****************************************************************************

--[[
 This class includes the score bar at the top of the screen with both factions, the alive players, the phase and the remaining time.
 Below it the damage and kills of the localPlayer are shown.

	_____________________________________________
	| FACTION-NAME  X/X | PHASE | X/X  FACTION-NAME2 |
	|___________________| TIME  |___________________|
	          | DAMAGE | FLAG | KILLS |
---]]

GangwarDisplay = inherit(Object)
local w, h = screenWidth, screenHeight
local width, height = w*0.5, h*0.065
local startX, startY = (w - width)/2, 0
local TOP_ROW_SHARE = 0.58
local CENTER_SHARE = 0.2
local overViewHeight = h*0.4 / ASPECT_RATIO_MULTIPLIER
local overViewWidth =  screenWidth/2-(screenWidth*0.65/2) / ASPECT_RATIO_MULTIPLIER
local overViewStartHeight = h*0.5-h*0.3+(screenWidth*0.65)*0.06
local overViewHealthWidth = dxGetTextWidth("200", 1, "default-bold")
local gradientTexture = dxCreateTexture( "files/images/Gangwar/gradient.png", "argb", true, "clamp")
local overViewLocationSize = 1
local overViewNameSize = 1
if w < 1280 and h < 850 then
	overViewLocationSize = 0.4
	overViewNameSize = 0.4
	if w < 900 then
		overViewLocationSize = 0
		overViewNameSize = 0.5
	end
end
local moveStateImages =
{
	["stand"] = "stand_icon",
	["walk"] = "run_icon",
	["jog"] = "run_icon",
	["sprint"] = "run_icon",
	["crouch"] = "stand_icon",
	["crawl"] = "run_icon",
	["jump"] = "run_icon",
	["fall"] = "run_icon",
	["climb"] = "run_icon",
	["powerwalk"] = "run_icon",
}

local PHASE_TITLES = {
	prepare = "Aufbauphase",
	battle = "Attackphase",
	["end"] = "Endphase",
}

-- constructor/destructor --
function GangwarDisplay:constructor( fac1, fac2, pAttackClient, pPhase, pInitTime, pPos )
	self.m_Faction1 = fac1
	self.m_Faction2 = fac2
	self.m_AttackClient = pAttackClient
	self.m_Phase = pPhase
	self.m_TimeLeft = pInitTime
	startX = tonumber(core:get("Gangwar", "DisplayTopX", startX)) or startX
	startY = tonumber(core:get("Gangwar", "DisplayTopY", startY)) or startY
	self.m_BindRender = bind( self.render,self)
	self.m_FlagPosition = pPos
	addEventHandler("onClientRender",root,self.m_BindRender)
	self.m_BindClick = bind(self.click,self)
	addEventHandler("onClientClick",root,self.m_BindClick)
	self.m_BindFuncTime = bind( GangwarDisplay.tickTime, self )
	self.m_TickTimer = setTimer( self.m_BindFuncTime, 1000, 0 )
end

function GangwarDisplay:destructor()
	removeEventHandler("onClientRender",root,self.m_BindRender)
	removeEventHandler("onClientClick",root,self.m_BindClick)
	if isTimer(self.m_TickTimer) then killTimer(self.m_TickTimer) end
end

-- draw-functions --
function GangwarDisplay:render()
	if CustomF11Map:isInstantiated() and CustomF11Map:getSingleton().m_Visible then return end
	self:checkDragDrop()
	self:rend_Display()
end

function GangwarDisplay:drawTeamBox(faction, x, boxWidth, boxHeight, isLeft)
	local color = faction.m_Color
	local white = tocolor(255, 255, 255, 255)
	local padding = boxWidth*0.04
	local participants = #self.m_AttackClient:getFactionParticipants(faction)
	local score = participants.."/"..self.m_AttackClient:getPickCount(faction)
	dxDrawImage(x, startY, boxWidth, boxHeight, "files/images/gangwar/tile.png", 0, 0, 0, tocolor(color.r, color.g, color.b, 220))
	self:dxDrawBoxShape(x, startY, boxWidth, boxHeight, tocolor(0, 0, 0, 255))
	self:drawShadowBoxText(faction.m_Name, x + padding, startY, boxWidth - padding*2, boxHeight, white, 1.2, "default-bold", isLeft and "left" or "right", "center")
	self:drawShadowBoxText(score, x + padding, startY, boxWidth - padding*2, boxHeight, white, 1.4, "default-bold", isLeft and "right" or "left", "center")
end

function GangwarDisplay:drawInfoCell(x, y, cellWidth, cellHeight, image, text)
	local iconSize = cellHeight*0.8
	local textWidth = dxGetTextWidth(text, 1, "default-bold")
	local contentX = x + (cellWidth - iconSize - 6 - textWidth)/2
	dxDrawImage(contentX, y + cellHeight*0.1, iconSize, iconSize, image)
	self:drawShadowBoxText(text, contentX + iconSize + 6, y, textWidth + 2, cellHeight, tocolor(255, 255, 255, 255), 1, "default-bold", "left", "center")
end

function GangwarDisplay:rend_Display( )
	local topHeight = height*TOP_ROW_SHARE
	local bottomHeight = height - topHeight
	local centerWidth = width*CENTER_SHARE
	local sideWidth = (width - centerWidth)/2
	local centerX = startX + sideWidth
	local white = tocolor(255, 255, 255, 255)

	self:drawTeamBox(self.m_Faction1, startX, sideWidth, topHeight, true)
	self:drawTeamBox(self.m_Faction2, centerX + centerWidth, sideWidth, topHeight, false)

	dxDrawRectangle(centerX, startY, centerWidth, topHeight, tocolor(0, 0, 0, 230))
	self:dxDrawBoxShape(centerX, startY, centerWidth, topHeight, tocolor(0, 0, 0, 255))
	self:drawShadowBoxText(PHASE_TITLES[self.m_Phase] or "", centerX, startY + topHeight*0.03, centerWidth, topHeight*0.45, white, 1, "default-bold", "center", "center")
	self:drawShadowBoxText(self:formatTick(self.m_TimeLeft), centerX, startY + topHeight*0.47, centerWidth, topHeight*0.5, white, 1.3, "default-bold", "center", "center")

	local rowWidth = width*0.5
	local rowX = startX + (width - rowWidth)/2
	local rowY = startY + topHeight
	local cellWidth = rowWidth/3
	dxDrawRectangle(rowX, rowY, rowWidth, bottomHeight, tocolor(0, 0, 0, 180))
	self:dxDrawBoxShape(rowX, rowY, rowWidth, bottomHeight, tocolor(0, 0, 0, 255))
	self:drawInfoCell(rowX, rowY, cellWidth, bottomHeight, "files/images/gangwar/gw_damage.png", tostring(self.m_AttackClient.m_GangwarDamage))
	self:drawInfoCell(rowX + cellWidth*2, rowY, cellWidth, bottomHeight, "files/images/gangwar/gw_kill.png", tostring(self.m_AttackClient.m_GangwarKill))
	self:rend_Flag(rowX + cellWidth, rowY, cellWidth, bottomHeight)

	if not dxGetStatus().AllowScreenUpload then
		dxDrawRectangle(0, 0, w, h, tocolor(0, 0, 0, 255), true)
		dxDrawText('Bitte aktiviere die Option "Erlauben von Screenshots" unter MTA -> Einstellungen', 0, 0, w, h, tocolor(255, 255, 255, 255), 2, "clear", "center", "center", false, false, true)
	end
	if ScoreboardGUI and ScoreboardGUI:getSingleton().m_Showing and core:get("Other", "GangwarTabView", true) then
		self:drawParticipantOverview()
	end
end

function GangwarDisplay:rend_Flag(x, y, cellWidth, cellHeight)
	local flagX, flagY = self.m_FlagPosition[1], self.m_FlagPosition[2]
	local px, py = getElementPosition(localPlayer)
	local distance = math.floor(getDistanceBetweenPoints2D(flagX, flagY, px, py))
	local color = distance > 15 and "#ee0000" or "#00ee00"
	dxDrawText(color..distance.."#ffffff/15 m", x, y, x + cellWidth, y + cellHeight, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center", false, false, false, true)
end

function GangwarDisplay:drawParticipantOverview()
	local faction
	local factionPlayers1 = {}
	local factionPlayers2 = {}
	local localFaction = localPlayer:getFactionId()
	local localFactionObject = localPlayer:getFaction()
	local enemyFaction, enemyFactionObject
	local slot = localPlayer:getPublicSync("gangwarParticipant")
	if not slot then return end
	for key, player in ipairs(getElementsByType("player")) do
		if player:getPublicSync("gangwarParticipant") == slot then
			if player:getFactionId() == localFaction then
				factionPlayers1[#factionPlayers1+1] = player
			else
				factionPlayers2[#factionPlayers2+1] = player
				if not enemyFaction then
					enemyFaction = player:getFactionId()
					enemyFactionObject = player:getFaction()
				end
			end
		end
	end
	if enemyFaction and enemyFactionObject then
		self:drawAttackerOverview( factionPlayers1, factionPlayers2, localFactionObject.m_Color["r"], localFactionObject.m_Color["g"], localFactionObject.m_Color["b"], enemyFactionObject.m_Color["r"], enemyFactionObject.m_Color["g"], enemyFactionObject.m_Color["b"] )
	else
		self:drawAttackerOverview( factionPlayers1, factionPlayers2, localFactionObject.m_Color["r"], localFactionObject.m_Color["g"], localFactionObject.m_Color["b"])
	end
end

function GangwarDisplay:drawAttackerOverview( playerTable, enemyTable, r, g, b, r2, g2, b2 )
	local left, right = ScoreboardGUI:getSingleton():getBodyRange()
	local heightPerElement =  overViewHeight / #playerTable
	if heightPerElement >= h*0.06 then heightPerElement = h*0.06 end
	for i = 0, #playerTable -1, 1 do
		self:drawPlayerOverview(playerTable[i+1], left - overViewWidth, overViewStartHeight+(heightPerElement*i), overViewWidth, heightPerElement, r, g, b)
	end
	if r2 and g2 and b2 then
		for i = 0, #enemyTable -1, 1 do
			self:drawEnemyOverview(enemyTable[i+1], right, overViewStartHeight+(heightPerElement*i), overViewWidth, heightPerElement, r2, g2, b2)
		end
	end
end

function GangwarDisplay:drawPlayerOverview( player, x, y, width, height, r, g, b)
	local health = getElementHealth( player )
	local armor = getPedArmor( player )
	local weapon = getPedWeapon(player)
	local healthbar = (health+armor) / 200
	local px,py,pz = getElementPosition(player)
	local zoneName = getZoneName(px, py, pz)
	local moveState = getPedMoveState(player)

	dxDrawRectangle(x, y+height*0.05, width- height*0.5, height*0.9, tocolor( 0, 0, 0, 100))
	dxDrawImage(x, y+height*0.05, (width-height*0.5)*healthbar, height*0.45, gradientTexture, 0, 0, 0, tocolor(r*0.6, g*0.6, b*0.6, 200))

	dxDrawText("#e8f0ff"..math.ceil(health+armor), x+width*0.01+height*0.3, y+height*0.05, x+width*0.01+height*0.3+overViewHealthWidth, y+height*0.45, tocolor(255, 255, 255, 255),  1, "default-bold", "left", "center", false, false, false, true )
	dxDrawImage(x+width*0.01, y+height*0.125, height*0.25, height*0.25, "files/images/Gangwar/armor.png")
	dxDrawText(getPlayerName(player), x+overViewHealthWidth+height*0.3+width*0.08, y+height*0.05, x+width*0.15, y+height*0.45, tocolor(255, 255, 255, 255), overViewNameSize, "default-bold", "left", "center", false, false, false, true )
	dxDrawText(zoneName, x+width*0.01, y+height*0.55, x+width, y+height, tocolor( 200, 200, 200, 255), overViewLocationSize, "default-bold")
	dxDrawImage(x+width - height*0.8, y+height*0.1, height*0.3, height*0.3, "files/images/Gangwar/"..(moveStateImages[moveState] or "stand_icon")..".png")
	dxDrawImage(x+width-height*0.5, y+height*0.25, height*0.5, height*0.5, "files/images/Weapons/"..(weapon or 0)..".png")
end

function GangwarDisplay:drawEnemyOverview( player, x, y, width, height, r, g, b)
	dxDrawRectangle(x, y+height*0.05, width, height*0.9, tocolor( 0, 0, 0, 100))
	dxDrawImage(x, y+height*0.05, width, height*0.45, gradientTexture, 0, 0, 0, tocolor(r*0.6, g*0.6, b*0.6, 200))
	dxDrawText(getPlayerName(player), x+width*0.05, y+height*0.05, x+width, y+height*0.45, tocolor(255, 255, 255, 255), overViewNameSize, "default-bold", "left", "center", false, false, false, true )
end

-- synchronize functions --
function GangwarDisplay:synchronize( pPhase, pTime )
	self.m_Phase = pPhase
	self.m_TimeLeft = pTime
end

function GangwarDisplay:tickTime( )
	self.m_TimeLeft = math.max(0, self.m_TimeLeft - 1)
end

-- click functions --
function GangwarDisplay:checkDragDrop()
	if self.m_Drag then
		local cx, cy = getCursorPosition()
		cx = cx*w;
		cy = cy*h;
		if not self.offsetX and not self.offsetY then
			self.offsetX = cx - startX
			self.offsetY = cy - startY
		end
		startX = cx - self.offsetX
		startY = cy - self.offsetY
	end
end

function GangwarDisplay:click( b, s)
	if b == "left" then
		local b_Over = self:isMouseOver( startX,startY,width,height)
		if b_Over then
			if s == "down" then
				self.m_Drag = true
			else
				self:stopDrag()
			end
		else
			self:stopDrag()
		end
	end
end

function GangwarDisplay:stopDrag()
	if self.m_Drag then
		core:set("Gangwar", "DisplayTopX", startX)
		core:set("Gangwar", "DisplayTopY", startY)
	end
	self.m_Drag = false
	self.offsetX = nil
	self.offsetY = nil
end

-- These functions are utilities --
function GangwarDisplay:drawShadowBoxText( text,x,y,w,h, color,... )
	self:dxDrawBoxText(text,x-1,y-1,w,h,tocolor(0,0,0,255),...)
	self:dxDrawBoxText(text,x+1,y+1,w,h,tocolor(0,0,0,255),...)
	self:dxDrawBoxText(text,x,y,w,h,color,...)
end

function GangwarDisplay:draw_DisplayBox( x , y , w , h ,color)
	dxDrawRectangle(x , y , w , h ,tocolor(0,0,0,100))
	--self:dxDrawBoxShape( x , y , w , h )
end

function GangwarDisplay:dxDrawBoxShape( x, y, w, h , ...)
	dxDrawLine( x, y, x+w,y,...)
	dxDrawLine( x, y+h , x +w , y+h,...)

	dxDrawLine( x , y ,x , y+h , ... )
	dxDrawLine( x+w , y ,x+w , y+h , ...)
end


function GangwarDisplay:isMouseOver( x,y,width,height)
	if isCursorShowing() then
		local cx,cy = getCursorPosition()
		cx = cx*w
		cy = cy*h
		if cx >= x and cx <= x+width then
			if cy >= y and cy <= y+height then
				return true
			end
		end
	end
	return false
end

function GangwarDisplay:dxDrawBoxText( text , x, y , w , h , ... )
	dxDrawText( text , x , y , x + w , y + h , ... )
end

function GangwarDisplay:formatTick( tick )
	if tick then
		 return string.format("%.2d:%.2d", tick/60%60, tick%60)
	end
end
