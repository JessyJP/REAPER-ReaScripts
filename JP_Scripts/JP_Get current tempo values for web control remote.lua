--[[
   * ReaScript Name: JP-LivePerfromSetup.lua
   * Description: Lua script for Cockos REAPER. 
   *              This is script computes the tempo updates and exports them to the web clients.
   *         
   * Author: JessyJP
   * Author URI: ....
   * Licence: GPL v3
   * Version: 2.0
--]]
 
 --[[ DEFINED PARAMETER CONSTANTS]]--
 
   local DEBUG_ON    = false;
   local projectInd  = 0; -- the current project index
   local var_section = "CustomWebInterfaceWithTempo"; -- for the MASTER track
   local tempoEnvelopeName  = "Tempo map";
   -- These are the keys for the variables in the HTML file
   local htmlKey_tempo       = "TEMPOSSTRING"; 
   local htmlKey_refreshHz   = "HZ_REFRESH"; 
   local htmlKey_numClients  = "NUM_CLIENTS";
   local htmlKey_clientDelta = "CLIENTDELTA";
 
---------------------------------------------------------------------------------------------------
--[[ FUNCTIONS ]]--

  -- Debug function - display messages in the console
  function Debug(String)
    if(DEBUG_ON) then
      reaper.ShowConsoleMsg(tostring(String).."\n")
    end
  end
  
  -- GET/SET the number of web clients
  function getNumClients()
    return tonumber(reaper.GetExtState(var_section, htmlKey_numClients ));
  end
  
  function setNumClients(numClients)
        reaper.SetExtState(var_section, htmlKey_numClients ,tonumber(numClients),false);
  end
  
  -- GET/SET the change in the number of clients
  function getClientsDelta()
    return tonumber(reaper.GetExtState(var_section, htmlKey_clientDelta ));
  end
  
  function setClientsDelta(cDelta)
        reaper.SetExtState(var_section, htmlKey_clientDelta ,tonumber(cDelta),false);
  end
  
  -- GET function for the refresh rate
  function getRefreshRate()
	return tonumber( reaper.GetExtState(var_section, htmlKey_refreshHz) );
  end
  
  
  -- Math rounding method
  function round(num)
	return math.floor(num + 0.5)
  end
  
  function wholeFloatToInt(num)
  	-- Check if num is a whole number
  	if num % 1 == 0 then
  		return math.floor(num)  -- Return as integer if whole number
  	else
		return num  -- Return as-is if float
  	end
  end

  
---------------------------------------------------------------------------------------------------
--[[ MAIN function ]]--

  -- The main function that gets the tempo/bpm and sets the states of a variable
  function Main_updateTempoInfo()
      
    -- Get Project Tempo
    local project_bpm, bpi = reaper.GetProjectTimeSignature2(projectInd)
    local playrate = reaper.Master_GetPlayRate();
    -- Get the tempo for the cursor
    local tempo_edit_cursor = "x";
    -- If the the playback is stopped, the play-head is at the cursor position
    local tempo_palyhead = "x";
    
    -- Get the tempo envelope on the master track and the number of tempo points
    local envelope = reaper.GetTrackEnvelopeByName(reaper.GetMasterTrack(projectInd), tempoEnvelopeName)
    local envelope_point_count = reaper.CountEnvelopePoints(envelope)
	
	-- Format the project bpm
	project_bpm = wholeFloatToInt(project_bpm);
    
    -- Only if the tempo envelope contains points
    if envelope_point_count > 0 then
      -- Get tempo at edit cursor
      tempo_edit_cursor = reaper.Master_GetTempo();
      -- The decimal places in the webpage therefore the floored number should be enough
      tempo_edit_cursor = round(tempo_edit_cursor);
    
      -- Get the tempo(effective BPM) at the play-head time
      if (reaper.GetPlayState() == 1) then  
    
      
        -- Get the variables and parameters needed
        local playPositionTime   = reaper.GetPlayPosition();
        
        -- Get the two versions
        tempo_palyhead_pt_index = reaper.GetEnvelopePointByTime(envelope,playPositionTime);
        tempo_palyhead = reaper.TimeMap_GetDividedBpmAtTime(playPositionTime);
        tempo_palyhead = round(tempo_palyhead)
        
        -- current_bpm = reaper.TimeMap_GetDividedBpmAtTime(cursor)
        if DEBUG_ON then
        Debug("[envelope  ]:"..tostring(envelope));
        Debug("[playPositionTime  ]:"..tostring(playPositionTime));
        end
      end
    
    end
    -- Compose Output
    local OutputString = tostring(project_bpm).."_"..
                         tostring(tempo_edit_cursor) .. "_".. 
                         tostring(tempo_palyhead) .. "_".. 
                         tostring(playrate);
                   
    -- Set the array state variable state
    reaper.SetExtState(var_section, htmlKey_tempo ,OutputString,false);
  
    --
    --[[ DEBUG OUTPUT ]]--
    --
    if DEBUG_ON then
      local OSCmessage1 = "TEMPO\t" .. project_bpm;
      local OSCmessage2 = "TEMPO\t" .. tempo_edit_cursor;
      local OSCmessage3 = "TEMPO\t" .. tempo_palyhead;
      local OSCmessage4 = "TEMPO\t" .. playrate;
      Debug("------------------------------");
      Debug("[project_bpm  ]:"..OSCmessage1);
      Debug("[tempo_edit_cursor  ]:"..OSCmessage2);
      Debug("[tempo_palyhead  ]" ..OSCmessage3);
      Debug("[playrate  ]" ..OSCmessage4);
      Debug("[OutputString  ]" ..OutputString);
    end
  end
  
---------------------------------------------------------------------------------------------------
  
  Debug("Current num ["..tostring(getNumClients()).."] "..
      "Current delta["..tostring(getClientsDelta()).."]");
  --[[ CALL THE MAIN FUNCTION PERIODICALLY]]--
  -- Get the number of clients and increment or decrement
  if (getNumClients() == nil) then -- This is the first instance of the script
     -- Initialize the tempo string
     reaper.SetExtState(var_section, htmlKey_tempo ,"\u{00A0}_x_x_1",false); -- "999_999_999_999"
	 reaper.SetExtState(var_section, htmlKey_refreshHz ,tonumber(20),false);
     setNumClients(1);
  else
     setNumClients(tonumber(getNumClients())+tonumber(getClientsDelta()));
  end
  setClientsDelta(0);

  
  if getNumClients() == 1 then
  
      -- VARIABLES: Initial values for call and timing. Global variables
      callCount  = 0; -- call counter
      startTimer=reaper.time_precise();-- Initial
      timeOut = 1/getRefreshRate();-- Initialize the refresh rate
      
      function runloop()
        
            -- Call the main
            if (reaper.time_precise()-startTimer >= timeOut) then
              -- Reset the timer
              startTimer= reaper.time_precise();
              -- Update the refresh rate
              timeOut = 1/getRefreshRate();
              -- Show some debug info
              if DEBUG_ON then
                  reaper.ClearConsole()
                  Debug("Number of clients["..getNumClients().."]");
                  Debug("Call ["..callCount.."]");
                  Debug("Refresh Rate Hz["..getRefreshRate().."]");
          Debug("Current delta["..tostring(getClientsDelta()).."]");
              end
              -- Call the main function to update the tempos
              Main_updateTempoInfo();
              -- Update the Call count
              callCount = callCount +1; 
            end

            if getNumClients() then
              reaper.defer(runloop);
            else
              Debug("All clients Disconnected!");
            end
      
      end
      
      -- call the runloop function directly to start the loop
      --reaper.defer(runloop); 
      runloop();
      Debug("Custom Web Remote is now running!");

  else 
      Debug("------------------------------");
      Debug("Current Number of clients["..getNumClients().."]");
      Debug("Custom Web Remote is already running!");
      Debug("New instance will not run!");
      Debug("------------------------------");
  end
