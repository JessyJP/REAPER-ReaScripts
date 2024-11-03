const colour_tempo 		 = "#A8A8A8";
const colour_edit_cursor = "#00D9FF";
const colour_playhead	 = "#F2B43F";
const colour_playrate 	 = "#03FC98";

// Load function to initialize client state
function initializeState() {
    // console.log("Start tempo taker!");

	// --- Global configurations ---
	var runHz = 20;
	var tempoRefreshRateMS = Math.round(1000 / runHz);
	// Set refresh rate state
    wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/HZ_REFRESH/" + runHz);
    
	//<!-- This will keep track of the clients -->
    // Set client delta state
    wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/CLIENTDELTA/1");
    
    // Initialize tempo string if not updated yet
    wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/TEMPOSSTRING/999_999_999_999");
    
    // Start recurring tempo requests
    wwr_req_recur("GET/EXTSTATE/CustomWebInterfaceWithTempo/TEMPOSSTRING", tempoRefreshRateMS);
    
    // Call Reaper script
    wwr_req("_RS68f620116facd7f78ad316646f7d04d4f8daf464;");
	
	
	// Set colours (
	setFillColor("tempo_current"), colour_tempo;
	setFillColor("project_bpm"), colour_tempo;
	setFillColor("tempo_edit_cursor"), colour_edit_cursor;
	setFillColor("playrate"), colour_playrate;
}

// Unload function to perform cleanup when page is closed or refreshed
function cleanupState() {
    console.log("Cleaning up client state...");
    
    // Reset client delta or any other cleanup actions
    wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/CLIENTDELTA/-1");
    
    // Optionally clear other states or stop recurring functions if needed
    // clearTimeout(wwr_req_recur);  // Example if you need to stop recurring requests
}

// --- Display method --- 
function displayTempoValues(token){
	if (token[2] == "TEMPOSSTRING")
	{
		// <!-- Get the Tempo array String and delimit the values -->
		tempoValues = token[3];
		tempoValues = tempoValues.split("_");
		// Get tempo variables
		var projectBPM  	= tempoValues[0];
		var tempoEditCursor = tempoValues[1];
		var tempoPlayhead 	= tempoValues[2];
		var playrate 	  	= tempoValues[3];
		
		if (tempoEditCursor == "x")
		{
			// Only project tempo with no tempo envelope
			document.getElementById("tempo_current").textContent = padTo4Chars(projectBPM);
			document.getElementById("project_bpm").textContent = "";
			document.getElementById("tempo_edit_cursor").textContent = "";
			setFillColor("tempo_current", colour_tempo);
		}
		else{
			// Has tempo envelope but not playing
			document.getElementById("project_bpm").textContent = "["+projectBPM+"]";
			if (tempoPlayhead == "x")
			{
				document.getElementById("tempo_current").textContent = padTo4Chars(tempoEditCursor);
				document.getElementById("tempo_edit_cursor").textContent = "";
				setFillColor("tempo_current", colour_edit_cursor);
			}
			else
			{
				document.getElementById("tempo_current").textContent = padTo4Chars(tempoPlayhead);
				document.getElementById("tempo_edit_cursor").textContent = "| "+tempoEditCursor;
				setFillColor("tempo_current", colour_playhead);
			}
		}
		
		
		// Set the playrate if different from unity
		if (playrate != 1 ){document.getElementById("playrate").textContent = "("+playrate+")";}
		else {document.getElementById("playrate").textContent = "";}
		
	}	
}

function isPlaying() {
    return (last_transport_state & 1) !== 0;
}

// Utility functions
function padTo4Chars(text) {
    if (text.length < 3) {
        return text.padStart(4, '\u00A0'); // \u00A0 is a non-breaking space
    }
    return text;
}

function setFillColor(elementId, color) {
    const element = document.getElementById(elementId);
    if (element && element.style.fill !== color) {
        element.style.fill = color;
    }
}


// Event listeners for page load and unload
window.addEventListener("DOMContentLoaded", initializeState);
window.addEventListener("beforeunload", cleanupState);
