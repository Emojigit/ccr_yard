-- ccr_yard/panel_mesecon_luacon.lua
-- This should be a mesecon lua controller.

local YardID = "CcrY-CcF"
local TrackID = "1"
local MeseconPort = "b"

if event.type == "digiline" and event.channel == (YardID .. "PanelMeseconControllers") then
    local occupancy = event.msg[TrackID]
    if occupancy == nil then occupancy = false end
    port[MeseconPort] = occupancy
end
