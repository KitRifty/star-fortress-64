// Main vehicle interface.

#if defined _sf64_basevehicle_included
  #endinput
#endif
#define _sf64_basevehicle_included


stock int GetCurrentVehicle(int ent, int &iVehicleType=VehicleType_Unknown, int &iIndex=-1)
{
	iVehicleType = VehicleType_Unknown;
	iIndex = -1;
	
	// Check Arwings first.
	int iIndex2 = -1, iVehicle = GetArwing(ent, iIndex2);
	if (iIndex2 != -1)
	{
		iVehicleType = VehicleType_Arwing;
		iIndex = iIndex2;
		return iVehicle;
	}
	
	// TODO: Add Landmaster support.
	
	return INVALID_ENT_REFERENCE;
}

stock int SpawnVehicle(int iVehicleType, const char[] sName, const float flPos[3], const float flAng[3], const float flVelocity[3], int &iIndex=-1)
{
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return SpawnArwing(sName, flPos, flAng, flVelocity, iIndex);
	}
	
	return INVALID_ENT_REFERENCE;
}

stock int VehicleGetType(int vehicle, int &iIndex=-1)
{
	int iVehicleType;
	IsVehicle(vehicle, iVehicleType, iIndex);
	return iVehicleType;
}

stock int GetVehicleTypeFromString(const char[] sType)
{
	if (StrEqual(sType, "arwing", false)) return VehicleType_Arwing;
	if (StrEqual(sType, "landmaster", false)) return VehicleType_Landmaster;
	
	return VehicleType_Unknown;
}

stock Handle GetConfigFromVehicleName(int iVehicleType, const char[] sName)
{
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return GetArwingConfig(sName);
	}
	
	return INVALID_HANDLE;
}

stock int VehicleGetTeam(int vehicle)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return -1;

	switch (iVehicleType)
	{
		case VehicleType_Arwing: return GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	}
	
	return -1;
}

stock bool IsVehicleEnabled(int vehicle)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return false;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Enabled));
	}
	
	return false;
}

stock void VehicleLock(int vehicle, bool bLock=true)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: SetArrayCell(g_hArwings, iIndex, bLock, Arwing_Locked);
	}
	
	return;
}

stock bool IsVehicleLocked(int vehicle)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return false;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return view_as<bool>(GetArrayCell(g_hArwings, iIndex, Arwing_Locked));
	}
	
	return false;
}

stock int VehicleGetTarget(int vehicle)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return INVALID_ENT_REFERENCE;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
	}
	
	return INVALID_ENT_REFERENCE;
}

stock int VehicleGetPilot(int vehicle)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return INVALID_ENT_REFERENCE;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	}
	
	return INVALID_ENT_REFERENCE;
}

stock void InsertPilotIntoVehicle(int vehicle, int iPilot, bool bImmediate=false)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: InsertPilotIntoArwing(vehicle, iPilot, bImmediate);
	}
}

stock void VehicleEjectPilot(int vehicle, bool bImmediate=false)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: EjectPilotFromArwing(vehicle, bImmediate);
	}
}

stock void VehicleSetIgnorePilotControls(int vehicle, bool bIgnore)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: SetArrayCell(g_hArwings, iIndex, bIgnore, Arwing_IgnorePilotControls);
	}
}

stock bool VehicleCanTarget(int vehicle, int target)
{
	if (!IsVehicle(vehicle) || !IsVehicle(target)) return false;
	
	int iTeam = VehicleGetTeam(vehicle);
	int iTargetTeam = VehicleGetTeam(target);
	
	if (!g_bFriendlyFire && iTeam == iTargetTeam) return false;
	
	return true;
}

stock void VehiclePressButton(int vehicle, int iButton)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingPressButton(vehicle, iButton);
	}
}

stock void VehicleReleaseButton(int vehicle, int iButton)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingReleaseButton(vehicle, iButton);
	}
}

public void VehicleOnSleep(int vehicle)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingOnSleep(vehicle);
	}
}

public void VehicleOnTouchingBoundary(int vehicle, int iBoundaryTrigger, int iBoundaryTriggerRef)
{
	int iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing:
		{
			float flVehicleAng[3];
			VehicleGetAbsAngles(vehicle, flVehicleAng);
			
			float flRefAng[3];
			GetEntPropVector(iBoundaryTriggerRef, Prop_Data, "m_angAbsRotation", flRefAng);
			
			if (FloatAbs(AngleDiff(flRefAng[1], flVehicleAng[1])) > 90.0)
			{
				// Force the Arwing to perform a U-Turn back into the game.
				ArwingStartUTurn(vehicle, true);
			}
		}
	}
}

stock bool IsVehicle(int ent, int &iVehicleType=VehicleType_Unknown, int &iIndex=-1)
{
	if (!IsValidEntity(ent)) return false;
	
	iVehicleType = VehicleType_Unknown;
	iIndex = -1;
	
	int entref = EntIndexToEntRef(ent);
	
	for (int i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
	{
		if (GetArrayCell(g_hArwings, i) != entref) continue;
		iVehicleType = VehicleType_Arwing;
		iIndex = i;
		return true;
	}
	
	// TODO: Add Landmaster support.
	
	return false;
}

stock void VehicleGetAbsOrigin(int vehicle, float flBuffer[3])
{
	int iVehicleType = VehicleType_Unknown;
	int iIndex = -1;

	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing:
		{
			// TODO: Add support for offsets.
			GetEntPropVector(vehicle, Prop_Data, "m_vecAbsOrigin", flBuffer);
		}
	}
}

stock void VehicleGetAbsAngles(int vehicle, float flBuffer[3])
{
	int iVehicleType = VehicleType_Unknown;
	int iIndex = -1;

	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing:
		{
			// TODO: Add support for offsets.
			GetEntPropVector(vehicle, Prop_Data, "m_angAbsRotation", flBuffer);
		}
	}
}

stock void VehicleGetOBBCenter(int vehicle, float flBuffer[3])
{
	float flPos[3];
	VehicleGetAbsOrigin(vehicle, flPos);

	float flMins[3], flMaxs[3];
	GetEntPropVector(vehicle, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(vehicle, Prop_Send, "m_vecMaxs", flMaxs);
	
	float flOBBCenter[3];
	for (int i = 0; i < 3; i++) flOBBCenter[i] = (flMins[i] + flMaxs[i]) / 2.0;
	
	AddVectors(flOBBCenter, flPos, flBuffer);
}

// Effects

stock void VehicleSpawnEffects(int vehicle, EffectEvent iEvent, bool bStartOn=false, bool bOverridePos=false, const float flOverridePos[3]=NULL_VECTOR, const float flOverrideAng[3]=NULL_VECTOR)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingSpawnEffects(vehicle, iEvent, bStartOn, bOverridePos, flOverridePos, flOverrideAng);
	}
}

// This function is specifically used in special cases where instead of parenting the effect to the vehicle,
// we want it to be parented to a "fake" model of the vehicle instead. One good example of these "special cases"
// include the Arwing's classic barrel roll.
stock void VehicleParentMyEffectToSelf(int iVehicle, int iEffectIndex, bool bOverridePos=false, const float flOverridePos[3]=NULL_VECTOR, const float flOverrideAng[3]=NULL_VECTOR)
{
	if (iEffectIndex < 0 || iEffectIndex >= GetArraySize(g_hEffects)) return;
	
	int iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex));
	if (!iEffect || iEffect == INVALID_ENT_REFERENCE) return;
	
	int iVehicleType, iIndex;
	if (!IsVehicle(iVehicle, iVehicleType, iIndex)) return;
	
	int iOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex, Effect_Owner));
	if (!iOwner || iOwner == INVALID_ENT_REFERENCE || iOwner != iVehicle) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingParentMyEffectToSelf(iVehicle, iEffectIndex, bOverridePos, flOverridePos, flOverrideAng);
	}
}

// This function is mostly used to update an entity's parent.
stock void VehicleParentMyEffectsToSelfOfEvent(int vehicle, EffectEvent iEvent, bool bIgnoreKill=false)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingParentMyEffectsToSelfOfEvent(vehicle, iEvent, bIgnoreKill);
	}
}

stock void VehicleSetTeamColorOfEffects(int vehicle)
{
	int iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingSetTeamColorOfEffects(vehicle);
	}
}