/*
	class_bomb_manager.nut
	
	Purpose:
		Creates and contains all instances of bombs.
		
	Created by BP for the Parabellum mod.
*/

IncludeScript("parabellum/class_bomb.nut")

class ::BombManager{
	/*
		Contains all instances of C4s on the map, even older, defused/exploded ones with no pointers.
		Responsible for allowing players to purchase C4s as well.
	*/
	
	constructor(){
		
		EnableBuy()
		InitEnt()
	}
	
	rBombs = []
	rMarkedBombs = [] //Bombs that will be deleted after updating.
	bCanBuy = true
	pEquip = null
	pLatestPlanted = null
	pLatestExploded = null
	pLatestDropped = null
	pLatestPickupped = null
	pLatestDefused = null
	
	function UpdateBombs(){
		
		SetLatestDefused(null)
		SetLatestDropped(null)
		SetLatestExplosion(null)
		SetLatestPickedUpped(null)
		SetLatestPlanted(null)
		
		//printl(rBombs.len())
		foreach(i, pBomb in rBombs){
			//printl("Updating!")
			pBomb.Update()
		}
		
		foreach(idx, pBomb in rMarkedBombs){
			pBomb.Delete()
		}
		rMarkedBombs = []
	}
	
	function UpdateBombsDropOnly(){
		//There's a problem where if a player is killed at the perfect time, it will fuck up the script.
		//We'll need to use this function instead of the original in order to keep things clean.
		SetLatestDropped(null)
		
		foreach(i, pBomb in rBombs){
			pBomb.UpdateDropOnly()
		}
	}
	
	function MarkBomb(pBomb){
		//Queues a bomb for deletion
		rMarkedBombs.append(pBomb)
	}
	
	function DeleteBomb(pDelBomb){
		//Deletes a bomb instance from the array.
		foreach(idx, pBomb in rBombs){
			if(pBomb == pDelBomb){
				rBombs.remove(idx)
				printl("Garbage Collected bomb #" + idx)
				return
			}
		}
		print("Couldn't find bomb instance!")
		return
	}
	
	function InitEnt(){
		//Spawns in a game_player_equip
		pEquip = Entities.CreateByClassname("game_player_equip")
		pEquip.ValidateScriptScope()
		pEquip.__KeyValueFromInt("spawnflags", 5)
		local pScope = pEquip.GetScriptScope()
		pScope.InputFireUser1 <- C4Clean
		pScope.pC4Manager <- this
	}
	
	function EnableBuy(){
		
		SendToConsoleServer("mp_weapons_allow_zeus -1")
		bCanBuy = true
	}
	
	function DisableBuy(){
		
		SendToConsoleServer("mp_weapons_allow_zeus 0")
		bCanBuy = false
	}
	
	function C4Bought(){
		//Replace the bought weapon_taser with a weapon_c4.
		local pTaser = Entities.FindByClassname(null, "weapon_taser")
		local activator = pTaser.GetOwner()
		pTaser.Destroy()
		Assert(activator, "Couldn't find taser owner!")
		GiveC4(activator)
	}
	
	function GiveC4(activator){
		//Gives the player a C4.
		
		EntFireByHandle(pEquip, "TriggerForActivatedPlayer", "weapon_c4", 0, activator, activator)
		EntFireByHandle(pEquip, "FireUser1", "", 0, activator, activator)
	}
	
	function C4Clean(){
		//game_player_equip has a habbit of spawning more than one weapon_c4.
		//Also creates the Bomb() instance.
		
		local pSelectedC4 = Entities.FindByClassnameWithin(null, "weapon_c4", activator.GetOrigin(), 64)
		pSelectedC4.SetOwner(activator)
		pC4Manager.rBombs.append(Script.Bomb(pSelectedC4, pC4Manager))
		
		local pC4 = null
		while(pC4 = Entities.FindByClassnameWithin(pC4, "weapon_c4", activator.GetOrigin(), 64)){
			if(pC4.GetOwner()){
				continue
			}
			pC4.Destroy()
		}
	}
	
	function FindBombWithUserId(intUserId){
		foreach(idx, pBomb in rBombs){
			if(pBomb.GetUserId() == intUserId){
				return pBomb
			}
		}
		return null
	}
	
	function GetLatestPlanted(){
		//printl("Getting latets!")
		//returns Bomb() instance
		return pLatestPlanted
	}
	
	function GetLatestExplosion(){
		//returns Bomb() instance
		return pLatestExploded
	}
	
	function GetLatestDropped(){
		//returns Bomb() instance
		return pLatestDropped
	}
	
	function GetLatestPickedUpped(){
		//returns Bomb() instance
		return pLatestPickupped
	}
	
	function GetLatestDefuse(){
		//returns Bomb() instance
		return pLatestDefused
	}
	
	function SetLatestPlanted(pC4){
		pLatestPlanted = pC4
	}
	
	function SetLatestExplosion(pC4){
		pLatestExploded = pC4
	}
	
	function SetLatestDropped(pC4){
		pLatestDropped = pC4
	}
	
	function SetLatestPickedUpped(pC4){
		pLatestPickupped = pC4
	}
	
	function SetLatestDefused(pC4){
		pLatestDefused = pC4
	}
}