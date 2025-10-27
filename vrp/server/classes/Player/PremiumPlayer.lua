-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Player/Premium.lua
-- *  PURPOSE:     Premium class
-- *
-- ****************************************************************************
PremiumPlayer = inherit(Object)

function PremiumPlayer:constructor(player)
	self.m_Player = player
	self.m_Premium = false
	self.m_PremiumEvent = 0

	self:refresh()
end

function PremiumPlayer:refresh()
	local row = sqlPremium:queryFetchSingle("SELECT * FROM user WHERE UserId = ?", self.m_Player:getId())
	if row then
		self.m_PremiumUntil = row.premium_bis
		self.m_PremiumEvent = row.premium_easter
		if row.premium_bis == -1 then --permanent
			self.m_Premium = true
			self.m_PremiumUntil = -1
		end
	else
		self.m_PremiumUntil = 0
	end
	local freeVIP = self.m_Player:getRank() >= ADMIN_RANK_PERMISSION["freeVip"]
	if self.m_PremiumUntil > getRealTime().timestamp or freeVIP or self.m_PremiumUntil == -1 then
		self.m_Premium = true
		self.m_Player:setPublicSync("DeathTime", DEATH_TIME_PREMIUM)
		if freeVIP then
			setTimer(function()
				self.m_Player:sendShortMessage(_("Du erhälst kostenlos Premium aufgrund deiner Stellung im Team.", self.m_Player), "Premium", {50, 200, 255})
			end, 1500, 1)
		elseif self.m_PremiumUntil == -1 then
			setTimer(function()
				self.m_Player:sendShortMessage(_("Dein Premiumaccount ist dauerhaft gültig.", self.m_Player), "Premium", {50, 200, 255})
			end, 1500, 1)
		else
			setTimer(function()
				self.m_Player:sendShortMessage(_("Dein Premiumaccount ist gültig\nbis: %s", self.m_Player, getOpticalTimestamp(self.m_PremiumUntil)), "Premium", {50, 200, 255})
			end, 1500, 1)
		end
	end

	self.m_Player:setPublicSync("Premium", self.m_Premium)
end

function PremiumPlayer:isPremium()
	return self.m_Premium
end

function PremiumPlayer:openVehicleList()
	local row = sqlPremium:queryFetch("SELECT * FROM premium_veh WHERE UserId = ? AND abgeholt = 0", self.m_Player:getId())
	local vehicles = {}
	if row and #row > 0 then
		for i, v in ipairs(row) do
			vehicles[v.ID] = v.Model
		end
		client:triggerEvent("vehicleTakeMarkerGUI", vehicles, "premiumTakeVehicle", "abholen")
	else
		self.m_Player:sendError(_("Keine Fahrzeuge zum Abholen bereit!", self.m_Player))
	end
end

function PremiumPlayer:takeVehicle(model)
	local row = sqlPremium:queryFetchSingle("SELECT * FROM premium_veh WHERE UserId = ? AND Model = ? AND abgeholt = 0", self.m_Player:getId(), model)
	if row and row.ID then
		--if self.m_Player:getVehicleCountWithoutPrem() < self.m_Player:getMaxVehicles() then
			sqlPremium:queryExec("UPDATE premium_veh SET abgeholt = 1, Timestamp_abgeholt = ? WHERE ID = ?;", getRealTime().timestamp, row.ID)
			local vehicle = VehicleManager:getSingleton():createNewVehicle(self.m_Player, VehicleTypes.Player, model, 1268.63, -2069.85, 59.49, 0, 0, 0, 1)
			if vehicle then
				warpPedIntoVehicle(self.m_Player, vehicle)
				self.m_Player:triggerEvent("vehicleBought")
				if row.Soundvan == 1 then
					vehicle.m_Tunings:saveTuning("Special", VehicleSpecial.Soundvan)
					vehicle.m_Tunings:applyTuning()
				end
			else
				self.m_Player:sendMessage(_("Fehler beim Erstellen des Fahrzeugs. Bitte benachrichtige einen Admin!", self.m_Player), 255, 0, 0)
			end
		--else
		--	self.m_Player:sendError(_("Maximaler Fahrzeug-Slot erreicht!", self.m_Player))
		--end
	else
		self.m_Player:sendError(_("Ungültiges Fahrzeug!", self.m_Player))
	end
end

function PremiumPlayer:giveEventMonth()
	local seconds = 30*24*60*60

	if self:isPremium() then
		self.m_PremiumUntil = self.m_PremiumUntil + seconds
	else
		self.m_PremiumUntil = getRealTime().timestamp + seconds
	end

	if sqlPremium:queryFetchSingle("SELECT UserId FROM user WHERE UserId = ?", self.m_Player:getId()) == nil then
		sqlPremium:queryFetch("INSERT INTO user (game_id, UserId, Name, premium_easter, premium, premium_bis) VALUES (?, ?, ?, 0, 0, 0); ", self.m_Player:getId(), self.m_Player:getId(), self.m_Player:getName())
	end

	local row = sqlPremium:queryFetchSingle("SELECT premium_bis FROM user WHERE UserId = ?", self.m_Player:getId())
	if row and row.premium_bis == -1 then
		return
	end

	sqlPremium:queryExec("UPDATE user SET Name = ?, premium_easter = ?, premium_bis = ?, premium = 1 WHERE UserId = ?;", self.m_Player:getName(), self.m_PremiumEvent+1, self.m_PremiumUntil, self.m_Player:getId())
	self:refresh()
end