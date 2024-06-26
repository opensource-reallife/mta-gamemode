-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/Gameplay/Minigames/WheelOfFortune.lua
-- *  PURPOSE:     create a wheel of fortune and manage it
-- *
-- ****************************************************************************

WheelOfFortune = inherit(Object)
WheelOfFortune.Map = {}
addRemoteEvents{"WheelOfFortuneClicked"}

function WheelOfFortune:constructor(pos, rz)

    self.m_BankAccountServer = BankServer.get("gameplay.wheelOfFortune")
    self.m_FootObj = createObject(1897, pos, 0, 0, rz)

    local m = self.m_FootObj.matrix
    self.m_CursorObj = createObject(1898, self.m_FootObj.position + m.forward*-0.1 + m.up*1.08, self.m_FootObj.rotation)
    self.m_WheelObj = createObject(1895, self.m_FootObj.position + m.forward*-0.08 + m.up*0.01, self.m_FootObj.rotation)
    self.m_WheelObj:setDoubleSided(true)

    self.m_WheelObj:setData("clickable", true, true)
    addEventHandler("WheelOfFortuneClicked", self.m_WheelObj, bind(WheelOfFortune.onClicked, self))

    self.m_InUse = false
    WheelOfFortune.Map[self.m_FootObj] = self
end


function WheelOfFortune:onClicked()
    --garbage collection
    if self.m_InUse then
        if not isElement(self.m_InUse) or not self.m_InUse.isLoggedIn or not self.m_InUse:isLoggedIn() then
            self.m_InUse = false
        end
    end

    --actual functions
    if not self.m_InUse then
        if not client.m_IsUsingWheel then
            if not client:getInventory():removeItem("Zuckerstange", 1) then
                return client:sendError(_("Du benötigst eine Zuckerstange um am Glücksrad zu drehen!", client))
            end

            self.m_InUse = client
            self:start(client)
        else
            client:sendError(_("Du drehst bereits an einem Glücksrad.", client))
        end
    else
        client:sendWarning(_("Das Glücksrad wird gerade von %s verwendet.", client, self.m_InUse:getName()))
    end
end

function WheelOfFortune:start(player)
    local power = math.random(500, 1000) -- maybe replace it with some kind of power meter like the fishing rod ?
    local x,y,z=getElementPosition(self.m_WheelObj)
    triggerClientEvent(PlayerManager:getSingleton():getReadyPlayers(), "WheelOfFortunePlaySound", resourceRoot, x, y, z, power*10)
    moveObject(self.m_WheelObj, power*5, x, y, z, 0, math.floor(power/24)*24, 0, "OutQuad")
    player.m_IsUsingWheel = true
    setTimer(function(marker)
        getElementRotation(self.m_WheelObj) --MTA bug, muss bleiben
        local _,ry,_= getElementRotation(self.m_WheelObj)
        if ry+15>=360 then
            ry=ry+15-360
        else
            ry=ry+15
        end
        player.m_IsUsingWheel = nil
		self:givePrice(player, WheelOfFortune.WinRotations[math.floor((ry)/24) + 1])
		triggerEvent("onFortuneWheelPlay", player) -- For Quest
        self.m_InUse = false
    end,power*5+1000,1,marker)
end

function WheelOfFortune:givePrice(player, type)
    if type == "Päckchen" then
        player:getInventory():giveItem("Päckchen", 1)
        player:sendSuccess(_("Du hast ein Päckchen gewonnen!", player))
    elseif type == "Gluehwein" then
        player:getInventory():giveItem("Gluehwein", 1)
        player:sendSuccess(_("Du hast eine Tasse Glühwein gewonnen!", player))
    elseif type == "Lebkuchen" then
        player:getInventory():giveItem("Lebkuchen", 1)
        player:sendSuccess(_("Du hast ein paar Lebkuchen gewonnen!", player))
    elseif type == "Punkte" then
        player:givePoints(25)
    elseif type == "500$" then
        self.m_BankAccountServer:transferMoney(player, 500, "Glücksrad-Gewinn", "Gameplay", "WheelOfFortune")
    elseif type == "1000$" then
        self.m_BankAccountServer:transferMoney(player, 1000, "Glücksrad-Gewinn", "Gameplay", "WheelOfFortune")
    elseif type == "2500$" then
        self.m_BankAccountServer:transferMoney(player, 2500, "Glücksrad-Gewinn", "Gameplay", "WheelOfFortune")
    elseif type == "Muetze" then
        player:getInventory():giveItem("Weihnachtsmütze", 1)
        player:sendSuccess(_("Du hast eine Weihnachtsmütze gewonnen! Ho ho ho!", player))
    elseif type == "Weed" then
        player:getInventory():giveItem("Weed", 3)
        player:sendSuccess(_("Du hast 3 Gramm Weed gewonnen!", player))
    end
end

WheelOfFortune.WinRotations = {
    [1]="Päckchen",
    [2]="Punkte",
    [3]="Lebkuchen",
    [4]="Päckchen",
    [5]="Punkte",
    [6]="Muetze",
    [7]="1000$",
    [8]="Punkte",
    [9]="Päckchen",
    [10]="500$",
    [11]="Punkte",
    [12]="Weed",
    [13]="Gluehwein",
    [14]="Päckchen",
    [15]="2500$",
}
