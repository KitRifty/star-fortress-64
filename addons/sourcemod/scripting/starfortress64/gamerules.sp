#if defined _sf64_gamerules_included
  #endinput
#endif
#define _sf64_gamerules_included

// Round variables.
static int g_iGameRoundState = SF64RoundState_Unknown;	// Current state of the round.
static Handle g_hGameRoundTimer;							// The round timer.
static int g_iGameRoundTime;									// Current round time.

static int g_iGameMinPlayers = 0;							// Minimum amount of players required for this gamemode.
static int g_iGameMaxPlayers = -2;							// -1 = limited to player spawns, -2 = all players, every other number is the limit of players.

// Game option variables.
static int g_iGameType = SF64GameType_None;				// Current game type.
static bool g_bGameRestrictToVehicles = false;			// If true, this will force players to spawn in a vehicle of their choice, but their vehicle will automatically lock upon entering.
static bool g_bGameRestrictSuicideInVehicles = false;	// If true, this will prevent players from using suicide commands while piloting a vehicle.
static bool g_bGameUseQueue = false;						// If true, this will allow players to queue into the game by choice.
static bool g_bGameFreeForAll = false;					// If true, this game will be a free-for-all based gametype.

static Handle g_hQueueList;

static bool g_bPlayerInGame[MAXPLAYERS + 1] = { false, ... };
static bool g_bPlayerEliminated[MAXPLAYERS + 1] = { false, ... };
static bool g_bPlayerInWarmup[MAXPLAYERS + 1] = { false, ... };
static int g_iPlayerVehicleSpawnType[MAXPLAYERS + 1] = { VehicleType_Unknown, ... };
static char g_strPlayerVehicleSpawnName[MAXPLAYERS + 1][64];

static Handle g_hPlayerVehicles[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
static Handle g_hPlayerVehicleTypes[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

// For g_hGameSpawnedVehicles, consists of two data thingies: 0 = entref to vehicle, 1 = reason for creation, 2 = some other stupid parameter thing.
// Reasons for creation: 0 = created by map spawner, 1 = created through warmup mode, 2 = create for gameplay purposes.

static Handle g_hVehicleSpawnPoints;
static Handle g_hGameSpawnedVehicles;
static Handle g_hPlayerSpawnPoints;

static Handle g_hBoundaryTriggers;

static Handle g_hHudSyncTimer;

// Forwards!
static Handle g_fGameOnRoundStateStart;
static Handle g_fGameOnRoundStateEnd;
static Handle g_fGameOnGetGameType;
static Handle g_hGameOnRequestVehiclesForPlayer;
static Handle g_hGameOnSaveVehiclesForPlayer;


void SetupGameRules()
{
	g_hHudSyncTimer = CreateHudSynchronizer();
	
	g_hVehicleSpawnPoints = CreateArray(4);
	g_hGameSpawnedVehicles = CreateArray(3);
	g_hPlayerSpawnPoints = CreateArray(2);
	g_hBoundaryTriggers = CreateArray(2);
	
	g_hQueueList = CreateArray();
	
	AddCommandListener(Hook_GameRulesCommandSuicide, "kill");
	AddCommandListener(Hook_GameRulesCommandSuicide, "explode");
	AddCommandListener(Hook_GameRulesCommandSuicide, "explodevector");
	AddCommandListener(Hook_GameRulesCommandSuicide, "join_class");
	AddCommandListener(Hook_GameRulesCommandSuicide, "joinclass");
	AddCommandListener(Hook_GameRulesCommandSuicide, "jointeam");
	AddCommandListener(Hook_GameRulesCommandSuicide, "spectate");
	
	RegAdminCmd("sm_sf64_setqueuestate", Command_SetQueueState, ADMFLAG_ROOT);
	RegConsoleCmd("sm_queue", Command_Queue);
}

void SetupGameRulesAPI()
{
	g_fGameOnRoundStateStart = CreateGlobalForward("SF64_GameRulesOnRoundStateStart", ET_Ignore, Param_Cell);
	g_fGameOnRoundStateEnd = CreateGlobalForward("SF64_GameRulesOnRoundStateEnd", ET_Ignore, Param_Cell);
	
	g_fGameOnGetGameType = CreateGlobalForward("SF64_GameRulesOnGetGameType", ET_Ignore, Param_String);
	
	g_hGameOnRequestVehiclesForPlayer = CreateGlobalForward("SF64_GameRulesOnRequestVehiclesForPlayer", ET_Ignore, Param_Cell);
	g_hGameOnSaveVehiclesForPlayer = CreateGlobalForward("SF64_GameRulesOnSaveVehiclesForPlayer", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	CreateNative("SF64_GameRulesGetGameType", Native_GameRulesGetGameType);
	CreateNative("SF64_GameRulesSetGameType", Native_GameRulesSetGameType);
	CreateNative("SF64_GameRulesGetMinPlayers", Native_GameRulesGetMinPlayers);
	CreateNative("SF64_GameRulesSetMinPlayers", Native_GameRulesSetMinPlayers);
	CreateNative("SF64_GameRulesGetMaxPlayers", Native_GameRulesGetMaxPlayers);
	CreateNative("SF64_GameRulesSetMaxPlayers", Native_GameRulesSetMaxPlayers);
	CreateNative("SF64_GameRulesGetRestrictToVehicles", Native_GameRulesGetRestrictToVehicles);
	CreateNative("SF64_GameRulesSetRestrictToVehicles", Native_GameRulesSetRestrictToVehicles);
	CreateNative("SF64_GameRulesGetRestrictSuicideInVehicles", Native_GameRulesGetRestrictSuicideInVehicles);
	CreateNative("SF64_GameRulesSetRestrictSuicideInVehicles", Native_GameRulesSetRestrictSuicideInVehicles);
	CreateNative("SF64_GameRulesGetUseQueue", Native_GameRulesGetUseQueue);
	CreateNative("SF64_GameRulesSetUseQueue", Native_GameRulesSetUseQueue);
	CreateNative("SF64_GameRulesGetQueueList", Native_GameRulesGetQueueList);
	CreateNative("SF64_GameRulesGetFreeForAll", Native_GameRulesGetFreeForAll);
	CreateNative("SF64_GameRulesSetFreeForAll", Native_GameRulesSetFreeForAll);
	CreateNative("SF64_GameRulesGetRoundState", Native_GameRulesGetRoundState);
	CreateNative("SF64_GameRulesSetRoundState", Native_GameRulesSetRoundState);
	CreateNative("SF64_GameRulesGetValidPlayerSpawnPoints", Native_GameRulesGetValidPlayerSpawnPoints);
	CreateNative("SF64_GameRulesIsPlayerInGame", Native_GameRulesIsPlayerInGame);
	CreateNative("SF64_GameRulesSetInGameStateOfPlayer", Native_GameRulesSetInGameStateOfPlayer);
	CreateNative("SF64_GameRulesIsPlayerEliminated", Native_GameRulesIsPlayerEliminated);
	CreateNative("SF64_GameRulesSetEliminatedStateOfPlayer", Native_GameRulesSetEliminatedStateOfPlayer);
	CreateNative("SF64_GameRulesIsPlayerInWarmup", Native_GameRulesIsPlayerInWarmup);
	CreateNative("SF64_GameRulesSetWarmupStateOfPlayer", Native_GameRulesSetWarmupStateOfPlayer);
	CreateNative("SF64_GameRulesGetRoundTime", Native_GameRulesGetRoundTime);
	CreateNative("SF64_GameRulesInitializeRoundTimer", Native_GameRulesInitializeRoundTimer);
	CreateNative("SF64_GameRulesStopRoundTimer", Native_GameRulesStopRoundTimer);
	CreateNative("SF64_GameRulesGivePlayerVehicle", Native_GameRulesGivePlayerVehicle);
	CreateNative("SF64_GameRulesSetPlayerVehicle", Native_GameRulesSetPlayerVehicle);
	CreateNative("SF64_GameRulesRequestVehiclesForPlayer", Native_GameRulesRequestVehiclesForPlayer);
	CreateNative("SF64_GameRulesSaveVehiclesForPlayer", Native_GameRulesSaveVehiclesForPlayer);
}

void GameRulesSetGameType(int iGameType)
{
	DebugMessage("START GameRulesSetGameType(%d)", iGameType);
	
	g_iGameType = iGameType;
	g_iGameMinPlayers = MaxClients;
	g_iGameMaxPlayers = -2;
	g_bGameRestrictToVehicles = false;
	g_bGameRestrictSuicideInVehicles = false;
	g_bGameUseQueue = false;
	g_bGameFreeForAll = false;
	
	DebugMessage("END GameRulesSetGameType(%d)", iGameType);
}

void GameRulesSetRoundState(int iRoundState)
{
	if (g_iGameRoundState == iRoundState) return;
	
	DebugMessage("START GameRulesSetRoundState(%d)", iRoundState);
	
	int iOldRoundState = g_iGameRoundState;
	g_iGameRoundState = iRoundState;
	
	GameRulesOnRoundStateEnd(iOldRoundState);
	GameRulesOnRoundStateStart(iRoundState);
	
	DebugMessage("END GameRulesSetRoundState(%d)", iRoundState);
}

public void GameRulesOnRoundStateStart(int iRoundState)
{
	DebugMessage("START GameRulesOnRoundStateStart(%d)", iRoundState);

	switch (iRoundState)
	{
		case SF64RoundState_Active:
		{
			if (g_bGameUseQueue)
			{
				int iNumPlayers = g_iGameMaxPlayers;
				if (iNumPlayers == -1) iNumPlayers = GetArraySize(g_hPlayerSpawnPoints);
				else if (iNumPlayers == -2) iNumPlayers = MaxClients;
				
				for (int i = 0, iSize = GetArraySize(g_hQueueList); i < iNumPlayers && i < iSize && GetArraySize(g_hQueueList); i++)
				{
					int client = GetArrayCell(g_hQueueList, 0);
					RemoveFromArray(g_hQueueList, 0);
					
					GameRulesSetInGameStateOfPlayer(client, true);
				}
			}
		}
	}
	
	Call_StartForward(g_fGameOnRoundStateStart);
	Call_PushCell(iRoundState);
	Call_Finish();
	
	DebugMessage("END GameRulesOnRoundStateStart(%d)", iRoundState);
}

public void GameRulesOnRoundStateEnd(int iRoundState)
{
	DebugMessage("START GameRulesOnRoundStateEnd(%d)", iRoundState);

	switch (iRoundState)
	{
		case SF64RoundState_Warmup:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				
				GameRulesSetWarmupStateOfPlayer(i, false);
			}
		}
		case SF64RoundState_Active:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				g_bPlayerInGame[i] = false;
				g_bPlayerEliminated[i] = false;
			}
			
			Handle hSpawnedVehicles = CloneArray(g_hGameSpawnedVehicles);
			
			for (int i = 0, iSize = GetArraySize(hSpawnedVehicles); i < iSize; i++)
			{
				int iVehicle = EntRefToEntIndex(GetArrayCell(hSpawnedVehicles, i));
				if (!iVehicle || iVehicle == INVALID_ENT_REFERENCE) continue;
				
				if (GetArrayCell(hSpawnedVehicles, i, 1) == 2)
				{
					int iPilot = VehicleGetPilot(iVehicle);
					if (iPilot && iPilot != INVALID_ENT_REFERENCE)
					{
						VehicleEjectPilot(iVehicle, true);
						if (iPilot > 0 && iPilot <= MaxClients)
						{
							TF2_RespawnPlayer(iPilot);
						}
					}
					
					AcceptEntityInput(iVehicle, "Kill");
				}
			}
			
			CloseHandle(hSpawnedVehicles);
		}
	}
	
	Call_StartForward(g_fGameOnRoundStateEnd);
	Call_PushCell(iRoundState);
	Call_Finish();
	
	DebugMessage("END GameRulesOnRoundStateEnd(%d)", iRoundState);
}

public Action Hook_GameRulesCommandSuicide(int client, const char[] command, int argc)
{
	if (g_iGameRoundState == SF64RoundState_Active)
	{
		if (g_bPlayerInGame[client])
		{
			if (g_bGameRestrictSuicideInVehicles)
			{
				int iVehicle = GetCurrentVehicle(client);
				if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public void GameRulesOnConfigsExecuted()
{
	ClearArray(g_hQueueList);
	ClearArray(g_hVehicleSpawnPoints);
	ClearArray(g_hGameSpawnedVehicles);
	ClearArray(g_hPlayerSpawnPoints);
	
	GameRulesSetGameType(SF64GameType_None);
	g_iGameRoundState = SF64RoundState_Unknown;
	
	char sGameType[64];
	
	// Get the game type entity.
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "info_target")) != -1)
	{
		char sTargetName[64];
		GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		
		if (!StrContains(sTargetName, "sf64_gametype_", false))
		{
			ReplaceString(sTargetName, sizeof(sTargetName), "sf64_gametype_", "", false);
			strcopy(sGameType, sizeof(sGameType), sTargetName);
			break;
		}
	}
	
	OnGetGameRulesGameType(sGameType);
}

public void GameRulesOnEntityDestroyed(int entity)
{
	int entref = EntIndexToEntRef(entity);
	
	int iIndex = FindValueInArray(g_hGameSpawnedVehicles, entref);
	if (iIndex != -1)
	{
		RemoveFromArray(g_hGameSpawnedVehicles, iIndex);
	}
}

void GameRulesGivePlayerVehicle(int client, int iVehicleType, const char[] sVehicleName)
{
	int iIndex = FindStringInArray(g_hPlayerVehicles[client], sVehicleName);
	if (iIndex != -1 && GetArrayCell(g_hPlayerVehicleTypes[client], iIndex) == iVehicleType) return; // Player already has this vehicle.

	PushArrayString(g_hPlayerVehicles[client], sVehicleName);
	PushArrayCell(g_hPlayerVehicleTypes[client], iVehicleType);
}

void GameRulesRequestVehiclesForPlayer(int client)
{
	Call_StartForward(g_hGameOnRequestVehiclesForPlayer);
	Call_PushCell(client);
	Call_Finish();
}

public void GameRulesOnClientPutInServer(int client)
{
	g_iPlayerVehicleSpawnType[client] = VehicleType_Unknown;
	strcopy(g_strPlayerVehicleSpawnName[client], sizeof(g_strPlayerVehicleSpawnName[]), "");
	
	g_bPlayerInGame[client] = false;
	g_bPlayerEliminated[client] = false;
	
	GameRulesSetWarmupStateOfPlayer(client, false);
	
	// Get vehicles. Call external forward to help populate our list.
	g_hPlayerVehicles[client] = CreateArray();
	g_hPlayerVehicleTypes[client] = CreateArray();
	
	GameRulesRequestVehiclesForPlayer(client);
}

void GameRulesSaveVehiclesForPlayer(int client)
{
	Call_StartForward(g_hGameOnSaveVehiclesForPlayer);
	Call_PushCell(client);
	Call_PushCell(g_hPlayerVehicles[client]);
	Call_PushCell(g_hPlayerVehicleTypes[client]);
	Call_Finish();
}

public void GameRulesOnClientDisconnect(int client)
{
	g_iPlayerVehicleSpawnType[client] = VehicleType_Unknown;
	strcopy(g_strPlayerVehicleSpawnName[client], sizeof(g_strPlayerVehicleSpawnName[]), "");
	
	g_bPlayerInGame[client] = false;
	g_bPlayerEliminated[client] = false;
	
	GameRulesSetWarmupStateOfPlayer(client, false);
	
	// Delete from queue list.
	{
		int iIndex = FindValueInArray(g_hQueueList, client);
		if (iIndex != -1) RemoveFromArray(g_hQueueList, iIndex);
	}
	
	GameRulesSaveVehiclesForPlayer(client);
	
	if (g_hPlayerVehicles[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerVehicles[client]);
		g_hPlayerVehicles[client] = INVALID_HANDLE;
	}
	
	if (g_hPlayerVehicleTypes[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerVehicleTypes[client]);
		g_hPlayerVehicleTypes[client] = INVALID_HANDLE;
	}
}

public void GameRulesOnTeamplayRoundStart(Handle event)
{
	DebugMessage("START GameRulesOnTeamplayRoundStart(event)");

	ClearArray(g_hVehicleSpawnPoints);
	ClearArray(g_hGameSpawnedVehicles);
	ClearArray(g_hPlayerSpawnPoints);
	ClearArray(g_hBoundaryTriggers);
	
	// Gather up all valid player spawn points.
	char sTargetName[64];
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "info_target")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		
		if (!StrContains(sTargetName, "sf64_player_start", false))
		{
			int iIndex = PushArrayCell(g_hPlayerSpawnPoints, EntIndexToEntRef(ent));
		
			if (!StrContains(sTargetName, "sf64_player_start_", false))
			{
				if (StrEqual(sTargetName, "sf64_player_start_red", false))
				{
					SetArrayCell(g_hPlayerSpawnPoints, iIndex, view_as<int>(TFTeam_Red), 1);
				}
				else if (StrEqual(sTargetName, "sf64_player_start_blue", false))
				{
					SetArrayCell(g_hPlayerSpawnPoints, iIndex, view_as<int>(TFTeam_Blue), 1);
				}
				else
				{
					// Free spawn for all, but warn them this time.
					PrintToServer("Warning! %s has unknown suffix! Defaulting to all teams.", sTargetName);
					SetArrayCell(g_hPlayerSpawnPoints, iIndex, 0, 1);
				}
			}
			else
			{
				// Free spawn for all.
				SetArrayCell(g_hPlayerSpawnPoints, iIndex, 0, 1);
			}
		}
	}
	
	PrintToServer("Gathered %d player spawn points", GetArraySize(g_hPlayerSpawnPoints));
	
	// Gather up all valid vehicle spawn points.
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "info_target")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		
		if (!StrContains(sTargetName, "sf64_vehicle_spawn_", false))
		{
			char sParameterString[64];
			char sParameters[16][64];
			
			strcopy(sParameterString, sizeof(sParameterString), sTargetName);
			ReplaceString(sParameterString, sizeof(sParameterString), "sf64_vehicle_spawn_", "", false);
			int iParameterNum = ExplodeString(sParameterString, "_", sParameters, 16, 64);
			
			if (iParameterNum > 0)
			{
				// First parameter is the vehicle type to spawn.
				int iVehicleType = GetVehicleTypeFromString(sParameters[0]);
				if (iVehicleType != VehicleType_Unknown)
				{
					int iSpawnMax = 1;
					float flSpawnDelay = 15.0;
					
					if (iParameterNum > 1)
					{
						// Second parameter is how many vehicles can be active at once.
						iSpawnMax = StringToInt(sParameters[1]);
						
						if (iParameterNum > 2)
						{
							// Third parameter is the delay vehicles spawn at this spawner.
							flSpawnDelay = StringToFloat(sParameters[2]);
						}
					}
					
					int iIndex = PushArrayCell(g_hVehicleSpawnPoints, EntIndexToEntRef(ent));
					SetArrayCell(g_hVehicleSpawnPoints, iIndex, iVehicleType, 1);
					SetArrayCell(g_hVehicleSpawnPoints, iIndex, iSpawnMax, 2);
					SetArrayCell(g_hVehicleSpawnPoints, iIndex, flSpawnDelay, 3);
				}
				else
				{
					PrintToServer("Error! Entity %s has invalid vehicle type parameter of (%s), skipping...", sParameters[0]);
				}
			}
		}
	}
	
	PrintToServer("Gathered %d vehicle spawn points", GetArraySize(g_hVehicleSpawnPoints));
	
	// Gather up all the boundary triggers.
	ent = -1;
	while ((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
		
		if (!StrContains(sTargetName, "sf64_boundary", false))
		{
			char sRefTargetName[64];
			char sTargetName2[64];
			
			Format(sRefTargetName, sizeof(sRefTargetName), "%s_ref", sTargetName);
			
			bool bFoundRef = false;
			
			int iRef = -1;
			while ((iRef = FindEntityByClassname(iRef, "info_target")) != -1)
			{
				GetEntPropString(iRef, Prop_Data, "m_iName", sTargetName2, sizeof(sTargetName2));
				if (StrEqual(sTargetName2, sRefTargetName, false))
				{
					bFoundRef = true;
					int iIndex = PushArrayCell(g_hBoundaryTriggers, EntIndexToEntRef(ent));
					SetArrayCell(g_hBoundaryTriggers, iIndex, EntIndexToEntRef(iRef), 1);
					
					SDKUnhook(ent, SDKHook_TouchPost, Hook_GameRulesBoundaryOnTouchPost);
					SDKHook(ent, SDKHook_TouchPost, Hook_GameRulesBoundaryOnTouchPost);
					break;
				}
			}
			
			if (!bFoundRef)
			{
				PrintToServer("Error! Entity %s has no reference entity, skipping...", sTargetName);
			}
		}
	}
	
	PrintToServer("Gathered %d boundary triggers", GetArraySize(g_hBoundaryTriggers));
	
	DebugMessage("END GameRulesOnTeamplayRoundStart(event)");
}

public void Hook_GameRulesBoundaryOnTouchPost(int iBoundary, int other)
{
	int iIndex = FindValueInArray(g_hBoundaryTriggers, EntIndexToEntRef(iBoundary));
	if (iIndex == -1) return;
	
	int iRef = EntRefToEntIndex(GetArrayCell(g_hBoundaryTriggers, iIndex, 1));
	if (iRef && iRef != INVALID_ENT_REFERENCE)
	{
		if (IsVehicle(other))
		{
			VehicleOnTouchingBoundary(other, iBoundary, iRef);
		}
	}
}

public void OnGetGameRulesGameType(const char[] sType)
{
	DebugMessage("START OnGetGameRulesGameType(%s)", sType);
	
	Call_StartForward(g_fGameOnGetGameType);
	Call_PushString(sType);
	Call_Finish();
	
	DebugMessage("END OnGetGameRulesGameType(%s)", sType);
}

public void GameRulesOnTeamplayRoundEnd(Handle event)
{
	GameRulesStopRoundTimer();
}

Handle GameRulesGetValidPlayerSpawnPoints(int client, bool bCheckCollision=false, const float flMins[3]=NULL_VECTOR, const float flMaxs[3]=NULL_VECTOR)
{
	// Get a list of spawn points we can spawn at.
	Handle hSpawnPoints = CreateArray();
	for (int i = 0, iSize = GetArraySize(g_hPlayerSpawnPoints); i < iSize; i++)
	{
		int iEnt = EntRefToEntIndex(GetArrayCell(g_hPlayerSpawnPoints, i));
		if (!iEnt || iEnt == INVALID_ENT_REFERENCE) continue;
		
		int iTeam = GetArrayCell(g_hPlayerSpawnPoints, i, 1);
		if (g_bGameFreeForAll || iTeam == GetClientTeam(client) || iTeam == 0)
		{
			if (bCheckCollision)
			{
				float flPos[3];
				GetEntPropVector(iEnt, Prop_Data, "m_vecAbsOrigin", flPos);
				
				Handle hTrace = TR_TraceHullEx(flPos, flPos, flMins, flMaxs, MASK_NPCSOLID);
				bool bHit = TR_DidHit(hTrace);
				CloseHandle(hTrace);
				
				if (bHit) continue; // space is occupied!
			}
		
			PushArrayCell(hSpawnPoints, iEnt);
		}
	}
	
	return hSpawnPoints;
}

public void GameRulesOnPlayerSpawn(Handle event)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsPlayerAlive(client)) return;
	
	if (g_iGameRoundState == SF64RoundState_Active ||
		g_iGameRoundState == SF64RoundState_Warmup)
	{
		if (g_bPlayerInGame[client])
		{
			if (g_bGameRestrictToVehicles)
			{
				if (g_iGameRoundState == SF64RoundState_Active && g_bPlayerEliminated[client])
				{
					// DO nothing; guy got eliminated.
				}
				else if (g_iGameRoundState == SF64RoundState_Warmup && !g_bPlayerInWarmup[client])
				{
					// DO nothing; guy isn't in warmup mode.
				}
				else
				{
					// Get a list of spawn points we can spawn at.
					Handle hSpawnPoints = GameRulesGetValidPlayerSpawnPoints(client, true, view_as<float>({ -256.0, -256.0, 0.0 }), view_as<float>({ 256.0, 256.0, 512.0 }));
					if (GetArraySize(hSpawnPoints) == 0)
					{
						CloseHandle(hSpawnPoints);
						hSpawnPoints = GameRulesGetValidPlayerSpawnPoints(client);
						PrintToServer("Warning! All player spawn points occupied; ignoring collision checks");
					}
					
					if (GetArraySize(hSpawnPoints) > 0)
					{
						if (g_iPlayerVehicleSpawnType[client] != VehicleType_Unknown)
						{
							if (GetConfigFromVehicleName(g_iPlayerVehicleSpawnType[client], g_strPlayerVehicleSpawnName[client]) != INVALID_HANDLE)
							{
								int iSpawnPoint = GetArrayCell(hSpawnPoints, GetRandomInt(0, GetArraySize(hSpawnPoints) - 1));
							
								float flPos[3], flAng[3];
								GetEntPropVector(iSpawnPoint, Prop_Data, "m_vecAbsOrigin", flPos);
								GetEntPropVector(iSpawnPoint, Prop_Data, "m_angAbsRotation", flAng);
								
								int iVehicle = SpawnVehicle(g_iPlayerVehicleSpawnType[client], g_strPlayerVehicleSpawnName[client], flPos, flAng, NULL_VECTOR);
								if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
								{
									TeleportEntity(client, flPos, flAng, NULL_VECTOR);
								
									VehicleLock(iVehicle);
									InsertPilotIntoVehicle(iVehicle, client, true);
									
									int iIndex = PushArrayCell(g_hGameSpawnedVehicles, EntIndexToEntRef(iVehicle));
									
									if (g_iGameRoundState == SF64RoundState_Active)
									{
										SetArrayCell(g_hGameSpawnedVehicles, iIndex, 2, 1);
									}
									else
									{
										SetArrayCell(g_hGameSpawnedVehicles, iIndex, 1, 1);
									}
								}
								else
								{
									PrintToServer("Could not spawn non-existent vehicle for player %N", client);
								}
							}
							else
							{
								PrintToServer("Could not spawn non-existent vehicle config for player %N", client);
							}
						}
						else
						{
							PrintToServer("Could not spawn unknown vehicle type for player %N", client);
						}
					}
					else
					{
						PrintToServer("Could not find good spawn point for player %N", client);
					}
					
					CloseHandle(hSpawnPoints);
				}
			}
		}
	}
}

void GameRulesSetInGameStateOfPlayer(int client, bool bState)
{
	if (!IsValidClient(client)) return;
	
	if (bState == g_bPlayerInGame[client]) return;
	
	if (bState)
	{
		g_bPlayerInGame[client] = true;
		TF2_RespawnPlayer(client);
	}
	else
	{
		g_bPlayerInGame[client] = false;
		TF2_RespawnPlayer(client);
	}
}

void GameRulesSetWarmupStateOfPlayer(int client, bool bState)
{
	if (!IsValidClient(client)) return;
	
	if (bState == g_bPlayerInWarmup[client]) return;
	
	if (bState)
	{
		if (g_bGameRestrictToVehicles)
		{
			Handle hSpawnPoints = GameRulesGetValidPlayerSpawnPoints(client);
			if (GetArraySize(hSpawnPoints) > 0)
			{
				// Warmup mode is only available when vehicles are in restriction mode, since we don't want players getting out of them anyway.
				g_bPlayerInWarmup[client] = true;
				TF2_RespawnPlayer(client);
			}
			
			CloseHandle(hSpawnPoints);
		}
	}
	else
	{
		g_bPlayerInWarmup[client] = false;
		
		int iVehicle = GetCurrentVehicle(client);
		if (iVehicle && iVehicle != INVALID_ENT_REFERENCE)
		{
			VehicleEjectPilot(iVehicle, true);
			TF2_RespawnPlayer(client);
			
			int iIndex = FindValueInArray(g_hGameSpawnedVehicles, EntIndexToEntRef(iVehicle));
			if (iIndex != -1)
			{
				if (GetArrayCell(g_hGameSpawnedVehicles, iIndex, 1) == 1)
				{
					// Spawned for warmup mode; delete.
					AcceptEntityInput(iVehicle, "Kill");
				}
			}
		}
	}
}

void GameRulesInitializeRoundTimer(int iRoundTime, Handle hCallbackPlugin=INVALID_HANDLE, Function fCallback=INVALID_FUNCTION)
{
	DebugMessage("START GameRulesInitializeRoundTimer(%d, %d)", iRoundTime, hCallbackPlugin);

	g_iGameRoundTime = iRoundTime;
	Handle hPack;
	g_hGameRoundTimer = CreateDataTimer(1.0, Timer_GameRound, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(hPack, hCallbackPlugin);
	WritePackFunction(hPack, fCallback);
	
	TriggerTimer(g_hGameRoundTimer, true);
	
	DebugMessage("END GameRulesInitializeRoundTimer(%d, %d)", iRoundTime, hCallbackPlugin);
}

void GameRulesStopRoundTimer()
{
	g_hGameRoundTimer = INVALID_HANDLE;
}

public Action Timer_GameRound(Handle timer, Handle hPack)
{
	if (timer != g_hGameRoundTimer) return Plugin_Stop;
	
	if (g_iGameRoundTime > 0)
	{
		int hours, minutes, seconds;
		FloatToTimeHMS(float(g_iGameRoundTime), hours, minutes, seconds);
	
		SetHudTextParams(-1.0, 0.1, 
			1.0,
			255, 255, 255, 255,
			_,
			_,
			1.5, 1.5);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			
			ShowSyncHudText(i, g_hHudSyncTimer, "%d:%02d", minutes, seconds);
		}
	}
	else
	{
		g_hGameRoundTimer = INVALID_HANDLE;
	
		ResetPack(hPack);
		Handle hCallbackPlugin = ReadPackCell(hPack);
		Function fCallback = ReadPackFunction(hPack);
		
		Call_StartFunction(hCallbackPlugin, fCallback);
		Call_Finish();
		
		return Plugin_Stop;
	}
	
	g_iGameRoundTime--;
	
	return Plugin_Continue;
}

public Action Command_Queue(int client, int args)
{
	if (!g_bGameUseQueue) return Plugin_Continue;
	GameRulesSendQueueMenu(client);
	return Plugin_Handled;
}

public Action Command_SetQueueState(int client, int args)
{
	if (!g_bGameUseQueue) return Plugin_Continue;
	
	if (args < 2)
	{
		ReplyToCommand(client, "sm_sf64_setqueuestate <name|#userid> <0/1>");
		return Plugin_Handled;
	}
	
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	bool bState = view_as<bool>(StringToInt(arg2));
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		if (bState)
		{
			if (FindValueInArray(g_hQueueList, target) == -1)
			{
				PushArrayCell(g_hQueueList, target);
				ReplyToCommand(client, "You have added %N to the queue list.", target);
				PrintToChat(target, "You have been added to the queue list by %N.", client);
			}
		}
		else
		{
			int iIndex = FindValueInArray(g_hQueueList, target);
			if (iIndex != -1)
			{
				RemoveFromArray(g_hQueueList, iIndex);
				ReplyToCommand(client, "You have removed %N from the queue list.", target);
				PrintToChat(target, "You have been removed from the queue list by %N.", client);
			}
		}
	}
	
	return Plugin_Handled;
}

void GameRulesSendQueueMenu(int client)
{
	if (!g_bGameUseQueue) return;
	
	Menu hMenu = CreateMenu(Menu_Queue);
	SetMenuTitle(hMenu, "Queue for next round?");
	AddMenuItem(hMenu, "0", "Put me in!");
	AddMenuItem(hMenu, "1", "Take me out!");
	DisplayMenu(hMenu, client, 30);
}

public int Menu_Queue(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bGameUseQueue)
			{
				switch (param2)
				{
					case 0:
					{
						if (FindValueInArray(g_hQueueList, param1) == -1)
						{
							PushArrayCell(g_hQueueList, param1);
							PrintToChat(param1, "You have been added to the queue list.");
						}
						else
						{
							PrintToChat(param1, "You are already in the queue list!");
						}
					}
					case 1:
					{
						int iIndex = FindValueInArray(g_hQueueList, param1);
						if (iIndex != -1)
						{
							RemoveFromArray(g_hQueueList, iIndex);
							PrintToChat(param1, "You have been removed from the queue list.");
						}
						else
						{
							PrintToChat(param1, "You are not in the queue list!");
						}
					}
				}
			}
			else
			{
				PrintToChat(param1, "This gamemode does not support the queue list!");
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

// API



public int Native_GameRulesGetGameType(Handle hPlugin, int iNumParams)
{
	return g_iGameType;
}

public int Native_GameRulesSetGameType(Handle hPlugin, int iNumParams)
{
	GameRulesSetGameType(GetNativeCell(1));
}

public int Native_GameRulesGetMinPlayers(Handle hPlugin, int iNumParams)
{
	return g_iGameMinPlayers;
}

public int Native_GameRulesSetMinPlayers(Handle hPlugin, int iNumParams)
{
	g_iGameMinPlayers = GetNativeCell(1);
}

public int Native_GameRulesGetMaxPlayers(Handle hPlugin, int iNumParams)
{
	return g_iGameMaxPlayers;
}

public int Native_GameRulesSetMaxPlayers(Handle hPlugin, int iNumParams)
{
	g_iGameMaxPlayers = GetNativeCell(1);
}

public int Native_GameRulesGetRestrictToVehicles(Handle hPlugin, int iNumParams)
{
	return g_bGameRestrictToVehicles;
}

public int Native_GameRulesSetRestrictToVehicles(Handle hPlugin, int iNumParams)
{
	g_bGameRestrictToVehicles = view_as<bool>(GetNativeCell(1));
}

public int Native_GameRulesGetRestrictSuicideInVehicles(Handle hPlugin, int iNumParams)
{
	return g_bGameRestrictSuicideInVehicles;
}

public int Native_GameRulesSetRestrictSuicideInVehicles(Handle hPlugin, int iNumParams)
{
	g_bGameRestrictSuicideInVehicles = view_as<bool>(GetNativeCell(1));
}

public int Native_GameRulesGetUseQueue(Handle hPlugin, int iNumParams)
{
	return g_bGameUseQueue;
}

public int Native_GameRulesSetUseQueue(Handle hPlugin, int iNumParams)
{
	g_bGameUseQueue = view_as<bool>(GetNativeCell(1));
}

public int Native_GameRulesGetQueueList(Handle hPlugin, int iNumParams)
{
	Handle hDestArray = view_as<Handle>(GetNativeCell(1));
	
	for (int i = 0, iSize = GetArraySize(g_hQueueList); i < iSize; i++)
	{
		PushArrayCell(hDestArray, GetArrayCell(g_hQueueList, i));
	}
}

public int Native_GameRulesGetFreeForAll(Handle hPlugin, int iNumParams)
{
	return g_bGameUseQueue;
}

public int Native_GameRulesSetFreeForAll(Handle hPlugin, int iNumParams)
{
	g_bGameFreeForAll = view_as<bool>(GetNativeCell(1));
}

public int Native_GameRulesGetRoundState(Handle hPlugin, int iNumParams)
{
	return g_iGameRoundState;
}

public int Native_GameRulesSetRoundState(Handle hPlugin, int iNumParams)
{
	GameRulesSetRoundState(GetNativeCell(1));
}

public int Native_GameRulesGetValidPlayerSpawnPoints(Handle hPlugin, int iNumParams)
{
	Handle hSpawnPoints = GameRulesGetValidPlayerSpawnPoints(GetNativeCell(1));
	Handle hDestArray = view_as<Handle>(GetNativeCell(2));
	
	for (int i = 0, iSize = GetArraySize(hSpawnPoints); i < iSize; i++)
	{
		PushArrayCell(hDestArray, GetArrayCell(hSpawnPoints, i));
	}
	
	CloseHandle(hSpawnPoints);
}

public int Native_GameRulesIsPlayerInGame(Handle hPlugin, int iNumParams)
{
	return g_bPlayerInGame[GetNativeCell(1)];
}

public int Native_GameRulesSetInGameStateOfPlayer(Handle hPlugin, int iNumParams)
{
	GameRulesSetInGameStateOfPlayer(GetNativeCell(1), view_as<bool>(GetNativeCell(2)));
}

public int Native_GameRulesIsPlayerEliminated(Handle hPlugin, int iNumParams)
{
	return g_bPlayerEliminated[GetNativeCell(1)];
}

public int Native_GameRulesSetEliminatedStateOfPlayer(Handle hPlugin, int iNumParams)
{
	g_bPlayerEliminated[GetNativeCell(1)] = view_as<bool>(GetNativeCell(2));
}

public int Native_GameRulesIsPlayerInWarmup(Handle hPlugin, int iNumParams)
{
	return g_bPlayerInWarmup[GetNativeCell(1)];
}

public int Native_GameRulesSetWarmupStateOfPlayer(Handle hPlugin, int iNumParams)
{
	GameRulesSetWarmupStateOfPlayer(GetNativeCell(1), view_as<bool>(GetNativeCell(2)));
}

public int Native_GameRulesGetRoundTime(Handle hPlugin, int iNumParams)
{
	return g_iGameRoundTime;
}

public int Native_GameRulesInitializeRoundTimer(Handle hPlugin, int iNumParams)
{
	GameRulesInitializeRoundTimer(GetNativeCell(1), view_as<Handle>(GetNativeCell(2)), GetNativeFunction(3));
}

public int Native_GameRulesStopRoundTimer(Handle hPlugin, int iNumParams)
{
	GameRulesStopRoundTimer();
}

public int Native_GameRulesGivePlayerVehicle(Handle hPlugin, int iNumParams)
{
	char sVehicleName[64];
	GetNativeString(3, sVehicleName, sizeof(sVehicleName));
	
	GameRulesGivePlayerVehicle(GetNativeCell(1), GetNativeCell(2), sVehicleName);
}

public int Native_GameRulesSetPlayerVehicle(Handle hPlugin, int iNumParams)
{
	char sVehicleName[64];
	GetNativeString(3, sVehicleName, sizeof(sVehicleName));
	
	g_iPlayerVehicleSpawnType[GetNativeCell(1)] = GetNativeCell(2);
	strcopy(g_strPlayerVehicleSpawnName[GetNativeCell(1)], sizeof(g_strPlayerVehicleSpawnName[]), sVehicleName);
}

public int Native_GameRulesRequestVehiclesForPlayer(Handle hPlugin, int iNumParams)
{
	GameRulesRequestVehiclesForPlayer(GetNativeCell(1));
}

public int Native_GameRulesSaveVehiclesForPlayer(Handle hPlugin, int iNumParams)
{
	GameRulesSaveVehiclesForPlayer(GetNativeCell(1));
}