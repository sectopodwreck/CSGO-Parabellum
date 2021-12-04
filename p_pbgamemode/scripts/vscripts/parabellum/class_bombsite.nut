/*
	class_bombsite.nut
	
	Purpose:
		An special instance of a trigger_multiple which is consitered
		a bombsite.
		
	Made by BP for the Parabellum mod.
*/

class ::Bombsite{
	/*
		Entity: trigger_multiple
		Initalizes a single bombsite and houses all the data needed.
	*/
	
	constructor(pEnt, intAssignedTeam){
		
		pInstance = pEnt
		intTeam = intAssignedTeam
		rPlayers = []
		
		InitEntity()
	}
	
	pInstance = null
	intTeam = -1
	bDestroyed = false
	bPlanted = false
	bHasBomber = false
	rPlayers = []
	//Players within the site.
	
	function GetEnt(){
		//Instance
		return pInstance
	}
	
	function GetTeam(){
		//Int
		return intTeam
	}
	
	function IsDestroyed(){
		//Bool
		return bDestroyed
	}
	
	function HasBomb(){
		//Bool
		return bPlanted
	}
	
	function HasBomber(){
		//Bool
		return bHasBomber
	}
	
	function InitEntity(){
		//Creates a script scope for the trigger and connects outputs.
		pInstance.__KeyValueFromFloat("wait", 0.01)
		//pInstance.__KeyValueFromInt("spawnflags", 5185) //We're going to test if it's possible for the planted C4 to trigger the site.
		pInstance.ValidateScriptScope()
		local pScope = pInstance.GetScriptScope()
		
		pScope.pSite <- this
		
		//pInstance.ConnectOutput("OnStartTouch", "OnStartTouch")
		//pInstance.ConnectOutput("OnEndTouch", "OnEndTouch")
		
		EntFireByHandle(pInstance, "AddOutput", "OnStartTouch !self:RunScriptCode:pSite.OnStartTouch():-1:0", 0, null, null)
		EntFireByHandle(pInstance, "AddOutput", "OnEndTouch !self:RunScriptCode:pSite.OnEndTouch():-1:0", 0, null, null)
	}
	
	function Plant(){
		//Fired when the bomb has been planted at this site. Keeps from another bomber from planting.
		//pInstance.DisconnectOutput("OnStartTouch", "OnStartTouch")
		//pInstance.DisconnectOutput("OnEndTouch", "OnEndTouch")
		
		//Allows the mapper to add map logic if the bomb is planted.
		EntFireByHandle(pInstance, "FireUser2", "", 0, null, null)
		bPlanted = true
		LockBombsite()
	}
	
	function Explode(){
		//Clean up
		pInstance.DisconnectOutput("OnStartTouch", "OnStartTouch")
		pInstance.DisconnectOutput("OnEndTouch", "OnEndTouch")
		
		//Allows the mapper to add map logic if the bomb explodes.
		EntFireByHandle(pInstance, "FireUser1", "", 0, null, null)
		bDestroyed = true
		bPlanted = false
		rPlayers = []
	}
	
	function Defuse(){
		//Fired by the Bomb() instance of the C4 planted here.
		//EntFireByHandle(pInstance, "AddOutput", "OnStartTouch !self:RunScriptCode:pSite.OnStartTouch():-1:0", 0, null, null)
		//EntFireByHandle(pInstance, "AddOutput", "OnEndTouch !self:RunScriptCode:pSite.OnEndTouch():-1:0", 0, null, null)
		
		//Allows the mapper to add map logic if the bomb is defused.
		EntFireByHandle(pInstance, "FireUser3", "", 0, null, null)
		bPlanted = false
	}
	
	function OnStartTouch(){
		//Check to see if the player entering has a bomb.
		//printl("Player's team:" + activator.GetTeam() + " Bombsite's team: " + intTeam)
		//printl("Activator: " + activator)
		if(bPlanted || bDestroyed){
			return
		}
		AddPlayer(activator)
		if(activator.GetTeam() == intTeam){
			local pC4 = Entities.FindByClassnameNearest("weapon_c4", GetEnt().GetOrigin(), 1024)
			if(!pC4){
				return
			}
			if(pC4.GetOwner() == activator){
				UnlockBombsite()
				return
			}
			return
		}
		return
	}
	
	function OnEndTouch(){
		//Checks to see if the player leaving has a bomb.
		if(bPlanted || bDestroyed){
			return
		}
		RemovePlayer(activator)
		if(activator.GetTeam() == intTeam){
			local pC4 = Entities.FindByClassnameNearest("weapon_c4", GetEnt().GetOrigin(), 1024)
			if(!pC4){
				return
			}
			if(pC4.GetOwner() == activator){
				LockBombsite()
				return
			}
			return
		}
	}
	
	function UnlockBombsite(){
		//printl("Unlocking")
		bHasBomber = true
		SendToConsoleServer("mp_plant_c4_anywhere 1")
	}
	
	function LockBombsite(){
		//printl("Locking")
		bHasBomber = false
		SendToConsoleServer("mp_plant_c4_anywhere 0")
	}
	
	function AddPlayer(pPlayer){
		//printl("Adding player!")
		Assert(pPlayer.GetClassname() == "player", "Only player entities can be appended to sites!")
		Assert(!HasPlayer(pPlayer), "Player already in!")
		rPlayers.append(pPlayer)
		//PrintPlayers()
		return
	}
	
	function RemovePlayer(pPlayer){
		//printl("Removing player!")
		foreach(idx, player in rPlayers){
			if(player == pPlayer){
				rPlayers.remove(idx)
				//PrintPlayers()
				return
			}
		}
		Assert(false, "Couldn't find player to remove!")
		return
	}
	
	function HasPlayer(pPlayer){
		//Bool
		foreach(idx, player in rPlayers){
			if(player == pPlayer){
				return true
			}
		}
		return false
	}
	
	function PrintPlayers(){
		print("Players on site: ")
		foreach(idx, player in rPlayers){
			print(player)
		}
		print("\nNo. of players: ")
		printl(rPlayers.len())
	}
}