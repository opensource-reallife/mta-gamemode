-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        server/classes/NameManager.lua
-- *  PURPOSE:     Name manager class
-- *
-- ****************************************************************************
NameManager = inherit(Singleton)

function NameManager:constructor()
    self.m_BadNames = {}
    local result = sql:queryFetch("SELECT * FROM ??_bad_names", sql:getPrefix())
    for _, data in pairs(result) do
        table.insert(self.m_BadNames, string.lower(data["Name"]))
    end
end

function NameManager:isNameBlocked(name)
    local foundResults = {}
    local nameLower = string.lower(name)
    for _, v in pairs(self.m_BadNames) do
        local normalName = string.gsub(v, "*", "")
        if string.find(nameLower, normalName) then

            if (string.len(normalName) == string.len(nameLower)) then
                return true
            end
            foundResults[normalName] = v
        end
    end

    for normalName, nameWithStars in pairs(foundResults) do    
        if string.sub(nameWithStars, 1, 1) == "*" then
            local start, end1 = string.find(nameLower, normalName)
            --
            if (start and end1) and start > 1  then
                return true
            end 
        end

        if string.sub(nameWithStars, string.len(nameWithStars), string.len(nameWithStars)) == "*" then
            local start, end1 = string.find(nameLower, normalName)
            local subedString = string.sub(nameLower, - string.len(normalName))
            if subedString ~= normalName then
                return true
            end 
        end
    end
    return false
end