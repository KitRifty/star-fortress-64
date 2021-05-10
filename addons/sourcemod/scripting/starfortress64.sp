#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <vphysics>
#include <tf2_stocks>
#include <starfortress64>

#define PLUGIN_VERSION "1.1.0"
#pragma newdecls required			// Force 1.7 Syntax.
#pragma semicolon 1

public Plugin myinfo = 
{
    name = "Star Fortress 64",
    author	= "KitRifty",
    description	= "A gamemode of flying space vehicles!",
    version = PLUGIN_VERSION,
    url = ""
}

//	#define DEBUG						// When debugging, outcomment it.


Handle g_hTargetReticles;
Handle g_hLasers;
Handle g_hChargedLasers;
Handle g_hSBombs;
Handle g_hPickups;
Handle g_hPickupsGet;
Handle g_hEffects;
Handle g_hHudElements;

bool g_bPlayerInvertedXAxis[MAXPLAYERS + 1] = { false, ... };
bool g_bPlayerInvertedYAxis[MAXPLAYERS + 1] = { true, ... };

int g_iPlayerLastButtons[MAXPLAYERS + 1];
float g_flPlayerForwardMove[MAXPLAYERS + 1];
float g_flPlayerSideMove[MAXPLAYERS + 1];
float g_flPlayerDesiredFOV[MAXPLAYERS + 1];
bool g_bPlayerDisableHUD[MAXPLAYERS + 1] = { false, ... };

Handle g_hPlayerVehicleSequenceTimer[MAXPLAYERS + 1];
float g_flPlayerVehicleBlockVoiceTime[MAXPLAYERS + 1];

Handle g_cvFriendlyFire;
bool g_bFriendlyFire;

Handle g_cvInfiniteBombs;

#if defined DEBUG
Handle g_hHudSyncDebug;
#endif

Handle g_hHudControls;

Handle g_hSDKGetSmoothedVelocity;

int g_offsPlayerFOV = -1;
int g_offsPlayerDefaultFOV = -1;

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




public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
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

public void OnPluginStart()
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

	g_hHudControls = CreateHudSynchronizer();
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	
	RegAdminCmd("sm_sf64_spawn_arwing", Command_SpawnArwing, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sf64_forceintovehicle", Command_ForceIntoVehicle, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sf64_spawn_pickup", Command_SpawnPickup, ADMFLAG_CHEATS);

	RegAdminCmd("sm_sf64_reloadconfigs", Command_ReloadConfigs, ADMFLAG_ROOT);
	
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

public void OnConVarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_cvFriendlyFire)
	{
		g_bFriendlyFire = GetConVarBool(cvar);
	}
}

public Action Hook_CommandVoiceMenu(int client, const char[] command, int argc)
{
	if (argc < 2) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (StringToInt(arg1) == 0 && StringToInt(arg2) == 0)
	{
		int iVehicle = GetCurrentVehicle(client);
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
			float flEyePos[3], flEyeAng[3], flDirection[3], flEndPos[3];
			GetClientEyePosition(client, flEyePos);
			GetClientEyeAngles(client, flEyeAng);
			GetAngleVectors(flEyeAng, flDirection, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(flDirection, flDirection);
			ScaleVector(flDirection, 300.0);
			AddVectors(flEyePos, flDirection, flEndPos);
			
			Handle hTrace = TR_TraceRayFilterEx(flEyePos, flEndPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayDontHitEntity, client);
			bool bHit = TR_DidHit(hTrace);
			int iHitEntity = TR_GetEntityIndex(hTrace);
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

void SetupSDK()
{
	Handle hConfig = LoadGameConfigFile("starfortress64");
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

#if defined DEBUG
public Action Timer_HudUpdateDebug(Handle timer)
{
	int iKitRifty = FindKitRifty();
	if (iKitRifty == -1) 
	{
		iKitRifty = 1;
	}
	
	if (!IsValidClient(iKitRifty)) return Plugin_Continue;
	
	int iEdictCount;
	for (int i = 0; i <= MAX_ENTITES; i++)
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

void PrecacheStuff()
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

public void OnConfigsExecuted()
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
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
	
#if defined DEBUG
	CreateTimer(0.1, Timer_HudUpdateDebug, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
#endif
}

public void OnEntityDestroyed(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return;
	
#if defined _sf64_gamerules_included
	GameRulesOnEntityDestroyed(entity);
#endif
	
	bool bCheckForRemoval = true;
	int entref = EntIndexToEntRef(entity);
	int iIndex = -1;
	
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

public void OnClientPutInServer(int client)
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

public void QueryClientDesiredFOV(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if (result != ConVarQuery_Okay)
	{
		g_flPlayerDesiredFOV[client] = 90.0;
		return;
	}
	
	g_flPlayerDesiredFOV[client] = StringToFloat(cvarValue);
}

public void OnClientDisconnect(int client)
{
#if defined _sf64_gamerules_included
	GameRulesOnClientDisconnect(client);
#endif

#if defined _sf64_music_included
	MusicOnClientDisconnect(client);
#endif

	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
}

public void OnClientDisconnect_Post(int client)
{
	g_iPlayerLastButtons[client] = 0;
	g_flPlayerForwardMove[client] = 0.0;
	g_flPlayerSideMove[client] = 0.0;
	g_bPlayerDisableHUD[client] = false;
}

public void Hook_ClientPreThink(int client)
{
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool DB)
{
#if defined _sf64_gamerules_included
	GameRulesOnTeamplayRoundStart(event);
#endif
}

public void Event_RoundEnd(Handle event, const char[] name, bool DB)
{
#if defined _sf64_gamerules_included
	GameRulesOnTeamplayRoundEnd(event);
#endif
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool DB)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
	
#if defined _sf64_gamerules_included
	GameRulesOnPlayerSpawn(event);
#endif
}

public void Event_PlayerDeath(Handle event, const char[] name, bool DB)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE) VehicleEjectPilot(iVehicle, true);
}

public void Event_PostInventoryApplication(Handle event, const char[] name, bool DB)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
	{
		for (int i = 0; i <= 5; i++)
		{
			int iWeapon = GetPlayerWeaponSlot(client, i);
			if (IsValidEntity(iWeapon))
			{
				SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iWeapon, 0, 0, 0, 1);
			}
		}
		
		ClientRemoveAllWearables(client);
	}
}

public Action Command_SpawnArwing(int client, int args)
{
	char sName[64], message[256];
	if (args > 0)
		GetCmdArg(1, sName, sizeof(sName));

	// If the arwing does not exist, let the player know which configs exist.
	Handle hConfig = GetArwingConfig(sName);
	if (hConfig == INVALID_HANDLE)
	{
		Handle hSnapshots = CreateTrieSnapshot(g_hArwingConfigs);
		if (hSnapshots != null)
		{
			// Cycle through all loaded configs to determine which exist, and then print them out.
			for (int i; i < GetTrieSize(g_hArwingConfigs); i++)
			{
				char sConfig[32];
				GetTrieSnapshotKey(hSnapshots, i, sConfig, sizeof(sConfig));

				if (message[0] == EOS)
					strcopy(message, sizeof(message), sConfig);
				else
					Format(message, sizeof(message), "%s, %s", message, sConfig);
			}
			delete hSnapshots;
		}

		if (message[0] != EOS)
			ReplyToCommand(client, "Usage: sm_sf64_spawn_arwing <%s>", message);
		else
			ReplyToCommand(client, "Error: There are currently no arwing configs loaded.");

		return Plugin_Handled;
	}
	
	float flEyePos[3], flEyeAng[3], flEndPos[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	Handle hTrace = TR_TraceRayFilterEx(flEyePos, flEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
	TR_GetEndPosition(flEndPos, hTrace);
	CloseHandle(hTrace);
	
	flEyeAng[0] = 0.0; flEyeAng[2] = 0.0;

	SpawnArwing(sName, flEndPos, flEyeAng, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action Command_SpawnPickup(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_spawn_pickup <laser, smartbomb, ring, ring2> <quantity> [can respawn 0/1]");
		return Plugin_Handled;
	}
	
	char sType[64];
	GetCmdArg(1, sType, sizeof(sType));
	if (!sType[0]) return Plugin_Handled;
	
	char sQuantity[64];
	GetCmdArg(2, sQuantity, sizeof(sQuantity));
	if (!sQuantity[0]) return Plugin_Handled;
	
	int iType = PickupType_Invalid;
	if (StrEqual(sType, "laser")) iType = PickupType_Laser;
	else if (StrEqual(sType, "smartbomb")) iType = PickupType_SmartBomb;
	else if (StrEqual(sType, "ring")) iType = PickupType_Ring;
	else if (StrEqual(sType, "ring2")) iType = PickupType_Ring2;
	
	if (iType == PickupType_Invalid) return Plugin_Handled;
	
	bool bCanRespawn = false;
	if (args > 2)
	{
		char sCanRespawn[64];
		GetCmdArg(3, sCanRespawn, sizeof(sCanRespawn));
		bCanRespawn = view_as<bool>(StringToInt(sCanRespawn));
	}
	
	float flPos[3];
	GetClientAbsOrigin(client, flPos);
	
	SpawnPickup(iType, StringToInt(sQuantity), flPos, NULL_VECTOR, bCanRespawn);
	
	return Plugin_Handled;
}

public Action Command_ForceIntoVehicle(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_sf64_forceintovehicle <#userid|name> [targetname]");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
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
	
	int iVehicle = INVALID_ENT_REFERENCE;
	
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
		char arg2[64];
		GetCmdArg(2, arg2, sizeof(arg2));
	
		for (int i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
		{
			int iArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
			if (!iArwing || iArwing == INVALID_ENT_REFERENCE) continue;
			
			char sName[64];
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

public Action Command_ReloadConfigs(int client, int args)
{
	LoadAllArwingConfigs();
	ReplyToCommand(client, "Arwing configs have been reloaded! Existing arwings will keep their current configs.");

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int button = (1 << i);
		
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

public void OnClientButtonPress(int client, int iButton)
{
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle != -1) VehiclePressButton(iVehicle, iButton);
}

public void OnClientButtonRelease(int client, int iButton)
{
	int iVehicle = GetCurrentVehicle(client);
	if (iVehicle != -1) VehicleReleaseButton(iVehicle, iButton);
}

public int Phys_OnObjectSleep(int ent)
{
	if (!IsValidEntity(ent)) return;
	
	if (IsVehicle(ent))
	{
		VehicleOnSleep(ent);
	}
}