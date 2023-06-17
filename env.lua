-- ccr_yard/env.lua

-- From original env. Should not be copied.
F.has_rc = function(query,rc_list) -- query = string, single entry
  for word in rc_list:gmatch("[^%s]+") do
    if word == query then return true end
  end
  return false
end
F.get_rc_safe = function() return get_rc() or "" end

-- Copy the following codes to the environment.
-- Yard code START --
F.YARD = {}
F.YARD.YARDDATA = {}

F.YARD.LOG = function(YardID,component,msg)
    print(string.format("[%s %s]: %s",
        YardID, component, msg
    ))
end

local YARD_DEBUG = false
if YARD_DEBUG then
    F.YARD.DEBUG = function(YardID,msg)
        F.YARD.LOG(YardID, "DEBUG", msg)
    end
else
    F.YARD.DEBUG = function() end
end

-- Key: track ID in str; val: section ID
-- `search_order` and `panel_pos` can never be a track ID.
F.YARD.YARDDATA["CcrY-CcF"] = {
    ["1"] = 897872,
    ["2"] = 689011,
    ["3"] = 352623,
    ["4"] = 611669,
    ["5"] = 575120,
    search_order = {"1","2","3","4","5"}, -- Order of searching
    panel_pos = POS(-27,9,14),
}

F.YARD.FUNC = {}

F.YARD.FUNC.EntrySig = function(YardID)
    if not event.train then return end -- Only work on train events
    if not atc_arrow then return end -- Only work on trains running in correct direction
    if not atc_id then return end -- Do not action if no trains
    local rc = F.get_rc_safe()
    local YardData = F.YARD.YARDDATA[YardID]
    if not (YardData and YardData.search_order) then return end -- do not work on not existing yard

    F.YARD.DEBUG(YardID,"Train " .. atc_id .. " (RC:" .. rc .. ") arrived the yard.")

    local shunt = F.has_rc("CcrOpt-AllowShunt",rc)

    local track = nil
    for _,id in ipairs(YardData.search_order) do
        if F.has_rc(YardID .. "-T" .. id,rc) then
            -- Force the train to be in that track
            F.YARD.DEBUG(YardID,"Found RC to track: " .. id)
            track = id
            break
        end
    end
    if not (track or shunt) then -- Do not assign tracks to trains if they allowed shunting
        for _,id in ipairs(YardData.search_order) do
            local section = YardData[id]
            local occupancy = section_occupancy(section)
            if not (occupancy and (#occupancy ~= 0)) then
                F.YARD.DEBUG(YardID,"Assigned empty track:" .. id)
                track = id
                break
            end
        end
    end

    if not track then
        F.YARD.LOG(YardID, "EntrySig",
            string.format("Cannot assign any tracks to train %d (RC: %s). Please visit the yard to solve the problem.",
                atc_id, rc
        ))
        return
    end

    local route_name = "T" .. track
    if shunt then
        route_name = route_name .. "-SHUNT"
    end
    F.YARD.DEBUG(YardID,"Route set to " .. route_name)

    local EntrySig_id = YardID .. "-EntrySig"
    set_route(EntrySig_id, route_name)
    atc_send("B6")
end

F.YARD.FUNC.UpdatePanel = function(YardID)
    local YardData = F.YARD.YARDDATA[YardID]
    if not (YardData and YardData.panel_pos) then return end -- do not work on not existing yard
    interrupt_pos(YardData.panel_pos,"update")
end

F.YARD.FUNC.PanelController = function(YardID)
    if event.ext_int then
        if event.message == "update" then
            local YardData = F.YARD.YARDDATA[YardID]
            if not (YardData and YardData.search_order) then return end -- do not work on not existing yard
            local dgl_send_table = {}
            for _,id in ipairs(YardData.search_order) do
                local section = YardData[id]
                local occupancy = section_occupancy(section)
                dgl_send_table[id] = (occupancy and (#occupancy ~= 0))
            end
            digiline_send(YardID .. "PanelMeseconControllers",dgl_send_table)
        end
    end
end

F.YARD.FUNC.StartingTrack = function(YardID, TrackID)
    if not atc_id then return end
    local rc = F.get_rc_safe()
    if atc_arrow then
        local StartingTrackSig_id = YardID .. "-T" .. TrackID
        set_route(StartingTrackSig_id, "C")
        atc_send("A1 SM")
    else
        F.YARD.FUNC.UpdatePanel(YardID)
        local cmd_sent = false
        if F.has_rc("CcrOpt-YardAutoCpl",rc) then
            local YardData = F.YARD.YARDDATA[YardID]

            if YardData and YardData.search_order then -- do not work on not existing yard
                local section = YardData[TrackID]
                local occupancy = section_occupancy(section)
                for _,train_id in ipairs(occupancy or {}) do
                    if train_id ~= atc_id then
                        -- Another train exists on the track. Allow coupling.
                        cmd_sent = true
                        atc_send("B3 Cpl BB")
                        break
                    end
                    if not cmd_sent then
                        F.YARD.LOG(YardID, "StartingTrack-" .. TrackID,
                            string.format("Train %d (RC: %s) have CcrOpt-YardAutoCpl set but no other trains on track. Ignored.",
                                atc_id, rc
                            )
                        )
                    end
                end
            end
        end
        if not cmd_sent then -- Fallback
            atc_send("B3")
        end
    end
end
-- Yard code END --
