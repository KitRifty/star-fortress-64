#if defined _sf64_proj_smartbomb_included
  #endinput
#endif
#define _sf64_proj_smartbomb_included

#define ARWING_SMARTBOMB_MODEL "models/tokens/bomb.mdl"
#define ARWING_SMARTBOMB_TRAIL_MATERIAL "sprites/light_glow02_add.vmt"
#define ARWING_SMARTBOMB_FLY_SOUND "arwing/pickups/smartbomb/smartbomb_fly.wav"
#define ARWING_SMARTBOMB_DETONATE_SOUND "arwing/pickups/smartbomb/smartbomb_detonate.mp3"
#define ARWING_SMARTBOMB_EXPLOSION_MATERIAL "sprites/light_glow02_add.vmt"
#define ARWING_SMARTBOMB_TRAIL_LIFETIME 0.1
#define ARWING_SMARTBOMB_TRAIL_STARTWIDTH 32.0
#define ARWING_SMARTBOMB_TRAIL_ENDWIDTH 16.0

void PrecacheSmartBomb()
{
	PrecacheModel2(ARWING_SMARTBOMB_MODEL);
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vtf");
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vmt");
	
	PrecacheSound2(ARWING_SMARTBOMB_FLY_SOUND);
	PrecacheSound2(ARWING_SMARTBOMB_DETONATE_SOUND);
}

int SpawnSmartBomb(const float flPos[3],
	const float flAng[3],
	const float flVelocity[3],
	int iTeam,
	int iOwner,
	int iTarget,
	float flDamage=150.0,
	float flDamageRadius=512.0,
	float flLifeTime=5.0,
	float flMaxSpeed=2500.0,
	float flTrackDuration=4.0,
	int &iIndex=-1)
{
	int iSmartBomb = CreateEntityByName("prop_dynamic_override");
	if (iSmartBomb != -1)
	{
		SetEntityModel(iSmartBomb, ARWING_SMARTBOMB_MODEL);
		DispatchKeyValue(iSmartBomb, "solid", "2");
		DispatchSpawn(iSmartBomb);
		ActivateEntity(iSmartBomb);
		SetEntityMoveType(iSmartBomb, MOVETYPE_FLY);
		SetEntProp(iSmartBomb, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iSmartBomb, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		int iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt, "renderamt", "255");
			DispatchKeyValue(iTrailEnt, "rendermode", "5");
			
			if (iTeam == view_as<int>(TFTeam_Red)) 
			{
				DispatchKeyValue(iTrailEnt, "rendercolor", "255 0 0");
			}
			else 
			{
				DispatchKeyValue(iTrailEnt, "rendercolor", "0 50 255");
			}
			
			DispatchKeyValueFloat(iTrailEnt, "lifetime", ARWING_SMARTBOMB_TRAIL_LIFETIME);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", ARWING_SMARTBOMB_TRAIL_STARTWIDTH);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", ARWING_SMARTBOMB_TRAIL_ENDWIDTH);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iSmartBomb);
		}
		
		int iSmoke = CreateEntityByName("env_smokestack");
		if (iSmoke != -1)
		{
			DispatchKeyValue(iSmoke, "SmokeMaterial", ARWING_SMARTBOMB_TRAIL_MATERIAL);
			DispatchKeyValue(iSmoke, "StartSize", "64");
			DispatchKeyValue(iSmoke, "EndSize", "20");
			DispatchKeyValue(iSmoke, "BaseSpread", "0");
			DispatchKeyValue(iSmoke, "Roll", "50");
			DispatchKeyValue(iSmoke, "JetLength", "10");
			DispatchKeyValue(iSmoke, "SpreadSpeed", "50");
			DispatchKeyValue(iSmoke, "Speed", "50");
			DispatchKeyValue(iSmoke, "Rate", "30");
			DispatchKeyValue(iSmoke, "renderamt", "255");
			DispatchKeyValue(iSmoke, "rendermode", "5");
			
			if (iTeam == view_as<int>(TFTeam_Red)) 
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
			AcceptEntityInput(iSmoke, "SetParent", iSmartBomb);
			AcceptEntityInput(iSmoke, "TurnOn");
			SetEdictFlags(iSmoke, FL_EDICT_ALWAYS);
		}
		
		DispatchKeyValue(iSmoke, "classname", "sf64_projectile_bomb");
		
		iIndex = PushArrayCell(g_hSBombs, EntIndexToEntRef(iSmartBomb));
		SetArrayCell(g_hSBombs, iIndex, GetGameTime(), SBomb_LastSpawnTime);
		SetArrayCell(g_hSBombs, iIndex, flLifeTime, SBomb_LifeTime);
		SetArrayCell(g_hSBombs, iIndex, flMaxSpeed, SBomb_MaxSpeed);
		SetArrayCell(g_hSBombs, iIndex, flDamage, SBomb_Damage);
		SetArrayCell(g_hSBombs, iIndex, flDamageRadius, SBomb_DamageRadius);
		SetArrayCell(g_hSBombs, iIndex, iTeam, SBomb_Team);
		SetArrayCell(g_hSBombs, iIndex, IsValidEntity(iOwner) ? EntIndexToEntRef(iOwner) : INVALID_ENT_REFERENCE, SBomb_Owner);
		SetArrayCell(g_hSBombs, iIndex, IsValidEntity(iTarget) ? EntIndexToEntRef(iTarget) : INVALID_ENT_REFERENCE, SBomb_Target);
		SetArrayCell(g_hSBombs, iIndex, IsValidEntity(iSmoke) ? EntIndexToEntRef(iSmoke) : INVALID_ENT_REFERENCE, SBomb_TrailEnt);
		SetArrayCell(g_hSBombs, iIndex, false, SBomb_Detonated);
		SetArrayCell(g_hSBombs, iIndex, INVALID_ENT_REFERENCE, SBomb_DetonateHurtEnt);
		SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateHurtTimer);
		SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateStopHurtTimer);
		SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateKillTimer);
		SetArrayCell(g_hSBombs, iIndex, true, SBomb_IsTracking);
		SetArrayCell(g_hSBombs, iIndex, flTrackDuration, SBomb_TrackDuration);
		
		Handle hTimer = CreateTimer(flLifeTime, Timer_DetonateSmartBomb, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
		SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateTimer);
		
		TeleportEntity(iSmartBomb, flPos, flAng, flVelocity);
		SDKHook(iSmartBomb, SDKHook_StartTouchPost, Hook_SmartBombStartTouchPost);
		CreateTimer(0.0001, Timer_SmartBombThink, EntIndexToEntRef(iSmartBomb), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		EmitSoundToAll(ARWING_SMARTBOMB_FLY_SOUND, iSmartBomb, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	return iSmartBomb;
}

public void Hook_SmartBombStartTouchPost(int iSmartBomb, int other)
{
	int iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return;
	
	int iOwner = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Owner));
	bool bHit = false;
	
	if (iOwner && iOwner != other)
	{
		int iOtherEntRef = EntIndexToEntRef(other);
		int iOtherIndex = FindValueInArray(g_hArwings, iOtherEntRef);
		if (iOtherIndex != -1)
		{
			if (EntRefToEntIndex(GetArrayCell(g_hArwings, iOtherIndex, Arwing_Pilot)) != iOwner)
			{
				bHit = true;
			}
		}
		else
		{
			bHit = true;
		}
	}
	
	if (bHit) 
	{
		DetonateSmartBomb(iSmartBomb);
	}
}

public Action Timer_SmartBombThink(Handle timer, any entref)
{
	int iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (view_as<bool>(GetArrayCell(g_hSBombs, iIndex, SBomb_Detonated))) return Plugin_Stop;
	
	int iTarget = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Target));
	if (SmartBombCanTrackTarget(iSmartBomb, iTarget))
	{
		float flPos[3], flVelocity[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsVelocity", flVelocity);
		
		float flGoalVelocity[3];
		if (GetArrayCell(g_hSBombs, iIndex, SBomb_IsTracking))
		{
			float flTargetPos[3];
			GetEntPropVector(iTarget, Prop_Data, "m_vecAbsOrigin", flTargetPos);
			SubtractVectors(flTargetPos, flPos, flGoalVelocity);
		}
		else
		{
			CopyVectors(flVelocity, flGoalVelocity);
		}
		
		NormalizeVector(flGoalVelocity, flGoalVelocity);
		ScaleVector(flGoalVelocity, view_as<float>(GetArrayCell(g_hSBombs, iIndex, SBomb_MaxSpeed)));
		
		float flNewVelocity[3];
		LerpVectors(flVelocity, flGoalVelocity, flNewVelocity, 0.25);
		TeleportEntity(iSmartBomb, NULL_VECTOR, NULL_VECTOR, flNewVelocity);
	}
	else
	{
		SetArrayCell(g_hSBombs, iIndex, INVALID_ENT_REFERENCE, SBomb_Target);
	}
	
	return Plugin_Continue;
}

bool SmartBombCanTrackTarget(int iSmartBomb, int iTarget)
{
	if (!IsValidEntity(iSmartBomb) || !IsValidEntity(iTarget)) return false;
	
	int iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return false;
	
	int iTeam = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Team));
	
	int iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iTarget));
	if (iTargetIndex != -1)
	{
		if (view_as<bool>(GetArrayCell(g_hArwings, iTargetIndex, Arwing_Destroyed))) return false;
	
		if (!g_bFriendlyFire && iTeam == GetArrayCell(g_hArwings, iTargetIndex, Arwing_Team))
		{
			return false;
		}
		
		if (view_as<bool>(GetArrayCell(g_hArwings, iTargetIndex, Arwing_InSomersault)) ||
			view_as<bool>(GetArrayCell(g_hArwings, iTargetIndex, Arwing_InUTurn)))
		{
			return false;
		}
	}
	else
	{
		if (!g_bFriendlyFire && GetEntProp(iTarget, Prop_Data, "m_iTeamNum") == iTeam) return false;
		if (IsValidClient(iTarget) && !IsPlayerAlive(iTarget)) return false;
	}
	
	return true;
}

public Action Timer_DetonateSmartBomb(Handle timer, any entref)
{
	int iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateTimer))) return;
	
	DetonateSmartBomb(iSmartBomb);
}

void DetonateSmartBomb(int iSmartBomb)
{
	int iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return;
	
	if (view_as<bool>(GetArrayCell(g_hSBombs, iIndex, SBomb_Detonated))) return;
	
	SetArrayCell(g_hSBombs, iIndex, true, SBomb_Detonated);
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateTimer);
	
	int iExplode = CreateEntityByName("env_explosion");
	if (iExplode != -1)
	{
		float flPos[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
	
		SetEntProp(iExplode, Prop_Data, "m_spawnflags", 2 + 4 + 8 + 16 + 32 + 64 + 256 + 512 + 1024);
		SetEntProp(iExplode, Prop_Data, "m_iMagnitude", RoundToFloor(view_as<float>(GetArrayCell(g_hSBombs, iIndex, SBomb_Damage))));
		SetEntProp(iExplode, Prop_Data, "m_iRadiusOverride", RoundToFloor(view_as<float>(GetArrayCell(g_hSBombs, iIndex, SBomb_DamageRadius))));
		DispatchSpawn(iExplode);
		ActivateEntity(iExplode);
		TeleportEntity(iExplode, flPos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(iExplode, Prop_Send, "m_hOwnerEntity", EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Owner)));
		SetVariantString("!activator");
		AcceptEntityInput(iExplode, "SetParent", iSmartBomb);
		
		SetArrayCell(g_hSBombs, iIndex, EntIndexToEntRef(iExplode), SBomb_DetonateHurtEnt);
	}
	
	Handle hTimer = CreateTimer(0.1, Timer_SmartBombDetonateHurt, EntIndexToEntRef(iSmartBomb), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateHurtTimer);
	TriggerTimer(hTimer, true);
	
	hTimer = CreateTimer(1.5, Timer_SmartBombDetonateStopHurt, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateStopHurtTimer);
	
	hTimer = CreateTimer(7.0, Timer_SmartBombDetonateKill, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateKillTimer);
	
	TeleportEntity(iSmartBomb, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	SetEntityMoveType(iSmartBomb, MOVETYPE_NONE);
	SetEntityRenderMode(iSmartBomb, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iSmartBomb, 0, 0, 0, 1);
	
	int iSmoke = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_TrailEnt));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		TurnOffEntity(iSmoke);
		DeleteEntity(iSmoke, 1.0);
	}
	
	StopSound(iSmartBomb, SNDCHAN_STATIC, ARWING_SMARTBOMB_FLY_SOUND);
	EmitSoundToAll(ARWING_SMARTBOMB_DETONATE_SOUND, iSmartBomb, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	
	int iEffect = CreateEntityByName("env_smokestack");
	if (iEffect != -1)
	{
		DispatchKeyValue(iEffect, "SmokeMaterial", ARWING_SMARTBOMB_EXPLOSION_MATERIAL);
		DispatchKeyValue(iEffect, "StartSize", "2500");
		DispatchKeyValue(iEffect, "EndSize", "1500");
		DispatchKeyValue(iEffect, "BaseSpread", "10");
		DispatchKeyValue(iEffect, "Roll", "90");
		DispatchKeyValue(iEffect, "JetLength", "30");
		DispatchKeyValue(iEffect, "SpreadSpeed", "500");
		DispatchKeyValue(iEffect, "Speed", "45");
		DispatchKeyValue(iEffect, "Rate", "35");
		DispatchKeyValue(iEffect, "renderamt", "255");
		DispatchKeyValue(iEffect, "rendermode", "5");
		
		int iTeam = GetArrayCell(g_hSBombs, iIndex, SBomb_Team);
		
		if (iTeam == view_as<int>(TFTeam_Red)) 
		{
			DispatchKeyValue(iEffect, "rendercolor", "255 150 150");
		}
		else 
		{
			DispatchKeyValue(iEffect, "rendercolor", "150 150 255");
		}
		
		DispatchSpawn(iEffect);
		ActivateEntity(iEffect);
		
		float flPos[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
		TeleportEntity(iEffect, flPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEffect, "TurnOn");
		SetEdictFlags(iEffect, FL_EDICT_ALWAYS);
		TurnOffEntity(iEffect, 1.0);
		DeleteEntity(iEffect, 5.0);
	}
}

public Action Timer_SmartBombDetonateHurt(Handle timer, any entref)
{
	int iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtTimer))) return Plugin_Stop;
	
	int iExplode = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtEnt));
	if (iExplode && iExplode != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iExplode, "Explode");
	}
	
	return Plugin_Continue;
}

public Action Timer_SmartBombDetonateStopHurt(Handle timer, any entref)
{
	int iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateStopHurtTimer))) return;
	
	int iExplode = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtEnt));
	if (iExplode && iExplode != INVALID_ENT_REFERENCE)
	{
		DeleteEntity(iExplode);
	}
	
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateHurtTimer);
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateStopHurtTimer);
}

public Action Timer_SmartBombDetonateKill(Handle timer, any entref)
{
	int iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != view_as<Handle>(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateKillTimer))) return;
	
	DeleteEntity(iSmartBomb);
}