-- import_processor.lua
-- Handles scanning, selection, and importing of subprojects

local r = reaper
local app_state = require("app_state") -- Import the centralized state
local ProjectInfo = require("project_info")

local LogMsg = function(...) app_state:LogMessage(...) end
local LogErr = function(...) app_state:LogError(...) end

-- Checks if a directory exists using a system call (Placeholder/Disabled for now)
function DoesDirectoryExist(path)
    LogMsg("Checking if directory exists: " .. tostring(path))

    -- Placeholder implementation always returns true
    -- Uncomment and use the real implementation when ready

    -- local command
    -- if package.config:sub(1, 1) == "\\" then
    --     -- Windows: Use 'if exist "path" (echo exists)' to check
    --     command = 'if exist "' .. path .. '" (exit 0) else (exit 1)'
    -- else
    --     -- macOS/Linux: Use 'test -d "path"' to check
    --     command = '[ -d "' .. path .. '" ]'
    -- end

    -- -- Run the system command
    -- local result = os.execute(command)

    -- if result == 0 then
    --     LogMsg("Directory exists!")
    --     return true
    -- else
    --     LogMsg("Directory does not exist.")
    --     return false
    -- end

    return true
end

-- Open a directory selection browser
local function BrowseForFolder()
    reaper.defer(function()
        local ret, path = reaper.JS_Dialog_BrowseForFolder("Select Project Directory", app_state:GetDirPath())
        if ret and path and path ~= "" then
            app_state:SetDirPath(path) -- Use setter method
            LogMsg("User selected folder: " .. path)
        else
            LogMsg("User canceled folder selection or selected an invalid path. No changes made.")
        end
    end)
end

-- Recursively scans directories for .rpp project files (case-insensitive)
local function RecursiveScan(directory, file_list)
    local i = 0
    local file = reaper.EnumerateFiles(directory, i)

    -- Scan all files in the current directory
    while file do
        if not file or file == "" then
            LogErr("Skipped invalid file entry in directory: " .. tostring(directory))
        else
            local success, err = xpcall(function()
            local lower_file = file:lower() -- Convert filename to lowercase
                if lower_file:match("%.rpp$") then
                    local full_path = directory .. "/" .. file
                    table.insert(file_list, full_path)
                    LogMsg("Found project file: " .. full_path)
                end
            end, debug.traceback)

            if not success then
                LogErr("Error processing file: " .. tostring(file) .. " -> " .. tostring(err))
            end
        end

        i = i + 1
        file = reaper.EnumerateFiles(directory, i)
    end

    -- Scan subdirectories recursively
    local j = 0
    local subdir = reaper.EnumerateSubdirectories(directory, j)

    while subdir do
        if not subdir or subdir == "" then
            LogErr("Encountered an invalid subdirectory entry while scanning: " .. tostring(directory))
            break
        end

        local success, err = xpcall(function()
            local full_subdir_path = directory .. "/" .. subdir
            LogMsg("Scanning subdirectory: " .. full_subdir_path)
            RecursiveScan(full_subdir_path, file_list) -- Recursive call
        end, debug.traceback)

        if not success then
            LogErr("Error processing subdirectory: " .. tostring(subdir) .. " -> " .. tostring(err))
        end

        j = j + 1
        subdir = reaper.EnumerateSubdirectories(directory, j)
    end
end

-- Creates an item table from a list of project files
local function CreateProjectDatabase(file_list)
    LogMsg("CreateProjectDatabase: Creating ProjectInfo instances with file paths.")
    LogMsg("======================================")

    local projects = {}
    for _, full_path in ipairs(file_list) do
        if type(full_path) == "string" and full_path ~= "" then  -- Prevent nil errors
            -- Normalize path: Replace backslashes with forward slashes
            local normalized_path = full_path:gsub("\\", "/"):gsub(":/+", ":/")

            -- Extract project name (which will be the project reference key in the dictionary)
            local project_name = normalized_path:lower():match(".+/([^/]+)%.rpp$")

            if project_name then
                -- Create a ProjectInfo instance with just the (normalized) file path
                projects[project_name] = ProjectInfo:new(normalized_path)

                LogMsg("Added project: " .. project_name .. " -> " .. normalized_path)
            else
                LogErr("Skipped invalid project file (No valid .rpp name found): " .. tostring(normalized_path))
            end
        else
            LogErr("Skipped invalid or empty file path entry in the file list.")
        end
    end

    LogMsg("======================================")
    LogMsg("CreateProjectDatabase: Creation complete. Total projects: " .. tostring(app_state:GetTotalProjectCount()))

    return projects
end

-- Scans directory for .rpp files and prepares project list (Recursively)
function ScanForProjects(dir_path)
    LogMsg("ScanForProjects called with path: " .. tostring(dir_path))

    if not DoesDirectoryExist(dir_path) then 
        LogErr("Directory does not exist!")
        return nil, "Invalid directory path. Please select a valid folder."
    end

    app_state:SetDirPath(dir_path)
    local file_list = {}

    -- Recursively scan the directory for .rpp files
    RecursiveScan(app_state:GetDirPath(), file_list)

    LogMsg("Total .rpp project files found: " .. #file_list)

    -- Convert to structured ProjectInfo objects
    local all_projects = CreateProjectDatabase(file_list)

    -- Assign structured metadata to state
    app_state:SetAllProjects(all_projects)
    app_state:ComputeAvailableProjects()

    LogMsg("Scan complete. Projects stored in app_state.")
end

return {
    DoesDirectoryExist = DoesDirectoryExist,
    BrowseForFolder = BrowseForFolder,
    ScanForProjects = ScanForProjects
}
