#if defined _sf64_hud_targetreticle_included
  #endinput
#endif
#define _sf64_hud_targetreticle_included


int SpawnTargetReticle(const char[] sMaterial, const float flPos[3], const float flAng[3], const float flVelocity[3], int iOwner, float flScale, bool bIsLockOn=false, int &iIndex=-1)
{
	int iReticle = CreateEntityByName("env_sprite");
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
		
		int iEdictFlags = GetEdictFlags(iReticle);
		if (!(iEdictFlags & FL_EDICT_ALWAYS)) iEdictFlags |= FL_EDICT_ALWAYS;
		if (!(iEdictFlags & FL_EDICT_FULLCHECK)) iEdictFlags |= FL_EDICT_FULLCHECK;
		if (iEdictFlags & FL_EDICT_PVSCHECK) iEdictFlags &= ~FL_EDICT_PVSCHECK;
		SetEdictFlags(iReticle, iEdictFlags);
		
		SDKHook(iReticle, SDKHook_SetTransmit, Hook_TargetReticleSetTransmit);
		
		TeleportEntity(iReticle, flPos, flAng, flVelocity);
	}
	
	return iReticle;
}

public Action Hook_TargetReticleSetTransmit(int iReticle, int other)
{
	int iIndex = FindValueInArray(g_hTargetReticles, EntIndexToEntRef(iReticle));
	if (iIndex == -1) return Plugin_Continue;
	
	bool bAppear = false;
	
	int iVehicle = EntRefToEntIndex(GetArrayCell(g_hTargetReticles, iIndex, TargetReticle_Owner));
	if (iVehicle && iVehicle != INVALID_ENT_REFERENCE && IsVehicle(iVehicle))
	{
		if (IsVehicleEnabled(iVehicle))
		{
			int iPilot = VehicleGetPilot(iVehicle);
			if (iPilot && iPilot != INVALID_ENT_REFERENCE && IsValidClient(iPilot))
			{
				if (iPilot == other)
				{
					// This reticle is a normal reticle; appear always to its pilot.
					bAppear = true;
				}
				else if (view_as<bool>(GetArrayCell(g_hTargetReticles, iIndex, TargetReticle_IsLockOn)))
				{
					int iTargetVehicle = VehicleGetTarget(iVehicle);
					if (IsVehicle(iTargetVehicle))
					{
						int iTargetPilot = VehicleGetPilot(iTargetVehicle);
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

stock void RemoveAllTargetReticlesFromEntity(int iEnt, bool bLockOnOnly=false)
{
	if (!IsValidEntity(iEnt)) return;
	
	Handle hArray = CloneArray(g_hTargetReticles);
	
	int iReticle;
	int iEntRef = EntIndexToEntRef(iEnt);
	for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		iReticle = EntRefToEntIndex(GetArrayCell(hArray, i));
		if (!iReticle || iReticle == INVALID_ENT_REFERENCE) continue;
		
		if (GetArrayCell(hArray, i, TargetReticle_Owner) == iEntRef)
		{
			if (bLockOnOnly)
			{
				if (view_as<bool>(GetArrayCell(hArray, i, TargetReticle_IsLockOn)))
				{
					DeleteEntity(iReticle);
				}
			}
			else
			{
				DeleteEntity(iReticle);
			}
		}
	}
	
	CloseHandle(hArray);
}