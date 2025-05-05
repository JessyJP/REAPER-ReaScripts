-- require_local_import_code_snippet.lua
-- Ensures the script can find and load local Lua files

local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
package.path = script_path .. "?.lua;" .. package.path