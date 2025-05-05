-- main.lua
-- Manages REAPER ImGui UI and HTML Web UI based on flags

-- Define UI flags (Set true or false to enable/disable)
local ENABLE_IMGUI_UI = true   -- Enable local ImGui UI
local ENABLE_HTML_UI = false   -- Enable HTML Web Server UI
local ENABLE_EXT_STATE = false   -- Enable Save Ext State to share state and work in linked mode

-- Require dependencies conditionally
local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path    -- Add root directory
package.path = script_path .. "dependencies/?.lua;" .. package.path  -- Add dependencies directory

local r = reaper
local app_state = require("app_state") -- Shared state
local fonts = require("fonts")
local LogMsg = function(...) app_state:LogMessage(...) end

local utf8 = require("utf8")
-- local utf8_project_name = utf8.from_cp1251(project_name)


-- Define filepath for state saving/loading
local state_filepath = script_path .. "app_state.json"

-- Initialize from saved state on startup
local success, err = app_state:LoadStateFromFile(state_filepath)
if success then
    LogMsg("App state initialized from saved file.")
else
    LogMsg("No saved state loaded (" .. tostring(err) .. "). Using defaults.")
end

-- Auto-save state on script exit
reaper.atexit(function()
    app_state:SaveStateToFile(state_filepath)
    LogMsg("Auto-save on exit completed.")
end)

local ui_components, imgui, open
if ENABLE_IMGUI_UI then
    ui_components = require("ui_components")
    imgui = r.ImGui_CreateContext("Subproject Importer")
    open = true
end

for i, font_name in ipairs(fonts) do
    LogMsg(i .. ": " .. tostring(font_name))
end


-- Create and attach a font
local font = reaper.ImGui_CreateFont("Noto Sans", 17) -- Best Unicode coverage
reaper.ImGui_Attach(imgui, font)

local server
if ENABLE_HTML_UI then
    server = require("server") -- HTML server handling
end

-- ✅ Function to check for exit keybinding (ESC or CTRL + Q)
local function CheckForClose(should_stay_open)
    if r.ImGui_IsKeyPressed(imgui, r.ImGui_Key_Escape()) or 
       (r.ImGui_IsKeyDown(imgui, r.ImGui_Mod_Ctrl()) and r.ImGui_IsKeyPressed(imgui, r.ImGui_Key_Q())) then
        return false
    end
    return should_stay_open
end

-- ✅ Single Event Loop handling ImGui and/or HTML Server
local function MainLoop()
    -- Handle ImGui UI if enabled
    if ENABLE_IMGUI_UI and open then
        reaper.ImGui_PushFont(imgui, font) -- Apply font
        r.ImGui_SetNextWindowSize(imgui, 500, 500, r.ImGui_Cond_FirstUseEver())
        local visible, should_stay_open = r.ImGui_Begin(imgui, "Import Subprojects", true)

        if visible then
            should_stay_open = CheckForClose(should_stay_open)
            ui_components.RenderUI(imgui)
            r.ImGui_End(imgui)
        end
        reaper.ImGui_PopFont(imgui) -- Reset back to default font

        open = should_stay_open
    end

    -- Handle HTML Server requests if enabled
    if ENABLE_HTML_UI then
        server.handle_requests()
    end

    if ENABLE_EXT_STATE then
        app_state:SaveStateToExtState()
    end

    -- Continue looping if either UI is open
    if (ENABLE_IMGUI_UI and open) or ENABLE_HTML_UI then
        reaper.defer(MainLoop)
    end
end

-- ✅ Start the combined loop based on flags
if ENABLE_IMGUI_UI and ENABLE_HTML_UI then
    LogMsg("Starting ImGui UI and HTML UI...\n")
elseif ENABLE_IMGUI_UI then
    LogMsg("Starting ImGui UI only...\n")
elseif ENABLE_HTML_UI then
    LogMsg("Starting HTML UI only...\n")
else
    LogMsg("No UI mode selected. Exiting.\n")
    return
end

MainLoop()
