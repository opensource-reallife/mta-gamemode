-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/ServerSettings.lua
-- *  PURPOSE:     ServerSettings from Database
-- *
-- ****************************************************************************
ServerSettings = inherit(Singleton)

function ServerSettings:constructor()
	self.m_Settings = {}

	local result = sql:queryFetch("SELECT * FROM ??_settings", sql:getPrefix())
	for index, row in pairs(result) do
		if row.Index == "ServerPassword" then
			if (row.Value) then
				setServerPassword(row.Value)
			else
				setServerPassword()
			end
		end

		if row.Index == "FPSLimit" then
			setFPSLimit(tonumber(row.Value) or 65)
		end

		if row.Index == "ServiceSync" then
			SERVICE_SYNC = toboolean(row.Value)
		end

		if row.Index == "JobPayMultiplicator" then
			JOB_PAY_MULTIPLICATOR = tonumber(row.Value)
		end

		if row.Index == "JobExtraPointFactor" then
			JOB_EXTRA_POINT_FACTOR = tonumber(row.Value)
		end

		if row.Index == "ForumLogin" then
			FORUM_LOGIN = toboolean(row.Value)
		end

		if row.Index == "MinMemberWeapontruck" then
			WEAPONTRUCK_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberBankrob" then
			BANKROB_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberCasinoHeist" then
			CASINOHEIST_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberWeedtruck" then
			WEEDTRUCK_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberEvidencetruck" then
			EVIDENCETRUCK_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberArmsdealer" then
			ARMSDEALER_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberShoprob" then
			SHOPROB_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberHouserob" then
			HOUSEROB_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberJewelry" then
			JEWELRY_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberPrisonBreak" then
			PRISONBREAK_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberVehicleShop" then
			SHOP_VEHICLE_ROB_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberChristmastruck" then
			CHRISTMASTRUCK_MIN_MEMBERS = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberFire" then
			MIN_PLAYERS_FOR_FIRE = DEBUG and 0 or tonumber(row.Value)
		end

		if row.Index == "MinMemberVehicleFire" then
			MIN_PLAYERS_FOR_VEHICLE_FIRE = DEBUG and 0 or tonumber(row.Value)
		end

		self.m_Settings[row.Index] = row.Value
	end
end
