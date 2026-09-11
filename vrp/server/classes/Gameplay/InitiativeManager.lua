-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/InitiativeManager.lua
-- *  PURPOSE:     Initiative manager class
-- *
-- ****************************************************************************

InitiativeManager = inherit(Singleton)
addRemoteEvents{"requestInitiatives", "registerInitiativeVote"}

InitiativeManager.Data = {
	[1] = {
		"Keine Initiative",
		"Kein Effekt."
	},
	[2] = {
		"Festes Jobgehalt",
		"Der Jobmultiplikator wird für alle Jobs auf +50%% gesetzt."
	},
	[3] = {
		"Mehr Grundsicherung",
		"Die Grundsicherung ist verdoppelt, dafür wird die Lohnsteuer 25%% erhöht."
	},
	[4] = {
		"Weniger Lohnsteuer",
		"Die Lohnsteuer ist 25%% reduziert, dafür wird die Grundsteuer verdoppelt."
	},
	[5] = {
		"Mittwochsmarkt",
		"Der Wochenmarkt findet auch Mittwochs statt (nicht während dem Oster- oder Weihnachtsevent)."
	},
	[6] = {
		"Keine Maut",
		"Es muss keine Maut gezahlt werden, dafür sind Blitzer-Strafen doppelt so hoch."
	},
	[7] = {
		"Mehr Punkte (Job)",
		"Bei Jobs erhält man 50%% mehr Punkte, dafür verdient man 25%% weniger."
	},
	[8] = {
		"Happy Hour",
		"Drei mal täglich findet eine Happy Hour statt, bei der die Bedingungen für Aktionen verringert sind."
	},
}

function InitiativeManager:constructor()
	self.m_Initiatives = {}

	local result = sql:queryFetch("SELECT * FROM ??_initiatives", sql:getPrefix())
	for k, row in pairs(result) do
		if InitiativeManager.Data[row.Id] then
			self.m_Initiatives[row.Id] = {toboolean(row.Active), row.Votes and fromJSON(row.Votes) or {}}
		end
	end

	for id, v in pairs(InitiativeManager.Data) do
		if not self.m_Initiatives[id] then
			self.m_Initiatives[id] = {false, {}}
		end
	end

	if getRealTime().weekday == 1 or DEBUG then
		local votes = {}
		local maxVotes = 0
		for id, data in pairs(self.m_Initiatives) do
			votes[id] = table.size(data[2])
			if votes[id] > maxVotes then
				maxVotes = votes[id]
			end
			data[1] = false
			data[2] = {}
		end

		if maxVotes > 0 then
			local winners = {}
			for id, voteCount in pairs(votes) do
				if voteCount == maxVotes then
					table.insert(winners, id)
				end
			end

			local winner = winners[math.random(#winners)]
			self.m_Initiatives[winner][1] = true
		end
	end

	local initiative = self:getActiveInitiative()
	if initiative == 2 then
		JobManager:getSingleton().m_TimedPulse:delete()
		JobManager:getSingleton():refreshJobMultiplicators(50 / 100, true)
	elseif initiative == 5 then
		local weekday = getRealTime().weekday
		if MARKET_POSSIBLE and weekday == 3 then
			Market:new()
		end
	elseif initiative == 6 then
		ItemSpeedCam.COST_FACTOR = ItemSpeedCam.COST_FACTOR * 2
	elseif initiative == 7 then
		JOB_PAY_MULTIPLICATOR = JOB_PAY_MULTIPLICATOR * 0.75
		JOB_EXTRA_POINT_FACTOR = JOB_EXTRA_POINT_FACTOR * 1.5
	elseif initiative == 8 then
		HappyHourManager:new()
	end

	addEventHandler("requestInitiatives", root, bind(self.Event_requestInitiatives, self))
	addEventHandler("registerInitiativeVote", root, bind(self.Event_registerInitiativeVote, self))
end

function InitiativeManager:getActiveInitiative()
	local initiative = 1
	for id, data in pairs(self.m_Initiatives) do
		if data[1] then
			initiative = id
		end
	end

	return initiative
end

function InitiativeManager:Event_requestInitiatives()
	if source ~= client then return end

	local tbl = {}
	for id, data in pairs(self.m_Initiatives) do
		tbl[id] = {
			InitiativeManager.Data[id][1], -- name
			InitiativeManager.Data[id][2], -- description
			data[1], -- active
			table.size(data[2]), -- votes
		}
	end

	triggerClientEvent(client, "receiveInitiatives", client, tbl)
end

function InitiativeManager:Event_registerInitiativeVote(vote)
	if source ~= client then return end

	if client:getInventory():getItemAmount("Ausweis") == 0 then
		return client:sendError(_("Du brauchst einen Ausweis, um für eine Initiative abzustimmen!", client))
	end

	local changed = false
	local name = client:getName()
	for id, data in pairs(self.m_Initiatives) do
		if data[2][name] then
			if id == vote then
				return client:sendError(_("Du hast bereits für diese Initiative abgestimmt!", client))
			else
				changed = true
				data[2][name] = nil
			end
		end
	end

	self.m_Initiatives[vote][2][name] = true

	if changed then
		client:sendSuccess(_("Du hast deine Stimme erfolgreich geändert!", client))
	else
		client:sendSuccess(_("Du hast erfolgreich für diese Initiative abgestimmt!", client))
	end
end

function InitiativeManager:destructor()
	sql:queryExec("DELETE FROM ??_initiatives", sql:getPrefix())
	for id, data in pairs(self.m_Initiatives) do
		sql:queryExec("INSERT INTO ??_initiatives (Id, Active, Votes) VALUES (?, ?, ?)", sql:getPrefix(), id, data[1], data[2] and toJSON(data[2]))
	end
end