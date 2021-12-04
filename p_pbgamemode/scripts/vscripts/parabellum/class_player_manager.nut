/*
	player_manager.nut
	
	Purpose:
		Contains the methods needed for giving players their scope, and getting players
        with their UserID
		
	Made by BP for the Parabellum mod.
*/

IncludeScript("parabellum/class_player.nut")

class ::PlayerManager{

    pEventProxy = null
    dictPlayers = {} //Hashtable of all players

    constructor(){
        InitEventProxy()
        ValidatePlayers()
        ResetArmor()
    }

    function InitEventProxy(){
        pEventProxy = Entities.CreateByClassname("info_game_event_proxy")
        pEventProxy.__KeyValueFromInt("spawnflags", 0)
        pEventProxy.__KeyValueFromString("event_name", "player_connect")

        printl("Built event proxy!")
    }

    function GetPlayerById(intUserId){
        try{
            return dictPlayers.rawget(intUserId)
        }
        catch(e){
            return null
        }
    }

    function ResetArmor(){
        //Go through each player and make sure they dequip their armor on round restart, or some shit.
        foreach(idx, player in dictPlayers){
            local pScope = player.GetScriptScope()
            pScope.RemoveArmor()
        }
    }

    function AddPlayer(intIdx, intUserId){
        //Takes the player's int index and their userid and gives them a scope.

        local pPlayer = Entities.First()

        while(pPlayer = Entities.FindByClassname(pPlayer, "player")){
            local intSelectedIdx = pPlayer.entindex()

            if(intSelectedIdx == intIdx){
                //We found the player!
                InitPlayer(pPlayer, intUserId)
                return
            }
            else if(intSelectedIdx > intIdx){
                //We passed them! They don't exist!
                return
            }
        }
    }

    function InitPlayer(pPlayer, intUserId){
        //Creates the player's script scope, and gives them an instance.
        //pPlayer: Player's handle.
        //intUserId: Player's UserID

        local pPlayer = Player(pPlayer, intUserId)

        dictPlayers.rawset(intUserId, pPlayer)

        return
    }

    function ValidatePlayers(){
        //Iterates through all players and makes sure they all have a script scope.
        local pPlayer = null
        local rQueue = [] //Used for adding new players.

        while(pPlayer = Entities.FindByClassname(pPlayer, "player")){
            local pScope = pPlayer.GetScriptScope()
            if(!pScope){
                //Player doesn't have a script scope!
                rQueue.append(pPlayer)
            }
            //Player is fine.
            try{
                dictPlayers.rawset(pScope.GetUserId(), pPlayer)
            }
            catch(e){
                //No he's not, you weasely bastard!
                rQueue.append(pPlayer)
            }
        }

        foreach(idx, pQueued in rQueue){
            EntFireByHandle(pEventProxy, "GenerateGameEvent", "", 0.1*idx, pQueued, pQueued)
        }
    }


}