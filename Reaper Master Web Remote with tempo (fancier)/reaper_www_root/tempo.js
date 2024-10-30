//<!-- JP edit:1 begin -->
	//<!-- This will keep track of the clients -->
	var clientDelta = 1;
	//<!-- wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/CLIENTDELTA/1")); -->
	clientDelta = -1;
	
	// <!-- Timeout/Refresh Rate-->
	var runHz = 20;
	var tempoRefreshRateMS = Math.round(1000/runHz);
	wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/HZ_REFRESH/"+runHz);
	
	// <!-- This is useful because it will indicate the tempo is not updated properly -->
	wwr_req("SET/EXTSTATE/CustomWebInterfaceWithTempo/TEMPOSSTRING/999_999_999_999");
	// <!-- This will get the tempo from Reaper at regular intervals -->
	wwr_req_recur("GET/EXTSTATE/CustomWebInterfaceWithTempo/TEMPOSSTRING",tempoRefreshRateMS);
	
	// <!-- This calls the reaper script -->
	wwr_req("_RSc99929bd32300e82b11053618eb27000e0bdbefa;");
	// <!-- The call here   -->
	// <!-- wwr_req_recur("_RSc99929bd32300e82b11053618eb27000e0bdbefa;",tempoRefreshRateMS); -->		
		
	
// <!-- JP edit:1 end -->