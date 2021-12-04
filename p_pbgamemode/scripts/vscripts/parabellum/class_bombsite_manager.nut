/*
	class_bombsite_manager.nut
	
	Purpose:
		Creates and contains all of the bombsite instances.
		
	Made by BP for the Parabellum mod.
*/

IncludeScript("parabellum/class_bombsite.nut")

class ::BombsiteManager{
	/*
		Initalizes and contains all of the bombsites for a map.
		Responsible for locking/unlocking, and checking the win state.
	*/

	constructor(){
		InitSites()
	}
	
	rCTSites = []
	rTSites = []
	TEAM_T = 2
	TEAM_CT = 3

	function InitSites(){
		//Finds all instances of trigger_multiples with the targetname "ct" or "t".
		local pTrigger = null
		while(pTrigger = Entities.FindByClassname(pTrigger, "trigger_multiple")){
			//Sites labeled with CT are the T's targets, same with the inverse.
			local strName = pTrigger.GetName().tolower()
			if(strName == "t"){
				rTSites.append(Script.Bombsite(pTrigger, TEAM_CT))
				continue
			}
			if(strName == "ct"){
				rCTSites.append(Script.Bombsite(pTrigger, TEAM_T))
				continue
			}
			continue
		}
		//printl("Found " + rCTSites.len() + " CT sites.")
		//printl("Found " + rTSites.len() + " T sites.")
	}
	
	function CheckWin(){
		//Retuns the team who won or false.
		local intCTCompleted = 0
		local intTCompleted = 0
		foreach(idx, pSite in rTSites){
			if(pSite.IsDestroyed()){
				intCTCompleted++
			}
		}
		foreach(idx, pSite in rCTSites){
			if(pSite.IsDestroyed()){
				intTCompleted++
			}
		}
		
		printl("intCTCompleted: " + intCTCompleted + "\nrTSites.len(): " + rTSites.len())
		
		//printl("T Sites: " + rCTSites.len() + " Destroyed: " + intCTCompleted)
		//printl("CT Sites: " + rTSites.len() + " Destroyed: " + intTCompleted)
		
		if(intTCompleted == rCTSites.len()){
			return TEAM_T
		}
		if(intCTCompleted == rTSites.len()){
			return TEAM_CT
		}
		return null
	}
	
	function GetTSites(){
		//Array of Bombsite()'s
		//These sites are defended by CT's, and attacked by T's
		return rTSites
	}
	
	function GetCTSites(){
		//Array of Bombsite()'s
		//These sites are defended by T's and attacked by CT's
		return rCTSites
	}
	
	function GetPlanted(){
		
		foreach(idx, pSite in rCTSites){
			if(pSite.HasBomber()){
				return pSite
			}
		}
		foreach(idx, pSite in rTSites){
			if(pSite.HasBomber()){
				return pSite
			}
		}
		Assert(false, "Called planted when there are no hot sites!")
	}
	
	function FindBomber(){
		//Bombsite() instance
		foreach(idx, tSite in rTSites){
			if(tSite.HasBomber()){
				return tSite
			}
		}
		foreach(idx, ctSite in rCTSites){
			if(ctSite.HasBomber()){
				return ctSite
			}
		}
		return null
	}
	
	function FindBombsiteWithPlayer(pPlayer){
		//Bombsite() instance
		foreach(idx, tSite in rTSites){
			if(tSite.HasPlayer(pPlayer)){
				//printl("Returning a T target!")
				return tSite
			}
		}
		
		foreach(idx, ctSite in rCTSites){
			if(ctSite.HasPlayer(pPlayer)){
				//printl("Returning a CT target!")
				return ctSite
			}
		}
		return null
	}
	
	function LockBombsites(){
		local pSite = FindBomber()
		if(pSite){
			pSite.LockBombsite()
		}
		return
	}
	
}