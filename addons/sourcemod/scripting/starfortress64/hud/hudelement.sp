#if defined _sf64_hud_elements_included
  #endinput
#endif
#define _sf64_hud_elements_included


SetupHudElements()
{
	g_hHudElements = CreateArray(HudElement_MaxStats);
	
	RegConsoleCmd("sm_sf64_spawnhudelement", Command_SpawnHudElement);
}

public Action:Command_SpawnHudElement(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_sf64_spawnhudelement <material> <type> <width> <height>");
		return Plugin_Handled;
	}
	
	decl String:sType[64], String:sWidth[64], String:sHeight[64];
	GetCmdArg(1, sType, sizeof(sType));
	GetCmdArg(2, sWidth, sizeof(sWidth));
	GetCmdArg(3, sHeight, sizeof(sHeight));
	
	new iType = StringToInt(sType);
	new Float:flWidth = StringToFloat(sWidth);
	new Float:flHeight = StringToFloat(sHeight);
	
	decl Float:flEyePos[3], Float:flEyeAng[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	decl Float:flHitPos[3];
	new Handle:hTrace = TR_TraceRayFilterEx(flEyePos, flEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
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

SpawnHudElement(const Float:flPos[3],
	const Float:flAng[3],
	iType,
	iOwner,
	Float:flMinWidth,
	Float:flMaxWidth,
	Float:flMinHeight,
	Float:flMaxHeight,
	iCustomIndex=-1,
	&iIndex=-1)
{
	new iHudElement = CreateEntityByName("vgui_screen");
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

public Action:Timer_HudElementInitialize(Handle:timer, any:entref)
{
	new iHudElement = EntRefToEntIndex(entref);
	
	if (!iHudElement || iHudElement == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hHudElements, entref);
	if (iIndex == -1) return;
	
	SetArrayCell(g_hHudElements, iIndex, false, HudElement_Initializing);
	SetArrayCell(g_hHudElements, iIndex, INVALID_HANDLE, HudElement_InitializeTimer);
	SetEntProp(iHudElement, Prop_Send, "m_nOverlayMaterial", GetArrayCell(g_hHudElements, iIndex, HudElement_OverlayMaterial));
	
	AcceptEntityInput(iHudElement, "SetActive");
}