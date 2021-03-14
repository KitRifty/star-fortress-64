#if defined _sf64_proj_laser_included
  #endinput
#endif
#define _sf64_proj_laser_included

#define ARWING_LASER_TRAIL_MATERIAL "sprites/laserbeam.vmt"
#define ARWING_LASER_TRAIL_LIFETIME 0.2
#define ARWING_LASER_TRAIL_STARTWIDTH 16.0
#define ARWING_LASER_TRAIL_ENDWIDTH 6.0
#define ARWING_LASER_HIT_NODAMAGE_SOUND "arwing/laserhitnodamage.mp3"


SpawnLaser(const Float:flPos[3], const Float:flAng[3], const Float:flVelocity[3], iTeam, iOwner, Float:flDamage=5.0, Float:flLifeTime=3.0, bool:bHyperLaser=false, &iIndex=-1)
{
	new iLaser = CreateEntityByName("tf_projectile_energy_ring");
	if (iLaser != -1)
	{
		SetEntPropEnt(iLaser, Prop_Send, "m_hOwnerEntity", iOwner);
		DispatchSpawn(iLaser);
		ActivateEntity(iLaser);
		SetEntityMoveType(iLaser, MOVETYPE_FLY);
		SetEntityRenderMode(iLaser, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iLaser, 0, 0, 0, 1);
		SetEntProp(iLaser, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iLaser, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		new iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt, "renderamt", "255");
			DispatchKeyValue(iTrailEnt, "rendermode", "5");
			
			if (iTeam == _:TFTeam_Red) 
			{
				if (bHyperLaser) DispatchKeyValue(iTrailEnt, "rendercolor", "255 50 0");
				else DispatchKeyValue(iTrailEnt, "rendercolor", "255 0 0");
			}
			else 
			{
				if (bHyperLaser) DispatchKeyValue(iTrailEnt, "rendercolor", "0 200 255");
				else DispatchKeyValue(iTrailEnt, "rendercolor", "0 50 255");
			}
			
			DispatchKeyValueFloat(iTrailEnt, "lifetime", ARWING_LASER_TRAIL_LIFETIME);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", ARWING_LASER_TRAIL_STARTWIDTH);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", ARWING_LASER_TRAIL_ENDWIDTH);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iLaser);
		}
		
		new iTrailEnt2 = CreateEntityByName("env_spritetrail");
		if (iTrailEnt2 != -1)
		{
			DispatchKeyValue(iTrailEnt2, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt2, "renderamt", "255");
			DispatchKeyValue(iTrailEnt2, "rendermode", "5");
			DispatchKeyValue(iTrailEnt2, "rendercolor", "255 255 255");
			DispatchKeyValueFloat(iTrailEnt2, "lifetime", ARWING_LASER_TRAIL_LIFETIME / 2.0);
			DispatchKeyValueFloat(iTrailEnt2, "startwidth", ARWING_LASER_TRAIL_STARTWIDTH);
			DispatchKeyValueFloat(iTrailEnt2, "endwidth", 0.0);
			DispatchSpawn(iTrailEnt2);
			ActivateEntity(iTrailEnt2);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt2, "SetParent", iLaser);
		}
		
		DispatchKeyValue(iLaser, "classname", "sf64_projectile_laser");
		
		iIndex = PushArrayCell(g_hLasers, EntIndexToEntRef(iLaser));
		SetArrayCell(g_hLasers, iIndex, GetGameTime(), Laser_LastSpawnTime);
		SetArrayCell(g_hLasers, iIndex, flLifeTime, Laser_LifeTime);
		SetArrayCell(g_hLasers, iIndex, bHyperLaser, Laser_IsHyperLaser);
		SetArrayCell(g_hLasers, iIndex, iTeam, Laser_Team);
		SetArrayCell(g_hLasers, iIndex, IsValidEntity(iOwner) ? EntIndexToEntRef(iOwner) : INVALID_ENT_REFERENCE, Laser_Owner);
		SetArrayCell(g_hLasers, iIndex, flDamage, Laser_Damage);
		SetArrayCell(g_hLasers, iIndex, IsValidEntity(iTrailEnt) ? EntIndexToEntRef(iTrailEnt) : INVALID_ENT_REFERENCE, Laser_TrailEnt);
		SetArrayCell(g_hLasers, iIndex, ARWING_LASER_TRAIL_LIFETIME, Laser_TrailLifeTime);
		
		SDKHook(iLaser, SDKHook_StartTouch, Hook_LaserStartTouch);
		SDKHook(iLaser, SDKHook_Touch, Hook_LaserTouch);
		SDKHook(iLaser, SDKHook_ThinkPost, Hook_LaserThinkPost);
		
		DeleteEntity(iLaser, flLifeTime);
		TeleportEntity(iLaser, flPos, flAng, flVelocity);
	}
	
	return iLaser;
}

public LaserOnEntityDestroyed(entity)
{
	if (GetArraySize(g_hLasers) > 0)
	{
		new iIndex = FindValueInArray(g_hLasers, EntIndexToEntRef(entity));
		if (iIndex != -1)
		{
			new iTrailEnt = EntRefToEntIndex(GetArrayCell(g_hLasers, iIndex, Laser_TrailEnt));
			if (iTrailEnt && iTrailEnt != INVALID_ENT_REFERENCE)
			{
				TeleportEntity(iTrailEnt, NULL_VECTOR, NULL_VECTOR, Float:{ 0.0, 0.0, 0.0 });
				AcceptEntityInput(iTrailEnt, "ClearParent");
				DeleteEntity(iTrailEnt, Float:GetArrayCell(g_hLasers, iIndex, Laser_TrailLifeTime));
			}
			
			RemoveFromArray(g_hLasers, iIndex);
		}
	}
}

public Hook_LaserThinkPost(iLaser)
{
	new iIndex = FindValueInArray(g_hLasers, EntIndexToEntRef(iLaser));
	if (iIndex == -1) return;
}

public Action:Hook_LaserTouch(iLaser, other)
{
	new iIndex = FindValueInArray(g_hLasers, EntIndexToEntRef(iLaser));
	if (iIndex == -1) return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action:Hook_LaserStartTouch(iLaser, other)
{
	new iIndex = FindValueInArray(g_hLasers, EntIndexToEntRef(iLaser));
	if (iIndex == -1) return Plugin_Continue;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hLasers, iIndex, Laser_Owner));
	new iTeam = GetArrayCell(g_hLasers, iIndex, Laser_Team);
	
	new bool:bHitAirwing = false;
	new bool:bHitPlayer = false;
	new bool:bHitEnemyPlayer = false;
	
	if (iOwner && iOwner != other)
	{
		new iOtherEntRef = EntIndexToEntRef(other);
		new iOtherIndex = FindValueInArray(g_hArwings, iOtherEntRef);

		// Did we hit another Airwing Entity?
		if (iOtherIndex != -1 && iOwner != EntRefToEntIndex(GetArrayCell(g_hArwings, iOtherIndex, Arwing_Pilot)))
		{
			decl Float:flPos[3];
			GetEntPropVector(iLaser, Prop_Data, "m_vecAbsOrigin", flPos);
		
			// Hit the Airwing, unless if they're doring a Barrel Roll, then deflect the shot instead.
			if (!bool:GetArrayCell(g_hArwings, iOtherIndex, Arwing_InBarrelRoll))
			{
				bHitAirwing = true;
				DamageArwing(other, iOwner, iLaser, Float:GetArrayCell(g_hLasers, iIndex, Laser_Damage), DMG_ENERGYBEAM, -1, NULL_VECTOR, flPos);
			}
			else
			{
				SetArrayCell(g_hLasers, iIndex, GetArrayCell(g_hArwings, iOtherIndex, Arwing_Pilot), Laser_Owner);
				SetArrayCell(g_hLasers, iIndex, GetArrayCell(g_hArwings, iOtherIndex, Arwing_Team), Laser_Team);
				
				decl Float:flTargetPos[3], Float:flVelocity[3];
				GetEntPropVector(other, Prop_Data, "m_vecAbsOrigin", flTargetPos);
				GetEntPropVector(iLaser, Prop_Data, "m_vecAbsVelocity", flVelocity);
				new Float:flSpeed = GetVectorLength(flVelocity);
				
				SubtractVectors(flTargetPos, flPos, flVelocity);
				GetAngleVectors(flVelocity, flVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(flVelocity, flVelocity);
				ScaleVector(flVelocity, flSpeed);
				
				TeleportEntity(iLaser, NULL_VECTOR, NULL_VECTOR, flVelocity);
				
				new Handle:hConfig = GetConfigOfArwing(other);
				if (hConfig != INVALID_HANDLE)
				{
					decl String:sPath[PLATFORM_MAX_PATH];
					if (GetRandomStringFromArwingConfig(hConfig, "sound_barrelroll_deflect", sPath, sizeof(sPath)) && sPath[0])
					{
						EmitSoundToAll(sPath, other, SNDCHAN_STATIC, SNDLEVEL_HELICOPTER);
					}
				}
			}
		}
		// Detects Player Hits
		else
		{
			if (other > 0 && other <= MaxClients)
			{
				bHitPlayer = true;
				
				// Make sure not to target players inside Airwings by accident. We wanna damage their Airwings after all!
				new iArwing = GetArwing(other);
				if (!iArwing || iArwing == INVALID_ENT_REFERENCE)
				{
					new iHitTeam = -1;
					if (IsValidClient(other)) iHitTeam = GetClientTeam(other);
					else iHitTeam = GetEntProp(other, Prop_Data, "m_iTeamNum");
					
					// Only hurt enemy players.
					if (iHitTeam != iTeam)
					{
						if (GetEntProp(other, Prop_Data, "m_takedamage"))
						{
							bHitEnemyPlayer = true;
							SDKHooks_TakeDamage(other, iOwner, iOwner, Float:GetArrayCell(g_hLasers, iIndex, Laser_Damage) * 3.0, DMG_ENERGYBEAM);
						}
					}
				}
			}
		}
	}
	
	if (bHitPlayer && !bHitEnemyPlayer)
		EmitSoundToAll(ARWING_LASER_HIT_NODAMAGE_SOUND, iLaser, SNDCHAN_STATIC, SNDLEVEL_MINIBIKE);
	
	// DO NOT DELETE THE LASER ENTITY WHEN HITTING A PLAYER, IT CRASHES for some godknown reason...
	// It might try to delete the entity twice in a row, causing the game crash?
	if (bHitAirwing)
		DeleteEntity(iLaser);
	
	return Plugin_Handled;
}