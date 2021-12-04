/*
    class_player.nut

    Instance of a player, used for equipping armor.
*/

class ::Player{

    pPlayer = null //Player's instance pointer.
    pScope = null //Player's script scope.
    intUserId = null //Player's UserID.
    bArmorEquipped = false

    constructor(player, userid){
        pPlayer = player
        intUserId = userid
        bArmorEquipped = false

        pPlayer.ValidateScriptScope()
        pScope = pPlayer.GetScriptScope()

        pScope.PlayerInstance <- this
        pScope.intUserId <- intUserId

        pScope.GetUserId <- function(){
            return intUserId
        }

        pScope.HarArmor <- function(){
            return PlayerInstance.HasArmor()
        }

        pScope.AddArmor <- function(intArmor){
            PlayerInstance.AddArmor(intArmor)
        }

        pScope.RemoveArmor <- function(){
            PlayerInstance.RemoveArmor()
        }
    }
    
    function GetUserId(){
        return intUserId
    }

    function HasArmor(){
        return bArmorEquipped
    }

    function AddArmor(intArmor){
        //intArmor: What type of armor to give?
        //1: Kevlar only.
        //2: Kevlar and helmet.

        if(intArmor == 2){
            //Bought helmet.
            pPlayer.SetBodygroup(3, 1)
        }
        pPlayer.SetBodygroup(2, 1)
        bArmorEquipped = true
    }

    function RemoveArmor(){
        //Removes the bodygroups that show armor.
        pPlayer.SetBodygroup(2, 0)
        pPlayer.SetBodygroup(3, 0)
        bArmorEquipped = false
    }


}