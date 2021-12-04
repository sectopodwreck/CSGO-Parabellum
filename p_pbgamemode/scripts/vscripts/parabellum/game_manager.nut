/*
	game_manager.nut
	
	Purpose:
		The bread and butter of the whole gamemode.
		This script parses all of the logic_eventlisteners and
		acts accordingly to allow gameplay.
		
		No Think() functions needed!
		
	Made by BP for the Parabellum mod.
	Sorry for writing this slowly ;)
				-BP
*/

Assert(self.GetClassname() == "logic_script", "This script is supposed to be loaded on a logic_script! Stop trying to break my code!")

IncludeScript("parabellum/class_bombsite_manager.nut")
IncludeScript("parabellum/class_bomb_manager.nut")
IncludeScript("parabellum/class_player_manager.nut")
IncludeScript("parabellum/wave_manager.nut")
IncludeScript("parabellum/class_cash.nut")
IncludeScript("parabellum/class_servercommand.nut")

::pGameRule <- null
::Script <- this

::bMultiBomb <- false

if(ScriptGetGameType() == 1){
	//game_type 1 is multi-bomb
	bMultiBomb = True
}

function OnPostSpawn(){
	pGameRule = GameRule()
}

class GameRule{
	/*
		The main instance which drives the gamemode.
	*/

	TEAM_T = 2
	TEAM_CT = 3

	constructor(){
		printl("Initalizing!")
		pC4 = BombManager()
		pSites = BombsiteManager()
		pPlayers = PlayerManager()
		pWave = WaveManager()
		InitEntities()
		InitBuyzones()
		InitScore()	
		//Keep the C4 from being purchasable in warmup. It's possible to finish the game early if all the sites are destroyed before the game starts.
		if(ScriptIsWarmupPeriod()){
			pC4.DisableBuy()
			return
		}
	}
	
	pC4 = null
	pSites = null
	pPlayers = null
	pWave = null
	pScorer = Entities.CreateByClassname("game_score")
	pClientCommand = Entities.CreateByClassname("point_clientcommand")
	pMessage = Entities.CreateByClassname("env_hudhint")
	
	
	/*
		EntityGroup Legend
		
		0: logic_eventlistener (bomb_planted)
		1: logic_eventlistener (bomb_exploded)
		2: logic_eventlistener (bomb_dropped)
		3: logic_eventlistener (bomb_pickup)
		4: logic_eventlistener (item_purchase)
		5: point_template (prop_mapplaced_long_use_entity)
		6: point_template (prop_dynamic_glow)
		7: logic_eventlistener (player_death)
		8: logic_eventlistener (begin_plant_check)
		9: logic_eventlistener (connect_check)
		10: logic_eventlistener (round_freeze_end)
	*/
	pPlantCheck = EntityGroup[0]
	pExplodeCheck = EntityGroup[1]
	pDropCheck = EntityGroup[2]
	pPickupCheck = EntityGroup[3]
	pBuyCheck = EntityGroup[4]
	pC4Template = EntityGroup[5]
	pGlowTemplate = EntityGroup[6]
	pDeathCheck = EntityGroup[7]
	pBeginPlantCheck = EntityGroup[8]
	pConnectCheck = EntityGroup[9]
	pFreezeCheck = EntityGroup[10]

	//TODO ConnectOutput doesn't work.
	
	//Force it to work through hammer I/O

	function InitEntities(){
		foreach(idx, pEnt in Script.EntityGroup){
			pEnt.ValidateScriptScope()
		}
		local pScope = null
		//PlantCheck
		pScope = pPlantCheck.GetScriptScope()
		pScope.pGameRule <- this
		//pPlantCheck.ConnectOutput("OnEventFired", "Planted")
		
		//ExplodeCheck
		pScope = pExplodeCheck.GetScriptScope()
		pScope.pGameRule <- this
		//pExplodeCheck.ConnectOutput("OnEventFired", "Explode")
		
		//DropCheck
		pScope = pDropCheck.GetScriptScope()
		pScope.pGameRule <- this
		//pDropCheck.ConnectOutput("OnEventFired", "UpdateBombs")
		
		//PickupCheck
		pScope = pPickupCheck.GetScriptScope()
		pScope.pGameRule <- this
		//pPickupCheck.ConnectOutput("OnEventFired", "UpdateBombs")
		
		//BuyCheck
		pScope = pBuyCheck.GetScriptScope()
		pScope.pGameRule <- this
		//pBuyCheck.ConnectOutput("OnEventFired", "ItemBought")
		
		//DeathCheck
		//This is needed in order to highlight the bomb from a player who was killed. Fuck bomb_dropped, it doesnt work if a planted bomb has been defused.
		pScope = pDeathCheck.GetScriptScope()
		pScope.pGameRule <- this
		
		//BeginPlantCheck
		//Make sure that the player IS within their bombsite, if they decide to plant on multibomb gamemode.
		pScope = pBeginPlantCheck.GetScriptScope()
		pScope.pGameRule <- this

		//ConnectCheck
		//Helps with finding the player's UserID.
		pScope = pConnectCheck.GetScriptScope()
		pScope.pGameRule <- this

		//FreezetimeCheck
		//Begins the waves after freezetime finishes.
		pScope = pFreezeCheck.GetScriptScope()
		pScope.pGameRule <- this
	}
	
	function InitBuyzones(){
		//Just a test in order to see if it's possible to connect the player to their userid.
		local pBuyzone = null
		
		while(pBuyzone = Entities.FindByClassname(pBuyzone, "func_buyzone")){
			printl("Found Buyzone!")
			pBuyzone.ValidateScriptScope()
			local pScope = pBuyzone.GetScriptScope()
		}
	}
	
	function FreezetimeOver(){
		//Time to play!
		pWave.StartWaves()
	}
	
	function InitScore(){
		//Sets the score to how many sites each team has remaining.
		local intCTSites = pSites.GetCTSites().len()
		local intTSites = pSites.GetTSites().len()
		
		printl(intTSites)
		printl(intCTSites)
		
		SendToConsoleServer("mp_maxrounds " + 2 * (intTSites + intCTSites))
		
		EntFireByHandle(pScorer, "AddOutput", "points " + intTSites, 0, null, null)
		//pScorer.__KeyValueFromInt("points", intCTSites)
		EntFireByHandle(pScorer, "AddScoreTerrorist", "", 0, null, null)
		
		EntFireByHandle(pScorer, "AddOutput", "points " + intCTSites, 0, null, null)
		//pScorer.__KeyValueFromInt("points", intTSites)
		EntFireByHandle(pScorer, "AddScoreCT", "", 0.1, null, null)
	}
	
	function UpdateScore(intTeam, intScoreDiff = -1){
		//intTeam is the attacker, not victim. ie. intTeam = 2 (CT), deduct T by 1
		//intScoreDiff should be what you want to change it by, not to.
		EntFireByHandle(pScorer, "AddOutput", "points " + intScoreDiff, 0, null, null)
		if(intTeam == TEAM_T){
			EntFireByHandle(pScorer, "AddScoreCT", "", 0, null, null)
			return
		}
		if(intTeam == TEAM_CT){
			EntFireByHandle(pScorer, "AddScoreTerrorist", "", 0, null, null)
			return
		}
		Assert(false, "Tried to update score for an unknown team!")
	}

	function PlayerConnect(){
		//Pass this off to the manager.
		local event_data = pConnectCheck.GetScriptScope().event_data

		local intUserId = event_data.userid
		local intIdx = event_data.index + 1

		pPlayers.AddPlayer(intIdx, intUserId)
	}
	
	
	function BeginPlant(){
		//Fired by pBeginPlantCheck
		printl("Beginning to plant!")
		
		local event_data = pBeginPlantCheck.GetScriptScope().event_data
		local pPlantingBomb = pC4.FindBombWithUserId(event_data.userid)
		local pPlayer = pPlantingBomb.GetLastOwner()
		local pSite = pSites.FindBombsiteWithPlayer(pPlayer)
		
		print(pSite)
		
		if(pSite){
			if(pSite.GetTeam() == pPlayer.GetTeam()){
				return
			}
		}
		
		EntFireByHandle(pClientCommand, "command", "lastinv", 0, pPlayer, pPlayer)
		return	
	}
	
	function Planted(){
		//Fired by pPlantCheck
		printl("planted!")
		
		ScriptPrintMessageCenterAll("The bomb has been planted!")
		
		UpdateBombs()
		
		local pNewPlant = pC4.GetLatestPlanted()
		local pPlantSite = pSites.GetPlanted()
		
		pNewPlant.SetSite(pPlantSite)
		pPlantSite.Plant()
		RequestDefuser(pNewPlant)
	}
	
	function Defuse(pDefusedBomb){
		//Fired by a Bomb() instance
		local pDefusedSite = pDefusedBomb.GetSite()
		
		ScriptPrintMessageCenterAll("The bomb has been defused!")
		
		pDefusedBomb.Defuse()
		pDefusedSite.Defuse()
		
		pC4.EnableBuy()
		
		//It's possible to give the C4 to the defuser after they finish.
		//Arez doesn't want this in the game. But, I'd like to keep this here for
		//anyone who wants to try it out for themselves.
		//pC4.GiveC4(pDefusedBomb.GetPlayerDefuser())
	}
	
	function Explode(){
		//Fired by pExplodeCheck
		
		printl("EXPLOSION!")
		
		UpdateBombs()
		
		local pNewExplode = pC4.GetLatestExplosion()
		local pExplodeSite = pNewExplode.GetSite()
		
		pNewExplode.Explode()
		pExplodeSite.Explode()
		
		UpdateScore(pExplodeSite.GetTeam())
		
		pC4.EnableBuy()
		//Check to see if a team has won.
		local intWinner = pSites.CheckWin()
		if(intWinner){
			EndGame(intWinner)
		}
	}
	
	function Dropped(){
		//Fired by pDropCheck
		//I'm using item_remove instead of bomb_dropped due to that event not firing if the last bomb is defused before exploding.
		local event_data = pDropCheck.GetScriptScope().event_data
		
		if(event_data.item != "c4"){
			return
		}
		
		//Unfortunatily, if the bomb is planted, this will be called twice.
		UpdateBombs()
		
		local pLatestDropped = pC4.GetLatestDropped()
		
		try{
		if(!pLatestDropped.GetEnt().IsValid()){
			return
		}
		}
		catch(e){
			return
		}
		
		printl("Dropped!")
		ScriptPrintMessageCenterAll("The bomb has been dropped!")
		
		RequestGlow(pLatestDropped)
		
		pSites.LockBombsites()
	}
	
	function PlayerKilled(){

		local event_data = pDeathCheck.GetScriptScope().event_data

		local pPlayer = pPlayers.GetPlayerById(event_data.userid)
		if(pPlayer){
			//Player exists!
			try{
				pPlayer.GetScriptScope().RemoveArmor()
			}
			catch(e){
				//Player instance doesn't exist.
			}
		}

		UpdateBombsDropOnly()
		
		local pLatestDropped = pC4.GetLatestDropped()
		
		try{
			
		if(!pLatestDropped.GetEnt().IsValid()){
			return
		}
		}
		catch(e){
			return
		}
		
		printl("Dropped via killing!")
		ScriptPrintMessageCenterAll("The bomb has been dropped!")
		
		RequestGlow(pLatestDropped)
		
		pSites.LockBombsites()
	}
	
	function PickedUp(){
		//Fired by pPickupCheck
		printl("Picked Upped!")
		ScriptPrintMessageCenterAll("The bomb has been picked up!")
		
		pSites.LockBombsites()
		
		UpdateBombsDropOnly()
		
		local pNewPickupped = pC4.GetLatestPickedUpped()
		printl(pNewPickupped)
		local pPlayer = pNewPickupped.GetLastOwner()
		local event_data = pPickupCheck.GetScriptScope().event_data
		
		printl(event_data.userid)
		
		pNewPickupped.SetUserId(event_data.userid)
		
		local pPickupSite = pSites.FindBombsiteWithPlayer(pPlayer)
		
		if(pPickupSite){
			//printl("Found player who picked up bomb within bombsite!")
			//printl(pPickupSite.intTeam)
			//printl(pPlayer.GetTeam())
			if(pPickupSite.GetTeam() == pPlayer.GetTeam()){
				pPickupSite.UnlockBombsite()
			}
			return
		}
		return
	}
	
	function UpdateBombs(){
		//Fired by both pDropCheck and pPickupCheck
		pC4.UpdateBombs()
	}
	
	function UpdateBombsDropOnly(){
		//Fired by pDeathCheck, this is needed in order to get out of the entity's script scope.
		pC4.UpdateBombsDropOnly()
	}
	
	function ItemBought(){
		//Fired by pBuyCheck
		printl("Bought!")
		local event_data = pBuyCheck.GetScriptScope().event_data
		if(event_data.weapon == "weapon_taser"){
			//Bought C4
			pC4.C4Bought()
			
			if(!bMultiBomb){
				pC4.DisableBuy()
			}
			return
		}
		if(event_data.weapon == "item_kevlar"){
			local pPlayer = pPlayers.GetPlayerById(event_data.userid)
			printl(pPlayer)
			if(!pPlayer){
				//Player isn't there?
				printl("Can't find player!")
				return
			}

			pPlayer.GetScriptScope().AddArmor(1)
			return
		}
		if(event_data.weapon == "item_assaultsuit"){
			local pPlayer = pPlayers.GetPlayerById(event_data.userid)
			if(!pPlayer){
				//Player isn't there?
				printl("Can't find player!")
				return
			}

			pPlayer.GetScriptScope().AddArmor(2)
			return
		}

	}
	
	function RequestDefuser(pC4){
		local pScope = pC4Template.GetScriptScope()
		pScope.RequestC4(pC4)
	}
	
	function RequestGlow(pC4){
		local pScope = pGlowTemplate.GetScriptScope()
		pScope.RequestGlow(pC4)
	}
	
	function EndGame(intTeam){
		printl("\n\nENDINGGAME\n\n")
		//printl("Winning team: " + intTeam)

		local pEnd = Entities.CreateByClassname("game_round_end")
		if(intTeam == TEAM_T){
			EntFireByHandle(pEnd, "EndRound_TerroristsWin", "0", 0, null, null)
		}
		else{
			EntFireByHandle(pEnd, "EndRound_CounterTerroristsWin", "0", 0, null, null)
		}

		pEnd.Destroy()
	}
}