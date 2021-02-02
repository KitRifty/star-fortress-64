#if defined _sf64_hud_targetreticle_included
  #endinput
#endif
#define _sf64_hud_targetreticle_included


SpawnTargetReticle(const String:sMaterial[], const Float:flPos[3], const Float:flAng[3], const Float:flVelocity[3], iOwner, Float:flScale, bool:bIsLockOn=false, &iIndex=-1)
{
	new iReticle = CreateEntityByName("env_sprite");
	if (iReticle != -1)
	{
		SetEntityModel(iReticle, sMaterial);
		DispatchKeyValue(iReticle, "model", sMaterial);
		DispatchKeyValueFloat(iReticle, "scale", flScale);
		DispatchKeyValue(iReticle, "renderamt", "255");
		DispatchSpawn(iReticle);
		ActivateEntity(iReticle);
		
		iIndex = PushArrayCell(g_hTargetReticles, EntIndexToEntRef(iReticle));
		SetArrayCell(g_hTargetReticles, iIndex, IsValidEntity(iOwner) ? EntIndexToEntRef(iOwner) : INVALID_ENT_REFERENCE, TargetReticle_Owner);
		SetArrayCell(g_hTargetReticles, iIndex, bIsLockOn, TargetReticle_IsLockOn);
		
		new iEdictFlags = GetEdictFlags(iReticle);
		if (!(iEdictFlags & FL_EDICT_ALWAYS)) iEdictFlags |= FL_EDICT_ALWAYS;
		if (!(iEdictFlags & FL_EDICT_FULLCHECK)) iEdictFlags |= FL_EDICT_FULLCHECK;
		if (iEdictFlags & FL_EDICT_PVSCHECK) iEdictFlags &= ~FL_EDICT_PVSCHECK;
		SetEdictFlags(iReticle, iEdictFlags);
		
		SDKHook(iReticle, SDKHook_SetTransmit, Hook_TargetReticleSetTransmit);
		
		TeleportEntity(iReticle, flPos, flAng, flVelocity);
	}
	
	return iReticle;
}

public Action:Hook_TargetReticleSetTransmit(iReticle, other)
{
	new iIndex = FindValueInArray(g_hTargetReticles, EntIndexToEntRef(iReticle));
	if (iIndex == -1) return Plugin_Continue;
	
	new bool:bAppear = false;
	
	new iVehicle = EntRefToEntIndex(GetArrayCell(g_hTargetReticles, iIndex, TargetReticle_Owner));
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE && IsVehicle(iVehicle))
	{
		if (IsVehicleEnabled(iVehicle))
		{
			new iPilot = VehicleGetPilot(iVehicle);
			if (iPilot && iPilot != INVALID_ENT_REFERENCE && IsValidClient(iPilot))
			{
				if (iPilot == other)
				{
					// This reticle is a normal reticle; appear always to its pilot.
					bAppear = true;
				}
				else if (bool:GetArrayCell(g_hTargetReticles, iIndex, TargetReticle_IsLockOn))
				{
					new iTargetVehicle = VehicleGetTarget(iVehicle);
					if (IsVehicle(iTargetVehicle))
					{
						new iTargetPilot = VehicleGetPilot(iTargetVehicle);
						if (iTargetPilot && iTargetPilot != INVALID_ENT_REFERENCE && IsValidClient(iTargetPilot))
						{
							if (iTargetPilot == other)
							{
								// This reticle is a lock-on reticle; appear always to its pilot, and the pilot's locked on target.
								bAppear = true;
							}
						}
					}
				}
			}
		}
	}
	
	if (!bAppear) return Plugin_Handled;
	return Plugin_Continue;
}

stock RemoveAllTargetReticlesFromEntity(iEnt, bool:bLockOnOnly=false)
{
	if (!IsValidEntity(iEnt)) return;
	
	new Handle:hArray = CloneArray(g_hTargetReticles);
	
	decl iReticle;
	new iEntRef = EntIndexToEntRef(iEnt);
	for (new i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		iReticle = EntRefToEntIndex(GetArrayCell(hArray, i));
		if (!iReticle || iReticle == INVALID_ENT_REFERENCE) continue;
		
		if (GetArrayCell(hArray, i, TargetReticle_Owner) == iEntRef)
		{
			if (bLockOnOnly)
			{
				if (bool:GetArrayCell(hArray, i, TargetReticle_IsLockOn))
				{
					RemoveEntity(iReticle);
				}
			}
			else
			{
				RemoveEntity(iReticle);
			}
		}
	}
	
	CloseHandle(hArray);
}