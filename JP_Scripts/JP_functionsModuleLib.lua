--[[
   * ReaScript Name: JP_functionsModuleLib.lua
   * Description: Lua Module for with general functions that can be imported for convenience. //JP-LivePerfromSetup.lua                     
   * Author: JessyJP
   * Author URI: ....
   * Licence: GPL v3
   * Version: 1.0
--]]


--[[ MODULE NAMESPACE ]]--
	JP_functionsModuleLib =  {}
	--module("JP_functionsModuleLib", package.seeall)

--[[ MODULE VALIDATION/CONFIRMATION ]]--
	JP_functionsModuleLib.loaded = true
	JP_functionsModuleLib.Author = "JessyJP"

--[[ GLOBAL VARIABLES ]]--
	JP_functionsModuleLib.DEBUG_ON = true;
	JP_functionsModuleLib.flag=0; -- is needed for calling some commands


-------------------------------
--[[ MODULE IMPORT SUMMARY ]]--
-------------------------------

	-- Description: This code can be copied into any script and the functions there can be imported locally.
	-- 				This method determins the OS and then finds the appropriate filepath.
	-- 				The module is imported and the internal properties are set.
	-- 				The user can choose to import the local properties and functions or to prefex them with the namespace.
	-- 				Any subset of the functions can be imported.
	--				There shouldn't be extra dependencies that have to be imported.
	----------------------------------------------------------------------------
	--|    -- Determine the platform that the script is currently running on.
	--|    local _OS_ , _CPU_ = reaper.GetOS(), "x64";
	--|    if OS == "Win32" or OS == "OSX32" then _CPU_="x32" end;
	--|    -- Load the necesary module
	--|    modulePath=(reaper.GetResourcePath().."/Scripts/".."JP_functionsModuleLib.lua");
	--|    package.path = modulePath;
	--|      -- Extra Method: info = debug.getinfo(1,'S');-- what is this ??
	--|      -- Extra Method: script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
	--|    -- Add the module
	--|    require(modulePath)--MM = require'JP_functionsModuleLib' -- "MM" stands for My module
	--|    assert(JP_functionsModuleLib.loaded,"ERROR: Module not found or failed to load! [JP_functionsModuleLib.lua]");
	--|    -- Import the needed subset of module function names(symbols) locally for conveniense.
	--|    local Debug          = JP_functionsModuleLib.Debug;
	--|    local DebugArray     = JP_functionsModuleLib.DebugArray;
	--|    local printTable     = JP_functionsModuleLib.printTable;
	--|    local runAction      = JP_functionsModuleLib.runAction;
	--|    -- Set module varaiables
	--|    JP_functionsModuleLib.DEBUG_ON =true; -- switch for debugging ON for the module functions
	--|    JP_functionsModuleLib.flag     =0; -- is needed for calling some commands			
	----------------------------------------------------------------------------




--------------------------------------------------------------------
--[[ FUNCTIONS SECTION 1: Display, debug & print type functions ]]--
--------------------------------------------------------------------

	
	-- Debug function - display messages in the console
	function JP_functionsModuleLib.Debug(String)
	  if(JP_functionsModuleLib.DEBUG_ON) then
	    reaper.ShowConsoleMsg(tostring(String).."\n");
	  end
	end
	
	-- Debug function to display array raw content in in console
	function JP_functionsModuleLib.DebugArray(Array)
	  if(JP_functionsModuleLib.DEBUG_ON) then
	    for index, value in ipairs(Array) do
	      reaper.ShowConsoleMsg("["..tostring(index).."] = "..tostring(value).."\n");
	    end
	  end
	end
		
	-- This one was found on a forum ... somewhere in the internet
	function JP_functionsModuleLib.dump(o)
	   if type(o) == 'table' then
		  local s = '{ '
		  for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
		  end
		  return s .. '} '
	   else
		  return tostring(o)
	   end
	end
	
	-- This one was found on a forum ... somewhere on the internet
	function JP_functionsModuleLib.tprint (t, s)
	    for k, v in pairs(t) do
		 local kfmt = '["' .. tostring(k) ..'"]'
		 if type(k) ~= 'string' then
		     kfmt = '[' .. k .. ']'
		 end
		 local vfmt = '"'.. tostring(v) ..'"'
		 if type(v) == 'table' then
		     tprint(v, (s or '')..kfmt)
		 else
		     if type(v) ~= 'string' then
			  vfmt = tostring(v)
		     end
		     print(type(t)..(s or '')..kfmt..' = '..vfmt)
		 end
	    end
	end


-----------------------------------------------------------
--[[ FUNCTIONS SECTION 2: Convert to string for display]]--
-----------------------------------------------------------

	
	-- Copied from: https://www.folkstalk.com/2022/09/print-a-table-in-lua-with-code-examples.html
	function JP_functionsModuleLib.printTable(node)
		local cache, stack, output = {},{},{}
		local depth = 1
		local output_str = "{\n"

		while true do
			local size = 0
			for k,v in pairs(node) do
				size = size + 1
			end

			local cur_index = 1
			for k,v in pairs(node) do
				if (cache[node] == nil) or (cur_index >= cache[node]) then

					if (string.find(output_str,"}",output_str:len())) then
						output_str = output_str .. ",\n"
					elseif not (string.find(output_str,"\n",output_str:len())) then
						output_str = output_str .. "\n"
					end

					-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
					table.insert(output,output_str)
					output_str = ""

					local key
					if (type(k) == "number" or type(k) == "boolean") then
						key = "["..tostring(k).."]"
					else
						key = "['"..tostring(k).."']"
					end

					if (type(v) == "number" or type(v) == "boolean") then
						output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
					elseif (type(v) == "table") then
						output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
						table.insert(stack,node)
						table.insert(stack,v)
						cache[node] = cur_index+1
						break
					else
						output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
					end

					if (cur_index == size) then
						output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
					else
						output_str = output_str .. ","
					end
				else
					-- close the table
					if (cur_index == size) then
						output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
					end
				end

				cur_index = cur_index + 1
			end

			if (size == 0) then
				output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
			end

			if (#stack > 0) then
				node = stack[#stack]
				stack[#stack] = nil
				depth = cache[node] == nil and depth + 1 or depth - 1
			else
				break
			end
		end

		-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
		table.insert(output,output_str)
		output_str = table.concat(output)

		JP_functionsModuleLib.Debug(output_str)
	end


--------------------------------------------------
--[[ FUNCTIONS SECTION 3: General call command]]--
--------------------------------------------------

    -- Run action and display information
    function JP_functionsModuleLib.runAction( descriptionText , actionID)
      local commandID = actionID;
      if (type(actionID) == "string") then
        commandID = reaper.NamedCommandLookup(actionID);
      end
      reaper.Main_OnCommand(commandID, JP_functionsModuleLib.flag );
      JP_functionsModuleLib.Debug("Call:["..tostring(descriptionText).."] cmdID:["..tostring(actionID).."]");
    end


---------------------------------------------
--[[ FUNCTIONS SECTION 4: Entry Functions]]--
---------------------------------------------

	
	-- Import Entry Function to string
    function JP_functionsModuleLib.importEntryToString(importEntry)
        local outputString =
        {
        " .",
        " |-subProjectIndex         :".. toString(importEntry.subProjectIndex         ).."\n",
        " |-trackNameOrIndex        :".. toString(importEntry.trackNameOrIndex        ).."\n",
        " |-allItemsYes             :".. toString(importEntry.allItemsYes             ).."\n",
        " |-envelopeNamesList       :".. toString(importEntry.envelopeNamesList       ).."\n",
        " |-FXsOnTrackByNameOrIndex :".. toString(importEntry.FXsOnTrackByNameOrIndex ).."\n",
        };
        return outputString;
    end
	
	
	-- Import Entry Function make
	function importEntryAdd(subProjectIndex,trackNameOrIndex,allItemsYes, envelopeNamesList,FXsOnTrackByNameOrIndex)
		-- Default Template
		-- local importTemplate =
		-- {
		   -- subProjectIndex=0;-- Default index, means don't import anything. Main (0) doesn't import to itself.
		   -- trackNameOrIndex="";--""/"all"/{[string -> sub_project_name(s)"]}/{[integer -> sub_project_index(s)]}
		   -- allItemsYes=false;--""/"Track Name"/"Track Index" -- All items on the track will be imported
		   -- envelopeNamesList={};-- All points on the Named envelopes on the track will be imported
		   -- FXsOnTrackByNameOrIndex={}
		-- };
		assert()
		local importTemplate = 
						   { subProjectIndex, 
							trackNameOrIndex, 
							allItemsYes, 
							envelopeNamesList,
							FXsOnTrackByNameOrIndex
						   }
    end


return JP_functionsModuleLib	