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
   local envelopeNm  = "Tempo map";
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
  
---------------------------------------------------------------------------------------------------
--[[ MAIN function ]]--

  -- The main function that gets the tempo/bpm and sets the states of a variable
  function Main_updateTempoInfo()
      
    -- Get Porject Tempo
    local project_bpm, bpi = reaper.GetProjectTimeSignature2(projectInd)
    -- Get the tempo for the cursor
    local tempo_cursor = reaper.Master_GetTempo();
    -- If the the playback is stopped, the playhead is at the cursor position
    local tempo_palyhead = tempo_cursor;
    local tempo_palyhead_effectiveBMP = tempo_palyhead;
    
    
    -- Get the tempo(effective BPM) at the play-head time
    if reaper.GetPlayState() == 1 then  
      -- Get the variables and parameters needed
      local envelope = reaper.GetTrackEnvelopeByName( reaper.GetMasterTrack(projectInd), envelopeNm);
      local playPositionTime   = reaper.GetPlayPosition();
      
      -- Get the two versions
      tempo_palyhead = reaper.GetEnvelopePointByTime(envelope,playPositionTime);
      tempo_palyhead_effectiveBMP = reaper.TimeMap_GetDividedBpmAtTime(playPositionTime);
      
      -- If the evelope is empty then 
      if (tempo_palyhead == -1) then
        tempo_palyhead = tempo_cursor;
      end 
        
     -- current_bpm = reaper.TimeMap_GetDividedBpmAtTime(cursor)
      if DEBUG_ON then
        Debug("[envelope  ]:"..tostring(envelope));
        Debug("[playPositionTime  ]:"..tostring(playPositionTime));
      end
    end
    
    -- Compose Output
    -- The decimal places in the webpage therefore the floored number should be enough
    tempo_cursor = math.floor(tempo_cursor);
    tempo_palyhead = math.floor(tempo_palyhead);
    local OutputString = tostring(project_bpm).."_"..
                         tostring(tempo_cursor) .. "_".. 
                         tostring(tempo_palyhead) .. "_" ..
                         tostring(tempo_palyhead_effectiveBMP);
                   
    -- Set the array state variable state
    reaper.SetExtState(var_section, htmlKey_tempo ,OutputString,false);
  
    --
    --[[ DEBUG OUTPUT ]]--
    --
    if DEBUG_ON then
      local OSCmessage1 = "TEMPO\t" .. project_bpm;
      local OSCmessage2 = "TEMPO\t" .. tempo_cursor;
      local OSCmessage3 = "TEMPO\t" .. tempo_palyhead;
      local OSCmessage4 = "TEMPO\t" .. tempo_palyhead_effectiveBMP;
      Debug("------------------------------");
      Debug("[project_bpm  ]:"..OSCmessage1);
      Debug("[tempo_cursor  ]:"..OSCmessage2);
      Debug("[tempo_palyhead]:"..OSCmessage3);
      Debug("[tempo_palyhead_effectiveBMP  ]" ..OSCmessage4);
      Debug("[OutputString  ]" ..OutputString);
    end
  end
  
---------------------------------------------------------------------------------------------------
  
  --[[ CALL THE MAIN FUNCTION PERIODICALLY]]--
  -- Get the number of clients and increment or decrement
  if (getNumClients() == nil) then -- This is the first instance of the script
     Debug("Current num ["..tostring(getNumClients()).."] "..
           "Current Deleta["..tostring(getClientsDelta()).."]");
     setNumClients(1);
  else
    Debug("Current num ["..tostring(getNumClients()).."] "..
          "Current Deleta["..tostring(getClientsDelta()).."]")
     setNumClients(getNumClients()+1);
  end
  setClientsDelta(0);

  
  if getNumClients() == 1 then
  
      -- VARIABLES: Initial values for call and timing timing
      callCount  = 0; -- call counter
      startTimer=reaper.time_precise();-- Initia
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
          Debug("Current Deleta["..tostring(getClientsDelta()).."]");
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
