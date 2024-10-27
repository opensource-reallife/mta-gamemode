-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/ZombieSurvivalQuest.lua
-- *  PURPOSE:     Zombie Survival Quest class
-- *
-- ****************************************************************************

ZombieSurvivalQuest = inherit(HalloweenQuest)

function ZombieSurvivalQuest:constructor()
	self.m_ColShape = createColSphere(-34.6, 1377.80, 8.4, 2)
    self.m_ColShapeHitFunc = bind(self.Event_onClientColShapeHit, self)
	addEventHandler("onClientColShapeHit", self.m_ColShape, self.m_ColShapeHitFunc)
end

function ZombieSurvivalQuest:virtual_destructor()
    if isElement(self.m_ColShape) then
        removeEventHandler("onClientColShapeHit", self.m_ColShape, self.m_ColShapeHitFunc)
        self.m_ColShape:destroy()
    end
end

function ZombieSurvivalQuest:startQuest()
    self:createDialog(bind(self.onStart, self), 
        "Oh, hallo! Ich bräuchte jemanden, der mir mit etwas behilflich ist.",
        "Es gibt Gerüchte, dass in Bone County Zombies gesichtet wurden.",
        "Könntest du das für mich mal untersuchen?"
    )
end

function ZombieSurvivalQuest:onStart()
    self.m_QuestMessage = ShortMessage:new(_"Untersuche die Zombie-Sichtungen!", "Halloween: Quest", Color.Orange, -1, false, false, Vector2(-31.64, 1377.67), {{path="Marker.png", pos=Vector2(-31.64, 1377.67)}}, true)
end

function ZombieSurvivalQuest:Event_onClientColShapeHit(hitElement, dim)
    if hitElement == localPlayer and dim then
        if not localPlayer:getOccupiedVehicle() then
            delete(self.m_QuestMessage)

            removeEventHandler("onClientColShapeHit", self.m_ColShape, self.m_ColShapeHitFunc)
            self.m_ColShape:destroy()

            CutscenePlayer:getSingleton():playCutscene("ZombieSurvivalCutscene", function()
                triggerServerEvent("startZombieSurvival", localPlayer)
                fadeCamera(true)
                self.m_QuestMessage = ShortMessage:new(_"Kehre nun zum Friedhof zurück!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
                self:setSucceeded()
            end, nil, true)
        end
    end
end

function ZombieSurvivalQuest:endQuest()
    self:createDialog(false, 
        "Wie? Da verkauft nur ein Irrer eine neue Droge?",
        "Schade, ich hatte auf etwas Spannenderes gehofft...",
        "Naja, wie dem auch sei. Hier, eine kleine Belohnung für deine Arbeit!"
    )
end