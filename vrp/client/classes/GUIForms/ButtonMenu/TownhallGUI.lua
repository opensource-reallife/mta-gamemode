-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/GUIForms/ButtonMenu/TownhallGUI.lua
-- *  PURPOSE:     Townhall GUI
-- *
-- ****************************************************************************
TownhallGUI = inherit(GUIButtonMenu)
inherit(Singleton, TownhallGUI)

function TownhallGUI:constructor(rangeElement)
    GUIButtonMenu.constructor(self, _("Stadthalle"), false, false, false, false, rangeElement:getPosition())

    self:addItem(_"Ausweis / Kaufvertrag", Color.Accent, function()
        delete(self)
        triggerServerEvent("shopOpenGUI", localPlayer, 50)
    end)

    self:addItem(_"Jobliste", Color.Accent, function()
        delete(self)
        JobHelpGUI:new()
    end)

    self:addItem(_"Fahrzeuge an-/abmelden", Color.Accent, function()
        delete(self)
        VehicleUnregisterGUI:new(rangeElement)
    end)
    
    self:addItem(_"Gruppen", Color.Accent, function()
        delete(self)
        GroupCreationGUI:new()
    end)

    self:addItem(_"Gruppenimmobilien", Color.Accent, function()
        delete(self)
        if localPlayer:getGroupName() ~= "" then
            GroupPropertyBuy:new()
        else 
            ErrorBox:new(_"Du hast keine Gruppe!")
        end
    end)

    self:addItem(_"Häuser", Color.Accent, function()
        delete(self)
        HousesForSaleGUI:new(rangeElement)
    end)
end