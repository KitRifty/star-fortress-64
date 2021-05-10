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

forward int SF64_GameRulesOnRoundStateStart(int iRoundState);
forward int SF64_GameRulesOnRoundStateEnd(int iRoundState);

forward int SF64_GameRulesOnGetGameType(const char[] sType);

forward int SF64_GameRulesOnRequestVehiclesForPlayer(int client);
forward int SF64_GameRulesOnSaveVehiclesForPlayer(int client, Handle hVehicles, Handle hVehicleTypes);


native int SF64_GameRulesGetGameType();
native int SF64_GameRulesSetGameType(int iGameType);

native int SF64_GameRulesGetMinPlayers();
native int SF64_GameRulesSetMinPlayers(int iNumPlayers);

native int SF64_GameRulesGetMaxPlayers();
native int SF64_GameRulesSetMaxPlayers(int iNumPlayers);

native bool SF64_GameRulesGetRestrictToVehicles();
native int SF64_GameRulesSetRestrictToVehicles(bool bRestrict);

native bool SF64_GameRulesGetRestrictSuicideInVehicles();
native int SF64_GameRulesSetRestrictSuicideInVehicles(bool bRestrict);

native bool SF64_GameRulesGetUseQueue();
native int SF64_GameRulesSetUseQueue(bool bUseQueue);
native int SF64_GameRulesGetQueueList(Handle hDestArray);

native bool SF64_GameRulesGetFreeForAll();
native int SF64_GameRulesSetFreeForAll(bool bFreeForAll);

native int SF64_GameRulesGetRoundState();
native int SF64_GameRulesSetRoundState(int iRoundState);

native int SF64_GameRulesGetValidPlayerSpawnPoints(int client, Handle hDestArray);

native bool SF64_GameRulesIsPlayerInGame(int client);
native int SF64_GameRulesSetInGameStateOfPlayer(int client, bool bState);

native bool SF64_GameRulesIsPlayerEliminated(int client);
native int SF64_GameRulesSetEliminatedStateOfPlayer(int client, bool bState);

native bool SF64_GameRulesIsPlayerInWarmup(int client);
native int SF64_GameRulesSetWarmupStateOfPlayer(int client, bool bState);

native int SF64_GameRulesGetRoundTime();
native int SF64_GameRulesInitializeRoundTimer(int iRoundTime, Handle hCallbackPlugin, Function fCallback);
native int SF64_GameRulesStopRoundTimer();

native int SF64_GameRulesGivePlayerVehicle(int client, int iVehicleType, const char[] sVehicleName);
native int SF64_GameRulesSetPlayerVehicle(int client, int iVehicleType, const char[] sVehicleName);

native int SF64_GameRulesRequestVehiclesForPlayer(int client);
native int SF64_GameRulesSaveVehiclesForPlayer(int client);


native int SF64_MusicCreateActiveMusic(const char[] sMusicName);

native bool SF64_MusicActiveMusicIdExists(int iActiveMusicId);

native int SF64_MusicRemoveActiveMusicById(int iActiveMusicId);

native int SF64_MusicPlayActiveMusicIdToPlayer(int client, int iActiveMusicId);
native int SF64_MusicRemoveActiveMusicIdFromPlayer(int client, int iActiveMusicId);
native int SF64_MusicRemoveAllActiveMusicIdsFromPlayer(int client);


public SharedPlugin __pl_starfortress64 =
{
	name = "starfortress64",
	file = "starfortress64.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};