-- reaper_interactions.lua
-- Handles interactions with REAPER (track selection, project state, etc.)

local r = reaper
local app_state = require("app_state")

local reaper_utils = {}  -- Alternative module name to avoid conflicts

-- Function to get selected track information, including index
function reaper_utils.GetSelectedTrackInfo()
    local num_selected_tracks = r.CountSelectedTracks(0)

    if num_selected_tracks == 1 then
        -- Get track reference & index
        local track = r.GetSelectedTrack(0, 0)
        local track_index = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") -- Track index (1-based)
        local _, track_name = r.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

        -- Return formatted message
        return string.format("Selected Track: [%d] %s", track_index, (track_name ~= "" and track_name or "Unnamed Track"))
    elseif num_selected_tracks > 1 then
        return "Multiple tracks selected. A new track will be created."
    else
        return "No track selected. A new track will be created."
    end
end

-- Function to check if exactly **one** track is selected
function reaper_utils.IsSingleTrackSelected()
    return r.CountSelectedTracks(0) == 1
end

-- Function to open selected projects in the current tab
function reaper_utils.OpenProjectInCurrentTab()
    local selected_names = app_state:GetSelectedProjectsList()
    if not next(selected_names) then
        app_state:LogMessage("No projects selected for opening.")
        return
    end

    for _, name in ipairs(selected_names) do
        local project = app_state:GetAllProjects()[name]  -- Fetch full project object
        if project and project.full_filepath then
            r.Main_openProject(project.full_filepath)  -- Open in current tab
            app_state:LogMessage("Opened project in current tab: " .. name)
        else
            app_state:LogError("Failed to open project: " .. tostring(name) .. " (No valid path found)")
        end
    end
end

-- Function to open selected projects in a **new tab**
function reaper_utils.OpenProjectInNewTab()
    local selected_names = app_state:GetSelectedProjectsList()
    if not next(selected_names) then
        app_state:LogMessage("No projects selected for opening in a new tab.")
        return
    end

    for _, name in ipairs(selected_names) do
        local project = app_state:GetAllProjects()[name]  -- Fetch full project object
        if project and project.full_filepath then
            r.Main_OnCommand(40859, 0)  -- Create new project tab (REAPER action)
            r.Main_openProject(project.full_filepath)  -- Open project in new tab
            app_state:LogMessage("Opened project in new tab: " .. name)
        else
            app_state:LogError("Failed to open project: " .. tostring(name) .. " (No valid path found)")
        end
    end
end

-- Function to import selected projects as **subproject media items**
function reaper_utils.ImportProjectsAsMediaItems()
    local selected_names = app_state:GetSelectedProjectsList()
    if not next(selected_names) then
        app_state:LogMessage("No projects selected for import as subprojects.")
        return
    end

    -- Get active track or create a new one if none is selected
    local track = r.GetSelectedTrack(0, 0)
    if not track then
        r.InsertTrackAtIndex(r.CountTracks(0), true)  -- Create a new track
        track = r.GetTrack(0, r.CountTracks(0) - 1)  -- Get the new track
    end

    -- Insert each selected project as a subproject item
    for _, name in ipairs(selected_names) do
        local project = app_state:GetAllProjects()[name]  -- Fetch full project object
        if project and project.full_filepath then
            -- Create a new media item
            local item = r.AddMediaItemToTrack(track)
            if item then
                -- Assign the .rpp file as a subproject item
                local take = r.AddTakeToMediaItem(item)
                if take then
                    r.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
                    r.GetSetMediaItemTakeInfo_String(take, "P_SOURCE", project.full_filepath, true)
                end

                -- Position the item correctly
                local project_length = project.total_length or 10  -- Default length if unknown
                r.SetMediaItemInfo_Value(item, "D_LENGTH", project_length) -- Set length
                r.SetMediaItemInfo_Value(item, "D_POSITION", r.GetCursorPosition()) -- Position at cursor
                r.UpdateArrange()

                app_state:LogMessage("Imported project as subproject: " .. name)
            else
                app_state:LogError("Failed to create media item for project: " .. tostring(name))
            end
        else
            app_state:LogError("Failed to import project: " .. tostring(name) .. " (No valid path found)")
        end
    end
end

return reaper_utils
