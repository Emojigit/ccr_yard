-- ccr_yard/logpanel_panel.lua
-- This should be a LuaATC Panel.

-- List of yards to be observing on.
local YardIDs = {"CcrY-CcF"}

-- Digiline channel receiving the raw log data.
local chn = "logs"

-- Code start
if event.punch then
    local logs = F.YARD.FUNC.DumpLog(YardIDs)
    digiline_send(chn,logs)
end