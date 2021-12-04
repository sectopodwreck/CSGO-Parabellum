/*
    Wave manager

    Purpose:
        Each wave is supposed to be a "mini-round" where each one lasts 60 seconds.
        On wave 1, players start with $250, and earn an extra $250 with their previous payments each wave. (500, 750, ...)
 */

class ::WaveManager{

    pMoney = null
    pTimer = null
    nWave = 1
    nWaveTime = 60 //Time is in seconds.
    nStartingAmount = 250
    nWaveAmount = 250


    constructor(){
        pMoney = GameCash(nStartingAmount, "New Wave Starting")
        InitTimer()
        printl(pTimer)
    }

    /*
        Creates a logic_timer entity and sets up it's parameters and I/O
    */
    function InitTimer(){
        pTimer = Entities.CreateByClassname("logic_timer")
        pTimer.__KeyValueFromInt("RefireTime", nWaveTime)
        pTimer.__KeyValueFromInt("UseRandomTime", 0)

        //Init the script scope to put in the output logic.
        pTimer.ValidateScriptScope()
        local pScope = pTimer.GetScriptScope()
        pScope.pWaveManager <- this
        pScope.OnTimer <- function(){
            pWaveManager.OnWaveEnd()
        }

        //Link OnTimer to our OnWaveEnd
        pTimer.ConnectOutput("OnTimer", "OnTimer")

        PauseTimer()
        ResetTimer()
    }

    //Resumes the timer, does not reset
    function ResumeTimer(nDelay = 0){
        EntFireByHandle(pTimer, "Enable", "", 0 + nDelay, null, null)
    }

    //Pauses the timer
    function PauseTimer(nDelay = 0){
        EntFireByHandle(pTimer, "Disable", "", 0 + nDelay, null, null)
    }

    //Resets the time, it will continue running.
    function ResetTimer(nDelay = 0){
        EntFireByHandle(pTimer, "ResetTimer", "", 0 + nDelay, null, null)
    }

    /*
        Begin the timer.
    */
    function StartWaves(){
        nWave = 1
        ScriptPrintMessageCenterAll("Wave 1 has started!\nGet to fighting!")
        ResumeTimer(1)
    }

    /*
        Fired when the wave finishes.
    */
    function OnWaveEnd(){
        printl("Wave Ended!")
        nWave += 1
        pMoney.AddCash(nWaveAmount)
        pMoney.GiveCashAll()

        SpawnPlayers()

        ScriptPrintMessageCenterAll("Wave " + nWave + " has started!\nYou've been given $" + pMoney.GetCash() + "!")
        ResetTimer()
    }

    /*
        Enables spawning for both teams.
    */
    function SpawnPlayers(){
        ServerCommand("mp_respawn_on_death_ct 1")
        ServerCommand("mp_respawn_on_death_t 1")

        ServerCommand("mp_respawn_on_death_ct 0", 1.5)
        ServerCommand("mp_respawn_on_death_t 0", 1.5)
    }

}