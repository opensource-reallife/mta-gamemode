-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/AI/Tasks/TaskGuard.lua
-- *  PURPOSE:     Guard task class
-- *
-- ****************************************************************************
TaskGuard = inherit(Task)

function TaskGuard:constructor(actor)
    self.m_DamageFunc = bind(self.Actor_Damage, self)

    addEventHandler("onClientPedDamage", actor, self.m_DamageFunc)
end

function TaskGuard:getId()
    return Tasks.TASK_GUARD
end

function TaskGuard:Actor_Damage(attacker, weapon, bodypart, loss)
    if attacker and isElement(attacker) and getElementType(attacker) == "player" then
        -- Tell server that we've been damaged
        triggerServerEvent("taskGuardDamage", self.m_Actor, attacker)

        -- Handle meelee manually so ped doesnt fall over
        if weapon and getSlotFromWeapon(weapon) == 0 or getSlotFromWeapon(weapon) == 1 then
            local newHealth = source:getHealth() - loss
            if newHealth > 0 then
                source:setHealth(newHealth)
                cancelEvent()
            end
        end
    else
        cancelEvent()
    end
end
