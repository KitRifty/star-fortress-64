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
    name = "[SF64] Deathmatch Gamemode",
    author	= "KitRifty",
    description	= "Adds a basic Deathmatch gamemode to Star Fortress 64.",
    version = PLUGIN_VERSION,
    url = ""
}

new bool:g_bEnabled = false;
new g_iPlayerKills[MAXPLAYERS + 1];

new g_iBGMusic = -1;

new bool:g_bRoundStarting = false;
new bool:g_bRoundEnded = false;
new Handle:g_hRoundTimer;
new g_iRoundTime;
new Handle:g_hRoundWinners;
new Handle:g_hRoundWinnerHudSync;

new Handle:g_cvRoundWarmupDuration;
new Handle:g_cvRoundDuration;
new Handle:g_cvRoundFragLimit;

public OnPluginStart()
{
	g_hRoundWinners = CreateArray();
	g_hRoundWinnerHudSync = CreateHudSynchronizer();
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_cvRoundWarmupDuration = CreateConVar("sf64_dm_round_warmup_duration", "60");
	g_cvRoundDuration = CreateConVar("sf64_dm_round_duration", "120");
	g_cvRoundFragLimit = CreateConVar("sf64_dm_round_frag_limit", "5");
}

public OnClientPutInServer(client)
{
	g_iPlayerKills[client] = 0;
	
	if (!g_bEnabled) return;
}

public OnClientDisconnect_Post(client)
{
	if (!g_bEnabled) return;
	
	CheckToEndRound();
}

public SF64_GameRulesOnGetGameType(const String:sType[64])
{
	g_bEnabled = false;
	g_iBGMusic = -1;
	g_bRoundEnded = false;
	g_hRoundTimer = INVALID_HANDLE;
	
	if (!StrEqual(sType, "deathmatch", false)) return;
	
	g_bEnabled = true;
	
	SF64_GameRulesSetGameType(SF64GameType_Custom);
	SF64_GameRulesStopRoundTimer();
	SF64_GameRulesSetMinPlayers(1);
	SF64_GameRulesSetMaxPlayers(-1);
	SF64_GameRulesSetRestrictToVehicles(true);
	SF64_GameRulesSetRestrictSuicideInVehicles(true);
	SF64_GameRulesSetUseQueue(true);
	SF64_GameRulesSetFreeForAll(true);
	
	PrintToServer("Initialized Deathmatch gamemode for SF64!");
}

public OnMapEnd()
{
	if (!g_bEnabled) return;
	
	if (SF64_MusicActiveMusicIdExists(g_iBGMusic))
	{
		SF64_MusicRemoveActiveMusicById(g_iBGMusic);
	}
	
	g_iBGMusic = -1;
}

public Event_RoundStart(Handle:event, const String:sName[], bool:dB)
{
	if (!g_bEnabled) return;
	
	SF64_GameRulesSetRoundState(SF64RoundState_Warmup);
	SF64_GameRulesInitializeRoundTimer(GetConVarInt(g_cvRoundWarmupDuration), GetMyHandle(), RoundWarmupTimerPost);
}

public Event_RoundEnd(Handle:event, const String:sName[], bool:dB)
{
	if (!g_bEnabled) return;
}

public Event_PlayerDeath(Handle:event, const String:sName[], bool:dB)
{
	if (!g_bEnabled) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	
	if (SF64_GameRulesGetRoundState() == SF64RoundState_Active)
	{
		if (!g_bRoundEnded)
		{
			if (SF64_GameRulesIsPlayerInGame(client) && !SF64_GameRulesIsPlayerEliminated(client))
			{
				new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
				if (attacker > 0 && attacker != client)
				{
					if (SF64_GameRulesIsPlayerInGame(attacker) && !SF64_GameRulesIsPlayerEliminated(attacker))
					{
						g_iPlayerKills[attacker]++;
					}
				}
				
				CheckToEndRound();
			}
		}
	}
}

public RoundWarmupTimerPost()
{
	new Handle:hQueueList = CreateArray();
	SF64_GameRulesGetQueueList(hQueueList);
	
	new iMinPlayers = SF64_GameRulesGetMinPlayers();
	
	if (GetArraySize(hQueueList) >= iMinPlayers)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			SF64_GameRulesSetPlayerVehicle(i, VehicleType_Arwing, "arwing");
		}
	
		SF64_GameRulesSetRoundState(SF64RoundState_Active);
	}
	else
	{
		SF64_GameRulesInitializeRoundTimer(GetConVarInt(g_cvRoundWarmupDuration), GetMyHandle(), RoundWarmupTimerPost);
		PrintToChatAll("Not enough players queued in! At least %d players must be queued in.", iMinPlayers);
	}
}

CheckToEndRound()
{
	if (SF64_GameRulesGetRoundState() != SF64RoundState_Active) return;
	
	new bool:bEndRound = false;
	
	{
		new iPlayerCount = 0;
		for (new client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client)) continue;
			if (SF64_GameRulesIsPlayerInGame(client))
			{
				if (!SF64_GameRulesIsPlayerEliminated(client))
				{
					iPlayerCount++;
				}
				
				if (g_iPlayerKills[client] >= GetConVarInt(g_cvRoundFragLimit))
				{
					bEndRound = true;
					break;
				}
			}
		}
	
		if (iPlayerCount < SF64_GameRulesGetMinPlayers()) bEndRound = true;
	}
	
	if (bEndRound)
	{
		EndActiveRound();
	}
}

public EndActiveRound()
{
	SF64_GameRulesStopRoundTimer();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SF64_MusicRemoveActiveMusicIdFromPlayer(i, g_iBGMusic);
		}
	}
	
	g_bRoundEnded = true;
	g_hRoundTimer = CreateTimer(2.25, Timer_PreAnnounceRoundWinners, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_PreActiveRound(Handle:timer)
{
	if (timer != g_hRoundTimer) return Plugin_Stop;
	
	g_iRoundTime--;
	
	if (g_iRoundTime <= 0)
	{
		g_bRoundStarting = false;
		PrintToChatAll("GO!");
		return Plugin_Stop;
	}
	
	// TODO: Make screen overlay effects.
	PrintToChatAll("%d!", g_iRoundTime);
	
	SF64_GameRulesInitializeRoundTimer(GetConVarInt(g_cvRoundDuration), GetMyHandle(), EndActiveRound);
	CheckToEndRound();
	
	return Plugin_Continue;
}

public SortWinnersArrayByKills(index1, index2, Handle:array, Handle:hndl)
{
	new client1 = GetArrayCell(array, index1);
	new client2 = GetArrayCell(array, index2);
	
	if (g_iPlayerKills[client1] > g_iPlayerKills[client2])
	{
		return -1;
	}
	else if (g_iPlayerKills[client1] == g_iPlayerKills[client2])
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

public Action:Timer_PreAnnounceRoundWinners(Handle:timer)
{
	if (timer != g_hRoundTimer) return;
	
	// TODO: Declare winrar and do celebratory effects. Also prevent the losers from firing.
	
	new Handle:hWinners = CreateArray();
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (!SF64_GameRulesIsPlayerInGame(client)) continue;
		
		PushArrayCell(hWinners, client);
	}
	
	if (GetArraySize(hWinners) > 0)
	{
		SortADTArrayCustom(hWinners, SortWinnersArrayByKills);
		
		new iBestScore = g_iPlayerKills[GetArrayCell(hWinners, 0)];
		
		for (new i = 1, iSize = GetArraySize(hWinners); i < iSize; i++)
		{
			if (g_iPlayerKills[GetArrayCell(hWinners, i)] < iBestScore)
			{
				ResizeArray(hWinners, i);
				break; // End of winners.
			}
		}
		
		new iNumWinners = GetArraySize(hWinners);
		
		decl String:sWinText[64];
		if (iNumWinners == 1) strcopy(sWinText, sizeof(sWinText), "WINNER:");
		else strcopy(sWinText, sizeof(sWinText), "WINNERS:");
		
		SetHudTextParams(-1.0, 0.3,
			10.0,
			255,
			255,
			255,
			255,
			_,
			1.0,
			0.0,
			0.5);
			
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			ShowSyncHudText(i, g_hRoundWinnerHudSync, sWinText);
		}
		
		decl String:sWinners[512];
		if (iNumWinners == 1) Format(sWinners, sizeof(sWinners), "%N", GetArrayCell(hWinners, 0));
		else
		{
			strcopy(sWinners, sizeof(sWinners), "");
		
			for (new i = 0; i < iNumWinners; i++)
			{
				new client = GetArrayCell(hWinners, i);
				decl String:sTemp[64];
				GetClientName(client, sTemp, sizeof(sTemp));
				
				if (i < iNumWinners - 1)
				{
					if (iNumWinners > 2)
					{
						StrCat(sTemp, sizeof(sTemp), ", ");
						
						if (i == iNumWinners - 2)
						{
							StrCat(sTemp, sizeof(sTemp), "and ");
						}
					}
					else
					{
						StrCat(sTemp, sizeof(sTemp), " and ");
					}
				}
				
				StrCat(sWinners, sizeof(sWinners), sTemp);
			}
		}
		
		new Handle:hPack;
		CreateDataTimer(1.0, Timer_AnnounceRoundWinners, hPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackString(hPack, sWinText);
		WritePackString(hPack, sWinners);
	}
	
	CloseHandle(hWinners);
	
	g_hRoundTimer = CreateTimer(10.0, Timer_PostActiveRound, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AnnounceRoundWinners(Handle:timer, Handle:hPack)
{
	new String:sWinText[64], String:sWinners[512];
	ResetPack(hPack);
	ReadPackString(hPack, sWinText, sizeof(sWinText));
	ReadPackString(hPack, sWinners, sizeof(sWinners));
	
	decl String:sMessage[512];
	Format(sMessage, sizeof(sMessage), "%s\n \n%s", sWinText, sWinners);
	
	SetHudTextParams(-1.0, 0.3,
		10.0,
		255,
		255,
		255,
		255,
		_,
		1.0,
		0.0,
		0.5);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		ShowSyncHudText(i, g_hRoundWinnerHudSync, sMessage);
	}
}

public Action:Timer_PostActiveRound(Handle:timer)
{
	if (timer != g_hRoundTimer) return;
	
	SF64_GameRulesSetRoundState(SF64RoundState_Warmup);
	SF64_GameRulesInitializeRoundTimer(GetConVarInt(g_cvRoundWarmupDuration), GetMyHandle(), RoundWarmupTimerPost);
}

public SF64_GameRulesOnRoundStateStart(iRoundState)
{
	if (!g_bEnabled) return;
	
	switch (iRoundState)
	{
		case SF64RoundState_Active:
		{
			g_iBGMusic = SF64_MusicCreateActiveMusic("vs_zoness");
			PrintToChatAll("g_iBGMusic = %d", g_iBGMusic);
			
			SF64_GameRulesStopRoundTimer();
			
			for (new i = 1; i <= MaxClients; i++)
			{
				g_iPlayerKills[i] = 0;
				
				if (IsClientInGame(i))
				{
					SF64_MusicPlayActiveMusicIdToPlayer(i, g_iBGMusic);
				}
			}
			
			g_bRoundStarting = true;
			g_bRoundEnded = false;
			g_iRoundTime = 4;
			g_hRoundTimer = CreateTimer(1.0, Timer_PreActiveRound, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			ClearArray(g_hRoundWinners);
			
			// TODO: Do some weird camera shizz.
		}
	}
}

public SF64_GameRulesOnRoundStateEnd(iRoundState)
{
	if (!g_bEnabled) return;
	
	switch (iRoundState)
	{
		case SF64RoundState_Active:
		{
			SF64_GameRulesStopRoundTimer();
			
			if (SF64_MusicActiveMusicIdExists(g_iBGMusic))
			{
				SF64_MusicRemoveActiveMusicById(g_iBGMusic);
			}
			
			for (new i = 1; i <= MaxClients; i++)
			{
				g_iPlayerKills[i] = 0;
			}
			
			g_bRoundStarting = false;
			g_bRoundEnded = false;
			g_hRoundTimer = INVALID_HANDLE;
			g_iRoundTime = 0;
			ClearArray(g_hRoundWinners);
		}
	}
}