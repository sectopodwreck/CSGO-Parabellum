/*
	template_defuse_script.nut
	
	Purpose:
		Set up the defuser and link it with the correct C4 class instance in the manager script.
		
	Made by BP for the Parabellum mod.
*/

//Make sure that the entity loading this is a point_template. I want to make sure there are no leaks in this vessel!
Assert(self.GetClassname() == "point_template", "This script is supposed to be loaded on a point_template! Stop trying to break my code!")

//This will change to the class pointer of whatever C4 class is requesting a defuser.
//Only problem with this method is it's time dependant, you can't plant two C4 at the same time or else it will break.
//Luckaly, the game mode only allows for one bomb at all times.
::pTarget <- null


function Precache(){
	self.PrecacheModel("models/weapons/w_ied.mdl")
}

function RequestC4(pPointer){
	/*
		Sets up this entity for spawning in a prop_mapplaced_long_use_entity.
		pPointer: Bomb() instance.
	*/
	
	pTarget = pPointer
	EntFireByHandle(self, "ForceSpawn", "", 0, self ,self)
}

function PreSpawnInstance(strClass, strName){
	/*
		Moves the defuser entity to the C4 location, and hides it.
	*/
	Assert(strClass == "prop_mapplaced_long_use_entity", "Stop trying to break this code by allowing different entities to be spawned with this point_template!")
	
	local keyvalues =
	{
		origin		=	pTarget.GetOrigin(),
		rendermode	=	10
	}
	return keyvalues
}

function PostSpawn(tbEntities){
	/*
		Links the output and changes the model of the defuser.
	*/
	printl("Spawning!")
	foreach(strName, pEnt in tbEntities){
		Assert(pEnt.GetClassname() == "prop_mapplaced_long_use_entity", "Blocking other entities from being affected.")
		
		printl(pTarget)
		
		EntFireByHandle(pEnt, "DisableMotion", "", 0, self, self)
		pEnt.SetModel("models/weapons/w_ied.mdl")
		pTarget.SetDefuser(pEnt)
	}
	
	//Clean up for the next use.
}