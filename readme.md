# CSGO: Parabellum
## Project Lead: AREZ
## Language: Squirrel
---

**All My Work Can Be Found In: `p_pbgamemode/scripts/vscripts/`**

This was one my first introductions to working with a team of people. I decided to try and take someone's offer on the #jobs board of the Source Modding Community, and went with this.

My time working under Arez was a bit odd... To start off with, I wasn't working on this when I was brought on. Instead, it was a different project entirely where he needed me to level design for it. After finishing up what he wanted, that project died off due to inactivity.

But, once the previous scripter for Parabellum went up and left, I was brought on-board to take his place. Before we get on, let's go over how to install/play.

## Installing
The way we worked on this project is a bit different than how we do on vanilla CS:GO. We used a tool called [MIGI](https://github.com/ZooLSmith/MIGI3) in order to split up the project into different sections. MIGI's readme should then instruct you on where to place these addon folders and how to launch the game..

## What is Parabellum?
This modification of CS:GO is familiar, but different. It's supposed to be a "MOBA" where each team is given multiple bombsites they must defend while also trying to plant/destroy the enemies bombsites. The first team to blow up all of the opposition's sites wins. Along with this, the round does not end when an entire team is eliminated, as respawning is enabled in a wave-like fassion. The time between the respawn wave is considered a "mini-round", as all players are given an increasing income at the start of the next wave. Once the round is ended, that's the end of the game.

So, it was my job to somehow make the base game:
* Allow Counter-Terrorists to plant C4.
* Allow for multiple C4s to be planted.
* Manage multiple bombsites.
* Modify the player's bodygroups to represent their current armor state. (Minor addition)
* Keep tabs on multiple C4s in the play area.
* Implement a wave system which progressively gives players more cash, and respawns all dead players.
* **And Most Importantly**, make sure that the level designer has a very easy experience implementing these features into their map without needing knowledge on VScripting or how this script works. (Abstract front-end)

## Previous code
Now I'm friends with the person who used to work on the project, he's a great man who knows C++ inside and out, but my god was what he left me terrible. I wish I still had his script file around in order to explain my grevances, but trust me when I say it didn't look like he knew what he was doing. So I had to trash his old work.

## Starting From Scratch
When it comes to scripting in CS:GO, I like to take a OOP approach by encapsulating each entity to only contain the bare minimum for what they need in order to function correctly. CS:GO's scripting engine allows for this by giving each entity their own *script scope* which allows an entity to store data that is only accessable from either being that entity, or referencing it. Because of this, I also like to split my script up into multiple files to allow for easier managing of the large project. There are many different moving parts in my script, so I will briefly explain each file, and what their role is.


## game\_manager.nut
This is the main script, which is pre-compiled into the map to already be inside the scope of a `logic_script` entity.

It manages loading all other files, initializing the game correctly, along with holding the functions of the `logic_eventlisteners` which allows me to react to certian events within the game and set the state accordingly. (ie. Player drops the bomb, or plants it.)

A neat, little feature I was able to pull off, which is found in this script, is that the rounds won counter on the player's UI has been changed to instead show the remaining bombsites of each team.

## class\_bombsite\_manager.nut
This script is loaded in by game\_manager.nut at runtime, and isn't associated to an entity.

This global class is in charge of initalizing all bombsites at map runtime, and keeping tabs on said sites. It acts as a link between the main game's scripts, and the functions of individual bombsites.

For whenever a level developer must place a bombsite, this script eases their process by allowing them to only need to place down a brush, assign it as a `trigger_multiple`, and then they change the targetname to either **T** or **CT** to signify which team owns the site. The script at runtime can then find this entity, give it a script scope, and initalize an instance of `class_bombsite`.

## class\_bombsite.nut
This script is loaded by class\_bombsite\_manager.nut, with instances being found inside of scopes of `trigger_multiple` entities.

This class is interacted by the players and script. It allows for a site to be unlocked/locked, flagged as destroyed, or flagged as planted.

Along with this, the level developer is able to bind events that happen within the site to other entities using Hammer IO:
* **OnUser1:** The bombsite has been destroyed.
* **OnUser2:** A player has planted C4 at the bombsite.
* **OnUser3:** A player has defused the C4 at the bombsite.

This is in order to mimic the IO seen in the vanilla `func_bomb_target` brush entity.

## class\_bomb\_manager.nut
This script is loaded in by game\_manager.nut at runtime, and isn't associated to an entity.

This global class is in charge of spawning in, and keeping tabs on all `weapon_c4`'s and `planted_c4`'s. It acts as a link between the main game's script, and the functions of individual C4's.

## class\_bomb.nut
This script is loaded in by class\_bomb\_manager.nut, but instances are only found within the manager class instance, not the associated entities.

This class is instanced to every `weapon_c4` spawned in by the player then they purchase the weapon. It holds functions which constantly update the state of the entity: wheter it is being held, dropped, planted, or defused. It is also responsible for applying the glow effect onto the C4 when it is dropped.

## wave\_manager.nut
This script is loaded in by game\_manager.nut, and isn't associated to an entity.

As the name implies, the script is used to manage the respawn waves of the players, and to distribute cash to every player at the start of each wave. This was implemented late into development as a means of breaking the game down into "mini-rounds" and to allow players to access more expensive weapons without dying resulting in a major detriment to the team's economy.

---

This concludes all of the important script files. All the other ones are to allow for the extra functionality seen within what was already stated

## Why I Abandoned The Project
I've tried to stick around and work on it, but the writing was on the wall that the project will not be going anywhere as it was suffering from feature creep. The team lead wanted to keep on adding more and more content, and I didn't have the time to do it due to starting college. Along with this, the team rarely spoke to each other, so it felt like I was the only active contributor as well.

Since then, ARES has decided to move the project onto the Unreal Engine, so it's now out of my scope of expertise, as I've only worked with UE3 once and the UDK doesn't run on Linux. But I do enjoy my time working on this project, and seeing myself in real time improve how I program within CS:GO.
