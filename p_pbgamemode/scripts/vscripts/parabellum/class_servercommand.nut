/*
    ServerCommand

    Allows for passing commands to the server, with the added benifit with delayed commands.
*/

::pServerCommand <- Entities.CreateByClassname("point_servercommand")

::ServerCommand <- function(strCommand, flDelay = 0){
    EntFireByHandle(pServerCommand, "Command", strCommand, flDelay, null, null)
}