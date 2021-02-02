// Specialized smokestack class.


EffectsCreateSmokeStack(iBaseEnt, Handle:hArray, iArrayBlock=0)
{
	if (!iBaseEnt || !IsValidEntity(iBaseEnt)) return INVALID_ENT_REFERENCE;
	
	new iEnt = CreateEntityByName("env_smokestack");
	if (iEnt != -1)
	{
		// Material.
		decl String:sMaterial[PLATFORM_MAX_PATH];
		GetEntPropString(iBaseEnt, Prop_Data, "m_strMaterialModel", sMaterial, sizeof(sMaterial));
	
		// Color.
		new iRenderColor[4] = { 255, ... };
		new iColorOffset = GetEntSendPropOffs(iBaseEnt, "m_clrRender", true);
		for (new i = 0; i < 4; i++) iRenderColor[i] = GetEntData(iBaseEnt, iColorOffset + i, 1);
		
		new RenderMode:iRenderMode = GetEntityRenderMode(iBaseEnt);
		new RenderFx:iRenderFx = GetEntityRenderFx(iBaseEnt);
		new iRenderAmt = 
	}
	
	return INVALID_ENT_REFERENCE;
}