#if defined _sf64_hud_elements_included
  #endinput
#endif
#define _sf64_hud_elements_included


void SetupHudElements()
{
	g_hHudElements = CreateArray(HudElement_MaxStats);
	
	RegConsoleCmd("sm_sf64_spawnhudelement", Command_SpawnHudElement);
}

public Action Command_SpawnHudElement(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_sf64_spawnhudelement <material> <type> <width> <height>");
		return Plugin_Handled;
	}
	
	char sType[64], sWidth[64], sHeight[64];
	GetCmdArg(1, sType, sizeof(sType));
	GetCmdArg(2, sWidth, sizeof(sWidth));
	GetCmdArg(3, sHeight, sizeof(sHeight));
	
	int iType = StringToInt(sType);
	float flWidth = StringToFloat(sWidth);
	float flHeight = StringToFloat(sHeight);
	
	float flEyePos[3], flEyeAng[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	float flHitPos[3];
	Handle hTrace = TR_TraceRayFilterEx(flEyePos, flEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
	TR_GetEndPosition(flHitPos, hTrace);
	CloseHandle(hTrace);
	
	SpawnHudElement(flHitPos,
		NULL_VECTOR,
		iType,
		INVALID_ENT_REFERENCE,
		flWidth,
		flWidth,
		flHeight,
		flHeight
	);
	
	return Plugin_Handled;
}

int SpawnHudElement(const float flPos[3],
	const float flAng[3],
	int iType,
	int iOwner,
	float flMinWidth,
	float flMaxWidth,
	float flMinHeight,
	float flMaxHeight,
	int iCustomIndex=-1,
	int &iIndex=-1)
{
	int iHudElement = CreateEntityByName("vgui_screen");
	if (iHudElement != -1)
	{
		DispatchKeyValue(iHudElement, "panelname", "pda_panel_spy");
		SetEntPropEnt(iHudElement, Prop_Send, "m_hOwnerEntity", iOwner);
		SetEntPropFloat(iHudElement, Prop_Send, "m_flWidth", flMinWidth);
		SetEntPropFloat(iHudElement, Prop_Send, "m_flHeight", flMinHeight);
		TeleportEntity(iHudElement, flPos, flAng, NULL_VECTOR);
		SetEntProp(iHudElement, Prop_Send, "m_nOverlayMaterial", OVERLAY_MATERIAL_INVALID_STRING);
		
		iIndex = PushArrayCell(g_hHudElements, EntIndexToEntRef(iHudElement));
		SetArrayCell(g_hHudElements, iIndex, iType, HudElement_Type);
		SetArrayCell(g_hHudElements, iIndex, IsValidEntity(iOwner) ? EntIndexToEntRef(iOwner) : INVALID_ENT_REFERENCE, HudElement_Owner);
		SetArrayCell(g_hHudElements, iIndex, flMinWidth, HudElement_MinWidth);
		SetArrayCell(g_hHudElements, iIndex, flMaxWidth, HudElement_MaxWidth);
		SetArrayCell(g_hHudElements, iIndex, flMinHeight, HudElement_MinHeight);
		SetArrayCell(g_hHudElements, iIndex, flMaxHeight, HudElement_MaxHeight);
		SetArrayCell(g_hHudElements, iIndex, iCustomIndex, HudElement_CustomIndex);
		SetArrayCell(g_hHudElements, iIndex, true, HudElement_Initializing);
		SetArrayCell(g_hHudElements, iIndex, OVERLAY_MATERIAL_INVALID_STRING, HudElement_OverlayMaterial);
		SetArrayCell(g_hHudElements, iIndex, CreateTimer(0.25, Timer_HudElementInitialize, EntIndexToEntRef(iHudElement), TIMER_FLAG_NO_MAPCHANGE), HudElement_InitializeTimer);
	}
	
	return iHudElement;
}

public Action Timer_HudElementInitialize(Handle timer, any entref)
{
	int iHudElement = EntRefToEntIndex(entref);
	
	if (!iHudElement || iHudElement == INVALID_ENT_REFERENCE) return;
	
	int iIndex = FindValueInArray(g_hHudElements, entref);
	if (iIndex == -1) return;
	
	SetArrayCell(g_hHudElements, iIndex, false, HudElement_Initializing);
	SetArrayCell(g_hHudElements, iIndex, INVALID_HANDLE, HudElement_InitializeTimer);
	SetEntProp(iHudElement, Prop_Send, "m_nOverlayMaterial", GetArrayCell(g_hHudElements, iIndex, HudElement_OverlayMaterial));
	
	AcceptEntityInput(iHudElement, "SetActive");
}