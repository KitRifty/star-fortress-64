#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <vphysics>
#include <tf2_stocks>
#include <starfortress64>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
    name = "Star Fortress 64",
    author	= "KitRifty",
    description	= "A gamemode of flying space vehicles!",
    version = PLUGIN_VERSION,
    url = ""
}

#define DEBUG


new Handle:g_hTargetReticles;
new Handle:g_hLasers;
new Handle:g_hChargedLasers;
new Handle:g_hSBombs;
new Handle:g_hPickups;
new Handle:g_hPickupsGet;
new Handle:g_hEffects;
new Handle:g_hHudElements;

new bool:g_bPlayerInvertedXAxis[MAXPLAYERS + 1] = { false, ... };
new bool:g_bPlayerInvertedYAxis[MAXPLAYERS + 1] = { true, ... };

new g_iPlayerLastButtons[MAXPLAYERS + 1];
new Float:g_flPlayerForwardMove[MAXPLAYERS + 1];
new Float:g_flPlayerSideMove[MAXPLAYERS + 1];
new Float:g_flPlayerDesiredFOV[MAXPLAYERS + 1];

new Handle:g_hPlayerVehicleSequenceTimer[MAXPLAYERS + 1];
new Float:g_flPlayerVehicleBlockVoiceTime[MAXPLAYERS + 1];

new Handle:g_cvFriendlyFire;
new bool:g_bFriendlyFire;

new Handle:g_cvInfiniteBombs;

#if defined DEBUG
new Handle:g_hHudSyncDebug;
#endif

new Handle:g_hSDKGetSmoothedVelocity;

new g_offsPlayerFOV = -1;
new g_offsPlayerDefaultFOV = -1;

// Helpers.
#include "starfortress64/defines.sp"
#include "starfortress64/util.sp"

// Effects.
#include "starfortress64/effects.sp"

// Vehicles.
#include "starfortress64/vehicles/arwing.sp"
#include "starfortress64/basevehicle.sp"

// Projectiles.
#include "starfortress64/projectiles/laser.sp"
#include "starfortress64/projectiles/chargedlaser.sp"
#include "starfortress64/projectiles/smartbomb.sp"

// Pickups.
#include "starfortress64/pickups.sp"

// HUD.
#include "starfortress64/hud/hudelement.sp"
#include "starfortress64/hud/targetreticle.sp"

// Gamerules.
#include "starfortress64/gamerules.sp"

// Music.
#include "starfortress64/music.sp"

// Vehicle externals.
#include "starfortress64/vehicles/arwing_ext.sp"




public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("starfortress64");
	
#if defined _sf64_gamerules_included
	SetupGameRulesAPI();
#endif

#if defined _sf64_music_included
	SetupMusicAPI();
#endif
	
	return APLRes_Success;
}

public OnPluginStart()
{
	g_offsPlayerFOV = FindSendPropInfo("CBasePlayer", "m_iFOV");
	if (g_offsPlayerFOV == -1) SetFailState("Couldn't find CBasePlayer offset for m_iFOV.");
	
	g_offsPlayerDefaultFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	if (g_offsPlayerDefaultFOV == -1) SetFailState("Couldn't find CBasePlayer offset for m_iDefaultFOV.");
	
	SetupSDK();
	
	g_hArwingConfigs = CreateTrie();
	
	g_hArwings = CreateArray(Arwing_MaxStats);
	g_hArwingNames = CreateTrie();
	
	g_hTargetReticles = CreateArray(TargetReticle_MaxStats);
	g_hLasers = CreateArray(Laser_MaxStats);
	g_hChargedLasers = CreateArray(ChargedLaser_MaxStats);
	g_hSBombs = CreateArray(SBomb_MaxStats);
	g_hPickups = CreateArray(Pickup_MaxStats);
	g_hPickupsGet = CreateArray(PickupGet_MaxStats);
	g_hEffects = CreateArray(Effect_MaxStats);
	
	g_cvFriendlyFire = FindConVar("mp_friendlyfire");
	HookConVarChange(g_cvFriendlyFire, OnConVarChanged);
	
	g_cvInfiniteBombs = CreateConVar("sf64_infinitebombs", "0", "Enable/Disable infinite bombs for all vehicles.");
	
#if defined DEBUG
	g_hHudSyncDebug = CreateHudSynchronizer();
#endif
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	
	RegAdminCmd("sm_sf64_spawn_arwing", Command_SpawnArwing, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sf64_forceintovehicle", Command_ForceIntoVehicle, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sf64_spawn_pickup", Command_SpawnPickup, ADMFLAG_CHEATS);
	
	AddCommandListener(Hook_CommandVoiceMenu, "voicemenu");
	
#if defined _sf64_hud_elements_included
	SetupHudElements();
#endif
	
#if defined _sf64_gamerules_included
	SetupGameRules();
#endif
	
#if defined _sf64_music_included
	SetupMusic();
#endif
	
#if defined _sf64_ai_nodegraph_included
	SetupAINodeGraph();
#endif

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == g_cvFriendlyFire)
	{
		g_bFriendlyFire = GetConVarBool(cvar);
	}
}

public Action:Hook_CommandVoiceMenu(client, const String:command[], argc)
{
	if (argc < 2) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	
	decl String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (StringToInt(arg1) == 0 && StringToInt(arg2) == 0)
	{
		new iVehicle = GetCurrentVehicle(client);
		if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
		{
			if (!IsVehicleLocked(iVehicle))
			{
				VehicleEjectPilot(iVehicle);
			}
			
			return Plugin_Handled;
		}
		else
		{
			decl Float:flEyePos[3], Float:flEyeAng[3], Float:flDirection[3], Float:flEndPos[3];
			GetClientEyePosition(client, flEyePos);
			GetClientEyeAngles(client, flEyeAng);
			GetAngleVectors(flEyeAng, flDirection, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(flDirection, flDirection);
			ScaleVector(flDirection, 300.0);
			AddVectors(flEyePos, flDirection, flEndPos);
			
			new Handle:hTrace = TR_TraceRayFilterEx(flEyePos, flEndPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitEntity, client);
			new bool:bHit = TR_DidHit(hTrace);
			new iHitEntity = TR_GetEntityIndex(hTrace);
			CloseHandle(hTrace);
			
			if (bHit && iHitEntity)
			{
				if (IsVehicle(iHitEntity))
				{
					if (!IsVehicleLocked(iHitEntity))
					{
						InsertPilotIntoVehicle(iHitEntity, client);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

SetupSDK()
{
	new Handle:hConfig = LoadGameConfigFile("starfortress64");
	if (hConfig == INVALID_HANDLE) 
	{
		CloseHandle(hConfig);
		SetFailState("Couldn't find plugin gamedata!");
	}
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConfig, SDKConf_Virtual, "CBaseEntity::GetSmoothedVelocity");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	if ((g_hSDKGetSmoothedVelocity = EndPrepSDKCall()) == INVALID_HANDLE) 
	{
		CloseHandle(hConfig);
		SetFailState("Failed to create SDKCall for CBaseEntity::GetSmoothedVelocity offset!");
	}
	
	CloseHandle(hConfig);
}

public OnMapStart()
{
}

#if defined DEBUG
public Action:Timer_HudUpdateDebug(Handle:timer)
{
	new iKitRifty = FindKitRifty();
	if (iKitRifty == -1) 
	{
		iKitRifty = 1;
	}
	
	if (!IsValidClient(iKitRifty)) return Plugin_Continue;
	
	new iEdictCount;
	for (new i = 0; i <= MAX_ENTITES; i++)
	{
		if (!IsValidEdict(i)) continue;
		iEdictCount++;
	}
	
	SetHudTextParams(0.05, 0.05, 
		1.0,
		255, 255, 255, 255,
		_,
		_,
		0.25, 1.25);
	
	ShowSyncHudText(iKitRifty, g_hHudSyncDebug, "SF64 - Entity Report:\n \nEdict count: %d\ng_hArwings: %d\ng_hLasers: %d\ng_hChargedLasers: %d\ng_hSBombs: %d\ng_hPickups: %d\ng_hEffects: %d\ng_hTargetReticles: %d",
		iEdictCount,
		GetArraySize(g_hArwings),
		GetArraySize(g_hLasers),
		GetArraySize(g_hChargedLasers),
		GetArraySize(g_hSBombs),
		GetArraySize(g_hPickups),
		GetArraySize(g_hEffects),
		GetArraySize(g_hTargetReticles));
	
	return Plugin_Continue;
}
#endif

PrecacheStuff()
{
#if defined _sf64_arwing_included
	PrecacheModel(ARWING_BARRELROLL_ROTATE_ENT_MODEL, true);
#endif

#if defined _sf64_arwing_ext_included
	PrecacheModel(ARWING_HEALTHBAR_MODEL, true);
#endif

#if defined _sf64_proj_laser_included
	PrecacheSound2(ARWING_LASER_HIT_NODAMAGE_SOUND);
#endif

#if defined _sf64_proj_chargedlaser_included
	PrecacheSound2(ARWING_CHARGEDLASER_HIT_SOUND);
#endif
	
#if defined _sf64_proj_smartbomb_included
	PrecacheSmartBomb();
#endif

#if defined _sf64_pickups_included
	PrecachePickups();
#endif
}

public OnConfigsExecuted()
{
	g_bFriendlyFire = GetConVarBool(g_cvFriendlyFire);
	
	PrecacheStuff();
	LoadAllArwingConfigs();
	
#if defined _sf64_ai_nodegraph_included
	AINodeGraphOnMapStart();
#endif
	
#if defined _sf64_gamerules_included
	GameRulesOnConfigsExecuted();
#endif

#if defined _sf64_music_included
	MusicOnConfigsExecuted();
#endif

	// Compensate for late load.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
	
#if defined DEBUG
	CreateTimer(0.1, Timer_HudUpdateDebug, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
#endif
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return;
	
#if defined _sf64_gamerules_included
	GameRulesOnEntityDestroyed(entity);
#endif

#if defined _sf64_music_included
	MusicOnEntityDestroyed(entity);
#endif
	
	new bool:bCheckForRemoval = true;
	new entref = EntIndexToEntRef(entity);
	new iIndex = -1;
	
#if defined _sf64_arwing_ext_included
	ArwingOnEntityDestroyed(entity);
#endif
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hTargetReticles))
		{
			iIndex = FindValueInArray(g_hTargetReticles, entref);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hTargetReticles, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hHudElements))
		{
			iIndex = FindValueInArray(g_hHudElements, entref);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hHudElements, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hPickups))
		{
			iIndex = FindValueInArray(g_hPickups, entref);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hPickups, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hPickupsGet))
		{
			iIndex = FindValueInArray(g_hPickupsGet, entref);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hPickupsGet, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hEffects))
		{
			iIndex = FindValueInArray(g_hEffects, entref);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hEffects, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
	
#if defined _sf64_proj_laser_included
	LaserOnEntityDestroyed(entity);
#endif
	
#if defined _sf64_proj_chargedlaser_included
	ChargedLaserOnEntityDestroyed(entity);
#endif
	
	if (bCheckForRemoval)
	{
		if (GetArraySize(g_hSBombs))
		{
			iIndex = FindValueInArray(g_hSBombs, entref);
			if (iIndex != -1)
			{
				StopSound(entity, SNDCHAN_STATIC, ARWING_SMARTBOMB_FLY_SOUND);
				
				RemoveFromArray(g_hSBombs, iIndex);
				bCheckForRemoval = false;
			}
		}
	}
}

public OnClientPutInServer(client)
{
	g_hPlayerVehicleSequenceTimer[client] = INVALID_HANDLE;
	g_flPlayerVehicleBlockVoiceTime[client] = 0.0;
	
	if (!IsFakeClient(client))
	{
		QueryClientConVar(client, "fov_desired", QueryClientDesiredFOV);
	}
	else
	{
		g_flPlayerDesiredFOV[client] = 90.0;
	}
	
	SDKHook(client, SDKHook_PreThink, Hook_ClientPreThink);
	
#if defined _sf64_ai_nodegraph_included
	AINodeGraphOnClientPutInServer(client);
#endif

#if defined _sf64_gamerules_included
	GameRulesOnClientPutInServer(client);
#endif

#if defined _sf64_music_included
	MusicOnClientPutInServer(client);
#endif
}

public QueryClientDesiredFOV(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result != ConVarQuery_Okay)
	{
		g_flPlayerDesiredFOV[client] = 90.0;
		return;
	}
	
	g_flPlayerDesiredFOV[client] = StringToFloat(cvarValue);
}

public OnClientDisconnect(client)
{
#if defined _sf64_gamerules_included
	GameRulesOnClientDisconnect(client);
#endif

#if defined _sf64_music_included
	MusicOnClientDisconnect(client);
#endif

	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
}

public OnClientDisconnect_Post(client)
{
	g_iPlayerLastButtons[client] = 0;
	g_flPlayerForwardMove[client] = 0.0;
	g_flPlayerSideMove[client] = 0.0;
}

public Hook_ClientPreThink(client)
{
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:DB)
{
#if defined _sf64_gamerules_included
	GameRulesOnTeamplayRoundStart(event);
#endif
}

public Event_RoundEnd(Handle:event, const String:name[], bool:DB)
{
#if defined _sf64_gamerules_included
	GameRulesOnTeamplayRoundEnd(event);
#endif
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:DB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
	
#if defined _sf64_gamerules_included
	GameRulesOnPlayerSpawn(event);
#endif
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:DB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
	
#if defined _sf64_gamerules_included
	GameRulesOnPlayerDeath(event);
#endif
}

public Event_PostInventoryApplication(Handle:event, const String:name[], bool:DB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
	{
		for (new i = 0; i <= 5; i++)
		{
			new iWeapon = GetPlayerWeaponSlot(client, i);
			if (IsValidEntity(iWeapon))
			{
				SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iWeapon, 0, 0, 0, 1);
			}
		}
		
		ClientRemoveAllWearables(client);
	}
}

public Action:Command_SpawnArwing(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_sf64_spawn_arwing <name>");
		return Plugin_Handled;
	}
	
	decl String:sName[64];
	GetCmdArg(1, sName, sizeof(sName));
	if (!sName[0]) return Plugin_Handled;
	
	decl Float:flEyePos[3], Float:flEyeAng[3], Float:flEndPos[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	new Handle:hTrace = TR_TraceRayFilterEx(flEyePos, flEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
	TR_GetEndPosition(flEndPos, hTrace);
	CloseHandle(hTrace);
	
	flEyeAng[0] = 0.0; flEyeAng[2] = 0.0;

	SpawnArwing(sName, flEndPos, flEyeAng, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action:Command_SpawnPickup(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_spawn_pickup <name> <quantity> [can respawn 0/1]");
		return Plugin_Handled;
	}
	
	decl String:sType[64];
	GetCmdArg(1, sType, sizeof(sType));
	if (!sType[0]) return Plugin_Handled;
	
	decl String:sQuantity[64];
	GetCmdArg(2, sQuantity, sizeof(sQuantity));
	if (!sQuantity[0]) return Plugin_Handled;
	
	new iType = PickupType_Invalid;
	if (StrEqual(sType, "laser")) iType = PickupType_Laser;
	else if (StrEqual(sType, "smartbomb")) iType = PickupType_SmartBomb;
	else if (StrEqual(sType, "ring")) iType = PickupType_Ring;
	else if (StrEqual(sType, "ring2")) iType = PickupType_Ring2;
	
	if (iType == PickupType_Invalid) return Plugin_Handled;
	
	new bool:bCanRespawn = false;
	if (args > 2)
	{
		decl String:sCanRespawn[64];
		GetCmdArg(3, sCanRespawn, sizeof(sCanRespawn));
		bCanRespawn = bool:StringToInt(sCanRespawn);
	}
	
	decl Float:flPos[3];
	GetClientAbsOrigin(client, flPos);
	
	SpawnPickup(iType, StringToInt(sQuantity), flPos, NULL_VECTOR, bCanRespawn);
	
	return Plugin_Handled;
}

public Action:Command_ForceIntoVehicle(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_sf64_forceintovehicle <#userid|name> [targetname]");
		return Plugin_Handled;
	}
	
	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	new iVehicle = INVALID_ENT_REFERENCE;
	
	if (args <= 1)
	{
		iVehicle = GetClientAimTarget(client, false);
		if (!IsVehicle(iVehicle))
		{
			ReplyToCommand(client, "Not pointing at a valid Arwing!");
			return Plugin_Handled;
		}
	}
	else
	{
		decl String:arg2[64];
		GetCmdArg(2, arg2, sizeof(arg2));
	
		for (new i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
		{
			new iArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
			if (!iArwing || iArwing == INVALID_ENT_REFERENCE) continue;
			
			decl String:sName[64];
			GetEntPropString(iArwing, Prop_Data, "m_iName", sName, sizeof(sName));
			if (StrEqual(sName, arg2, false))
			{
				iVehicle = iArwing;
				break;
			}
		}
	}
	
	if (iVehicle != INVALID_ENT_REFERENCE)
	{
		InsertPilotIntoVehicle(iVehicle, target_list[0]);
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	for (new i = 0; i < MAX_BUTTONS; i++)
	{
		new button = (1 << i);
		
		if ((buttons & button))
		{
			if (!(g_iPlayerLastButtons[client] & button)) OnClientButtonPress(client, button);
		}
		else if ((g_iPlayerLastButtons[client] & button)) OnClientButtonRelease(client, button);
	}
	
	g_iPlayerLastButtons[client] = buttons;
	g_flPlayerForwardMove[client] = vel[0] / 450.0;
	g_flPlayerSideMove[client] = vel[1] / 450.0;
	
#if defined _sf64_arwing_ext_included
	ArwingOnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
#endif
	
	return Plugin_Continue;
}

public OnClientButtonPress(client, iButton)
{
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle != -1) VehiclePressButton(iVehicle, iButton);
}

public OnClientButtonRelease(client, iButton)
{
	new iVehicle = GetCurrentVehicle(client);
	if (iVehicle != -1) VehicleReleaseButton(iVehicle, iButton);
}

public Phys_OnObjectSleep(ent)
{
	if (!IsValidEntity(ent)) return;
	
	if (IsVehicle(ent))
	{
		VehicleOnSleep(ent);
	}
}