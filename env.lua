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
F.YARD.LOGS = {}
F.YARD.LOGS_KEEP = 10

F.YARD.LOG = function(YardID,component,msg)
    if not F.YARD.LOGS[YardID] then F.YARD.LOGS[YardID] = {} end
    table.insert(F.YARD.LOGS[YardID],{component,msg})
    if #F.YARD.LOGS[YardID] > F.YARD.LOGS_KEEP then
        repeat
            table.remove(F.YARD.LOGS[YardID],1)
        until #F.YARD.LOGS[YardID] <= F.YARD.LOGS_KEEP
    end
end

F.YARD.DEBUG = function(YardID,msg)
    F.YARD.LOG(YardID, "DEBUG", msg)
end

-- Key: track ID in str; val: section ID
-- `search_order` and `panel_pos` can never be a track ID.

-- Data of testing environment
-- F.YARD.YARDDATA["CcrY-CcF"] = {
--     ["1"] = 897872,
--     ["2"] = 689011,
--     ["3"] = 352623,
--     ["4"] = 611669,
--     ["5"] = 575120,
--     search_order = {"1","2","3","4","5"}, -- Order of searching
--     panel_pos = POS(-27,9,14),
-- }

-- Data of real environment on LinuxForks (CcrY-CcF)
F.YARD.YARDDATA["CcrY-CcF"] = {
    ["1.1"]  = 244528,
    ["1.2"]  = 204861,
    ["1.3"]  = 430094,
    ["1.4"]  = 751434,
    ["1.5"]  = 418639,
    ["1.6"]  = 299596,
    ["1.7"]  = 588770,
    ["1.8"]  = 742722,
    ["1.9"]  = 528108,
    ["1.10"] = 535580,
    ["1.11"] = 722617,

    ["2.1"]  = 730975,
    ["2.2"]  = 832228,
    ["2.3"]  = 982226,
    ["2.4"]  = 188741,
    ["2.5"]  = 461947,
    ["2.6"]  = 501657,
    ["2.7"]  = 849251,
    ["2.8"]  = 639872,
    ["2.9"]  = 383000,
    ["2.10"] = 263266,

    search_order = {
        "1.1","1.2","1.3","1.4","1.5","1.6","1.7","1.8","1.9","1.10","1.11",
        "2.1","2.2","2.3","2.4","2.5","2.6","2.7","2.8","2.9","2.10"
    },
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
            track = id
            break
        end
    end
    if not (track or shunt) then -- Do not assign tracks to trains if they allowed shunting
        for _,id in ipairs(YardData.search_order) do
            local section = YardData[id]
            local occupancy = section_occupancy(section)
            if not (occupancy and (#occupancy ~= 0)) then
                track = id
                break
            end
        end
    end

    if track then
        F.YARD.LOG(YardID,"Entry",string.format("%d -> %d",atc_id,track))
    else
        F.YARD.LOG(YardID, "Entry",
            string.format("%d assign failed",
                atc_id
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

F.YARD.FUNC.StartingTrack = function(YardID, TrackID)
    if not atc_id then return end
    local rc = F.get_rc_safe()
    if atc_arrow then
        local StartingTrackSig_id = YardID .. "-T" .. TrackID
        set_route(StartingTrackSig_id, "C")
        atc_send("A1 SM")
    else
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
                        F.YARD.LOG(YardID, "Start" .. TrackID,
                            string.format("%d Cpl: no others",
                                atc_id
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

F.YARD.FUNC.DumpLog = function(YardIDs) -- YardIDs: table of Yards to be viewed
    local RTN = {}
    for _,k in ipairs(YardIDs) do
        RTN[k] = F.YARD.LOGS[k] or {}
    end
    return RTN
end
-- Yard code END --
