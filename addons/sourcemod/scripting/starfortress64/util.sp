#if defined _sf64_util_included
  #endinput
#endif
#define _sf64_util_included

stock void DebugMessage(const char[] sMessage, any ...)
{
#if defined DEBUG
	char sFormattedMessage[1024];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 2);
	PrintToServer(sFormattedMessage);
#endif
}

stock void ClientSetFOV(int client, int iFOV)
{
	SetEntData(client, g_offsPlayerFOV, iFOV);
	SetEntData(client, g_offsPlayerDefaultFOV, iFOV);
}

stock void ClientRemoveAllWearables(int client)
{
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable")) != -1)
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client)
		{
			DeleteEntity(iEnt);
		}
	}
	
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_wearable_demoshield")) != -1)
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client)
		{
			DeleteEntity(iEnt);
		}
	}
	
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_powerup_bottle")) != -1)
	{
		if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client)
		{
			DeleteEntity(iEnt);
		}
	}
}

stock bool IsPointWithinFOV(const float flEyePos[3], const float flEyeAng[3], const float flFOV, const float flTargetPos[3])
{
	float flTargetAng[3];
	SubtractVectors(flTargetPos, flEyePos, flTargetAng);
	GetVectorAngles(flTargetAng, flTargetAng);
	
	return view_as<bool>(((FloatAbs(AngleDiff(flEyeAng[0], flTargetAng[0])) + FloatAbs(AngleDiff(flEyeAng[1], flTargetAng[1]))) <= flFOV / 2.0));
}

stock void GetEntityBoundingBoxScaled(int entity, float flMins[3], float flMaxs[3], float flScale)
{
	GetEntPropVector(entity, Prop_Send, "m_vecMinsPreScaled", flMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxsPreScaled", flMaxs);
	ScaleVector(flMins, flScale);
	ScaleVector(flMaxs, flScale);
}

stock void ResizeEntity(int entity, float flScale)
{
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", flScale);

	float flSurroundingMins[3], flSurroundingMaxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMinsPreScaled", flSurroundingMins);
	GetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMaxsPreScaled", flSurroundingMaxs);
	
	ScaleVector(flSurroundingMins, flScale);
	ScaleVector(flSurroundingMaxs, flScale);
	
	SetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMins", flSurroundingMins);
	SetEntPropVector(entity, Prop_Send, "m_vecSpecifiedSurroundingMaxs", flSurroundingMaxs);
}

public Action Timer_FakePilotModelScaleToSize(Handle timer, Handle hPack)
{
	ResetPack(hPack);
	int entref = ReadPackCell(hPack);
	
	int iFakeModel = EntRefToEntIndex(entref);
	if (!iFakeModel || iFakeModel == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	float flTargetModelScale = ReadPackFloat(hPack);
	float flRate = ReadPackFloat(hPack);
	
	float flModelScale = GetEntPropFloat(iFakeModel, Prop_Send, "m_flModelScale");
	
	flModelScale = FloatApproach(flModelScale, flTargetModelScale, flRate);
	SetEntPropFloat(iFakeModel, Prop_Send, "m_flModelScale", flModelScale);
	
	return Plugin_Continue;
}

public Action Timer_FakePilotModelMoveToPos(Handle timer, Handle hPack)
{
	ResetPack(hPack);
	int entref = ReadPackCell(hPack);
	
	int iFakeModel = EntRefToEntIndex(entref);
	if (!iFakeModel || iFakeModel == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	float flTargetPos[3];
	flTargetPos[0] = ReadPackFloat(hPack);
	flTargetPos[1] = ReadPackFloat(hPack);
	flTargetPos[2] = ReadPackFloat(hPack);
	
	float flMyPos[3], flMyVelocity[3];
	GetEntPropVector(iFakeModel, Prop_Data, "m_vecAbsOrigin", flMyPos);
	GetEntPropVector(iFakeModel, Prop_Data, "m_vecAbsVelocity", flMyVelocity);
	
	float flGoalVelocity[3];
	SubtractVectors(flTargetPos, flMyPos, flGoalVelocity);
	NormalizeVector(flGoalVelocity, flGoalVelocity);
	ScaleVector(flGoalVelocity, 900.0);
	
	float flMoveVelocity[3];
	LerpVectors(flMyVelocity, flGoalVelocity, flMoveVelocity, 0.25);
	TeleportEntity(iFakeModel, NULL_VECTOR, NULL_VECTOR, flMoveVelocity);
	
	return Plugin_Continue;
}

public Action Timer_FakePilotModelMoveToOffsetOfEntity(Handle timer, Handle hPack)
{
	ResetPack(hPack);
	int entref = ReadPackCell(hPack);
	int entref2 = ReadPackCell(hPack);
	
	int iFakeModel = EntRefToEntIndex(entref);
	if (!iFakeModel || iFakeModel == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	int iEntity = EntRefToEntIndex(entref2);
	if (!IsValidEntity(iEntity)) return Plugin_Stop;
	
	float flMyPos[3], flMyVelocity[3];
	GetEntPropVector(iFakeModel, Prop_Data, "m_vecAbsOrigin", flMyPos);
	GetEntPropVector(iFakeModel, Prop_Data, "m_vecAbsVelocity", flMyVelocity);
	
	float flOffset[3];
	flOffset[0] = ReadPackFloat(hPack);
	flOffset[1] = ReadPackFloat(hPack);
	flOffset[2] = ReadPackFloat(hPack);
	
	float flTargetPos[3], flArwingPos[3], flArwingAng[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", flArwingPos);
	GetEntPropVector(iEntity, Prop_Data, "m_angAbsRotation", flArwingAng);
	VectorTransform(flOffset, flArwingPos, flArwingAng, flTargetPos);
	
	float flGoalVelocity[3];
	SubtractVectors(flTargetPos, flMyPos, flGoalVelocity);
	NormalizeVector(flGoalVelocity, flGoalVelocity);
	ScaleVector(flGoalVelocity, 900.0);
	
	float flMoveVelocity[3];
	LerpVectors(flMyVelocity, flGoalVelocity, flMoveVelocity, 0.25);
	TeleportEntity(iFakeModel, NULL_VECTOR, NULL_VECTOR, flMoveVelocity);
	
	return Plugin_Continue;
}

stock void DeleteEntity(int ent, float flDelay=0.0)
{
	if (!IsValidEntity(ent)) return;
	if (flDelay > 0.0) CreateTimer(flDelay, Timer_KillEntity, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	else AcceptEntityInput(ent, "Kill");
}

stock void StopEntity(int ent, float flDelay=0.0)
{
	if (!IsValidEntity(ent)) return;
	if (flDelay > 0.0) CreateTimer(flDelay, Timer_StopEntity, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	else AcceptEntityInput(ent, "Stop");
}

stock void TurnOffEntity(int ent, float flDelay=0.0)
{
	if (!IsValidEntity(ent)) return;
	if (flDelay > 0.0) CreateTimer(flDelay, Timer_TurnOffEntity, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	else AcceptEntityInput(ent, "TurnOff");
}

stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return false;
	return true;
}

stock int FindKitRifty()
{
	char sAuth[64];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		GetClientAuthId(i, AuthId_Steam3, sAuth, sizeof(sAuth));
		if (strcmp(sAuth, "[U:0:19146370]") == 0)
		{
			return i;
		}
	}
	
	return -1;
}

stock bool GetEntitySmoothedVelocity(int entity, float flBuffer[3])
{
	if (!IsValidEntity(entity)) return false;

	if (g_hSDKGetSmoothedVelocity == INVALID_HANDLE)
	{
		LogError("SDKCall for GetSmoothedVelocity is invalid!");
		return false;
	}
	
	SDKCall(g_hSDKGetSmoothedVelocity, entity, flBuffer);
	return true;
}

stock void TE_SetupTFParticleEffect(int iParticleSystemIndex, 
	const float flOrigin[3]=NULL_VECTOR, 
	const float flStart[3]=NULL_VECTOR, 
	int iAttachType=0, 
	int iEntIndex=-1, 
	int iAttachmentPointIndex=0, 
	bool bResetParticles=true, 
	bool bControlPoint1=false, 
	const float flControlPoint1Offset[3]=NULL_VECTOR)
{
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", flOrigin[0]);
	TE_WriteFloat("m_vecOrigin[1]", flOrigin[1]);
	TE_WriteFloat("m_vecOrigin[2]", flOrigin[2]);
	TE_WriteFloat("m_vecStart[0]", flStart[0]);
	TE_WriteFloat("m_vecStart[1]", flStart[1]);
	TE_WriteFloat("m_vecStart[2]", flStart[2]);
	TE_WriteNum("m_iParticleSystemIndex", iParticleSystemIndex);
	TE_WriteNum("m_iAttachType", iAttachType);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_iAttachmentPointIndex", iAttachmentPointIndex);
	TE_WriteNum("m_bResetParticles", bResetParticles);
	TE_WriteNum("m_bControlPoint1", bControlPoint1);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", flControlPoint1Offset[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", flControlPoint1Offset[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", flControlPoint1Offset[2]);
}

stock void TE_SetupBeamEnts(int StartEntity, int EndEntity, int ModelIndex, int HaloIndex, int StartFrame, int FrameRate, float Life,  
                float Width, float EndWidth, int FadeLength, float Amplitude, const Color[4], int Speed) 
{ 
    TE_Start("BeamEnts"); 
    TE_WriteEncodedEnt("m_nStartEntity", StartEntity); 
    TE_WriteEncodedEnt("m_nEndEntity", EndEntity); 
    TE_WriteNum("m_nModelIndex", ModelIndex); 
    TE_WriteNum("m_nHaloIndex", HaloIndex); 
    TE_WriteNum("m_nStartFrame", StartFrame); 
    TE_WriteNum("m_nFrameRate", FrameRate); 
    TE_WriteFloat("m_fLife", Life); 
    TE_WriteFloat("m_fWidth", Width); 
    TE_WriteFloat("m_fEndWidth", EndWidth); 
    TE_WriteFloat("m_fAmplitude", Amplitude); 
    TE_WriteNum("r", Color[0]); 
    TE_WriteNum("g", Color[1]); 
    TE_WriteNum("b", Color[2]); 
    TE_WriteNum("a", Color[3]); 
    TE_WriteNum("m_nSpeed", Speed); 
    TE_WriteNum("m_nFadeLength", FadeLength); 
}  

stock int SpawnParticleSystem(const char[] sParticleName, const float flPos[3], const float flAng[3], float flTimeToStop=0.0, float flTimeToRemove=0.0, bool bStartOn=true)
{
	int iEnt = CreateEntityByName("info_particle_system");
	if (iEnt != -1)
	{
		DispatchKeyValue(iEnt, "effect_name", sParticleName);
		DispatchSpawn(iEnt);
		ActivateEntity(iEnt);
		TeleportEntity(iEnt, flPos, flAng, NULL_VECTOR);
		if (bStartOn) AcceptEntityInput(iEnt, "Start");
		
		if (flTimeToStop > 0.0) StopEntity(iEnt, flTimeToStop);
		if (flTimeToRemove > 0.0) DeleteEntity(iEnt, flTimeToRemove);
	}
	
	return iEnt;
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) 
	{
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) return INVALID_STRING_INDEX;
	}
	
	int index = FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX) 
	{
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) return INVALID_STRING_INDEX;
		
		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}
	
	return index;
}

stock int PrecacheMaterial(const char[] sMaterialName)
{
	static int iStringTableMaterials = INVALID_STRING_TABLE;
	if (iStringTableMaterials == INVALID_STRING_TABLE) 
	{
		if ((iStringTableMaterials = FindStringTable("Materials")) == INVALID_STRING_TABLE) return INVALID_STRING_INDEX;
	}
	
	int index = FindStringIndex2(iStringTableMaterials, sMaterialName);
	if (index == INVALID_STRING_INDEX) 
	{
		int numStrings = GetStringTableNumStrings(iStringTableMaterials);
		if (numStrings >= GetStringTableMaxStrings(iStringTableMaterials)) return INVALID_STRING_INDEX;
		
		AddToStringTable(iStringTableMaterials, sMaterialName);
		index = numStrings;
	}
	
	// For Linux, since Linux can be a bastard at times.
	char sBuffer[PLATFORM_MAX_PATH];
	Format(sBuffer, sizeof(sBuffer), "materials/%s", sMaterialName);
	PrecacheModel(sBuffer);
	
	return index;
}

stock int PrecacheVGUIScreen(const char[] sScreenType)
{
	static iStringTableMaterials = INVALID_STRING_TABLE;
	if (iStringTableMaterials == INVALID_STRING_TABLE) 
	{
		if ((iStringTableMaterials = FindStringTable("VguiScreen")) == INVALID_STRING_TABLE) return INVALID_STRING_INDEX;
	}
	
	int index = FindStringIndex2(iStringTableMaterials, sScreenType);
	if (index == INVALID_STRING_INDEX) 
	{
		int numStrings = GetStringTableNumStrings(iStringTableMaterials);
		if (numStrings >= GetStringTableMaxStrings(iStringTableMaterials)) return INVALID_STRING_INDEX;
		
		AddToStringTable(iStringTableMaterials, sScreenType);
		index = numStrings;
	}
	
	return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
	char buf[1024];
	
	for (int i = 0, numStrings = GetStringTableNumStrings(tableidx); i < numStrings; i++) 
	{
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		if (StrEqual(buf, str)) return i;
	}
	
	return INVALID_STRING_INDEX;
}

stock void PrecacheSound2(const char[] sPath)
{
	PrecacheSound(sPath, true);
	char sDownloadPath[PLATFORM_MAX_PATH];
	Format(sDownloadPath, sizeof(sDownloadPath), "sound/%s", sPath);
	AddFileToDownloadsTable(sDownloadPath);
}

stock void PrecacheModel2(const char[] sPath)
{
	PrecacheModel(sPath, true);
	AddFileToDownloadsTable(sPath);
	
	char sPath2[PLATFORM_MAX_PATH];
	strcopy(sPath2, sizeof(sPath2), sPath);
	ReplaceString(sPath2, sizeof(sPath2), ".mdl", "", false);
	
	char sDownloadPath[PLATFORM_MAX_PATH];
	char sExtensions[][] = { ".phy", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd" };
	
	for (int i = 0; i < sizeof(sExtensions); i++)
	{
		Format(sDownloadPath, sizeof(sDownloadPath), "%s%s", sPath2, sExtensions[i]);
		AddFileToDownloadsTable(sDownloadPath);
	}
}

stock void LerpVectors(const float fA[3], const float fB[3], float fC[3], float t)
{
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;
    
    fC[0] = fA[0] + (fB[0] - fA[0]) * t;
    fC[1] = fA[1] + (fB[1] - fA[1]) * t;
    fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

stock void CopyVectors(const float fFrom[3], float fTo[3])
{
    fTo[0] = fFrom[0];
    fTo[1] = fFrom[1];
    fTo[2] = fFrom[2];
}

stock int clamp(int value, int a, int b)
{
	if (value < a) return a;
	if (value > b) return b;
	return value;
}

stock float FloatClamp(float value, float a, float b)
{
	if (value < a) return a;
	if (value > b) return b;
	return value;
}

stock void VectorTransform(const float offset[3], const float worldpos[3], const float ang[3], float buffer[3])
{
	float fwd[3], right[3], up[3];
	GetAngleVectors(ang, fwd, right, up);
	
	NormalizeVector(fwd, fwd);
	NormalizeVector(right, right);
	NormalizeVector(up, up);
	
	ScaleVector(right, offset[1]);
	ScaleVector(fwd, offset[0]);
	ScaleVector(up, offset[2]);
	
	buffer[0] = worldpos[0] + right[0] + fwd[0] + up[0];
	buffer[1] = worldpos[1] + right[1] + fwd[1] + up[1];
	buffer[2] = worldpos[2] + right[2] + fwd[2] + up[2];
}

stock float AngleDiff(float firstAngle, float secondAngle)
{
	float diff = secondAngle - firstAngle;
	return AngleNormalize(diff);
}

stock float AngleNormalize(float angle)
{
	while (angle > 180.0) angle -= 360.0;
	while (angle < -180.0) angle += 360.0;
	return angle;
}

stock float FloatApproach(float a, float b, float c)
{
	if (FloatAbs(b - a) < FloatAbs(c)) return b;
	else
	{
		if (a > b) return a - c;
		else return a + c;
	}
}

stock void FloatToTimeHMS(float time, int &h, int &m, int &s)
{
	s = RoundFloat(time);
	h = s / 3600;
	s -= h * 3600;
	m = s / 60;
	s = s % 60;
}

public Action Timer_KillEntity(Handle timer, any entref)
{
	int ent = EntRefToEntIndex(entref);
	if (!ent || ent == INVALID_ENT_REFERENCE) return;
	AcceptEntityInput(ent, "Kill");
}

public Action Timer_StopEntity(Handle timer, any entref)
{
	int ent = EntRefToEntIndex(entref);
	if (!ent || ent == INVALID_ENT_REFERENCE) return;
	AcceptEntityInput(ent, "Stop");
}

public Action Timer_TurnOffEntity(Handle timer, any entref)
{
	int ent = EntRefToEntIndex(entref);
	if (!ent || ent == INVALID_ENT_REFERENCE) return;
	AcceptEntityInput(ent, "TurnOff");
}

public Action Timer_RegeneratePlayer(Handle timer, any entref)
{
	int ent = EntRefToEntIndex(entref);
	if (!ent || ent == INVALID_ENT_REFERENCE || !IsValidClient(ent)) return;
	TF2_RegeneratePlayer(ent);
}

public bool TraceRayDontHitEntity(int entity, int contentsMask, any data)
{
	if (entity == data) return false;
	return true;
}