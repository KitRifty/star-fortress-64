#if defined _sf64_arwing_included
  #endinput
#endif
#define _sf64_arwing_included

#include "starfortress64/effects.sp"


#define ARWING_BARRELROLL_ROTATE_ENT_MODEL "models/Effects/teleporttrail.mdl"

new Handle:g_hArwingConfigs;

new Handle:g_hArwings;
new Handle:g_hArwingNames;


LoadAllArwingConfigs()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sFileName[PLATFORM_MAX_PATH], String:sName[64], FileType:iFiletype;
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/vehicles/arwing/");
	
	new Handle:hDirectory = OpenDirectory(sPath);
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

LoadArwingConfig(const String:sName[])
{
	RemoveArwingConfig(sName);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/starfortress64/vehicles/arwing/%s.cfg", sName);
	if (!FileExists(sPath))
	{
		LogError("Arwing vehicle config %s does not exist!", sName);
		return;
	}
	
	new Handle:hConfig = CreateKeyValues("root");
	if (!FileToKeyValues(hConfig, sPath))
	{
		CloseHandle(hConfig);
		LogError("Arwing vehicle config %s is invalid!", sName);
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
			else if (StrEqual(sSectionName, "mat_precache"))
			{
				for (new i = 1;; i++)
				{
					IntToString(i, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sValue, sizeof(sValue));
					if (!sValue[0]) break;
					
					PrecacheMaterial(sValue);
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
	
	SetTrieValue(g_hArwingConfigs, sName, hConfig);
}

RemoveArwingConfig(const String:sName[])
{
	new Handle:hConfig = INVALID_HANDLE;
	if (GetTrieValue(g_hArwingConfigs, sName, hConfig) && hConfig != INVALID_HANDLE)
	{
		CloseHandle(hConfig);
		SetTrieValue(g_hArwingConfigs, sName, INVALID_HANDLE);
	}
}

// Code originally from FF2. Credits to the original authors Rainbolt Dash and FlaminSarge.
stock bool:GetRandomStringFromArwingConfig(Handle:hConfig, const String:strKeyValue[], String:buffer[], bufferlen, index=-1)
{
	strcopy(buffer, bufferlen, "");
	
	if (hConfig == INVALID_HANDLE) return false;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, strKeyValue)) return false;
	
	decl String:s[32], String:s2[PLATFORM_MAX_PATH];
	
	new i = 1;
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

stock Handle:GetArwingConfig(const String:sName[])
{
	new Handle:hConfig = INVALID_HANDLE;
	GetTrieValue(g_hArwingConfigs, sName, hConfig);
	return hConfig;
}

stock Handle:GetConfigOfArwing(iArwing)
{
	if (!IsValidEntity(iArwing)) return INVALID_HANDLE;
	
	new entref = EntIndexToEntRef(iArwing);
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return INVALID_HANDLE;
	
	decl String:sEntRef[256];
	IntToString(entref, sEntRef, sizeof(sEntRef));
	
	new String:sName[64];
	GetTrieString(g_hArwingNames, sEntRef, sName, sizeof(sName));
	if (!sName[0]) return INVALID_HANDLE;
	
	return GetArwingConfig(sName);
}

stock SpawnArwing(const String:sName[], const Float:flPos[3], const Float:flAng[3], const Float:flVelocity[3], &iIndex=-1)
{
	new Handle:hConfig = GetArwingConfig(sName);
	if (hConfig == INVALID_HANDLE)
	{
		LogError("Could not spawn arwing %s because the config is invalid!", sName);
		return -1;
	}

	new iArwing = CreateEntityByName("prop_physics_override");
	if (iArwing != -1)
	{
		decl String:sBuffer[PLATFORM_MAX_PATH];
		KvRewind(hConfig);
		KvGetString(hConfig, "model", sBuffer, sizeof(sBuffer));
		SetEntityModel(iArwing, sBuffer);
		DispatchKeyValueFloat(iArwing, "modelscale", KvGetFloat(hConfig, "modelscale", 1.0));
		DispatchSpawn(iArwing);
		ActivateEntity(iArwing);
		Phys_SetMass(iArwing, KvGetFloat(hConfig, "mass", 100.0));
		DispatchKeyValueFloat(iArwing, "physdamagescale", KvGetFloat(hConfig, "physdamagescale", 1.0))
		
		DispatchKeyValue(iArwing, "classname", "sf64_vehicle_arwing");
		
		iIndex = PushArrayCell(g_hArwings, EntIndexToEntRef(iArwing));
		
		decl String:sEntRef[256];
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
		SetArrayCell(g_hArwings, iIndex, 0, Arwing_Buttons);
		SetArrayCell(g_hArwings, iIndex, false, Arwing_IgnorePilotControls);
		
		SetArrayCell(g_hArwings, iIndex, false, Arwing_Intro);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_IntroStartTime);
		SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_IntroEndTime);
		
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
				
				decl Float:flOffset[3];
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
			decl String:sType[64];
			decl String:sMaterial[PLATFORM_MAX_PATH];
			decl iReticle, iColor[4];
			decl Float:flOffsetPos[3];
			
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
							
							decl String:sValue[64];
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

EnableArwing(iArwing, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) return;
	if (!bForce && bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
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

ArwingSetHealth(iArwing, iAmount, bool:bCheckOldValue=true)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iOldAmount = GetArrayCell(g_hArwings, iIndex, Arwing_Health);
	if (bCheckOldValue && iAmount == iOldAmount) return;
	
	SetArrayCell(g_hArwings, iIndex, iAmount, Arwing_Health);
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	decl String:sPath[PLATFORM_MAX_PATH];
	
	new iMaxHealth = GetArrayCell(g_hArwings, iIndex, Arwing_MaxHealth);
	new Float:flOldHealthPercent = float(iOldAmount) / float(iMaxHealth);
	new Float:flHealthPercent = float(iAmount) / float(iMaxHealth);
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
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

ArwingSetEnergy(iArwing, iAmount, bool:bCheckOldValue=true)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iOldEnergyAmount = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (bCheckOldValue && iAmount == iOldEnergyAmount) return;
	
	SetArrayCell(g_hArwings, iIndex, iAmount, Arwing_Energy);
	
	new iMaxEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy);
	
	if ((!bCheckOldValue || iOldEnergyAmount < iMaxEnergy) && iAmount >= iMaxEnergy)
	{
		if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))
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

DisableArwing(iArwing, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bForce && !bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
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
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		decl String:sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_flyloop", sPath, sizeof(sPath), 1) && sPath[0])
		{
			StopSound(iArwing, SNDCHAN_STATIC, sPath);
		}
	}
}

InsertPilotIntoArwing(iArwing, iPilot, bool:bImmediate=false)
{
	if (!IsValidEntity(iPilot)) return;

	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) return;
	
	DebugMessage("InsertPilotIntoArwing START (%d, %d)", iArwing, iPilot);
	
	new iMyPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
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

EjectPilotFromArwing(iArwing, bool:bImmediate=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (!iPilot || iPilot == INVALID_ENT_REFERENCE) return;
	
	DebugMessage("EjectPilotFromArwing START (%d)", iArwing);
	
	ArwingReleaseAllButtons(iArwing);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Pilot);
	
	if (IsValidClient(iPilot)) OnClientExitArwing(iPilot, iArwing, bImmediate);
	
	DebugMessage("EjectPilotFromArwing END (%d)", iArwing);
}

stock GetArwing(ent, &iIndex=-1)
{
	if (!IsValidEntity(ent)) return -1;

	decl iArwing;
	for (new i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
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


ResetArwingLaser(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_NextLaserAttackTime);
}

ResetArwingMove(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_ForwardMove);
	SetArrayCell(g_hArwings, iIndex, 0.0, Arwing_SideMove);
}

ArwingStartTilt(iArwing, Float:flDesiredDirection)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InTilt)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "abilities") || !KvJumpToKey(hConfig, "tilt")) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InTilt);
	SetArrayCell(g_hArwings, iIndex, flDesiredDirection, Arwing_TiltDirection);
}

ArwingStopTilt(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InTilt)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InTilt);
}

ArwingStartBarrelRoll(iArwing, Float:flDesiredDirection)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll)) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_HasBarrelRollAbility)) return;
	
	if (GetGameTime() < GetArrayCell(g_hArwings, iIndex, Arwing_NextBarrelRollTime)) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBarrelRoll);
	SetArrayCell(g_hArwings, iIndex, flDesiredDirection, Arwing_BarrelRollDirection);
	
	new iPropEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
	if (iPropEnt && iPropEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iPropEnt);
	}
	
	new iRotateEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotateEnt));
	if (iRotateEnt && iRotateEnt != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iRotateEnt);
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollEnt);
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_BarrelRollRotateEnt);
	
	iRotateEnt = CreateEntityByName("prop_dynamic_override");
	if (iRotateEnt != -1)
	{
		decl Float:flArwingPos[3], Float:flArwingAng[3];
		GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
		GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
		
		decl Float:flRotatePos[3];
		flRotatePos[0] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosX);
		flRotatePos[1] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosY);
		flRotatePos[2] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotatePosZ);
		
		VectorTransform(flRotatePos, flArwingPos, flArwingAng, flRotatePos);
		
		SetEntityModel(iRotateEnt, ARWING_BARRELROLL_ROTATE_ENT_MODEL);
		DispatchSpawn(iRotateEnt);
		ActivateEntity(iRotateEnt);
		TeleportEntity(iRotateEnt, flRotatePos, flArwingAng, NULL_VECTOR);
		
		new iTrailEnt = CreateEntityByName("env_spritetrail");
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
			decl String:sModel[PLATFORM_MAX_PATH];
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
	
	CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDuration), Timer_ArwingStopBarrelRoll, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollCooldown), Arwing_NextBarrelRollTime);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBarrelRollTime);
	
	ArwingParentMyEffectsToSelfOfEvent(iArwing, EffectEvent_All);
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBarrelRoll);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBarrelRoll);
}

stock ArwingParentMyEffectsToSelfOfEvent(iArwing, EffectEvent:iEvent, bool:bIgnoreKill=false)
{
	decl iEffect, iEffectOwner, EffectEvent:iEffectEvent;
	for (new i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		if (!bIgnoreKill && bool:GetArrayCell(g_hEffects, i, Effect_InKill)) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (!iEffectOwner || iEffectOwner == INVALID_ENT_REFERENCE || iEffectOwner != iArwing) return;
		
		iEffectEvent = EffectEvent:GetArrayCell(g_hEffects, i, Effect_Event);
		if (iEvent == EffectEvent_All || iEffectEvent == iEvent)
		{
			ArwingParentMyEffectToSelf(iArwing, i);
		}
	}
}

public Action:Timer_ArwingBarrelRoll(Handle:timer, any:entref)
{
	new iEnt = EntRefToEntIndex(entref);
	if (!iEnt || iEnt == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	decl Float:flAng[3]; // Get angles local to parent.
	GetEntPropVector(iEnt, Prop_Data, "m_angRotation", flAng);
	flAng[2] -= 150.0;
	flAng[2] = AngleNormalize(flAng[2]);
	TeleportEntity(iEnt, NULL_VECTOR, flAng, NULL_VECTOR);
	
	return Plugin_Continue;
}

public Action:Timer_ArwingStopBarrelRoll(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ArwingStopBarrelRoll(iArwing);
}

ArwingStopBarrelRoll(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBarrelRoll);
	
	VehicleParentMyEffectsToSelfOfEvent(iArwing, EffectEvent_All);
	
	new iEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
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

ArwingStartUTurn(iArwing, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated)) return;
	
	if (!bForce && (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)))
	{
		return;
	}
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_HasUTurnAbility)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return; // Highly unlikely that this will happen.
	
	if (!bForce && GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InUTurn);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastUTurnTime);
	
	new Handle:hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnEnergyBurnRate), Timer_ArwingUTurnBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	// Set to phase 1. The semi-somersault.
	SetArrayCell(g_hArwings, iIndex, 1, Arwing_UTurnPhase);
	hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultDuration), Timer_ArwingUTurnPhaseOne, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnPhaseTimer);
	
	hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnDuration), Timer_ArwingStopUTurn, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_UTurnTimer);
	
	decl Float:flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	SetArrayCell(g_hArwings, iIndex, flArwingAng[1], Arwing_UTurnYawAngle);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_uturn_somersault", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingUTurn);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingUTurn);
}

public Action:Timer_ArwingUTurnBurnEnergy(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnEnergyBurnTimer)) return Plugin_Stop;
	
	new iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy > 0)
	{
		ArwingSetEnergy(iArwing, iEnergy - 1);
	}
	
	return Plugin_Continue;
}

public Action:Timer_ArwingUTurnPhaseOne(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnPhaseTimer)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return; // Highly unlikely that this will happen.
	
	// Set to phase two. The boost. This will last for the rest of the U-turn manuever.
	SetArrayCell(g_hArwings, iIndex, 2, Arwing_UTurnPhase);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnPhaseTimer);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_uturn_boost", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
}

public Action:Timer_ArwingStopUTurn(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnTimer)) return;
	
	ArwingStopUTurn(iArwing);
}

ArwingStopUTurn(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InUTurn);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnEnergyBurnTimer);
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_UTurnPhase);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnPhaseTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_UTurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingUTurn);
}

ArwingStartBoost(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn))
	{
		return;
	}
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_HasBoostAbility)) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBoost);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBoostTime);
	
	new Handle:hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_BoostEnergyBurnRate), Timer_ArwingBoostBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_BoostEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_boost", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBoost);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBoost);
}

ArwingStopBoost(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBoost);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BoostEnergyBurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingBoost);
}

public Action:Timer_ArwingBoostBurnEnergy(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_BoostEnergyBurnTimer)) return Plugin_Stop;
	
	new iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy <= 0)
	{
		ArwingStopBoost(iArwing);
		return Plugin_Stop;
	}
	
	ArwingSetEnergy(iArwing, iEnergy - 1);
	
	return Plugin_Continue;
}

ArwingStartBrake(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn))
	{
		return;
	}
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_HasBrakeAbility)) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InBrake);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastBrakeTime);
	
	new Handle:hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_BrakeEnergyBurnRate), Timer_ArwingBrakeBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_BrakeEnergyBurnTimer);
	TriggerTimer(hTimer, true);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_brake", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingBrake);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingBrake);
}

ArwingStopBrake(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InBrake);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_BrakeEnergyBurnTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingBrake);
}

public Action:Timer_ArwingBrakeBurnEnergy(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_BrakeEnergyBurnTimer)) return Plugin_Stop;
	
	new iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy <= 0)
	{
		ArwingStopBrake(iArwing);
		return Plugin_Stop;
	}
	
	ArwingSetEnergy(iArwing, iEnergy - 1);
	
	return Plugin_Continue;
}

ArwingStartSomersault(iArwing, bool:bIgnoreEnergy=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn))
	{
		return;
	}
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_HasSomersaultAbility)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	if (!bIgnoreEnergy && GetArrayCell(g_hArwings, iIndex, Arwing_Energy) < GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy)) return;
	
	decl Float:flArwingPos[3], Float:flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	new Float:flCurTime = GetGameTime();
	new Float:flDuration = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultDuration);
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InSomersault);
	SetArrayCell(g_hArwings, iIndex, flCurTime, Arwing_LastSomersaultTime);
	SetArrayCell(g_hArwings, iIndex, flArwingAng[1], Arwing_SomersaultYawAngle);
	
	new Handle:hTimer = CreateTimer(Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultEnergyBurnRate), Timer_ArwingSomersaultBurnEnergy, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_SomersaultEnergyBurnTimer);
	
	hTimer = CreateTimer(flDuration, Timer_ArwingStopSomersault, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_SomersaultTimer);
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_somersault", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingSomersault);
	TurnOnEffectsOfEntityOfEvent(iArwing, EffectEvent_ArwingSomersault);
}

public Action:Timer_ArwingSomersaultBurnEnergy(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultEnergyBurnTimer)) return Plugin_Stop;
	
	new iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	if (iEnergy > 0)
	{
		ArwingSetEnergy(iArwing, iEnergy - 1);
	}
	
	return Plugin_Continue;
}

public Action:Timer_ArwingStopSomersault(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultTimer)) return;
	
	ArwingStopSomersault(iArwing);
}

ArwingStopSomersault(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InSomersault);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultEnergyBurnTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_SomersaultTimer);
	
	RemoveEffectsFromEntityOfEvent(iArwing, EffectEvent_ArwingSomersault);
}

ArwingRemoveHealthBar(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	// No health bar entities? Initialize them.
	new iHealthBarStartEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarStartEntity));
	new iHealthBarEndEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarEndEntity));
	
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

public bool:OnClientEnterArwing(client, iArwing, bool:bImmediate)
{
	if (!IsValidClient(client) || !IsValidEntity(iArwing)) return false;
	
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return false;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return false;
	
	// Set up the camera first.
	new iCamera = CreateEntityByName("point_viewcontrol");
	if (iCamera != -1)
	{
		decl Float:flCameraPos[3], Float:flCameraAng[3];
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
		new iFakeModel = CreateEntityByName("prop_dynamic_override");
		if (iFakeModel != -1)
		{
			decl Float:flPos[3], Float:flAng[3];
			GetClientAbsOrigin(client, flPos);
			GetClientAbsAngles(client, flAng);
			
			decl String:sModel[PLATFORM_MAX_PATH];
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
			new iTrailEnt = CreateEntityByName("env_spritetrail");
			if (iTrailEnt != -1)
			{
				DispatchSpawn(iTrailEnt);
				ActivateEntity(iTrailEnt);
				SetVariantString("!activator");
				AcceptEntityInput(iTrailEnt, "SetParent", iFakeModel);
			}
			
			SetEntPropVector(iFakeModel, Prop_Data, "m_vecAngVelocity", Float:{ 720.0, 0.0, 0.0 });
			
			new iFlags = GetEntProp(client, Prop_Send, "m_fEffects");
			if (!(iFlags & 1)) iFlags |= 1;
			if (!(iFlags & iFlags)) iFlags |= 512;
			SetEntProp(client, Prop_Send, "m_fEffects", iFlags);
			
			SetVariantString("!activator");
			AcceptEntityInput(client, "SetParent", iFakeModel);
			SetVariantString("flag");
			AcceptEntityInput(client, "SetParentAttachment");
			
			SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iFakeModel), Arwing_FakePilotModel);
			
			TeleportEntity(iFakeModel, NULL_VECTOR, NULL_VECTOR, Float:{ 0.0, 0.0, 1200.0 });
			
			decl Float:flOffset[3];
			KvRewind(hConfig);
			KvGetVector(hConfig, "pilot_player_pos_offset", flOffset);
			
			new Handle:hPack;
			new Handle:hTimer = CreateDataTimer(0.01, Timer_FakePilotModelMoveToOffsetOfEntity, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
	new iHideHud = GetEntProp(client, Prop_Send, "m_iHideHUD");
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

public OnClientEnterArwingPost(client, iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	g_hPlayerVehicleSequenceTimer[client] = INVALID_HANDLE;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InPilotSequence);
	
	// Remove fake model.
	new iFakeModel = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_FakePilotModel));
	if (iFakeModel && iFakeModel != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(client, "ClearParent");
		DeleteEntity(iFakeModel, 0.75);
	}
	
	// Place the player in our offset position.
	decl Float:flPos[3], Float:flArwingPos[3], Float:flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	new iFlags = GetEntProp(client, Prop_Send, "m_fEffects");
	if (iFlags & 1) iFlags &= ~1;
	if (iFlags & 512) iFlags &= ~512;
	SetEntProp(client, Prop_Send, "m_fEffects", iFlags);
	
	SetVariantString("!activator");
	AcceptEntityInput(client, "SetParent", iArwing);
	
	KvRewind(hConfig);
	KvGetVector(hConfig, "pilot_player_pos_offset", flPos);
	TeleportEntity(client, flPos, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
	
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

public OnClientExitArwing(client, iArwing, bool:bImmediate)
{
	if (!IsValidClient(client)) return;
	
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	// Remove all my hud elements.
	decl iHudElement;
	new Handle:hArray = CloneArray(g_hHudElements);
	for (new i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		iHudElement = EntRefToEntIndex(GetArrayCell(hArray, i));
		if (!iHudElement || iHudElement == INVALID_ENT_REFERENCE) continue;
		
		if (EntRefToEntIndex(GetArrayCell(hArray, i, HudElement_Owner)) != iArwing) continue;
		
		AcceptEntityInput(iHudElement, "Kill");
	}
	
	CloseHandle(hArray);
	
	new iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (iCamera && iCamera != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iCamera, "Disable");
		DeleteEntity(iCamera, 0.1);
	}
	
	SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_CameraEnt);
	
	new iFakeModel = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_FakePilotModel));
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
	
	new iHideHud = GetEntProp(client, Prop_Send, "m_iHideHUD");
	iHideHud &= ~HIDEHUD_HEALTH;
	iHideHud &= ~HIDEHUD_WEAPONSELECTION;
	iHideHud &= ~HIDEHUD_INVEHICLE;
	SetEntProp(client, Prop_Send, "m_iHideHUD", iHideHud);
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	
	// Turn this off.
	DisableArwing(iArwing);
	
	for (new i = 0; i <= 5; i++)
	{
		new iWeapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_NORMAL);
			SetEntityRenderColor(iWeapon, 255, 255, 255, 255);
		}
	}
	
	TF2_RegeneratePlayer(client);
	
	ClientSetFOV(client, RoundFloat(g_flPlayerDesiredFOV[client]));
}

public Hook_ArwingVPhysicsUpdate(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	decl Float:flAng[3], Float:flPos[3], Float:flVelocity[3], Float:flAngVelocity[3];
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flAng);
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flPos);
	GetEntitySmoothedVelocity(iArwing, flVelocity);
	GetEntPropVector(iArwing, Prop_Data, "m_vecAngVelocity", flAngVelocity);
	
	new bool:bEnabled = bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled);
	
	new Float:flForwardMove = Float:GetArrayCell(g_hArwings, iIndex, Arwing_ForwardMove);
	new Float:flSideMove = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SideMove);
	
	new Float:flPitchRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_PitchRate);
	new Float:flYawRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_YawRate);
	new Float:flRollRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_RollRate); 
	
	new bool:bInIntro = bool:GetArrayCell(g_hArwings, iIndex, Arwing_Intro);
	new Float:flIntroStartTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_IntroStartTime);
	new Float:flIntroEndTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_IntroEndTime);
	new Float:flTotalIntroTime = flIntroEndTime - flIntroStartTime;
	
	new bool:bInBarrelRoll = bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll);
	new bool:bInSomersault = bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault);
	new bool:bInTilt = bool:GetArrayCell(g_hArwings, iIndex, Arwing_InTilt);
	new bool:bDestroyed = bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed);
	
	new bool:bInUTurn = bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn);
	new iUTurnPhase = GetArrayCell(g_hArwings, iIndex, Arwing_UTurnPhase);
	
	if (bInBarrelRoll)
	{
		new iRotateEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollRotateEnt));
		if (iRotateEnt && iRotateEnt != INVALID_ENT_REFERENCE)
		{
			decl Float:flRotateAng[3];
			GetEntPropVector(iRotateEnt, Prop_Data, "m_angRotation", flRotateAng); // get angles relative to parent
			
			new bool:bRotate = false;
			
			new iRollNum = GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollNum);
			
			new Float:flTargetRoll = -360.0 * Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDirection);
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
			
			new Float:flDuration = Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDuration);
			new Float:flStartTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LastBarrelRollTime);
			new Float:flEndTime = flStartTime + flDuration;
			
			if (GetGameTime() >= flEndTime) bRotate = false;
			
			if (bRotate)
			{
				new Float:flX = (GetGameTime() - flStartTime) / flDuration;
				new Float:flFinalAngVelocity[3];
				flFinalAngVelocity[2] = (2.0 * flTargetRoll * float(iRollNum) * (1.0 - flX)) / flDuration;
				SetEntPropVector(iRotateEnt, Prop_Data, "m_vecAngVelocity", flFinalAngVelocity);
			}
			else
			{
				new Float:flFinalAng[3];
				flFinalAng[2] = flTargetRoll * float(iRollNum);
				SetEntPropVector(iRotateEnt, Prop_Data, "m_vecAngVelocity", Float:{ 0.0, 0.0, 0.0 });
				SetEntPropVector(iRotateEnt, Prop_Data, "m_angRotation", flFinalAng);
			}
		}
	}
	
	if (bEnabled)
	{
		new bool:bApplyVelocity = true;
		new bool:bApplyAngVelocity = true;
		
		// Calculate the goal angular velocity we should be in.
		// Calculate the move angular velocity, first as local to object in terms of angles.
		decl Float:flMoveAngVelocity[3];
		decl Float:flMoveGoalAng[3];
		
		if (flForwardMove != 0.0)
		{
			if (flForwardMove > 0.0) flMoveGoalAng[0] = 50.0;
			else flMoveGoalAng[0] = -50.0;
		}
		else
		{
			flMoveGoalAng[0] = 0.0;
		}
		
		new Float:flTiltDirection = Float:GetArrayCell(g_hArwings, iIndex, Arwing_TiltDirection);
		new Float:flTiltTurnRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_TiltTurnRate);
		
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
			flMoveGoalAng[2] = AngleNormalize(-1.0 * Float:GetArrayCell(g_hArwings, iIndex, Arwing_TiltDegrees) * Float:GetArrayCell(g_hArwings, iIndex, Arwing_TiltDirection));
		}
		
		if (bInUTurn)
		{
			
		}
		
		if (bInSomersault)
		{
			flMoveAngVelocity[1] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultAngleFactor);
			flMoveAngVelocity[2] = 0.0;
			flMoveAngVelocity[0] = 0.0;
		}
		else if (bInUTurn)
		{
			if (iUTurnPhase == 1)
			{
				flMoveAngVelocity[1] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultAngleFactor);
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
			new Float:flRollRadians = DegToRad(flAng[2]);
		
			flMoveAngVelocity[1] = (flMoveGoalAng[0] - flAng[0]) * flPitchRate;
			flMoveAngVelocity[0] = (flMoveGoalAng[2] - flAng[2]) * flRollRate;
			
			// Adjust and rotate angular velocity to compensate for roll.
			decl Float:flOldMoveAngVelocity[3];
			CopyVectors(flMoveAngVelocity, flOldMoveAngVelocity);
			
			flMoveAngVelocity[2] = (flOldMoveAngVelocity[2] * Cosine(flRollRadians)) - (flOldMoveAngVelocity[1] * Sine(flRollRadians));
			flMoveAngVelocity[1] = (flOldMoveAngVelocity[2] * Sine(flRollRadians)) + (flOldMoveAngVelocity[1] * Cosine(flRollRadians));
		}
		
		// Are we in a damage sequence? Factor that in!
		if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InDamageSequence))
		{
			new Float:flLastDamageSequenceTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LastDamageSequenceTime);
			new Float:flLastDamageSequenceUpdateTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LastDamageSequenceUpdateTime);
			new Float:flCurTime = GetGameTime();
			
			if (flLastDamageSequenceUpdateTime > 0.0)
			{
				new Float:flLastScale = (150.0 * (1.0 - ((flLastDamageSequenceUpdateTime - flLastDamageSequenceTime) / 4.0))) * Sine(flLastDamageSequenceUpdateTime * 20.0);
				flMoveAngVelocity[0] += flLastScale;
			}
			
			new Float:flScale = (150.0 * (1.0 - ((flCurTime - flLastDamageSequenceTime) / 4.0))) * Sine(flCurTime * 20.0);
			flMoveAngVelocity[0] += flScale;
			
			SetArrayCell(g_hArwings, iIndex, flCurTime, Arwing_LastDamageSequenceUpdateTime);
		}
		
		// Calculate the goal velocity we should be in.
		decl Float:flMoveGoalVelocity[3];
		
		GetAngleVectors(flAng, flMoveGoalVelocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(flMoveGoalVelocity, flMoveGoalVelocity);
		
		if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost))
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_BoostSpeed));
		}
		else if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake))
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_BrakeSpeed));
		}
		else if (bInSomersault)
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultSpeed));
		}
		else if (bInUTurn && iUTurnPhase == 1)
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnSomersaultSpeed));
		}
		else if (bInUTurn && iUTurnPhase == 2)
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnBoostSpeed));
		}
		else
		{
			ScaleVector(flMoveGoalVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_MaxSpeed));
		}
		
		decl Float:flMoveVelocity[3];
		new Float:flAccelFactor = Float:GetArrayCell(g_hArwings, iIndex, Arwing_AccelFactor);
		
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
			new iEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
			if (iEnt && iEnt != INVALID_ENT_REFERENCE)
			{
				decl Float:flTargetAng[3]; // Get angles local to parent.
				GetEntPropVector(iEnt, Prop_Data, "m_angRotation", flTargetAng);
				flTargetAng[2] -= 20.0 * Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDirection);
				flTargetAng[2] = AngleNormalize(flTargetAng[2]);
				TeleportEntity(iEnt, NULL_VECTOR, flTargetAng, NULL_VECTOR);
			}
		}
		*/
		
		// Sound stuff.
		new Handle:hConfig = GetConfigOfArwing(iArwing);
		if (hConfig != INVALID_HANDLE)
		{
			decl Float:flArwingVelocity[3];
			GetEntitySmoothedVelocity(iArwing, flArwingVelocity);
			new Float:flSpeed = GetVectorLength(flArwingVelocity);
			new Float:flMaxSpeed = Float:GetArrayCell(g_hArwings, iIndex, Arwing_MaxSpeed);
			
			decl String:sPath[PLATFORM_MAX_PATH];
			if (GetRandomStringFromArwingConfig(hConfig, "sound_flyloop", sPath, sizeof(sPath), 1) && sPath[0])
			{
				new iPitch = RoundFloat(100.0 * (flSpeed / flMaxSpeed));
				if (iPitch < 25) iPitch = 25;
				else if (iPitch > 200) iPitch = 200;
				
				EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER, SND_CHANGEPITCH, 0.33, iPitch);
			}
		}
	}
	
	// Camera stuff.
	new iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (iCamera && iCamera != INVALID_ENT_REFERENCE)
	{
		decl Float:flCameraAng[3], Float:flCameraPos[3], Float:flCameraVelocity[3], Float:flCameraAngVelocity[3];
		GetEntPropVector(iCamera, Prop_Data, "m_angAbsRotation", flCameraAng);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAbsOrigin", flCameraPos);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAbsVelocity", flCameraVelocity);
		GetEntPropVector(iCamera, Prop_Data, "m_vecAngVelocity", flCameraAngVelocity);
		
		new Float:flCameraPitchRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_CameraPitchRate);
		new Float:flCameraYawRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_CameraYawRate);
		new Float:flCameraRollRate = Float:GetArrayCell(g_hArwings, iIndex, Arwing_CameraRollRate); 
		new Float:flAngAccelFactor = Float:GetArrayCell(g_hArwings, iIndex, Arwing_CameraAngAccelFactor);
		
		new Handle:hConfig = GetConfigOfArwing(iArwing);
		KvRewind(hConfig);
		
		new Float:flCameraMoveGoalAng[3];
		decl Float:flCameraMoveAngVelocity[3];
		decl Float:flCameraMoveGoalVelocity[3], Float:flCameraMoveGoalPos[3];
		
		// Calculate goal angular velocity.
		if (bInSomersault)
		{
			decl Float:flCameraAngSomersault[3];
			KvGetVector(hConfig, "camera_somersault_ang_offset", flCameraAngSomersault);
			
			SubtractVectors(flPos, flCameraPos, flCameraMoveGoalAng);
			GetVectorAngles(flCameraMoveGoalAng, flCameraMoveGoalAng);
			AddVectors(flCameraMoveGoalAng, flCameraAngSomersault, flCameraMoveGoalAng);
		}
		else if (bInUTurn)
		{
			decl Float:flCameraAngUTurn[3];
			
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
				decl Float:flCameraAngUpOrDown[3];
				
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
				decl Float:flCameraAngLeftOrRight[3];
				
				if (flSideMove > 0.0)
				{
					KvGetVector(hConfig, "camera_turn_right_ang_offset", flCameraAngLeftOrRight);
				}
				else
				{
					KvGetVector(hConfig, "camera_turn_left_ang_offset", flCameraAngLeftOrRight);
				}
				
				for (new i = 0; i < 2; i++) flCameraMoveGoalAng[i] = AngleNormalize(flAng[i] + (flCameraAngLeftOrRight[i] * FloatAbs(flSideMove)));
				flCameraMoveGoalAng[2] = (flCameraAngLeftOrRight[2] * FloatAbs(flSideMove));
			}
			else
			{
				decl Float:flCameraAngDefault[3];
				KvGetVector(hConfig, "camera_default_ang_offset", flCameraAngDefault);
				
				for (new i = 0; i < 2; i++) flCameraMoveGoalAng[i] = AngleNormalize(flAng[i] + flCameraAngDefault[i]);
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
			decl Float:flCameraPosSomersault[3], Float:flTempAng[3];
			KvGetVector(hConfig, "camera_somersault_pos_offset", flCameraPosSomersault);
			CopyVectors(flAng, flTempAng);
			flTempAng[0] = 0.0;
			flTempAng[1] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultYawAngle);
			flTempAng[2] = 0.0;
			VectorTransform(flCameraPosSomersault, flPos, flTempAng, flCameraPosSomersault);
			
			CopyVectors(flCameraPosSomersault, flCameraMoveGoalPos);
		}
		else if (bInUTurn)
		{
			decl Float:flCameraPosUTurn[3], Float:flTempAng[3];
			
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
			flTempAng[1] = Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnYawAngle);
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
			decl Float:flCameraPosDefault[3], Float:flCameraPosTurnLeft[3], Float:flCameraPosTurnRight[3];
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
		decl Float:flCameraMoveVelocity[3];
		
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

public Hook_ArwingOnTakeDamagePost(iArwing, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	DamageArwing(iArwing, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition);
}

public Action:Timer_ArwingRechargeEnergy(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (Handle:GetArrayCell(g_hArwings, iIndex, Arwing_EnergyRechargeTimer) != timer) return Plugin_Stop;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBoost) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBrake) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InSomersault) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InUTurn))
	{
		return Plugin_Continue;
	}
	
	new iEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_Energy);
	new iMaxEnergy = GetArrayCell(g_hArwings, iIndex, Arwing_MaxEnergy);
	
	if (iEnergy < iMaxEnergy)
	{
		ArwingSetEnergy(iArwing, iEnergy + 1);
	}
	
	return Plugin_Continue;
}

public Action:Timer_PlayerEnteredArwing(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0) return;
	
	if (timer != g_hPlayerVehicleSequenceTimer[client]) return;
	
	OnClientEnterArwingPost(client, GetArwing(client));
}

DestroyArwing(iArwing, iAttacker, iInflictor)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) return;
	
	DebugMessage("DestroyArwing START (%d)", iArwing);
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_Destroyed);
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.5, Arwing_ObliterateTime);
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
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
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		decl String:sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_destroyed", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingDestroyed, true);
	
	CreateTimer(5.0, Timer_ObliterateArwing, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	
	DebugMessage("DestroyArwing END (%d)", iArwing);
}

public Action:Timer_ObliterateArwing(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ObliterateArwing(iArwing);
}

ObliterateArwing(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) return;
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated)) return;
	
	if (GetGameTime() < Float:GetArrayCell(g_hArwings, iIndex, Arwing_ObliterateTime)) return;
	
	DebugMessage("ObliterateArwing START (%d)", iArwing);
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_Obliterated);
	
	Phys_EnableCollisions(iArwing, false);
	Phys_EnableMotion(iArwing, false);
	
	SetEntityRenderMode(iArwing, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iArwing, 0, 0, 0, 1);
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		decl String:sPath[PLATFORM_MAX_PATH];
		if (GetRandomStringFromArwingConfig(hConfig, "sound_obliterated", sPath, sizeof(sPath)) && sPath[0])
		{
			EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
		}
	}
	
	ArwingSpawnEffects(iArwing, EffectEvent_ArwingObliterated, true);
	DeleteEntity(iArwing, 5.0);
	
	DebugMessage("ObliterateArwing END (%d)", iArwing);
}

public DamageArwing(iArwing, iAttacker, iInflictor, Float:flDamage, iDamageType, iWeapon, const Float:flDamageForce[3], const Float:flDamagePosition[3])
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Obliterated))
	{
		return;
	}
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed))
	{
		ObliterateArwing(iArwing);
		return;
	}
	
	if ((iDamageType & DMG_BULLET) || (iDamageType & 0x80)) return; // No damage from bullets.
	
	if (!g_bFriendlyFire && iAttacker && IsValidEntity(iAttacker) && GetEntProp(iAttacker, Prop_Data, "m_iTeamNum") == GetArrayCell(g_hArwings, iIndex, Arwing_Team)) return;
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (IsValidEntity(iPilot) && iPilot == iAttacker) return; // No self damage.
	
	new iHealth = GetArrayCell(g_hArwings, iIndex, Arwing_Health);
	iHealth -= RoundToFloor(flDamage);
	ArwingSetHealth(iArwing, iHealth);
	
	new bool:bFromCollision = bool:(iDamageType & DMG_CRUSH);
	
	if (iHealth <= 0) 
	{
		DestroyArwing(iArwing, iAttacker, iInflictor);
		if (bFromCollision) ObliterateArwing(iArwing);
	}
	else 
	{
		ArwingStartDamageSequence(iArwing, bFromCollision);
		
		if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled) && bFromCollision) 
		{
			decl Float:flForceVector[3];
			NormalizeVector(flDamageForce, flForceVector);
			ScaleVector(flForceVector, 3.0);
			
			Phys_SetVelocity(iArwing, flDamageForce, NULL_VECTOR, true);
		}
	}
}

ArwingStartDamageSequence(iArwing, bool:bFromWorld)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
	SetArrayCell(g_hArwings, iIndex, true, Arwing_InDamageSequence);
	SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_LastDamageSequenceTime);
	SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_LastDamageSequenceUpdateTime);
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_DamageSequenceRedBlink);
	
	new Handle:hTimer = CreateTimer(0.5, Timer_ArwingStopDamageSequence, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_DamageSequenceTimer);
	
	hTimer = CreateTimer(0.025, Timer_ArwingDamageSequenceRedBlink, EntIndexToEntRef(iArwing), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_DamageSequenceRedBlinkTimer);
	TriggerTimer(hTimer, true);
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		decl String:sPath[PLATFORM_MAX_PATH];
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
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (IsValidClient(iPilot) && !IsFakeClient(iPilot))
	{
		new iFade = CreateEntityByName("env_fade");
		SetEntPropFloat(iFade, Prop_Data, "m_Duration", 0.66);
		SetEntPropFloat(iFade, Prop_Data, "m_HoldTime", 0.0);
		SetEntProp(iFade, Prop_Data, "m_spawnflags", 5);
		SetEntityRenderColor(iFade, 255, 0, 0, 100);
		DispatchSpawn(iFade);
		AcceptEntityInput(iFade, "Fade", iPilot);
		DeleteEntity(iFade);
	}
}

public Action:Timer_ArwingDamageSequenceRedBlink(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceRedBlinkTimer)) return Plugin_Stop;
	
	ArwingDamageSequenceDoRedBlink(iArwing);
	
	return Plugin_Continue;
}

ArwingDamageSequenceDoRedBlink(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Destroyed)) return;
	
	new iColorEnt = iArwing;
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll))
	{
		new iBarrelRollEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
		if (iBarrelRollEnt && iBarrelRollEnt != INVALID_ENT_REFERENCE)
		{
			iColorEnt = iBarrelRollEnt;
		}
	}
	
	new iPattern = GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceRedBlink);
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

ArwingStopDamageSequence(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_InDamageSequence)) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_InDamageSequence);
	SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_LastDamageSequenceUpdateTime);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_DamageSequenceTimer);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_DamageSequenceRedBlinkTimer);
	
	SetArrayCell(g_hArwings, iIndex, 0, Arwing_DamageSequenceRedBlink);
	ArwingDamageSequenceDoRedBlink(iArwing);
}

public Action:Timer_ArwingStopDamageSequence(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hArwings, iIndex, Arwing_DamageSequenceTimer)) return;
	
	ArwingStopDamageSequence(iArwing);
}

ArwingOnSleep(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled) ||
		bool:GetArrayCell(g_hArwings, iIndex, Arwing_InPilotSequence))
	{
		Phys_Wake(iArwing);
	}
}

ArwingSpawnEffects(iArwing, EffectEvent:iEvent, bool:bStartOn=false, bool:bOverridePos=false, const Float:flOverridePos[3]=NULL_VECTOR, const Float:flOverrideAng[3]=NULL_VECTOR)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "effects") || !KvGotoFirstSubKey(hConfig)) return;
	
	new Handle:hArray = CreateArray(64);
	decl String:sSectionName[64];
	decl String:sType[512];
	
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
	
	decl String:sEffectName[64];
	GetEffectEventName(iEvent, sEffectName, sizeof(sEffectName));
	
	decl iEffect, iEffectIndex, EffectType:iEffectType, iColor[4], Float:flLifeTime;
	//decl String:sValue[PLATFORM_MAX_PATH];
	
	for (new i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
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
		
		new bool:bCheckTeam = bool:KvGetNum(hConfig, "color_team");
		
		iEffect = CreateEffect(iEffectType, iEvent, iArwing, i, bCheckTeam, iEffectIndex);
		if (iEffect != -1)
		{
			// Parse through keyvalues, if specified.
			if (KvJumpToKey(hConfig, "keyvalues"))
			{
				decl String:sWholeThing[512];
				new String:sKeyValues[2][512];
				
				for (new i2 = 1;;i2++)
				{
					decl String:sIndex[16];
					IntToString(i2, sIndex, sizeof(sIndex));
					KvGetString(hConfig, sIndex, sWholeThing, sizeof(sWholeThing));
					if (!sWholeThing[0]) break; // ran out of key values. stop.
					
					new iCount = ExplodeString(sWholeThing, ";", sKeyValues, 2, 512);
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
							decl iColor2[4];
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

ArwingParentMyEffectToSelf(iArwing, iEffectIndex, bool:bOverridePos=false, const Float:flOverridePos[3]=NULL_VECTOR, const Float:flOverrideAng[3]=NULL_VECTOR)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	new iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex));
	
	// Get the appropriate offset positions we should use for the effect.
	decl Float:flPos[3], Float:flAng[3];
	if (bOverridePos)
	{
		CopyVectors(flOverridePos, flPos);
		CopyVectors(flOverrideAng, flAng);
	}
	else
	{
		new Handle:hConfig = GetConfigOfArwing(iArwing);
		if (hConfig == INVALID_HANDLE) return;
		
		KvRewind(hConfig);
		if (!KvJumpToKey(hConfig, "effects") || !KvGotoFirstSubKey(hConfig)) return;
	
		new bool:bFoundEffect = false;
	
		new iCustomIndex = GetArrayCell(g_hEffects, iEffectIndex, Effect_CustomIndex);
		new iIndexCount;
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
	new iParentEnt = iArwing;
	new iBarrelRollEnt = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollEnt));
	if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_InBarrelRoll) && iBarrelRollEnt && iBarrelRollEnt != INVALID_ENT_REFERENCE)
	{
		iParentEnt = iBarrelRollEnt;
	}
	
	decl Float:flParentPos[3], Float:flParentAng[3];
	GetEntPropVector(iParentEnt, Prop_Data, "m_vecAbsOrigin", flParentPos);
	GetEntPropVector(iParentEnt, Prop_Data, "m_angAbsRotation", flParentAng);
	
	// Parent by offset.
	SetVariantString("!activator");
	AcceptEntityInput(iEffect, "SetParent", iParentEnt);
	TeleportEntity(iEffect, flPos, flAng, Float:{ 0.0, 0.0, 0.0 });
}

ArwingSetTeamColorOfEffects(iArwing)
{
	decl iEffect, iEffectOwner;
	for (new i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (!iEffectOwner || iEffectOwner == INVALID_ENT_REFERENCE || iEffectOwner != iArwing) return;
		
		if (!bool:GetArrayCell(g_hEffects, i, Effect_ShouldCheckTeam)) continue;
		
		ArwingEffectSetTeamColor(iArwing, i);
	}
}

ArwingEffectSetTeamColor(iArwing, iEffectIndex)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex))
	if (!iEffect || iEffect == INVALID_ENT_REFERENCE) return;
	
	new iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	new EffectType:iType = GetArrayCell(g_hEffects, iEffectIndex, Effect_Type);
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig != INVALID_HANDLE)
	{
		KvRewind(hConfig);
		if (KvJumpToKey(hConfig, "effects") && KvGotoFirstSubKey(hConfig))
		{
			decl iColor[4], iColor2[4];
			new iCustomIndex = GetArrayCell(g_hEffects, iEffectIndex, Effect_CustomIndex);
			new iIndexCount;
			
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

public bool:TraceRayArwingTargeting(entity, contentsMask, any:data)
{
	if (entity == data) return false;
	
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(data));
	if (iIndex != -1)
	{
		new iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
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

public bool:TraceRayArwingTargetsOnly(entity, contentsMask, any:data)
{
	if (entity == data) return false;
	
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
	if (iIndex == -1) return false;
	
	return true;
}

public bool:TraceRayArwingTargetingNoWorld(entity, contentsMask, any:data)
{
	if (entity == data) return false;
	if (entity == 0) return false;
	
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(data));
	if (iIndex != -1)
	{
		new iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(entity));
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