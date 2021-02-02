#if defined _sf64_included
  #endinput
#endif
#define _sf64_included

enum 
{
	SF64RoundState_Unknown = -1,
	SF64RoundState_WaitingForPlayers = 0,
	SF64RoundState_Warmup,
	SF64RoundState_Active
};

enum
{
	SF64GameType_None = -1,
	SF64GameType_Custom
};

enum
{
	VehicleType_Unknown = -1,
	VehicleType_Arwing = 0,
	VehicleType_Landmaster
};

forward SF64_GameRulesOnRoundStateStart(iRoundState);
forward SF64_GameRulesOnRoundStateEnd(iRoundState);

forward SF64_GameRulesOnGetGameType(const String:sType[64]);

forward SF64_GameRulesOnRequestVehiclesForPlayer(client);
forward SF64_GameRulesOnSaveVehiclesForPlayer(client, Handle:hVehicles, Handle:hVehicleTypes);


native SF64_GameRulesGetGameType();
native SF64_GameRulesSetGameType(iGameType);

native SF64_GameRulesGetMinPlayers();
native SF64_GameRulesSetMinPlayers(iNumPlayers);

native SF64_GameRulesGetMaxPlayers();
native SF64_GameRulesSetMaxPlayers(iNumPlayers);

native bool:SF64_GameRulesGetRestrictToVehicles();
native SF64_GameRulesSetRestrictToVehicles(bool:bRestrict);

native bool:SF64_GameRulesGetRestrictSuicideInVehicles();
native SF64_GameRulesSetRestrictSuicideInVehicles(bool:bRestrict);

native bool:SF64_GameRulesGetUseQueue();
native SF64_GameRulesSetUseQueue(bool:bUseQueue);
native SF64_GameRulesGetQueueList(Handle:hDestArray);

native bool:SF64_GameRulesGetFreeForAll();
native SF64_GameRulesSetFreeForAll(bool:bFreeForAll);

native SF64_GameRulesGetRoundState();
native SF64_GameRulesSetRoundState(iRoundState);

native SF64_GameRulesGetValidPlayerSpawnPoints(client, Handle:hDestArray);

native bool:SF64_GameRulesIsPlayerInGame(client);
native SF64_GameRulesSetInGameStateOfPlayer(client, bool:bState);

native bool:SF64_GameRulesIsPlayerEliminated(client);
native SF64_GameRulesSetEliminatedStateOfPlayer(client, bool:bState);

native bool:SF64_GameRulesIsPlayerInWarmup(client);
native SF64_GameRulesSetWarmupStateOfPlayer(client, bool:bState);

native SF64_GameRulesGetRoundTime();
native SF64_GameRulesInitializeRoundTimer(iRoundTime, Handle:hCallbackPlugin, Function:fCallback);
native SF64_GameRulesStopRoundTimer();

native SF64_GameRulesGivePlayerVehicle(client, iVehicleType, const String:sVehicleName[]);
native SF64_GameRulesSetPlayerVehicle(client, iVehicleType, const String:sVehicleName[]);

native SF64_GameRulesRequestVehiclesForPlayer(client);
native SF64_GameRulesSaveVehiclesForPlayer(client);


native SF64_MusicCreateActiveMusic(const String:sMusicName[]);

native bool:SF64_MusicActiveMusicIdExists(iActiveMusicId);

native SF64_MusicRemoveActiveMusicById(iActiveMusicId);

native SF64_MusicPlayActiveMusicIdToPlayer(client, iActiveMusicId);
native SF64_MusicRemoveActiveMusicIdFromPlayer(client, iActiveMusicId);
native SF64_MusicRemoveAllActiveMusicIdsFromPlayer(client);


public SharedPlugin:__pl_starfortress64 =
{
	name = "starfortress64",
	file = "starfortress64.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};