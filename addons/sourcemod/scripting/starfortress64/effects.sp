#if defined _sf64_effects_included
  #endinput
#endif
#define _sf64_effects_included


stock int CreateEffect(EffectType iType, EffectEvent iEvent, int iOwner, int iCustomIndex=-1, bool bShouldCheckTeam=true, int &iIndex=-1)
{
	int iEffect = -1;
	switch (iType)
	{
		case EffectType_Sprite: iEffect = CreateEntityByName("env_sprite");
		case EffectType_Smokestack: iEffect = CreateEntityByName("env_smokestack");
		case EffectType_Smoketrail: iEffect = CreateEntityByName("env_smoketrail");
		case EffectType_Trail: iEffect = CreateEntityByName("env_spritetrail");
		case EffectType_ParticleSystem: iEffect = CreateEntityByName("info_particle_system");
	}
	
	if (iEffect != -1)
	{
		iIndex = PushArrayCell(g_hEffects, EntIndexToEntRef(iEffect));
		SetArrayCell(g_hEffects, iIndex, iType, Effect_Type);
		SetArrayCell(g_hEffects, iIndex, iEvent, Effect_Event);
		SetArrayCell(g_hEffects, iIndex, iOwner, Effect_Owner);
		SetArrayCell(g_hEffects, iIndex, iCustomIndex, Effect_CustomIndex);
		SetArrayCell(g_hEffects, iIndex, bShouldCheckTeam, Effect_ShouldCheckTeam);
		SetArrayCell(g_hEffects, iIndex, false, Effect_InKill);
	}
	
	return iEffect;
}

stock void EffectSetColor(int iEffect, int r, int g, int b, int a, int r2=255, int g2=255, int b2=255)
{
	int iIndex = FindValueInArray(g_hEffects, EntIndexToEntRef(iEffect));
	if (iIndex == -1) return;
	
	EffectType iType = GetArrayCell(g_hEffects, iIndex, Effect_Type);
	
	switch (iType)
	{
		case EffectType_Sprite:
		{
			SetVariantInt(r);
			AcceptEntityInput(iEffect, "ColorRedValue");
			SetVariantInt(g);
			AcceptEntityInput(iEffect, "ColorGreenValue");
			SetVariantInt(b);
			AcceptEntityInput(iEffect, "ColorBlueValue");
		}
		case EffectType_Smoketrail:
		{
			float flColor[3];
			flColor[0] = float(r);
			flColor[1] = float(g);
			flColor[2] = float(b);
			SetEntPropVector(iEffect, Prop_Send, "m_StartColor", flColor);
			flColor[0] = float(r2);
			flColor[1] = float(g2);
			flColor[2] = float(b2);
			SetEntPropVector(iEffect, Prop_Send, "m_EndColor", flColor);
			SetEntPropFloat(iEffect, Prop_Send, "m_Opacity", float(a));
		}
		case EffectType_Smokestack, EffectType_Trail:
		{
			char sForm[64];
			Format(sForm, sizeof(sForm), "%d %d %d", r, g, b);
			DispatchKeyValue(iEffect, "rendercolor", sForm);
		}
	}
}

stock void TurnOnEffect(int iEffect)
{
	if (!IsValidEntity(iEffect)) return;
	
	int iIndex = FindValueInArray(g_hEffects, EntIndexToEntRef(iEffect));
	if (iIndex == -1) return;
	
	EffectType iType = GetArrayCell(g_hEffects, iIndex, Effect_Type);
	
	switch (iType)
	{
		case EffectType_Sprite, EffectType_Trail: AcceptEntityInput(iEffect, "ShowSprite");
		case EffectType_Smokestack, EffectType_Smoketrail: SetEntProp(iEffect, Prop_Send, "m_bEmit", true);
		case EffectType_ParticleSystem: AcceptEntityInput(iEffect, "Start");
	}
}

stock void TurnOffEffect(int iEffect)
{
	if (!IsValidEntity(iEffect)) return;
	
	int iIndex = FindValueInArray(g_hEffects, EntIndexToEntRef(iEffect));
	if (iIndex == -1) return;
	
	EffectType iType = GetArrayCell(g_hEffects, iIndex, Effect_Type);
	
	switch (iType)
	{
		case EffectType_Sprite, EffectType_Trail: AcceptEntityInput(iEffect, "HideSprite");
		case EffectType_Smokestack, EffectType_Smoketrail: SetEntProp(iEffect, Prop_Send, "m_bEmit", false);
		case EffectType_ParticleSystem: StopEntity(iEffect);
	}
}

stock void RemoveEffect(int iEffect, bool bForce=false)
{
	if (!IsValidEntity(iEffect)) return;
	
	int iIndex = FindValueInArray(g_hEffects, EntIndexToEntRef(iEffect));
	if (iIndex == -1) return;
	
	if (!bForce && view_as<bool>(GetArrayCell(g_hEffects, iIndex, Effect_InKill))) return;
	
	SetArrayCell(g_hEffects, iIndex, true, Effect_InKill);
	
	float flPos[3];
	GetEntPropVector(iEffect, Prop_Data, "m_vecAbsOrigin", flPos);
	
	EffectType iType = GetArrayCell(g_hEffects, iIndex, Effect_Type);
	
	if (iType != EffectType_Trail)
	{
		TurnOffEffect(iEffect);
	}
	
	AcceptEntityInput(iEffect, "ClearParent");
	TeleportEntity(iEffect, flPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	
	float flDelay = 0.0;
	switch (iType)
	{
		case EffectType_Smokestack: flDelay = GetEntPropFloat(iEffect, Prop_Send, "m_JetLength") / GetEntPropFloat(iEffect, Prop_Send, "m_Speed");
		case EffectType_Trail: flDelay = GetEntPropFloat(iEffect, Prop_Send, "m_flLifeTime");
	}
	
	DeleteEntity(iEffect, flDelay);
}

stock void TurnOnEffectsOfEntityOfEvent(int iOwner, EffectEvent iEvent, bool bIgnoreKill=false)
{
	if (!IsValidEntity(iOwner)) return;
	
	int iEffect, iEffectOwner;
	EffectEvent iEffectEvent;

	for (int i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		if (!bIgnoreKill && view_as<bool>(GetArrayCell(g_hEffects, i, Effect_InKill))) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (iEffectOwner != iOwner) continue;
		
		iEffectEvent = view_as<EffectEvent>(GetArrayCell(g_hEffects, i, Effect_Event));
		if (iEvent == EffectEvent_All || iEffectEvent == iEvent)
		{
			TurnOnEffect(iEffect);
		}
	}
}

stock void TurnOffEffectsOfEntityOfEvent(int iOwner, EffectEvent iEvent, bool bIgnoreKill=false)
{
	if (!IsValidEntity(iOwner)) return;
	
	int iEffect, iEffectOwner;
	EffectEvent iEffectEvent;

	for (int i = 0, iSize = GetArraySize(g_hEffects); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(g_hEffects, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		if (!bIgnoreKill && view_as<bool>(GetArrayCell(g_hEffects, i, Effect_InKill))) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(g_hEffects, i, Effect_Owner));
		if (iEffectOwner != iOwner) continue;
		
		iEffectEvent = view_as<EffectEvent>(GetArrayCell(g_hEffects, i, Effect_Event));
		if (iEvent == EffectEvent_All || iEffectEvent == iEvent)
		{
			TurnOffEffect(iEffect);
		}
	}
}

stock void RemoveEffectsFromEntityOfEvent(int iOwner, EffectEvent iEvent, bool bForce=false)
{
	if (!IsValidEntity(iOwner)) return;
	
	Handle hArray = CloneArray(g_hEffects);
	
	int iEffect, iEffectOwner;
	EffectEvent iEffectEvent;

	for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		iEffect = EntRefToEntIndex(GetArrayCell(hArray, i));
		if (!iEffect || iEffect == INVALID_ENT_REFERENCE) continue;
		
		if (!bForce && view_as<bool>(GetArrayCell(hArray, i, Effect_InKill))) continue;
		
		iEffectOwner = EntRefToEntIndex(GetArrayCell(hArray, i, Effect_Owner));
		if (iEffectOwner != iOwner) continue;
		
		iEffectEvent = view_as<EffectEvent>(GetArrayCell(hArray, i, Effect_Event));
		if (iEvent == EffectEvent_All || iEffectEvent == iEvent)
		{
			RemoveEffect(iEffect, bForce);
		}
	}
	
	CloseHandle(hArray);
}

public Action Timer_EffectRemove(Handle timer, any entref)
{
	int iEffect = EntRefToEntIndex(entref);
	if (!iEffect || iEffect == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hEffects, entref);
	if (iIndex == -1) return;
	
	RemoveEffect(iEffect, true);
}

stock EffectType GetEffectTypeFromName(const char[] sName)
{
	if (StrEqual(sName, "sprite")) return EffectType_Sprite;
	else if (StrEqual(sName, "smokestack")) return EffectType_Smokestack;
	else if (StrEqual(sName, "smoketrail")) return EffectType_Smoketrail;
	else if (StrEqual(sName, "trail")) return EffectType_Trail;
	else if (StrEqual(sName, "particlesystem")) return EffectType_ParticleSystem;
	return EffectType_Invalid;
}

stock EffectEvent GetEffectEventFromName(const char[] sName)
{
	if (StrEqual(sName, "constant")) return EffectEvent_Constant;
	
#if defined _sf64_included
	else if (StrEqual(sName, "arwing_enabled")) return EffectEvent_ArwingEnabled;
	else if (StrEqual(sName, "arwing_fullenergy")) return EffectEvent_ArwingFullEnergy;
	else if (StrEqual(sName, "arwing_firelaser")) return EffectEvent_ArwingFireLaser;
	else if (StrEqual(sName, "arwing_firehyperlaser")) return EffectEvent_ArwingFireHyperLaser;
	else if (StrEqual(sName, "arwing_health_75pct")) return EffectEvent_ArwingHealth75Pct;
	else if (StrEqual(sName, "arwing_health_50pct")) return EffectEvent_ArwingHealth50Pct;
	else if (StrEqual(sName, "arwing_health_25pct")) return EffectEvent_ArwingHealth25Pct;
	else if (StrEqual(sName, "arwing_damaged")) return EffectEvent_ArwingDamaged;
	else if (StrEqual(sName, "arwing_destroyed")) return EffectEvent_ArwingDestroyed;
	else if (StrEqual(sName, "arwing_obliterated")) return EffectEvent_ArwingObliterated;
	else if (StrEqual(sName, "arwing_barrelroll")) return EffectEvent_ArwingBarrelRoll;
	else if (StrEqual(sName, "arwing_boost")) return EffectEvent_ArwingBoost;
	else if (StrEqual(sName, "arwing_brake")) return EffectEvent_ArwingBrake;
	else if (StrEqual(sName, "arwing_somersault")) return EffectEvent_ArwingSomersault;
	else if (StrEqual(sName, "arwing_uturn")) return EffectEvent_ArwingUTurn;
#endif
	
	return EffectEvent_Invalid;
}

stock void GetEffectEventName(EffectEvent iEvent, char[] sBuffer, int iBufferLen)
{
	switch (iEvent)
	{
		case EffectEvent_Constant: strcopy(sBuffer, iBufferLen, "constant");
		
#if defined _sf64_included
		case EffectEvent_ArwingEnabled: strcopy(sBuffer, iBufferLen, "arwing_enabled");
		case EffectEvent_ArwingFullEnergy: strcopy(sBuffer, iBufferLen, "arwing_fullenergy");
		case EffectEvent_ArwingFireLaser: strcopy(sBuffer, iBufferLen, "arwing_firelaser");
		case EffectEvent_ArwingFireHyperLaser: strcopy(sBuffer, iBufferLen, "arwing_firehyperlaser");
		case EffectEvent_ArwingHealth75Pct: strcopy(sBuffer, iBufferLen, "arwing_health_75pct");
		case EffectEvent_ArwingHealth50Pct: strcopy(sBuffer, iBufferLen, "arwing_health_50pct");
		case EffectEvent_ArwingHealth25Pct: strcopy(sBuffer, iBufferLen, "arwing_health_25pct");
		case EffectEvent_ArwingDamaged: strcopy(sBuffer, iBufferLen, "arwing_damaged");
		case EffectEvent_ArwingDestroyed: strcopy(sBuffer, iBufferLen, "arwing_destroyed");
		case EffectEvent_ArwingObliterated: strcopy(sBuffer, iBufferLen, "arwing_obliterated");
		case EffectEvent_ArwingBarrelRoll: strcopy(sBuffer, iBufferLen, "arwing_barrelroll");
		case EffectEvent_ArwingBoost: strcopy(sBuffer, iBufferLen, "arwing_boost");
		case EffectEvent_ArwingBrake: strcopy(sBuffer, iBufferLen, "arwing_brake");
		case EffectEvent_ArwingSomersault: strcopy(sBuffer, iBufferLen, "arwing_somersault");
		case EffectEvent_ArwingUTurn: strcopy(sBuffer, iBufferLen, "arwing_uturn");
#endif

		default: strcopy(sBuffer, iBufferLen, "");
	}
}