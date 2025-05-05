-- app_state.lua
-- Centralized state for the application with getters/setters and compute method

local json = require("dkjson") -- Include JSON library
local ProjectInfo = require("project_info") -- Import project metadata class

local app_state = {
    dir_path = "",           -- Directory path for projects
    all_projects = {},       -- Full list of detected projects
    available_projects = {}, -- Available projects (filtered dynamically)
    selected_order = {},      -- Keeps track of the arrangement order List: { "Project1", "Project2" }
    append_projects = false,  -- Flag to append projects instead of overwriting
    search_query = "",       -- Search query for filtering
    import_mode = 0,         -- 0: Single Track, 1: Multiple Tracks Sequential, 2: Multiple Tracks Overlapping
    bar_gap = 2,             -- Bar gap for placement
    busy = false,            -- Busy indicator
    LOG_ENABLED = true,      -- Global debug logging flag (set to false to disable logs)
    state_changed = false    -- Tracks if the state has changed
}

-- Function to log messages only when logging is enabled
function app_state:LogMessage(message)
    if app_state.LOG_ENABLED then
        reaper.ShowConsoleMsg("[DEBUG] " .. message .. "\n")
    end
end

-- Function to log error messages (ALWAYS prints, even if logging is off)
function app_state:LogError(error_message)
    reaper.ShowConsoleMsg("[ERROR] " .. error_message .. "\n")
end

-- Dynamic properties with key-value pairs
function app_state:Set(key, value)
    self[key] = value
end

function app_state:Get(key)
    return self[key]
end

-- TODO: we should add a remove method that removes a dynamic property

-- ===========================
--  Simple getters and setters

function app_state:GetDirPath()
    return self.dir_path
end

function app_state:SetDirPath(path)
    self.dir_path = path
    self.state_changed = true
end

function app_state:GetSearchQuery()
    return self.search_query
end

function app_state:SetSearchQuery(query)
    self.search_query = query
    self.state_changed = true
end

function app_state:GetBusy()
    return self.busy
end

function app_state:SetBusy(is_busy)
    self.busy = is_busy
    self.state_changed = true
end

function app_state:GetImportMode()
    return self.import_mode
end

function app_state:SetImportMode(mode)
    self.import_mode = mode
    self.state_changed = true
end

function app_state:GetBarGap()
    return self.bar_gap
end

function app_state:SetBarGap(gap)
    self.bar_gap = gap
    self.state_changed = true
end

function app_state:GetAppendProjects()
    return self.append_projects
end

function app_state:SetAppendProjects(append_ON)
    self.append_projects = append_ON
    self.state_changed = true
end

function app_state:GetSelectedProjectsList()
    return self.selected_order
end

-- Getter for change flag
function app_state:HasStateChanged()
    return self.state_changed
end

-- Reset change flag and store it
function app_state:ResetStateChanged()
    self.state_changed = false
    self:SaveStateChangedFlag()
end

-- ==================================
-- Getters/Setters for complex tables

function app_state:GetAllProjects()
    return self.all_projects
end

function app_state:SetAllProjects(projects)
    if self.append_projects then
        -- The append method will perform it's own checks. 
        -- This is done because it might be used separately.
        self:AppendToAllProjects(projects)
    else        
        if type(projects) ~= "table" then
            self:LogError("SetAllProjects received an invalid format! Expected a table.")
            return
        end

        -- Validate all projects before assigning
        for name, project in pairs(projects) do
            if not ProjectInfo.Validate(project) then
                self:LogError("Invalid project format detected for: " .. tostring(name))
                return  -- Exit early if any project is invalid
            end
        end

        self.all_projects = projects
        self:LogMessage("Overwritten projects with a new structured list.")
    end

    self.state_changed = true
end

function app_state:AppendToAllProjects(projects)
    if type(projects) ~= "table" then
        self:LogError("AppendToAllProjects received an invalid format! Expected a table.")
        return
    end

    for name, project in pairs(projects) do
        if not ProjectInfo.Validate(project) then
            self:LogError("Invalid project format detected while appending: " .. tostring(name))
            return  -- Stop appending if an invalid entry is found
        end

        if self.all_projects[name] then
            if self.all_projects[name].full_filepath == project.full_filepath then
                -- Same name and path: ignore (already exists)
                self:LogMessage("Duplicate project (same path): " .. name)
            else
                -- Same name, different path: add alternative version
                local count = 2
                local alt_name = name .. " (alt " .. count .. ")"
                while self.all_projects[alt_name] do
                    if self.all_projects[alt_name].full_filepath == project.full_filepath then
                        -- Already added this alternative path
                        break
                    end
                    count = count + 1
                    alt_name = name .. " (alt " .. count .. ")"
                end
                self.all_projects[alt_name] = project
                self:LogMessage("Added alternative project: " .. alt_name)
            end
        else
            -- New project, just add it
            self.all_projects[name] = project
        end
    end
    self:LogMessage("Appended new projects with duplicate handling.")
    self.state_changed = true
end

function app_state:GetTotalProjectCount()
    local count = 0
    for _ in pairs(self.all_projects) do count = count + 1 end
    return count
end

-- Getter for available_projects (dependent variable)
function app_state:GetAvailableProjects()
    return self.available_projects
end

-- Compute available projects based on selected projects and search query
function app_state:ComputeAvailableProjects()
    local tokens = {}
    -- Tokenize search query (split by space, case-insensitive, supports Unicode)
    for token in self.search_query:lower():gmatch("%S+") do
        table.insert(tokens, token)
    end

    -- Create a fast lookup set for selected projects
    local selected_set = {}
    for _, name in ipairs(self.selected_order) do
        selected_set[name] = true
    end

    local available_projects = {}
    for name, _ in pairs(self.all_projects) do
        local lower_name = name:lower()
        local matches_all = true

        -- Check if all tokens exist in the project name
        for _, token in ipairs(tokens) do
            if not lower_name:find(token, 1, true) then
                matches_all = false
                break
            end
        end

        if matches_all and not selected_set[name] then
            table.insert(available_projects, name) -- Store only the project key
        end
    end

    self.available_projects = available_projects
    self.state_changed = true
end

function app_state:GetAvailableProjectCount()
    local count = 0
    for _ in pairs(self.available_projects) do count = count + 1 end
    return count
end

-- ==============================================
-- Moves a project between available and selected
function app_state:SelectProject(proj_name, select)
    if not self.all_projects[proj_name] then
        self:LogError("Attempted to select a project that does not exist: " .. tostring(proj_name))
        return
    end

    if select then
        -- Only add if it's not already selected
        for _, name in ipairs(self.selected_order) do
            if name == proj_name then return end
        end
        table.insert(self.selected_order, proj_name) -- Maintain order
    else
        -- Remove the project from selected_order
        for i, name in ipairs(self.selected_order) do
            if name == proj_name then
                table.remove(self.selected_order, i)
                break
            end
        end
    end

    self:ComputeAvailableProjects() -- Refresh available projects
    self.state_changed = true
end

function app_state:MoveProjectUp(index)
    if type(index) ~= "number" or index <= 1 or index > #self.selected_order then
        self:LogError("MoveProjectUp received an invalid index: " .. tostring(index))
        return
    end

    -- Swap with the previous element
    self.selected_order[index], self.selected_order[index - 1] =
        self.selected_order[index - 1], self.selected_order[index]

    self.state_changed = true
end

function app_state:MoveProjectDown(index)
    if type(index) ~= "number" or index < 1 or index >= #self.selected_order then
        self:LogError("MoveProjectDown received an invalid index: " .. tostring(index))
        return
    end

    -- Swap with the next element
    self.selected_order[index], self.selected_order[index + 1] =
        self.selected_order[index + 1], self.selected_order[index]

    self.state_changed = true
end

function app_state:MoveProject(from_index, to_index)
    -- Ensure both indexes are valid numbers and within bounds
    if type(from_index) ~= "number" or type(to_index) ~= "number" then
        self:LogError("MoveProject received non-numeric index values: " .. tostring(from_index) .. ", " .. tostring(to_index))
        return
    end

    if from_index < 1 or from_index > #self.selected_order or to_index < 1 or to_index > #self.selected_order then
        self:LogError("MoveProject received out-of-bounds indexes: " .. tostring(from_index) .. " -> " .. tostring(to_index))
        return
    end

    if from_index == to_index then
        self:LogMessage("MoveProject: Source and destination are the same, no change needed.")
        return
    end

    -- Remove the project from the original position
    local moved_project = table.remove(self.selected_order, from_index)

    -- Insert at the new position
    table.insert(self.selected_order, to_index, moved_project)

    self.state_changed = true
end

-- ====================================
--== State Export and Recall methods ==

-- Save state to file
function app_state:SaveStateToFile(filepath)
    local state_to_save = {
        dir_path = self.dir_path,
        all_projects = {},  -- Convert objects to tables
        selected_order = self.selected_order,
        import_mode = self.import_mode,
        bar_gap = self.bar_gap
    }

    -- Convert all ProjectInfo objects to tables before saving
    for name, project in pairs(self.all_projects) do
        state_to_save.all_projects[name] = project:ToTable()
    end

    local file, err = io.open(filepath, "w")
    if not file then
        self:LogError("Failed to save state: " .. tostring(err))
        return false, err
    end

    local content = json.encode(state_to_save, { indent = true })
    file:write(content)
    file:close()

    self:LogMessage("State saved to " .. filepath)
    return true
end

-- Load state from file
function app_state:LoadStateFromFile(filepath)
    local file, err = io.open(filepath, "r")
    if not file then
        self:LogError("Failed to load state: " .. tostring(err))
        return false, err
    end

    local content = file:read("*all")
    file:close()

    local state_loaded, pos, decode_err = json.decode(content)
    if decode_err then
        self:LogError("JSON decode error: " .. tostring(decode_err))
        return false, decode_err
    end

    -- Restore Saved State (with Defaults if Missing)
    self.dir_path = state_loaded.dir_path or ""
    self.selected_order = state_loaded.selected_order or {}
    self.import_mode = state_loaded.import_mode or 0
    self.bar_gap = state_loaded.bar_gap or 2

    -- Convert project tables back to ProjectInfo instances
    self.all_projects = {}
    if state_loaded.all_projects then
        for name, project_data in pairs(state_loaded.all_projects) do
            local project_instance = ProjectInfo.fromTable(project_data)
            if project_instance then
                self.all_projects[name] = project_instance
            else
                self:LogError("Skipping invalid project: " .. tostring(name))
            end
        end
    end

    self:ComputeAvailableProjects()
    self.state_changed = true

    self:LogMessage("State loaded from " .. filepath)
    return true
end


-- == Ex State methods ==
-- Create a clean copy of the app_state to prevent encoding errors
function app_state:GetSerializableState()
    local state_to_save = {
        dir_path = self.dir_path,
        selected_order = self.selected_order,
        import_mode = self.import_mode,
        bar_gap = self.bar_gap,
        append_projects = self.append_projects,
        search_query = self.search_query,
        busy = self.busy,
        state_changed = self.state_changed,
        all_projects = {},  -- Convert objects to tables
        available_projects = self.available_projects
    }

    -- Convert all `ProjectInfo` objects into plain tables before saving
    for name, project in pairs(self.all_projects) do
        if type(project.ToTable) == "function" then
            state_to_save.all_projects[name] = project:ToTable()
        else
            self:LogError("Skipping invalid project: " .. tostring(name))
        end
    end

    return state_to_save
end

-- Save entire `app_state` as JSON to REAPER's ExtState
function app_state:SaveStateToExtState()
    local success, state_json = pcall(json.encode, self:GetSerializableState())
    if success then
        reaper.SetExtState("SubprojectImporter", "state", state_json, false)  -- False = not persistent across REAPER sessions
        self:LogMessage("State saved to REAPER ExtState")
    else
        self:LogError("Failed to encode state to JSON: " .. tostring(state_json))
    end
end

-- Load `app_state` from REAPER's ExtState
function app_state:LoadStateFromExtState()
    local state_json = reaper.GetExtState("SubprojectImporter", "state")
    if state_json and state_json ~= "" then
        local success, decoded_state = pcall(json.decode, state_json)
        if success and type(decoded_state) == "table" then
            -- Restore values from saved state
            self.dir_path = decoded_state.dir_path or ""
            self.selected_order = decoded_state.selected_order or {}
            self.import_mode = decoded_state.import_mode or 0
            self.bar_gap = decoded_state.bar_gap or 2
            self.append_projects = decoded_state.append_projects or false
            self.search_query = decoded_state.search_query or ""
            self.busy = decoded_state.busy or false
            self.state_changed = decoded_state.state_changed or false

            -- Restore projects properly
            self.all_projects = decoded_state.all_projects or {}
            self.available_projects = decoded_state.available_projects or {}

            self:LogMessage("State loaded from REAPER ExtState")
            return true
        else
            self:LogError("Failed to decode JSON from ExtState: " .. tostring(decoded_state))
        end
    else
        self:LogError("No saved ExtState found")
    end
    return false
end

-- Save `state_changed` flag separately to ExtState (useful for polling)
function app_state:SaveStateChangedFlag()
    local flag_value = self.state_changed and "1" or "0"
    reaper.SetExtState("SubprojectImporter", "state_changed", flag_value, false)
    self:LogMessage("State change flag saved: " .. flag_value)
end

-- Retrieve `state_changed` flag (useful for web requests)
function app_state:GetStateChangedFromExtState()
    local flag_value = reaper.GetExtState("SubprojectImporter", "state_changed")
    return flag_value == "1"
end


return app_state
