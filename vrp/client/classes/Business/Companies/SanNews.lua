-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Business/Companies/SanNews.lua
-- *  PURPOSE:     SAN News class
-- *
-- ****************************************************************************

SanNews = inherit(Singleton)

function SanNews:constructor()
    self.m_SanNewsAds = {}
    addRemoteEvents{"sanNewsAdsLoadForClient", "sanNewsAdsSound"}
    addEventHandler("sanNewsAdsLoadForClient", root, bind(self.loadAds, self))
    addEventHandler("sanNewsAdsSound", root, bind(self.playAdsSound, self))
end

function SanNews:loadAds(Ads)
    if Ads then
        self.m_SanNewsAds = Ads
    else
        return 
    end
    if SANNewsAdsOverviewGUI:isInstantiated() then
        delete(SANNewsAdsOverviewGUI:getSingleton())
    end
    SANNewsAdsOverviewGUI:new(self.m_SanNewsAds)
end

function SanNews:playAdsSound()
    local snd = playSound ( "files/audio/sannews/adSound.ogg", false )
	setSoundVolume ( snd, 1)
end
