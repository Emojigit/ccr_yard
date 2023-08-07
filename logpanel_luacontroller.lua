-- ccr_yard/logpanel_luacontroller.lua
-- This should be a normal Mesecons Luacontroller.

-- The same as ccr_yard/logpanel_panel.lua.
local chn = "logs"

-- Textling channels
local disp_upper = "disp1"
local disp_lower = "disp2"

-- Buttons mapping
local btns = {
    prev = "C",
    next = "A",
    showdebug = "B"
}

local function updatescreen()
    local lines = {}
    local curr_id = mem.list_yards[mem.curr_yard]
    if curr_id then
        table.insert(lines,string.format("Y: %s  D: %s",curr_id,mem.showdebug and "T" or "F"))
        local log_table = mem.logs[curr_id]
        for i = #log_table, 1, -1 do
            if mem.showdebug or log_table[i][1] ~= "DEBUG" then
                table.insert(lines,string.format("%s %s",log_table[i][1],log_table[i][2]))
            end
            if #lines >= 7 then break end
        end
        while #lines < 7 do
            table.insert(lines,".")
        end
        table.insert(lines,"Prev      DEBUG      Next")
        digiline_send(disp_upper,
            lines[1] .. "\n" ..
            lines[2] .. "\n" ..
            lines[3] .. "\n" ..
            lines[4] .. "\n"
        )
        digiline_send(disp_lower,
            lines[5] .. "\n" ..
            lines[6] .. "\n" ..
            lines[7] .. "\n" ..
            lines[8] .. "\n"
        )
    else
        digiline_send(disp_upper,"ERR: No yard")
        digiline_send(disp_lower,".")
    end
    
end

if event.type == "program" then
    -- Init cache
    mem.logs = {}
    mem.list_yards = {}
    mem.curr_yard = 1
    updatescreen()
elseif event.channel == chn then
    mem.logs = event.msg
    mem.list_yards = {}
    for k,_ in pairs(mem.logs) do
        table.insert(mem.list_yards,k)
    end
    mem.curr_yard = 1
    mem.showdebug = false
    updatescreen()
elseif event.type == "on" then
    if event.pin.name == btns.prev then
        mem.curr_yard = mem.curr_yard - 1
        if mem.curr_yard <= 0 then
            mem.curr_yard = #mem.list_yards
        end
    elseif event.pin.name == btns.next then
        mem.curr_yard = mem.curr_yard + 1
        if mem.curr_yard > #mem.list_yards then
            mem.curr_yard = 1
        end
    elseif event.pin.name == btns.showdebug then
        mem.showdebug = not mem.showdebug
    end
    updatescreen()
end