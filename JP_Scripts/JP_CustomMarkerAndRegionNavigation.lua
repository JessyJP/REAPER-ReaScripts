--[[
   * ReaScript Name: Custom Navigation by Layer 1 Marker/Region and Layer 2 Marker/Region
   * Lua script for Cockos REAPER
   * Author: JessyJP
   * Author URI: ....
   * Licence: GPL v3
   * Version: 1.0
--]]
--
--[[ CUSTOMIZABLE VARIABLES ]]--
--
--tag = ""
DEBUG_ON=true;
projectInd = 0;
trackSelectInd = 2;

--
--[[ FUNCTIONS ]]--
--
  -- Debug function - display messages in the console
  function Debug(String)
    if(DEBUG_ON) then
      reaper.ShowConsoleMsg(tostring(String).."\n")
    end
  end
  
  -- Debug function - display all inputs in the console
  function displayInputs()
    if (DEBUG_ON) then
      Debug("Input Variables");
      Debug("-------------------------------------");
      Debug("projectInd:" .. tostring(projectInd));
      Debug("trackSelectInd:" .. tostring(trackSelectInd));
      Debug("FXselection:" .. tostring(FXselection));
      Debug("paramSelection:" .. tostring(paramSelection));
      Debug("curTime:" .. tostring(time));
      Debug("markerIdx:" .. tostring(markerIdx));
      Debug("regionIdx:" .. tostring(regionIdx));
      Debug("mediaTrack" .. tostring(mediaTrack));
      Debug("-------------------------------------");
    end
  end
  
  -- Debu function to display array raw content in in console
  function DebugArray(Array)
    for index, value in ipairs(Array) do
      reaper.ShowConsoleMsg("["..tostring(index).."] = "..tostring(value).."\n")
    end
  end
  
  
  
  
--------------------------------------------------------------------------------
  -- this function allow you to remove duplicates entries in an array
  function removeDuplicates(array)
    local flags = {}
    local expurgatedArray = {}
    local j=1
    for i=1,#array do
       if not flags[array[i]] then
        flags[array[i]] = true
        expurgatedArray[j]=array[i]
        j=j+1
       end
    end
  return expurgatedArray
  end
  

--
--[[ CORE ]]--
--
function Main()
  -- Get HWND
  hwnd = reaper.MIDIEditor_GetActive()
  --Debug(hwnd)
  -- Get current take being edited in MIDI Editor
  take = reaper.MIDIEditor_GetTake(hwnd)
  --Debug(take)

  -- Loop through each selected note
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take) -- count all notes(events)
  i = 0
  check = 0
  notes_selected=0
  chordArray={}
  chordArrayParsed={}
  chordArrayKey=1

  for i=0, notes-1 do
     retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
     if sel == true then -- find which notes are selected 
       if pitch ~= nil then
      --Debug("pitch = "..pitch)
      --get note basic numbers (between 1 and 12)
      noteBasicNumber = (pitch % 12)+1 --we add +1 because noteReferenceTable table count start to 1
      --Debug(noteBasicNumber)
      chordArray[chordArrayKey]=noteReferenceTable[noteBasicNumber] --same here table count start to 1 isntead of 
      --Debug(chordArray[i])
      --Debug(chordArrayKey)
      chordArrayKey=chordArrayKey+1
         
       end
     end
     i=i+1
     --Debug("loop =".. i) -- print to console to check how many loop goes (even if item not selected)*
     
  end
  --DebugArray(chordArray)
  chordArrayParsed = removeDuplicates(chordArray)
  DebugArray(chordArrayParsed)
end
-----------------------------------------------------------------------------------------


--
--[[ EXECUTION ]]--
--

-- clear console debug
reaper.ClearConsole() 

FXselection = 3;
paramSelection = 1;

-- Get Variables
curTime = reaper.GetCursorPosition();
markerIdx, regionIdx = reaper.GetLastMarkerAndCurRegion(projectInd,curTime);
selected_trk = reaper.GetSelectedTrack( projectInd, trackSelectInd );





--paramVal = reaper.TrackFX_GetParam(mediaTrack,FXselection,paramSelection);



-- Disaply Input variables
displayInputs();
Debug("selected_trk:" .. tostring(selected_trk));
Debug("tracknumber:" .. tostring(tracknumber));

selected_trk = reaper.GetTrack( projectInd, trackSelectInd )
tracknumber = reaper.GetMediaTrackInfo_Value(selected_trk, 'IP_TRACKNUMBER')
reaper.ShowConsoleMsg(tracknumber)
val = reaper.GetMediaTrackInfo_Value(selected_trk,"P_NAME")
Debug("val:" .. tostring(val));



reaper.GoToRegion(0,1,true)
reaper.GoToRegion(0,2 ,true)
reaper.GoToRegion(0,1 ,true)

--reaper.PreventUIRefresh(1)
--reaper.GetProjectTimeOffset(
--reaoer.gettrac
-- Begining of the undo block. Leave it at the top of your main function.
--reaper.Undo_BeginBlock() 

-- execute script core
--Main()
 
-- End of the undo block. Leave it at the bottom of your main function.
--reaper.Undo_EndBlock("put here undo message", - 1) 
  
-- update arrange view UI
--reaper.UpdateArrange()

--reaper.PreventUIRefresh(-1)
