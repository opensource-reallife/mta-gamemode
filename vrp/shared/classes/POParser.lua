-- ****************************************************************************
-- *
-- *  PROJECT:     	vRoleplay
-- *  FILE:        	shared/classes/POParser.lua
-- *  PURPOSE:     	Gettext .po parser
-- *
-- ****************************************************************************
POParser = inherit(Object)

function POParser:constructor(poPath)
    self.m_Strings = {}

    local file = fileOpen(poPath)
    if not file then
        outputDebug("File could not be opened: " .. poPath)
        return false
    end

    local fileContent = fileRead(file, fileGetSize(file))

    for msgid, msgstr in fileContent:gmatch('msgid "(.-)"%s+msgstr "(.-)"') do
        msgid = msgid:gsub("\\n", "\n")
        msgstr = msgstr:gsub("\\n", "\n")

        self.m_Strings[msgid] = msgstr
    end

    fileClose(file)
end

function POParser:translate(str)
	return self.m_Strings[str]
end
