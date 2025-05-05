-- app_actions.lua
-- Defines action callbacks that can be triggered by UI or server interactions

local import_processor = require("import_processor")
local app_state = require("app_state")
local reaper_interactions = require("reaper_interactions")

-- Function to sanitize input (removes newlines and trims leading/trailing spaces)
local function SanitizeText(text)
    return text:gsub("\n", ""):match("^%s*(.-)%s*$") -- Remove newlines and trim spaces
end

-- Function to scan the specified directory for projects
local function ScanDirectory()
    if import_processor.DoesDirectoryExist(app_state:GetDirPath()) then
        app_state:SetBusy(true)
        import_processor.ScanForProjects(app_state:GetDirPath())
        app_state:ComputeAvailableProjects()
        app_state:SetBusy(false)
    end
end

-- Function to import selected projects into REAPER
local function ImportProjects()
    if next(app_state:GetSelectedProjectsList()) then
        app_state:SetBusy(true)
        reaper_interactions.ImportProjectsAsMediaItems()
        app_state:SetBusy(false)
    end
end

-- Function to refresh available projects list (based on current state)
local function RefreshAvailableProjects()
    app_state:ComputeAvailableProjects()
end

-- Function to move a specific project up or down
local function MoveSelectedProject(selected_name, direction)
    if not selected_name then return end

    local selected_projects = app_state:GetSelectedProjectsList()

    for i, name in ipairs(selected_projects) do
        if name == selected_name then
            if direction == "up" and i > 1 then
                app_state:MoveProjectUp(i)
                return selected_projects[i - 1] -- Return new selected project
            elseif direction == "down" and i < #selected_projects then
                app_state:MoveProjectDown(i)
                return selected_projects[i + 1] -- Return new selected project
            end
        end
    end

    return selected_name -- If no move happened, keep selection unchanged
end

-- Function to remove a selected project from the list
local function RemoveSelectedProject(selected_name)
    if not selected_name then return end

    -- Remove project from selected list
    app_state:SelectProject(selected_name, false)

    -- Refresh available projects after removal
    RefreshAvailableProjects()

    return nil -- Return nil to indicate the selection should be cleared
end

return {
    SanitizeText = SanitizeText,
    ScanDirectory = ScanDirectory,
    ImportProjects = ImportProjects,
    RefreshAvailableProjects = RefreshAvailableProjects,
    MoveSelectedProject = MoveSelectedProject,
    RemoveSelectedProject = RemoveSelectedProject
}
