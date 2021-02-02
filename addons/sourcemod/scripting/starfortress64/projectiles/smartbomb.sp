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

PrecacheSmartBomb()
{
	PrecacheModel2(ARWING_SMARTBOMB_MODEL);
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vtf");
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vmt");
	
	PrecacheSound2(ARWING_SMARTBOMB_FLY_SOUND);
	PrecacheSound2(ARWING_SMARTBOMB_DETONATE_SOUND);
}

SpawnSmartBomb(const Float:flPos[3],
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
	&iIndex=-1)
{
	new iSmartBomb = CreateEntityByName("prop_dynamic_override");
	if (iSmartBomb != -1)
	{
		SetEntityModel(iSmartBomb, ARWING_SMARTBOMB_MODEL);
		DispatchKeyValue(iSmartBomb, "solid", "2");
		DispatchSpawn(iSmartBomb);
		ActivateEntity(iSmartBomb);
		SetEntityMoveType(iSmartBomb, MOVETYPE_FLY);
		SetEntProp(iSmartBomb, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iSmartBomb, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		new iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
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
			
			DispatchKeyValueFloat(iTrailEnt, "lifetime", ARWING_SMARTBOMB_TRAIL_LIFETIME);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", ARWING_SMARTBOMB_TRAIL_STARTWIDTH);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", ARWING_SMARTBOMB_TRAIL_ENDWIDTH);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iSmartBomb);
		}
		
		new iSmoke = CreateEntityByName("env_smokestack");
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
		
		new Handle:hTimer = CreateTimer(flLifeTime, Timer_DetonateSmartBomb, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
		SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateTimer);
		
		TeleportEntity(iSmartBomb, flPos, flAng, flVelocity);
		SDKHook(iSmartBomb, SDKHook_StartTouchPost, Hook_SmartBombStartTouchPost);
		CreateTimer(0.0001, Timer_SmartBombThink, EntIndexToEntRef(iSmartBomb), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		EmitSoundToAll(ARWING_SMARTBOMB_FLY_SOUND, iSmartBomb, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
	}
	
	return iSmartBomb;
}

public Hook_SmartBombStartTouchPost(iSmartBomb, other)
{
	new iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Owner));
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

public Action:Timer_SmartBombThink(Handle:timer, any:entref)
{
	new iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (bool:GetArrayCell(g_hSBombs, iIndex, SBomb_Detonated)) return Plugin_Stop;
	
	new iTarget = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Target));
	if (SmartBombCanTrackTarget(iSmartBomb, iTarget))
	{
		decl Float:flPos[3], Float:flVelocity[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsVelocity", flVelocity);
		
		decl Float:flGoalVelocity[3];
		if (GetArrayCell(g_hSBombs, iIndex, SBomb_IsTracking))
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
		ScaleVector(flGoalVelocity, Float:GetArrayCell(g_hSBombs, iIndex, SBomb_MaxSpeed));
		
		decl Float:flNewVelocity[3];
		LerpVectors(flVelocity, flGoalVelocity, flNewVelocity, 0.25);
		TeleportEntity(iSmartBomb, NULL_VECTOR, NULL_VECTOR, flNewVelocity);
	}
	else
	{
		SetArrayCell(g_hSBombs, iIndex, INVALID_ENT_REFERENCE, SBomb_Target);
	}
	
	return Plugin_Continue;
}

bool:SmartBombCanTrackTarget(iSmartBomb, iTarget)
{
	if (!IsValidEntity(iSmartBomb) || !IsValidEntity(iTarget)) return false;
	
	new iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return false;
	
	new iTeam = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Team));
	
	new iTargetIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(iTarget));
	if (iTargetIndex != -1)
	{
		if (bool:GetArrayCell(g_hArwings, iTargetIndex, Arwing_Destroyed)) return false;
	
		if (!g_bFriendlyFire && iTeam == GetArrayCell(g_hArwings, iTargetIndex, Arwing_Team))
		{
			return false;
		}
		
		if (bool:GetArrayCell(g_hArwings, iTargetIndex, Arwing_InSomersault) ||
			bool:GetArrayCell(g_hArwings, iTargetIndex, Arwing_InUTurn))
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

public Action:Timer_DetonateSmartBomb(Handle:timer, any:entref)
{
	new iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateTimer)) return;
	
	DetonateSmartBomb(iSmartBomb);
}

DetonateSmartBomb(iSmartBomb)
{
	new iIndex = FindValueInArray(g_hSBombs, EntIndexToEntRef(iSmartBomb));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hSBombs, iIndex, SBomb_Detonated)) return;
	
	SetArrayCell(g_hSBombs, iIndex, true, SBomb_Detonated);
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateTimer);
	
	new iExplode = CreateEntityByName("env_explosion");
	if (iExplode != -1)
	{
		decl Float:flPos[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
	
		SetEntProp(iExplode, Prop_Data, "m_spawnflags", 2 + 4 + 8 + 16 + 32 + 64 + 256 + 512 + 1024);
		SetEntProp(iExplode, Prop_Data, "m_iMagnitude", RoundToFloor(Float:GetArrayCell(g_hSBombs, iIndex, SBomb_Damage)));
		SetEntProp(iExplode, Prop_Data, "m_iRadiusOverride", RoundToFloor(Float:GetArrayCell(g_hSBombs, iIndex, SBomb_DamageRadius)));
		DispatchSpawn(iExplode);
		ActivateEntity(iExplode);
		TeleportEntity(iExplode, flPos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(iExplode, Prop_Send, "m_hOwnerEntity", EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_Owner)));
		SetVariantString("!activator");
		AcceptEntityInput(iExplode, "SetParent", iSmartBomb);
		
		SetArrayCell(g_hSBombs, iIndex, EntIndexToEntRef(iExplode), SBomb_DetonateHurtEnt);
	}
	
	new Handle:hTimer = CreateTimer(0.1, Timer_SmartBombDetonateHurt, EntIndexToEntRef(iSmartBomb), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateHurtTimer);
	TriggerTimer(hTimer, true);
	
	hTimer = CreateTimer(1.5, Timer_SmartBombDetonateStopHurt, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateStopHurtTimer);
	
	hTimer = CreateTimer(7.0, Timer_SmartBombDetonateKill, EntIndexToEntRef(iSmartBomb), TIMER_FLAG_NO_MAPCHANGE);
	SetArrayCell(g_hSBombs, iIndex, hTimer, SBomb_DetonateKillTimer);
	
	TeleportEntity(iSmartBomb, NULL_VECTOR, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
	SetEntityMoveType(iSmartBomb, MOVETYPE_NONE);
	SetEntityRenderMode(iSmartBomb, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iSmartBomb, 0, 0, 0, 1);
	
	new iSmoke = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_TrailEnt));
	if (iSmoke && iSmoke != INVALID_ENT_REFERENCE)
	{
		TurnOffEntity(iSmoke);
		RemoveEntity(iSmoke, 1.0);
	}
	
	StopSound(iSmartBomb, SNDCHAN_STATIC, ARWING_SMARTBOMB_FLY_SOUND);
	EmitSoundToAll(ARWING_SMARTBOMB_DETONATE_SOUND, iSmartBomb, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	
	new iEffect = CreateEntityByName("env_smokestack");
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
		
		new iTeam = GetArrayCell(g_hSBombs, iIndex, SBomb_Team);
		
		if (iTeam == _:TFTeam_Red) 
		{
			DispatchKeyValue(iEffect, "rendercolor", "255 150 150");
		}
		else 
		{
			DispatchKeyValue(iEffect, "rendercolor", "150 150 255");
		}
		
		DispatchSpawn(iEffect);
		ActivateEntity(iEffect);
		
		decl Float:flPos[3];
		GetEntPropVector(iSmartBomb, Prop_Data, "m_vecAbsOrigin", flPos);
		TeleportEntity(iEffect, flPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEffect, "TurnOn");
		SetEdictFlags(iEffect, FL_EDICT_ALWAYS);
		TurnOffEntity(iEffect, 1.0);
		RemoveEntity(iEffect, 5.0);
	}
}

public Action:Timer_SmartBombDetonateHurt(Handle:timer, any:entref)
{
	new iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	if (timer != Handle:GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtTimer)) return Plugin_Stop;
	
	new iExplode = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtEnt));
	if (iExplode && iExplode != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(iExplode, "Explode");
	}
	
	return Plugin_Continue;
}

public Action:Timer_SmartBombDetonateStopHurt(Handle:timer, any:entref)
{
	new iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateStopHurtTimer)) return;
	
	new iExplode = EntRefToEntIndex(GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateHurtEnt));
	if (iExplode && iExplode != INVALID_ENT_REFERENCE)
	{
		RemoveEntity(iExplode);
	}
	
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateHurtTimer);
	SetArrayCell(g_hSBombs, iIndex, INVALID_HANDLE, SBomb_DetonateStopHurtTimer);
}

public Action:Timer_SmartBombDetonateKill(Handle:timer, any:entref)
{
	new iSmartBomb = EntRefToEntIndex(entref);
	if (!iSmartBomb || iSmartBomb == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hSBombs, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hSBombs, iIndex, SBomb_DetonateKillTimer)) return;
	
	RemoveEntity(iSmartBomb);
}