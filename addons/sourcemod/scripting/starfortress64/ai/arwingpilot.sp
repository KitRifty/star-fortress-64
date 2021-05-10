#if defined _sf64_ai_arwingpilot_included
  #endinput
#endif
#define _sf64_ai_arwingpilot_included


enum
{
	AIArwingPilot_EntRef = 0,
	AIArwingPilot_Team,
	AIArwingPilot_Target,
	AIArwingPilot_Enemy,
	AIArwingPilot_Enemies,
	AIArwingPilot_State,
	AIArwingPilot_Conditions,
	AIArwingPilot_HasSchedule,
	AIArwingPilot_Schedule,
	AIArwingPilot_ScheduleInterrupts,
	AIArwingPilot_ScheduleTask,
	AIArwingPilot_Path,
	AIArwingPilot_MaxStats
};

Handle g_hAIArwingPilotConfigs;
Handle g_hAIArwingPilots;

void SetupAIArwingPilots()
{
	g_hAIArwingPilotConfigs = CreateTrie();
	g_hAIArwingPilots = CreateArray(AIArwingPilot_MaxStats);
}

void LoadAllAIArwingPilotConfigs()
{
	char sPath[PLATFORM_MAX_PATH], sFileName[PLATFORM_MAX_PATH], sName[64];
	FileType iFiletype;
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/aipilots");
	
	Handle hDirectory = OpenDirectory(sPath);
	if (hDirectory == INVALID_HANDLE)
	{
		LogError("The arwing ai pilot configs directory does not exist!");
		return;
	}
	
	while (ReadDirEntry(hDirectory, sFileName, sizeof(sFileName), iFiletype))
	{
		if (iFiletype == FileType_File && StrContains(sFileName, ".cfg", false) != -1)
		{
			strcopy(sName, sizeof(sName), sFileName);
			ReplaceString(sName, sizeof(sName), ".cfg", "", false);
			LoadAIArwingPilotConfig(sName);
		}
	}
	
	CloseHandle(hDirectory);
}

void LoadAIArwingPilotConfig(const char[] sName)
{
	RemoveAIArwingPilotConfig(sName);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/aipilots/%s.cfg", sName);
	if (!FileExists(sPath))
	{
		LogError("Arwing ai pilot config %s does not exist!", sName);
		return;
	}
	
	Handle hConfig = CreateKeyValues("root");
	if (!FileToKeyValues(hConfig, sPath))
	{
		CloseHandle(hConfig);
		LogError("Arwing ai pilot config %s is invalid!", sName);
		return;
	}
	
	KvRewind(hConfig);
	if (KvGotoFirstSubKey(hConfig))
	{
		char sSectionName[64], sIndex[32], sValue[PLATFORM_MAX_PATH], sDownload[PLATFORM_MAX_PATH];
		
		do
		{
			KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
			
			if (!StrContains(sSectionName, "sound_"))
			{
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheSound2(sValue);
				}
			}
			else if (StrEqual(sSectionName, "download"))
			{
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					AddFileToDownloadsTable(sValue);
				}
			}
			else if (StrEqual(sSectionName, "mod_precache"))
			{
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheModel(sValue, true);
				}
			}
			else if (StrEqual(sSectionName, "mat_download"))
			{	
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					Format(sDownload, sizeof(sDownload), "%s.vtf", sValue);
					AddFileToDownloadsTable(sDownload);
					Format(sDownload, sizeof(sDownload), "%s.vmt", sValue);
					AddFileToDownloadsTable(sDownload);
				}
			}
			else if (StrEqual(sSectionName, "mod_download"))
			{
				char sExtensions[][] = { ".mdl", ".phy", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd" };
				
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					for (int i2 = 0; i2 < sizeof(sExtensions); i2++)
					{
						Format(sDownload, sizeof(sDownload), "%s%s", sValue, sExtensions[i2]);
						AddFileToDownloadsTable(sDownload);
					}
				}
			}
		}
		while (KvGotoNextKey(hConfig));
	}
	
	SetTrieValue(g_hAIArwingPilotConfigs, sName, hConfig);
}

void RemoveAIArwingPilotConfig(const char[] sName)
{
	Handle hConfig = INVALID_HANDLE;
	if (GetTrieValue(g_hAIArwingPilotConfigs, sName, hConfig) && hConfig != INVALID_HANDLE)
	{
		CloseHandle(hConfig);
		SetTrieValue(g_hAIArwingPilotConfigs, sName, INVALID_HANDLE);
	}
}

int  SpawnAIArwingPilot(const char[] sName, const float flPos[3], const float flAng[3], int iTeam, int &iIndex=-1)
{
	int iAIPilot = CreateEntityByName("info_target");
	if (iAIPilot != -1)
	{
		TeleportEntity(iAIPilot, flPos, flAng, NULL_VECTOR);
		
		iIndex = PushArrayCell(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
		SetArrayCell(g_hAIArwingPilots, iIndex, iTeam, AIArwingPilot_Team);
		SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_ENT_REFERENCE, AIArwingPilot_Enemy);
		SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_ENT_REFERENCE, AIArwingPilot_Target);
		SetArrayCell(g_hAIArwingPilots, iIndex, AIState_Idle, AIArwingPilot_State);
		SetArrayCell(g_hAIArwingPilots, iIndex, 0, AIArwingPilot_Conditions);
		SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_HANDLE, AIArwingPilot_Schedule);
		SetArrayCell(g_hAIArwingPilots, iIndex, 0, AIArwingPilot_ScheduleInterrupts);
		SetArrayCell(g_hAIArwingPilots, iIndex, 0, AIArwingPilot_ScheduleTask);
		SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_HANDLE, AIArwingPilot_Path);
		
		Handle hTimer = CreateTimer(0.0, Timer_AIArwingPilotThink, EntIndexToEntRef(iAIPilot), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return iAIPilot;
}

public Action Timer_AIArwingPilotThink(Handle timer, any entref)
{
	int iAIPilot = EntRefToEntIndex(entref);
	if (!iAIPilot || iAIPilot == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hAIArwingPilots, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	Handle hSchedule = view_as<Handle>(GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Schedule));
	bool bFinishSchedule = false;
	
	int iArwingIndex = -1, iArwing = GetArwing(iAIPilot, iArwingIndex);
	if (iArwingIndex == -1)
	{
		// Since we're not in an Arwing, we can't do anything.
		if (hSchedule != INVALID_HANDLE)
		{
			bFinishSchedule = true;
		}
	}
	
	if (!bFinishSchedule && hSchedule != INVALID_HANDLE)
	{
		if (!GetArraySize(hSchedule)) bFinishSchedule = true;
	}
	
	int iConditions = GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Conditions);
	if (!bFinishSchedule && 
		hSchedule != INVALID_HANDLE &&
		iConditions & GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_ScheduleInterrupts))
	{
		bFinishSchedule = true;
	}
	
	if (bFinishSchedule)
	{
		hSchedule = INVALID_HANDLE;
		AIArwingPilotDestroyAISchedule(iAIPilot);
	}
	
	// Reset our conditions for the next think.
	SetArrayCell(g_hAIArwingPilots, iIndex, 0, AIArwingPilot_Conditions);
	
	// Determine our state.
	int iState = AIArwingPilotGetIdealState(iAIPilot);
	SetArrayCell(g_hAIArwingPilots, iIndex, iState, AIArwingPilot_State);
	
	if (hSchedule == INVALID_HANDLE) // Pick a new schedule if we don't have one.
	{
		if (iArwingIndex != -1) // We have to be in an Arwing in order to do anything.
		{
			float flArwingPos[3], flArwingAng[3];
			GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
			GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
		
			// First, gather a list of entities that are in my vision that seem to be important.
			Handle hPlayerList = CreateArray();
			Handle hArwingList = CreateArray();
			Handle hChargedLaserList = CreateArray();
			
			Handle hTrace;
			float flEntityPos[3];
			
			// Go through players.
			for (int i = 1, iEntityArwingIndex = -1, iEntityArwing = INVALID_ENT_REFERENCE; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
				
				iEntityArwing = GetArwing(i, iEntityArwingIndex);
				if (iEntityArwingIndex != -1) continue; // We'll check for Arwings later.
				
				GetClientEyePosition(i, flEntityPos);
				
				hTrace = TR_TraceRayFilterEx(flArwingPos, flEntityPos, MASK_PLAYERSOLID, RayType_EndPoint, AIArwingPilotTraceRayVisibility, iAIPilot);
				bool bHit = TR_DidHit(hTrace);
				int iHitEntity = TR_GetEntityIndex(hTrace);
				CloseHandle(hTrace);
				
				if (!bHit || iHitEntity == i)
				{
					PushArrayCell(hPlayerList, i);
				}
			}
			
			// Go through Arwings.
			for (int i = 0, iSize = GetArraySize(g_hArwings), iEntityArwing = INVALID_ENT_REFERENCE; i < iSize; i++)
			{
				iEntityArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
				if (!iEntityArwing || iEntityArwing == INVALID_ENT_REFERENCE) continue;
				
				GetEntPropVector(iEntityArwing, Prop_Data, "m_vecAbsOrigin", flEntityPos);
				
				hTrace = TR_TraceRayFilterEx(flArwingPos, flEntityPos, MASK_PLAYERSOLID, RayType_EndPoint, AIArwingPilotTraceRayVisibility, iAIPilot);
				bool bHit = TR_DidHit(hTrace);
				int iHitEntity = TR_GetEntityIndex(hTrace);
				CloseHandle(hTrace);
				
				if (!bHit || iHitEntity == iEntityArwing)
				{
					PushArrayCell(hArwingList, iEntityArwing);
				}
			}
			
			// Detect any charged lasers around me.
			for (int i = 0, iSize = GetArraySize(g_hChargedLasers), iChargedLaser = INVALID_ENT_REFERENCE; i < iSize; i++)
			{
				iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, i));
				if (!iChargedLaser || iChargedLaser == INVALID_ENT_REFERENCE) continue;
				
				GetEntPropVector(iChargedLaser, Prop_Data, "m_vecAbsOrigin", flEntityPos);
				
				hTrace = TR_TraceRayFilterEx(flArwingPos, flEntityPos, MASK_PLAYERSOLID, RayType_EndPoint, AIArwingPilotTraceRayVisibility, iAIPilot);
				bool bHit = TR_DidHit(hTrace);
				int iHitEntity = TR_GetEntityIndex(hTrace);
				CloseHandle(hTrace);
				
				if (!bHit || iHitEntity == iChargedLaser)
				{
					PushArrayCell(hChargedLaserList, iChargedLaser);
				}
			}
			
			CloseHandle(hPlayerList);
			CloseHandle(hArwingList);
			CloseHandle(hChargedLaserList);
		}
	}
	else // Go through our schedule until it is an empty set.
	{
	}
}

bool AIArwingPilotHasCondition(int iAIPilot, AICondition iCondition)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return false;
	
	return bool (GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Conditions) & (1 << view_as<int>(iCondition)));
}

AIArwingPilotAddCondition(int iAIPilot, AICondition iCondition)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	int iNewConditions = GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Conditions);
	if (!(iNewConditions & (1 << view_as<int>(iCondition)))) iNewConditions |= (1 << view_as<int>(iCondition));
}

AIArwingPilotRemoveCondition(int iAIPilot, AICondition iCondition)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	int iNewConditions = GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Conditions);
	if (iNewConditions & (1 << view_as<int>(iCondition))) iNewConditions &= ~(1 << view_as<int>(iCondition));
}

AIState AIArwingPilotGetIdealState(int iAIPilot)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	int iEnemy = EntRefToEntIndex(GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Enemy));
	
	if (IsValidEntity(iEnemy))
	{
		return AIState_Combat;
	}
	
	return AIState_Idle;
}

Handle ConstructAISchedule(const int iTasks[], int iTaskNum)
{
	Handle hAISchedule = CreateArray();
	for (int i = 0; i < iTaskNum; i++) PushArrayCell(hAISchedule, view_as<AIScheduleTask>(iTasks[i]));
	return hAISchedule;
}

void AIArwingPilotDestroyAISchedule(int iAIPilot)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	Handle hAISchedule = view_as<Handle>(GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Schedule));
	if (hAISchedule != INVALID_HANDLE) CloseHandle(hAISchedule);
	
	SetArrayCell(g_hAIArwingPilots, iIndex, 0, AIArwingPilot_ScheduleInterrupts);
	SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_HANDLE, AIArwingPilot_Schedule);
}

Handle ConstructNewAIPath()
{
	Handle hPath = CreateArray(3);
	return hPath;
}

void PushPointToPath(Handle hPath, const float flPoint[3])
{
	PushArrayArray(hPath, flPoint, 3);
}

void AIArwingPilotDestroyPath(int iAIPilot)
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	Handle hPath = view_as<Handle>(GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Path));
	if (hPath != INVALID_HANDLE) CloseHandle(hPath);
	
	SetArrayCell(g_hAIArwingPilots, iIndex, INVALID_HANDLE, AIArwingPilot_Path);
}

void AIArwingPilotConstructPathToPoint(int iAIPilot, const float flDestination[3])
{
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex == -1) return;
	
	AIArwingPilotDestroyPath(iAIPilot);
	
	Handle hPath = ConstructNewAIPath();
	SetArrayCell(g_hAIArwingPilots, iIndex, hPath, AIArwingPilot_Path);
	
	float flMyPos[3];
	GetEntPropVector(iAIPilot, Prop_Data, "m_vecAbsOrigin", flMyPos);
	
	PushPointToPath(hPath, flMyPos);
}

public bool AIArwingPilotTraceRayVisibility(int entity, int contentsMask, any iAIPilot)
{
	if (entity == data) return false;
	
	int iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex != -1)
	{
		int iArwingIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
		if (iArwingIndex != -1)
		{
			if (GetArrayCell(g_hArwings, iArwingIndex, Arwing_Team) == GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Team)) return false;
		
			if (EntRefToEntIndex(GetArrayCell(g_hArwings, iArwingIndex, Arwing_Pilot)) == iAIPilot) return false;
		}
	}
	
	return true;
}