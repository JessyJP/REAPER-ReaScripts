-- JP_web_handler_project_importer.lua (web slave)
-- Handles API actions using REAPER ExtState

-- Configuration
local r = reaper
local APP_NAME = "SubprojectImporter"  -- Can be dynamically set

-- Toggle: Control whether multiple actions execute in one loop iteration
local ALLOW_MULTIPLE_ACTIONS = true  -- Set to `false` to execute only one action per iteration

-- Dependencies
local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path
package.path = script_path .. "dependencies/?.lua;" .. package.path

local app_state = require("app_state")
local action_cb = require("app_actions")
local reaper_utils = require("reaper_interactions")
local import_processor = require("import_processor")

-- Logging Helper
local function LogMsg(...) app_state:LogMessage(...) end

-- Helper: Set and Get REAPER ExtState
local function setState(key, value) r.SetExtState(APP_NAME, key, value, false) end
local function getState(key) return r.GetExtState(APP_NAME, key) end

-- Unified action handlers (Key → Function)
local handlers = {
    -- Simple actions
    ["init"] = function(value) LogMsg("🚀 Web UI Initialized. Syncing state...") end,
    ["scan"] = function(value) action_cb.ScanDirectory(); setState("status", "Scan complete") end,
    ["import"] = function(value) action_cb.ImportProjects(); setState("status", "Import complete") end,
    ["browse"] = function(value) import_processor.BrowseForFolder(); setState("status", "Opened directory browser") end,

    -- REAPER interactions
    ["get_selected_track"] = function(value)
        local track_info = reaper_utils.GetSelectedTrackInfo()
        setState("track_info", track_info)
        setState("status", "Track info updated")
    end,
    ["open_in_current_tab"] = function(value) reaper_utils.OpenProjectInCurrentTab(); setState("status", "Opened projects in current tab") end,
    ["open_in_new_tab"] = function(value) reaper_utils.OpenProjectInNewTab(); setState("status", "Opened projects in new tab") end,
    ["import_as_media_items"] = function(value) reaper_utils.ImportProjectsAsMediaItems(); setState("status", "Imported projects as media items") end,
    ["get_busy"] = function(value) setState("busy", app_state:GetBusy() and "true" or "false") end,

    -- Project order management
    ["move_up"] = function(value) action_cb.MoveSelectedProject(value, "up"); setState("status", "Moved " .. value .. " up") end,
    ["move_down"] = function(value) action_cb.MoveSelectedProject(value, "down"); setState("status", "Moved " .. value .. " down") end,
    ["remove"] = function(value) action_cb.RemoveSelectedProject(value); setState("status", "Removed " .. value) end,

    -- App state updates
    ["set_dir"] = function(value) app_state:SetDirPath(value); setState("status", "Set directory to " .. value) end,
    ["set_import_mode"] = function(value) app_state:SetImportMode(tonumber(value)); setState("status", "Import mode set to " .. value) end,
    ["set_bar_gap"] = function(value) app_state:SetBarGap(tonumber(value)); setState("status", "Bar gap set to " .. value) end,
    ["set_append"] = function(value) app_state:SetAppendProjects(value == "true"); setState("status", "Append projects " .. value) end,
    ["set_search"] = function(value) app_state:SetSearchQuery(value); setState("status", "Search query updated") end,
    ["set_available_projects"] = function(value)
        local success, decoded = pcall(json.decode, value)
        if success and type(decoded) == "table" then
            app_state:Set("available_projects", decoded)
            setState("status", "Available projects updated")
        else
            LogMsg("❌ Failed to decode available projects JSON")
        end
    end,
    ["set_selected_order"] = function(value)
        local success, decoded = pcall(json.decode, value)
        if success and type(decoded) == "table" then
            app_state:SetSelectedOrder(decoded)
            setState("status", "Selected project order updated")
        else
            LogMsg("❌ Failed to decode selected order JSON")
        end
    end
}

-- Main API handler
local function handleAction()
    app_state:LoadStateFromExtState()
    local executed_action = false  -- Track if an action has been executed

    for key, handler in pairs(handlers) do
        local value = getState(key)

        if value and value ~= "" then
            LogMsg("🔹 Processing API call: " .. key .. " = " .. value)
            handler(value)
            setState(key, "") -- Clear state after execution            
            executed_action = true

            -- If multiple actions are NOT allowed, stop after the first execution
            if not ALLOW_MULTIPLE_ACTIONS then
                break
            end
        end
    end

    -- Save state after processing, regardless of mode
    if executed_action then
        app_state:SaveStateToExtState()
    end
end

-- Execute handler
handleAction()
