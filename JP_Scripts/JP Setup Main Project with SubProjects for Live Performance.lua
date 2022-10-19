--[[
   * ReaScript Name: JP Setup Main Project with SubProjects for Live Performance.lua
   * Description: Lua script for Cockos REAPER. 
   *                        This is script for Live performance setup.
   *                        
   * Author: JessyJP
   * Author URI: ....
   * Licence: GPL v3
   * Version: 1.0
--]]

------------------------------
--[[ FURTHER DESCRIPTION: ]]--
------------------------------
--
--       This script automates number of actions and processes for setup of live performance.
--       --- Main project:
--               We Assume that there is a main project and multiple subprojects with various parts
--          that will be imported. The main project connects with the audio interface in a standard way.
--               That is to say the main project is the audio router, can plays virtual instruments and MIDI,
--               handles navigation. All hardware sends are routed by the main(is the master of all!). Main can 
--                record and more importantly play back song parts sequentially or or non-sequentially via smooth seek.
--               An empty main project is just a ready setup for live performance with no backing or automation.
--
--       --- Subproject: (i.e. songs, backing tracks)
--               The subprojects contain all backing tracks, midi, cues, preset changes etc. When imported 
--                anything that will not be changed during the live performance should be rendered to audio. 
--               This is a feature of the subprojects. 
--               Anything that might changed or is not audio, i.e. MIDI, video or other data can imported to 
--                the main. The subproject will have one master bus (master sub-group routed to hardware) for 
--                normal use for making the song and processing etc. just like any usual DAW project and workflow. 
--               The (actual master bus) will be a multichannel master bus, therefore each pair is a subgroup 
--               according to your need and the template and hardware you have.
--               * Technically, the subproject master bus pair can be the usual first pair, while the rest of the pairs 
--                 are the sub-group.
--               * Technically, the subproject can run in the background and be in sync with the main playback. 
--
--       --- Notes & purpose of this script:
--               After all what this script aims to do is import what can and should be imported and reduce FX processing.
--               Render is should be preferable for most things. In case something small needs to be added or routed on top: 
--               - In that case MIDI can be routed via external virtual MIDI cable. 
--               - For audio there is also ReaRoute.
--               - Other data or video (if possible) can be routed via plug-ins, if that is really necessary.
--
--       --- Template:
--                             The key part here is that the main and the sub(s) inherit from common template. Think inheritance in programming!
--               This is the template determines how many channels there are, which is of course depended on the 
--               the available hardware sends and how many channels the musicians want to mix on stage.
--               Well, ... things can be customized, so whether we import multichannel sub-project project and 
--                  render/play-along or multichannel wav file both allow us flexibility with reduced complexity.
--                                    Some musicians might not want to mix anything and just want all instrumentals to single fader subgroup. 
--                                    Other will be in between, as per instrument or group of instruments.
--                      Rare few might want granular control over individual instruments/sound source (go for it if you can manage).
--               - Generally: 
--                                   Drums & Bass can be separate or together sub-grouped. String/pads and all other harmony synths
--                        can be grouped together. Maybe along with the pads we can group extra sounds and on-off sounds clips.
--                        The keyboards and pianos can be grouped together. Any guitars together. Brass and woodwind together.
--                                   Other sections or sporadic sounds all in one subgroup or added to on of the other ones.
--                        Reasonable any song could be grouped with up to 8 stereo sub-groups or less, but that is very depended on 
--                        what the project calls for. 
--        --- Final thoughts
--               The live mix will always be mixed in the hardware mixer or the mix-channels routed to the hardware/interface outputs.
--               For streaming and recording we have the DAW's mixer. Reaper's mix can be done in a quiet Room or with headphones.
--               Live mix is mixed on the mixer/interface or mixing desk console etc. 
--                             Any mastering, compressors/limiters or EQ for speaker/room tunings on the output bus will be separate, 
--                             not affect each other and not affect the in-ear stage sub-mixes. +++ EVERYONE IS HAPPY! +++
--

-------------------------------------------
--[[ IMPORT MODULE & VARIOUS FUNCTIONS ]]--
-------------------------------------------

    -- Determine the platform that the script is currently running on.
    local _OS_ , _CPU_ = reaper.GetOS(), "x64";
    if OS == "Win32" or OS == "OSX32" then _CPU_="x32" end;
    -- Load the necesary module
    modulePath=(reaper.GetResourcePath().."/Scripts/JP_Scripts/".."JP_functionsModuleLib.lua");
    package.path = modulePath;
        -- Extra Method: info = debug.getinfo(1,'S');-- what is this ??
        -- Extra Method: script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
    -- Add the module
    require(modulePath)--MM = require'JP_functionsModuleLib' -- "MM" stands for My module
    assert(JP_functionsModuleLib.loaded,"ERROR: Module not found or failed to load! [JP_functionsModuleLib.lua]");
    -- Import the needed subset of module function names(symbols) locally for conveniense.
    local Debug          = JP_functionsModuleLib.Debug;
    local DebugArray     = JP_functionsModuleLib.DebugArray;
    local printTable     = JP_functionsModuleLib.printTable;
    local runAction      = JP_functionsModuleLib.runAction;
    -- Set module varaiables
    JP_functionsModuleLib.DEBUG_ON =true; -- switch for debugging ON for the module functions
    JP_functionsModuleLib.flag     =0; -- is needed for calling some commands
    
-------------------------
--[[ LOCAL VARIABLES ]]--
-------------------------

    -- Local/ effectively global for the namespcae and functions information structure
    local I = {}; -- I stands for info/information.
          I.Description  = "BG Church Bristol Live - Template Setup!";
          I.Author       = JP_functionsModuleLib.Author;
          I.tag          = "";
          I.mainPrjInd   = 0;-- the current project index i.e. the main.
          I.sepRepDisp   = 80;-- This is used for visual separator lenght
    local userParam = {routing = {}, imports = {}};-- Declare a structure
    -- Usually, audio should be mixed and routed in the sub.  
    -- Use this for MIDI, video, lyrics and envelopes. 
    
--================================================================================================
---------------------------------------------
--[[ USER EDITALBE CONTROLLED PARAMETERS ]]--
---------------------------------------------
               
          
    -- User parameters: were you might need to change thing to work with the template.
    userParam.importTrackName ="Song Playback Subproject";-- Track name
    userParam.markerPrefix="SONG=";-- Prefix for the control marker
    -- Usually, the track index starts at "0" also the track might be moved.
    -- The label is unlikely to change in the template.
    userParam.routing[1] = {"1/2","Drums"}          -- Template mapping: "Drums" == 2
    userParam.routing[2] = {"3/4","Keyboard-Piano"} -- Template mapping: "Keyboard-Piano" == 3 
    userParam.routing[3] = {"5/6","Bass"}           -- Template mapping: "Bass" == 4
    userParam.routing[4] = {"7/8","Strings"}        -- Template mapping: "Strings" == 5



    userParam.imports.allTrackItems = {"all","Quelea"}; -- Use this for special tacks.

--[[ USER EDITALBE GUI PARAMETERS ]]--
    -- In this section we con customize the gui
    -- GUI = {showLive} -- RUN LIVE STUFF
    
    --reaper.Main_OnCommand(6,0)
     -- reaper.MB("Tudelu","",0)
     -- reaper.ShowConsoleMsg("I will be shown, after action 6 is run, as reaper.MB pauses the current script, allowing other scripts/actions to run in the background")

-- GUI EXPERIMENTAL STUFF

--================================================================================================

--------------------------------
--[[ BASIC INPUT VALIDATION ]]--
--------------------------------
   
    -- Check if the user input for the import track name is valid
    assert(( type(userParam.importTrackName)=="string"),
            "Error: Invalid input [userParam.importTrackName]."..
            "Please input the name of the import track. ");



-------------------
--[[ FUNCTIONS ]]--
-------------------


    -- Pre setup function to find variables and parameters and check everything
    function setupProjectInfo() -- This should be the first function that is called.
        
        -- Get and Display Project name & file name
        I.projectName = reaper.GetProjectName(I.mainPrjInd);
        Debug("Project Name: " .. I.projectName );
        -- Display the rest of the information stored in the project information table 
        Debug("Description: " .. tostring(I.Description));
        Debug("Author: " .. tostring(I.Author));
        if (I.tag~="") then -- only display if the tag is not empty
            Debug("Tag: " .. tostring(I.tag));
        end
        -- Get and display project filepath
        _, I.filepath = reaper.EnumProjects(-1, '')
        Debug(string.format("Project File: %s", I.filepath));

        -- Get and display track information
        Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
        -- Display Track information
        I.trackCount = reaper.CountTracks(I.mainPrjInd);
        Debug("Track Count: " .. I.trackCount);
        -- Get List of the Tracks with Names, Index and Track identifier
        I.tracks = {};
        for i=0,I.trackCount-1 do
            local tmpTrack = reaper.GetTrack(I.mainPrjInd, i );
            local retVal , tmpTrackName = reaper.GetTrackName(tmpTrack);
            I.tracks[i] = { index=i, obj=tmpTrack, name=tmpTrackName};

            -- Display the track info and index
            Debug(string.format(" |- Track [%2d]: %s",(I.tracks[i].index+1),I.tracks[i].name));    
        end
        Debug(" .");

        -- Locate the subproject import track
        local isSubTrFound=false;
        for i=0,I.trackCount-1 do
        -- Compare track names
            if (I.tracks[i].name == userParam.importTrackName) then
            -- Get assign the data for the import track
                I.importTrack = I.tracks[i];
                I.importTrack.numChannels = reaper.GetMediaTrackInfo_Value(I.tracks[i].obj,"I_NCHAN");
                -- Set the flag
                isSubTrFound=true;
                break;
            end
        end

        -- Validate and check
        if not(isSubTrFound) then
            Debug("Error: Track name not found [userParam.importTrackName]");
            assert(isSubTrFound,"Error: Track name not found [userParam.importTrackName]");
            return false;
        end

        -- Display information for the import track
        Debug(string.format("Import Track[%d] Name:[%s] with [%d] channels",
                            I.importTrack.index+1, 
                            I.importTrack.name, 
                            I.importTrack.numChannels ));


        -- Check the view state of media item cues (i.e. subproject cues)
        Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
        -- "View: Toggle show media cues in items"
        local ShowCuesInItemsCmd = 40691;--"View: Toggle show media cues in items"
        -- If the state is OFF turn it ON
        if (reaper.GetToggleCommandState(ShowCuesInItemsCmd) ~= 1)  then
            runAction("View: Toggle show media cues in items",ShowCuesInItemsCmd);
        end
        Debug(string.format("View: Toggle show media cues in items - State[%s]",
              ((reaper.GetToggleCommandState(ShowCuesInItemsCmd)==1) and "ON" or "OFF")  ));

        -- Prepare function done return true
        return true;
    end
       
    -- Get and display the selected Item info in a table
    function getAndDisplaySelectedItemsInfoInTable()
        -- Output variable
        local subItems = {};      
        local itemCount = reaper.CountSelectedMediaItems(I.mainPrjInd);
        local tableLines = {}; -- Talbe lines are stored here 
        local maxLineSize = 0; -- Max line size needed for the separator
        
        -- Get List of the Tracks with Names, Index and Track identifier
        for i=0,itemCount-1 do
            local item = reaper.GetSelectedMediaItem(I.mainPrjInd, i );
            local isSelected = reaper.IsMediaItemSelected(item);

            -- Colouing  
            reaper.SetMediaItemInfo_Value( item, "I_CUSTOMCOLOR",
            reaper.ColorToNative(math.random(255),math.random(255),math.random(255))|0x1000000 );
            -- Get active take
            local takeH = reaper.GetActiveTake(item);

            -- Put the info into a data structure
            subItems[i] = 
                {   -- Item info
                    IP_ITEMNUMBER = reaper.GetMediaItemInfo_Value(item,"IP_ITEMNUMBER"),
                    D_POSITION    = reaper.GetMediaItemInfo_Value(item,"D_POSITION"),
                    D_LENGTH      = reaper.GetMediaItemInfo_Value(item,"D_LENGTH"),
                    C_LOCK        = reaper.GetMediaItemInfo_Value(item,"C_LOCK"),
                    colour        = reaper.GetDisplayedMediaItemColor(item),
                    -- Take info
                    take          = reaper.GetActiveTake(item),-- Assume single take per item that's active
                    src           = reaper.GetMediaItemTake_Source(takeH),
                    takeName      = reaper.GetTakeName(takeH)
                };
            subItems[i].fileName        = reaper.GetMediaSourceFileName(subItems[i].src, "");
            subItems[i].mediaSourceType = reaper.GetMediaSourceType(subItems[i].src, '');-- 'RPP_PROJECT'
            subItems[i].group  = math.floor(subItems[i].IP_ITEMNUMBER)+1;-- Assign a group to each item
            -- ... GetSubProjectFromSource(...)

                 -- This section below is in case more fields are needed for processing.
                   --??
                   -- GetSetMediaItemInfo_String 
                 --- ---------------------   
                 ---- Lua: number reaper.GetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname)
                 ---- 
                 ---- Get media item take numerical-value attributes.
                 ---- D_STARTOFFS : double * : start offset in source media, in seconds
                 ---- D_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped
                 ---- D_PAN : double * : take pan, -1..1
                 ---- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
                 ---- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
                 ---- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
                 ---- B_PPITCH : bool * : preserve pitch when changing playback rate
                 ---- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
                 ---- I_LASTH : int * : height in pixels (read-only)
                 ---- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
                 ---- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
                 ---- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
                 ---- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
                 ---- P_TRACK : pointer to MediaTrack (read-only)
                 ---- P_ITEM : pointer to MediaItem (read-only)
                 ---- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.


            -- Display item info in a row
            tableLines[i] = string.format("| %d | %s | %4d | %8.2f | %.2f | %40s |",                  
                                           subItems[i].IP_ITEMNUMBER+1,
                                           subItems[i].colour,
                                           subItems[i].C_LOCK,
                                           subItems[i].D_POSITION,
                                           subItems[i].D_LENGTH,
                                           subItems[i].takeName);
            -- Get the max line size
            if (maxLineSize < string.len(tableLines[i])) then maxLineSize = string.len(tableLines[i]); end                      
                       
            -- NB: not sure exactly what it updates!
            reaper.UpdateItemInProject(item);
        end    

        -- Display the selected items in a formatted table
        local PS=" "; -- Stands for Prefix Space
        Debug("Selected Item Count: " .. itemCount);
        Debug(PS..string.rep("-", maxLineSize));-- "-" make a separator
        Debug(PS..string.format("| %s | %8s | %s | %s | %s | %40s |", 
              "#","Colour", "Lock", "Position", "Lenght", "Take Name" ));
        Debug(PS..string.rep("-", maxLineSize));-- "-" make a separator
        for i = 0,itemCount-1 do Debug(PS..tableLines[i]); end
        Debug(PS..string.rep("-", maxLineSize));-- "-" make a separator
        
        -- Return the two output variables
        return subItems, itemCount;
    end
        
    -- Extract a marker or region for the current project by index
    function getMarkerOrRegionEntry(index)
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
    function addMarkerOrRegionEntry(E)
        output = reaper.AddProjectMarker(I.mainPrjInd,E.isrgn, E.pos, E.rgnend, E.name, E.markrgnindexnumber);
        Debug(string.format(" |- AddProjectMarker I:[%2d] On:[%1s] IsR:[%3s] P:[%8.2f] G:[%2d] Nm:[%-s]",
                            E.markrgnindexnumber,(E.enabled and "*" or " "),
                            (E.isrgn and "yes" or "no"),E.pos,E.group,E.name));
        return output;
    end
    
    -- Get separate structures for the Markers and the regions
    function extraxtAllMarkersAndRegions()      
        -- Get the number of markers and regions
        local numMarkersAndRegions, num_markers, num_regions  = reaper.CountProjectMarkers()
        -- Separate Markers and Regions into different databases
        local M, m = {},0;--marker database index 
        local R, r = {},0;;--region database index
        -- Loop over all entries and separate them by type
        for i =0,(numMarkersAndRegions) do
            local E = getMarkerOrRegionEntry(i);
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
        Debug(string.format("Do:Extracted markers and regions database: Markers[%d] Regions[%d]",
                            num_markers,num_regions));
        -- Retrun both database structures/arrays
        return M,R;-- Return the marker and region database
    end
   
    -- Group, reindex and rename the markers
    function groupAndReindexAllMarkers(I)
        -- Put a separator here
        Debug(string.rep("-", 30));-- "-" make a separator
        Debug("Do:Edit all project markers and add to project after:");
        Debug(" |= Do:Group all markers and regions in the database by their subproject group");
        Debug(" |= Do:Reindex all markers such that:");
        Debug(" |== Do: the prexfixed with ["..userParam.markerPrefix.."] first.");
        Debug(" |== Do: the non-prexfixed are indexed after according their intiaial order(time position).");        
        Debug(" |= Do:Rename prefixed markers to ["..userParam.markerPrefix.."\"<Name of Song>\"]");
        Debug(" .");
        -- First step is to assign groups to all markers
        local ext=".rpp";-- the reaper extention
        local smc = 0;--Secondary Marker counter
        local reorderedIndexList = {};
        -- Loop over all subprojects
        for s=0,I.subProjItemCount-1 do
            local subPrI   = I.subProjItems[s];
            local T1       = subPrI.D_POSITION;-- Get the start position of the item 
            local T2       = T1 + subPrI.D_LENGTH;-- Get the end position of the item
            local group    = subPrI.group;-- Get the sub project group
            local takeName = subPrI.takeName;-- Get the take name that will be used in the marker
            takeName = takeName:sub(1, takeName:find(ext, 1, true) - 1);-- Remove the file extention
            -- Show info about the subprojects
                -- Debug(string.rep("-", 30));-- "-" make a separator
                -- Debug("Sub Project Group"..group);
                -- printTable(subPrI);
                -- Debug(string.rep(".", 30));-- "-" make a separator
            
            -- Loop over all markers
            for m=0,((#I.markers)-1) do
                -- If the marker is within the item range
                if  ((T1 <= I.markers[m].pos) and (I.markers[m].pos <= T2)) then
                    -- Assign Group
                    I.markers[m].group = group;
                    -- Locate the Item start/ prefixed marker
                    local n1,n2 = string.find(I.markers[m].name,userParam.markerPrefix);
                    -- If the prefix is matched then the first marker of the sub-proejct item is found
                    if (n1~=nil) then
                        -- Assign the the relevant markrgnindexnumber
                        I.markers[m].markrgnindexnumber = group;
                        -- Compose a name
                        I.markers[m].name = string.format("%s\"%s\"",userParam.markerPrefix,takeName)
                    else
                        -- Keep the marker as is but reindex
                        smc=smc+1;
                        I.markers[m].markrgnindexnumber=I.subProjItemCount+smc;
                    end
                    
                    -- Add Marker entry
                    addMarkerOrRegionEntry(I.markers[m]);
                    
                    -- Get the marker index list
                    reorderedIndexList[m] = I.markers[m].markrgnindexnumber; -- This is the new marker index
                end
            end
            
            -- Loop over all regions
            for r=0,((#I.regions)-1) do
                -- If the region start position is within the item range 
                -- NOTE: The region end could also be considered
                if  ((T1 <= I.regions[r].pos) and (I.regions[r].pos <= T2)) then
                    -- Assign Group
                    I.regions[r].group = group;
                    -- Set as disabled
                    I.regions[r].enabled = false;                    
                    
                    Debug(r);---------------------ahahahahha-
                    --printTable(I.regions[r]);
                end
            end
            
        end
    
        -- We can reorder the table
        --printTable(I.markers);
        --printTalbe(reorderedIndexList);
    end
  
    -- NB: finish me !!!!!!!!!+++++++++?????????????
    function processSubPrjTrackSends()
        Debug(string.rep("-", I.sepRepDisp));-- "-" make a separator
        local track = I.importTrack.TrackObj;
        local name  = I.importTrack.TrackName;
        local numReci = reaper.GetTrackNumSends(track, -1 );
        local numSend = reaper.GetTrackNumSends(track, 0 );
        local numHrwa = reaper.GetTrackNumSends(track, 1 );
        Debug("["..name.."] Receives:"..tostring(numReci))
        Debug("["..name.."] Sends:"..tostring(numSend))
        Debug("["..name.."] Hardware outputs:"..tostring(numHrwa))
        -- returns number of sends/receives/hardware outputs 
        -- category is <0 for receives, 0=sends, >0 for hardware outputs

        -- Disable the send to master
        reaper.SetMediaTrackInfo_Value( track, 'B_MAINSEND', 0 );
        Debug("["..name.."] Disable send to MASTER");
        
        -- Remove Receives
        if (numReci > 0) then
        end
    end


--------------------------------
--[[ MAIN SEQUENCE FUNCTION ]]--
--------------------------------

    function MainSequence()
    --[[ CALL ACTION SEQUENCE IN STEPS ]]--
            local function dsipStep(Step) return string.format("=== Setp %d: ",Step); end
        -- Start an undo block --
            reaper.Undo_BeginBlock()

        -- Step 0: Run pre-setup --
            -- The consol output should be cleared.
            reaper.ClearConsole();
            Debug(dsipStep(0)..string.rep("=", I.sepRepDisp));-- "=" make a separator
            local success = setupProjectInfo();
            assert(success,"ERROR: the project information could not be extracted!");
            if not(success) then return end;

        -- Step 1: Cleaning by removeing all markers regions and tempo --
            Debug(dsipStep(1)..string.rep("=", I.sepRepDisp));-- "=" make a separator
            runAction("Unselect (clear selection of) all tracks/items/envelope points",40769);
            runAction("Time selection: Remove (unselect) time selection and loop points",40020);
            runAction("Clear tempo envelope",42395);
            runAction("SWS: Delete all markers","_SWSMARKERLIST9");
            runAction("SWS: Delete all regions","_SWSMARKERLIST10");

        -- Step 2: Import all cues from all subprojects --
            Debug(dsipStep(2)..string.rep("=", I.sepRepDisp));-- "=" make a separator
            -- Select the subproject track
            reaper.SetOnlyTrackSelected(I.importTrack.obj);
            Debug("Do:SetOnlyTrackSelected:["..I.importTrack.name.."] Index["..(I.importTrack.index+1).."]");
            Debug("Show:Selected Num Tracks:["..reaper.CountSelectedTracks().."]");
            -- Select All Items in the track
            runAction("Item: Select all items in track",40421);
                -- runAction("Item: Select all items",40182); -- This one works too but it's better to be specific
                    -- The imports might be multi-channel *.wav files, so it's better to select the items directly.
                -- runAction("SWS/BR: Select all subproject (PiP) items","_BR_SEL_ALL_ITEMS_PIP");          
            -- Display listed items info and colour
            I.subProjItems, I.subProjItemCount = getAndDisplaySelectedItemsInfoInTable();        
            runAction("Item: Import item media cues as project markers",40692);
            -- Makese sense to remove all selections after the import
            runAction("Time selection: Remove (unselect) time selection and loop points",40020);
            -- Import tempo markers
            Debug(" NB!!!!!!!!!!!!!!!!!!!?????????++++++++NEED TO: Import tempo markers");
              
        -- Setp 3: Extract and process all Markers and Regions
            Debug(dsipStep(3)..string.rep("=", I.sepRepDisp));-- "=" make a separator
            -- Extract All markers and Regions
            I.markers, I.regions = extraxtAllMarkersAndRegions();        
            -- Clear all regions (as we will import only the regions that 
            runAction("SWS: Delete all regions","_SWSMARKERLIST10");
            runAction("SWS: Delete all markers","_SWSMARKERLIST9");
      -- Process the Markers
            groupAndReindexAllMarkers(I);
            Debug(string.rep("=", I.sepRepDisp));-- "=" make a separator
        
            --I.markers =  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        
  -------------- CURRENT PROGRESS ---------------      
            -- printTable(I.markers);  
            -- printTable(I.subProjItems);  
        
              
-- error("HALT!"); ----------------------------      

               
              
        -- Step 4: Process sends on the subproject track sends
            -- processSubPrjTrackSends()
 
             
        -- Setp 5: Show custom toolbars and windows
            -- runAction("Script: X-Raym_Regions clock.lua","_RSbb00ff23c9af247391aedbfac1471c44aaf455b5");
            -- Debug(" !!! This can and should be customized");
       
       
     
        -- Start an undo block --
            reaper.Undo_EndBlock( 'JP - Template setup for live performance - script', -1 )
     
        -- Display script completed
            Debug(string.rep("=", I.sepRepDisp));-- "=" make a separator
            Debug("JP_LivePerformanceSetup - Completed!");
 --[[      

       -- Open the relevant live performance Toolbar !!!
       -----------------
       
 

       -- import

       -- "Tempo envelope: Set display range to current project min/max bpm" 
       reaper.Main_OnCommand(41804, flag );
        
       

       
       integer retval = reaper.NamedCommandLookup(string command_name )
       integer retval = reaper.GetToggleCommandState(integer command_id )

]]--
     
     Debug(" NB!!!!!!!!!!!!!!!!!!!?????????++++++++NEED TO: Make sure all automation is deleted.\n"..
           "Envolpe points are cleard, is there anything else to clean and reset on the tracks?\n"..
           "Afterall this is starting from a template."..
           "But the script might be called more than once on the given project");
  
  end


-------------------
--[[ EXECUTION ]]--
-------------------
  
MainSequence();-- Yup, that's it!

-----------------------------------------------------------------------------------------

--[[-- Useful code that might be used later:

  curTime = reaper.GetCursorPosition();
  markerIdx, regionIdx = reaper.GetLastMarkerAndCurRegion(I.mainPrjInd,curTime);

  paramVal = reaper.TrackFX_GetParam(mediaTrack,FXselection,paramSelection);

  reaper.GoToRegion(0,1,true)
  reaper.GoToRegion(0,2 ,true)
  reaper.GoToRegion(0,1 ,true)

  reaper.PreventUIRefresh(1)
  reaper.GetProjectTimeOffset( ... reaoer.gettrac??? ...
  -- Begining of the undo block. Leave it at the top of your main function.
  reaper.Undo_BeginBlock() 

  -- update arrange view UI
  reaper.UpdateArrange()

  reaper.PreventUIRefresh(-1)

]]--

--[[-- Useful for persistance:

  function SaveExtState( var, val)
    reaper.SetExtState( ext_name, var, tostring(val), true )
  end

  function GetExtState( var, val )
    if reaper.HasExtState( ext_name, var ) then
    local t = type( val )
    val = reaper.GetExtState( ext_name, var )
    if t == "boolean" then val = toboolean( val )
    elseif t == "number" then val = tonumber( val )
    else
    end
    end
    return val
  end
  
]]--
