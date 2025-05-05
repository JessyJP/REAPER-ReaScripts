-- project_info.lua
-- Defines the ProjectInfo class to encapsulate project metadata

-- local lfs = require("lfs")  -- LuaFileSystem for getting file modification time
local ProjectInfo = {}
ProjectInfo.__index = ProjectInfo

-- Primary constructor (extracts metadata automatically)
function ProjectInfo:new(filepath)
    local self = setmetatable({}, ProjectInfo)

    -- Assign file path
    self.full_filepath = filepath or ""

    -- Initialize metadata fields
    self.track_count = 0
    self.tempo = 120
    self.total_length = 0
    self.last_modified = 0
    self.project_content = nil  -- Cached file content

    -- Attempt to extract metadata upon creation
    -- self:RefreshMetadata()

    return self
end

-- Secondary constructor: Restore from saved state
function ProjectInfo.fromTable(tbl)
    if not ProjectInfo.Validate(tbl) then
        return nil, "Invalid table structure for ProjectInfo"
    end

    -- Create a new instance
    local instance = setmetatable({}, ProjectInfo)

    -- Assign basic info
    instance.full_filepath = tbl.full_filepath
    instance.last_modified = tbl.last_modified or instance:GetLastModified()

    -- If file hasn't changed, restore metadata; otherwise, refresh
    if instance.last_modified == tbl.last_modified then
        instance.track_count = tbl.track_count
        instance.tempo = tbl.tempo
        instance.total_length = tbl.total_length
    else
        -- instance:RefreshMetadata() -- Refresh because the file changed
    end

    return instance
end

-- Validate if an object conforms to ProjectInfo
function ProjectInfo:IsValid()
    return ProjectInfo.Validate(self)  -- Uses the static method for validation
end

-- === Static validation method ===
function ProjectInfo.Validate(obj)
    return type(obj) == "table"
        and type(obj.full_filepath) == "string"
        and type(obj.track_count) == "number"
        and type(obj.tempo) == "number"
        and type(obj.total_length) == "number"
        and type(obj.last_modified) == "number"
end

-- Convert ProjectInfo to a table (for serialization)
function ProjectInfo:ToTable()
    return {
        full_filepath = self.full_filepath,
        track_count = self.track_count,
        tempo = self.tempo,
        total_length = self.total_length,
        last_modified = self.last_modified
    }
end

-- Get last modified time (cross-platform)
-- function ProjectInfo:GetLastModified()
--     local attr = lfs.attributes(self.full_filepath, "modification")
--     return attr or 0 -- Return timestamp or 0 if not found
-- end

-- Get last modified time (Windows & macOS/Linux)
function ProjectInfo:GetLastModified()
    local command
    if reaper.GetOS():find("Win") then
        command = 'powershell -command "(Get-Item \'' .. self.full_filepath .. '\').LastWriteTime.ToUnixTimeSeconds()" 2>$null'
    else
        command = 'stat -c %Y "' .. self.full_filepath .. '" 2>/dev/null'
    end

    local file = io.popen(command)
    local timestamp = file:read("*a")
    file:close()

    return tonumber(timestamp) or 0
end

-- Read the file content, but only if it has changed
function ProjectInfo:ReadProjectFile()
    local modified_time = self:GetLastModified()

    if modified_time == self.last_modified and self.project_content then
        return self.project_content  -- Return cached content
    end

    local file = io.open(self.full_filepath, "r")
    if not file then
        return nil, "Error opening file: " .. self.full_filepath
    end

    local content = file:read("*all")
    file:close()

    -- Update cache
    self.project_content = content
    self.last_modified = modified_time

    return content
end

-- Refresh metadata only if the file has changed
function ProjectInfo:RefreshMetadata()
    local content, err = self:ReadProjectFile()
    if not content then
        reaper.ShowConsoleMsg("[ERROR] Failed to read file: " .. self.full_filepath .. " -> " .. tostring(err) .. "\n")
        return
    end

    -- Extract metadata from the content
    self.track_count = self:ExtractTrackCount(content)
    self.tempo = self:ExtractTempo(content)
    self.total_length = self:ExtractTotalLength(content)
end

-- Extract track count
function ProjectInfo:ExtractTrackCount(content)
    local track_count = 0
    for _ in content:gmatch("<TRACK") do track_count = track_count + 1 end
    return track_count
end

-- Extract tempo
function ProjectInfo:ExtractTempo(content)
    local tempo_match = content:match("<TEMPO[^>]*>([%d%.]+)")
    if tempo_match then return tonumber(tempo_match) end

    local master_match = content:match("<MASTER_TRACK[^>]*TEMPOENVEX ([%d%.]+)")
    if master_match then return tonumber(master_match) end

    return 120  -- Default tempo
end

-- Extract total length
function ProjectInfo:ExtractTotalLength(content)
    local max_time = 0
    for position, length in content:gmatch("POSITION ([%d%.]+).-LENGTH ([%d%.]+)") do
        local pos_num = tonumber(position) or 0
        local len_num = tonumber(length) or 0
        local item_end = pos_num + len_num
        if item_end > max_time then max_time = item_end end
    end
    return max_time
end

-- Generate a formatted summary string of the project
function ProjectInfo:GetSummaryString(include_tracks, include_last_modified)
    -- Format total length as MM:SS
    local minutes = math.floor(self.total_length / 60)
    local seconds = self.total_length % 60
    local formatted_time = string.format("%d:%02d", minutes, seconds)

    -- Extract project name from filepath
    local project_name = self.full_filepath:match(".+/([^/]+)%.rpp$") or "Unnamed Project"

    -- Base summary
    local summary = string.format("%s | 🎵 %d BPM | ⏱️ %s", project_name, self.tempo, formatted_time)

    -- Optionally include track count
    if include_tracks then
        summary = summary .. string.format(" | 🎚️ Tracks: %d", self.track_count)
    end

    -- Optionally include last modified timestamp
    if include_last_modified then
        local modified_time = os.date("%Y-%m-%d %H:%M", self.last_modified)
        summary = string.format("[%s] %s", modified_time, summary)
    end

    return summary
end

return ProjectInfo
