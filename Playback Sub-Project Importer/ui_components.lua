-- ui_components.lua
-- Handles UI Components & Layout

local import_processor = require("import_processor")
local app_state = require("app_state") -- Import global state
local reaper_interactions = require("reaper_interactions") -- Use the new module
local action_cb = require("app_actions") -- Import state modification utilities

-- UI state variables
local ui_state = {
    focus_directory = false, -- UI toggle flags
    focus_search = false, -- UI toggle flags
    selected_project_name = nil  -- Track selected project
}

-- Function to handle keyboard shortcuts (Ctrl + B, S, I, D, F, Alt + A)
local function HandleShortcuts(imgui)
    -- Get the current key modifiers (Ctrl, Alt, Shift, etc.)
    local key_mods = reaper.ImGui_GetKeyMods(imgui)
    local ctrl = (key_mods & reaper.ImGui_Mod_Ctrl()) ~= 0  -- Check if Ctrl is held
    local alt = (key_mods & reaper.ImGui_Mod_Alt()) ~= 0    -- Check if Alt is held

    -- Define shortcut actions with their corresponding key combinations
    local shortcuts = {
        -- Ctrl + B → Open folder browser to select project directory
        { ctrl, reaper.ImGui_Key_B(), import_processor.BrowseForFolder },

        -- Ctrl + S → Scan the selected directory for projects
        { ctrl, reaper.ImGui_Key_S(), action_cb.ScanDirectory },

        -- Ctrl + I → Import selected projects into REAPER
        { ctrl, reaper.ImGui_Key_I(), action_cb.ImportProjects },

        -- Ctrl + D → Focus on the directory input field
        { ctrl, reaper.ImGui_Key_D(), function() ui_state.focus_directory = true end },

        -- Ctrl + F → Focus on the search bar
        { ctrl, reaper.ImGui_Key_F(), function() ui_state.focus_search = true end },

        -- Alt + A → Toggle the "Append Projects" option (ON/OFF)
        { alt, reaper.ImGui_Key_A(), function()
            app_state:SetAppendProjects(not app_state:GetAppendProjects())
        end }
    }

    -- Loop through the shortcut table and execute actions if keys are pressed
    for _, shortcut in ipairs(shortcuts) do
        local mod, key, action = table.unpack(shortcut)
        if mod and reaper.ImGui_IsKeyPressed(imgui, key) then
            action() -- Execute the assigned function
        end
    end

    -- Handle project selection-related shortcuts (Up/Down/X)
    local selected_name = ui_state.selected_project_name
    if selected_name then
        -- ↑ Arrow Key → Move the selected project UP in the list
        if reaper.ImGui_IsKeyPressed(imgui, reaper.ImGui_Key_UpArrow()) then
            ui_state.selected_project_name = action_cb.MoveSelectedProject(selected_name, "up")

        -- ↓ Arrow Key → Move the selected project DOWN in the list
        elseif reaper.ImGui_IsKeyPressed(imgui, reaper.ImGui_Key_DownArrow()) then
            ui_state.selected_project_name = action_cb.MoveSelectedProject(selected_name, "down")

        -- X Key → Remove the selected project from the list
        elseif reaper.ImGui_IsKeyPressed(imgui, reaper.ImGui_Key_X()) then
            ui_state.selected_project_name = action_cb.RemoveSelectedProject(selected_name)
        end
    end
end

-- =================================================================================================
-- === FUNCTION: Render Append Projects checkbox ===
local function RenderAppendCheckbox(imgui)
    -- Keep the checkbox on the same line as the input
    reaper.ImGui_SameLine(imgui, nil, 10) -- Adjust spacing if needed

    local append = app_state:GetAppendProjects()
    local changed, new_append = reaper.ImGui_Checkbox(imgui, "Append Projects", append)
    if changed then
        app_state:SetAppendProjects(new_append)
    end
    -- reaper.ImGui_Separator(imgui)
end

-- === FUNCTION: Render directory path input ===
local function RenderProjectFolderInput(imgui)
    reaper.ImGui_Text(imgui, "Project Folder:")

    if ui_state.focus_directory then
        reaper.ImGui_SetKeyboardFocusHere(imgui)
        ui_state.focus_directory = false  -- Reset after applying
    end

    -- Directory input field
    local changed, new_path = reaper.ImGui_InputText(imgui, "##ProjectFolder", app_state:GetDirPath())

    if changed then
        app_state:SetDirPath(action_cb.SanitizeText(new_path))
    end

    -- Append Projects Checkbox
    RenderAppendCheckbox(imgui)  -- Added checkbox here

    reaper.ImGui_Separator(imgui)
end

-- === FUNCTION: Render action buttons (Browse, Scan, Import) ===
local function RenderActionButtons(imgui)
    local browse_width = reaper.ImGui_CalcTextSize(imgui, "Browse (CTRL + B)") + 20
    local scan_width = reaper.ImGui_CalcTextSize(imgui, "Scan Directory (CTRL + S)") + 20
    local import_width = reaper.ImGui_CalcTextSize(imgui, "Import Selected Subprojects (CTRL + I)") + 20

    if reaper.ImGui_Button(imgui, "Browse (CTRL + B)", browse_width, 30) then
        import_processor.BrowseForFolder()
    end
    
    reaper.ImGui_SameLine(imgui)

    if reaper.ImGui_Button(imgui, "Scan Directory (CTRL + S)", scan_width, 30) then
        action_cb.ScanDirectory()
    end

    reaper.ImGui_SameLine(imgui)

    if reaper.ImGui_Button(imgui, "Import Selected Subprojects (CTRL + I)", import_width, 30) then
        action_cb.ImportProjects()
    end

    reaper.ImGui_Separator(imgui)
end

-- === FUNCTION: Render import settings (mode & gap) ===
local function RenderImportSettings(imgui)
    local options = { "Single Track (Sequential)", "Multiple Tracks (Sequential)", "Multiple Tracks (Overlapping)" }
    local mode_changed, new_mode = reaper.ImGui_Combo(imgui, "##ImportMode", app_state:GetImportMode(), table.concat(options, "\0") .. "\0")

    reaper.ImGui_SameLine(imgui)
    reaper.ImGui_Text(imgui, "Import Mode")

    if mode_changed then 
        import_processor.SetImportMode(new_mode)
    end

    local gap_changed, new_gap = reaper.ImGui_InputInt(imgui, "Gap Between Projects (Bars)", app_state:GetBarGap())
    if gap_changed and new_gap >= 0 then 
        import_processor.SetBarGap(new_gap)
    end
end

-- FUNCTION: Render track selection info + busy indicator
local function RenderTrackSelectionInfo(imgui)
    if app_state:GetImportMode() == 0 then  -- 0 = Single Track Sequential
        reaper.ImGui_Separator(imgui)

        -- Get track selection info (now includes track index)
        local track_info = reaper_interactions.GetSelectedTrackInfo()

        -- Convert RGBA (0.7, 0.7, 0.7, 1.0) into packed color
        local text_color = reaper.ImGui_ColorConvertDouble4ToU32(0.7, 0.7, 0.7, 1.0)

        -- Display track index along with name
        reaper.ImGui_TextColored(imgui, text_color, track_info)

        -- Render Busy Indicator
        if app_state:GetBusy() then
            reaper.ImGui_SameLine(imgui)
            local busy_color = reaper.ImGui_ColorConvertDouble4ToU32(1.0, 0.0, 0.0, 1.0)  -- Red
            reaper.ImGui_TextColored(imgui, busy_color, " [BUSY]")
        end
    end

    reaper.ImGui_Separator(imgui)
end

-- FUNCTION: Render search bar for filtering available projects
local function RenderSearchBar(imgui)
    reaper.ImGui_Text(imgui, "Search Available Projects:")

    if ui_state.focus_search then
        reaper.ImGui_SetKeyboardFocusHere(imgui)
        ui_state.focus_search = false  -- Reset after applying
    end

    local changed, new_search = reaper.ImGui_InputText(imgui, "##SearchProjects", app_state:GetSearchQuery())

    if changed then
        app_state:SetSearchQuery(new_search)
        action_cb.RefreshAvailableProjects() -- Recompute available projects on search update
    end

    reaper.ImGui_Separator(imgui)
end

-- === FUNCTION: Directory Selection & Configuration (Top Controls) ===
local function RenderTopControls(imgui)
    RenderProjectFolderInput(imgui)
    RenderActionButtons(imgui)
    RenderImportSettings(imgui)
    RenderTrackSelectionInfo(imgui)
    RenderSearchBar(imgui)
end

-- =================================================================================================
-- FUNCTION: Render Available Projects Panel
local function RenderAvailableProjectsPanel(imgui, panel_width, panel_height)
    -- Get as local variables
    local available_projects = app_state:GetAvailableProjects()
    local all_projects = app_state:GetAllProjects()

    -- Left Panel: Available Projects
    reaper.ImGui_BeginGroup(imgui)
    reaper.ImGui_Text(imgui, string.format("Available Projects (%d / %d)", #available_projects, app_state:GetTotalProjectCount()))

    if reaper.ImGui_BeginChild(imgui, "##AvailableProjects", panel_width, panel_height, 1) then
        for _, project_name in ipairs(available_projects) do
            local project = all_projects[project_name]
            if project then
                local summary = project:GetSummaryString()  -- Display summary instead of name
                
                if reaper.ImGui_Selectable(imgui, summary, false) then
                    app_state:SelectProject(project_name, true)
                    action_cb.RefreshAvailableProjects()
                end
            end
        end
        reaper.ImGui_EndChild(imgui)
    end
    reaper.ImGui_EndGroup(imgui)
end

-- FUNCTION: Render Selected Projects Panel (Supports Right-Click Removal & Drag/Drop Reordering)
local function RenderSelectedProjectsPanel(imgui, panel_width, panel_height)
    -- Get local variables
    local selected_projects = app_state:GetSelectedProjectsList()
    local all_projects = app_state:GetAllProjects()

    -- Right Panel: Selected Projects
    reaper.ImGui_BeginGroup(imgui)
    reaper.ImGui_Text(imgui, string.format("Selected for Import (%d)", #selected_projects))

    if reaper.ImGui_BeginChild(imgui, "##SelectedProjects", panel_width, panel_height, 1) then
        for i, project_name in ipairs(selected_projects) do
            local project = all_projects[project_name]
            if project then
                local summary = string.format("%d. %s", i, project:GetSummaryString()) -- Add index

                -- Determine if this project is the selected one
                local is_selected = (ui_state.selected_project_name == project_name)

                -- Begin a horizontal layout for the row (index, project name, buttons)
                reaper.ImGui_PushID(imgui, "Selected_" .. i)

                -- If the project is selected, show Up/Down buttons
                if is_selected then
                    -- Move Up button
                    if i > 1 then
                        if reaper.ImGui_Button(imgui, "▲") then
                            ui_state.selected_project_name = action_cb.MoveSelectedProject(project_name, "up")
                        end
                        reaper.ImGui_SameLine(imgui, nil, 5)
                    else
                        -- Placeholder to align buttons
                        reaper.ImGui_Dummy(imgui, 20, 20)
                        reaper.ImGui_SameLine(imgui, nil, 5)
                    end
                    
                    -- Move Down button
                    if i < #selected_projects then
                        if reaper.ImGui_Button(imgui, "▼") then
                            ui_state.selected_project_name = action_cb.MoveSelectedProject(project_name, "down")
                        end
                        reaper.ImGui_SameLine(imgui, nil, 5)
                    else
                        -- Placeholder to align buttons
                        reaper.ImGui_Dummy(imgui, 20, 20)
                        reaper.ImGui_SameLine(imgui, nil, 5)
                    end
                end

                -- ✅ FIX: Clicking the same item again will now DESELECT it
                if reaper.ImGui_Selectable(imgui, summary, is_selected, reaper.ImGui_SelectableFlags_AllowItemOverlap) then
                    if is_selected then
                        ui_state.selected_project_name = nil  -- Deselect if already selected
                    else
                        ui_state.selected_project_name = project_name -- Select item
                    end
                end

                -- Right-click removal
                if reaper.ImGui_IsItemClicked(imgui, 1) then  -- Detect right-click
                    ui_state.selected_project_name = action_cb.RemoveSelectedProject(project_name)
                end

                -- Drag and Drop Source (Reordering)
                if reaper.ImGui_BeginDragDropSource(imgui) then
                    reaper.ImGui_SetDragDropPayload(imgui, "DND_PROJECT", i)
                    reaper.ImGui_Text(imgui, summary)
                    reaper.ImGui_EndDragDropSource(imgui)
                end

                -- Drag and Drop Target (Drop at new position)
                if reaper.ImGui_BeginDragDropTarget(imgui) then
                    local payload_index = reaper.ImGui_AcceptDragDropPayload(imgui, "DND_PROJECT")
                    if type(payload_index) == "number" and payload_index ~= i then
                        app_state:MoveProject(payload_index, i) -- ✅ FIX Drag and Drop
                    end
                    reaper.ImGui_EndDragDropTarget(imgui)
                end                            

                reaper.ImGui_PopID(imgui)
            end
        end
        reaper.ImGui_EndChild(imgui)
    end
    reaper.ImGui_EndGroup(imgui)
end

-- === FUNCTION: Render Project Selection UI (Available & Selected fill Remaining Window Height) ===
local function RenderProjectSelection(imgui)
    local window_width, window_height = reaper.ImGui_GetContentRegionAvail(imgui)
    local top_panel_height = 170
    local panel_height = window_height - 22
    if panel_height < 100 then panel_height = 100 end
    local panel_width = (reaper.ImGui_GetContentRegionAvail(imgui) / 2) - 5

    RenderAvailableProjectsPanel(imgui, panel_width, panel_height)
    reaper.ImGui_SameLine(imgui)
    RenderSelectedProjectsPanel(imgui, panel_width, panel_height)
end

-- =======================================
-- === MAIN FUNCTION: Render Entire UI ===
local function RenderUI(imgui)
    HandleShortcuts(imgui)
    RenderTopControls(imgui)
    RenderProjectSelection(imgui)
end

-- Export UI functions
return { RenderUI = RenderUI }
