```
=============================================================================================================
=============================================================================================================
=============================================================================================================

  _________ __                 ___________            __                                   ________   _____  
 /   _____//  |______ _______  \_   _____/___________/  |________   ____   ______ ______  /  _____/  /  |  | 
 \_____  \\   __\__  \\_  __ \  |    __)/  _ \_  __ \   __\_  __ \_/ __ \ /  ___//  ___/ /   __  \  /   |  |_
 /        \|  |  / __ \|  | \/  |     \(  <_> )  | \/|  |  |  | \/\  ___/ \___ \ \___ \  \  |__\  \/    ^   /
/_______  /|__| (____  /__|     \___  / \____/|__|   |__|  |__|    \___  >____  >____  >  \_____  /\____   | 
        \/           \/             \/                                 \/     \/     \/         \/      |__| 

=============================================================================================================
=============================================================================================================
=============================================================================================================
```
<p align="center">
  <img src="https://github.com/KitRifty/star-fortress-64/actions/workflows/build.yml/badge.svg?branch=master"/>
</p>

Where Star Fox and Team Fortress 2 two love each other so much they decided to make a baby.

This was made seven years ago for the late Lunar Republic Gaming and Gray Mann Gaming communities, but now here it all is for the public. Included is both the Arwing core plugin and a custom gamemode I built for the Arwings, but I never got that far with it.

Note: **Arwing** is used here as a generic term for any flying vehicles of this mod. Yes, the Star Fox Arwing is provided here, but you *can* technically create your own flying vehicles. You can use the Arwing's config as a base. Vehicle configs are located at `sourcemod/configs/starfortress64/vehicles/arwing`.

# Showcase
https://www.youtube.com/watch?v=5xfbHrXYY_4

https://www.youtube.com/watch?v=K6liOH1dJjU

https://www.youtube.com/watch?v=rewV_Ntr8PY

https://www.youtube.com/watch?v=A24JMjyenpI

# Requirements
- [VPhysics](https://forums.alliedmods.net/showthread.php?t=136350)
- [SteamTools](https://builds.limetech.io/?p=steamtools)
- [DHooks](https://github.com/peace-maker/DHooks2/releases)

If you are compiling, you must use [this updated `vphysics.inc` file](https://github.com/asherkin/vphysics/blob/master/vphysics.inc). 

# Assets
[Star Fox Arwing Model](https://garrysmods.org/download/17957/arwingzip)

[Pickup Models, Sounds, Materials, Test Map, Woonwing](https://drive.google.com/file/d/1auuQE4MMv8O-_sLSpEzukK9l5_EUv3p6/view?usp=sharing)
> :warning: The Woonwing model is missing its material and is unfortunately lost to time.

# Configuration
- **`sv_maxvelocity`** - Laser projectiles move extremely fast, so you must set this hidden cvar via `sm_cvar` to a value higher than any of the projectiles' speeds. Projectile's velocity will be clamped down to this value by default. For reference, the Arwing laser projectile's default speed is `18500`, so set `sv_maxvelocity` higher than this.

# Controls
To enter an Arwing, walk up and point at it then call MEDIC (default is 'E').

| Name | Keybind (Default) |
| --- | --- |
| Fire | Primary Attack |
| Fire Charged Laser | HOLD Primary Attack then release |
| Fire Smart Bomb | Secondary Attack |
| Tilt Left/Right | HOLD Reload + Strafe Key |
| Barrel Roll | Double tap Reload |
| Boost | HOLD Jump |
| Brake | HOLD Crouch |
| Somersault | Strafe Back + Jump |
| U-Turn | Strafe Back + Crouch |
| Toggle HUD instructions | Crouch 2x |

# Commands
| Name | Description | Admin Flags |
| --- | --- | --- |
| sm_sf64_spawn_arwing \<name\> | Spawns a vehicle at wherever you're pointing. This takes one argument, the vehicle name, which is usually just `arwing` or whatever vehicles are defined in `sourcemod/configs/starfortress64/vehicles/arwing` directory. | ADMFLAG_CHEATS |
| sm_sf64_forceintovehicle <#userid\|name> \[targetname\] | Forces the specified player into the Arwing you're pointing at. Optionally, you may also provide a target name of the Arwing entity. | ADMFLAG_CHEATS |
| sm_sf64_spawn_pickup \<name\> \<quantity\> \[can respawn 0/1\] | Spawns a pickup at your location with the provided name and quantity. The name can be `laser`, `smartbomb`, `ring`, or `ring2`. | ADMFLAG_CHEATS |

# Contributions
Pull requests are welcome. Just make sure of the following: 
1. It compiles
2. Use tabs for indentation.

# Credits

**Jug(?)** - Woona Arwing reskin

**Nintendo** - For ~~not copystriking me~~ Star Fox

**LRG and GMG** - Thanks, guys.

Good luck, and have fun.

Sincerely,

Kit o' Rifty
