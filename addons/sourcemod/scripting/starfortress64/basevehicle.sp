// Main vehicle interface.

#if defined _sf64_basevehicle_included
  #endinput
#endif
#define _sf64_basevehicle_included


stock GetCurrentVehicle(ent, &iVehicleType=VehicleType_Unknown, &iIndex=-1)
{
	iVehicleType = VehicleType_Unknown;
	iIndex = -1;
	
	// Check Arwings first.
	new iIndex2 = -1, iVehicle = GetArwing(ent, iIndex2);
	if (iIndex2 != -1)
	{
		iVehicleType = VehicleType_Arwing;
		iIndex = iIndex2;
		return iVehicle;
	}
	
	// TODO: Add Landmaster support.
	
	return INVALID_ENT_REFERENCE;
}

stock SpawnVehicle(iVehicleType, const String:sName[], const Float:flPos[3], const Float:flAng[3], const Float:flVelocity[3], &iIndex=-1)
{
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return SpawnArwing(sName, flPos, flAng, flVelocity, iIndex);
	}
	
	return INVALID_ENT_REFERENCE;
}

stock VehicleGetType(vehicle, &iIndex=-1)
{
	decl iVehicleType;
	IsVehicle(vehicle, iVehicleType, iIndex);
	return iVehicleType;
}

stock GetVehicleTypeFromString(const String:sType[])
{
	if (StrEqual(sType, "arwing", false)) return VehicleType_Arwing;
	if (StrEqual(sType, "landmaster", false)) return VehicleType_Landmaster;
	
	return VehicleType_Unknown;
}

stock Handle:GetConfigFromVehicleName(iVehicleType, const String:sName[])
{
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return GetArwingConfig(sName);
	}
	
	return INVALID_HANDLE;
}

stock VehicleGetTeam(vehicle)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return -1;

	switch (iVehicleType)
	{
		case VehicleType_Arwing: return GetArrayCell(g_hArwings, iIndex, Arwing_Team);
	}
	
	return -1;
}

stock bool:IsVehicleEnabled(vehicle)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return false;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return bool:GetArrayCell(g_hArwings, iIndex, Arwing_Enabled);
	}
	
	return false;
}

stock VehicleLock(vehicle, bool:bLock=true)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: SetArrayCell(g_hArwings, iIndex, bLock, Arwing_Locked);
	}
	
	return;
}

stock bool:IsVehicleLocked(vehicle)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return false;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return bool:GetArrayCell(g_hArwings, iIndex, Arwing_Locked);
	}
	
	return false;
}

stock VehicleGetTarget(vehicle)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return INVALID_ENT_REFERENCE;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Target));
	}
	
	return INVALID_ENT_REFERENCE;
}

stock VehicleGetPilot(vehicle)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return INVALID_ENT_REFERENCE;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: return EntRefToEntIndex(GetArrayCell(g_hArwings, iIndex, Arwing_Pilot));
	}
	
	return INVALID_ENT_REFERENCE;
}

stock bool:InsertPilotIntoVehicle(vehicle, iPilot, bool:bImmediate=false)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: InsertPilotIntoArwing(vehicle, iPilot, bImmediate);
	}
}

stock VehicleEjectPilot(vehicle, bool:bImmediate=false)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: EjectPilotFromArwing(vehicle, bImmediate);
	}
}

stock VehicleSetIgnorePilotControls(vehicle, bool:bIgnore)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: SetArrayCell(g_hArwings, iIndex, bIgnore, Arwing_IgnorePilotControls);
	}
}

stock bool:VehicleCanTarget(vehicle, target)
{
	if (!IsVehicle(vehicle) || !IsVehicle(target)) return false;
	
	new iTeam = VehicleGetTeam(vehicle);
	new iTargetTeam = VehicleGetTeam(target);
	
	if (!g_bFriendlyFire && iTeam == iTargetTeam) return false;
	
	return true;
}

stock VehiclePressButton(vehicle, iButton)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingPressButton(vehicle, iButton);
	}
}

stock VehicleReleaseButton(vehicle, iButton)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingReleaseButton(vehicle, iButton);
	}
}

public VehicleOnSleep(vehicle)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingOnSleep(vehicle);
	}
}

public VehicleOnTouchingBoundary(vehicle, iBoundaryTrigger, iBoundaryTriggerRef)
{
	decl iVehicleType, iIndex;
	if (!IsVehicle(vehicle, iVehicleType, iIndex)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing:
		{
			decl Float:flVehicleAng[3];
			VehicleGetAbsAngles(vehicle, flVehicleAng);
			
			decl Float:flRefAng[3];
			GetEntPropVector(iBoundaryTriggerRef, Prop_Data, "m_angAbsRotation", flRefAng);
			
			if (FloatAbs(AngleDiff(flRefAng[1], flVehicleAng[1])) > 90.0)
			{
				// Force the Arwing to perform a U-Turn back into the game.
				ArwingStartUTurn(vehicle, true);
			}
		}
	}
}

stock bool:IsVehicle(ent, &iVehicleType=VehicleType_Unknown, &iIndex=-1)
{
	if (!IsValidEntity(ent)) return false;
	
	iVehicleType = VehicleType_Unknown;
	iIndex = -1;
	
	new entref = EntIndexToEntRef(ent);
	
	for (new i = 0, iSize = GetArraySize(g_hArwings); i < iSize; i++)
	{
		if (GetArrayCell(g_hArwings, i) != entref) continue;
		iVehicleType = VehicleType_Arwing;
		iIndex = i;
		return true;
	}
	
	// TODO: Add Landmaster support.
	
	return false;
}

stock VehicleGetAbsOrigin(vehicle, Float:flBuffer[3])
{
	new iVehicleType = VehicleType_Unknown;
	new iIndex = -1;

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

stock VehicleGetAbsAngles(vehicle, Float:flBuffer[3])
{
	new iVehicleType = VehicleType_Unknown;
	new iIndex = -1;

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

stock VehicleGetOBBCenter(vehicle, Float:flBuffer[3])
{
	decl Float:flPos[3];
	VehicleGetAbsOrigin(vehicle, flPos);

	decl Float:flMins[3], Float:flMaxs[3];
	GetEntPropVector(vehicle, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(vehicle, Prop_Send, "m_vecMaxs", flMaxs);
	
	decl Float:flOBBCenter[3];
	for (new i = 0; i < 3; i++) flOBBCenter[i] = (flMins[i] + flMaxs[i]) / 2.0;
	
	AddVectors(flOBBCenter, flPos, flBuffer);
}

// Effects

stock VehicleSpawnEffects(vehicle, EffectEvent:iEvent, bool:bStartOn=false, bool:bOverridePos=false, const Float:flOverridePos[3]=NULL_VECTOR, const Float:flOverrideAng[3]=NULL_VECTOR)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingSpawnEffects(vehicle, iEvent, bStartOn, bOverridePos, flOverridePos, flOverrideAng);
	}
}

// This function is specifically used in special cases where instead of parenting the effect to the vehicle,
// we want it to be parented to a "fake" model of the vehicle instead. One good example of these "special cases"
// include the Arwing's classic barrel roll.
stock VehicleParentMyEffectToSelf(vehicle, iEffectIndex, bool:bOverridePos=false, const Float:flOverridePos[3]=NULL_VECTOR, const Float:flOverrideAng[3]=NULL_VECTOR)
{
	if (iEffectIndex < 0 || iEffectIndex >= GetArraySize(g_hEffects)) return;
	
	new iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex));
	if (!iEffect || iEffect == INVALID_ENT_REFERENCE) return;
	
	decl iVehicleType, iIndex;
	if (!IsVehicle(iVehicle, iVehicleType, iIndex)) return;
	
	new iOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, iEffectIndex, Effect_Owner));
	if (!iOwner || iOwner == INVALID_ENT_REFERENCE || iOwner != vehicle) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingParentMyEffectToSelf(vehicle, iEffectIndex, bOverridePos, flOverridePos, flOverrideAng);
	}
}

// This function is mostly used to update an entity's parent.
stock VehicleParentMyEffectsToSelfOfEvent(vehicle, EffectEvent:iEvent, bool:bIgnoreKill=false)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingParentMyEffectsToSelfOfEvent(vehicle, iEvent, bIgnoreKill);
	}
}

stock VehicleSetTeamColorOfEffects(vehicle)
{
	decl iVehicleType;
	if (!IsVehicle(vehicle, iVehicleType)) return;
	
	switch (iVehicleType)
	{
		case VehicleType_Arwing: ArwingSetTeamColorOfEffects(vehicle);
	}
}