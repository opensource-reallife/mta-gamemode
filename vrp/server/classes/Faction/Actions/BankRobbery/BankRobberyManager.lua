BankRobberyManager = inherit(Singleton)
BANKROB_VAULT_OPEN_TIME = 3*(60*1000)
--BankRobberyManager:getSingleton().m_Banks["Caligulas"]
function BankRobberyManager:constructor()
	self.m_Banks = {}
	self.m_CurrentBank = false
	self.m_IsBankrobRunning = false
	self.m_CircuitBreakerPlayers = {}

	self.m_Banks["Palomino"] = BankPalomino:new()
	self.m_Banks["LosSantos"] = BankLosSantos:new()
	--self.m_Banks["Caligulas"] = CasinoHeist:new()

	addRemoteEvents{"bankRobberyPcHack", "bankRobberyPcHackStepFailed", "bankRobberyPcDisarm", "bankRobberyPcHackSuccess"}

	self.m_OnStartHack = bind(self.Event_onStartHacking, self)
	self.onHackStepFailed = bind(self.Event_onHackStepFailed, self)
	self.m_OnDisarm = bind(self.Event_onDisarmAlarm, self)
	self.m_OnSuccess = bind(self.Event_onHackSuccessful, self)

	addEventHandler("bankRobberyPcHack", root, self.m_OnStartHack)
	addEventHandler("bankRobberyPcHackStepFailed", root, self.onHackStepFailed)
	addEventHandler("bankRobberyPcDisarm", root,self.m_OnDisarm )
	addEventHandler("bankRobberyPcHackSuccess", root, self.m_OnSuccess)
end

function BankRobberyManager:startRob(bank)
	self.m_IsBankrobRunning = true
	self.m_CurrentBank = bank
end

function BankRobberyManager:stopRob()
	if self.m_CircuitBreakerPlayers then
		for player, bool in pairs(self.m_CircuitBreakerPlayers) do
			if isElement(player) then
				player:triggerEvent("forceCircuitBreakerClose")
				self.m_CircuitBreakerPlayers[player] = nil
				player.m_InCircuitBreak = false
			end
		end
	end
	if self.m_OpenVaulTimer then
		if isTimer(self.m_OpenVaulTimer) then
			killTimer(self.m_OpenVaulTimer)
			if self.m_RobFaction then
				for k, pl in pairs(self.m_CurrentBank:getEvilPeople()) do
					pl:triggerEvent("CountdownStop","Safe offen:")
				end
			end
		end
		self.m_OpenVaulTimer = false
	end
	self.m_IsBankrobRunning = false
	self.m_CurrentBank = false
	ActionsCheck:getSingleton():endAction()
end

function BankRobberyManager:Event_onStartHacking(pc)
	local faction = client:getFaction()
	if faction and (faction:isEvilFaction() or faction:isStateFaction()) and not client:isDead() then
		if self.m_IsBankrobRunning and not self.m_OpenVaulTimer and not self.m_CurrentBank.m_SafeDoor.m_Open then
			self.m_CircuitBreakerPlayers[client] = true
			client.m_InCircuitBreak = true
			triggerClientEvent(client, "startCircuitBreaker", client, "bankRobberyPcHackSuccess", "bankRobberyPcHackStepFailed", pc)
		else
			client:sendError(_("Du kannst das gerade nicht tun!", client))
		end
	end
end

function BankRobberyManager:Event_onDisarmAlarm()
	local faction = client:getFaction()
	if faction and (faction:isEvilFaction() or faction:isStateFaction()) and not client:isDead() then
		if self.m_IsBankrobRunning then
			triggerClientEvent("bankAlarmStop", root)
		else
			client:sendError(_("Du kannst das gerade nicht tun!", client))
		end
	end
end

function BankRobberyManager:Event_onHackStepFailed() --somebody hit the wall
	if client:isDead() then
		client:triggerEvent("forceCircuitBreakerClose")
		client.m_InCircuitBreak = false
		self.m_CircuitBreakerPlayers[client] = nil
	else
		local faction = client:getFaction()
		if not self.m_CurrentBank.m_AlarmTriggered and faction and faction:isEvilFaction() then
			for k, player in pairs(self.m_CurrentBank:getEvilPeople()) do
				player:sendWarning(_("%s war unvorsichtig und hat beim Hacken die Polizei alarmiert!", player, client:getName()))
			end
			self.m_CurrentBank:loadDestinationsAndInformState()
		elseif faction and faction:isStateFaction() then
			for k, player in pairs(self.m_CurrentBank:getEvilPeople()) do
				player:sendWarning(_("%s versucht den Tresor zu verriegeln!", player, client:getName()))
			end
		end
	end
end

function BankRobberyManager:Event_onHackSuccessful() --all three steps
	if client:isDead() then
		client:triggerEvent("forceCircuitBreakerClose")
		client.m_InCircuitBreak = false
		self.m_CircuitBreakerPlayers[client] = nil
	else
		for player, bool in pairs(self.m_CircuitBreakerPlayers) do
			if isElement(player) then
				player:triggerEvent("forceCircuitBreakerClose")
				player.m_InCircuitBreak = false
				self.m_CircuitBreakerPlayers[player] = nil
			end
		end
		self.m_CircuitBreakerPlayers = {}
		local faction = client:getFaction()
		if faction and faction:isEvilFaction() then
			self.m_CurrentBank:loadDestinationsAndInformState()
			local brobFaction = client:getFaction()
			local openTime = self.m_CurrentBank.ms_VaultOpenTime
			for k, player in pairs(self.m_CurrentBank:getEvilPeople()) do
				player:sendSuccess(_("Das Sicherheitssystem wurde von %s geknackt! Die Safetür ist offen", player, client:getName()))
				player:triggerEvent("Countdown", (openTime/1000), "Safe offen:")
			end
			self.m_OpenVaulTimer = setTimer(bind(self.m_CurrentBank.openSafeDoor,self.m_CurrentBank), openTime, 1)
		else
			self.m_CurrentBank:sealSafeDoor()
		end
	end
end