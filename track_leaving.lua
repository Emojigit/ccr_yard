-- ccr_yard/track_leaving.lua
-- This should be the last LuaATC the train executes before leaving the yard.

local YardID = "CcrY-CcF"

if atc_arrow then atc_send("SM") end
