#if defined _sf64_arwing_included
  #endinput
#endif
#define _sf64_arwing_included

#include "starfortress64/effects.sp"


#define ARWING_BARRELROLL_ROTATE_ENT_MODEL "models/Effects/teleporttrail.mdl"

Handle g_hArwingConfigs;

Handle g_hArwings;
Handle g_hArwingNames;


void LoadAllArwingConfigs()
{
	char sPath[PLATFORM_MAX_PATH], sFileName[PLATFORM_MAX_PATH], sName[64];
	FileType iFiletype;
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/vehicles/arwing/");
	
	Handle hDirectory = OpenDirectory(sPath);
	if (hDirectory == INVALID_HANDLE)
	{
		LogError("The arwing vehicle configs directory does not exist!");
		return;
	}
	
	while (ReadDirEntry(hDirectory, sFileName, sizeof(sFileName), iFiletype))
	{
		if (iFiletype == FileType_File && StrContains(sFileName, ".cfg", false) != -1)
		{
			strcopy(sName, sizeof(sName), sFileName);
			ReplaceString(sName, sizeof(sName), ".cfg", "", false);
			LoadArwingConfig(sName);
		}
	}
	
	CloseHandle(hDirectory);
}

void LoadArwingConfig(const char[] sName)
{
	RemoveArwingConfig(sName);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/vehicles/arwing/%s.cfg", sName);
	if (!FileExists(sPath))
	{
		LogError("Arwing vehicle config %s does not exist!", sName);
		return;
	}
	
	Handle hConfig = CreateKeyValues("root");
	if (!FileToKeyValues(hConfig, sPath))
	{
		CloseHandle(hConfig);
		LogError("Arwing vehicle config %s is invalid!", sName);
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
			else if (StrEqual(sSectionName, "mat_precache"))
			{
				for (int i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheMaterial(sValue);
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
	
	SetTrieValue(g_hArwingConfigs, sName, hConfig);
}

void RemoveArwingConfig(const char[] sName)
{
	Handle hConfig = INVALID_HANDLE;
	if (GetTrieValue(g_hArwingConfigs, sName, hConfig) && hConfig != INVALID_HANDLE)
	{
		CloseHandle(hConfig);
		SetTrieValue(g_hArwingConfigs, sName, INVALID_HANDLE);
	}
}

// Code originally from FF2. Credits to the original authors Rainbolt Dash and FlaminSarge.
stock bool GetRandomStringFromArwingConfig(Handle hConfig, const char[] strKeyValue, char[] buffer, int bufferlen, int index=-1)
{
	strcopy(buffer, bufferlen, "");
	
	if (hConfig == INVALID_HANDLE) return false;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, strKeyValue)) return false;
	
	char s[32], s2[PLATFORM_MAX_PATH];
	
	int i = 1;
	for (;;)
	{
		IntToString(i, s, sizeof(s));
		KvGetString(hConfig, s, s2, sizeof(s2));
		if (!s2[0]) break;
		
		i++;
	}
	
	if (i == 1) return false;
	
	IntToString(index < 0 ? GetRandomInt(1, i - 1) : index, s, sizeof(s));
	KvGetString(hConfig, s, buffer, bufferlen);
	return true;
}

stock Handle GetArwingConfig(const char[] sName)
{
	Handle hConfig = INVALID_HANDLE;
	GetTrieValue(g_hArwingConfigs, sName, hConfig);
	return hConfig;
}

stock Handle GetConfigOfArwing(int iArwing)
{
	if (!IsValidEntity(iArwing)) return INVALID_HANDLE;
	
	int entref = EntIndexToEntRef(iArwing);
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return INVALID_HANDLE;
	
	char sEntRef[256];
	IntToString(entref, sEntRef, sizeof(sEntRef));
	
	char sName[64];
	GetTrieString(g_hArwingNames, sEntRef, sName, sizeof(sName));
	if (!sName[0]) return INVALID_HANDLE;
	
	return GetArwingConfig(sName);
}

stock int SpawnArwing(const char[] sName, const float flPos[3], const float flAng[3], const float flVelocity[3], int &iIndex=-1)
{
	Handle hConfig = GetArwingConfig(sName);
	if (hConfig == INVALID_HANDLE)
	{
		LogError("Could not spawn arwing %s because the config is invalid!", sName);
		return -1;
	}

	int iArwing = CreateEntityByName("prop_physics_override");
	if (iArwing != -1)
	{
		char sBuffer[PLATFORM_MAX_PATH];
		KvRewind(hConfig);
		KvGetString(hConfig, "model", sBuffer, sizeof(sBuffer));
		SetEntityModel(iArwing, sBuffer);
		DispatchKeyValueFloat(iArwing, "modelscale", KvGetFloat(hConfig, "modelscale", 1.0));
		DispatchSpawn(iArwing);
		ActivateEntity(iArwing);
		Phys_SetMass(iArwing, KvGetFloat(hConfig, "mass", 100.0));
		DispatchKeyValueFloat(iArwing, "physdamagescale", KvGetFloat(hConfig, "physdamagescale", 1.0));
		
		DispatchKeyValue(iArwing, "classname", "sf64_vehicle_arwing");
		
		iIndex = PushArrayCell(g_hArwings, EntIndexToEntRef(iArwing));
		
		char sEntRef[256];
		IntToString(EntIndexToEntRef(iArwing), sEntRef, sizeof(sEntRef));
		SetTrieString(g_hArwingNames, sEntRef, sName);
		
		// Set up base stats.
		SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "maxhealth"), Arwing_MaxHealth);
		SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "maxhealth"), Arwing_Health);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "maxspeed"), Arwing_MaxSpeed);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "pitchrate"), Arwing_PitchRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "yawrate"), Arwing_YawRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "rollrate"), Arwing_RollRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "accelfactor"), Arwing_AccelFactor);
		
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Pilot);
		SetArrayCell(g_hArwings, iIndex, -1, Arwing_PilotSequence);
		SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_PilotSequenceStartTime);
		SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_PilotSequenceEndTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_PilotHudLastTime);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_Buttons);
		SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_CrouchStartTime);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_IgnorePilotControls);
		
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Target);
		
		SetArrayCell(g_hArwings, iIndex, false, Arwing_Locked);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_Destroyed);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_Obliterated);
		
		// Set up damage sequence.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InDamageSequence);
		SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_LastDamageSequenceUpdateTime);
		
		// Set up camera.
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_CameraEnt);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "camera_pitchrate"), Arwing_CameraPitchRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "camera_yawrate"), Arwing_CameraYawRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "camera_rollrate"), Arwing_CameraRollRate);
		SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "camera_angaccelfactor"), Arwing_CameraAngAccelFactor);
		
		// Set up energy.
		SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "energy_max"), Arwing_MaxEnergy);
		SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "energy_max"), Arwing_Energy);
		SetArrayCell(g_hArwings, iIndex, CreateTimer(KvGetFloat(hConfig, "energy_rechargerate"), Timer_ArwingRechargeEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE), Arwing_EnergyRechargeTimer);
		
		// Set up lasers.
		SetArrayCell(g_hArwings, iIndex, 1, Arwing_LaserMaxUpgradeLevel);
		SetArrayCell(g_hArwings, iIndex, 1, Arwing_LaserUpgradeLevel);
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_LaserLifeTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LaserDamage);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LaserHyperDamage);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LaserCooldown);
		ResetArwingLaser(iArwing);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "weapons"))
		{
			if (KvJumpToKey(hConfig, "types") && KvJumpToKey(hConfig, "laser"))
			{
				SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "upgrade_level_max", 1), Arwing_LaserMaxUpgradeLevel);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_LaserSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "lifetime"), Arwing_LaserLifeTime);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damage"), Arwing_LaserDamage);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damage_hyper"), Arwing_LaserHyperDamage);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "cooldown"), Arwing_LaserCooldown);
			}
		}
		
		// Set up charged laser.
		SetArrayCell(g_hArwings, iIndex, 1, Arwing_ChargedLaserUpgradeLevel);
		SetArrayCell(g_hArwings, iIndex, 1, Arwing_ChargedLaserMaxUpgradeLevel);
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_ChargedLaserLifeTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ChargedLaserDamage);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ChargedLaserDamageRadius);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ChargedLaserCooldown);
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_ChargedLaserEnt);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ChargedLaserStartTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastChargedLaserAttackTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_NextChargedLaserAttackTime);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_ChargedLaserReady);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "weapons"))
		{
			if (KvJumpToKey(hConfig, "types") && KvJumpToKey(hConfig, "chargedlaser"))
			{
				SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "upgrade_level_max", 1), Arwing_ChargedLaserMaxUpgradeLevel);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_ChargedLaserSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "lifetime"), Arwing_ChargedLaserLifeTime);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damage"), Arwing_ChargedLaserDamage);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damageradius"), Arwing_ChargedLaserDamageRadius);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "cooldown"), Arwing_ChargedLaserCooldown);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "trackduration"), Arwing_ChargedLaserTrackDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "chargeduration"), Arwing_ChargedLaserChargeDuration);
			}
		}
		
		// Set up Smart Bombs.
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_SmartBombLifeTime);
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_SmartBombMaxSpeed);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SmartBombDamage);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SmartBombDamageRadius);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SmartBombTrackDuration);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_SmartBombMaxNum);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_SmartBombNum);
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_SmartBombEnt);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "weapons"))
		{
			if (KvJumpToKey(hConfig, "types") && KvJumpToKey(hConfig, "smartbomb"))
			{
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_SmartBombMaxSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "lifetime"), Arwing_SmartBombLifeTime);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damage"), Arwing_SmartBombDamage);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "damageradius"), Arwing_SmartBombDamageRadius);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "trackduration"), Arwing_SmartBombTrackDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "max"), Arwing_SmartBombMaxNum);
			}
		}
		
		// Set up tilt ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasTiltAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InTilt);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_TiltDirection);
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_TiltDesiredDirection);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "tilt"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasTiltAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "degrees"), Arwing_TiltDegrees);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "turnrate"), Arwing_TiltTurnRate);
			}
		}
		
		// Set up brake ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasBrakeAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InBrake);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastBrakeTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BrakeSpeed);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BrakeEnergyBurnRate);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BrakeEnergyBurnTimer);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "brake"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasBrakeAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_BrakeSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "energyburnrate"), Arwing_BrakeEnergyBurnRate);
			}
		}
		
		// Set up boost ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasBoostAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InBoost);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastBoostTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BoostSpeed);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BoostEnergyBurnRate);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BoostEnergyBurnTimer);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "boost"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasBoostAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_BoostSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "energyburnrate"), Arwing_BoostEnergyBurnRate);
			}
		}
		
		// Set up somersault ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasSomersaultAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InSomersault);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastSomersaultTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SomersaultDuration);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SomersaultEnergyBurnRate);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultEnergyBurnTimer);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultTimer);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SomersaultAngleFactor);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SomersaultSpeed);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "somersault"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasSomersaultAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "duration"), Arwing_SomersaultDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "energyburnrate"), Arwing_SomersaultEnergyBurnRate);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "anglefactor"), Arwing_SomersaultAngleFactor);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "speed"), Arwing_SomersaultSpeed);
			}
		}
		
		// Set up U-turn ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasUTurnAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InUTurn);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnTimer);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_UTurnPhase);
		SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnPhaseTimer);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastUTurnTime);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "uturn"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasUTurnAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "duration"), Arwing_UTurnDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "somersault_duration"), Arwing_UTurnSomersaultDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "somersault_anglefactor"), Arwing_UTurnSomersaultAngleFactor);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "somersault_speed"), Arwing_UTurnSomersaultSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "boost_speed"), Arwing_UTurnBoostSpeed);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "energyburnrate"), Arwing_UTurnEnergyBurnRate);
			}
		}
		
		// Set up barrel roll ability.
		SetArrayCell(g_hArwings, iIndex, false, Arwing_HasBarrelRollAbility);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InBarrelRoll);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_LastBarrelRollTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_NextBarrelRollTime);
		SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_BarrelRollDirection);
		SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_BarrelRollStartTime);
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollRotateEnt);
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollEnt);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BarrelRollRotatePosX);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BarrelRollRotatePosY);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_BarrelRollRotatePosZ);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_BarrelRollNum);
		
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "abilities"))
		{
			if (KvJumpToKey(hConfig, "barrelroll"))
			{
				SetArrayCell(g_hArwings, iIndex, true, Arwing_HasBarrelRollAbility);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "duration"), Arwing_BarrelRollDuration);
				SetArrayCell(g_hArwings, iIndex, KvGetFloat(hConfig, "cooldown"), Arwing_BarrelRollCooldown);
				
				SetArrayCell(g_hArwings, iIndex, KvGetNum(hConfig, "rolls", 1), Arwing_BarrelRollNum);
				
				float flOffset[3];
				KvGetVector(hConfig, "rotate_pos_offset", flOffset);
				
				SetArrayCell(g_hArwings, iIndex, flOffset[0], Arwing_BarrelRollRotatePosX);
				SetArrayCell(g_hArwings, iIndex, flOffset[1], Arwing_BarrelRollRotatePosY);
				SetArrayCell(g_hArwings, iIndex, flOffset[2], Arwing_BarrelRollRotatePosZ);
			}
		}
		
		// Set up health bar.
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_HealthBarStartEntity);
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_HealthBarEndEntity);
		
		// Set up fake model.
		SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_FakePilotModel);
		
		SetArrayCell(g_hArwings, iIndex, false, Arwing_InPilotSequence);
		
		// Spawn reticles.
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "reticles") && KvGotoFirstSubKey(hConfig))
		{
			char sType[64];
			char sMaterial[PLATFORM_MAX_PATH];
			int iReticle, iColor[4];
			float flOffsetPos[3];
			
			do
			{
				KvGetString(hConfig, "model", sMaterial, sizeof(sMaterial));
				if (sMaterial[0])
				{
					KvGetString(hConfig, "type", sType, sizeof(sType));
					if (!StrEqual(sType, "lockon"))
					{
						KvGetVector(hConfig, "origin", flOffsetPos);
						
						iReticle = SpawnTargetReticle(sMaterial, flOffsetPos, NULL_VECTOR, NULL_VECTOR, iArwing, KvGetFloat(hConfig, "scale", 1.0), false);
						if (iReticle != -1)
						{
							SetVariantString("!activator");
							AcceptEntityInput(iReticle, "SetParent", iArwing);
							KvGetColor(hConfig, "rendercolor", iColor[0], iColor[1], iColor[2], iColor[3]);
							SetVariantInt(iColor[0]);
							AcceptEntityInput(iReticle, "ColorRedValue");
							SetVariantInt(iColor[1]);
							AcceptEntityInput(iReticle, "ColorGreenValue");
							SetVariantInt(iColor[2]);
							AcceptEntityInput(iReticle, "ColorBlueValue");
							
							char sValue[64];
							IntToString(KvGetNum(hConfig, "renderamt", 255), sValue, sizeof(sValue));
							DispatchKeyValue(iReticle, "renderamt", sValue);
							IntToString(KvGetNum(hConfig, "rendermode", 5), sValue, sizeof(sValue));
							DispatchKeyValue(iReticle, "rendermode", sValue);
							
							AcceptEntityInput(iReticle, "ShowSprite");
						}
					}
				}
			}
			while (KvGotoNextKey(hConfig));
		}
		
		DisableArwing(iArwing, true);
		
		// Spawn effects.
		ArwingSpawnEffects(iArwing, EffectEvent_Constant);
		TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_Constant);
		
		TeleportEntity(iArwing, flPos, flAng, flVelocity);
		SDKHook(iArwing, SDKHook_VPhysicsUpdate, Hook_ArwingVPhysicsUpdate);
		SDKHook(iArwing, SDKHook_OnTakeDamagePost, Hook_ArwingOnTakeDamagePost);
		CreateTimer(0.0001, Timer_ArwingThink, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return iArwing;
}

void EnableArwing(int iArwing, bool bForce=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))) return;
	if (!bForce && view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_Enabled);
	ResetArwingMove(iArwing);
	
	// Start up the health bar.
	ArwingUpdateHealthBar(iArwing);
	
	Phys_Wake(iArwing);
	Phys_EnableGravity(iArwing, false);
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingEnabled);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingEnabled);
	
	ArwingSetEnergy(iArwing, GetArrayCell(g_hArwings, iIndex, Arwing_Energy), false);
}

void ArwingSetHealth(int iArwing, int iAmount, bool bCheckOldValue=true)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iOldAmount = GetArrayCell(g_hArwings, iIndex, Arwing_Health);
	if (bCheckOldValue && iAmount == iOldAmount) return;
	
	SetArrayCell(g_hArwings, iIndex, iAmount, Arwing_Health);
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	char sPath[PLATFORM_MAX_PATH];
	
	int iMaxHealth = GetArrayCell(g_hArwings, iIndex, Arwing_MaxHealth);
	float flOldHealthPercent = float(iOldAmount) / float(iMaxHealth);
	float flHealthPercent = float(iAmount) / float(iMaxHealth);
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
	if (flHealthPercent <= 0.75 && flOldHealthPercent > 0.75)
	{
		ArwingSpawnEffects(iArwing, EffectEvent_ArwingHealth75Pct);
		TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingHealth75Pct);
		
		if (IsValidClient(iPilot))
		{
			if (GetRandomStringFromArwingConfig(hConfig, "sound_health_75pct", sPath, sizeof(sPath)) && sPath[0])
			{
				EmitSoundToClient(iPilot, sPath, _, SNDCHAN_WEAPON, SNDLEVEL_NONE);
			}
		}
	}
	else if (flHealthPercent > 0.75 && flOldHealthPercent <= 0.75)
	{
		RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingHealth75Pct);
	}
	
	if (flHealthPercent <= 0.5 && flOldHealthPercent > 0.5)
	{
		ArwingSpawnEffects(iArwing, EffectEvent_ArwingHealth50Pct);
		TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingHealth50Pct);
		
		if (IsValidClient(iPilot))
		{
			if (GetRandomStringFromArwingConfig(hConfig, "sound_health_50pct", sPath, sizeof(sPath)) && sPath[0])
			{
				EmitSoundToClient(iPilot, sPath, _, SNDCHAN_WEAPON, SNDLEVEL_NONE);
			}
		}
	}
	else if (flHealthPercent > 0.5 && flOldHealthPercent <= 0.5)
	{
		RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingHealth50Pct);
	}
	
	if (flHealthPercent <= 0.25)
	{
		if (flOldHealthPercent > 0.25)
		{
			ArwingSpawnEffects(iArwing, EffectEvent_ArwingHealth25Pct);
			TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingHealth25Pct);
		}
		
		if (flHealthPercent < flOldHealthPercent)
		{
			if (IsValidClient(iPilot))
			{
				if (GetRandomStringFromArwingConfig(hConfig, "sound_health_25pct", sPath, sizeof(sPath)) && sPath[0])
				{
					EmitSoundToClient(iPilot, sPath, _, SNDCHAN_WEAPON, SNDLEVEL_NONE);
				}
			}
		}
	}
	else if (flHealthPercent > 0.25 && flOldHealthPercent <= 0.25)
	{
		RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingHealth25Pct);
	}
	
	ArwingUpdateHealthBar(iArwing);
}

void ArwingSetEnergy(int iArwing, int iAmount, bool bCheckOldValue=true)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iOldEnergyAmount = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (bCheckOldValue && iAmount == iOldEnergyAmount) return;
	
	SetArrayCell(g_hArwings, iIndex, iAmount, Arwing_Energy);
	
	int iMaxEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy);
	
	if ((!bCheckOldValue || iOldEnergyAmount < iMaxEnergy) && iAmount >= iMaxEnergy)
	{
		if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)))
		{
			ArwingSpawnEffects(iArwing, EffectEvent_ArwingFullEnergy);
			TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingFullEnergy);
		}
	}
	else if ((!bCheckOldValue || iOldEnergyAmount >= iMaxEnergy) && iAmount < iMaxEnergy)
	{
		RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingFullEnergy);
	}
}

void DisableArwing(int iArwing, bool bForce=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bForce && !view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_Enabled);
	ResetArwingMove(iArwing);
	
	Phys_EnableGravity(iArwing, true);
	
	// Stop abilities.
	ArwingStopTilt(iArwing);
	ArwingStopBoost(iArwing);
	ArwingStopBrake(iArwing);
	ArwingStopSomersault(iArwing);
	ArwingStopUTurn(iArwing);
	
	// Destroy healthbar.
	ArwingRemoveHealthBar(iArwing);
	
	// Effects.
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingEnabled);
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingFullEnergy);
	
	// Sounds.
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		char sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_flyloop", sPath, sizeof(sPath), 1) && sPath[0])
		{
			StopSound(iArwing, SNDCHAN_STATIC, sPath);
		}
	}
}

void InsertPilotIntoArwing(int iArwing, int iPilot, bool bImmediate=false)
{
	if (!IsValidEntity(iPilot)) return;

	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))) return;
	
	DebugMessage("InsertPilotIntoArwing START (%d, %d)", iArwing, iPilot);
	
	int iMyPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (iMyPilot && iMyPilot != INVALID_ENT_REFERENCE) return;
	
	if (IsValidClient(iPilot))
	{
		if (!OnClientEnterArwing(iPilot, iArwing, bImmediate)) return;
	}
	
	ArwingReleaseAllButtons(iArwing);
	SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iPilot), Arwing_Pilot);
	
	// Effects.
	ArwingSetTeamColorOfEffects(iArwing);
	
	DebugMessage("InsertPilotIntoArwing END (%d, %d)", iArwing, iPilot);
}

void EjectPilotFromArwing(int iArwing, bool bImmediate=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (!iPilot || iPilot == INVALID_ENT_REFERENCE) return;
	
	DebugMessage("EjectPilotFromArwing START (%d)", iArwing);
	
	ArwingReleaseAllButtons(iArwing);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Pilot);
	
	if (IsValidClient(iPilot)) OnClientExitArwing(iPilot, iArwing, bImmediate);
	
	DebugMessage("EjectPilotFromArwing END (%d)", iArwing);
}

stock int GetArwing(int ent, int &iIndex=-1)
{
	if (!IsValidEntity(ent)) return -1;

	int iArwing;
	for (int i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
	{
		iArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
		if (!iArwing || iArwing == INVALID_ENT_REFERENCE) continue;
		
		if (EntRefToEntIndex(GetArrayCell(g_hArwings, i, Arwing_Pilot)) == ent)
		{
			iIndex = i;
			return iArwing;
		}
	}
	
	return -1;
}


void ResetArwingLaser(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_NextLaserAttackTime);
}

void ResetArwingMove(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ForwardMove);
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SideMove);
}

void ArwingStartTilt(int iArwing, float flDesiredDirection)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InTilt))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "abilities") || !KvJumpToKey(hConfig, "tilt")) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InTilt);
	SetArrayCell(g_hArwings, iIndex, flDesiredDirection, Arwing_TiltDirection);
}

void ArwingStopTilt(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InTilt))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InTilt);
}

void ArwingStartBarrelRoll(int iArwing, float flDesiredDirection)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll))) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_HasBarrelRollAbility))) return;
	
	if (GetGameTime() < GetArrayCell(g_hArwings, iIndex, Arwing_NextBarrelRollTime)) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBarrelRoll);
	SetArrayCell(g_hArwings, iIndex, flDesiredDirection, Arwing_BarrelRollDirection);
	
	int iPropEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
	if (iPropEnt && iPropEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iPropEnt);
	}
	
	int iRotateEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotateEnt));
	if (iRotateEnt && iRotateEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iRotateEnt);
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollEnt);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollRotateEnt);
	
	iRotateEnt = CreateEntityByName("prop_dynamic_override");
	if (iRotateEnt != -1)
	{
		float flArwingPos[3], flArwingAng[3];
		GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
		GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
		
		float flRotatePos[3];
		flRotatePos[0] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosX));
		flRotatePos[1] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosY));
		flRotatePos[2] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosZ));
		
		VectorTransform(flRotatePos, flArwingPos, flArwingAng, flRotatePos);
		
		SetEntityModel(iRotateEnt, ARWING_BARRELROLL_ROTATE_ENT_MODEL);
		DispatchSpawn(iRotateEnt);
		ActivateEntity(iRotateEnt);
		TeleportEntity(iRotateEnt, flRotatePos, flArwingAng, NULL_VECTOR);
		
		int iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			//DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iRotateEnt);
		}
		
		SetVariantString("!activator");
		AcceptEntityInput(iRotateEnt, "SetParent", iArwing);
		SetEntityRenderMode(iRotateEnt, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iRotateEnt, 0, 0, 0, 1);
		SetEntityMoveType(iRotateEnt, MOVETYPE_NOCLIP);
		SetEntProp(iRotateEnt, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iRotateEnt, Prop_Send, "m_CollisionGroup", 0);
		
		SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iRotateEnt), Arwing_BarrelRollRotateEnt);
		
		iPropEnt = CreateEntityByName("prop_dynamic_override");
		if (iPropEnt != -1)
		{
			char sModel[PLATFORM_MAX_PATH];
			GetEntPropString(iArwing, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			SetEntityModel(iPropEnt, sModel);
			DispatchSpawn(iPropEnt);
			ActivateEntity(iPropEnt);
			SetEntProp(iPropEnt, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
			SetEntProp(iPropEnt, Prop_Send, "m_CollisionGroup", 0);
			SetEntPropFloat(iPropEnt, Prop_Send, "m_flModelScale", GetEntPropFloat(iArwing, Prop_Send, "m_flModelScale"));
			TeleportEntity(iPropEnt, flArwingPos, flArwingAng, NULL_VECTOR);
			SetVariantString("!activator");
			AcceptEntityInput(iPropEnt, "SetParent", iRotateEnt);
			AcceptEntityInput(iPropEnt, "EnableShadow");
			
			SetEntityRenderMode(iArwing, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iArwing, 0, 0, 0, 1);
			
			SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iPropEnt), Arwing_BarrelRollEnt);
		}
	}
	
	CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDuration)), Timer_ArwingStopBarrelRoll, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollCooldown)), Arwing_NextBarrelRollTime);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBarrelRollTime);
	
	ArwingParentMyEffectsToSelfOfEvent(iArwing, EffectEvent_All);
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBarrelRoll);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBarrelRoll);
}

stock void ArwingParentMyEffectsToSelfOfEvent(int iArwing, EffectEvent iEvent, bool bIgnoreKill=false)
{
	int iEffect, iEffectOwner;
	EffectEvent iEffectEvent;

	for (int i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		if (!bIgnoreKill && view_as<bool>(GetArrayCell(g_hEffects, i, Effect_InKill))) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (!iEffectOwner || iEffectOwner == INVALID_ENT_REFERENCE || iEffectOwner != iArwing) return;
		
		iEffectEvent = view_as<EffectEvent>(GetArrayCell(g_hEffects, i, Effect_Event));
		if (iEvent == EffectEvent_All || iEffectEvent == iEvent)
		{
			ArwingParentMyEffectToSelf(iArwing, i);
		}
	}
}

public Action Timer_ArwingBarrelRoll(Handle timer, any entref)
{
	int iEnt = EntRefToEntIndex(entref);
	if (!iEnt || iEnt == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	float flAng[3]; // Get angles local to parent.
	GetEntPropVector(iEnt, Prop_Data, "m_angRotation", flAng);
	flAng[2] -= 150.0;
	flAng[2] = AngleNormalize(flAng[2]);
	TeleportEntity(iEnt, NULL_VECTOR, flAng, NULL_VECTOR);
	
	return Plugin_Continue;
}

public Action Timer_ArwingStopBarrelRoll(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ArwingStopBarrelRoll(iArwing);
}

void ArwingStopBarrelRoll(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBarrelRoll);
	
	VehicleParentMyEffectsToSelfOfEvent(iArwing, EffectEvent_All);
	
	int iEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
	if (iEnt && iEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iEnt);
	}
	
	iEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotateEnt));
	if (iEnt && iEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iEnt);
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollEnt);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollRotateEnt);
	SetEntityRenderMode(iArwing, RENDER_NORMAL);
	SetEntityRenderColor(iArwing, 255, 255, 255, 255);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingBarrelRoll);
}

void ArwingStartUTurn(int iArwing, bool bForce=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated))) return;
	
	if (!bForce && (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake))))
	{
		return;
	}
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_HasUTurnAbility))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return; // Highly unlikely that this will happen.
	
	if (!bForce && GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InUTurn);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastUTurnTime);
	
	Handle hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnEnergyBurnRate)), Timer_ArwingUTurnBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	// Set to phase 1. The semi-somersault.
	SetArrayCell(g_hArwings, iIndex, 1, Arwing_UTurnPhase);
	hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultDuration)), Timer_ArwingUTurnPhaseOne, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnPhaseTimer);
	
	hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnDuration)), Timer_ArwingStopUTurn, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnTimer);
	
	float flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	SetArrayCell(g_hArwings, iIndex, flArwingAng[1], Arwing_UTurnYawAngle);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_uturn_somersault", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingUTurn);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingUTurn);
}

public Action Timer_ArwingUTurnBurnEnergy(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnEnergyBurnTimer))) return Plugin_Stop;
	
	int iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy > 0)
	{
		ArwingSetEnergy(iArwing, iEnergy - 1);
	}
	
	return Plugin_Continue;
}

public Action Timer_ArwingUTurnPhaseOne(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnPhaseTimer))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return; // Highly unlikely that this will happen.
	
	// Set to phase two. The boost. This will last for the rest of the U-turn manuever.
	SetArrayCell(g_hArwings, iIndex, 2, Arwing_UTurnPhase);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnPhaseTimer);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_uturn_boost", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
}

public Action Timer_ArwingStopUTurn(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnTimer))) return;
	
	ArwingStopUTurn(iArwing);
}

void ArwingStopUTurn(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InUTurn);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnEnergyBurnTimer);
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_UTurnPhase);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnPhaseTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingUTurn);
}

void ArwingStartBoost(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)))
	{
		return;
	}
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_HasBoostAbility))) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBoost);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBoostTime);
	
	Handle hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BoostEnergyBurnRate)), Timer_ArwingBoostBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_BoostEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_boost", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBoost);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBoost);
}

void ArwingStopBoost(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBoost);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BoostEnergyBurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingBoost);
}

public Action Timer_ArwingBoostBurnEnergy(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_BoostEnergyBurnTimer))) return Plugin_Stop;
	
	int iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy <= 0)
	{
		ArwingStopBoost(iArwing);
		return Plugin_Stop;
	}
	
	ArwingSetEnergy(iArwing, iEnergy - 1);
	
	return Plugin_Continue;
}

void ArwingStartBrake(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)))
	{
		return;
	}
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_HasBrakeAbility))) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBrake);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBrakeTime);
	
	Handle hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BrakeEnergyBurnRate)), Timer_ArwingBrakeBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_BrakeEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_brake", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBrake);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBrake);
}

void ArwingStopBrake(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBrake);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BrakeEnergyBurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingBrake);
}

public Action Timer_ArwingBrakeBurnEnergy(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_BrakeEnergyBurnTimer))) return Plugin_Stop;
	
	int iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy <= 0)
	{
		ArwingStopBrake(iArwing);
		return Plugin_Stop;
	}
	
	ArwingSetEnergy(iArwing, iEnergy - 1);
	
	return Plugin_Continue;
}

void ArwingStartSomersault(int iArwing, bool bIgnoreEnergy=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)))
	{
		return;
	}
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_HasSomersaultAbility))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	if (!bIgnoreEnergy && GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	float flArwingPos[3], flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	float flCurTime = GetGameTime();
	float flDuration = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultDuration));
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InSomersault);
	SetArrayCell(g_hArwings, iIndex, flCurTime, Arwing_LastSomersaultTime);
	SetArrayCell(g_hArwings, iIndex, flArwingAng[1], Arwing_SomersaultYawAngle);
	
	Handle hTimer = CreateTimer(view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultEnergyBurnRate)), Timer_ArwingSomersaultBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_SomersaultEnergyBurnTimer);
	
	hTimer = CreateTimer(flDuration, Timer_ArwingStopSomersault, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_SomersaultTimer);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_somersault", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingSomersault);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingSomersault);
}

public Action Timer_ArwingSomersaultBurnEnergy(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultEnergyBurnTimer))) return Plugin_Stop;
	
	int iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy > 0)
	{
		ArwingSetEnergy(iArwing, iEnergy - 1);
	}
	
	return Plugin_Continue;
}

public Action Timer_ArwingStopSomersault(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultTimer))) return;
	
	ArwingStopSomersault(iArwing);
}

void ArwingStopSomersault(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InSomersault);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultEnergyBurnTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingSomersault);
}

void ArwingRemoveHealthBar(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	// No health bar entities? Initialize them.
	int iHealthBarStartEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarStartEntity));
	int iHealthBarEndEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarEndEntity));
	
	if ((!iHealthBarStartEntity || iHealthBarStartEntity == INVALID_ENT_REFERENCE) ||
		(!iHealthBarEndEntity || iHealthBarEndEntity == INVALID_ENT_REFERENCE))
	{
		// Remove our old ones if they exist.
		if (iHealthBarStartEntity && iHealthBarStartEntity != INVALID_ENT_REFERENCE) AcceptEntityInput(iHealthBarStartEntity, "Kill");
		if (iHealthBarEndEntity && iHealthBarEndEntity != INVALID_ENT_REFERENCE) AcceptEntityInput(iHealthBarEndEntity, "Kill");
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_HealthBarStartEntity);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_HealthBarEndEntity);
}

public bool OnClientEnterArwing(int client, int iArwing, bool bImmediate)
{
	if (!IsValidClient(client) || !IsValidEntity(iArwing)) return false;
	
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return false;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return false;
	
	// Set up the camera first.
	int iCamera = CreateEntityByName("point_viewcontrol");
	if (iCamera != -1)
	{
		float flCameraPos[3], flCameraAng[3];
		GetClientEyePosition(client, flCameraPos);
		GetClientEyeAngles(client, flCameraAng);
		TeleportEntity(iCamera, flCameraPos, flCameraAng, NULL_VECTOR);
		DispatchSpawn(iCamera);
		ActivateEntity(iCamera);
		AcceptEntityInput(iCamera, "Enable", client);
		
		SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iCamera), Arwing_CameraEnt);
		ClientSetFOV(client, 90);
	}
	
	if (!bImmediate)
	{
		SetArrayCell(g_hArwings, iIndex, true, Arwing_InPilotSequence);
	
		// Set up the fake model.
		int iFakeModel = CreateEntityByName("prop_dynamic_override");
		if (iFakeModel != -1)
		{
			float flPos[3], flAng[3];
			GetClientAbsOrigin(client, flPos);
			GetClientAbsAngles(client, flAng);
			
			char sModel[PLATFORM_MAX_PATH];
			GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			SetEntityModel(iFakeModel, sModel);
			TeleportEntity(iFakeModel, flPos, flAng, NULL_VECTOR);
			DispatchSpawn(iFakeModel);
			ActivateEntity(iFakeModel);
			SetVariantString("crouch_LOSER");
			AcceptEntityInput(iFakeModel, "SetAnimation");
			SetVariantString("crouch_LOSER");
			AcceptEntityInput(iFakeModel, "SetDefaultAnimation");
			SetEntityRenderMode(iFakeModel, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iFakeModel, 0, 0, 0, 1);
			SetEntityMoveType(iFakeModel, MOVETYPE_NOCLIP);
			SetEntProp(iFakeModel, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
			SetEntProp(iFakeModel, Prop_Send, "m_CollisionGroup", 0);
			SetEntPropFloat(iFakeModel, Prop_Send, "m_flModelScale", GetEntPropFloat(client, Prop_Send, "m_flModelScale"));
			
			// Attach dummy trail to enable movement.
			int iTrailEnt = CreateEntityByName("env_spritetrail");
			if (iTrailEnt != -1)
			{
				DispatchSpawn(iTrailEnt);
				ActivateEntity(iTrailEnt);
				SetVariantString("!activator");
				AcceptEntityInput(iTrailEnt, "SetParent", iFakeModel);
			}
			
			SetEntPropVector(iFakeModel, Prop_Data, "m_vecAngVelocity", view_as<float>({ 720.0, 0.0, 0.0 }));
			
			int iFlags = GetEntProp(client, Prop_Send, "m_fEffects");
			if (!(iFlags & 1)) iFlags |= 1;
			if (!(iFlags & iFlags)) iFlags |= 512;
			SetEntProp(client, Prop_Send, "m_fEffects", iFlags);
			
			SetVariantString("!activator");
			AcceptEntityInput(client, "SetParent", iFakeModel);
			SetVariantString("flag");
			AcceptEntityInput(client, "SetParentAttachment");
			
			SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iFakeModel), Arwing_FakePilotModel);
			
			TeleportEntity(iFakeModel, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 1200.0 }));
			
			float flOffset[3];
			KvRewind(hConfig);
			KvGetVector(hConfig, "pilot_player_pos_offset", flOffset);
			
			Handle hPack;
			Handle hTimer = CreateDataTimer(0.01, Timer_FakePilotModelMoveToOffsetOfEntity, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hPack, EntIndexToEntRef(iFakeModel));
			WritePackCell(hPack, EntIndexToEntRef(iArwing));
			WritePackFloat(hPack, flOffset[0]);
			WritePackFloat(hPack, flOffset[1]);
			WritePackFloat(hPack, flOffset[2]);
			TriggerTimer(hTimer, true);
			
			hTimer = CreateDataTimer(0.01, Timer_FakePilotModelScaleToSize, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hPack, EntIndexToEntRef(iFakeModel));
			WritePackFloat(hPack, 0.1);
			WritePackFloat(hPack, 0.05);
			TriggerTimer(hTimer, true);
			
			FakeClientCommandEx(client, "voicemenu 2 1");
		}
		
		g_hPlayerVehicleSequenceTimer[client] = CreateTimer(0.7, Timer_PlayerEnteredArwing, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_flPlayerVehicleBlockVoiceTime[client] = GetGameTime() + 0.33;
	
	TF2_RemovePlayerDisguise(client);
	
	// Remove default TF2 hud elements.
	int iHideHud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	iHideHud |= HIDEHUD_HEALTH;
	iHideHud |= HIDEHUD_WEAPONSELECTION;
	iHideHud |= HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", iHideHud);
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	
	SetArrayCell(g_hArwings, iIndex, GetClientTeam(client), Arwing_Team);
	
	Phys_Wake(iArwing);
	
	if (bImmediate) OnClientEnterArwingPost(client, iArwing);
	
	return true;
}

public void OnClientEnterArwingPost(int client, int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	g_hPlayerVehicleSequenceTimer[client] = INVALID_HANDLE;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InPilotSequence);
	
	// Remove fake model.
	int iFakeModel = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_FakePilotModel));
	if (iFakeModel && iFakeModel != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(client, "ClearParent");
		DeleteEntity(iFakeModel, 0.75);
	}
	
	// Place the player in our offset position.
	float flPos[3], flArwingPos[3], flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	int iFlags = GetEntProp(client, Prop_Send, "m_fEffects");
	if (iFlags & 1) iFlags &= ~1;
	if (iFlags & 512) iFlags &= ~512;
	SetEntProp(client, Prop_Send, "m_fEffects", iFlags);
	
	SetVariantString("!activator");
	AcceptEntityInput(client, "SetParent", iArwing);
	
	KvRewind(hConfig);
	KvGetVector(hConfig, "pilot_player_pos_offset", flPos);
	TeleportEntity(client, flPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	TF2_RegeneratePlayer(client);
	ClientRemoveAllWearables(client);
	
	// Let's turn this baby on!
	EnableArwing(iArwing);
}

public void OnClientExitArwing(int client, int iArwing, bool bImmediate)
{
	if (!IsValidClient(client)) return;
	
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	// Remove all my hud elements.
	int iHudElement;
	Handle hArray = CloneArray(g_hHudElements);
	for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		iHudElement = EntRefToEntIndex(GetArrayCell(hArray, i));
		if (!iHudElement || iHudElement == INVALID_ENT_REFERENCE) continue;
		
		if (EntRefToEntIndex(GetArrayCell(hArray, i, HudElement_Owner)) != iArwing) continue;
		
		AcceptEntityInput(iHudElement, "Kill");
	}
	
	CloseHandle(hArray);
	
	int iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (iCamera && iCamera != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iCamera, "Disable");
		DeleteEntity(iCamera, 0.1);
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_CameraEnt);
	
	int iFakeModel = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_FakePilotModel));
	if (iFakeModel && iFakeModel != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(client, "ClearParent");
		DeleteEntity(iFakeModel, 0.75); // we add a 0.75 delay to keep hats from glitching out
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_FakePilotModel);
	
	AcceptEntityInput(client, "ClearParent");
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	int iHideHud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	iHideHud &= ~HIDEHUD_HEALTH;
	iHideHud &= ~HIDEHUD_WEAPONSELECTION;
	iHideHud &= ~HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", iHideHud);
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	// Turn this off.
	DisableArwing(iArwing);
	
	for (int i = 0; i <= 5; i++)
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_NORMAL);
			SetEntityRenderColor(iWeapon, 255, 255, 255, 255);
		}
	}
	
	TF2_RegeneratePlayer(client);
	
	ClientSetFOV(client, RoundFloat(g_flPlayerDesiredFOV[client]));
}

public void Hook_ArwingVPhysicsUpdate(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	float flAng[3], flPos[3], flVelocity[3], flAngVelocity[3];
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flAng);
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flPos);
	GetEntitySmoothedVelocity(iArwing, flVelocity);
	GetEntPropVector(iArwing, Prop_Data, "m_vecAngVelocity", flAngVelocity);
	
	bool bEnabled = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled));
	
	float flForwardMove = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ForwardMove));
	float flSideMove = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SideMove));
	
	float flPitchRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_PitchRate));
	float flYawRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_YawRate));
	float flRollRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_RollRate));
	
	bool bInBarrelRoll = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll));
	bool bInSomersault = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault));
	bool bInTilt = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InTilt));
	bool bDestroyed = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed));
	
	bool bInUTurn = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn));
	int iUTurnPhase = GetArrayCell(g_hArwings, iIndex, Arwing_UTurnPhase);
	
	if (bInBarrelRoll)
	{
		int iRotateEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotateEnt));
		if (iRotateEnt && iRotateEnt != INVALID_ENT_REFERENCE)
		{
			float flRotateAng[3];
			GetEntPropVector(iRotateEnt, Prop_Data, "m_angRotation", flRotateAng); // get angles relative to parent
			
			bool bRotate = false;
			
			int iRollNum = GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollNum);
			
			float flTargetRoll = -360.0 * view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDirection));
			if (flTargetRoll > 0.0)
			{
				if (flRotateAng[2] < flTargetRoll * iRollNum)
				{
					bRotate = true;
				}
			}
			else
			{
				if (flRotateAng[2] > flTargetRoll * iRollNum)
				{
					bRotate = true;
				}
			}
			
			float flDuration = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDuration));
			float flStartTime = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LastBarrelRollTime));
			float flEndTime = flStartTime + flDuration;
			
			if (GetGameTime() >= flEndTime) bRotate = false;
			
			if (bRotate)
			{
				float flX = (GetGameTime() - flStartTime) / flDuration;
				float flFinalAngVelocity[3];
				flFinalAngVelocity[2] = (2.0 * flTargetRoll * float(iRollNum) * (1.0 - flX)) / flDuration;
				SetEntPropVector(iRotateEnt, Prop_Data, "m_vecAngVelocity", flFinalAngVelocity);
			}
			else
			{
				float flFinalAng[3];
				flFinalAng[2] = flTargetRoll * float(iRollNum);
				SetEntPropVector(iRotateEnt, Prop_Data, "m_vecAngVelocity", view_as<float>({ 0.0, 0.0, 0.0 }));
				SetEntPropVector(iRotateEnt, Prop_Data, "m_angRotation", flFinalAng);
			}
		}
	}
	
	if (bEnabled)
	{
		bool bApplyVelocity = true;
		bool bApplyAngVelocity = true;
		
		// Calculate the goal angular velocity we should be in.
		// Calculate the move angular velocity, first as local to object in terms of angles.
		float flMoveAngVelocity[3];
		float flMoveGoalAng[3];
		
		if (flForwardMove != 0.0)
		{
			if (flForwardMove > 0.0) flMoveGoalAng[0] = 50.0;
			else flMoveGoalAng[0] = -50.0;
		}
		else
		{
			flMoveGoalAng[0] = 0.0;
		}
		
		float flTiltDirection = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_TiltDirection));
		float flTiltTurnRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_TiltTurnRate));
		
		if (flSideMove != 0.0) 
		{
			if (flSideMove > 0.0) 
			{
				if (bInTilt && flTiltDirection < 0.0)
				{
					flMoveAngVelocity[2] = -flTiltTurnRate * FloatAbs(flSideMove) * flYawRate;
				}
				else
				{
					flMoveAngVelocity[2] = -90.0 * FloatAbs(flSideMove) * flYawRate;
				}
				
				flMoveGoalAng[2] = 45.0 * FloatAbs(flSideMove);
			}
			else 
			{
				if (bInTilt && flTiltDirection > 0.0)
				{
					flMoveAngVelocity[2] = flTiltTurnRate * FloatAbs(flSideMove) * flYawRate;
				}
				else
				{
					flMoveAngVelocity[2] = 90.0 * FloatAbs(flSideMove) * flYawRate;
				}
				
				flMoveGoalAng[2] = -45.0 * FloatAbs(flSideMove);
			}
		}
		else
		{
			flMoveAngVelocity[2] = 0.0;
			flMoveGoalAng[2] = 0.0;
		}
		
		if (bInTilt)
		{
			flMoveGoalAng[2] = AngleNormalize(-1.0 * view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_TiltDegrees)) * view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_TiltDirection)));
		}
		
		if (bInUTurn)
		{
			
		}
		
		if (bInSomersault)
		{
			flMoveAngVelocity[1] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultAngleFactor));
			flMoveAngVelocity[2] = 0.0;
			flMoveAngVelocity[0] = 0.0;
		}
		else if (bInUTurn)
		{
			if (iUTurnPhase == 1)
			{
				flMoveAngVelocity[1] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultAngleFactor));
				flMoveAngVelocity[0] = 0.0;
			}
			else if (iUTurnPhase == 2)
			{
				flMoveAngVelocity[1] = -flAng[0] * flPitchRate * 6.0;
				flMoveAngVelocity[0] = -flAng[2] * flRollRate * 6.0;
			}
			
			flMoveAngVelocity[2] = 0.0;
		}
		else
		{
			float flRollRadians = DegToRad(flAng[2]);
		
			flMoveAngVelocity[1] = (flMoveGoalAng[0] - flAng[0]) * flPitchRate;
			flMoveAngVelocity[0] = (flMoveGoalAng[2] - flAng[2]) * flRollRate;
			
			// Adjust and rotate angular velocity to compensate for roll.
			float flOldMoveAngVelocity[3];
			CopyVectors(flMoveAngVelocity, flOldMoveAngVelocity);
			
			flMoveAngVelocity[2] = (flOldMoveAngVelocity[2] * Cosine(flRollRadians)) - (flOldMoveAngVelocity[1] * Sine(flRollRadians));
			flMoveAngVelocity[1] = (flOldMoveAngVelocity[2] * Sine(flRollRadians)) + (flOldMoveAngVelocity[1] * Cosine(flRollRadians));
		}
		
		// Are we in a damage sequence? Factor that in!
		if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InDamageSequence)))
		{
			float flLastDamageSequenceTime = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LastDamageSequenceTime));
			float flLastDamageSequenceUpdateTime = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LastDamageSequenceUpdateTime));
			float flCurTime = GetGameTime();
			
			if (flLastDamageSequenceUpdateTime > 0.0)
			{
				float flLastScale = (150.0 * (1.0 - ((flLastDamageSequenceUpdateTime - flLastDamageSequenceTime) / 4.0))) * Sine(flLastDamageSequenceUpdateTime * 20.0);
				flMoveAngVelocity[0] += flLastScale;
			}
			
			float flScale = (150.0 * (1.0 - ((flCurTime - flLastDamageSequenceTime) / 4.0))) * Sine(flCurTime * 20.0);
			flMoveAngVelocity[0] += flScale;
			
			SetArrayCell(g_hArwings, iIndex, flCurTime, Arwing_LastDamageSequenceUpdateTime);
		}
		
		// Calculate the goal velocity we should be in.
		float flMoveGoalVelocity[3];
		
		GetAngleVectors(flAng, flMoveGoalVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(flMoveGoalVelocity, flMoveGoalVelocity);
		
		if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)))
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BoostSpeed)));
		}
		else if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)))
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BrakeSpeed)));
		}
		else if (bInSomersault)
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultSpeed)));
		}
		else if (bInUTurn && iUTurnPhase == 1)
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultSpeed)));
		}
		else if (bInUTurn && iUTurnPhase == 2)
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnBoostSpeed)));
		}
		else
		{
			ScaleVector(flMoveGoalVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_MaxSpeed)));
		}
		
		float flMoveVelocity[3];
		float flAccelFactor = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_AccelFactor));
		
		// Calculate the move velocity, user input only.
		flMoveVelocity[0] = flVelocity[0] + (flMoveGoalVelocity[0] - flVelocity[0]) * flAccelFactor;
		flMoveVelocity[1] = flVelocity[1] + (flMoveGoalVelocity[1] - flVelocity[1]) * flAccelFactor;
		flMoveVelocity[2] = flVelocity[2] + (flMoveGoalVelocity[2] - flVelocity[2]) * flAccelFactor;
		
		// And now... WE FLY!
		Phys_SetVelocity(iArwing, bApplyVelocity ? flMoveVelocity : NULL_VECTOR, bApplyAngVelocity ? flMoveAngVelocity : NULL_VECTOR, true);
		
		/*
		// Barrel roll stuff.
		if (bInBarrelRoll)
		{
			int iEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
			if (iEnt && iEnt != INVALID_ENT_REFERENCE)
			{
				float flTargetAng[3]; // Get angles local to parent.
				GetEntPropVector(iEnt, Prop_Data, "m_angRotation", flTargetAng);
				flTargetAng[2] -= 20.0 * view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDirection));
				flTargetAng[2] = AngleNormalize(flTargetAng[2]);
				TeleportEntity(iEnt, NULL_VECTOR, flTargetAng, NULL_VECTOR);
			}
		}
		*/
		
		// Sound stuff.
		Handle hConfig = GetConfigOfArwing(iArwing);
		if (hConfig != INVALID_HANDLE)
		{
			float flArwingVelocity[3];
			GetEntitySmoothedVelocity(iArwing, flArwingVelocity);
			float flSpeed = GetVectorLength(flArwingVelocity);
			float flMaxSpeed = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_MaxSpeed));
			
			char sPath[PLATFORM_MAX_PATH];
			if (GetRandomStringFromArwingConfig(hConfig, "sound_flyloop", sPath, sizeof(sPath), 1) && sPath[0])
			{
				int iPitch = RoundFloat(100.0 * (flSpeed / flMaxSpeed));
				if (iPitch < 25) iPitch = 25;
				else if (iPitch > 200) iPitch = 200;
				
				EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER, SND_CHANGEPITCH, 0.33, iPitch);
			}
		}
	}
	
	// Camera stuff.
	int iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (iCamera && iCamera != INVALID_ENT_REFERENCE)
	{
		float flCameraAng[3], flCameraPos[3], flCameraVelocity[3], flCameraAngVelocity[3];
		GetEntPropVector(iCamera, Prop_Data, "m_angAbsRotation", flCameraAng);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAbsOrigin", flCameraPos);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAbsVelocity", flCameraVelocity);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAngVelocity", flCameraAngVelocity);
		
		float flCameraPitchRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_CameraPitchRate));
		float flCameraYawRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_CameraYawRate));
		float flCameraRollRate = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_CameraRollRate)); 
		float flAngAccelFactor = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_CameraAngAccelFactor));
		
		Handle hConfig = GetConfigOfArwing(iArwing);
		KvRewind(hConfig);
		
		float flCameraMoveGoalAng[3];
		float flCameraMoveAngVelocity[3];
		float flCameraMoveGoalVelocity[3], flCameraMoveGoalPos[3];
		
		// Calculate goal angular velocity.
		if (bInSomersault)
		{
			float flCameraAngSomersault[3];
			KvGetVector(hConfig, "camera_somersault_ang_offset", flCameraAngSomersault);
			
			SubtractVectors(flPos, flCameraPos, flCameraMoveGoalAng);
			GetVectorAngles(flCameraMoveGoalAng, flCameraMoveGoalAng);
			AddVectors(flCameraMoveGoalAng, flCameraAngSomersault, flCameraMoveGoalAng);
		}
		else if (bInUTurn)
		{
			float flCameraAngUTurn[3];
			
			if (iUTurnPhase == 1)
			{
				KvGetVector(hConfig, "camera_uturn_somersault_ang_offset", flCameraAngUTurn);
			}
			else if (iUTurnPhase == 2)
			{
				KvGetVector(hConfig, "camera_uturn_boost_ang_offset", flCameraAngUTurn);
			}
			
			SubtractVectors(flPos, flCameraPos, flCameraMoveGoalAng);
			GetVectorAngles(flCameraMoveGoalAng, flCameraMoveGoalAng);
			AddVectors(flCameraMoveGoalAng, flCameraAngUTurn, flCameraMoveGoalAng);
		}
		else if (bDestroyed)
		{
			SubtractVectors(flPos, flCameraPos, flCameraMoveGoalAng);
			GetVectorAngles(flCameraMoveGoalAng, flCameraMoveGoalAng);
		}
		else
		{
			if (bEnabled && flForwardMove != 0.0) 
			{
				float flCameraAngUpOrDown[3];
				
				if (flForwardMove > 0.0) 
				{
					KvGetVector(hConfig, "camera_down_ang_offset", flCameraAngUpOrDown);
				}
				else
				{
					KvGetVector(hConfig, "camera_up_ang_offset", flCameraAngUpOrDown);
				}
				
				flCameraMoveGoalAng[0] = flCameraAngUpOrDown[0] * FloatAbs(flForwardMove);
			}
			else
			{
				flCameraMoveGoalAng[0] = 0.0;
			}
			
			if (bEnabled && flSideMove != 0.0)
			{
				float flCameraAngLeftOrRight[3];
				
				if (flSideMove > 0.0)
				{
					KvGetVector(hConfig, "camera_turn_right_ang_offset", flCameraAngLeftOrRight);
				}
				else
				{
					KvGetVector(hConfig, "camera_turn_left_ang_offset", flCameraAngLeftOrRight);
				}
				
				for (int i = 0; i < 2; i++) flCameraMoveGoalAng[i] = AngleNormalize(flAng[i] + (flCameraAngLeftOrRight[i] * FloatAbs(flSideMove)));
				flCameraMoveGoalAng[2] = (flCameraAngLeftOrRight[2] * FloatAbs(flSideMove));
			}
			else
			{
				float flCameraAngDefault[3];
				KvGetVector(hConfig, "camera_default_ang_offset", flCameraAngDefault);
				
				for (int i = 0; i < 2; i++) flCameraMoveGoalAng[i] = AngleNormalize(flAng[i] + flCameraAngDefault[i]);
				flCameraMoveGoalAng[2] = flCameraAngDefault[2];
			}
		}
		
		// Calculate angular velocity.
		flCameraMoveAngVelocity[2] = AngleDiff(flCameraAng[2], flCameraMoveGoalAng[2]) * flCameraRollRate;
		flCameraMoveAngVelocity[0] = AngleDiff(flCameraAng[0], flCameraMoveGoalAng[0]) * flCameraPitchRate;
		flCameraMoveAngVelocity[1] = AngleDiff(flCameraAng[1], flCameraMoveGoalAng[1]) * flCameraYawRate;
		
		// Smooth it out.
		if (flSideMove != 0.0) flCameraMoveAngVelocity[1] = flCameraAngVelocity[1] + (flCameraMoveAngVelocity[1] - flCameraAngVelocity[1]) * flAngAccelFactor;
		if (flForwardMove != 0.0) flCameraMoveAngVelocity[0] = flCameraAngVelocity[0] + (flCameraMoveAngVelocity[0] - flCameraAngVelocity[0]) * flAngAccelFactor;
		
		// Calculate goal velocity.
		
		if (bInSomersault)
		{
			float flCameraPosSomersault[3], flTempAng[3];
			KvGetVector(hConfig, "camera_somersault_pos_offset", flCameraPosSomersault);
			CopyVectors(flAng, flTempAng);
			flTempAng[0] = 0.0;
			flTempAng[1] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultYawAngle));
			flTempAng[2] = 0.0;
			VectorTransform(flCameraPosSomersault, flPos, flTempAng, flCameraPosSomersault);
			
			CopyVectors(flCameraPosSomersault, flCameraMoveGoalPos);
		}
		else if (bInUTurn)
		{
			float flCameraPosUTurn[3], flTempAng[3];
			
			if (iUTurnPhase == 1)
			{
				KvGetVector(hConfig, "camera_uturn_somersault_pos_offset", flCameraPosUTurn);
			}
			else if (iUTurnPhase == 2)
			{
				KvGetVector(hConfig, "camera_uturn_boost_pos_offset", flCameraPosUTurn);
			}
			
			CopyVectors(flAng, flTempAng);
			flTempAng[0] = 0.0;
			flTempAng[1] = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnYawAngle));
			flTempAng[2] = 0.0;
			VectorTransform(flCameraPosUTurn, flPos, flTempAng, flCameraPosUTurn);
			
			CopyVectors(flCameraPosUTurn, flCameraMoveGoalPos);
		}
		else if (bDestroyed)
		{
			CopyVectors(flCameraPos, flCameraMoveGoalPos);
		}
		else
		{
			float flCameraPosDefault[3], flCameraPosTurnLeft[3], flCameraPosTurnRight[3];
			KvGetVector(hConfig, "camera_default_pos_offset", flCameraPosDefault);
			VectorTransform(flCameraPosDefault, flPos, flAng, flCameraPosDefault);
			KvGetVector(hConfig, "camera_turn_left_pos_offset", flCameraPosTurnLeft);
			VectorTransform(flCameraPosTurnLeft, flPos, flAng, flCameraPosTurnLeft);
			KvGetVector(hConfig, "camera_turn_right_pos_offset", flCameraPosTurnRight);
			VectorTransform(flCameraPosTurnRight, flPos, flAng, flCameraPosTurnRight);
			
			if (bEnabled)
			{
				if (flSideMove > 0.0) CopyVectors(flCameraPosTurnRight, flCameraMoveGoalPos);
				else if (flSideMove < 0.0) CopyVectors(flCameraPosTurnLeft, flCameraMoveGoalPos);
				else CopyVectors(flCameraPosDefault, flCameraMoveGoalPos);
			}
			else
			{
				CopyVectors(flCameraPosDefault, flCameraMoveGoalPos);
			}
		}
		
		SubtractVectors(flCameraMoveGoalPos, flCameraPos, flCameraMoveGoalVelocity);
		NormalizeVector(flCameraMoveGoalVelocity, flCameraMoveGoalVelocity);
		ScaleVector(flCameraMoveGoalVelocity, GetVectorDistance(flCameraPos, flCameraMoveGoalPos) * 5.0);
		
		// Calculate real velocity.
		float flCameraMoveVelocity[3];
		
		if (bInSomersault)
		{
			LerpVectors(flCameraVelocity, flCameraMoveGoalVelocity, flCameraMoveVelocity, 0.75);
		}
		else
		{
			LerpVectors(flCameraVelocity, flCameraMoveGoalVelocity, flCameraMoveVelocity, 0.425);
		}
		
		TeleportEntity(iCamera, NULL_VECTOR, NULL_VECTOR, flCameraMoveVelocity);
		SetEntPropVector(iCamera, Prop_Data, "m_vecAngVelocity", flCameraMoveAngVelocity);
	}
}

public void Hook_ArwingOnTakeDamagePost(int iArwing, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3])
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	DamageArwing(iArwing, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition);
}

public Action Timer_ArwingRechargeEnergy(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_EnergyRechargeTimer) != timer)) return Plugin_Stop;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)))
	{
		return Plugin_Continue;
	}
	
	int iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	int iMaxEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy);
	
	if (iEnergy < iMaxEnergy)
	{
		ArwingSetEnergy(iArwing, iEnergy + 1);
	}
	
	return Plugin_Continue;
}

public Action Timer_PlayerEnteredArwing(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0) return;
	
	if (timer != g_hPlayerVehicleSequenceTimer[client]) return;
	
	// Did the Arwing magically disappear before the enter sequence is finished?
	int arwing = GetArwing(client);
	if (arwing != -1) OnClientEnterArwingPost(client, arwing);
}

void DestroyArwing(int iArwing, int iAttacker, int iInflictor)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))) return;
	
	DebugMessage("DestroyArwing START (%d)", iArwing);
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_Destroyed);
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.5, Arwing_ObliterateTime);
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
	EjectPilotFromArwing(iArwing);
	DisableArwing(iArwing);
	
	if (iPilot && iPilot != INVALID_ENT_REFERENCE)
	{
		SDKHooks_TakeDamage(iPilot, iInflictor, iAttacker, 9001.0, DMG_ACID);
	}
	
	SetEntityRenderMode(iArwing, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iArwing, 0, 0, 0, 255);
	
	SetVariantFloat(100.0);
	AcceptEntityInput(iArwing, "physdamagescale");
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		char sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_destroyed", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingDestroyed, true);
	
	CreateTimer(5.0, Timer_ObliterateArwing, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	
	DebugMessage("DestroyArwing END (%d)", iArwing);
}

public Action Timer_ObliterateArwing(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ObliterateArwing(iArwing);
}

void ObliterateArwing(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))) return;
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated))) return;
	
	if (GetGameTime() < view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ObliterateTime))) return;
	
	DebugMessage("ObliterateArwing START (%d)", iArwing);
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_Obliterated);
	
	Phys_EnableCollisions(iArwing, false);
	Phys_EnableMotion(iArwing, false);
	
	SetEntityRenderMode(iArwing, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iArwing, 0, 0, 0, 1);
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		char sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_obliterated", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingObliterated, true);
	DeleteEntity(iArwing, 5.0);
	
	DebugMessage("ObliterateArwing END (%d)", iArwing);
}

public void DamageArwing(int iArwing, int iAttacker, int iInflictor, float flDamage, int iDamageType, int iWeapon, const float flDamageForce[3], const float flDamagePosition[3])
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated)))
	{
		return;
	}
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)))
	{
		ObliterateArwing(iArwing);
		return;
	}
	
	if ((iDamageType & DMG_BULLET) || (iDamageType & 0x80)) return; // No damage from bullets.
	
	if (!g_bFriendlyFire && iAttacker && IsValidEntity(iAttacker) && GetEntProp(iAttacker, Prop_Data, "m_iTeamNum") == GetArrayCell(g_hArwings, iIndex, Arwing_Team)) return;
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (IsValidEntity(iPilot) && iPilot == iAttacker) return; // No self damage.
	
	int iHealth = GetArrayCell(g_hArwings, iIndex, Arwing_Health);
	iHealth -= RoundToFloor(flDamage);
	ArwingSetHealth(iArwing, iHealth);
	
	bool bFromCollision = view_as<bool>(iDamageType & DMG_CRUSH);
	
	if (iHealth <= 0) 
	{
		DestroyArwing(iArwing, iAttacker, iInflictor);
		if (bFromCollision) ObliterateArwing(iArwing);
	}
	else 
	{
		ArwingStartDamageSequence(iArwing, bFromCollision);
		
		if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled) && bFromCollision))
		{
			float flForceVector[3];
			NormalizeVector(flDamageForce, flForceVector);
			ScaleVector(flForceVector, 3.0);
			
			Phys_SetVelocity(iArwing, flDamageForce, NULL_VECTOR, true);
		}
	}
}

void ArwingStartDamageSequence(int iArwing, bool bFromWorld)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InDamageSequence);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastDamageSequenceTime);
	SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_LastDamageSequenceUpdateTime);
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_DamageSequenceRedBlink);
	
	Handle hTimer = CreateTimer(0.5, Timer_ArwingStopDamageSequence, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_DamageSequenceTimer);
	
	hTimer = CreateTimer(0.025, Timer_ArwingDamageSequenceRedBlink, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_DamageSequenceRedBlinkTimer);
	TriggerTimer(hTimer, true);
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		char sPath[PLATFORM_MAX_PATH];
		if (bFromWorld && GetRandomStringFromArwingConfig(hConfig, "sound_damaged_world", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
		else if (!bFromWorld && GetRandomStringFromArwingConfig(hConfig, "sound_damaged", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingDamaged, true);
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (IsValidClient(iPilot) && !IsFakeClient(iPilot))
	{
		int iFade = CreateEntityByName("env_fade");
		SetEntPropFloat(iFade, Prop_Data, "m_Duration", 0.66);
		SetEntPropFloat(iFade, Prop_Data, "m_HoldTime", 0.0);
		SetEntProp(iFade, Prop_Data, "m_spawnflags", 5);
		SetEntityRenderColor(iFade, 255, 0, 0, 100);
		DispatchSpawn(iFade);
		AcceptEntityInput(iFade, "Fade", iPilot);
		DeleteEntity(iFade);
	}
}

public Action Timer_ArwingDamageSequenceRedBlink(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceRedBlinkTimer))) return Plugin_Stop;
	
	ArwingDamageSequenceDoRedBlink(iArwing);
	
	return Plugin_Continue;
}

void ArwingDamageSequenceDoRedBlink(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))) return;
	
	int iColorEnt = iArwing;
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll)))
	{
		int iBarrelRollEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
		if (iBarrelRollEnt && iBarrelRollEnt != INVALID_ENT_REFERENCE)
		{
			iColorEnt = iBarrelRollEnt;
		}
	}
	
	int iPattern = GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceRedBlink);
	if (iPattern == 1)
	{
		SetEntityRenderColor(iColorEnt, 255, 0, 0, 255);
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_DamageSequenceRedBlink);
	}
	else if (iPattern == 0)
	{
		SetEntityRenderColor(iColorEnt, 255, 255, 255, 255);
		SetArrayCell(g_hArwings, iIndex, 1, Arwing_DamageSequenceRedBlink);
	}
}

void ArwingStopDamageSequence(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InDamageSequence))) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InDamageSequence);
	SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_LastDamageSequenceUpdateTime);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_DamageSequenceTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_DamageSequenceRedBlinkTimer);
	
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_DamageSequenceRedBlink);
	ArwingDamageSequenceDoRedBlink(iArwing);
}

public Action Timer_ArwingStopDamageSequence(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceTimer))) return;
	
	ArwingStopDamageSequence(iArwing);
}

void ArwingOnSleep(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) ||
		view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InPilotSequence)))
	{
		Phys_Wake(iArwing);
	}
}

void ArwingSpawnEffects(int iArwing, EffectEvent iEvent, bool bStartOn=false, bool bOverridePos=false, const float flOverridePos[3]=NULL_VECTOR, const float flOverrideAng[3]=NULL_VECTOR)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "effects") || !KvGotoFirstSubKey(hConfig)) return;
	
	Handle hArray = CreateArray(64);
	char sSectionName[64];
	char sType[512];
	
	do
	{
		KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
		PushArrayString(hArray, sSectionName);
	}
	while (KvGotoNextKey(hConfig));
	
	if (GetArraySize(hArray) == 0) 
	{
		CloseHandle(hArray);
		return;
	}
	
	char sEffectName[64];
	GetEffectEventName(iEvent, sEffectName, sizeof(sEffectName));
	
	int iEffect, iEffectIndex, iColor[4];
	EffectType iEffectType;
	float flLifeTime;
	//char sValue[PLATFORM_MAX_PATH];
	
	for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		GetArrayString(hArray, i, sSectionName, sizeof(sSectionName));
		KvRewind(hConfig);
		KvJumpToKey(hConfig, "effects");
		KvJumpToKey(hConfig, sSectionName);
		
		KvGetString(hConfig, "type", sType, sizeof(sType));
		iEffectType = GetEffectTypeFromName(sType);
		if (iEffectType == EffectType_Invalid) continue; // effect is not supported.
		
		KvGetString(hConfig, "event", sType, sizeof(sType));
		if (StrContains(sType, sEffectName) == -1) continue; // effect is not for our event.
		
		flLifeTime = KvGetFloat(hConfig, "lifetime");
		
		bool bCheckTeam = view_as<bool>(KvGetNum(hConfig, "color_team"));
		
		iEffect = CreateEffect(iEffectType, iEvent, iArwing, i, bCheckTeam, iEffectIndex);
		if (iEffect != -1)
		{
			// Parse through keyvalues, if specified.
			if (KvJumpToKey(hConfig, "keyvalues"))
			{
				char sWholeThing[512];
				char sKeyValues[2][512];
				
				for (int i2 = 1;;i2++)
				{
					char sIndex[16];
					IntToString(i2, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sWholeThing, sizeof(sWholeThing));
					if (!sWholeThing[0]) break; // ran out of key values. stop.
					
					int iCount = ExplodeString(sWholeThing, ";", sKeyValues, 2, 512);
					if (iCount < 2) 
					{
						continue; // not a valid key value; warn about it and just continue on.
					}
					
					DispatchKeyValue(iEffect, sKeyValues[0], sKeyValues[1]);
				}
				
				KvGoBack(hConfig);
			}
			
			// Apply colors.
			if (iEffectType != EffectType_ParticleSystem)
			{
				if (!bCheckTeam)
				{
					switch (iEffectType)
					{
						case EffectType_Smoketrail:
						{
							int iColor2[4];
							KvGetColor(hConfig, "color_start", iColor[0], iColor[1], iColor[2], iColor[3]);
							KvGetColor(hConfig, "color_end", iColor2[0], iColor2[1], iColor2[2], iColor2[3]);
							
							EffectSetColor(iEffect, iColor[0], iColor[1], iColor[2], iColor[3], iColor2[0], iColor2[1], iColor2[2]);
						}
						default: 
						{
							KvGetColor(hConfig, "color", iColor[0], iColor[1], iColor[2], iColor[3]);
							EffectSetColor(iEffect, iColor[0], iColor[1], iColor[2], iColor[3]);
						}
					}
				}
				else
				{
					ArwingEffectSetTeamColor(iArwing, iEffectIndex);
				}
			}
			
			DispatchSpawn(iEffect);
			ActivateEntity(iEffect);
			ArwingParentMyEffectToSelf(iArwing, iEffectIndex, bOverridePos, flOverridePos, flOverrideAng);
			
			if (bStartOn) TurnOnEffect(iEffect);
			
			if (flLifeTime > 0.0)
			{
				SetArrayCell(g_hEffects, iEffectIndex, true, Effect_InKill);
				CreateTimer(flLifeTime, Timer_EffectRemove, EntIndexToEntRef(iEffect), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	CloseHandle(hArray);
}

void ArwingParentMyEffectToSelf(int iArwing, int iEffectIndex, bool bOverridePos=false, const float flOverridePos[3]=NULL_VECTOR, const float flOverrideAng[3]=NULL_VECTOR)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	int iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex));
	
	// Get the appropriate offset positions we should use for the effect.
	float flPos[3], flAng[3];
	if (bOverridePos)
	{
		CopyVectors(flOverridePos, flPos);
		CopyVectors(flOverrideAng, flAng);
	}
	else
	{
		Handle hConfig = GetConfigOfArwing(iArwing);
		if (hConfig == INVALID_HANDLE) return;
		
		KvRewind(hConfig);
		if (!KvJumpToKey(hConfig, "effects") || !KvGotoFirstSubKey(hConfig)) return;
	
		bool bFoundEffect = false;
	
		int iCustomIndex = GetArrayCell(g_hEffects, iEffectIndex, Effect_CustomIndex);
		int iIndexCount;
		do
		{
			if (iIndexCount == iCustomIndex)
			{
				bFoundEffect = true;
				KvGetVector(hConfig, "origin", flPos);
				KvGetVector(hConfig, "angles", flAng);
				break;
			}
			
			iIndexCount++;
		}
		while (KvGotoNextKey(hConfig));
		
		if (!bFoundEffect) return; // effect doesn't exist in our config; do nothing.
	}
	
	// Determine the proper entity we should parent to.
	int iParentEnt = iArwing;
	int iBarrelRollEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
	if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll)) && iBarrelRollEnt && iBarrelRollEnt != INVALID_ENT_REFERENCE)
	{
		iParentEnt = iBarrelRollEnt;
	}
	
	float flParentPos[3], flParentAng[3];
	GetEntPropVector(iParentEnt, Prop_Data, "m_vecAbsOrigin", flParentPos);
	GetEntPropVector(iParentEnt, Prop_Data, "m_angAbsRotation", flParentAng);
	
	// Parent by offset.
	SetVariantString("!activator");
	AcceptEntityInput(iEffect, "SetParent", iParentEnt);
	TeleportEntity(iEffect, flPos, flAng, view_as<float>({ 0.0, 0.0, 0.0 }));
}

void ArwingSetTeamColorOfEffects(int iArwing)
{
	int iEffect, iEffectOwner;
	for (int i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (!iEffectOwner || iEffectOwner == INVALID_ENT_REFERENCE || iEffectOwner != iArwing) return;
		
		if (!view_as<bool>(GetArrayCell(g_hEffects, i, Effect_ShouldCheckTeam))) continue;
		
		ArwingEffectSetTeamColor(iArwing, i);
	}
}

void ArwingEffectSetTeamColor(int iArwing, int iEffectIndex)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex));
	if (!iEffect || iEffect == INVALID_ENT_REFERENCE) return;
	
	int iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	EffectType iType = GetArrayCell(g_hEffects, iEffectIndex, Effect_Type);
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "effects") && KvGotoFirstSubKey(hConfig))
		{
			int iColor[4], iColor2[4];
			int iCustomIndex = GetArrayCell(g_hEffects, iEffectIndex, Effect_CustomIndex);
			int iIndexCount;
			
			do
			{
				if (iIndexCount == iCustomIndex)
				{
					switch (iType)
					{
						case EffectType_Sprite, EffectType_Smokestack, EffectType_Trail:
						{
							switch (iTeam)
							{
								case TFTeam_Red: KvGetColor(hConfig, "color_team_red", iColor[0], iColor[1], iColor[2], iColor[3]);
								default: KvGetColor(hConfig, "color_team_blue", iColor[0], iColor[1], iColor[2], iColor[3]);
							}
							
							EffectSetColor(iEffect, iColor[0], iColor[1], iColor[2], iColor[3]);
						}
						case EffectType_Smoketrail:
						{
							switch (iTeam)
							{
								case TFTeam_Red: 
								{
									KvGetColor(hConfig, "color_team_red_start", iColor[0], iColor[1], iColor[2], iColor[3]);
									KvGetColor(hConfig, "color_team_red_end", iColor2[0], iColor2[1], iColor2[2], iColor2[3]);
								}
								default: 
								{
									KvGetColor(hConfig, "color_team_blue_start", iColor[0], iColor[1], iColor[2], iColor[3]);
									KvGetColor(hConfig, "color_team_blue_end", iColor2[0], iColor2[1], iColor2[2], iColor2[3]);
								}
							}
							
							EffectSetColor(iEffect, iColor[0], iColor[1], iColor[2], iColor[3], iColor2[0], iColor2[1], iColor2[2]);
						}
					}
					
					break;
				}
				
				iIndexCount++;
			}
			while (KvGotoNextKey(hConfig));
		}
	}
}

public bool TraceRayArwingTargeting(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(data));
	if (iIndex != -1)
	{
		int iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
		if (iTargetIndex == -1)
		{
			if (IsValidClient(entity))
			{
				return false;
			}
		}
		else
		{
			if (!g_bFriendlyFire && GetArrayCell(g_hArwings, iIndex, Arwing_Team) == GetArrayCell(g_hArwings, iTargetIndex, Arwing_Team))
			{
				return false;
			}
		}
	}
	
	return true;
}

public bool TraceRayArwingTargetsOnly(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
	if (iIndex == -1) return false;
	
	return true;
}

public bool TraceRayArwingTargetingNoWorld(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	if (entity == 0) return false;
	
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(data));
	if (iIndex != -1)
	{
		int iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
		if (iTargetIndex == -1)
		{
			return false;
		}
		else
		{
			if (!g_bFriendlyFire && GetArrayCell(g_hArwings, iIndex, Arwing_Team) == GetArrayCell(g_hArwings, iTargetIndex, Arwing_Team))
			{
				return false;
			}
		}
	}
	
	return true;
}