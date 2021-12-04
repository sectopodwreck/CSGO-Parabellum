/*
	template_glow_script.nut
	
	Purpose:
		Set up the defuser and link it with the correct C4 class instance in the manager script.
		
	Made by BP for the Parabellum mod.
*/

//Make sure that the entity loading this is a point_template. I want to make sure there are no leaks in this vessel!
Assert(self.GetClassname() == "point_template", "This script is supposed to be loaded on a point_template! Stop trying to break my code!")

//C4 Class
::pTarget <- null

function RequestGlow(pPointer){
	/*
		Sets up this entity for spawning in a prop_dynamic_glow.
		pPointer: Bomb() instance.
	*/
	
	pTarget = pPointer
	EntFireByHandle(self, "ForceSpawn", "", 0, self ,self)
}

function PreSpawnInstance(strClass, strName){
	/*
		Moves the defuser entity to the C4 location, and hides it.
	*/
	Assert(strClass == "prop_dynamic_glow", "Stop trying to break this code by allowing different entities to be spawned with this point_template!")
	
	local keyvalues =
	{
		origin		=	pTarget.GetOrigin(),
		rendermode	=	0
	}
	return keyvalues
}

function PostSpawn(tbEntities){
	/*
		Links the output and changes the model of the defuser.
	*/
	printl("Spawning!")
	foreach(strName, pEnt in tbEntities){
		Assert(pEnt.GetClassname() == "prop_dynamic_glow", "Blocking other entities from being affected.")
		
		local strName = pTarget.GetName()
		
		pEnt.SetModel("models/weapons/w_ied_dropped.mdl")
		
		EntFireByHandle(pEnt, "SetParent", strName, 0, null, null)
		pEnt.SetOrigin(pTarget.GetOrigin())
		
		local vectAngles = pTarget.GetAngles()
		
		pEnt.SetAngles(vectAngles.x, vectAngles.y, vectAngles.z)
		
		pEnt.__KeyValueFromVector("glowcolor", pTarget.vectStartColor)
		
		pTarget.SetGlow(pEnt)
	}
	
	//Clean up for the next use.
}