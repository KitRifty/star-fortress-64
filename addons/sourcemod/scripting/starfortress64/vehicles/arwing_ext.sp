#if defined _sf64_arwing_ext_included
  #endinput
#endif
#define _sf64_arwing_ext_included

#define ARWING_HEALTHBAR_MODEL "models/Effects/teleporttrail.mdl"


public void ArwingOnEntityDestroyed(int entity)
{
	// Check if this entity is our charged laser entity.
	for (int i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
	{
		int iArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
		if (!iArwing || iArwing == INVALID_ENT_REFERENCE) continue;
		
		int iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, i, Arwing_ChargedLaserEnt));
		if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE && iChargedLaser == entity)
		{
			RemoveAllTargetReticlesFromEntity(iArwing, true);
			SetArrayCell(g_hArwings, i, INVALID_ENT_REFERENCE, Arwing_Target);
			break;
		}
	}
	
	if (GetArraySize(g_hArwings) > 0)
	{
		int entref = EntIndexToEntRef(entity);
		int iIndex = FindValueInArray(g_hArwings, entref);
		if (iIndex != -1)
		{
			EjectPilotFromArwing(entity);
			DisableArwing(entity);
			
			char sEntRef[256];
			IntToString(entref, sEntRef, sizeof(sEntRef));
			RemoveFromTrie(g_hArwingNames, sEntRef);
			RemoveFromArray(g_hArwings, iIndex);
			
			DispatchKeyValueFloat(entity, "modelscale", 1.0); // prevent crashing?
		}
	}
}

public void ArwingOnPlayerRunCmd(int client, int &buttons,int &impulse, float vel[3], float angles[3], int &weapon)
{
	int iVehicleType, iIndex;
	GetCurrentVehicle(client, iVehicleType, iIndex);
	
	if (iVehicleType == VehicleType_Arwing)
	{
		if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)))
		{
			if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_IgnorePilotControls)))
			{
				SetArrayCell(g_hArwings, iIndex, g_bPlayerInvertedYAxis[client] ? g_flPlayerForwardMove[client] : -g_flPlayerForwardMove[client], Arwing_ForwardMove);
				SetArrayCell(g_hArwings, iIndex, g_bPlayerInvertedXAxis[client] ? -g_flPlayerSideMove[client] :  g_flPlayerSideMove[client], Arwing_SideMove);
			}
		}
	}
}

void ArwingPressButton(int iArwing, int iButton)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;

	int iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (iButtons & iButton) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_IgnorePilotControls)) return;
	
	iButtons |= iButton;
	SetArrayCell(g_hArwings, iIndex, iButtons, Arwing_Buttons);
	
	bool bEnabled = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled));
	
	switch (iButton)
	{
		case IN_BACK:
		{
			SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.25, Arwing_SomersaultTime);
			SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.25, Arwing_UTurnTime);
		}
		case IN_ATTACK:
		{
			if (bEnabled) 
			{
				if (view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserReady)))
				{
					ArwingReleaseChargedLaser(iArwing);
				}
				else
				{
					ArwingFireLasers(iArwing);
					SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.1, Arwing_ChargedLaserStartTime);
				}
			}
		}
		case IN_ATTACK2:
		{
			if (bEnabled)
			{
				bool bFireNew = true;
				
				int iSmartBomb = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombEnt));
				if ((iSmartBomb && iSmartBomb != INVALID_ENT_REFERENCE))
				{
					int iSmartBombIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
					if (iSmartBombIndex != -1 && !view_as<bool>(GetArrayCell(g_hSBombs, iSmartBombIndex, SBomb_Detonated)))
					{
						bFireNew = false;
					}
				}
				
				if (bFireNew)
				{
					ArwingFireSmartBomb(iArwing);
				}
				else
				{
					DetonateSmartBomb(iSmartBomb);
				}
			}
		}
		case IN_JUMP:
		{
			if (bEnabled)
			{
				float flArwingAng[3];
				GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
				
				if (iButtons & IN_BACK && !(iButtons & IN_MOVELEFT) && !(iButtons & IN_MOVERIGHT) && FloatAbs(flArwingAng[2]) <= 45.0 && GetGameTime() < view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultTime)))
				{
					ArwingStartSomersault(iArwing);
				}
				else
				{
					ArwingStartBoost(iArwing);
				}
			}
		}
		case IN_DUCK:
		{
			if (bEnabled)
			{
				float flArwingAng[3];
				GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
			
				if (iButtons & IN_BACK && !(iButtons & IN_MOVELEFT) && !(iButtons & IN_MOVERIGHT) && FloatAbs(flArwingAng[2]) <= 45.0 && GetGameTime() < view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_UTurnTime)))
				{
					ArwingStartUTurn(iArwing);
				}
				else
				{
					ArwingStartBrake(iArwing);
				}

				float flCrouchStart = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_CrouchStartTime));
				if (flCrouchStart < 0.0 || GetGameTime() > flCrouchStart)
				{
					SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.25, Arwing_CrouchStartTime);
				}
				else
				{
					int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot)); 
					g_bPlayerDisableHUD[iPilot] = !g_bPlayerDisableHUD[iPilot];
					SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_CrouchStartTime);
				}
			}
		}
		case IN_RELOAD:
		{
			if (bEnabled)
			{
				ArwingStartTilt(iArwing, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_TiltDesiredDirection)));
			
				float flBarrelRollStart = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollStartTime));
				if (flBarrelRollStart < 0.0 || GetGameTime() > flBarrelRollStart)
				{
					SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.25, Arwing_BarrelRollStartTime);
				}
				else
				{
					ArwingStartBarrelRoll(iArwing, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDesiredDirection)));
					SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_BarrelRollStartTime);
				}
			}
		}
		case IN_MOVELEFT:
		{
			SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_BarrelRollDesiredDirection);
			SetArrayCell(g_hArwings, iIndex, 1.0, Arwing_TiltDesiredDirection);
		}
		case IN_MOVERIGHT:
		{
			SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_BarrelRollDesiredDirection);
			SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_TiltDesiredDirection);
		}
	}
}

void ArwingReleaseButton(int iArwing, int iButton)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (!(iButtons & iButton)) return;
	
	iButtons &= ~iButton;
	SetArrayCell(g_hArwings, iIndex, iButtons, Arwing_Buttons);
	
	switch (iButton)
	{
		case IN_ATTACK:
		{
			int iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
			if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE)
			{
				int iChargedLaserIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
				if (iChargedLaserIndex != -1)
				{
					if (view_as<bool>(GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging)))
					{
						// Create a kill timer.
						Handle hTimer = CreateTimer(0.25, Timer_ArwingChargedLaserKillTimer, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
						SetArrayCell(g_hArwings, iIndex, hTimer, Arwing_ChargedLaserKillTimer);
					}
				}
			}
		}
		case IN_JUMP:
		{
			ArwingStopBoost(iArwing);
		}
		case IN_DUCK:
		{
			ArwingStopBrake(iArwing);
		}
		case IN_RELOAD:
		{
			ArwingStopTilt(iArwing);
		}
	}
}

void ArwingReleaseAllButtons(int iArwing)
{
	for (int iButton = 0; iButton < MAX_BUTTONS; iButton++)
	{
		ArwingReleaseButton(iArwing, iButton);
	}
}

void ArwingFireLasers(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (GetGameTime() < view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_NextLaserAttackTime))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "laser")) return;
	
	float flArwingPos[3], flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	bool bCanAutoAim = view_as<bool>(KvGetNum(hConfig, "autoaim"));
	
	float flArwingLaserAutoAimPos[3];
	KvGetVector(hConfig, "autoaim_pos_offset", flArwingLaserAutoAimPos);
	VectorTransform(flArwingLaserAutoAimPos, flArwingPos, flArwingAng, flArwingLaserAutoAimPos);
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	int iOwner = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	int iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	int iUpgradeLevel = GetArrayCell(g_hArwings, iIndex, Arwing_LaserUpgradeLevel);
	
	char sType[64];
	float flPos[3], flVelocity[3];
	
	// Determine the velocity. Implement auto-aim here.
	bool bAutoAim = false;
	float flAutoAimPos[3];
	float flAutoAimVelocity[3];
	
	if (bCanAutoAim)
	{
		for (int i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
		{
			if (iIndex == i) continue;
			int ent = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
			if (!ent || ent == INVALID_ENT_REFERENCE) continue;
			
			float flTargetPos[3];
			VehicleGetOBBCenter(ent, flTargetPos);
			
			if (IsPointWithinFOV(flArwingLaserAutoAimPos, flArwingAng, 10.0, flTargetPos))
			{
				GetEntitySmoothedVelocity(ent, flAutoAimVelocity);
				for (int i2 = 0; i2 < 3; i2++) flAutoAimPos[i2] = flTargetPos[i2];
				bAutoAim = true;
				break;
			}
		}
	}
	
	float flLaserSpeed = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LaserSpeed));

	// We need to clamp down the speed if the cvar value is smaller than the projectile speed,
	// otherwise the projectile speed will be clamped down by the engine and somehow ends up flying into a random direction.
	ConVar cvMaxVelocity = FindConVar("sv_maxvelocity");
	if (cvMaxVelocity != null && flLaserSpeed > cvMaxVelocity.FloatValue)
		flLaserSpeed = cvMaxVelocity.FloatValue;
	
	if (bAutoAim)
	{
		float flTime = GetVectorDistance(flAutoAimPos, flArwingLaserAutoAimPos) / flLaserSpeed;
		ScaleVector(flAutoAimVelocity, flTime);
		AddVectors(flAutoAimPos, flAutoAimVelocity, flAutoAimPos);
		SubtractVectors(flAutoAimPos, flArwingLaserAutoAimPos, flVelocity);
	}
	else
	{
		GetAngleVectors(flArwingAng, flVelocity, NULL_VECTOR, NULL_VECTOR);
	}
	
	NormalizeVector(flVelocity, flVelocity);
	ScaleVector(flVelocity, flLaserSpeed);
	
	int iHyperCount;
	
	if (KvGotoFirstSubKey(hConfig))
	{
		Handle hArray = CreateArray(64);
		char sSectionName[64];
		
		// We have to store section names in an array because the ArwingSpawnEffects function will change our KeyValue position in hConfig.
		do
		{
			KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
			PushArrayString(hArray, sSectionName);
		}
		while (KvGotoNextKey(hConfig));
		
		for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
		{
			GetArrayString(hArray, i, sSectionName, sizeof(sSectionName));
			KvRewind(hConfig);
			KvJumpToKey(hConfig, "weapons");
			KvJumpToKey(hConfig, "positions");
			KvJumpToKey(hConfig, sSectionName);
			
			KvGetString(hConfig, "type", sType, sizeof(sType));
			if (StrEqual(sType, "laser"))
			{
				if (KvGetNum(hConfig, "upgrade_level") == iUpgradeLevel)
				{
					bool bHyper = view_as<bool>(KvGetNum(hConfig, "hyper"));
					float flDamage = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LaserDamage));
					if (bHyper)
					{
						flDamage = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LaserHyperDamage));
					}
				
					KvGetVector(hConfig, "origin", flPos);
					VectorTransform(flPos, flArwingPos, flArwingAng, flPos);
					SpawnLaser(flPos, flArwingAng, flVelocity, iTeam, iOwner, flDamage, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LaserLifeTime)), bHyper);
					
					/*
					{
						float flEndPos[3];
						NormalizeVector(flVelocity, flEndPos);
						ScaleVector(flEndPos, 6000.0);
						AddVectors(flPos, flEndPos, flEndPos);
						
						TE_SetupBeamPoints(flEndPos, flPos,
							PrecacheModel("materials/sprites/laserbeam.vmt"),
							PrecacheModel("materials/sprites/laserbeam.vmt"),
							0,
							30,
							1.0,
							2.0,
							2.0,
							1,
							0.0,
							{ 255, 255, 255, 100 },
							1);
						TE_SendToAll();
					}
					*/
					
					KvGetVector(hConfig, "origin", flPos);
					
					if (bHyper)
					{
						iHyperCount++;
						ArwingSpawnEffects(iArwing, EffectEvent_ArwingFireHyperLaser, true, true, flPos, NULL_VECTOR);
					}
					else
					{
						ArwingSpawnEffects(iArwing, EffectEvent_ArwingFireLaser, true, true, flPos, NULL_VECTOR);
					}
				}
			}
		}
		
		CloseHandle(hArray);
	}
	
	char sPath[PLATFORM_MAX_PATH];
	if (iHyperCount && GetRandomStringFromArwingConfig(hConfig, "sound_hyperlaser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	else if (GetRandomStringFromArwingConfig(hConfig, "sound_laser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_LaserCooldown)), Arwing_NextLaserAttackTime);
}

void ArwingStartChargedLaser(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (GetGameTime() < view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_NextChargedLaserAttackTime))) return;
	
	int iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
	if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "chargedlaser")) return;
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	int iOwner = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	int iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	int iUpgradeLevel = GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserUpgradeLevel);
	
	char sType[64];
	float flArwingPos[3], flArwingAng[3];
	float flPos[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_ChargedLaserReady);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_ChargedLaserKillTimer);
	
	if (KvGotoFirstSubKey(hConfig))
	{
		do
		{
			KvGetString(hConfig, "type", sType, sizeof(sType));
			if (StrEqual(sType, "chargedlaser"))
			{
				if (KvGetNum(hConfig, "upgrade_level") == iUpgradeLevel)
				{
					KvGetVector(hConfig, "origin", flPos);
					VectorTransform(flPos, flArwingPos, flArwingAng, flPos);
					
					iChargedLaser = SpawnChargedLaser(flPos, 
						NULL_VECTOR, 
						NULL_VECTOR, 
						iTeam, 
						iOwner, 
						-1, 
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserDamage)),
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserDamageRadius)),
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserLifeTime)),
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserSpeed)),
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserTrackDuration)),
						true,
						view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserChargeDuration)));
						
					if (iChargedLaser != -1)
					{
						RemoveAllTargetReticlesFromEntity(iArwing, true);
						SetArrayCell(g_hArwings, iIndex, -1.0, Arwing_ChargedLaserStartTime);
						SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iChargedLaser), Arwing_ChargedLaserEnt);
						SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Target);
						
						SetVariantString("!activator");
						AcceptEntityInput(iChargedLaser, "SetParent", iArwing);
					}
					
					break;
				}
			}
		}
		while (KvGotoNextKey(hConfig));
	}
}

public Action Timer_ArwingChargedLaserKillTimer(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ArwingReleaseChargedLaser(iArwing, true);
}

void ArwingReleaseChargedLaser(int iArwing, bool bForceKill=false)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_ChargedLaserReady);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_ChargedLaserKillTimer);
	
	int iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
	if (!iChargedLaser || iChargedLaser == INVALID_ENT_REFERENCE) return;
	
	int iChargedLaserIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iChargedLaserIndex == -1) return;
	
	if (!view_as<bool>(GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging))) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	if (bForceKill || (view_as<bool>(GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging)) &&
		GetGameTime() < view_as<float>(GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_ChargeEndTime))))
	{
		DeleteEntity(iChargedLaser);
		return;
	}
	
	float flPos[3], flVelocity[3];
	GetEntPropVector(iChargedLaser, Prop_Data, "m_vecAbsOrigin", flPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flVelocity);
	GetAngleVectors(flVelocity, flVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(flVelocity, flVelocity);
	ScaleVector(flVelocity, view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserSpeed)));
	
	ReleaseChargedLaser(iChargedLaser);
	TeleportEntity(iChargedLaser, flPos, NULL_VECTOR, flVelocity);
	
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserCooldown)), Arwing_NextChargedLaserAttackTime);
	
	char sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_chargedlaser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
}

void ArwingFireSmartBomb(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iSmartBomb = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombEnt));
	if ((iSmartBomb && iSmartBomb != INVALID_ENT_REFERENCE))
	{
		int iSmartBombIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
		if (iSmartBombIndex != -1 && !view_as<bool>(GetArrayCell(g_hSBombs, iSmartBombIndex, SBomb_Detonated)))
		{
			// can't fire a bomb if we already have one out.
			return;
		}
	}
	
	int iNumSmartBombs = GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombNum);
	if (!GetConVarBool(g_cvInfiniteBombs) && iNumSmartBombs <= 0) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "smartbomb")) return;
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	int iTarget = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
	int iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	float flSmartBombDamage = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombDamage));
	float flSmartBombDamageRadius = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombDamageRadius));
	float flSmartBombLifeTime = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombLifeTime));
	float flSmartBombMaxSpeed = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombMaxSpeed));
	float flSmartBombTrackDuration = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombTrackDuration));
	
	float flArwingPos[3], flArwingAng[3], flPos[3], flAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	if (KvGotoFirstSubKey(hConfig))
	{
		char sType[64];
	
		do
		{
			KvGetString(hConfig, "type", sType, sizeof(sType));
			if (StrEqual(sType, "smartbomb"))
			{
				KvGetVector(hConfig, "origin", flPos);
				VectorTransform(flPos, flArwingPos, flArwingAng, flPos);
				CopyVectors(flArwingAng, flAng);
				flAng[2] = 0.0;
				
				float flVelocity[3];
				GetAngleVectors(flArwingAng, flVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(flVelocity, flVelocity);
				ScaleVector(flVelocity, flSmartBombMaxSpeed);
				
				iSmartBomb = SpawnSmartBomb(flPos, flAng, flVelocity, iTeam, iPilot, iTarget, flSmartBombDamage, flSmartBombDamageRadius, flSmartBombLifeTime, flSmartBombMaxSpeed, flSmartBombTrackDuration);
				if (iSmartBomb != -1)
				{
					if (!GetConVarBool(g_cvInfiniteBombs))
					{
						SetArrayCell(g_hArwings, iIndex, --iNumSmartBombs, Arwing_SmartBombNum);
					}
					
					SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iSmartBomb), Arwing_SmartBombEnt);
					break;
				}
			}
		}
		while (KvGotoNextKey(hConfig));
	}
}

// Health bars are technically not considered an actual HUD element.
// Rather, they are simply beams emitted across two prop_dynamic entities.

void ArwingUpdateHealthBar(int iArwing)
{
	int iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (!IsValidClient(iPilot) || IsFakeClient(iPilot)) return;
	
	// No camera entity? *middle finger*
	int iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (!iCamera || iCamera == INVALID_ENT_REFERENCE) return;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	float flHealthBarStartEntityPosOffset[3], flHealthBarEndEntityStartPosOffset[3];
	float flStartWidth, flEndWidth;
	
	bool bFoundHealthBar = false;
	
	// Search through all my stored hud elements to see if the health range matches.
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "hudelements") && KvGotoFirstSubKey(hConfig))
	{
		char sHudElementType[64];
	
		do
		{
			KvGetString(hConfig, "type", sHudElementType, sizeof(sHudElementType));
			if (StrEqual(sHudElementType, "healthbar"))
			{
				// Get the beam positions, relative to the camera's position.
				bFoundHealthBar = true;
				KvGetVector(hConfig, "origin_start", flHealthBarStartEntityPosOffset);
				KvGetVector(hConfig, "origin_end", flHealthBarEndEntityStartPosOffset);
				flStartWidth = KvGetFloat(hConfig, "startwidth");
				flEndWidth = KvGetFloat(hConfig, "endwidth");
				
				break;
			}
		}
		while KvGotoNextKey(hConfig);
	}
	
	// This arwing does not have a health bar. Ignored.
	if (!bFoundHealthBar) return;
	
	float flCameraPos[3], flCameraAng[3];
	GetEntPropVector(iCamera, Prop_Data, "m_vecAbsOrigin", flCameraPos);
	GetEntPropVector(iCamera, Prop_Data, "m_angAbsRotation", flCameraAng);
	
	// No health bar entities? Create them, for Pete's sake!
	int iHealthBarStartEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarStartEntity));
	int iHealthBarEndEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarEndEntity));
	if ((!iHealthBarStartEntity || iHealthBarStartEntity == INVALID_ENT_REFERENCE) ||
		(!iHealthBarEndEntity || iHealthBarEndEntity == INVALID_ENT_REFERENCE))
	{
		// Reset.
		ArwingRemoveHealthBar(iArwing);
		
		iHealthBarStartEntity = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(iHealthBarStartEntity, ARWING_HEALTHBAR_MODEL);
		DispatchSpawn(iHealthBarStartEntity);
		ActivateEntity(iHealthBarStartEntity);
		SetEntityRenderMode(iHealthBarStartEntity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iHealthBarStartEntity, 0, 0, 0, 1);
		SetEntProp(iHealthBarStartEntity, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iHealthBarStartEntity, Prop_Send, "m_CollisionGroup", 0);
		
		SetVariantString("!activator");
		AcceptEntityInput(iHealthBarStartEntity, "SetParent", iCamera);
		
		// We can teleport by offset because we are in the parent's space, not the world's space.
		TeleportEntity(iHealthBarStartEntity, flHealthBarStartEntityPosOffset, NULL_VECTOR, NULL_VECTOR);
		
		SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iHealthBarStartEntity), Arwing_HealthBarStartEntity);
		
		iHealthBarEndEntity = CreateEntityByName("prop_dynamic_override");
		SetEntityModel(iHealthBarEndEntity, ARWING_HEALTHBAR_MODEL);
		DispatchSpawn(iHealthBarEndEntity);
		ActivateEntity(iHealthBarEndEntity);
		SetEntityRenderMode(iHealthBarEndEntity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iHealthBarEndEntity, 0, 0, 0, 1);
		SetEntProp(iHealthBarEndEntity, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iHealthBarEndEntity, Prop_Send, "m_CollisionGroup", 0);
		
		SetVariantString("!activator");
		AcceptEntityInput(iHealthBarEndEntity, "SetParent", iCamera);
		
		// We can teleport by offset because we are in the parent's space, not the world's space.
		TeleportEntity(iHealthBarEndEntity, flHealthBarEndEntityStartPosOffset, NULL_VECTOR, NULL_VECTOR);
		
		SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iHealthBarEndEntity), Arwing_HealthBarEndEntity);
	}
	
	float flHealthBarEndEntityPosOffset[3];
	
	float flHealthRatio = float(GetArrayCell(g_hArwings, iIndex, Arwing_Health)) / float(GetArrayCell(g_hArwings, iIndex, Arwing_MaxHealth));
	float flLength = GetVectorDistance(flHealthBarStartEntityPosOffset, flHealthBarEndEntityStartPosOffset) * flHealthRatio;
	
	SubtractVectors(flHealthBarEndEntityStartPosOffset, flHealthBarStartEntityPosOffset, flHealthBarEndEntityPosOffset);
	NormalizeVector(flHealthBarEndEntityPosOffset, flHealthBarEndEntityPosOffset);
	ScaleVector(flHealthBarEndEntityPosOffset, flLength);
	AddVectors(flHealthBarStartEntityPosOffset, flHealthBarEndEntityPosOffset, flHealthBarEndEntityPosOffset);
	
	TeleportEntity(iHealthBarEndEntity, flHealthBarEndEntityPosOffset, NULL_VECTOR, NULL_VECTOR);
	
	// Positions set. Now we need to determine which material to show to our client.
	// Parse through our config again.
	
	// Assuming no other functions between here and the last place we parsed the
	// config, we should still be within the correct KeyValues tree position.
	
	float flMinHealthRange, flMaxHealthRange;
	
	int iModelIndex = -1;
	
	// Parse through all the ranges in our hud element to get the right one to use.
	if (KvJumpToKey(hConfig, "ranges") && KvGotoFirstSubKey(hConfig))
	{
		do
		{
			flMinHealthRange = KvGetFloat(hConfig, "range_min");
			flMaxHealthRange = KvGetFloat(hConfig, "range_max");
			
			if (flHealthRatio > flMinHealthRange && flHealthRatio <= flMaxHealthRange)
			{
				char sHudElementMaterial[PLATFORM_MAX_PATH];
				KvGetString(hConfig, "material", sHudElementMaterial, sizeof(sHudElementMaterial));
				
				iModelIndex = PrecacheModel(sHudElementMaterial);
				break;
			}
		}
		while KvGotoNextKey(hConfig);
	}
	
	if (iModelIndex == -1) return; // No material; we're done here.
	
	if (!view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))) return;
	
	TE_SetupBeamEnts(iHealthBarStartEntity,
		iHealthBarEndEntity,
		iModelIndex,
		iModelIndex,
		0,
		30,
		0.4,
		flStartWidth,
		flEndWidth,
		0,
		0.0,
		{ 255, 255, 255, 255 },
		0);
	
	TE_SendToClient(iPilot);
}

public Action Timer_ArwingThink(Handle timer, any entref)
{
	int iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	Handle hConfig = GetConfigOfArwing(iArwing);
	
	int iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
	if (IsValidClient(iPilot))
	{
		ArwingUpdateHealthBar(iArwing);

		// Display Controls Hud to the Pilot every few seconds.
		if (!g_bPlayerDisableHUD[iPilot] && GetGameTime() >= view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_PilotHudLastTime)) + 3.0)
		{
			SetHudTextParams(0.01, -1.0, 3.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(iPilot, g_hHudControls, "%s%s%s%s%s%s%s%s%s",
			"(HOLD) Mouse1: (Charged) Laser\n",
			"Mouse2: Bombs\n",
			"HOLD Reload + Left/Right: Tilt\n",
			"2x Reload: Barrel Roll\n",
			"HOLD Jump: Boost\n",
			"HOLD Crouch: Brake\n",
			"Back + Jump: Somersault\n",
			"Back + Crouch: U-Turn\n",
			"2x Crouch: Toggle HUD");
			SetArrayCell(g_hArwings, iIndex, GetGameTime(), Arwing_PilotHudLastTime);
		}
	}
	
	SetEntPropEnt(iArwing, Prop_Data, "m_hPhysicsAttacker", iPilot); // for the kill credit
	SetEntPropFloat(iArwing, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
	
	int iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (iButtons & IN_ATTACK)
	{
		float flStartChargeTime = view_as<float>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserStartTime));
		if (flStartChargeTime > 0.0 && GetGameTime() >= flStartChargeTime)
		{
			ArwingStartChargedLaser(iArwing);
		}
		
		int iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
		if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE)
		{
			int iChargedIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
			if (iChargedIndex != -1)
			{
				bool bOldChargedLaserReady = view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserReady));
				bool bChargedLaserReady = bOldChargedLaserReady;
				
				if (!bOldChargedLaserReady)
				{
					if (view_as<bool>(GetArrayCell(g_hChargedLasers, iChargedIndex, ChargedLaser_IsCharging)) &&
						GetGameTime() >= view_as<float>(GetArrayCell(g_hChargedLasers, iChargedIndex, ChargedLaser_ChargeEndTime)))
					{
						bChargedLaserReady = true;
						SetArrayCell(g_hArwings, iIndex, true, Arwing_ChargedLaserReady);
					}
				}
				
				int iTarget = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
				if (!ChargedLaserCanTrackTarget(iChargedLaser, iTarget))
				{
					iTarget = INVALID_ENT_REFERENCE;
					RemoveAllTargetReticlesFromEntity(iArwing, true);
					SetArrayCell(g_hArwings, iIndex, INVALID_ENT_REFERENCE, Arwing_Target);
					SetArrayCell(g_hChargedLasers, iChargedIndex, INVALID_ENT_REFERENCE, ChargedLaser_Target);
				}
				
				if (bChargedLaserReady)
				{
					// Emit sound to client that we're ready to target!
					if (!bOldChargedLaserReady)
					{
						if (IsValidClient(iPilot))
						{
							char sPath[PLATFORM_MAX_PATH];
							if (GetRandomStringFromArwingConfig(hConfig, "sound_targeting_ready", sPath, sizeof(sPath)) && sPath[0])
							{
								EmitSoundToClient(iPilot, sPath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
							}
						}
					}
				
					float flArwingPos[3], flArwingAng[3];
					GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
					GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
					
					if (!iTarget || iTarget == INVALID_ENT_REFERENCE)
					{
						float flEndPos[3];
						GetAngleVectors(flArwingAng, flEndPos, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(flEndPos, flEndPos);
						ScaleVector(flEndPos, 6000.0);
						AddVectors(flEndPos, flArwingPos, flEndPos);
					
						Handle hTrace = TR_TraceRayFilterEx(flArwingPos, flEndPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayArwingTargeting, iArwing);
						bool bHit = TR_DidHit(hTrace);
						int iHitEntity = TR_GetEntityIndex(hTrace);
						CloseHandle(hTrace);
						
						if (bHit && iHitEntity && IsValidEntity(iHitEntity))
						{
							if (ChargedLaserCanTrackTarget(iChargedLaser, iHitEntity))
							{
								if (ChargedLaserCanTrackTarget(iChargedLaser, iHitEntity))
								{
									SetArrayCell(g_hArwings, iIndex, EntIndexToEntRef(iHitEntity), Arwing_Target);
									SetArrayCell(g_hChargedLasers, iChargedIndex, EntIndexToEntRef(iHitEntity), ChargedLaser_Target);
									
									if (IsValidClient(iPilot))
									{
										if (hConfig != INVALID_HANDLE)
										{
											KvRewind(hConfig);
											if (KvJumpToKey(hConfig, "reticles") && KvGotoFirstSubKey(hConfig))
											{
												char sType[64], sMaterial[PLATFORM_MAX_PATH];
												float flTargetPos[3];
												VehicleGetAbsOrigin(iHitEntity, flTargetPos);
												
												int iReticle, iColor[4];
												
												do
												{
													KvGetString(hConfig, "type", sType, sizeof(sType));
													if (StrEqual(sType, "lockon"))
													{
														KvGetString(hConfig, "model", sMaterial, sizeof(sMaterial));
														if (sMaterial[0])
														{
															iReticle = SpawnTargetReticle(sMaterial, flTargetPos, NULL_VECTOR, NULL_VECTOR, iArwing, KvGetFloat(hConfig, "scale", 1.0), true);
															if (iReticle != -1)
															{
																SetVariantString("!activator");
																AcceptEntityInput(iReticle, "SetParent", iHitEntity);
																
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
											
											
											char sPath[PLATFORM_MAX_PATH];
											if (GetRandomStringFromArwingConfig(hConfig, "sound_targeted_enemy", sPath, sizeof(sPath)) && sPath[0])
											{
												EmitSoundToClient(iPilot, sPath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}