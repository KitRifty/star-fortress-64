#if defined _sf64_ai_pilot_arwing_included
  #endinput
#endif
#define _sf64_ai_pilot_arwing_included


#define SF64_PILOT_ARWING_CONFIG_DIRECTORY "configs/starfortress64/ai/pilots/arwing/"

enum
{
	ArwingPilot_EntRef = 0,
	ArwingPilot_Arwing,
	ArwingPilot_Target,
	ArwingPilot_Enemy,
	ArwingPilot_Enemies,
	ArwingPilot_State,
	ArwingPilot_Conditions,
	ArwingPilot_Schedule,
	ArwingPilot_ScheduleInterrupts,
	ArwingPilot_ScheduleTask,
	ArwingPilot_Path,
	ArwingPilot_PathTolerance,
	ArwingPilot_Wait,
	ArwingPilot_MaxStats
};

enum
{
	ArwingPilotConfig_KeyValues = 0,
	
	/*
	* Skill (1-10) determines how "appropriate" the pilot will use the abilities it is aware of. This can affect behaviors such as smart bombs, barrel rolls, somersaults,
	* u-turns, turning distance, aiming + prediction error, etc.
	*/
	ArwingPilotConfig_Skill,
	
	/*
	* Aggression (1-10) determines how much the pilot is willing to commit to engaging an enemy. This can affect behaviors such as engaging distance of an enemy,
	* gauging its health advantage against enemies, knowing when to flee from an enemy (or enemies), etc..
	*/
	ArwingPilotConfig_Aggression,
	
	/*
	* Caution (1-10) determines how wary the pilot is about its own survival and how it gauges its environment. This can affect behaviors such as
	* health gathering, obstacle avoidance (the more the better), etc.
	*/
	ArwingPilotConfig_Caution,
	
	ArwingPilotConfig_MaxStats
};

static Handle:g_hPilotConfigs = INVALID_HANDLE;
static Handle:g_hPilotConfigNames = INVALID_HANDLE;
static Handle:g_hPilots = INVALID_HANDLE;

InitializeArwingPilots()
{
	g_hPilotConfigs = CreateArray(ArwingPilotConfig_MaxStats);
	g_hPilotConfigNames = CreateArray(SF64_MAX_PILOT_NAME_LENGTH);
	g_hPilots = CreateArray(ArwingPilot_MaxStats);
}

/*
*	Loads all pilot configs found in the pilot configs directory.
*/
LoadAllArwingPilotConfigs()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sName[64];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, SF64_PILOT_ARWING_CONFIG_DIRECTORY);
	
	new Handle:hDirectory = OpenDirectory(sPath);
	if (hDirectory == INVALID_HANDLE)
	{
		LogError("The arwing ai pilot configs directory does not exist!");
		return;
	}
	
	decl String:sFileName[PLATFORM_MAX_PATH], FileType:iFiletype;
	
	while (ReadDirEntry(hDirectory, sFileName, sizeof(sFileName), iFiletype))
	{
		if (iFiletype == FileType_File && StrContains(sFileName, ".cfg", false) != -1)
		{
			strcopy(sName, sizeof(sName), sFileName);
			ReplaceString(sName, sizeof(sName), ".cfg", "", false);
			LoadArwingPilotConfig(sName);
		}
	}
	
	CloseHandle(hDirectory);
}

/*
*	Clears all values and memory stored in configs.
*/
ClearArwingPilotConfigs()
{
	for (new i = 0, iSize = GetArraySize(g_hPilotConfigs); i < iSize; i++)
	{
		CloseHandle(Handle:GetArrayCell(g_hPilotConfigs, i, ArwingPilotConfig_KeyValues));
	}
	
	ClearArray(g_hPilotConfigs);
	ClearArray(g_hPilotConfigNames);
	ClearArray(g_hPilots);
}

/*
*	Loads a pilot config from the config directory and returns the index in g_hPilotConfigs where the data of the config is stored.
*/
static LoadArwingPilotConfig(const String:sName[])
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s%s.cfg", SF64_PILOT_ARWING_CONFIG_DIRECTORY, sName);
	if (!FileExists(sPath))
	{
		LogError("Arwing pilot config %s does not exist!", sName);
		return;
	}
	
	new Handle:hConfig = CreateKeyValues("root");
	if (!FileToKeyValues(hConfig, sPath))
	{
		CloseHandle(hConfig);
		LogError("Arwing pilot config %s failed to load!", sName);
		return;
	}
	
	KvRewind(hConfig);
	if (KvGotoFirstSubKey(hConfig))
	{
		decl String:sSectionName[64], String:sIndex[32], String:sValue[PLATFORM_MAX_PATH], String:sDownload[PLATFORM_MAX_PATH];
		
		do
		{
			KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
			
			if (!StrContains(sSectionName, "sound_"))
			{
				for (new i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheSound2(sValue);
				}
			}
			else if (StrEqual(sSectionName, "download"))
			{
				for (new i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					AddFileToDownloadsTable(sValue);
				}
			}
			else if (StrEqual(sSectionName, "mod_precache"))
			{
				for (new i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheModel(sValue, true);
				}
			}
			else if (StrEqual(sSectionName, "mat_download"))
			{	
				for (new i = 1;; i++)
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
				new String:sExtensions[][] = { ".mdl", ".phy", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd" };
				
				for (new i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					for (new i2 = 0; i2 < sizeof(sExtensions); i2++)
					{
						Format(sDownload, sizeof(sDownload), "%s%s", sValue, sExtensions[i2]);
						AddFileToDownloadsTable(sDownload);
					}
				}
			}
		}
		while (KvGotoNextKey(hConfig));
	}
	
	PushArrayString(g_hPilotConfigNames, sName);
	new iIndex = PushArrayCell(g_hPilotConfigs, hConfig);
	if (iIndex != -1)
	{
		KvRewind(hConfig);
		new iSkill = clamp(KvGetInt(hConfig, "skill", 1), 1, 10);
		new iAggression = clamp(KvGetInt(hConfig, "aggression", 1), 1, 10);
		new iCaution = clamp(KvGetInt(hConfig, "caution", 1), 1, 10);
		
		SetArrayCell(g_hPilotConfigs, iIndex, hConfig, ArwingPilotConfig_KeyValues);
		SetArrayCell(g_hPilotConfigs, iIndex, iSkill, ArwingPilotConfig_Skill);
		SetArrayCell(g_hPilotConfigs, iIndex, iAggression, ArwingPilotConfig_Aggression);
		SetArrayCell(g_hPilotConfigs, iIndex, iCaution, ArwingPilotConfig_Caution);
	}
	
	return iIndex;
}

/*
*	Spawns an Arwing pilot entity and returns the entity index which it is associated with.
*/
SpawnArwingPilot(const String:sName[], const Float:flPos[3], const Float:flAng[3], iTeam, &iIndex=-1)
{
}

/*
*	Handle overall movement commands of the pilot.
*/
ProcessArwingPilotMoveCmds(iPilot)
{
	decl iVehicleType, iArwingIndex;
	new iArwing = GetCurrentVehicle(iPilot, iVehicleType, iArwingIndex);
	if (iVehicleType != VehicleType_Arwing)
	{
		return; // No vehicle: don't do anything.
	}
	
	
}

/*
*	Checks sections of space ahead of the pilot's vehicle. Returns a set of flags indicating which spaces are clear.
*/
static CheckForObstaclesAhead(iPilot, iVehicle, Float:flDist)
{
	decl Float:flAng[3];
	GetEntitySmoothedVelocity(iVehicle, flAng);
	NormalizeVector(flAng, flAng);
	GetVectorAngles(flAng, flAng);
	
	decl Float:flFwd[3], Float:flRight[3], Float:flUp[3];
	GetAngleVectors(flAng, flFwd, flRight, flUp);
	NormalizeVector(flFwd, flFwd);
	NormalizeVector(flRight, flRight);
	NormalizeVector(flUp, flUp);
	
	flAng[0] = flAng[2] = 0.0;
	flAng[1] = AngleNormalize(flAng[1]);
	
	decl Float:flMins[3], Float:flMaxs[3];
	GetEntityBoundingBoxScaled(iVehicle, flMins, flMaxs, GetEntPropFloat(iVehicle, Prop_Send, "m_flModelScale"));
	
}

static CheckForObstaclesAheadPartial(iPilot, iVehicle, iPartial, Float:flDist, const Float:flMins[3], const Float:flMaxs[3], const Float:flFwd[3], const Float:flRight[3], const Float:flUp[3])
{
	
}

public Action:Timer_ArwingPilotThink(Handle:timer, any:entref)
{
}

public bool:ArwingPilotTraceRayVisibility(entity, contentsMask, any:iAIPilot)
{
	if (entity == data) return false;
	
	new iIndex = FindValueInArray(g_hAIArwingPilots, EntIndexToEntRef(iAIPilot));
	if (iIndex != -1)
	{
		new iArwingIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
		if (iArwingIndex != -1)
		{
			if (GetArrayCell(g_hArwings, iArwingIndex, Arwing_Team) == GetArrayCell(g_hAIArwingPilots, iIndex, AIArwingPilot_Team)) return false;
		
			if (EntRefToEntIndex(GetArrayCell(g_hArwings, iArwingIndex, Arwing_Pilot)) == iAIPilot) return false;
		}
	}
	
	return true;
}