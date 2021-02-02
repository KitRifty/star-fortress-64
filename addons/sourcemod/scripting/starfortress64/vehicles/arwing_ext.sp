#if defined _sf64_arwing_ext_included
  #endinput
#endif
#define _sf64_arwing_ext_included

#define ARWING_HEALTHBAR_MODEL "models/Effects/teleporttrail.mdl"


public ArwingOnEntityDestroyed(entity)
{
	// Check if this entity is our charged laser entity.
	for (new i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
	{
		new iArwing = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
		if (!iArwing || iArwing == INVALID_ENT_REFERENCE) continue;
		
		new iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, i, Arwing_ChargedLaserEnt));
		if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE && iChargedLaser == entity)
		{
			RemoveAllTargetReticlesFromEntity(iArwing, true);
			SetArrayCell(g_hArwings, i, INVALID_ENT_REFERENCE, Arwing_Target);
			break;
		}
	}
	
	if (GetArraySize(g_hArwings) > 0)
	{
		new entref = EntIndexToEntRef(entity);
		new iIndex = FindValueInArray(g_hArwings, entref);
		if (iIndex != -1)
		{
			EjectPilotFromArwing(entity);
			DisableArwing(entity);
			
			decl String:sEntRef[256];
			IntToString(entref, sEntRef, sizeof(sEntRef));
			RemoveFromTrie(g_hArwingNames, sEntRef);
			RemoveFromArray(g_hArwings, iIndex);
			
			DispatchKeyValueFloat(entity, "modelscale", 1.0); // prevent crashing?
		}
	}
}

public ArwingOnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	decl iVehicleType, iIndex;
	GetCurrentVehicle(client, iVehicleType, iIndex);
	
	if (iVehicleType == VehicleType_Arwing)
	{
		if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled))
		{
			if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_IgnorePilotControls))
			{
				SetArrayCell(g_hArwings, iIndex, g_bPlayerInvertedYAxis[client] ? g_flPlayerForwardMove[client] : -g_flPlayerForwardMove[client], Arwing_ForwardMove);
				SetArrayCell(g_hArwings, iIndex, g_bPlayerInvertedXAxis[client] ? -g_flPlayerSideMove[client] :  g_flPlayerSideMove[client], Arwing_SideMove);
			}
		}
	}
}

ArwingPressButton(iArwing, iButton)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;

	new iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (iButtons & iButton) return;
	
	if (GetArrayCell(g_hArwings, iIndex, Arwing_IgnorePilotControls)) return;
	
	iButtons |= iButton;
	SetArrayCell(g_hArwings, iIndex, iButtons, Arwing_Buttons);
	
	new bool:bEnabled = bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled);
	
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
				if (bool:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserReady))
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
				new bool:bFireNew = true;
				
				new iSmartBomb = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombEnt));
				if ((iSmartBomb && iSmartBomb != INVALID_ENT_REFERENCE))
				{
					new iSmartBombIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
					if (iSmartBombIndex != -1 && !bool:GetArrayCell(g_hSBombs, iSmartBombIndex, SBomb_Detonated))
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
				decl Float:flArwingAng[3];
				GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
				
				if (iButtons & IN_BACK && !(iButtons & IN_MOVELEFT) && !(iButtons & IN_MOVERIGHT) && FloatAbs(flArwingAng[2]) <= 45.0 && GetGameTime() < Float:GetArrayCell(g_hArwings, iIndex, Arwing_SomersaultTime))
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
				decl Float:flArwingAng[3];
				GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
			
				if (iButtons & IN_BACK && !(iButtons & IN_MOVELEFT) && !(iButtons & IN_MOVERIGHT) && FloatAbs(flArwingAng[2]) <= 45.0 && GetGameTime() < Float:GetArrayCell(g_hArwings, iIndex, Arwing_UTurnTime))
				{
					ArwingStartUTurn(iArwing);
				}
				else
				{
					ArwingStartBrake(iArwing);
				}
			}
		}
		case IN_RELOAD:
		{
			if (bEnabled)
			{
				ArwingStartTilt(iArwing, Float:GetArrayCell(g_hArwings, iIndex, Arwing_TiltDesiredDirection));
			
				new Float:flBarrelRollStart = Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollStartTime);
				if (flBarrelRollStart < 0.0 || GetGameTime() > flBarrelRollStart)
				{
					SetArrayCell(g_hArwings, iIndex, GetGameTime() + 0.25, Arwing_BarrelRollStartTime);
				}
				else
				{
					ArwingStartBarrelRoll(iArwing, Float:GetArrayCell(g_hArwings, iIndex, Arwing_BarrelRollDesiredDirection));
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

ArwingReleaseButton(iArwing, iButton)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (!(iButtons & iButton)) return;
	
	iButtons &= ~iButton;
	SetArrayCell(g_hArwings, iIndex, iButtons, Arwing_Buttons);
	
	switch (iButton)
	{
		case IN_ATTACK:
		{
			new iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
			if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE)
			{
				new iChargedLaserIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
				if (iChargedLaserIndex != -1)
				{
					if (bool:GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging))
					{
						// Create a kill timer.
						new Handle:hTimer = CreateTimer(0.25, Timer_ArwingChargedLaserKillTimer, EntIndexToEntRef(iArwing), TIMER_FLAG_NO_MAPCHANGE);
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

ArwingReleaseAllButtons(iArwing)
{
	for (new iButton = 0; iButton < MAX_BUTTONS; iButton++)
	{
		ArwingReleaseButton(iArwing, iButton);
	}
}

ArwingFireLasers(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (GetGameTime() < Float:GetArrayCell(g_hArwings, iIndex, Arwing_NextLaserAttackTime)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "laser")) return;
	
	decl Float:flArwingPos[3], Float:flArwingAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	new bool:bCanAutoAim = bool:KvGetNum(hConfig, "autoaim");
	
	decl Float:flArwingLaserAutoAimPos[3];
	KvGetVector(hConfig, "autoaim_pos_offset", flArwingLaserAutoAimPos);
	VectorTransform(flArwingLaserAutoAimPos, flArwingPos, flArwingAng, flArwingLaserAutoAimPos);
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	new iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	new iUpgradeLevel = GetArrayCell(g_hArwings, iIndex, Arwing_LaserUpgradeLevel);
	
	decl String:sType[64];
	decl Float:flPos[3], Float:flVelocity[3];
	
	// Determine the velocity. Implement auto-aim here.
	new bool:bAutoAim = false;
	decl Float:flAutoAimPos[3];
	decl Float:flAutoAimVelocity[3];
	
	if (bCanAutoAim)
	{
		for (new i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
		{
			if (iIndex == i) continue;
			new ent = EntRefToEntIndex(GetArrayCell(g_hArwings, i));
			if (!ent || ent == INVALID_ENT_REFERENCE) continue;
			
			decl Float:flTargetPos[3];
			VehicleGetOBBCenter(ent, flTargetPos);
			
			if (IsPointWithinFOV(flArwingLaserAutoAimPos, flArwingAng, 10.0, flTargetPos))
			{
				GetEntitySmoothedVelocity(ent, flAutoAimVelocity);
				for (new i2 = 0; i2 < 3; i2++) flAutoAimPos[i2] = flTargetPos[i2];
				bAutoAim = true;
				break;
			}
		}
	}
	
	new Float:flLaserSpeed = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LaserSpeed);
	
	if (bAutoAim)
	{
		new Float:flTime = GetVectorDistance(flAutoAimPos, flArwingLaserAutoAimPos) / flLaserSpeed;
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
	
	new iHyperCount;
	
	if (KvGotoFirstSubKey(hConfig))
	{
		new Handle:hArray = CreateArray(64);
		decl String:sSectionName[64];
		
		// We have to store section names in an array because the ArwingSpawnEffects function will change our KeyValue position in hConfig.
		do
		{
			KvGetSectionName(hConfig, sSectionName, sizeof(sSectionName));
			PushArrayString(hArray, sSectionName);
		}
		while (KvGotoNextKey(hConfig));
		
		for (new i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
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
					new bool:bHyper = bool:KvGetNum(hConfig, "hyper");
					new Float:flDamage = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LaserDamage);
					if (bHyper)
					{
						flDamage = Float:GetArrayCell(g_hArwings, iIndex, Arwing_LaserHyperDamage);
					}
				
					KvGetVector(hConfig, "origin", flPos);
					VectorTransform(flPos, flArwingPos, flArwingAng, flPos);
					SpawnLaser(flPos, flArwingAng, flVelocity, iTeam, iOwner, flDamage, Float:GetArrayCell(g_hArwings, iIndex, Arwing_LaserLifeTime), bHyper);
					
					/*
					{
						decl Float:flEndPos[3];
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
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (iHyperCount && GetRandomStringFromArwingConfig(hConfig, "sound_hyperlaser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	else if (GetRandomStringFromArwingConfig(hConfig, "sound_laser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + Float:GetArrayCell(g_hArwings, iIndex, Arwing_LaserCooldown), Arwing_NextLaserAttackTime);
}

ArwingStartChargedLaser(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	if (GetGameTime() < Float:GetArrayCell(g_hArwings, iIndex, Arwing_NextChargedLaserAttackTime)) return;
	
	new iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
	if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "chargedlaser")) return;
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	new iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	new iUpgradeLevel = GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserUpgradeLevel);
	
	decl String:sType[64];
	decl Float:flArwingPos[3], Float:flArwingAng[3];
	decl Float:flPos[3];
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
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserDamage), 
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserDamageRadius), 
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserLifeTime), 
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserSpeed), 
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserTrackDuration), 
						true, 
						Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserChargeDuration));
						
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

public Action:Timer_ArwingChargedLaserKillTimer(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return;
	
	ArwingReleaseChargedLaser(iArwing, true);
}

ArwingReleaseChargedLaser(iArwing, bool:bForceKill=false)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	SetArrayCell(g_hArwings, iIndex, false, Arwing_ChargedLaserReady);
	SetArrayCell(g_hArwings, iIndex, INVALID_HANDLE, Arwing_ChargedLaserKillTimer);
	
	new iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
	if (!iChargedLaser || iChargedLaser == INVALID_ENT_REFERENCE) return;
	
	new iChargedLaserIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iChargedLaserIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging)) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	if (bForceKill || (bool:GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_IsCharging) &&
		GetGameTime() < Float:GetArrayCell(g_hChargedLasers, iChargedLaserIndex, ChargedLaser_ChargeEndTime)))
	{
		RemoveEntity(iChargedLaser);
		return;
	}
	
	decl Float:flPos[3], Float:flVelocity[3];
	GetEntPropVector(iChargedLaser, Prop_Data, "m_vecAbsOrigin", flPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flVelocity);
	GetAngleVectors(flVelocity, flVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(flVelocity, flVelocity);
	ScaleVector(flVelocity, Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserSpeed));
	
	ReleaseChargedLaser(iChargedLaser);
	TeleportEntity(iChargedLaser, flPos, NULL_VECTOR, flVelocity);
	
	SetArrayCell(g_hArwings, iIndex, GetGameTime() + Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserCooldown), Arwing_NextChargedLaserAttackTime)
	
	decl String:sPath[PLATFORM_MAX_PATH];
	if (GetRandomStringFromArwingConfig(hConfig, "sound_chargedlaser_single", sPath, sizeof(sPath)) && sPath[0])
	{
		EmitSoundToAll(sPath, iArwing, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
}

ArwingFireSmartBomb(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iSmartBomb = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombEnt));
	if ((iSmartBomb && iSmartBomb != INVALID_ENT_REFERENCE))
	{
		new iSmartBombIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
		if (iSmartBombIndex != -1 && !bool:GetArrayCell(g_hSBombs, iSmartBombIndex, SBomb_Detonated))
		{
			// can't fire a bomb if we already have one out.
			return;
		}
	}
	
	new iNumSmartBombs = GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombNum);
	if (!GetConVarBool(g_cvInfiniteBombs) && iNumSmartBombs <= 0) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	KvRewind(hConfig);
	if (!KvJumpToKey(hConfig, "weapons") || !KvJumpToKey(hConfig, "types") || !KvJumpToKey(hConfig, "smartbomb")) return;
	
	KvRewind(hConfig);
	KvJumpToKey(hConfig, "weapons");
	if (!KvJumpToKey(hConfig, "positions")) return;
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	new iTarget = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
	new iTeam = GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	new Float:flSmartBombDamage = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombDamage);
	new Float:flSmartBombDamageRadius = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombDamageRadius);
	new Float:flSmartBombLifeTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombLifeTime);
	new Float:flSmartBombMaxSpeed = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombMaxSpeed);
	new Float:flSmartBombTrackDuration = Float:GetArrayCell(g_hArwings, iIndex, Arwing_SmartBombTrackDuration);
	
	decl Float:flArwingPos[3], Float:flArwingAng[3], Float:flPos[3], Float:flAng[3];
	GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
	
	if (KvGotoFirstSubKey(hConfig))
	{
		decl String:sType[64];
	
		do
		{
			KvGetString(hConfig, "type", sType, sizeof(sType));
			if (StrEqual(sType, "smartbomb"))
			{
				KvGetVector(hConfig, "origin", flPos);
				VectorTransform(flPos, flArwingPos, flArwingAng, flPos);
				CopyVectors(flArwingAng, flAng);
				flAng[2] = 0.0;
				
				decl Float:flVelocity[3];
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

ArwingUpdateHealthBar(iArwing)
{
	new iIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iArwing));
	if (iIndex == -1) return;
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	if (!IsValidClient(iPilot) || IsFakeClient(iPilot)) return;
	
	// No camera entity? *middle finger*
	new iCamera = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_CameraEnt));
	if (!iCamera || iCamera == INVALID_ENT_REFERENCE) return;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	if (hConfig == INVALID_HANDLE) return;
	
	decl Float:flHealthBarStartEntityPosOffset[3], Float:flHealthBarEndEntityStartPosOffset[3];
	new Float:flStartWidth, Float:flEndWidth;
	
	new bool:bFoundHealthBar = false;
	
	// Search through all my stored hud elements to see if the health range matches.
	KvRewind(hConfig);
	if (KvJumpToKey(hConfig, "hudelements") && KvGotoFirstSubKey(hConfig))
	{
		decl String:sHudElementType[64];
	
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
	
	decl Float:flCameraPos[3], Float:flCameraAng[3];
	GetEntPropVector(iCamera, Prop_Data, "m_vecAbsOrigin", flCameraPos);
	GetEntPropVector(iCamera, Prop_Data, "m_angAbsRotation", flCameraAng);
	
	// No health bar entities? Create them, for Pete's sake!
	new iHealthBarStartEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarStartEntity));
	new iHealthBarEndEntity = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_HealthBarEndEntity));
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
	
	decl Float:flHealthBarEndEntityPosOffset[3];
	
	new Float:flHealthRatio = float(GetArrayCell(g_hArwings, iIndex, Arwing_Health)) / float(GetArrayCell(g_hArwings, iIndex, Arwing_MaxHealth));
	new Float:flLength = GetVectorDistance(flHealthBarStartEntityPosOffset, flHealthBarEndEntityStartPosOffset) * flHealthRatio;
	
	SubtractVectors(flHealthBarEndEntityStartPosOffset, flHealthBarStartEntityPosOffset, flHealthBarEndEntityPosOffset);
	NormalizeVector(flHealthBarEndEntityPosOffset, flHealthBarEndEntityPosOffset);
	ScaleVector(flHealthBarEndEntityPosOffset, flLength);
	AddVectors(flHealthBarStartEntityPosOffset, flHealthBarEndEntityPosOffset, flHealthBarEndEntityPosOffset);
	
	TeleportEntity(iHealthBarEndEntity, flHealthBarEndEntityPosOffset, NULL_VECTOR, NULL_VECTOR);
	
	// Positions set. Now we need to determine which material to show to our client.
	// Parse through our config again.
	
	// Assuming no other functions between here and the last place we parsed the
	// config, we should still be within the correct KeyValues tree position.
	
	new Float:flMinHealthRange, Float:flMaxHealthRange;
	
	new iModelIndex = -1;
	
	// Parse through all the ranges in our hud element to get the right one to use.
	if (KvJumpToKey(hConfig, "ranges") && KvGotoFirstSubKey(hConfig))
	{
		do
		{
			flMinHealthRange = KvGetFloat(hConfig, "range_min");
			flMaxHealthRange = KvGetFloat(hConfig, "range_max");
			
			if (flHealthRatio > flMinHealthRange && flHealthRatio <= flMaxHealthRange)
			{
				decl String:sHudElementMaterial[PLATFORM_MAX_PATH];
				KvGetString(hConfig, "material", sHudElementMaterial, sizeof(sHudElementMaterial));
				
				iModelIndex = PrecacheModel(sHudElementMaterial);
				break;
			}
		}
		while KvGotoNextKey(hConfig);
	}
	
	if (iModelIndex == -1) return; // No material; we're done here.
	
	if (!bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled)) return;
	
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

public Action:Timer_ArwingThink(Handle:timer, any:entref)
{
	new iArwing = EntRefToEntIndex(entref);
	if (!iArwing || iArwing == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hArwings, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	new Handle:hConfig = GetConfigOfArwing(iArwing);
	
	new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	
	if (IsValidClient(iPilot))
	{
		ArwingUpdateHealthBar(iArwing);
	}
	
	SetEntPropEnt(iArwing, Prop_Data, "m_hPhysicsAttacker", iPilot); // for the kill credit
	SetEntPropFloat(iArwing, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
	
	new iButtons = GetArrayCell(g_hArwings, iIndex, Arwing_Buttons);
	if (iButtons & IN_ATTACK)
	{
		new Float:flStartChargeTime = Float:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserStartTime);
		if (flStartChargeTime > 0.0 && GetGameTime() >= flStartChargeTime)
		{
			ArwingStartChargedLaser(iArwing);
		}
		
		new iChargedLaser = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserEnt));
		if (iChargedLaser && iChargedLaser != INVALID_ENT_REFERENCE)
		{
			new iChargedIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
			if (iChargedIndex != -1)
			{
				new bool:bOldChargedLaserReady = bool:GetArrayCell(g_hArwings, iIndex, Arwing_ChargedLaserReady);
				new bool:bChargedLaserReady = bOldChargedLaserReady;
				
				if (!bOldChargedLaserReady)
				{
					if (bool:GetArrayCell(g_hChargedLasers, iChargedIndex, ChargedLaser_IsCharging) &&
						GetGameTime() >= Float:GetArrayCell(g_hChargedLasers, iChargedIndex, ChargedLaser_ChargeEndTime))
					{
						bChargedLaserReady = true;
						SetArrayCell(g_hArwings, iIndex, true, Arwing_ChargedLaserReady);
					}
				}
				
				new iTarget = EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
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
							decl String:sPath[PLATFORM_MAX_PATH];
							if (GetRandomStringFromArwingConfig(hConfig, "sound_targeting_ready", sPath, sizeof(sPath)) && sPath[0])
							{
								EmitSoundToClient(iPilot, sPath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
							}
						}
					}
				
					decl Float:flArwingPos[3], Float:flArwingAng[3];
					GetEntPropVector(iArwing, Prop_Data, "m_vecAbsOrigin", flArwingPos);
					GetEntPropVector(iArwing, Prop_Data, "m_angAbsRotation", flArwingAng);
					
					if (!iTarget || iTarget == INVALID_ENT_REFERENCE)
					{
						decl Float:flEndPos[3];
						GetAngleVectors(flArwingAng, flEndPos, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(flEndPos, flEndPos);
						ScaleVector(flEndPos, 6000.0);
						AddVectors(flEndPos, flArwingPos, flEndPos);
					
						new Handle:hTrace = TR_TraceRayFilterEx(flArwingPos, flEndPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayArwingTargeting, iArwing);
						new bool:bHit = TR_DidHit(hTrace);
						new iHitEntity = TR_GetEntityIndex(hTrace);
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
												decl String:sType[64], String:sMaterial[PLATFORM_MAX_PATH];
												decl Float:flTargetPos[3];
												VehicleGetAbsOrigin(iHitEntity, flTargetPos);
												
												decl iReticle, iColor[4];
												
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
											
											
											decl String:sPath[PLATFORM_MAX_PATH];
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