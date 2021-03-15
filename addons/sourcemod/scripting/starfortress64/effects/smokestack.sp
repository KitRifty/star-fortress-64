// Specialized smokestack class.


int EffectsCreateSmokeStack(int iBaseEnt, Handle hArray, int iArrayBlock=0)
{
	if (!iBaseEnt || !IsValidEntity(iBaseEnt)) return INVALID_ENT_REFERENCE;
	
	int iEnt = CreateEntityByName("env_smokestack");
	if (iEnt != -1)
	{
		// Material.
		char sMaterial[PLATFORM_MAX_PATH];
		GetEntPropString(iBaseEnt, Prop_Data, "m_strMaterialModel", sMaterial, sizeof(sMaterial));
	
		// Color.
		int iRenderColor[4] = { 255, ... };
		int iColorOffset = GetEntSendPropOffs(iBaseEnt, "m_clrRender", true);
		for (int i = 0; i < 4; i++) iRenderColor[i] = GetEntData(iBaseEnt, iColorOffset + i, 1);
		
		RenderMode iRenderMode = GetEntityRenderMode(iBaseEnt);
		RenderFx iRenderFx = GetEntityRenderFx(iBaseEnt);
	}
	
	return INVALID_ENT_REFERENCE;
}