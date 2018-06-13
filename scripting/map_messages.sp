#pragma semicolon 1

#include <sourcemod>
#include <csgo_colors> 

#define PLUGIN_PREFIX	"[{BLUE}КАРТА{DEFAULT}]"
#define PLUGIN_VERSION	"1.0.0"


public Plugin myinfo = 
{
	name = "Map messages replace",
	author = "Se7en",
	version = PLUGIN_VERSION,
	url = "https://csgo.su"
}

char szBuffer[PLATFORM_MAX_PATH]; // Временный буффер
Handle hMessages = INVALID_HANDLE;
Handle hReplacements = INVALID_HANDLE;
int iMessagesCount = 0;

public OnPluginStart()
{
	hMessages = CreateArray(192);
	hReplacements = CreateArray(192);

	RegConsoleCmd("say", Command_Say);
}

public OnAutoConfigsBuffered() {
	loadMessages();
}

public Action Command_Say(int iClient, int args)
{
	if (iClient == 0 && iMessagesCount != 0)
	{
		char sMessage[192];
		GetCmdArgString(sMessage, sizeof(sMessage));
		StripQuotes(sMessage);
		
		int array_index = FindStringInArray(hMessages, sMessage);
		if(array_index != -1) {
			char sReplacement[192];
			GetArrayString(hReplacements, array_index, sReplacement, sizeof(sReplacement));

			if(sReplacement[0]) {
				CGOPrintToChatAll("%s %s", PLUGIN_PREFIX, sReplacement);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

stock loadMessages()
{
	iMessagesCount = 0;
	ClearArray(hMessages);
	ClearArray(hReplacements);

	char g_MapCfgPath[PLATFORM_MAX_PATH];
	char sMap[PLATFORM_MAX_PATH];

	GetCurrentMap(sMap, sizeof(sMap));
	new WorkshopFix = FindCharInString(sMap, '/', true);
	if (WorkshopFix != -1) {
		strcopy(sMap, sizeof(sMap), sMap[WorkshopFix+1]);
	}

	Format(szBuffer, sizeof(szBuffer), "configs/map_messages/%s.cfg", sMap);

	BuildPath(Path_SM, g_MapCfgPath, sizeof(g_MapCfgPath), szBuffer);
	
	Handle kv = CreateKeyValues("Messages");
	FileToKeyValues(kv, g_MapCfgPath);

	if (!KvGotoFirstSubKey(kv)) {
		return iMessagesCount;
	}

	char message[192];
	char replacement[192];

	do {
		KvGetSectionName(kv, message, sizeof(message));
		KvGetString(kv, "replacement", replacement, sizeof(replacement));
		PushArrayString(hMessages, message);
		PushArrayString(hReplacements, replacement);
		iMessagesCount++;
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);
	
	return iMessagesCount;
}