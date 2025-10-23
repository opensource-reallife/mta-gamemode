-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Events/Halloween/Quests/BigSmokeQuest.lua
-- *  PURPOSE:     Ghost Finder Quest class
-- *
-- ****************************************************************************

BigSmokeQuest = inherit(HalloweenQuest)

function BigSmokeQuest:constructor()
    self.m_Ghost = HalloweenGhost:new(Vector3(368.68, -6.34, 1001.85), 0, 9, 4, false, false)
    self.m_Ghost:setHealth(0) -- makes ghost basically invincible
    self.m_ColShape = createColRectangle(363.74, -8.95, 10, 10)
    addEventHandler("onClientColShapeHit", self.m_ColShape, bind(self.onClientColShapeHit, self))
end

function BigSmokeQuest:virtual_destructor()
    if self.m_Ghost then
        delete(self.m_Ghost)
    end
end

function BigSmokeQuest:startQuest()
    self:createDialog(bind(self.onStart, self),
        "Du kommst wie gerufen!",
        "Ich habe Informationen zu einem Geist in Willowfield!",
        "Nimm den Geistvertreiber und vertreibe ihn!"
    )
end

function BigSmokeQuest:onStart()
    triggerServerEvent("Halloween:giveGhostCleaner", localPlayer)
    self.m_QuestMessage = ShortMessage:new("Vertreibe den Geist im Cluckin Bell Willowfield!", "Halloween: Quest", Color.Orange, -1, false, false, Vector2(2397.83, -1898.65), {{path="Marker.png", pos=Vector2(2397.83, -1898.65)}}, true)
end

function BigSmokeQuest:onClientColShapeHit(hitElement)
    if hitElement == localPlayer then
        if hitElement:getDimension() == 4 then
            toggleAllControls(false)
            self:createDialog(bind(self.removeDisguise, self), 
                "Ich wusste, dass du kommen wirst.",
                "Du wirst uns nicht an unserem Plan hindern."
            )
            self.m_ColShape:destroy()
        end
    end
end

function BigSmokeQuest:removeDisguise()
    fadeCamera(false, 0.1)
    setTimer(
        function()
            self.m_Ghost.m_Ped:setModel(311)
            self.m_Ghost.m_Ped:setAlpha(150)
        end
    , 200, 1)
    setTimer(
        function()
            fadeCamera(true, 0.1)
        end
    , 600, 1)
    setTimer(
        function()
            self:createDialog(bind(self.moveGhost, self), 
                "Wenn Du mich nun entschuldigen würdest, Ich muss los."
            )
        end
    , 700, 1)
end

function BigSmokeQuest:moveGhost()
    self.m_Ghost.m_MoveObject:move(4000, 368.68, -6.34, 1010)
    
    toggleAllControls(true)
    delete(self.m_QuestMessage)
    self.m_QuestMessage = ShortMessage:new("Kehre nun zum Friedhof zurück!", "Halloween: Quest", Color.Orange, -1, false, false, false, false, true)
    self:setSucceeded()
end

function BigSmokeQuest:endQuest()
    self:createDialog(false, 
        "Der Geist hat von einem Plan gesprochen und ist anschließend geflohen?",
        "Merkwürdig...",
        "Dennoch, eine Belohnung für deine Arbeit!"
    )
end