/*
    class_cash.nut

    A cash instance that can add/remove cash.
*/

class ::GameCash{

    pMoney = null
    nCash = 0

    constructor(nAmount = 0, strReason = ""){
        nCash = nAmount
        InitEnt(strReason)
    }
    
    /*
        Remove the ent
    */
    function destructor(){
        pMoney.Destroy()
    }

    /*
        Initalize the game_money entity.
    */
    function InitEnt(strReason){
        pMoney = Entities.CreateByClassname("game_money")
        SetCash(nCash)
        SetReason(strReason)
    }

    /*
        Set the amount of money to give out.

        nAmount: Amount of cash to change to.
    */
    function SetCash(nAmount){
        nCash = nAmount
        pMoney.__KeyValueFromInt("Money", nCash)
    }

    function GetCash(){
        return nCash
    }

    /*
        Edit the message that comes alongside giving the cash.
    */
    function SetReason(strReason){
        pMoney.__KeyValueFromString("AwardText", strReason)
    }

    /*
        Add to the amount of cash already set.

        nAmount: Amount of cash to add to.
    */
    function AddCash(nAmount){
        SetCash(nCash + nAmount)
    }

    /*
        Give cash to all players.
    */
    function GiveCashAll(){
        GiveCashCT()
        GiveCashT()
    }

    /*
        Only give the cash reward to T's
    */
    function GiveCashT(){
        EntFireByHandle(pMoney, "AddTeamMoneyTerrorist", "", 0, null, null)
    }

    /*
        Only give the cash reward to CT's
    */
    function GiveCashCT(){
        EntFireByHandle(pMoney, "AddTeamMoneyCT", "", 0, null, null)
    }

    /*
        Give Cash to the specified player.

        pPlayer: Player who will be earning money.
    */
    function GiveCash(pPlayer){
        EntFireByHandle(pMoney, "AddMoneyPlayer", "", 0, pPlayer, pPlayer)
    }
}