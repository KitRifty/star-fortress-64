#if defined _sf64_music_included
  #endinput
#endif
#define _sf64_music_included

#define MUSIC_FADEIN_RATE 0.05
#define MUSIC_FADEOUT_RATE 0.05

static g_iMusicGlobalId = 0;

static Handle:g_hActiveMusic;

static g_iPlayerActiveMusicId[MAXPLAYERS + 1] = { -1, ... };
static Float:g_flPlayerActiveMusicVolume[MAXPLAYERS + 1];
static Handle:g_hPlayerActiveMusic[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
static Handle:g_hPlayerFadingActiveMusic[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
static Handle:g_hPlayerFadingActiveMusicPaths[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

static Handle:g_hMusicIndexes;
static Handle:g_hMusicIndexNames;
static Handle:g_hMusicIndexPaths;


SetupMusicAPI()
{
	CreateNative("SF64_MusicCreateActiveMusic", Native_MusicCreateActiveMusic);
	CreateNative("SF64_MusicActiveMusicIdExists", Native_MusicActiveMusicIdExists);
	CreateNative("SF64_MusicRemoveActiveMusicById", Native_MusicRemoveActiveMusicById);
	CreateNative("SF64_MusicPlayActiveMusicIdToPlayer", Native_MusicPlayActiveMusicIdToPlayer);
	CreateNative("SF64_MusicRemoveActiveMusicIdFromPlayer", Native_MusicRemoveActiveMusicIdFromPlayer);
	CreateNative("SF64_MusicRemoveAllActiveMusicIdsFromPlayer", Native_MusicRemoveAllActiveMusicIdsFromPlayer);
}

SetupMusic()
{
	g_hActiveMusic = CreateArray(ActiveMusic_MaxStats);
	g_hMusicIndexes = CreateArray(Music_MaxStats);
	g_hMusicIndexNames = CreateArray(64);
	g_hMusicIndexPaths = CreateArray(PLATFORM_MAX_PATH);
}

public MusicOnConfigsExecuted()
{
	ClearArray(g_hActiveMusic);
	g_iMusicGlobalId = 0;
	
	ClearArray(g_hMusicIndexes);
	ClearArray(g_hMusicIndexNames);
	ClearArray(g_hMusicIndexPaths);
	
	new Handle:hConfig = INVALID_HANDLE;
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/music.cfg");
	if (FileExists(sPath))
	{
		new Handle:kv = CreateKeyValues("root");
	
		if (FileToKeyValues(kv, sPath))
		{
			hConfig = kv;
		}
		else
		{
			CloseHandle(kv);
			LogError("Music config at path %s could not be parsed properly!", sPath);
		}
	}
	else
	{
		LogError("Music config at path %s does not exist!", sPath);
	}
	
	if (hConfig != INVALID_HANDLE)
	{
		KvRewind(hConfig);
		if (KvGotoFirstSubKey(hConfig))
		{
			do
			{
				decl String:sSectionName[64];
				KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
				
				new iChannel = KvGetNum(hConfig, "channel");
				new Float:flVolume = KvGetFloat(hConfig, "volume", 1.0);
				new iPitch = KvGetNum(hConfig, "pitch", 100);
				new iFlags = 0; // TODO: Parse music flags!
				
				new iIndex = PushArrayCell(g_hMusicIndexes, 9001337);
				SetArrayCell(g_hMusicIndexes, iIndex, iChannel, Music_Channel);
				SetArrayCell(g_hMusicIndexes, iIndex, flVolume, Music_Volume);
				SetArrayCell(g_hMusicIndexes, iIndex, iPitch, Music_Pitch);
				SetArrayCell(g_hMusicIndexes, iIndex, iFlags, Music_Flags);
				
				PushArrayString(g_hMusicIndexNames, sSectionName);
				
				// Precache our song!
				KvGetString(hConfig, "path", sPath, sizeof(sPath), "");
				if (sPath[0])
				{
					PrecacheSound2(sPath);
				}
				else
				{
					LogError("Song %s has blank path in music config!", sSectionName);
				}
				
				PushArrayString(g_hMusicIndexPaths, sPath);
				
				decl String:sFinalPath[PLATFORM_MAX_PATH];
				Format(sFinalPath, sizeof(sFinalPath), "#%s", sPath);
				
				PrecacheSound(sFinalPath);
				
				DebugMessage("Added music %s", sSectionName);
			}
			while (KvGotoNextKey(hConfig));
		}
		
		CloseHandle(hConfig);
	}
}

public MusicOnEntityDestroyed(entity)
{
}

public MusicOnClientPutInServer(client)
{
	g_iPlayerActiveMusicId[client] = -1;
	g_flPlayerActiveMusicVolume[client] = 0.0;
	g_hPlayerActiveMusic[client] = CreateArray(PlayerActiveMusic_MaxStats);
	g_hPlayerFadingActiveMusicPaths[client] = CreateArray(PLATFORM_MAX_PATH);
	g_hPlayerFadingActiveMusic[client] = CreateArray(FadingPlayerActiveMusic_MaxStats);
}

public MusicOnClientDisconnect(client)
{
	MusicRemoveAllActiveMusicIdsFromPlayer(client);

	g_iPlayerActiveMusicId[client] = -1;
	g_flPlayerActiveMusicVolume[client] = 0.0;
	
	if (g_hPlayerActiveMusic[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerActiveMusic[client]);
		g_hPlayerActiveMusic[client] = INVALID_HANDLE;
	}
	
	if (g_hPlayerFadingActiveMusicPaths[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerFadingActiveMusicPaths[client]);
		g_hPlayerFadingActiveMusicPaths[client] = INVALID_HANDLE;
	}
	
	if (g_hPlayerFadingActiveMusic[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerFadingActiveMusic[client]);
		g_hPlayerFadingActiveMusic[client] = INVALID_HANDLE;
	}
}

MusicCreateActiveMusic(const String:sMusicName[])
{
	new iMusicIndex = FindStringInArray(g_hMusicIndexNames, sMusicName);
	if (iMusicIndex == -1) return -1; // music does not exist.
	
	new iId = g_iMusicGlobalId;
	g_iMusicGlobalId++;
	
	new iIndex = PushArrayCell(g_hActiveMusic, iId);
	SetArrayCell(g_hActiveMusic, iIndex, iMusicIndex, ActiveMusic_MusicIndex);
	
	return iId;
}

MusicRemoveActiveMusicById(iActiveMusicId)
{
	decl iIndex;
	if (!MusicActiveMusicIdExists(iActiveMusicId, iIndex)) return;
	
	// Stop the music first before removing the active music.
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		MusicRemoveActiveMusicIdFromPlayer(client, iActiveMusicId);
	}
	
	RemoveFromArray(g_hActiveMusic, iIndex);
}

static bool:MusicActiveMusicIdExists(iActiveMusicId, &iIndex=-1)
{
	iIndex = FindValueInArray(g_hActiveMusic, iActiveMusicId);
	if (iIndex == -1) return false;
	return true;
}

MusicPlayActiveMusicIdToPlayer(client, iActiveMusicId)
{
	if (!MusicActiveMusicIdExists(iActiveMusicId)) return;
	new iIndex = FindValueInArray(g_hPlayerActiveMusic[client], iActiveMusicId);
	if (iIndex != -1) return; // already playing.
	
	iIndex = PushArrayCell(g_hPlayerActiveMusic[client], iActiveMusicId);
	SetArrayCell(g_hPlayerActiveMusic[client], iIndex, iActiveMusicId, PlayerActiveMusic_ActiveMusicId);
	SetArrayCell(g_hPlayerActiveMusic[client], iIndex, INVALID_HANDLE, PlayerActiveMusic_FadeTimer);
	SetArrayCell(g_hPlayerActiveMusic[client], iIndex, false, PlayerActiveMusic_Played);
	
	MusicUpdateForPlayer(client);
}

MusicRemoveActiveMusicIdFromPlayer(client, iActiveMusicId)
{
	new iIndex = FindValueInArray(g_hPlayerActiveMusic[client], iActiveMusicId);
	if (iIndex == -1) return;
	
	RemoveFromArray(g_hPlayerActiveMusic[client], iIndex);
	MusicUpdateForPlayer(client);
}

MusicRemoveAllActiveMusicIdsFromPlayer(client)
{
	ClearArray(g_hPlayerActiveMusic[client]);
	MusicUpdateForPlayer(client);
}

// Called every time the music changes for the player. This is where all the magic happens, boys (and girls).
public MusicUpdateForPlayer(client)
{
	DebugMessage("START MusicUpdateForPlayer(%d)", client);

	new iOldActiveMusicId = g_iPlayerActiveMusicId[client];
	new Float:flOldActiveMusicVolume = g_flPlayerActiveMusicVolume[client];
	new iActiveMusicId = -1;
	if (GetArraySize(g_hPlayerActiveMusic[client]) > 0) iActiveMusicId = GetArrayCell(g_hPlayerActiveMusic[client], GetArraySize(g_hPlayerActiveMusic[client]) - 1, PlayerActiveMusic_ActiveMusicId);
	
	if (iActiveMusicId != iOldActiveMusicId)
	{
		DebugMessage("Found music change for client %d (old: %d, new: %d)", client, iOldActiveMusicId, iActiveMusicId);
	
		// Change detected.
		g_iPlayerActiveMusicId[client] = iActiveMusicId;
		
		decl iOldActiveMusicIndex;
		if (MusicActiveMusicIdExists(iOldActiveMusicId, iOldActiveMusicIndex))
		{
			new iMusicIndex = GetArrayCell(g_hActiveMusic, iOldActiveMusicIndex, ActiveMusic_MusicIndex);
			new iChannel = GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Channel);
			new iPitch = GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Pitch);
			
			new iFadeIndex = PushArrayCell(g_hPlayerFadingActiveMusic[client], 1337);
			SetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, iChannel, FadingPlayerActiveMusic_Channel);
			SetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, iPitch, FadingPlayerActiveMusic_Pitch);
			SetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, flOldActiveMusicVolume, FadingPlayerActiveMusic_Volume);
			
			decl String:sPath[PLATFORM_MAX_PATH];
			GetArrayString(g_hMusicIndexPaths, iMusicIndex, sPath, sizeof(sPath));
			PushArrayString(g_hPlayerFadingActiveMusicPaths[client], sPath);
			
			new Handle:hPack;
			new Handle:hTimer = CreateDataTimer(0.0, Timer_PlayerActiveMusicFadeOut, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackString(hPack, sPath);
			SetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, hTimer, FadingPlayerActiveMusic_FadeTimer);
			TriggerTimer(hTimer, true);
			
			DebugMessage("Stopping music id %d (%s) for client %d", iOldActiveMusicId, sPath, client);
		}
		else
		{
			DebugMessage("Can't stop nonexistent music id %d for client %d", iOldActiveMusicId, client);
		}
		
		g_flPlayerActiveMusicVolume[client] = 0.0;
		
		decl iActiveMusicIndex;
		if (MusicActiveMusicIdExists(iActiveMusicId, iActiveMusicIndex))
		{
			new iMusicIndex = GetArrayCell(g_hActiveMusic, iActiveMusicIndex, ActiveMusic_MusicIndex);
			new iChannel = GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Channel);
			
			decl String:sPath[PLATFORM_MAX_PATH];
			GetArrayString(g_hMusicIndexPaths, iMusicIndex, sPath, sizeof(sPath));
			
			// First check if this specific sound is already fading.
			// The sound has to match the channel and sound path to be considered already fading.
			
			new Float:flStartVolume = 0.0;
			
			for (new i = 0, iSize = GetArraySize(g_hPlayerFadingActiveMusic[client]); i < iSize; i++)
			{
				new iFadingChannel = GetArrayCell(g_hPlayerFadingActiveMusic[client], i, FadingPlayerActiveMusic_Channel);
				if (iFadingChannel == iChannel)
				{
					decl String:sFadingPath[PLATFORM_MAX_PATH];
					GetArrayString(g_hPlayerFadingActiveMusicPaths[client], i, sFadingPath, sizeof(sFadingPath));
					
					if (StrEqual(sFadingPath, sPath))
					{
						flStartVolume = Float:GetArrayCell(g_hPlayerFadingActiveMusic[client], i, FadingPlayerActiveMusic_Volume);
						
						// Stop the sound from fading.
						CloseHandle(Handle:GetArrayCell(g_hPlayerFadingActiveMusic[client], i, FadingPlayerActiveMusic_FadeTimer));
						RemoveFromArray(g_hPlayerFadingActiveMusic[client], i);
						RemoveFromArray(g_hPlayerFadingActiveMusicPaths[client], i);
						break;
					}
				}
			}
			
			new iPlayerActiveMusicIndex = FindValueInArray(g_hPlayerActiveMusic[client], iActiveMusicId);
			if (!bool:GetArrayCell(g_hPlayerActiveMusic[client], iPlayerActiveMusicIndex, PlayerActiveMusic_Played))
			{
				if (iOldActiveMusicIndex == -1) // no previous song was played.
				{
					flStartVolume = Float:GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Volume);
				}
				
				SetArrayCell(g_hPlayerActiveMusic[client], iPlayerActiveMusicIndex, true, PlayerActiveMusic_Played)
			}
			
			// Finally, play the damn song.
			g_flPlayerActiveMusicVolume[client] = flStartVolume;
			new Handle:hPack;
			new Handle:hTimer = CreateDataTimer(0.0, Timer_PlayerActiveMusicFadeIn, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hPack, GetClientUserId(client));
			WritePackCell(hPack, iActiveMusicId);
			SetArrayCell(g_hPlayerActiveMusic[client], iPlayerActiveMusicIndex, hTimer, PlayerActiveMusic_FadeTimer);
			TriggerTimer(hTimer, true);
			
			DebugMessage("Playing music id %d (%s) for client %d", iActiveMusicId, sPath, client);
		}
		else
		{
			DebugMessage("Can't play nonexistent music id %d for client %d", iOldActiveMusicId, client);
		}
	}
	
	DebugMessage("END MusicUpdateForPlayer(%d)", client);
}

public Action:Timer_PlayerActiveMusicFadeIn(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	
	new client = GetClientOfUserId(ReadPackCell(hPack));
	if (client <= 0) return Plugin_Stop;
	
	new iActiveMusicId = ReadPackCell(hPack);
	new iPlayerActiveMusicIndex = FindValueInArray(g_hPlayerActiveMusic[client], iActiveMusicId);
	if (iPlayerActiveMusicIndex == -1) return Plugin_Stop;
	
	decl iActiveMusicIndex;
	if (!MusicActiveMusicIdExists(iActiveMusicId, iActiveMusicIndex)) return Plugin_Stop; // this should almost never happen.
	
	if (timer != Handle:GetArrayCell(g_hPlayerActiveMusic[client], iPlayerActiveMusicIndex, PlayerActiveMusic_FadeTimer)) return Plugin_Stop;
	
	new iMusicIndex = GetArrayCell(g_hActiveMusic, iActiveMusicIndex, ActiveMusic_MusicIndex);
	
	
	new Float:flCurrentVolume = g_flPlayerActiveMusicVolume[client];
	new Float:flTargetVolume = Float:GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Volume);
	new iChannel = GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Channel);
	new iPitch = GetArrayCell(g_hMusicIndexes, iMusicIndex, Music_Pitch);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	GetArrayString(g_hMusicIndexPaths, iMusicIndex, sPath, sizeof(sPath));
	
	decl String:sFinalPath[PLATFORM_MAX_PATH];
	Format(sFinalPath, sizeof(sFinalPath), "#%s", sPath);
	
	new bool:bFinished = false;
	
	if (flCurrentVolume > flTargetVolume)
	{
		if (flCurrentVolume - MUSIC_FADEIN_RATE <= flTargetVolume)
		{
			bFinished = true;
			flCurrentVolume = flTargetVolume;
		}
		else
		{
			flCurrentVolume -= MUSIC_FADEIN_RATE;
		}
	}
	else if (flCurrentVolume < flTargetVolume)
	{
		if (flCurrentVolume + MUSIC_FADEIN_RATE >= flTargetVolume)
		{
			bFinished = true;
			flCurrentVolume = flTargetVolume;
		}
		else
		{
			flCurrentVolume += MUSIC_FADEIN_RATE;
		}
	}
	else
	{
		bFinished = true;
	}
	
	g_flPlayerActiveMusicVolume[client] = flCurrentVolume;
	EmitSoundToClient(client, sFinalPath, _, iChannel, SNDLEVEL_NONE, SND_CHANGEVOL | SND_CHANGEPITCH, flCurrentVolume, iPitch);
	
	if (bFinished)
	{
		SetArrayCell(g_hPlayerActiveMusic[client], iPlayerActiveMusicIndex, INVALID_HANDLE, PlayerActiveMusic_FadeTimer);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Timer_PlayerActiveMusicFadeOut(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	
	new client = GetClientOfUserId(ReadPackCell(hPack));
	if (client <= 0) return Plugin_Stop;
	
	decl String:sPath[PLATFORM_MAX_PATH];
	ReadPackString(hPack, sPath, sizeof(sPath));
	
	new iFadeIndex = FindStringInArray(g_hPlayerFadingActiveMusicPaths[client], sPath);
	if (iFadeIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, FadingPlayerActiveMusic_FadeTimer)) return Plugin_Stop;
	
	new iChannel = GetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, FadingPlayerActiveMusic_Channel);
	new iPitch = GetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, FadingPlayerActiveMusic_Pitch);
	new Float:flCurrentVolume = Float:GetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, FadingPlayerActiveMusic_Volume);
	
	decl String:sFinalPath[PLATFORM_MAX_PATH];
	Format(sFinalPath, sizeof(sFinalPath), "#%s", sPath);
	
	new bool:bFinished = false;
	
	if (flCurrentVolume > 0.0)
	{
		if (flCurrentVolume - MUSIC_FADEOUT_RATE <= 0.0)
		{
			bFinished = true;
			flCurrentVolume = 0.0;
		}
		else
		{
			flCurrentVolume -= MUSIC_FADEOUT_RATE;
		}
	}
	else
	{
		bFinished = true;
	}
	
	SetArrayCell(g_hPlayerFadingActiveMusic[client], iFadeIndex, flCurrentVolume, FadingPlayerActiveMusic_Volume);
	
	if (bFinished)
	{
		StopSound(client, iChannel, sFinalPath);
		RemoveFromArray(g_hPlayerFadingActiveMusic[client], iFadeIndex);
		RemoveFromArray(g_hPlayerFadingActiveMusicPaths[client], iFadeIndex);
		return Plugin_Stop;
	}
	else
	{
		// prevents sound glitching if we place it here instead
		EmitSoundToClient(client, sFinalPath, _, iChannel, SNDLEVEL_NONE, SND_CHANGEVOL | SND_CHANGEPITCH, flCurrentVolume, iPitch);
	}
	
	return Plugin_Continue;
}

// API

public Native_MusicCreateActiveMusic(Handle:hPlugin, iNumParams)
{
	decl String:sMusicName[64];
	GetNativeString(1, sMusicName, sizeof(sMusicName));
	return MusicCreateActiveMusic(sMusicName);
}

public Native_MusicActiveMusicIdExists(Handle:hPlugin, iNumParams)
{
	return MusicActiveMusicIdExists(GetNativeCell(1));
}

public Native_MusicRemoveActiveMusicById(Handle:hPlugin, iNumParams)
{
	MusicRemoveActiveMusicById(GetNativeCell(1));
}

public Native_MusicPlayActiveMusicIdToPlayer(Handle:hPlugin, iNumParams)
{
	MusicPlayActiveMusicIdToPlayer(GetNativeCell(1), GetNativeCell(2));
}

public Native_MusicRemoveActiveMusicIdFromPlayer(Handle:hPlugin, iNumParams)
{
	MusicRemoveActiveMusicIdFromPlayer(GetNativeCell(1), GetNativeCell(2));
}

public Native_MusicRemoveAllActiveMusicIdsFromPlayer(Handle:hPlugin, iNumParams)
{
	MusicRemoveAllActiveMusicIdsFromPlayer(GetNativeCell(1));
}