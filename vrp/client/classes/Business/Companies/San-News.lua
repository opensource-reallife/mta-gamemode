-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Business/Companies/San-News.lua
-- *  PURPOSE:     SAN News class
-- *
-- ****************************************************************************

SanNews = inherit(Singleton)

function SanNews:constructor()
    self.m_sanNewsAds = {}
    addRemoteEvents{"sanNewsAdsLoadForClient", "sanNewsAdsSound"}
    addEventHandler("sanNewsAdsLoadForClient", root, bind(self.loadAds, self))
    addEventHandler("sanNewsAdsSound", root, bind(self.playAdsSound, self))
end

function SanNews:loadAds(theAds)
    if theAds then
        self.m_sanNewsAds = theAds
    else
        return 
    end
    if SANNewsAdsOverviewGUI:isInstantiated() then
        delete(SANNewsAdsOverviewGUI:getSingleton())
    end
    SANNewsAdsOverviewGUI:new(self.m_sanNewsAds)
end

function SanNews:playAdsSound()
    local snd = playSound ( "files/audio/sannews/adSound.ogg", false )
	setSoundVolume ( snd, 1)
end
