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

	local result = sql:queryFetch("SELECT `Index`, `Value` FROM ??_settings", sql:getPrefix())
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

		if row.Index == "MinMembersWeapontruck" then
			WEAPONTRUCK_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersBankrob" then
			BANKROB_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersCasinoHeist" then
			CASINOHEIST_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersWeedtruck" then
			WEEDTRUCK_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersEvidencetruck" then
			EVIDENCETRUCK_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersArmsdealer" then
			ARMSDEALER_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersShoprob" then
			SHOPROB_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersHouserob" then
			HOUSEROB_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersJewelry" then
			JEWELRY_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersPrisonBreak" then
			PRISONBREAK_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersVehicleShop" then
			SHOP_VEHICLE_ROB_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersChristmastruck" then
			CHRISTMASTRUCK_MIN_MEMBERS = tonumber(row.Value)
		end

		if row.Index == "MinMembersFire" then
			MIN_PLAYERS_FOR_FIRE = tonumber(row.Value)
		end

		if row.Index == "MinMembersVehicleFire" then
			MIN_PLAYERS_FOR_VEHICLE_FIRE = tonumber(row.Value)
		end

		if row.Index == "MinMembersSAR" then
			SAR_MIN_PLAYERS = tonumber(row.Value)
		end

		if row.Index == "MinTimeSAR" then
			SAR_TIME_MIN = tonumber(row.Value)
		end

		if row.Index == "MaxTimeSAR" then
			SAR_TIME_MAX = tonumber(row.Value)
		end

		if row.Index == "MinFireTime" then
			FIRE_TIME_MIN = tonumber(row.Value)
		end

		if row.Index == "MaxFireTime" then
			FIRE_TIME_MAX = tonumber(row.Value)
		end

		if row.Index == "FireRandomChance" then
			FIRE_RANDOM_CHANCE = tonumber(row.Value)
		end

		if row.Index == "RouletteRerollChance" then
			ROULETTE_REROLL_CHANCE = tonumber(row.Value)
		end

		if row.Index == "JobMultRefreshTime" then
			JOBMULT_REFRESH_TIME = tonumber(row.Value)
		end

		if row.Index == "MaxMoneyPerPlayerFromSplit" then
			MAX_MONEY_PER_PLAYER_FROM_SPLIT = tonumber(row.Value)
		end

		if row.Index == "VehicleImportPayFactor" then
			VEHICLE_IMPORT_PAY_FACTOR = tonumber(row.Value)
		end

		if row.Index == "VehicleImportPayMaximum" then
			VEHICLE_IMPORT_PAY_MAXIMUM = tonumber(row.Value)
		end

		if row.Index == "VehicleImportPayFactorDriver" then
			VEHICLE_IMPORT_PAY_FACTOR_DRIVER = tonumber(row.Value)
		end

		if row.Index == "RegistrationActivated" then
			Account.REGISTRATION_ACTIVATED = toboolean(row.Value)
		end

		self.m_Settings[row.Index] = row.Value
	end
end