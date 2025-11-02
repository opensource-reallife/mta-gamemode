SanNews = inherit(Company)

function SanNews:constructor()
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_Blips = {}
	self.m_NextAd = getRealTime().timestamp
	self.m_onInterviewColshapeLeaveFunc = bind(self.onInterviewColshapeLeave, self)
	self.m_onPlayerChatFunc = bind(self.Event_onPlayerChat, self)
	self.m_SanNewsMessageEnabled = false
	self.m_RunningEvent = false
	self.m_AppUnlocked = {}

	local safe = createObject(2332, 294.43, -22.6, 1031.7)
	safe:setInterior(10)
 	self:setSafe(safe)

	local id = self:getId()
	local blip = Blip:new("House.png", 1219.20, -1812.31, {company = id}, 400, {companyColors[id].r, companyColors[id].g, companyColors[id].b})
	blip:setDisplayText(self:getName(), BLIP_CATEGORY.Company)

	local elevator = Elevator:new()
	elevator:addStation("Heliport", Vector3(1242, -1777.0996, 33.7), 270)
	elevator:addStation("Erdgeschoss", Vector3(296.49, -36.23, 1032.20), 90, 10)

	local gateLeft = Gate:new(988, Vector3(1211, -1841.9004, 13.4), Vector3(0, 0, 0), Vector3(1206, -1841.9004, 13.4))
	gateLeft.onGateHit = bind(self.onBarrierHit, self)
	gateLeft:addGate(988, Vector3(1216.5, -1841.9004, 13.4), Vector3(0, 0, 0), Vector3(1221.9004, -1841.9004, 13.4))

	local gateRight = Gate:new(988, Vector3(1267.4, -1841.9004, 13.4), Vector3(0, 0, 0), Vector3(1262, -1841.9004, 13.4))
	gateRight.onGateHit = bind(self.onBarrierHit, self)
	gateRight:addGate(988, Vector3(1272.9004, -1841.9004, 13.4), Vector3(0, 0, 0), Vector3(1277.9004, -1841.9004, 13.4))

	InteriorEnterExit:new(Vector3(1211.15, -1749.66, 13.6), Vector3(267.03, -23.87, 1032.20), 220, 0, 10) -- main entrance
	InteriorEnterExit:new(Vector3(1219.20, -1812.25, 16.59), Vector3(259.91, -74.91, 1037.35), 0, 180, 10) -- back entrance / parking lot

	-- Register in Player Hooks
	Player.getQuitHook():register(bind(self.Event_onPlayerQuit, self))
	Player.getChatHook():register(bind(self.Event_onPlayerChat, self))

	addRemoteEvents{"sanNewsStartInterview", "sanNewsStopInterview", "sanNewsAdvertisement", "sanNewsToggleMessage", "sanNewsStartStreetrace", "sanNewsAddBlip", "sanNewsDeleteBlips", "requestNewsAppUnlock"}
	addEventHandler("sanNewsStartInterview", root, bind(self.Event_startInterview, self))
	addEventHandler("sanNewsStopInterview", root, bind(self.Event_stopInterview, self))
	addEventHandler("sanNewsAdvertisement", root, bind(self.Event_advertisement, self))
	addEventHandler("sanNewsToggleMessage", root, bind(self.Event_toggleMessage, self))
	addEventHandler("sanNewsStartStreetrace", root, bind(self.Event_startStreetrace, self))
	addEventHandler("sanNewsAddBlip", root, bind(self.Event_addBlip, self))
	addEventHandler("sanNewsDeleteBlips", root, bind(self.Event_deleteBlips, self))
	addEventHandler("requestNewsAppUnlock", root, bind(self.Event_requestNewsAppUnlock, self))

	addCommandHandler("news", bind(self.Event_news, self))
	addCommandHandler("sannews", bind(self.Event_sanNewsMessage, self), false, false)
end

function SanNews:destuctor()

end

function SanNews:onBarrierHit(player)
    if player:getCompany() ~= self then
        return false
    end
    return true
end

function SanNews:Event_news(player, cmd, ...)
	if player:getCompany() == self then
		if player:isCompanyDuty() then
			local argTable = { ... }
			local text = table.concat ( argTable , " " )
			outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)

    		local receivedPlayers = {}
			for k, targetPlayer in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
				if targetPlayer ~= player then
					if targetPlayer:isLoggedIn() then
						receivedPlayers[#receivedPlayers+1] = targetPlayer
					end
				end
			end
			StatisticsLogger:getSingleton():addChatLog(player, "news", text, receivedPlayers)
		else
			player:sendError(_("Du bist nicht im Dienst!", player))
		end
	end
end

function SanNews:Event_startInterview(target)
	if client:getCompany() == self then
		if client:isCompanyDuty() then
			if not self.m_isInterview then
				self.m_isInterview = true
				self.m_InterviewColshape = createColSphere(client.position, 4)
				self.m_InterviewColshape:attach(client)

				client:sendInfo(_("Du hast ein Interview mit %s gestartet!", client, target.name))
				target:sendInfo(_("Reporter %s hat ein Interview mit dir gestartet!", target, client.name))
				target:sendShortMessage(_("Interview: Alles was du im Chat schreibst ist nun öffentlich! (Außnahme: @l [text])", target))
				self:addInterviewPlayer(client)
				self:addInterviewPlayer(target)
			else
				client:sendError(_("Es findet bereits ein Interview statt!", client))
			end
		else
			client:sendError(_("Du bist nicht im Dienst!", client))
		end
	end
end

function SanNews:addInterviewPlayer(player)
	table.insert(self.m_InterviewPlayer, player)
	player:setPublicSync("inInterview", true)
end

function SanNews:Event_stopInterview(target)
	if client:getCompany() == self then
		if client:isCompanyDuty() then
			client:sendInfo(_("Du hast das Interview mit %s beendet!", client, target.name))
			target:sendInfo(_("Reporter %s hat das Interview mit dir beendet!", target, client.name))
			self:stopInterview()
		else
			client:sendError(_("Du bist nicht im Dienst!", client))
		end
	end
end

function SanNews:Event_onPlayerQuit()
	if table.find(self.m_InterviewPlayer, source) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview beendet! Ein Spieler ist offline gegangen!", player))
		end
		self:stopInterview()
	end
end

function SanNews:onInterviewColshapeLeave(leaveElement)
	if table.find(self.m_InterviewPlayer, leaveElement) then
		for index, player in pairs(self.m_InterviewPlayer) do
			player:sendInfo(_("Interview beendet! Ihr habt euch zu weit entfernt!", player))
		end
		self:stopInterview()
	end
end

function SanNews:stopInterview()
	for index, player in pairs(self.m_InterviewPlayer) do
		player:setPublicSync("inInterview", false)
	end
	self.m_isInterview = false
	self.m_InterviewPlayer = {}
	self.m_InterviewColshape:destroy()
end

function SanNews:Event_onPlayerChat(player, text, type)
	if type == 0 then
		if table.find(self.m_InterviewPlayer, player) then
			if text:sub(1, 2):lower() ~= "@l" then
				if player:getCompany() == self and player:isCompanyDuty() then
					outputChatBox(_("#FE8D14Reporter %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				else
					outputChatBox(_("#FE8D14[Interview] %s:#FEDD42 %s", player, player.name, text), root, 255, 200, 20, true)
				end

				local receivedPlayers = {}
				for k, targetPlayer in pairs(getElementsByType("player")) do
					if targetPlayer ~= player then
						if targetPlayer:isLoggedIn() then
							receivedPlayers[#receivedPlayers+1] = targetPlayer
						end
					end
				end
				StatisticsLogger:getSingleton():addChatLog(player, "interview", text, receivedPlayers)
				return true
			end
		end
	end
end

function SanNews:Event_advertisement(senderIndex, text, color, duration)
	local length = text:len()
	if length <= 50 and length >= 5 then
		local durationExtra = (AD_DURATIONS[duration] - 20) * 2
		local colorMultiplicator = 1
		if color ~= "Schwarz" then
			colorMultiplicator = 2
		end

		local costs = (length*AD_COST_PER_CHAR + AD_COST + durationExtra) * colorMultiplicator

		if (client:getPlayTime() / 60) >= AD_MIN_PLAYTIME then
			if client:getBankMoney() >= costs then
				if self.m_NextAd < getRealTime().timestamp then
					client:transferBankMoney({self, nil, true}, costs, "San News Ad", "Company", "Ads")
					self.m_NextAd = getRealTime().timestamp + AD_DURATIONS[duration] + AD_BREAK_TIME
					StatisticsLogger:getSingleton():addAdvert(client, text)

					local sender = {referenz = "player", name = client:getName()}
					if senderIndex == 2 and client:getGroup() and client:getGroup():getName() then
						sender = {referenz = "group", name = client:getGroup():getName(), number = client:getGroup():getPhoneNumber()}
					elseif senderIndex == 3 and client:getFaction() and client:getFaction():getShortName() then
						sender = {referenz = "faction", name = client:getFaction():getShortName(), number = client:getFaction():getPhoneNumber()}
					elseif senderIndex == 4 and client:getCompany() and client:getCompany():getShortName() then
						sender = {referenz = "company", name = client:getCompany():getShortName(), number = client:getCompany():getPhoneNumber()}
					end

					triggerClientEvent("showAd", client, sender, text, color, duration)
				else
					local next = self.m_NextAd - getRealTime().timestamp
					client:sendError(_("Die nächste Werbung kann erst in %d Sekunden gesendet werden!", client, next))
				end
			else
				client:sendError(_("Du hast zu wenig Geld dabei! (%s$)", client, costs))
			end
		else
			client:sendError(_("Du benötigst dafür mindestens %d Spielstunden!", client, AD_MIN_PLAYTIME))
		end
	end
end

function SanNews:Event_toggleMessage()
	if self.m_SanNewsMessageEnabled then
		self.m_SanNewsMessageEnabled = false
		self:sendShortMessage(("%s hat /sannews deaktiviert!"):format(client:getName()))
	else
		self.m_SanNewsMessageEnabled = true
		self:sendShortMessage(("%s hat /sannews aktiviert!"):format(client:getName()))
	end
end

function SanNews:Event_startStreetrace()
	if PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "startStreetRace") then
		if not EventManager:getSingleton():isEvent(self.m_RunningEvent) then
			self.m_RunningEvent = EventManager:getSingleton():openRandomEvent()
			self:addLog(client, "Events", "hat ein Straßenrennen gestartet!")
		else
			client:sendError("Es läuft bereits ein Event!")
		end
	else
		client:sendError(_("Du bist nicht berechtigt ein Straßenrennen zu starten!", client))
	end
end

function SanNews:Event_addBlip(posX, posY, text)
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("Du bist nicht berechtigt Marker zu erstellen!")
		return
	end

	local id = self:getId()
	local color = {companyColors[id].r, companyColors[id].g, companyColors[id].b}
	local blipName = ("San News - %s"):format(text or "Marker")
	local blip = Blip:new("Marker.png", posX, posY, root, 10000, color)
	blip:setDisplayText(blipName, BLIP_CATEGORY.Default)
	table.insert(self.m_Blips, blip)

	self:addLog(client, "Marker", ("hat einen Marker erstellt: %s"):format(blipName))
	--PlayerManager:getSingleton():sendShortMessage("Die San News hat einen Ort auf der Karte markiert!", ("San News - %s"):format(text or "Marker"), color, 15000)
end

function SanNews:Event_deleteBlips()
	if not PermissionsManager:getSingleton():hasPlayerPermissionsTo(client, "company", "addBlip") then
		client:sendError("Du bist nicht berechtigt Marker zu entfernen!")
		return
	end

	for _, blip in pairs(self.m_Blips) do
		blip:delete()
	end
	self.m_Blips = {}

	client:sendInfo("Alle Blips entfernt!")
end

function SanNews:Event_sanNewsMessage(player, cmd, ...)
	if self.m_SanNewsMessageEnabled then
		local argTable = {...}
		local msg = table.concat(argTable, " ")
		StatisticsLogger:getSingleton():addChatLog(player, "sannews", msg, self:getOnlinePlayers())
		self:sendMessage(("#9cff00[SanNews-Nachricht] %s: #FFFFFF%s"):format(player:getName(), msg), 255, 255 ,0, true)
		player:sendMessage(("#9cff00[Msg an Sannews]: #FFFFFF%s"):format(msg), 255, 255 ,0, true)
	else
		player:sendError(_("Die SanNews hat /sannews derzeit deaktiviert!", player))
	end
end

function SanNews:Event_requestNewsAppUnlock(pay)
	if pay then
		local costs = 1000
		if client:getBankMoney() >= costs then
			client:transferBankMoney({self, nil, true}, costs, "San News App", "Company", "App")
			client:sendShortMessage(_("Die Funktion steht dir nun bis zum Server-Neustart zur Verfügung!", client))
			self.m_AppUnlocked[client:getId()] = true
		else
			client:sendError(_("Du hast zu wenig Geld auf deinem Bankkonto! (%s$)", client, costs))
		end
	end
	local minutes = math.ceil(JobManager:getSingleton().m_TimedPulse.m_Timer:getDetails() / 1000 / 60)
	local realTime = getRealTime()
	local changeTime = (realTime.hour*60 + realTime.minute + minutes) % 1440
	local timeFormatted = ("%02d:%02d"):format(changeTime/60, changeTime%60)
	client:triggerEvent("receiveNewsAppUnlock", self.m_AppUnlocked[client:getId()], timeFormatted)
end