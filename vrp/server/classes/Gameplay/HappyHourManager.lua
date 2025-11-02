-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/HappyHourManager.lua
-- *  PURPOSE:     Happy Hour Manager class
-- *
-- ****************************************************************************

HappyHourManager = inherit(Singleton)

function HappyHourManager:constructor()
    GlobalTimer:getSingleton():registerEvent(bind(self.startHappyHour, self), "HappyHourBegin", nil, 12, 00)
    GlobalTimer:getSingleton():registerEvent(bind(self.endHappyHour, self), "HappyHourEnd", nil, 13, 30)

    GlobalTimer:getSingleton():registerEvent(bind(self.startHappyHour, self), "HappyHourBegin", nil, 16, 30)
    GlobalTimer:getSingleton():registerEvent(bind(self.endHappyHour, self), "HappyHourEnd", nil, 18, 00)

	GlobalTimer:getSingleton():registerEvent(bind(self.startHappyHour, self), "HappyHourBegin", nil, 21, 30)
    GlobalTimer:getSingleton():registerEvent(bind(self.endHappyHour, self), "HappyHourEnd", nil, 22, 30)
	
	self.m_isHappyHour = false
    self.m_MinMembers = {
		["MinMembersWeapontruck"] = WEAPONTRUCK_MIN_MEMBERS,
		["MinMembersBankrob"] = BANKROB_MIN_MEMBERS,
		["MinMembersCasinoHeist"] = CASINOHEIST_MIN_MEMBERS,
		["MinMembersWeedtruck"] = WEEDTRUCK_MIN_MEMBERS,
		["MinMembersEvidencetruck"] = EVIDENCETRUCK_MIN_MEMBERS,
		["MinMembersArmsdealer"] = ARMSDEALER_MIN_MEMBERS,
		["MinMembersShoprob"] = SHOPROB_MIN_MEMBERS,
		["MinMembersHouserob"] = HOUSEROB_MIN_MEMBERS,
		["MinMembersJewelry"] = JEWELRY_MIN_MEMBERS,
		["MinMembersPrisonBreak"] = PRISONBREAK_MIN_MEMBERS,
		["MinMembersVehicleShop"] = SHOP_VEHICLE_ROB_MIN_MEMBERS,
		["MinMembersChristmastruck"] = CHRISTMASTRUCK_MIN_MEMBERS,
		["MinMembersFire"] = MIN_PLAYERS_FOR_FIRE,
		["MinMembersVehicleFire"] = MIN_PLAYERS_FOR_VEHICLE_FIRE,
	}
end

function HappyHourManager:startHappyHour()
	self.m_isHappyHour = true
	WEEDTRUCK_MIN_MEMBERS = 0
	EVIDENCETRUCK_MIN_MEMBERS = 0
	SHOPROB_MIN_MEMBERS = math.ceil(self.m_MinMembers["MinMembersShoprob"] / 2)
	HOUSEROB_MIN_MEMBERS = math.ceil(self.m_MinMembers["MinMembersHouserob"] / 2)
	SHOP_VEHICLE_ROB_MIN_MEMBERS = math.ceil(self.m_MinMembers["MinMembersVehicleShop"] / 2)

	--[[ //no changes
	BANKROB_MIN_MEMBERS = 
	WEAPONTRUCK_MIN_MEMBERS = 
	CASINOHEIST_MIN_MEMBERS = 
	ARMSDEALER_MIN_MEMBERS = 
	JEWELRY_MIN_MEMBERS = 
	PRISONBREAK_MIN_MEMBERS = 
	CHRISTMASTRUCK_MIN_MEMBERS = 
	MIN_PLAYERS_FOR_FIRE = 
	MIN_PLAYERS_FOR_VEHICLE_FIRE =
	]]

	for k, player in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
		triggerClientEvent(player, "breakingNews", resourceRoot, _("Die Happy Hour hat begonnen! Die Aktionsstartbedingungen von einigen Aktionen sind nun verringert!", player), "HappyHour", {44, 148, 12}, {0, 0, 0})
	end
end

function HappyHourManager:endHappyHour()
	self.m_isHappyHour = false
	WEAPONTRUCK_MIN_MEMBERS = self.m_MinMembers["MinMembersWeapontruck"]
	BANKROB_MIN_MEMBERS = self.m_MinMembers["MinMembersBankrob"]
	CASINOHEIST_MIN_MEMBERS = self.m_MinMembers["MinMembersCasinoHeist"]
	WEEDTRUCK_MIN_MEMBERS = self.m_MinMembers["MinMembersWeedtruck"]
	EVIDENCETRUCK_MIN_MEMBERS = self.m_MinMembers["MinMembersEvidencetruck"]
	ARMSDEALER_MIN_MEMBERS = self.m_MinMembers["MinMembersArmsdealer"]
	SHOPROB_MIN_MEMBERS = self.m_MinMembers["MinMembersShoprob"]
	HOUSEROB_MIN_MEMBERS = self.m_MinMembers["MinMembersHouserob"]
	JEWELRY_MIN_MEMBERS = self.m_MinMembers["MinMembersJewelry"]
	PRISONBREAK_MIN_MEMBERS = self.m_MinMembers["MinMembersPrisonBreak"]
	SHOP_VEHICLE_ROB_MIN_MEMBERS = self.m_MinMembers["MinMembersVehicleShop"]
	CHRISTMASTRUCK_MIN_MEMBERS = self.m_MinMembers["MinMembersChristmastruck"]

	for k, player in pairs(PlayerManager:getSingleton():getReadyPlayers()) do
		triggerClientEvent(player, "breakingNews", resourceRoot, _("Die Happy Hour ist beendet! Die Aktionsstartbedingungen sind nun zurückgesetzt!", player), "HappyHour", {44, 148, 12}, {0, 0, 0})
	end
end