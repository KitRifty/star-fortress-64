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


new Handle:g_hAINodes;

new g_iPlayerNodeEditorFlags[MAXPLAYERS + 1];
new g_iPlayerCurrentNode[MAXPLAYERS + 1] = { -1, ... };

static g_iNodeLaserModelIndex = -1;

SetupAINodeGraph()
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

AINodeGraphOnMapStart()
{
	g_iNodeLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	GetAINodeGraphOfMap();
	CreateTimer(0.2, Timer_NodeGraphAppear, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

AINodeGraphOnClientPutInServer(client)
{
	g_iPlayerNodeEditorFlags[client] = 0;
	g_iPlayerCurrentNode[client] = -1;
}

public Action:Timer_NodeGraphAppear(Handle:timer)
{
	static iNodeParticleSystem = -1;
	static iLinkParticleSystemActive = -1;
	static iLinkParticleSystemInactive = -1;
	
	if (iNodeParticleSystem == -1) iNodeParticleSystem = PrecacheParticleSystem("merasmus_zap_flash");
	if (iLinkParticleSystemActive == -1) iLinkParticleSystemActive = PrecacheParticleSystem("bullet_tracer02_red");
	if (iLinkParticleSystemInactive == -1) iLinkParticleSystemInactive = PrecacheParticleSystem("bullet_tracer01_crit");
	
	decl Float:flClientPos[3];
	
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient)) continue;
		if (g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_NODES ||
			g_iPlayerNodeEditorFlags[iClient] & SF64_NODE_EDIT_FLAG_SHOW_LINKS)
		{
			GetClientAbsOrigin(iClient, flClientPos);
			
			new iBestNodeID = GetClientAimNode(iClient);
			
			for (new iSmallestNode = 0, iSize = GetArraySize(g_hAINodes); iSmallestNode < iSize; iSmallestNode++)
			{
				new iSmallestNodeID = GetArrayCell(g_hAINodes, iSmallestNode);
				
				decl Float:flSmallestNodePos[3];
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
						new Handle:hSmallestNodeLinks = GetAINodeLinks(iSmallestNodeID); // pSmallestNode->GetNodeLinks();
						for (new iLinkedNode = 0, iLinkSize = GetArraySize(hSmallestNodeLinks); iLinkedNode < iLinkSize; iLinkedNode++)
						{
							decl Float:flLinkedNodePos[3];
							new iLinkedNodeID = GetArrayCell(hSmallestNodeLinks, iLinkedNode);
							GetAINodePosition(iLinkedNodeID, flLinkedNodePos);
							
							if (bool:GetArrayCell(hSmallestNodeLinks, iLinkedNode, AINodeLink_Enabled))
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

public Action:Command_CreateAIAirNode(client, args)
{
	decl Float:flNodePos[3];
	GetClientAbsOrigin(client, flNodePos);
	
	new iNodeID = 0;
	while (FindValueInArray(g_hAINodes, iNodeID) != -1) iNodeID++;
	CreateAINode(AINodeType_Air, iNodeID, flNodePos);
	
	PrintToChat(client, "Created air node at your feet! (ID: %d)", iNodeID);
	
	return Plugin_Handled;
}

public Action:Command_CreateAIGroundNode(client, args)
{
	decl Float:flNodePos[3];
	GetClientAbsOrigin(client, flNodePos);
	
	new iNodeID = 0;
	while (FindValueInArray(g_hAINodes, iNodeID) != -1) iNodeID++;
	CreateAINode(AINodeType_Ground, iNodeID, flNodePos);
	
	PrintToChat(client, "Created ground node at your feet! (ID: %d)", iNodeID);
	
	return Plugin_Handled;
}

public Action:Command_LinkAINodes(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_link_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	LinkAINodeToAINode(StringToInt(sNodeID), StringToInt(sTargetNodeID), true);
	
	return Plugin_Handled;
}

public Action:Command_EnableAINodeLink(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "Usage: sm_sf64_enable_node_link <start node id> <end node id> <0/1>");
		return Plugin_Handled;
	}
	
	decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], String:sEnable[64];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	GetCmdArg(3, sEnable, sizeof(sEnable));
	
	EnableAINodeLink(StringToInt(sNodeID), StringToInt(sTargetNodeID), bool:StringToInt(sEnable));
	
	return Plugin_Handled;
}

public Action:Command_UnlinkAINodes(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_unlink_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	UnlinkAINodeFromAINode(StringToInt(sNodeID), StringToInt(sTargetNodeID));
	
	return Plugin_Handled;
}

public Action:Command_ShowAINodes(client, args)
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

public Action:Command_ShowAINodeLinks(client, args)
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

public Action:Command_FindPathBetweenAINodes(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_sf64_find_path_between_nodes <start node id> <end node id>");
		return Plugin_Handled;
	}
	
	decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH];
	GetCmdArg(1, sNodeID, sizeof(sNodeID));
	GetCmdArg(2, sTargetNodeID, sizeof(sTargetNodeID));
	
	new iNodeID = StringToInt(sNodeID);
	new iTargetNodeID = StringToInt(sTargetNodeID);
	
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
	
	new bool:bPathSuccess = false;
	new Handle:hNodes = AINodeFindBestPath(iNodeID, iTargetNodeID, bPathSuccess);
	
	new iColor[4] = { 0, 255, 0, 255 };
	if (!bPathSuccess)
	{
		iColor[0] = 255;
		iColor[1] = 0;
		iColor[2] = 0;
		iColor[3] = 255;
	}
	
	new iPrevNodeID = -1, iCurrentNodeID = -1;
	for (new i = 0, iSize = GetArraySize(hNodes); i < iSize; i++)
	{
		iCurrentNodeID = GetArrayCell(hNodes, i);
	
		if (iPrevNodeID != -1)
		{
			decl Float:flPrevNodePos[3], Float:flCurrentNodePos[3];
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

public Action:Command_GetAINodeID(client, args)
{
	new iNodeID = GetClientAimNode(client);
	PrintToChat(client, "iNodeID: %d", iNodeID);
	
	return Plugin_Handled;
}

public Action:Command_SaveAINodegraph(client, args)
{
	if (SaveAINodeGraphOfMap()) PrintToChat(client, "Nodegraph saved successfully!");
	else PrintToChat(client, "Failed to save the nodegraph!");
	
	return Plugin_Handled;
}

stock GetClientAimNode(client)
{
	if (!IsValidClient(client)) return -1;
	
	decl Float:flEyePos[3], Float:flEyeAng[3];
	GetClientEyePosition(client, flEyePos);
	GetClientEyeAngles(client, flEyeAng);
	
	new iBestNodeID = -1;
	new bool:bBestNodeDistance = false;
	new bool:bBestNodeAngDistance = false;
	new Float:flBestNodeDistance = -1.0;
	new Float:flBestNodeAngDistance = -1.0;
	new iTempNodeID = -1;
	decl Float:flTempNodePos[3], Float:flDirection[3], Handle:hTrace;
	
	for (new iTempNode = 0, iSize = GetArraySize(g_hAINodes); iTempNode < iSize; iTempNode++)
	{
		iTempNodeID = GetArrayCell(g_hAINodes, iTempNode);
		GetAINodePosition(iTempNodeID, flTempNodePos);
		
		// Check for visibility first.
		hTrace = TR_TraceRayFilterEx(flEyePos, flTempNodePos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceRayDontHitEntity, client);
		new bool:bHit = TR_DidHit(hTrace);
		CloseHandle(hTrace);
		
		if (bHit) continue;
		
		// Check distance.
		new Float:flDist = GetVectorDistance(flEyePos, flTempNodePos);
		if (!bBestNodeDistance || flDist < flBestNodeDistance)
		{
			// Check angle distance.
			SubtractVectors(flTempNodePos, flEyePos, flDirection);
			GetVectorAngles(flDirection, flDirection);
			new Float:flAngDist = FloatAbs(AngleDiff(flDirection[0], flEyeAng[0])) + FloatAbs(AngleDiff(flDirection[1], flEyeAng[1]));
			
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

bool:GetAINodeGraphOfMap()
{
	decl String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/arwing/nodegraphs/%s.cfg", sMapName);
	
	new Handle:hConfig = CreateKeyValues("root");
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
			decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sNodeType[64], iNodeID, iNodeType, Float:flNodePos[3];
			
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
		
		new Handle:hNodeArray = CreateArray(SF64_NODE_MAX_ID_LENGTH);
		
		// Get the IDs of all the nodes and store them for future iteration.
		KvRewind(hConfig);
		if (KvGotoFirstSubKey(hConfig))
		{
			decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH];
			
			do
			{
				KvGetSectionName(hConfig, sNodeID, sizeof(sNodeID));
				PushArrayString(hNodeArray, sNodeID);
			}
			while (KvGotoNextKey(hConfig));
		}
		
		if (GetArraySize(hNodeArray) > 0)
		{
			decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], iNodeID, iTargetNodeID;
			
			for (new i = 0, iSize = GetArraySize(hNodeArray); i < iSize; i++)
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
						
						LinkAINodeToAINode(iNodeID, iTargetNodeID, bool:KvGetNum(hConfig, "enabled", 1));
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

bool:SaveAINodeGraphOfMap()
{
	decl String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/arwing/nodegraphs/%s.cfg", sMapName);
	
	LogMessage("Saving nodegraph for map %s...", sMapName);
	
	new Handle:hConfig = CreateKeyValues("Nodegraph");
	
	if (GetArraySize(g_hAINodes) > 0)
	{
		decl String:sNodeID[SF64_NODE_MAX_ID_LENGTH], iNodeID, iNodeType, String:sNodeType[64], Float:flNodePos[3], Handle:hNodeLinks;
		decl String:sTargetNodeID[SF64_NODE_MAX_ID_LENGTH], iTargetNodeID;
		
		for (new i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
		{
			iNodeID = GetArrayCell(g_hAINodes, i);
			iNodeType = GetArrayCell(g_hAINodes, i, AINode_Type);
			hNodeLinks = Handle:GetArrayCell(g_hAINodes, i, AINode_Links);
			flNodePos[0] = Float:GetArrayCell(g_hAINodes, i, AINode_PositionX);
			flNodePos[1] = Float:GetArrayCell(g_hAINodes, i, AINode_PositionY);
			flNodePos[2] = Float:GetArrayCell(g_hAINodes, i, AINode_PositionZ);
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
						for (new iNodeLink = 0, iNumLinks = GetArraySize(hNodeLinks); iNodeLink < iNumLinks; iNodeLink++)
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
	
	new bool:bSuccess = false;
	
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

ClearAINodeGraph()
{
	if (GetArraySize(g_hAINodes) <= 0) return;
	
	new Handle:hArray = CloneArray(g_hAINodes);
	for (new i = 0, iSize = GetArraySize(hArray); i < iSize; i++)
	{
		RemoveAINode(GetArrayCell(hArray, i));
	}
	
	CloseHandle(hArray);
}

CreateAINode(iNodeType, iNodeID, const Float:flPos[3])
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
	
	new iIndex = PushArrayCell(g_hAINodes, iNodeID);
	SetArrayCell(g_hAINodes, iIndex, iNodeType, AINode_Type);
	SetArrayCell(g_hAINodes, iIndex, CreateArray(AINodeLink_MaxStats), AINode_Links);
	SetArrayCell(g_hAINodes, iIndex, flPos[0], AINode_PositionX);
	SetArrayCell(g_hAINodes, iIndex, flPos[1], AINode_PositionY);
	SetArrayCell(g_hAINodes, iIndex, flPos[2], AINode_PositionZ);
	
	return iIndex;
}

RemoveAINode(iNodeID)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return;
	
	new Handle:hLinks = Handle:GetArrayCell(g_hAINodes, iIndex, AINode_Links);
	CloseHandle(hLinks);
	SetArrayCell(g_hAINodes, iIndex, INVALID_HANDLE, AINode_Links);
	
	// Iterate through all nodes in the graph to make sure that they unlink from this node.
	decl iNodeID2, iNodeLinkIndex;
	for (new i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
	{
		iNodeID2 = GetArrayCell(g_hAINodes, i, AINode_ID);
		if (iNodeID2 == iNodeID) continue;
		
		hLinks = Handle:GetArrayCell(g_hAINodes, i, AINode_Links);
		iNodeLinkIndex = FindValueInArray(hLinks, iNodeID);
		if (iNodeLinkIndex != -1)
		{
			UnlinkAINodeFromAINode(iNodeID2, iNodeID);
		}
	}
	
	RemoveFromArray(g_hAINodes, iIndex);
}

bool:LinkAINodeToAINode(iNodeID, iTargetNodeID, bool:bEnable)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
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
	
	new iTargetIndex = FindValueInArray(g_hAINodes, iTargetNodeID);
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
		new Handle:hLinks = Handle:GetArrayCell(g_hAINodes, iIndex, AINode_Links);
		new iNodeLinkIndex = PushArrayCell(hLinks, iTargetNodeID);
		SetArrayCell(hLinks, iNodeLinkIndex, bEnable, AINodeLink_Enabled);
		
		return true;
	}
	else
	{
		LogMessage("Could not link starting node (ID: %d) to target node (ID: %d): starting node is already linked to target node!", iNodeID, iTargetNodeID);
	}
	
	return false;
}

UnlinkAINodeFromAINode(iNodeID, iTargetNodeID)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1)
	{
		LogError("Could not unlink starting node (ID: %d) from target node (ID: %d): starting node does not exist!", iNodeID, iTargetNodeID);
		return;
	}
	
	if (IsAINodeLinkedToAINode(iNodeID, iTargetNodeID))
	{
		new Handle:hLinks = Handle:GetArrayCell(g_hAINodes, iIndex, AINode_Links);
		RemoveFromArray(hLinks, FindValueInArray(hLinks, iTargetNodeID));
	}
	else
	{
		LogMessage("Could not unlink starting node (ID: %d) from target node (ID: %d): starting node is already unlinked to target node!", iNodeID, iTargetNodeID);
	}
}

EnableAINodeLink(iNodeID, iTargetNodeID, bool:bEnable)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return;
	
	new iTargetIndex = FindValueInArray(g_hAINodes, iTargetNodeID);
	if (iTargetIndex == -1) return;
	
	new Handle:hLinks = Handle:GetArrayCell(g_hAINodes, iIndex, AINode_Links);
	new iNodeLinkIndex = FindValueInArray(hLinks, iTargetNodeID);
	if (iNodeLinkIndex != -1)
	{
		SetArrayCell(hLinks, iNodeLinkIndex, bEnable, AINodeLink_Enabled);
	}
}

bool:IsAINodeLinkedToAINode(iNodeID, iTargetNodeID)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return false;
	
	new Handle:hLinks = GetAINodeLinks(iNodeID); // pNode->GetNodeLinks();
	return bool:(FindValueInArray(hLinks, iTargetNodeID) != -1);
}

bool:IsAINodeLinkEnabled(iNodeID, iTargetNodeID)
{
	if (!IsAINodeLinkedToAINode(iNodeID, iTargetNodeID)) return false;
	
	new Handle:hLinks = GetAINodeLinks(iNodeID); // pNode->GetNodeLinks();
	return bool:GetArrayCell(hLinks, FindValueInArray(hLinks, iTargetNodeID), AINodeLink_Enabled);
}

Handle:AINodeFindBestPath(iNodeID, iTargetNodeID, &bool:bSuccess=false)
{
	if (!GetArraySize(g_hAINodes)) 
	{
		bSuccess = false;
		return CreateArray();
	}
	
	new Handle:hTraversedNodes = CreateArray();
	
	new Handle:hOpenSet = CreateArray(AINodeSet_MaxStats);
	new iOpenSetIndex = PushArrayCell(hOpenSet, iNodeID);
	SetArrayCell(hOpenSet, iOpenSetIndex, 0.0, AINodeSet_GScore);
	SetArrayCell(hOpenSet, iOpenSetIndex, 0.0 + GetAINodeHeuristicCost(iNodeID, iTargetNodeID), AINodeSet_FScore); // F score.
	
	new Handle:hClosedSet = CreateArray(AINodeSet_MaxStats);
	
	decl iCurrentNodeID, iCurrentNodeIDOpenSetIndex, Handle:hCurrentNodeLinks, iTempNodeID, Float:flTempFScore, Float:flBestFScore, bool:bHasBestFScore;
	decl Float:flCurrentNodeGScore;
	
	bSuccess = false;
	
	while (GetArraySize(hOpenSet) > 0)
	{
		// First, get the node with the lowest F score in the open set.
		iCurrentNodeID = -1;
		iCurrentNodeIDOpenSetIndex = -1;
		bHasBestFScore = false;
		
		for (new i = 0, iSize = GetArraySize(hOpenSet); i < iSize; i++)
		{
			iTempNodeID = GetArrayCell(hOpenSet, i);
			flTempFScore = Float:GetArrayCell(hOpenSet, i, AINodeSet_FScore);
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
		
		flCurrentNodeGScore = Float:GetArrayCell(hOpenSet, iCurrentNodeIDOpenSetIndex, AINodeSet_GScore);
		
		RemoveFromArray(hOpenSet, iCurrentNodeIDOpenSetIndex);
		PushArrayCell(hClosedSet, iCurrentNodeID);
		
		hCurrentNodeLinks = GetAINodeLinks(iCurrentNodeID);
		for (new i = 0, iSize = GetArraySize(hCurrentNodeLinks); i < iSize; i++)
		{
			new iNeighborNodeID = GetArrayCell(hCurrentNodeLinks, i);
			if (!IsAINodeLinkEnabled(iCurrentNodeID, iNeighborNodeID)) continue;
			
			new Float:flTentativeGScore = flCurrentNodeGScore + GetAINodeHeuristicCost(iCurrentNodeID, iNeighborNodeID);
			
			new iNeighborNodeIDClosedSetIndex = FindValueInArray(hClosedSet, iNeighborNodeID);
			if (iNeighborNodeIDClosedSetIndex != -1 && flTentativeGScore >= Float:GetArrayCell(hClosedSet, iNeighborNodeIDClosedSetIndex, AINodeSet_GScore))
			{
				continue;
			}
			
			new iNeighborNodeIDOpenSetIndex = FindValueInArray(hOpenSet, iNeighborNodeID);
			if (iNeighborNodeIDOpenSetIndex == -1 || flTentativeGScore < Float:GetArrayCell(hOpenSet, iNeighborNodeIDOpenSetIndex, AINodeSet_GScore))
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

static Float:GetAINodeHeuristicCost(iNodeID, iTargetNodeID)
{
	decl Float:flNodePos[3], Float:flTargetNodePos[3];
	GetAINodePosition(iNodeID, flNodePos);
	GetAINodePosition(iTargetNodeID, flTargetNodePos);
	
	return GetVectorDistance(flNodePos, flTargetNodePos);
}

stock bool:GetAINodePosition(iNodeID, Float:flBuffer[3])
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) return false;
	
	flBuffer[0] = Float:GetArrayCell(g_hAINodes, iIndex, AINode_PositionX);
	flBuffer[1] = Float:GetArrayCell(g_hAINodes, iIndex, AINode_PositionY);
	flBuffer[2] = Float:GetArrayCell(g_hAINodes, iIndex, AINode_PositionZ);
	
	return true;
}

stock Handle:GetAINodeLinks(iNodeID)
{
	new iIndex = FindValueInArray(g_hAINodes, iNodeID);
	if (iIndex == -1) 
	{
		LogError("Could not retrieve links of node (ID: %d): node does not exist!", iNodeID);
		return INVALID_HANDLE;
	}
	
	return Handle:GetArrayCell(g_hAINodes, iIndex, AINode_Links);
}

stock GetNearestAINodeToPoint(const Float:flPos[3], Float:flTolerance=512.0)
{
	decl Float:flNodePos[3];
	new iBestNodeID = -1;
	new Float:flBestDistance = flTolerance;
	if (flTolerance < 0.0) flBestDistance = 16384.0;
	
	decl Float:flDist;
	
	for (new i = 0, iSize = GetArraySize(g_hAINodes); i < iSize; i++)
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

stock FindAINodeByID(iNodeID) return FindValueInArray(g_hAINodes, iNodeID);