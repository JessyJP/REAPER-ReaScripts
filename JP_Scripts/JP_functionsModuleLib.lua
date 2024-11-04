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

--[[ VARIABLES ]]--
	JP_functionsModuleLib.DEBUG_ON = true;
	JP_functionsModuleLib.flag=0; -- is needed for calling some commands
	JP_functionsModuleLib.database = {};--

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
	--|    local getMarkerOrRegionEntry      = JP_functionsModuleLib.getMarkerOrRegionEntry;
	--|    local addMarkerOrRegionEntry      = JP_functionsModuleLib.addMarkerOrRegionEntry;
	--|    local extraxtAllMarkersAndRegions = JP_functionsModuleLib.extraxtAllMarkersAndRegions;
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

	-- This function is pretty useful for debugging. It was downloaded from a forum on the internet.
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


-------------------------------------------------------------------
--[[ FUNCTIONS SECTION 5: Markers and regions struct functions ]]--
-------------------------------------------------------------------

        
    -- Extract a marker or region for the current project by index
    function JP_functionsModuleLib.getMarkerOrRegionEntry(index)
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(index)
        --local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(I.mainPrjInd, index)
        --local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(I.mainPrjInd, index)
        local E = {
                    retval              =retval, 
                    isrgn               =isrgn, 
                    pos                 =pos, 
                    rgnend              =rgnend, 
                    name                =name, 
                    markrgnindexnumber  =markrgnindexnumber,
                    enabled             =true,
                    group               =0
                  };
        return E;-- Return the Entry
    end

    -- Add marker or region entry
    function JP_functionsModuleLib.addMarkerOrRegionEntry(E,projectInd)
        output = reaper.AddProjectMarker(projectInd,E.isrgn, E.pos, E.rgnend, E.name, E.markrgnindexnumber);
        JP_functionsModuleLib.Debug(string.format(" |- AddProjectMarker I:[%2d] On:[%1s] IsR:[%3s] P:[%8.2f] G:[%2d] Nm:[%-s]",
                                    E.markrgnindexnumber,(E.enabled and "*" or " "),
                                    (E.isrgn and "yes" or "no"),E.pos,E.group,E.name));
        return output;
    end
    
    -- Get separate structures for the Markers and the regions
    function JP_functionsModuleLib.extraxtAllMarkersAndRegions()      
        -- Get the number of markers and regions
        local numMarkersAndRegions, num_markers, num_regions  = reaper.CountProjectMarkers()
        -- Separate Markers and Regions into different databases
        local M, m = {},0;--marker database index 
        local R, r = {},0;;--region database index
        -- Loop over all entries and separate them by type
        for i =0,(numMarkersAndRegions) do
            local E = JP_functionsModuleLib.getMarkerOrRegionEntry(i);
            if E.isrgn then
                R[r] = E; r=r+1;
            else
                M[m] = E; m=m+1;
            end
        end

               -- Display all marker and region entries
               -- Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
               -- printTable(R)
               -- Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
               -- printTable(M)
               -- Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
             
             -- boolean reaper.SetProjectMarker3(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name, integer color)
             
               -- boolean reaper.SetProjectMarker (                 integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name)
               -- boolean reaper.SetProjectMarker2(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name)
               -- boolean reaper.SetProjectMarker4(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name, integer color, integer flags)
             -- color should be 0 to not change, or ColorToNative(r,g,b)|0x1000000, flags&1 to clear name
             
             
               -- boolean reaper.SetProjectMarkerByIndex (ReaProject proj, integer markrgnidx, boolean isrgn, number pos, number rgnend, integer IDnumber, string name, integer color)
               -- boolean reaper.SetProjectMarkerByIndex2(ReaProject proj, integer markrgnidx, boolean isrgn, number pos, number rgnend, integer IDnumber, string name, integer color, integer flags)

        --Differs from SetProjectMarker4 in that markrgnidx is 0 for the first marker/region, 1 for the next, etc (see EnumProjectMarkers3), rather than representing the displayed marker/region ID number (see SetProjectMarker3). Function will fail if attempting to set a duplicate ID number for a region (duplicate ID numbers for markers are OK). , flags&1 to clear name.
        JP_functionsModuleLib.Debug(string.format("Do:Extracted markers and regions database: Markers[%d] Regions[%d]",
                                                  num_markers,num_regions));
        -- Retrun both database structures/arrays
        return M,R;-- Return the marker and region database
    end

   

---------------------------------------------
--[[ FUNCTIONS SECTION 5: Entry Functions]]--
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


---------------------------------------------------------------
--[[ FUNCTIONS SECTION 5: Table export and import Functions]]--
---------------------------------------------------------------


-- This code is from: http://lua-users.org/wiki/SaveTableToFile
--[[
   Save Table to File
   Load Table from File
   v 1.0
   
   Lua 5.2 compatible
   
   Only Saves Tables, Numbers and Strings
   Insides Table References are saved
   Does not save Userdata, Metatables, Functions and indices of these
   ----------------------------------------------------
   table.save( table , filename )
   
   on failure: returns an error msg
   
   ----------------------------------------------------
   table.load( filename or stringtable )
   
   Loads a table that has been saved via the table.save function
   
   on success: returns a previously saved table
   on failure: returns as second argument an error msg
   ----------------------------------------------------
   
   Licensed under the same terms as Lua itself.
]]--
do
   -- declare local variables
   --// exportstring( string )
   --// returns a "Lua" portable version of the string
   local function exportstring( s )
      return string.format("%q", s)
   end

   --// The Save Function
   function JP_functionsModuleLib.table_save(  tbl,filename )
      local charS,charE = "   ","\n"
      local file,err = io.open( filename, "wb" )
      if err then return err end

      -- initiate variables for save procedure
      local tables,lookup = { tbl },{ [tbl] = 1 }
      file:write( "return {"..charE )

      for idx,t in ipairs( tables ) do
         file:write( "-- Table: {"..idx.."}"..charE )
         file:write( "{"..charE )
         local thandled = {}

         for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
               if not lookup[v] then
                  table.insert( tables, v )
                  lookup[v] = #tables
               end
               file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
               file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
               file:write(  charS..tostring( v )..","..charE )
            end
         end

         for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then
            
               local str = ""
               local stype = type( i )
               -- handle index
               if stype == "table" then
                  if not lookup[i] then
                     table.insert( tables,i )
                     lookup[i] = #tables
                  end
                  str = charS.."[{"..lookup[i].."}]="
               elseif stype == "string" then
                  str = charS.."["..exportstring( i ).."]="
               elseif stype == "number" then
                  str = charS.."["..tostring( i ).."]="
               end
            
               if str ~= "" then
                  stype = type( v )
                  -- handle value
                  if stype == "table" then
                     if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                     end
                     file:write( str.."{"..lookup[v].."},"..charE )
                  elseif stype == "string" then
                     file:write( str..exportstring( v )..","..charE )
                  elseif stype == "number" then
                     file:write( str..tostring( v )..","..charE )
                  end
               end
            end
         end
         file:write( "},"..charE )
      end
      file:write( "}" )
      file:close()
   end
   
   --// The Load Function
   function JP_functionsModuleLib.table_load( sfile )
      local ftables,err = loadfile( sfile )
      if err then return _,err end
      local tables = ftables()
      for idx = 1,#tables do
         local tolinki = {}
         for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
               tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
               table.insert( tolinki,{ i,tables[i[1]] } )
            end
         end
         -- link indices
         for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
         end
      end
      return tables[1]
   end
-- close do
end

-- ChillCode

---


-----------------------------------------------------
-- Some other code from another site:

--  require("json")
--  
--  databaseFilePath=(reaper.GetResourcePath().."/Scripts/JP_Scripts/tmp/".."exportedTempFileabc.txt");
--      
--  result = {
--      ["ip"]="192.168.0.177",
--      ["date"]="2018-1-21",
--  }
--  
--  function exportTable(exportTable,filepath)
--      local test = assert(io.open(filepath, "w"))
--      exportTable = json.encode(exportTable)
--      test:write(exportTable)
--      test:close()
--  end
--  
--  function importTable(filepath)
--      local test = io.open(filepath, "r")
--      local readjson= test:read("*a")
--      local table =json.decode(readjson)
--      test:close()
--      return table;
--  end


--------------------------------
--[[ RETURN MODULE NAMESPACE]]--
--------------------------------
return JP_functionsModuleLib	