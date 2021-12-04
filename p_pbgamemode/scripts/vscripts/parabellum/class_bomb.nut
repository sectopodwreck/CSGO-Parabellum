/*
	class_bomb.nut
	
	Purpose:
		An special instance of a weapon_c4.
		
	Created by BP for the Parabellum mod.
*/

class ::Bomb{
	/*
		Entity: weapon_c4 / planted_c4 / null (Depends on state)
		Also houses a defuser entity while it's in the planted_c4 state.
	*/

	constructor(pEnt, pMgr){
		
		pInstance = pEnt
		pDefuser = null
		pLastOwner = null
		pBombManager = pMgr
		pSite = null
		pTimer = null
		pGlow = null
		strState = "dropped"
		intUserId = null //Last Owner's User ID
		flExplodeTime = null
		flTimeout = null
		flDropStart = null
		
		//Update()
	}
	
	pInstance = null
	pDefuser = null
	//Player who defused the bomb, if it happens
	pPlayerDefuser = null
	pBombManager = null
	pLastOwner = null
	pSite = null
	pTimer = null
	pGlow = null
	strState = "dropped"
	intUserId = null
	flExplodeTime = null
	flTimeout = null
	flDropStart = null
	
	vectStartColor = Vector(0, 255, 0)
	vectEndColor = Vector(255, 0, 0)
	
	function GetEnt(){
		return pInstance
	}
	
	function GetOrigin(){
		//Vector
		return pInstance.GetOrigin()
	}
	
	function GetAngles(){
		//vector
		return pInstance.GetAngles()
	}
	
	function GetName(){
		//String
		local strName = pInstance.GetName()
		if(strName == ""){
			strName = UniqueString()
			EntFireByHandle(pInstance, "AddOutput", "targetname " + strName, 0, null, null)
		}
		
		return strName
	}
	
	function GetState(){
		//String
		return strState
	}
	
	function GetSite(){
		//Bombsite()
		return pSite
	}
	
	function GetLastOwner(){
		//player
		return pLastOwner
	}
	
	function GetPlayerDefuser(){
		//player
		return pPlayerDefuser
	}
	
	function GetUserId(){
		//int
		return intUserId
	}
	
	function SetUserId(userid){
		intUserId = userid
	}
	
	function SetState(strNewState){
		strState = strNewState
	}
	
	function SetGlow(pEnt){
		//pEnt sould be a prop_dynamic_glow!
		Assert(pEnt.GetClassname() == "prop_dynamic_glow", "Tried to set the glow to an illegal instance!")
		pGlow = pEnt
		//The timer should take care of the rest of this.
	}
	
	function SetDefuser(pEnt){
		//pEnt should be a prop_mapplaced_long_use_entity.
		Assert(pEnt.GetClassname() == "prop_mapplaced_long_use_entity", "Tried to set the defuser to an illegal instnace!")
		pDefuser = pEnt
		InitDefuser()
	}
	
	function SetPlayerDefuser(pPlayer){
		Assert(pPlayer.GetClassname() == "player", "Tried to set pPlayerDefuser to an illegal instance!")
		pPlayerDefuser = pPlayer
	}
	
	function SetSite(pEnt){
		//pEnt should be an instance of Bombsite() for where this is planted.
		pSite = pEnt
	}
	
	function InitDefuser(){
		//Makes sure the defuser has a script scope and connects the output.
		pDefuser.ValidateScriptScope()
		local pScope = pDefuser.GetScriptScope()
		
		pScope.Defuse <- EntDefuse
		pScope.pGameRule <- pGameRule
		pScope.pC4 <- this
		
		pDefuser.ConnectOutput("OnUseCompleted", "Defuse")
	}
	
	function Update(){
		/*
			Called whenever there is an update to a bomb being planted/exploded/dropped/picked up.
			Helps make sure that the class always knows what the intended bomb's state is.
		*/
		
		printl(GetState())
		printl(pInstance.IsValid())
		
		if(strState == "exploded" || strState == "defused" || strState == "timeout"){
			pBombManager.MarkBomb(this)
			return
		}
		
		if(strState == "planted"){
			if(Time() >= flExplodeTime){
				SetState("exploded")
				pBombManager.SetLatestExplosion(this)
				return
			}
			return
		}
		
		if(strState == "carried" || strState == "dropped"){
			
			if(pInstance.IsValid()){
				if(pInstance.GetOwner()){
					if(GetState() == "carried"){
						return
					}
					pBombManager.SetLatestPickedUpped(this)
					pLastOwner = pInstance.GetOwner()
					SetState("carried")
					PickUp()
					return
				}
				
				else{
					if(GetState() == "dropped"){
						return
					}
					pBombManager.SetLatestDropped(this)
					SetState("dropped")
					Drop()
					return
				}
				
			}
			
			else{
				Plant()
				SetState("planted")
				pBombManager.SetLatestPlanted(this)
				return
			}
		}
		Assert(false, "A bomb class has an unknown state!")
	}
	
	function UpdateDropOnly(){
		if(strState == "carried"){
			//Check to see if there is an owner.
			if(pInstance.GetOwner()){
				//If there is, do nothing.
				return
			}
			SetState("dropped")
			pBombManager.SetLatestDropped(this)
			Drop()
			return
		}
		
		if(strState == "dropped"){
			if(!pInstance.GetOwner()){
				//If there is none, do nothing.
				return
			}
			pBombManager.SetLatestPickedUpped(this)
			pLastOwner = pInstance.GetOwner()
			SetState("carried")
			PickUp()
			return
		}
	}
	
	function Tick(){
		//Fired by logic_timer, updates timeout.
		if(Time() > flTimeout){
			CleanUp()
			return
		}
		local flTimeDelta = (Time() - flDropStart) / 60
		local vectNewColor = VectLerp(vectStartColor, vectEndColor, flTimeDelta)
		try{
			pGlow.__KeyValueFromVector("glowcolor", vectNewColor)
		}
		catch(e){
			//On some RARE occasions, the bomb can be picked up while this method is running.
			//Since I fucking hate seeing errors, I'm adding this to make the console cleaner.
			return
		}
		
		//printl(flTimeDelta)
		//printl(vectNewColor.ToKVString())
		local flTimeLeft = floor(flTimeout - Time())
		if(flTimeLeft % 15 == 0 && flTimeLeft > 0){
			ScriptPrintMessageCenterAll("The bomb will respawn in " + flTimeLeft.tointeger() + " seconds!")
		}
		
	}
	
	function EntTick(){
		//FOR THE TIMER'S SCRIPT SCOPE ONLY!
		pC4.Tick()
	}
	
	function Plant(){
		//Attempts to find a planted_c4 entity near the last player who held the bomb.
		local pEnt = Entities.FindByClassnameNearest("planted_c4", pLastOwner.GetOrigin(), 64.0)
		Assert(pEnt, "Couldn't find a planted_c4 entity!")
		pInstance = pEnt
		flExplodeTime = Time() + 60.0
	}
	
	function Explode(){
		//Clean up and keep the bombsite from being planted at again.
		pInstance.Destroy()
		pDefuser.Destroy()
	}
	
	function Drop(){
		pTimer = Entities.CreateByClassname("logic_timer")
		pTimer.__KeyValueFromInt("RefireTime", 1)
		pTimer.ValidateScriptScope()
		
		local pScope = pTimer.GetScriptScope()
		pScope.pC4 <- this
		pScope.Fired <- EntTick
		pTimer.ConnectOutput("OnTimer", "Fired")
		
		EntFireByHandle(pTimer, "ResetTimer", "", 0, null, null)
		
		flTimeout = Time() + 60
		flDropStart = Time()
	}
	
	function PickUp(){
		if(!pTimer){
			return
		}
		pTimer.Destroy()
		pGlow.Destroy()
	}
	
	function EntDefuse(){
		pC4.SetPlayerDefuser(activator)
		pGameRule.Defuse(pC4)
	}
	
	function Defuse(){
		//Clean up
		pInstance.Destroy()
		SetState("defused")
	}
	
	function CleanUp(){
		//The players didn't pick up the C4 in time. Remove the C4 and allow it to be purchasable.
		SetState("timeout")
		pInstance.Destroy()
		pTimer.Destroy()
		ScriptPrintMessageCenterAll("The bomb has been reset!")
		//pGlow.Destroy()
		
		pBombManager.EnableBuy()
	}
	
	function Delete(){
		//WARNING! Completely removes this instance! Use with caution!
		
		if(GetState() != "exploded"){
			if(GetState() == "dropped"){
				PickUp()
			}
			else if(GetState() == "planted"){
				pDefuser.Destroy()
			}
			try{
				pInstance.Destroy()
			}
			catch(e){
				
			}
		}
		pBombManager.DeleteBomb(this)
	}
	
	function VectLerp(vectA, vectB, flAmount){
		return Vector(
			vectA.x + flAmount * (vectB.x - vectA.x),
			vectA.y + flAmount * (vectB.y - vectA.y),
			vectA.z + flAmount * (vectB.z - vectA.z)
		)
	}
}