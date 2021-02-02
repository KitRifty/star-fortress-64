#if defined _sf64_proj_chargedlaser_included
  #endinput
#endif
#define _sf64_proj_chargedlaser_included

#define ARWING_CHARGEDLASER_HIT_PARTICLE_RED "drg_cow_explosioncore_charged"
#define ARWING_CHARGEDLASER_HIT_PARTICLE_BLUE "drg_cow_explosioncore_charged_blue"
#define ARWING_CHARGEDLASER_HIT_SOUND "arwing/pulselaserexplode.mp3"
#define ARWING_CHARGEDLASER_TRAIL_MATERIAL "sprites/laserbeam.vmt"
#define ARWING_CHARGEDLASER_TRAIL_LIFETIME 0.1
#define ARWING_CHARGEDLASER_TRAIL_STARTWIDTH 32.0
#define ARWING_CHARGEDLASER_TRAIL_ENDWIDTH 16.0
#define ARWING_CHARGEDLASER_SMOKESTACK_MATERIAL "sprites/light_glow02_add.vmt"


SpawnChargedLaser(const Float:flPos[3],
	const Float:flAng[3],
	const Float:flVelocity[3],
	iTeam,
	iOwner,
	iTarget,
	Float:flDamage=150.0,
	Float:flDamageRadius=512.0,
	Float:flLifeTime=5.0,
	Float:flMaxSpeed=2500.0,
	Float:flTrackDuration=4.0,
	bool:bCharging=false,
	Float:flChargeTime=0.75,
	&iIndex=-1)
{
	new iChargedLaser = CreateEntityByName("tf_projectile_energy_ring");
	if (iChargedLaser != -1)
	{
		SetEntPropEnt(iChargedLaser, Prop_Send, "m_hOwnerEntity", iOwner);
		DispatchSpawn(iChargedLaser);
		ActivateEntity(iChargedLaser);
		SetEntityMoveType(iChargedLaser, MOVETYPE_FLY);
		SetEntityRenderMode(iChargedLaser, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iChargedLaser, 0, 0, 0, 1);
		SetEntProp(iChargedLaser, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iChargedLaser, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		new iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_CHARGEDLASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt, "renderamt", "255");
			DispatchKeyValue(iTrailEnt, "rendermode", "5");
			
			if (iTeam == _:TFTeam_Red) 
			{
				DispatchKeyValue(iTrailEnt, "rendercolor", "255 0 0");
			}
			else 
			{
				DispatchKeyValue(iTrailEnt, "rendercolor", "0 50 255");
			}
			
			DispatchKeyValueFloat(iTrailEnt, "lifetime", ARWING_CHARGEDLASER_TRAIL_LIFETIME);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", ARWING_CHARGEDLASER_TRAIL_STARTWIDTH);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", ARWING_CHARGEDLASER_TRAIL_ENDWIDTH);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iChargedLaser);
		}
		
		new iSmoke = CreateEntityByName("env_smokestack");
		if (iSmoke != -1)
		{
			DispatchKeyValue(iSmoke, "SmokeMaterial", ARWING_CHARGEDLASER_SMOKESTACK_MATERIAL);
			DispatchKeyValue(iSmoke, "StartSize", "300");
			DispatchKeyValue(iSmoke, "EndSize", "100");
			DispatchKeyValue(iSmoke, "BaseSpread", "0");
			DispatchKeyValue(iSmoke, "Roll", "50");
			DispatchKeyValue(iSmoke, "JetLength", "10");
			DispatchKeyValue(iSmoke, "SpreadSpeed", "50");
			DispatchKeyValue(iSmoke, "Speed", "50");
			DispatchKeyValue(iSmoke, "Rate", "74");
			DispatchKeyValue(iSmoke, "renderamt", "255");
			DispatchKeyValue(iSmoke, "rendermode", "5");
			
			if (iTeam == _:TFTeam_Red) 
			{
				DispatchKeyValue(iSmoke, "rendercolor", "255 150 150");
			}
			else 
			{
				DispatchKeyValue(iSmoke, "rendercolor", "150 150 255");
			}
			
			DispatchSpawn(iSmoke);
			ActivateEntity(iSmoke);
			SetVariantString("!activator");
			AcceptEntityInput(iSmoke, "SetParent", iChargedLaser);
			SetEdictFlags(iSmoke, FL_EDICT_ALWAYS);
		}
		
		new iSmoke2 = CreateEntityByName("env_smokestack");
		if (iSmoke2 != -1)
		{
			DispatchKeyValue(iSmoke2, "SmokeMaterial", ARWING_CHARGEDLASER_SMOKESTACK_MATERIAL);
			DispatchKeyValue(iSmoke2, "StartSize", "500");
			DispatchKeyValue(iSmoke2, "EndSize", "500");
			DispatchKeyValue(iSmoke2, "BaseSpread", "0");
			DispatchKeyValue(iSmoke2, "Roll", "50");
			DispatchKeyValue(iSmoke2, "JetLength", "10");
			DispatchKeyValue(iSmoke2, "SpreadSpeed", "50");
			DispatchKeyValue(iSmoke2, "Speed", "200");
			DispatchKeyValue(iSmoke2, "Rate", "20");
			DispatchKeyValue(iSmoke2, "renderamt", "255");
			DispatchKeyValue(iSmoke2, "rendermode", "5");
			
			if (iTeam == _:TFTeam_Red) 
			{
				DispatchKeyValue(iSmoke2, "rendercolor", "255 70 70");
			}
			else 
			{
				DispatchKeyValue(iSmoke2, "rendercolor", "70 70 255");
			}
			
			DispatchSpawn(iSmoke2);
			ActivateEntity(iSmoke2);
			AcceptEntityInput(iSmoke2, "TurnOn");
			SetVariantString("!activator");
			AcceptEntityInput(iSmoke2, "SetParent", iChargedLaser);
			SetEdictFlags(iSmoke2, FL_EDICT_ALWAYS);
		}
		
		new iSmoke3 = CreateEntityByName("env_smokestack");
		if (iSmoke3 != -1)
		{
			DispatchKeyValue(iSmoke3, "SmokeMaterial", ARWING_CHARGEDLASER_SMOKESTACK_MATERIAL);
			DispatchKeyValue(iSmoke3, "StartSize", "20");
			DispatchKeyValue(iSmoke3, "EndSize", "0");
			DispatchKeyValue(iSmoke3, "BaseSpread", "0");
			DispatchKeyValue(iSmoke3, "Roll", "50");
			DispatchKeyValue(iSmoke3, "JetLength", "10");
			DispatchKeyValue(iSmoke3, "SpreadSpeed", "50");
			DispatchKeyValue(iSmoke3, "Speed", "20");
			DispatchKeyValue(iSmoke3, "Rate", "70");
			DispatchKeyValue(iSmoke3, "renderamt", "255");
			DispatchKeyValue(iSmoke3, "rendermode", "5");
			
			if (iTeam == _:TFTeam_Red) 
			{
				DispatchKeyValue(iSmoke3, "rendercolor", "255 150 150");
			}
			else 
			{
				DispatchKeyValue(iSmoke3, "rendercolor", "150 150 255");
			}
			
			DispatchSpawn(iSmoke3);
			ActivateEntity(iSmoke3);
			SetVariantString("!activator");
			AcceptEntityInput(iSmoke3, "SetParent", iChargedLaser);
			SetEdictFlags(iSmoke3, FL_EDICT_ALWAYS);
		}
		
		DispatchKeyValue(iChargedLaser, "classname", "sf64_projectile_pulselaser");
		
		iIndex = PushArrayCell(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
		SetArrayCell(g_hChargedLasers, iIndex, GetGameTime(), ChargedLaser_LastSpawnTime);
		SetArrayCell(g_hChargedLasers, iIndex, flLifeTime, ChargedLaser_LifeTime);
		SetArrayCell(g_hChargedLasers, iIndex, flMaxSpeed, ChargedLaser_MaxSpeed);
		SetArrayCell(g_hChargedLasers, iIndex, flDamage, ChargedLaser_Damage);
		SetArrayCell(g_hChargedLasers, iIndex, flDamageRadius, ChargedLaser_DamageRadius);
		SetArrayCell(g_hChargedLasers, iIndex, iTeam, ChargedLaser_Team);
		SetArrayCell(g_hChargedLasers, iIndex, IsValidEntity(iOwner) ? EntIndexToEntRef(iOwner) : INVALID_ENT_REFERENCE, ChargedLaser_Owner);
		SetArrayCell(g_hChargedLasers, iIndex, IsValidEntity(iTarget) ? EntIndexToEntRef(iTarget) : INVALID_ENT_REFERENCE, ChargedLaser_Target);
		SetArrayCell(g_hChargedLasers, iIndex, bCharging, ChargedLaser_IsCharging);
		SetArrayCell(g_hChargedLasers, iIndex, false, ChargedLaser_Hit);
		
		SetArrayCell(g_hChargedLasers, iIndex, flTrackDuration, ChargedLaser_TrackDuration);
		
		SetArrayCell(g_hChargedLasers, iIndex, IsValidEntity(iSmoke) ? EntIndexToEntRef(iSmoke) : INVALID_ENT_REFERENCE, ChargedLaser_TrailEnt1);
		SetArrayCell(g_hChargedLasers, iIndex, INVALID_ENT_REFERENCE, ChargedLaser_TrailEnt2);
		SetArrayCell(g_hChargedLasers, iIndex, IsValidEntity(iSmoke3) ? EntIndexToEntRef(iSmoke3) : INVALID_ENT_REFERENCE, ChargedLaser_TrailEnt3);
		
		TeleportEntity(iChargedLaser, flPos, flAng, flVelocity);
		SDKHook(iChargedLaser, SDKHook_StartTouchPost, Hook_ChargedLaserStartTouchPost);
		CreateTimer(0.0001, Timer_ChargedLaserThink, EntIndexToEntRef(iChargedLaser), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		if (bCharging) StartChargingChargedLaser(iChargedLaser, flChargeTime, true);
		else ReleaseChargedLaser(iChargedLaser, true);
	}
	
	return iChargedLaser;
}

public ChargedLaserOnEntityDestroyed(entity)
{
	if (GetArraySize(g_hChargedLasers) > 0)
	{
		new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(entity));
		if (iIndex != -1)
		{
			if (bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Hit))
			{
				new iParticleChargedLaser = PrecacheParticleSystem(ARWING_CHARGEDLASER_HIT_PARTICLE_BLUE);
				if (GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Team) == _:TFTeam_Red)
				{
					iParticleChargedLaser = PrecacheParticleSystem(ARWING_CHARGEDLASER_HIT_PARTICLE_RED);
				}
				
				decl Float:flPos[3];
				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flPos);
				
				TE_SetupTFParticleEffect(iParticleChargedLaser, flPos, flPos);
				TE_SendToAll();
				
				new iExplode = CreateEntityByName("env_explosion");
				if (iExplode != -1)
				{
					SetEntProp(iExplode, Prop_Data, "m_spawnflags", 4 + 8 + 16 + 32 + 64 + 256 + 512 + 1024);
					SetEntProp(iExplode, Prop_Data, "m_iMagnitude", RoundToFloor(Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Damage)));
					SetEntProp(iExplode, Prop_Data, "m_iRadiusOverride", RoundToFloor(Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_DamageRadius)));
					DispatchSpawn(iExplode);
					ActivateEntity(iExplode);
					TeleportEntity(iExplode, flPos, NULL_VECTOR, NULL_VECTOR);
					SetEntPropEnt(iExplode, Prop_Send, "m_hOwnerEntity", EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Owner)));
					AcceptEntityInput(iExplode, "Explode");
				}
				
				new iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt1));
				if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(iSmoke, "TurnOff");
					AcceptEntityInput(iSmoke, "ClearParent");
					TeleportEntity(iSmoke, flPos, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
					DeleteEntity(iSmoke, (GetEntPropFloat(iSmoke, Prop_Send, "m_JetLength") / GetEntPropFloat(iSmoke, Prop_Send, "m_Speed")));
				}
				
				iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt2));
				if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(iSmoke, "TurnOff");
					AcceptEntityInput(iSmoke, "ClearParent");
					TeleportEntity(iSmoke, flPos, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
					DeleteEntity(iSmoke, (GetEntPropFloat(iSmoke, Prop_Send, "m_JetLength") / GetEntPropFloat(iSmoke, Prop_Send, "m_Speed")));
				}
				
				iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt3));
				if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(iSmoke, "TurnOff");
					AcceptEntityInput(iSmoke, "ClearParent");
					TeleportEntity(iSmoke, flPos, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
					DeleteEntity(iSmoke, (GetEntPropFloat(iSmoke, Prop_Send, "m_JetLength") / GetEntPropFloat(iSmoke, Prop_Send, "m_Speed")));
				}
				
				EmitSoundToAll(ARWING_CHARGEDLASER_HIT_SOUND, entity, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
			}
			
			RemoveFromArray(g_hChargedLasers, iIndex);
		}
	}
}

public Hook_ChargedLaserStartTouchPost(iChargedLaser, other)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsCharging))
	{
		new iOwner = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Owner));
		
		new bool:bHit = false;
		
		if (iOwner && iOwner != other)
		{
			new iOtherEntRef = EntIndexToEntRef(other);
			new iOtherIndex = FindValueInArray(g_hArwings, iOtherEntRef);
			if (iOtherIndex != -1)
			{
				if (EntRefToEntIndex(GetArrayCell(g_hArwings, iOtherIndex, Arwing_Pilot)) != iOwner)
				{
					bHit = true;
				}
			}
			else if (IsValidClient(other))
			{
				bHit = true;
			}
			else
			{
				bHit = true;
			}
		}
		
		if (bHit) 
		{
			SetArrayCell(g_hChargedLasers, iIndex, true, ChargedLaser_Hit);
			DeleteEntity(iChargedLaser);
		}
	}
}

bool:ChargedLaserCanTrackTarget(iChargedLaser, iTarget)
{
	if (!IsValidEntity(iChargedLaser) || !IsValidEntity(iTarget)) return false;
	
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return false;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Owner));
	new iOwnerVehicle = GetCurrentVehicle(iOwner);
	
	if (!VehicleCanTarget(iOwnerVehicle, iTarget)) return false;
	
	decl Float:flOwnerPos[3], Float:flOwnerAng[3];
	VehicleGetAbsOrigin(iOwnerVehicle, flOwnerPos);
	VehicleGetAbsAngles(iOwnerVehicle, flOwnerAng);
	
	decl Float:flTargetPos[3];
	VehicleGetOBBCenter(iTarget, flTargetPos);
	
	if (!IsPointWithinFOV(flOwnerPos, flOwnerAng, 180.0, flTargetPos)) return false;
	
	new Handle:hTrace = TR_TraceRayFilterEx(flOwnerPos, flTargetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceRayArwingTargeting, iOwnerVehicle);
	new iHitEntity = TR_GetEntityIndex(hTrace);
	new bool:bHit = TR_DidHit(hTrace);
	CloseHandle(hTrace);
	
	if (bHit && iHitEntity != iTarget) return false;
	
	return true;
}

public Action:Timer_ChargedLaserThink(Handle:timer, any:entref)
{
	new iChargedLaser = EntRefToEntIndex(entref);
	if (!iChargedLaser || iChargedLaser == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hChargedLasers, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (!bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsCharging))
	{
		new iTarget = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_Target));
		if (ChargedLaserCanTrackTarget(iChargedLaser, iTarget))
		{
			decl Float:flPos[3], Float:flVelocity[3];
			GetEntPropVector(iChargedLaser, Prop_Data, "m_vecAbsOrigin", flPos);
			GetEntPropVector(iChargedLaser, Prop_Data, "m_vecAbsVelocity", flVelocity);
			
			decl Float:flGoalVelocity[3];
			if (GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsTracking))
			{
				decl Float:flTargetPos[3];
				GetEntPropVector(iTarget, Prop_Data, "m_vecAbsOrigin", flTargetPos);
				SubtractVectors(flTargetPos, flPos, flGoalVelocity);
			}
			else
			{
				CopyVectors(flVelocity, flGoalVelocity);
			}
			
			NormalizeVector(flGoalVelocity, flGoalVelocity);
			ScaleVector(flGoalVelocity, Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_MaxSpeed));
			
			decl Float:flNewVelocity[3];
			LerpVectors(flVelocity, flGoalVelocity, flNewVelocity, 0.25);
			TeleportEntity(iChargedLaser, NULL_VECTOR, NULL_VECTOR, flNewVelocity);
		}
		else
		{
			SetArrayCell(g_hChargedLasers, iIndex, INVALID_ENT_REFERENCE, ChargedLaser_Target);
		}
	}
	else
	{
		new Float:flFinishTime = Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_ChargeEndTime);
		if (flFinishTime > 0.0 && GetGameTime() >= flFinishTime)
		{
			SetArrayCell(g_hChargedLasers, iIndex, -1.0, ChargedLaser_ChargeEndTime);
			FinishChargingChargedLaser(iChargedLaser);
		}
	}
	
	return Plugin_Continue;
}

StartChargingChargedLaser(iChargedLaser, Float:flChargeTime, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bForce && bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsCharging)) return;
	
	SetArrayCell(g_hChargedLasers, iIndex, true, ChargedLaser_IsCharging);
	SetArrayCell(g_hChargedLasers, iIndex, GetGameTime(), ChargedLaser_ChargeStartTime);
	SetArrayCell(g_hChargedLasers, iIndex, GetGameTime() + flChargeTime, ChargedLaser_ChargeEndTime);
	
	StopTrackingOnChargedLaser(iChargedLaser, true);
	
	SetEntityMoveType(iChargedLaser, MOVETYPE_NONE);
	
	new iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt1));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOff");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt2));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt3));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
}

FinishChargingChargedLaser(iChargedLaser, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bForce && !bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsCharging)) return;
	
	SetArrayCell(g_hChargedLasers, iIndex, true, ChargedLaser_IsCharging);
	StopTrackingOnChargedLaser(iChargedLaser, true);
	
	SetEntityMoveType(iChargedLaser, MOVETYPE_NONE);
	
	new iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt1));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt2));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt3));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
}

ReleaseChargedLaser(iChargedLaser, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bForce && !bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsCharging)) return;
	
	SetArrayCell(g_hChargedLasers, iIndex, false, ChargedLaser_IsCharging);
	StartTrackingOnChargedLaser(iChargedLaser, true);
	
	AcceptEntityInput(iChargedLaser, "ClearParent");
	SetEntityMoveType(iChargedLaser, MOVETYPE_FLY);
	
	new iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt1));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt2));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	iSmoke = EntRefToEntIndex(GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrailEnt3));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iSmoke, "TurnOn");
	}
	
	DeleteEntity(iChargedLaser, Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_LifeTime));
}

StartTrackingOnChargedLaser(iChargedLaser, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bForce && bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsTracking)) return;
	
	SetArrayCell(g_hChargedLasers, iIndex, true, ChargedLaser_IsTracking);
	SetArrayCell(g_hChargedLasers, iIndex, GetGameTime(), ChargedLaser_TrackStartTime);
	SetArrayCell(g_hChargedLasers, iIndex, GetGameTime() + Float:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_TrackDuration), ChargedLaser_TrackEndTime);
}

StopTrackingOnChargedLaser(iChargedLaser, bool:bForce=false)
{
	new iIndex = FindValueInArray(g_hChargedLasers, EntIndexToEntRef(iChargedLaser));
	if (iIndex == -1) return;
	
	if (!bForce && !bool:GetArrayCell(g_hChargedLasers, iIndex, ChargedLaser_IsTracking)) return;
	
	SetArrayCell(g_hChargedLasers, iIndex, true, ChargedLaser_IsTracking);
	SetArrayCell(g_hChargedLasers, iIndex, 0.0, ChargedLaser_TrackStartTime);
	SetArrayCell(g_hChargedLasers, iIndex, 0.0, ChargedLaser_TrackEndTime);
}