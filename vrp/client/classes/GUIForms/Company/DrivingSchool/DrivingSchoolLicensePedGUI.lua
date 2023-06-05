-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/DrivingSchoolLicensePedGUI.lua
-- *  PURPOSE:     DrivingSchoolLicensePedGUI
-- *
-- ****************************************************************************
DrivingSchoolLicensePedGUI = inherit(GUIButtonMenu)
inherit(Singleton, DrivingSchoolLicensePedGUI)

function DrivingSchoolLicensePedGUI:constructor(buyPlayerLicense)
	GUIButtonMenu.constructor(self, "Fahrschule", 300, 380, false, false, localPlayer.position)
	self:addItem(_"Helikopterführerschein", Color.Accent,
		function()
			triggerServerEvent("drivingSchoolBuyLicense", localPlayer, "heli")
			self:delete()
		end
	)
	self:addItem(_"LKW Führerschein", Color.Accent,
		function()
			triggerServerEvent("drivingSchoolBuyLicense", localPlayer, "truck")
			self:delete()
		end
	)
end