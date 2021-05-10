#if defined _sf64_ai_nodegraph_included
  #endinput
#endif
#define _sf64_ai_nodegraph_included


#define SF64_NODE_MAX_ID_LENGTH 512

enum
{
	AINodeType_Invalid = -1,
	AINodeType_Ground = 0,
	AINodeType_Air
};

enum
{
	AINode_ID = 0,
	AINode_Type,
	AINode_Links,
	AINode_PositionX,
	AINode_PositionY,
	AINode_PositionZ,
	AINode_MaxStats
};

enum
{
	AINodeLink_TargetNodeID = 0,
	AINodeLink_Enabled,
	AINodeLink_MaxStats
};

enum
{
	AINodeSet_NodeID = 0,
	AINodeSet_GScore,
	AINodeSet_FScore,
	AINodeSet_MaxStats
};

#define SF64_NODE_EDIT_FLAG_SHOW_NODES (1 << 0)
#define SF64_NODE_EDIT_FLAG_SHOW_LINKS (1 << 1)


Handle g_hAINodes;

int g_iPlayerNodeEditorFlags[MAXPLAYERS + 1];
int g_iPlayerCurrentNode[MAXPLAYERS + 1] = { -1, ... };

static int g_iNodeLaserModelIndex = -1;

void SetupAINodeGraph()
{
	g_hAINodes = CreateArray(AINode_MaxStats);
	
	RegConsoleCmd("sm_sf64_create_air_node", Command_CreateAIAirNode);
	RegConsoleCmd("sm_sf64_create_ground_node", Command_CreateAIGroundNode);
	RegConsoleCmd("sm_sf64_link_nodes", Command_LinkAINodes);
	RegConsoleCmd("sm_sf64_enable_node_link", Command_EnableAINodeLink);
	RegConsoleCmd("sm_sf64_unlink_nodes", Command_UnlinkAINodes);
	RegConsoleCmd("sm_sf64_show_nodes", Command_ShowAINodes);
	RegConsoleCmd("sm_sf64_show_node_links", Command_ShowAINodeLinks);
	RegConsoleCmd("sm_sf64_find_path_between_nodes", Command_FindPathBetweenAINodes);
	RegConsoleCmd("sm_sf64_get_node_id", Command_GetAINodeID);
	RegConsoleCmd("sm_sf64_save_nodes", Command_SaveAINodegraph);
}

void AINodeGraphOnMapStart()
{
	g_iNodeLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	GetAINodeGraphOfMap();
	CreateTimer(0.2, Timer_NodeGraphAppear, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void AINodeGraphOnClientPutInServer(int client)
{
	g_iPlayerNodeEditorFlags[client] = 0;
	g_iPlayerCurrentNode[client] = -1;
}

public Action Timer_NodeGraphAppear(Handle timer)
{
	static iNodeParticleSystem = -1;
	static iLinkParticleSystemActive = -1;
	static iLinkParticleSystemInactive = -1;
	
	if (iNodeParticleSystem == -1) iNodeParticleSystem = PrecacheParticleSystem("merasmus_zap_flash");
	if (iLinkParticleSystemActive == -1) iLinkParticleSystemActive = PrecacheParticleSystem("bullet_tracer02_red");
	if (iLinkParticleSystemInactive == -1) iLinkParticleSystemInactive = PrecacheParticleSystem("bullet_tracer01_crit");
	
	float flClientPos[3];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		if (g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_NODES ||
			g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_LINKS)
		{
			GetClientAbsOrigin(iClient, flClientPos);
			
			int iBestNodeID = GetClientAimNode(iClient);
			
			for (int iSmallestNode = 0, iSize = GetArraySize(g_hAINodes); iSmallestNode < iSize; iSmallestNode++)
			{
				int iSmallestNodeID = GetArrayCell(g_hAINodes, iSmallestNode);
				
				float flSmallestNodePos[3];
				GetAINodePosition(iSmallestNodeID, flSmallestNodePos);
				
				if (g_iPlayerCurrentNode[iClient] != iSmallestNodeID && GetVectorDistance(flClientPos, flSmallestNodePos) > 3500.0) continue;
				
				if (g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_NODES)
				{
					if (g_iPlayerCurrentNode[iClient] == -1 || iBestNodeID == g_iPlayerCurrentNode[iClient])
					{
						TE_SetupTFParticleEffect(iNodeParticleSystem,
							flSmallestNodePos,
							flSmallestNodePos);
						TE_SendToClient(iClient);
					}
				}
				
				if (g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_LINKS)
				{
					if (iSmallestNodeID == iBestNodeID || iBestNodeID == g_iPlayerCurrentNode[iClient])
					{
						Handle hSmallestNodeLinks = GetAINodeLinks(iSmallestNodeID); // pSmallestNode->GetNodeLinks();
						for (int iLinkedNode = 0, iLinkSize = GetArraySize(hSmallestNodeLinks); iLinkedNode < iLinkSize; iLinkedNode++)
						{
							float flLinkedNodePos[3];
							int iLinkedNodeID = GetArrayCell(hSmallestNodeLinks, iLinkedNode);
							GetAINodePosition(iLinkedNodeID, flLinkedNodePos);
							
							if (view_as<bool>(GetArrayCell(hSmallestNodeLinks, iLinkedNode, AINodeLink_Enabled)))
							{
								TE_SetupTFParticleEffect(iLinkParticleSystemActive,
									flSmallestNodePos,
									flSmallestNodePos,
									_,
									_,
									_,
									_,
									true,
									flLinkedNodePos);
								TE_SendToClient(iClient);
							}
							else
							{
								TE_SetupTFParticleEffect(iLinkParticleSystemInactive,
									flSmallestNodePos,
									flSmallestNodePos,
									_,
									_,
									_,
									_,
									true,
									flLinkedNodePos);
								TE_SendToClient(iClient);
							}
						}
					}
				}
			}
		}
	}
}

public Action Command_CreateAIAirNode(int client, int args)
{
	float flNodePos[3];
	GetClientAbsOrigin(client, flNodePos);
	
	int iNodeID = 0;
	while (FindValueInArray(g_hAINodes, iNodeID) != -1) iNodeID++;
	CreateAINode(AINodeType_Air, iNodeID, flNodePos);
	
	PrintToChat(client, "Created air node at your feet! (ID: %d)", iNodeID);
	
	return Plugin_Handled;
}

public Action Command_CreateAIGroundNode(int client, int args)
{
	float flNodePos[3];
	GetClientAbsOrigin(client, flNodePos);
	
	int iNodeID = 0;
	while (FindValueInArray(g_hAINodes, iNodeID) != -1) iNodeID++;
	CreateAINode(AINodeType_Ground, iNodeID, flNodePos);
	
	PrintToChat(client, "Created ground node at your feet! (ID: %d)", iNodeID);
	
	return Plugin_Handled;
}

public Action Command_LinkAINodes(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_link_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	LinkAINodeToAINode(StringToInt(sNodeID), StringToInt(sTargetNodeID), true);
	
	return Plugin_Handled;
}

public Action Command_EnableAINodeLink(int client, int args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_sf64_enable_node_link <start node id> <end node id> <0/1>");
		return Plugin_Handled;
	}
	
	char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], sEnable[64];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	GetCmdArg(3, sEnable, sizeof(sEnable));
	
	EnableAINodeLink(StringToInt(sNodeID), StringToInt(sTargetNodeID), bool StringToInt(sEnable));
	
	return Plugin_Handled;
}

public Action Command_UnlinkAINodes(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_unlink_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	UnlinkAINodeFromAINode(StringToInt(sNodeID), StringToInt(sTargetNodeID));
	
	return Plugin_Handled;
}

public Action Command_ShowAINodes(int client, int args)
{
	if (!(g_iPlayerNodeEditorFlags[client] & SF64_NODE_EDIT_FLAG_SHOW_NODES))
	{
		g_iPlayerNodeEditorFlags[client] |= SF64_NODE_EDIT_FLAG_SHOW_NODES;
		PrintToChat(client, "Node display enabled.");
	}
	else
	{
		g_iPlayerNodeEditorFlags[client] &= ~SF64_NODE_EDIT_FLAG_SHOW_NODES;
		PrintToChat(client, "Node display disabled.");
	}
	
	return Plugin_Handled;
}

public Action Command_ShowAINodeLinks(int client, int args)
{
	if (!(g_iPlayerNodeEditorFlags[client] & SF64_NODE_EDIT_FLAG_SHOW_LINKS))
	{
		g_iPlayerNodeEditorFlags[client] |= SF64_NODE_EDIT_FLAG_SHOW_LINKS;
		PrintToChat(client, "Node link display enabled.");
	}
	else
	{
		g_iPlayerNodeEditorFlags[client] &= ~SF64_NODE_EDIT_FLAG_SHOW_LINKS;
		PrintToChat(client, "Node link display disabled.");
	}
	
	return Plugin_Handled;
}

public Action Command_FindPathBetweenAINodes(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_find_path_between_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	int iNodeID = StringToInt(sNodeID);
	int iTargetNodeID = StringToInt(sTargetNodeID);
	
	if (FindValueInArray(g_hAINodes, iNodeID) == -1)
	{
		PrintToChat(client, "Starting node does not exist!");
		return Plugin_Handled;
	}
	
	if (FindValueInArray(g_hAINodes, iTargetNodeID) == -1)
	{
		PrintToChat(client, "Ending node does not exist!");
		return Plugin_Handled;
	}
	
	bool bPathSuccess = false;
	Handle hNodes = AINodeFindBestPath(iNodeID, iTargetNodeID, bPathSuccess);
	
	int iColor[4] = { 0, 255, 0, 255 };
	if (!bPathSuccess)
	{
		iColor[0] = 255;
		iColor[1] = 0;
		iColor[2] = 0;
		iColor[3] = 255;
	}
	
	int iPrevNodeID = -1, iCurrentNodeID = -1;
	for (int i = 0, iSize = GetArraySize(hNodes); i < iSize; i++)
	{
		iCurrentNodeID = GetArrayCell(hNodes, i);
	
		if (iPrevNodeID != -1)
		{
			float flPrevNodePos[3], flCurrentNodePos[3];
			GetAINodePosition(iPrevNodeID, flPrevNodePos);
			GetAINodePosition(iCurrentNodeID, flCurrentNodePos);
			
			TE_SetupBeamPoints(flPrevNodePos,
				flCurrentNodePos,
				g_iNodeLaserModelIndex,
				g_iNodeLaserModelIndex,
				0,
				30,
				2.0,
				1.5,
				1.5,
				1,
				0.0,
				iColor,
				30);
			TE_SendToClient(client);
		}
		
		iPrevNodeID = iCurrentNodeID;
	}
	
	CloseHandle(hNodes);
	
	return Plugin_Handled;
}

public Action Command_GetAINodeID(int client, int args)
{
	int iNodeID = GetClientAimNode(client);
	PrintToChat(client, "iNodeID: %d", iNodeID);
	
	return Plugin_Handled;
}

public Action Command_SaveAINodegraph(int client, int args)
{
	if (SaveAINodeGraphOfMap()) PrintToChat(client, "Nodegraph saved successfully!");
	else PrintToChat(client, "Failed to save the nodegraph!");
	
	return Plugin_Handled;
}

stock int GetClientAimNode(int client)
{
	if (!IsValidClient(client)) return -1;
	
	float flEyePos[3], flEyeAng[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	int iBestNodeID = -1;
	bool bBestNodeDistance = false;
	bool bBestNodeAngDistance = false;
	float flBestNodeDistance = -1.0;
	float flBestNodeAngDistance = -1.0;
	int iTempNodeID = -1;
	float flTempNodePos[3], flDirection[3];
	Handle hTrace;
	
	for (int iTempNode = 0, iSize = GetArraySize(g_hAINodes); iTempNode < iSize; iTempNode++)
	{
		iTempNodeID = GetArrayCell(g_hAINodes, iTempNode);
		GetAINodePosition(iTempNodeID, flTempNodePos);
		
		// Check for visibility first.
		hTrace = TR_TraceRayFilterEx(flEyePos, flTempNodePos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceRayDontHitEntity, client);
		bool bHit = TR_DidHit(hTrace);
		CloseHandle(hTrace);
		
		if (bHit) continue;
		
		// Check distance.
		float flDist = GetVectorDistance(flEyePos, flTempNodePos);
		if (!bBestNodeDistance || flDist < flBestNodeDistance)
		{
			// Check angle distance.
			SubtractVectors(flTempNodePos, flEyePos, flDirection);
			GetVectorAngles(flDirection, flDirection);
			float flAngDist = FloatAbs(AngleDiff(flDirection[0], flEyeAng[0])) + FloatAbs(AngleDiff(flDirection[1], flEyeAng[1]));
			
			if (flAngDist <= 30.0 && (!bBestNodeAngDistance || flAngDist < flBestNodeAngDistance))
			{
				iBestNodeID = iTempNodeID;
				bBestNodeDistance = true;
				bBestNodeAngDistance = true;
				flBestNodeDistance = flDist;
				flBestNodeAngDistance = flAngDist;
			}
		}
	}
	
	return iBestNodeID;
}

bool GetAINodeGraphOfMap()
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/arwing/nodegraphs/%s.cfg", sMapName);
	
	Handle hConfig = CreateKeyValues("root");
	if (!FileToKeyValues(hConfig, sPath))
	{
		LogError("Nodegraph for %s could not be found!", sMapName);
	}
	else
	{
		LogMessage("Found nodegraph file for map %s! Removing old nodegraph...", sMapName);
		
		ClearAINodeGraph();
		
		LogMessage("Constructing new node graph...");
		
		KvRewind(hConfig);
		if (KvGotoFirstSubKey(hConfig))
		{
			char sNodeID[SF64_NODE_MAX_ID_LENGTH], sNodeType[64];
			int iNodeID, iNodeType;
			float flNodePos[3];
			
			do
			{
				KvGetSectionName(hConfig, sNodeID, sizeof(sNodeID));
				iNodeID = StringToInt(sNodeID);
				
				// Check our node type first.
				KvGetString(hConfig, "type", sNodeType, sizeof(sNodeType));
				if (StrEqual(sNodeType, "ground", false)) iNodeType = AINodeType_Ground;
				else if (StrEqual(sNodeType, "air", false)) iNodeType = AINodeType_Air;
				else iNodeType = AINodeType_Invalid;
				
				if (iNodeType != AINodeType_Invalid)
				{
					KvGetVector(hConfig, "origin", flNodePos);
					CreateAINode(iNodeType, iNodeID, flNodePos);
				}
				else
				{
					LogError("Could not create node (ID: %d): type is invalid!", iNodeID);
				}
			}
			while (KvGotoNextKey(hConfig));
		}
		
		LogMessage("Linking nodes...");
		
		Handle hNodeArray = CreateArray(SF64_NODE_MAX_ID_LENGTH);
		
		// Get the IDs of all the nodes and store them for future iteration.
		KvRewind(hConfig);
		if (KvGotoFirstSubKey(hConfig))
		{
			char sNodeID[SF64_NODE_MAX_ID_LENGTH];
			
			do
			{
				KvGetSectionName(hConfig, sNodeID, sizeof(sNodeID));
				PushArrayString(hNodeArray, sNodeID);
			}
			while (KvGotoNextKey(hConfig));
		}
		
		if (GetArraySize(hNodeArray) > 0)
		{
			char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], iNodeID, iTargetNodeID;
			
			for (int i = 0, iSize = GetArraySize(hNodeArray); i < iSize; i++)
			{
				GetArrayString(hNodeArray, i, sNodeID, sizeof(sNodeID));
				iNodeID = StringToInt(sNodeID);
				
				KvRewind(hConfig);
				if (KvJumpToKey(hConfig, sNodeID) && KvJumpToKey(hConfig, "links") && KvGotoFirstSubKey(hConfig))
				{
					do
					{
						KvGetSectionName(hConfig, sTargetNodeID, sizeof(sTargetNodeID));
						iTargetNodeID = StringToInt(sTargetNodeID);
						
						LinkAINodeToAINode(iNodeID, iTargetNodeID, bool KvGetNum(hConfig, "enabled", 1));
					}
					while (KvGotoNextKey(hConfig));
				}
			}
		}
		
		CloseHandle(hNodeArray);
		
		LogMessage("Node graph construction successful!");
	}
	
	CloseHandle(hConfig);
	
	return true;
}

bool SaveAINodeGraphOfMap()
{
	char sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/arwing/nodegraphs/%s.cfg", sMapName);
	
	LogMessage("Saving nodegraph for map %s...", sMapName);
	
	Handle hConfig = CreateKeyValues("Nodegraph");
	
	if (GetArraySize(g_hAINodes) > 0)
	{
		char sNodeID[SF64_NODE_MAX_ID_LENGTH], sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], sNodeType[64];
		int iNodeID, iNodeType, iTargetNodeID;
		float flNodePos[3];
		Handle hNodeLinks;
		
		for (int i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
		{
			iNodeID = GetArrayCell(g_hAINodes, i);
			iNodeType = GetArrayCell(g_hAINodes, i, AINode_Type);
			hNodeLinks = view_as<Handle>(GetArrayCell(g_hAINodes, i, AINode_Links));
			flNodePos[0] = view_as<float>(GetArrayCell(g_hAINodes, i, AINode_PositionX));
			flNodePos[1] = view_as<float>(GetArrayCell(g_hAINodes, i, AINode_PositionY));
			flNodePos[2] = view_as<float>(GetArrayCell(g_hAINodes, i, AINode_PositionZ));
			IntToString(iNodeID, sNodeID, sizeof(sNodeID));
			
			switch (iNodeType)
			{
				case AINodeType_Ground: strcopy(sNodeType, sizeof(sNodeType), "ground");
				case AINodeType_Air: strcopy(sNodeType, sizeof(sNodeType), "air");
				default: strcopy(sNodeType, sizeof(sNodeType), "invalid");
			}
			
			KvRewind(hConfig);
			if (KvJumpToKey(hConfig, sNodeID, true))
			{
				KvSetVector(hConfig, "origin", flNodePos);
				KvSetString(hConfig, "type", sNodeType);
				
				if (GetArraySize(hNodeLinks))
				{
					if (KvJumpToKey(hConfig, "links", true))
					{
						for (int iNodeLink = 0, iNumLinks = GetArraySize(hNodeLinks); iNodeLink < iNumLinks; iNodeLink++)
						{
							iTargetNodeID = GetArrayCell(hNodeLinks, iNodeLink);
							IntToString(iTargetNodeID, sTargetNodeID, sizeof(sTargetNodeID));
							
							if (KvJumpToKey(hConfig, sTargetNodeID, true))
							{
								KvSetNum(hConfig, "enabled", IsAINodeLinkEnabled(iNodeID, iTargetNodeID));
								KvGoBack(hConfig);
							}
						}
					}
				}
			}
		}
	}
	
	bool bSuccess = false;
	
	KvRewind(hConfig);
	if (KeyValuesToFile(hConfig, sPath))
	{
		bSuccess = true;
		LogMessage("Saved nodegraph successfully to file: %s", sPath);
	}
	else
	{
		LogMessage("Unable to save nodegraph!");
	}
	
	CloseHandle(hConfig);
	
	return bSuccess;
}

void ClearAINodeGraph()
{
	if (GetArraySize(g_hAINodes) <= 0) return;
	
	Handle hArray = CloneArray(g_hAINodes);
	for (int i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		RemoveAINode(GetArrayCell(hArray, i));
	}
	
	CloseHandle(hArray);
}

int CreateAINode(int iNodeType, int iNodeID, const float flPos[3])
{
	if (iNodeID < 0)
	{
		LogError("Could not create node: ID is out of range! (ID: %d)", iNodeID);
		return -1;
	}

	if (FindValueInArray(g_hAINodes, iNodeID) != -1)
	{
		LogError("Could not create node: there already is a node with the same ID! (ID: %d)", iNodeID);
		return -1;
	}
	
	int iIndex = PushArrayCell(g_hAINodes, iNodeID);
	SetArrayCell(g_hAINodes, iIndex, iNodeType, AINode_Type);
	SetArrayCell(g_hAINodes, iIndex, CreateArray(AINodeLink_MaxStats), AINode_Links);
	SetArrayCell(g_hAINodes, iIndex, flPos[0], AINode_PositionX);
	SetArrayCell(g_hAINodes, iIndex, flPos[1], AINode_PositionY);
	SetArrayCell(g_hAINodes, iIndex, flPos[2], AINode_PositionZ);
	
	return iIndex;
}

void RemoveAINode(int iNodeID)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return;
	
	Handle hLinks = view_as<Handle>(GetArrayCell(g_hAINodes, iIndex, AINode_Links));
	CloseHandle(hLinks);
	SetArrayCell(g_hAINodes, iIndex, INVALID_HANDLE, AINode_Links);
	
	// Iterate through all nodes in the graph to make sure that they unlink from this node.
	int iNodeID2, iNodeLinkIndex;
	for (int i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
	{
		iNodeID2 = GetArrayCell(g_hAINodes, i, AINode_ID);
		if (iNodeID2 == iNodeID) continue;
		
		hLinks = view_as<Handle>(GetArrayCell(g_hAINodes, i, AINode_Links));
		iNodeLinkIndex = FindValueInArray(hLinks, iNodeID);
		if (iNodeLinkIndex != -1)
		{
			UnlinkAINodeFromAINode(iNodeID2, iNodeID);
		}
	}
	
	RemoveFromArray(g_hAINodes, iIndex);
}

bool LinkAINodeToAINode(int iNodeID, int iTargetNodeID, bool bEnable)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) 
	{
		LogError("Could not link starting node (ID: %d) to target node (ID: %d): starting node does not exist!", iNodeID, iTargetNodeID);
		return false;
	}
	
	if (iNodeID == iTargetNodeID)
	{
		LogError("Could not link starting node (ID: %d): A node cannot link to itself!", iNodeID);
		return false;
	}
	
	int iTargetIndex = FindValueInArray(g_hAINodes, iTargetNodeID);
	if (iTargetIndex == -1)
	{
		LogError("Could not link starting node (ID: %d) to target node (ID: %d): target node does not exist!", iNodeID, iTargetNodeID);
		return false;
	}
	
	if (GetArrayCell(g_hAINodes, iIndex, AINode_Type) != GetArrayCell(g_hAINodes, iTargetIndex, AINode_Type))
	{
		LogError("Could not link starting node (ID: %d) to target node (ID: %d): A node cannot link to a node of a different type!", iNodeID, iTargetNodeID);
		return false;
	}
	
	if (!IsAINodeLinkedToAINode(iNodeID, iTargetNodeID))
	{
		Handle hLinks = view_as<Handle>(GetArrayCell(g_hAINodes, iIndex, AINode_Links));
		int iNodeLinkIndex = PushArrayCell(hLinks, iTargetNodeID);
		SetArrayCell(hLinks, iNodeLinkIndex, bEnable, AINodeLink_Enabled);
		
		return true;
	}
	else
	{
		LogMessage("Could not link starting node (ID: %d) to target node (ID: %d): starting node is already linked to target node!", iNodeID, iTargetNodeID);
	}
	
	return false;
}

void UnlinkAINodeFromAINode(int iNodeID, int iTargetNodeID)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1)
	{
		LogError("Could not unlink starting node (ID: %d) from target node (ID: %d): starting node does not exist!", iNodeID, iTargetNodeID);
		return;
	}
	
	if (IsAINodeLinkedToAINode(iNodeID, iTargetNodeID))
	{
		Handle hLinks = view_as<Handle>(GetArrayCell(g_hAINodes, iIndex, AINode_Links));
		RemoveFromArray(hLinks, FindValueInArray(hLinks, iTargetNodeID));
	}
	else
	{
		LogMessage("Could not unlink starting node (ID: %d) from target node (ID: %d): starting node is already unlinked to target node!", iNodeID, iTargetNodeID);
	}
}

void EnableAINodeLink(int iNodeID, int iTargetNodeID, bool bEnable)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return;
	
	int iTargetIndex = FindValueInArray(g_hAINodes, iTargetNodeID);
	if (iTargetIndex == -1) return;
	
	Handle hLinks = view_as<Handle>(GetArrayCell(g_hAINodes, iIndex, AINode_Links));
	int iNodeLinkIndex = FindValueInArray(hLinks, iTargetNodeID);
	if (iNodeLinkIndex != -1)
	{
		SetArrayCell(hLinks, iNodeLinkIndex, bEnable, AINodeLink_Enabled);
	}
}

bool IsAINodeLinkedToAINode(int iNodeID, int iTargetNodeID)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return false;
	
	Handle hLinks = GetAINodeLinks(iNodeID); // pNode->GetNodeLinks();
	return bool (FindValueInArray(hLinks, iTargetNodeID) != -1);
}

bool IsAINodeLinkEnabled(int iNodeID, int iTargetNodeID)
{
	if (!IsAINodeLinkedToAINode(iNodeID, iTargetNodeID)) return false;
	
	Handle hLinks = GetAINodeLinks(iNodeID); // pNode->GetNodeLinks();
	return view_as<bool>(GetArrayCell(hLinks, FindValueInArray(hLinks, iTargetNodeID), AINodeLink_Enabled));
}

Handle AINodeFindBestPath(int iNodeID, int iTargetNodeID, bool &bSuccess=false)
{
	if (!GetArraySize(g_hAINodes)) 
	{
		bSuccess = false;
		return CreateArray();
	}
	
	Handle hTraversedNodes = CreateArray();
	
	Handle hOpenSet = CreateArray(AINodeSet_MaxStats);
	int iOpenSetIndex = PushArrayCell(hOpenSet, iNodeID);
	SetArrayCell(hOpenSet, iOpenSetIndex, 0.0, AINodeSet_GScore);
	SetArrayCell(hOpenSet, iOpenSetIndex, 0.0 + GetAINodeHeuristicCost(iNodeID, iTargetNodeID), AINodeSet_FScore); // F score.
	
	Handle hClosedSet = CreateArray(AINodeSet_MaxStats);
	
	int iCurrentNodeID, iCurrentNodeIDOpenSetIndex, iTempNodeID;
	Handle hCurrentNodeLinks;
	float flTempFScore, flBestFScore, flCurrentNodeGScore;
	bool bHasBestFScore;
	
	bSuccess = false;
	
	while (GetArraySize(hOpenSet) > 0)
	{
		// First, get the node with the lowest F score in the open set.
		iCurrentNodeID = -1;
		iCurrentNodeIDOpenSetIndex = -1;
		bHasBestFScore = false;
		
		for (int i = 0, iSize = GetArraySize(hOpenSet); i < iSize; i++)
		{
			iTempNodeID = GetArrayCell(hOpenSet, i);
			flTempFScore = view_as<float>(GetArrayCell(hOpenSet, i, AINodeSet_FScore));
			if (!bHasBestFScore || flTempFScore < flBestFScore)
			{
				iCurrentNodeID = iTempNodeID;
				iCurrentNodeIDOpenSetIndex = i;
				bHasBestFScore = true;
				flBestFScore = flTempFScore;
			}
		}
		
		if (iCurrentNodeID == iTargetNodeID)
		{
			bSuccess = true;
			PushArrayCell(hTraversedNodes, iTargetNodeID);
			break;
		}
		
		flCurrentNodeGScore = view_as<float>(GetArrayCell(hOpenSet, iCurrentNodeIDOpenSetIndex, AINodeSet_GScore));
		
		RemoveFromArray(hOpenSet, iCurrentNodeIDOpenSetIndex);
		PushArrayCell(hClosedSet, iCurrentNodeID);
		
		hCurrentNodeLinks = GetAINodeLinks(iCurrentNodeID);
		for (int i = 0, iSize = GetArraySize(hCurrentNodeLinks); i < iSize; i++)
		{
			int iNeighborNodeID = GetArrayCell(hCurrentNodeLinks, i);
			if (!IsAINodeLinkEnabled(iCurrentNodeID, iNeighborNodeID)) continue;
			
			float flTentativeGScore = flCurrentNodeGScore + GetAINodeHeuristicCost(iCurrentNodeID, iNeighborNodeID);
			
			int iNeighborNodeIDClosedSetIndex = FindValueInArray(hClosedSet, iNeighborNodeID);
			if (iNeighborNodeIDClosedSetIndex != -1 && flTentativeGScore >= view_as<float>(GetArrayCell(hClosedSet, iNeighborNodeIDClosedSetIndex, AINodeSet_GScore)))
			{
				continue;
			}
			
			int iNeighborNodeIDOpenSetIndex = FindValueInArray(hOpenSet, iNeighborNodeID);
			if (iNeighborNodeIDOpenSetIndex == -1 || flTentativeGScore < view_as<float>(GetArrayCell(hOpenSet, iNeighborNodeIDOpenSetIndex, AINodeSet_GScore)))
			{
				PushArrayCell(hTraversedNodes, iCurrentNodeID);
				
				if (iNeighborNodeIDOpenSetIndex == -1) iNeighborNodeIDOpenSetIndex = PushArrayCell(hOpenSet, iNeighborNodeID);
				
				SetArrayCell(hOpenSet, iNeighborNodeIDOpenSetIndex, flTentativeGScore, AINodeSet_GScore);
				SetArrayCell(hOpenSet, iNeighborNodeIDOpenSetIndex, flTentativeGScore + GetAINodeHeuristicCost(iNeighborNodeID, iTargetNodeID), AINodeSet_FScore);
			}
		}
	}
	
	CloseHandle(hOpenSet);
	CloseHandle(hClosedSet);
	
	return hTraversedNodes;
}

static float GetAINodeHeuristicCost(int iNodeID, int iTargetNodeID)
{
	float flNodePos[3], flTargetNodePos[3];
	GetAINodePosition(iNodeID, flNodePos);
	GetAINodePosition(iTargetNodeID, flTargetNodePos);
	
	return GetVectorDistance(flNodePos, flTargetNodePos);
}

stock bool GetAINodePosition(int iNodeID, float flBuffer[3])
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return false;
	
	flBuffer[0] = view_as<float>(GetArrayCell(g_hAINodes, iIndex, AINode_PositionX));
	flBuffer[1] = view_as<float>(GetArrayCell(g_hAINodes, iIndex, AINode_PositionY));
	flBuffer[2] = view_as<float>(GetArrayCell(g_hAINodes, iIndex, AINode_PositionZ));
	
	return true;
}

stock Handle GetAINodeLinks(int iNodeID)
{
	int iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) 
	{
		LogError("Could not retrieve links of node (ID: %d): node does not exist!", iNodeID);
		return INVALID_HANDLE;
	}
	
	return view_as<Handle>(GetArrayCell(g_hAINodes, iIndex, AINode_Links));
}

stock int GetNearestAINodeToPoint(const float flPos[3], float flTolerance=512.0)
{
	float flNodePos[3];
	int iBestNodeID = -1;
	float flBestDistance = flTolerance;
	if (flTolerance < 0.0) flBestDistance = 16384.0;
	
	float flDist;
	
	for (int i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
	{
		GetAINodePosition(GetArrayCell(g_hAINodes, i), flNodePos);
		
		flDist = GetVectorDistance(flPos, flNodePos);
		if (flDist < flBestDistance)
		{
			iBestNodeID = GetArrayCell(g_hAINodes, i);
			flBestDistance = flDist;
		}
	}
	
	return iBestNodeID;
}

stock int FindAINodeByID(int iNodeID) return FindValueInArray(g_hAINodes, iNodeID);