/*
    class_armor.nut

    Purpose:
        Used for changing the player's submodels in order to
        reflect the type of armor they have equipped.



    UNUSED! THIS FEATURE IS INTEGRATED INTO CLASS_PLAYER.NUT
*/

class ArmorManager{

    dictPlayers = null //Dictionary of players who have some type of armor equipped.

    function AddArmor(intUserId, pPlayer, intArmor){
        //intUserId: The player's UserID.
        //pPlayer: The player's instance pointer.
        //intArmor: What type of armor did they purchase? (1: Kevlar, 2: Kevlar/Helmet)

        local pExistingPlayer = dictPlayers.rawin(intUserId)

        if(!pExistingPlayer){
            dictPlayers.rawset(intUserId,pPlayer)
        }

        if(intArmor == 2){
            //Add helmet.
            pPlayer.SetBodyGroup(3, 1)
        }
        pPlayer.SetBodyGroup(2, 1)
    }

    function RemoveArmor(intUserId){
        //intUserId: The player's UserID.

        local pPlayer = dictPlayers.rawin(intUserId)

        if(!pPlayer){
            //Player didn't have armor.
            return
        }

        //Remove both types of armor.
        pPlayer.SetBodyGroup(3, 0)
        pPlayer.SetBodyGroup(4, 0)
    }
}