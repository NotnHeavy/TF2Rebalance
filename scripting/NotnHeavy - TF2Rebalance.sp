// TODO: work on something similar to mini-crit impact sounds with the Flying Guillotine on stunned targets.
// also i need to implement the gas passer treatment for the mad milk too.
// also i need to think of s

// make new repo when making this public.

//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// This uses nosoop's fork of TF2Attributes.
// https://github.com/nosoop/tf2attributes

// This plugin also uses DHooks with Detours by Dr!fter. Unless compiled with >= SM 1.11, you'll have to include the plugin below:
// https://forums.alliedmods.net/showthread.php?t=180114

// For dynamic memory allocation, this also uses nosoop's SourceScramble extension. this plugin may use scags' sm-memory instead.
// https://github.com/nosoop/SMExt-SourceScramble

#pragma semicolon true 
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>
#include <dhooks>
#include <smmem>

#define EF_NODRAW 0x0020 // EF_NODRAW prevents any data about an entity from being transmitted to the client, without affecting it on the server. In other words, it makes the entity disappear from the player's view without deleting it.

#define FSOLID_USE_TRIGGER_BOUNDS (1 << 7) // Uses a special trigger bounds separate from the normal OBB.

#define TICK_RATE 66
#define TICK_RATE_PRECISION GetTickInterval()

#define FLIGHT_TIME_TO_MAX_STUN	1.0
#define FLIGHT_TIME_TO_MAX_SLOWDOWN_RAMPUP 0.8

#define TF_STUN_NONE						0
#define TF_STUN_MOVEMENT					(1<<0)
#define	TF_STUN_CONTROLS					(1<<1)
#define TF_STUN_MOVEMENT_FORWARD_ONLY		(1<<2)
#define TF_STUN_SPECIAL_SOUND				(1<<3)
#define TF_STUN_DODGE_COOLDOWN				(1<<4)
#define TF_STUN_NO_EFFECTS					(1<<5)
#define TF_STUN_LOSER_STATE					(1<<6)
#define TF_STUN_BY_TRIGGER					(1<<7)
#define TF_STUN_BOTH						TF_STUN_MOVEMENT | TF_STUN_CONTROLS

#define PLUGIN_NAME "NotnHeavy - TF2Rebalance"

//////////////////////////////////////////////////////////////////////////////
// GLOBALS                                                                  //
//////////////////////////////////////////////////////////////////////////////

static int pl_impact_stun_range_mutes = 0;

static int explosionModelIndex;

static Address energyRingSpeedAddress;
static float oldEnergyRingSpeed;
static float newEnergyRingSpeed = 3000.00;

static ConVar tf_scout_stunball_base_duration;
static ConVar tf_flamethrower_maxdamagedist;
static ConVar tf_parachute_aircontrol;
static ConVar tf_rocketpack_airborne_launch_absvelocity_preserved;
static ConVar tf_rocketpack_launch_absvelocity_preserved;
static ConVar tf_rocketpack_toggle_duration;
static ConVar tf_rocketpack_launch_push;
ConVar tf_weapon_criticals;
ConVar tf_use_fixed_weaponspreads;
ConVar notnheavy_tf2rebalance_use_fixed_falldamage;
bool initiatedConVars;

DHookSetup DHooks_CBaseEntity_Deflected;
DHookSetup DHooks_CObjectDispenser_DispenseAmmo;
DHookSetup DHooks_CTFProjectile_Jar_Explode;

DHookSetup DHooks_CTFWeaponBase_Deploy;
DHookSetup DHooks_CTFWeaponBaseGun_GetWeaponSpread;
DHookSetup DHooks_CTFFlareGun_Revenge_ExtinguishPlayerInternal;
DHookSetup DHooks_CBaseObject_OnTakeDamage;
DHookSetup DHooks_CTFPlayer_OnTakeDamage;
DHookSetup DHooks_CTFPlayer_OnTakeDamage_Alive;
DHookSetup DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed;
DHookSetup DHooks_CTFPlayerShared_AddCond;
DHookSetup DHooks_CTFPlayerShared_RemoveCond;
DHookSetup DHooks_CTFPlayerShared_InCond;
DHookSetup DHooks_CTFGameRules_FlPlayerFallDamage;

Handle SDKCall_CBaseCombatWeapon_GetName;
Handle SDKCall_CTFWeaponBase_GetMaxClip1;

Handle SDKCall_CBaseCombatWeapon_Deploy;
Handle SDKCall_ExtinguishPlayer;
Handle SDKCall_CBaseEntity_TakeDamage;
Handle SDKCall_CTFPlayer_TeamFortress_CalculateMaxSpeed;
Handle SDKCall_CTFPlayer_GetMaxAmmo;
Handle SDKCall_CTFPlayerShared_Burn;
Handle SDKCall_CTFGameRules_FlPlayerFallDamage;
Handle SDKCall_CTFGameRules_RadiusDamage;
Handle SDKCall_CTFRadiusDamageInfo_CalculateFalloff;

Address CObjectDispenser_m_hHealingTargets;
Address CTFWeaponBase_m_flLastDeployTime;
Address CTFWeaponBase_m_pWeaponInfo;
Address CTFWeaponBase_m_iWeaponMode;
Address CTFWeaponInfo_m_WeaponData;

char configMacros[][][] = 
{
    { "HOLSTER_CHANGE", "Note: The holster attribute is now independent of how long this weapon was equipped.\nIt now also applies if the user switches from one weapon to another <0.5s after holstering\nthis weapon." }
};

//////////////////////////////////////////////////////////////////////////////
// TF2 CODE                                                                 //
//////////////////////////////////////////////////////////////////////////////

enum ETFAmmoType
{
	TF_AMMO_DUMMY = 0,	// Dummy index to make the CAmmoDef indices correct for the other ammo types.
	TF_AMMO_PRIMARY,
	TF_AMMO_SECONDARY,
	TF_AMMO_METAL,
	TF_AMMO_GRENADES1,
	TF_AMMO_GRENADES2,
	TF_AMMO_GRENADES3,	// Utility Slot Grenades
	TF_AMMO_COUNT,

	//
	// ADD NEW ITEMS HERE TO AVOID BREAKING DEMOS
	//
};

// Reloading singly.
enum
{
	TF_RELOAD_START = 0,
	TF_RELOADING,
	TF_RELOADING_CONTINUE,
	TF_RELOAD_FINISH
};

/*
TFCond g_aDebuffConditions[] =
{
	TFCond_OnFire,
	TFCond_Jarated,
	TFCond_Bleeding,
	TFCond_Milked,
    TFCond_Gas
};
*/

float RemapValClamped(float val, float A, float B, float C, float D)
{
	if ( A == B )
		return val >= B ? D : C;
	float cVal = (val - A) / (B - A);
	cVal = clamp( cVal, 0.0, 1.0 );

	return C + (D - C) * cVal;
}

float clamp(float val, float minVal, float maxVal)
{
	if ( maxVal < minVal )
		return maxVal;
	else if( val < minVal )
		return minVal;
	else if( val > maxVal )
		return maxVal;
	else
		return val;
}

//////////////////////////////////////////////////////////////////////////////
// FIRST-PARTY INCLUDES                                                     //
//////////////////////////////////////////////////////////////////////////////

#include "methodmaps/Pointer.sp"
#include "methodmaps/mathlib/Vector.sp"
#include "methodmaps/tier1/CUtlMemory.sp"
#include "methodmaps/tier1/CUtlVector.sp"
#include "methodmaps/server/CBaseEntity.sp"
#include "methodmaps/server/CObjectDispenser.sp"
#include "methodmaps/shared/CEconEntity.sp"
#include "methodmaps/shared/WeaponData_t.sp"
#include "methodmaps/shared/CTFWeaponInfo.sp"
#include "methodmaps/shared/CTFWeaponBase.sp"
#include "methodmaps/shared/CTFPlayerShared.sp"
#include "methodmaps/shared/CTFWearable.sp"
#include "methodmaps/server/CTFPlayer.sp"
#include "methodmaps/shared/CTakeDamageInfo.sp"
#include "methodmaps/shared/CTFRadiusDamageInfo.sp"
#include "methodmaps/shared/CTFGameRules.sp"
#include "methodmaps/shared/healers_t.sp"

static CTFGameRules g_pGameRules;

//////////////////////////////////////////////////////////////////////////////
// TF2 GLOBALS                                                              //
//////////////////////////////////////////////////////////////////////////////

void ExtinguishPlayer(CEconEntity pExtinguisher, CTFPlayer pOwner, CTFPlayer pTarget, const int pExtinguisherName /* const char* */)
{
    SDKCall(SDKCall_ExtinguishPlayer, pExtinguisher.Index, pOwner.Index, pTarget.Index, pExtinguisherName);
}

//////////////////////////////////////////////////////////////////////////////
// UTILITY                                                                  //
//////////////////////////////////////////////////////////////////////////////

// Get the smaller integral value.
int intMin(int x, int y)
{
    return x > y ? y : x;
}

// Get the smaller floating point value.
float min(float x, float y)
{
    return x > y ? y : x;
}

// Get the larger floating point value.
float max(float x, float y)
{
    return x > y ? x : y;
}

//////////////////////////////////////////////////////////////////////////////
// PLUGIN INFO                                                              //
//////////////////////////////////////////////////////////////////////////////

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "NotnHeavy",
    description = "My own attempts at rebalancing existing weapons and introducing new content. :)",
    version = "1.0",
    url = "none"
};

//////////////////////////////////////////////////////////////////////////////
// INITIALISATION                                                           //
//////////////////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    AddNormalSoundHook(SoundPlayed);

    HookEvent("post_inventory_application", PostClientInventoryReset);
    HookEvent("player_spawn", ClientSpawned);
    HookEvent("player_death", ClientDied);
    HookEvent("player_hurt", ClientHurt, EventHookMode_Pre);

    RegConsoleCmd("loadout", ShowLoadout);

    // Configs.
    GameData config = LoadGameConfigFile(PLUGIN_NAME);
    if (config == null)
    {
        SetFailState("The configuration file for plugin \"%s\" has failed to load. Please make sure that it is actually present in your gamedata directory.", PLUGIN_NAME);
    }

    // DHooks.
    DHooks_CBaseEntity_Deflected = DHookCreateFromConf(config, "CBaseEntity::Deflected");
    DHooks_CObjectDispenser_DispenseAmmo = DHookCreateFromConf(config, "CObjectDispenser::DispenseAmmo");
    DHooks_CTFProjectile_Jar_Explode = DHookCreateFromConf(config, "CTFProjectile_Jar::Explode");

    DHooks_CTFWeaponBase_Deploy = DHookCreateFromConf(config, "CTFWeaponBase::Deploy");
    DHooks_CTFWeaponBaseGun_GetWeaponSpread = DHookCreateFromConf(config, "CTFWeaponBaseGun::GetWeaponSpread");
    DHooks_CTFFlareGun_Revenge_ExtinguishPlayerInternal = DHookCreateFromConf(config, "CTFFlareGun_Revenge::ExtinguishPlayerInternal");
    DHooks_CBaseObject_OnTakeDamage = DHookCreateFromConf(config, "CBaseObject::OnTakeDamage");
    DHooks_CTFPlayer_OnTakeDamage = DHookCreateFromConf(config, "CTFPlayer::OnTakeDamage");
    DHooks_CTFPlayer_OnTakeDamage_Alive = DHookCreateFromConf(config, "CTFPlayer::OnTakeDamage_Alive");
    DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed = DHookCreateFromConf(config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    DHooks_CTFPlayerShared_AddCond = DHookCreateFromConf(config, "CTFPlayerShared::AddCond");
    DHooks_CTFPlayerShared_RemoveCond = DHookCreateFromConf(config, "CTFPlayerShared::RemoveCond");
    DHooks_CTFPlayerShared_InCond = DHookCreateFromConf(config, "CTFPlayerShared::InCond");
    DHooks_CTFGameRules_FlPlayerFallDamage = DHookCreateFromConf(config, "CTFGameRules::FlPlayerFallDamage");

    DHookEnableDetour(DHooks_CTFWeaponBase_Deploy, false, Deploy);
    DHookEnableDetour(DHooks_CTFWeaponBaseGun_GetWeaponSpread, true, GetWeaponSpread); // for some reason this has to be post in order to work properly.
    DHookEnableDetour(DHooks_CTFFlareGun_Revenge_ExtinguishPlayerInternal, false, ExtinguishPlayerInternal);
    DHookEnableDetour(DHooks_CBaseObject_OnTakeDamage, false, CBaseObject_OnTakeDamage);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage, false, CTFPlayer_OnTakeDamage);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage, true, OnTakeDamagePost);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage_Alive, false, OnTakeDamageAlive);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage_Alive, true, OnTakeDamageAlivePost);
    DHookEnableDetour(DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed, true, TeamFortress_CalculateMaxSpeed);
    DHookEnableDetour(DHooks_CTFPlayerShared_AddCond, false, AddCond);
    DHookEnableDetour(DHooks_CTFPlayerShared_RemoveCond, false, RemoveCond);
    DHookEnableDetour(DHooks_CTFPlayerShared_InCond, false, InCond);
    DHookEnableDetour(DHooks_CTFGameRules_FlPlayerFallDamage, true, FlPlayerFallDamage);

    // SDKCall.
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CBaseCombatWeapon::GetName");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CBaseCombatWeapon_GetName = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CTFWeaponBase_GetMaxClip1 = EndPrepSDKCall();

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CBaseCombatWeapon::Deploy");
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    SDKCall_CBaseCombatWeapon_Deploy = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "ExtinguishPlayer");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // const char*
    SDKCall_ExtinguishPlayer = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CBaseEntity::TakeDamage");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CBaseEntity_TakeDamage = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
    SDKCall_CTFPlayer_TeamFortress_CalculateMaxSpeed = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CTFPlayer_GetMaxAmmo = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFPlayerShared::Burn");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
    SDKCall_CTFPlayerShared_Burn = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_GameRules);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFGameRules::FlPlayerFallDamage");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
    SDKCall_CTFGameRules_FlPlayerFallDamage = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_GameRules);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFGameRules::RadiusDamage");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CTFGameRules_RadiusDamage = EndPrepSDKCall();
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTFRadiusDamageInfo::CalculateFalloff");
    SDKCall_CTFRadiusDamageInfo_CalculateFalloff = EndPrepSDKCall();
    
    // Offsets.
    CObjectDispenser_m_hHealingTargets = view_as<Address>(GameConfGetOffset(config, "CObjectDispenser::m_hHealingTargets"));
    CTFWeaponBase_m_flLastDeployTime = view_as<Address>(GameConfGetOffset(config, "CTFWeaponBase::m_flLastDeployTime"));
    CTFWeaponBase_m_pWeaponInfo = view_as<Address>(GameConfGetOffset(config, "CTFWeaponBase::m_pWeaponInfo"));
    CTFWeaponBase_m_iWeaponMode = view_as<Address>(GameConfGetOffset(config, "CTFWeaponBase::m_iWeaponMode"));
    CTFWeaponInfo_m_WeaponData = view_as<Address>(GameConfGetOffset(config, "CTFWeaponInfo_m_WeaponData"));

    // Memory patches.
    energyRingSpeedAddress = GameConfGetAddress(config, "CreateEnergyRing") + view_as<Address>(GameConfGetOffset(config, "Memory_CreateEnergyRingVelocity"));
    oldEnergyRingSpeed = Dereference(energyRingSpeedAddress);
    WriteToValue(energyRingSpeedAddress, AddressOf(newEnergyRingSpeed));

    delete config;

    // ConVars.
    tf_flamethrower_maxdamagedist = FindConVar("tf_flamethrower_maxdamagedist");
    tf_scout_stunball_base_duration = FindConVar("tf_scout_stunball_base_duration");
    tf_parachute_aircontrol = FindConVar("tf_parachute_aircontrol");
    tf_rocketpack_airborne_launch_absvelocity_preserved = FindConVar("tf_rocketpack_airborne_launch_absvelocity_preserved");
    tf_rocketpack_launch_absvelocity_preserved = FindConVar("tf_rocketpack_launch_absvelocity_preserved");
    tf_rocketpack_toggle_duration = FindConVar("tf_rocketpack_toggle_duration");
    tf_rocketpack_launch_push = FindConVar("tf_rocketpack_launch_push");

    tf_weapon_criticals = FindConVar("tf_weapon_criticals");
    tf_use_fixed_weaponspreads = FindConVar("tf_use_fixed_weaponspreads");
    notnheavy_tf2rebalance_use_fixed_falldamage = CreateConVar("notnheavy_tf2rebalance_use_fixed_falldamage", "1.00", "Use fixed fall damage. This also applies to the Thermal Thruster/Mantreads stomp.", FCVAR_PROTECTED);
    initiatedConVars = true;

    // Hook onto entities.
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i))
        {
            CTFPlayer player = CTFPlayer(i);
            player.ShowWelcomePanel();
            if (player.Alive)
                player.StructuriseWeaponList();
        }
    }
    for (int i = MAXPLAYERS; i < MAX_ENTITY_COUNT; ++i)
    {
        if (IsValidEntity(i) && i > MaxClients)
            CBaseEntity(i);
    }

    PrintToServer("--------------------------------------------------------\n\"%s\" has loaded.\n--------------------------------------------------------", PLUGIN_NAME);
}

public void OnMapStart()
{
    explosionModelIndex = PrecacheModel("sprites/sprite_fire01.vmt");
}

public void OnPluginEnd()
{
    WriteToValue(energyRingSpeedAddress, oldEnergyRingSpeed);
    tf_parachute_aircontrol.RestoreDefault();
    tf_rocketpack_airborne_launch_absvelocity_preserved.RestoreDefault();
    tf_rocketpack_launch_absvelocity_preserved.RestoreDefault();
    tf_rocketpack_toggle_duration.RestoreDefault();
    tf_rocketpack_launch_push.RestoreDefault();
}

//////////////////////////////////////////////////////////////////////////////
// MENUS                                                                    //
//////////////////////////////////////////////////////////////////////////////

int ShowLoadoutMenuAction(Menu menu, MenuAction action, int param1, int param2)
{
    CTFPlayer player = view_as<CTFPlayer>(param1);
    if (action == MenuAction_Select && param2 == 2) // The user selected the next button.
        player.CreateLoadoutPanel();
    return 0;
}

int ShowWelcomeMenuAction(Menu menu, MenuAction action, int param1, int param2)
{
    return 0;
}

Action ShowLoadout(int clientIndex, int args)
{
    CTFPlayer player = view_as<CTFPlayer>(clientIndex);
    player.ResetLoadoutLastEntry();
    if (player.CreateLoadoutPanel() == 1)
        PrintToChat(player.Index, "Your loadout is the same as stock TF2.");
    return Plugin_Handled;
}
//////////////////////////////////////////////////////////////////////////////
// EVENTS                                                                   //
//////////////////////////////////////////////////////////////////////////////

public Action PostClientInventoryReset(Event event, const char[] name, bool dontBroadcast)
{
    CTFPlayer client = view_as<CTFPlayer>(GetClientOfUserId(event.GetInt("userid")));
    client.TimeUntilSandmanStunEnd = 0.00;
    client.TimeSinceStoppedBurning = 0.00;
    client.FromSVF = view_as<CTFWeaponBase>(INVALID_ENTITY);
    client.StructuriseWeaponList();
    client.Regenerate();
    return Plugin_Continue;
}

public Action ClientSpawned(Event event, const char[] name, bool dontBroadcast)
{
    CTFPlayer client = view_as<CTFPlayer>(GetClientOfUserId(event.GetInt("userid")));
    client.ShowWelcomePanel();
    return Plugin_Continue;
}

public Action ClientDied(Event event, const char[] name, bool dontBroadcast)
{
    CTFPlayer victim = view_as<CTFPlayer>(GetClientOfUserId(event.GetInt("userid")));

    // If the victim is dead and has been marked as volcano by the Sharpened Volcano Fragment, make an explosion that can cause a chain reaction.
    // The explosion is only created next frame because any form of damaging players inside these damage hooks will cause the server to crash.
    if (victim.FromSVF.Exists)
    {
        DataPack data = new DataPack();
        data.WriteCell(victim.FromSVF.Owner);
        data.WriteCell(victim);
        data.WriteCell(victim.FromSVF);
        RequestFrame(VolcanoExplosion, data);

        /*
        CTakeDamageInfo newInfo = CTakeDamageInfo(victim.FromSVF.Owner, victim.FromSVF.Owner, victim.FromSVF, victim.GetAbsOrigin(), victim.GetAbsOrigin(), 30.00, DMG_BLAST | DMG_IGNITE | DMG_HALF_FALLOFF, TF_CUSTOM_BURNING, victim.GetAbsOrigin());
        CTFRadiusDamageInfo radiusInfo = CTFRadiusDamageInfo(newInfo, victim.GetAbsOrigin(), 146.00);
        g_pGameRules.RadiusDamage(radiusInfo);
        newInfo.Dispose();
        radiusInfo.Dispose();

        float buffer[3];
        victim.GetAbsOrigin().GetBuffer(buffer);
        TE_SetupExplosion(buffer, explosionModelIndex, 10.0, 1, 0, 146, 0);
        TE_SendToAll();
        */
    }

    return Plugin_Continue;
}

public Action ClientHurt(Event event, const char[] name, bool dontBroadcast)
{
    CTFPlayer client = view_as<CTFPlayer>(GetClientOfUserId(event.GetInt("userid")));
    if (client.TakingMiniCritDamage)
        event.SetInt("bonuseffect", 1);
    client.TakingMiniCritDamage = false;
    return Plugin_Changed;
}

//////////////////////////////////////////////////////////////////////////////
// NEXT FRAME CALLS                                                          //
//////////////////////////////////////////////////////////////////////////////

void OnEntityCreatedRequestFrame(CBaseEntity entity)
{
    if (entity.ClassEquals("tf_projectile_jar_gas")) // Reset the Gas Passer charge meter.
        entity.GetMemberEntity(Prop_Send, "m_hLauncher").RechargeTime = 0.00;
}

void DamageAllConnected(DataPack data)
{
    data.Reset();
    CTFPlayer attacker = data.ReadCell();
    CTFPlayer victim = data.ReadCell();

    victim.TakeDamage(attacker.ConnectedInfo);
    --attacker.RecursiveCheck;
    if (!attacker.RecursiveCheck)
    {
        attacker.ConnectedInfo.Dispose();
        attacker.ConnectedInfo = NULL;
    }

    delete data;
}

void VolcanoExplosion(DataPack data)
{
    data.Reset();
    CTFPlayer attacker = data.ReadCell();
    CTFPlayer victim = data.ReadCell();
    CTFWeaponBase weapon = data.ReadCell();

    CTakeDamageInfo newInfo = CTakeDamageInfo(attacker, attacker, weapon, victim.GetAbsOrigin(), victim.GetAbsOrigin(), 30.00, DMG_BLAST | DMG_IGNITE | DMG_HALF_FALLOFF, TF_CUSTOM_BURNING, victim.GetAbsOrigin());
    CTFRadiusDamageInfo radiusInfo = CTFRadiusDamageInfo(newInfo, victim.GetAbsOrigin(), 146.00);
    g_pGameRules.RadiusDamage(radiusInfo);
    newInfo.Dispose();
    radiusInfo.Dispose();

    float buffer[3];
    victim.GetAbsOrigin().GetBuffer(buffer);
    TE_SetupExplosion(buffer, explosionModelIndex, 10.0, 1, 0, 146, 0);
    TE_SendToAll();

    delete data;
}

//////////////////////////////////////////////////////////////////////////////
// FORWARDS                                                                 //
//////////////////////////////////////////////////////////////////////////////

public void OnClientPutInServer(int client)
{
    CTFPlayer(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity <= MaxClients)
        return;
    CBaseEntity newEntity = CBaseEntity(entity);
    if (newEntity.ClassEquals("tf_dropped_weapon") && newEntity.Owner != INVALID_ENTITY) // If the player drops a weapon death, re-structurise their weapon list just to be safe.
        ToTFPlayer(newEntity.Owner).StructuriseWeaponList();
    RequestFrame(OnEntityCreatedRequestFrame, newEntity);
}

public void OnGameFrame()
{
    static int frame = 0;
    ++frame;
    pl_impact_stun_range_mutes = 0;
    tf_parachute_aircontrol.FloatValue = 5.00; // Reset B.A.S.E Jumper air control back to 100%.
    tf_rocketpack_airborne_launch_absvelocity_preserved.IntValue = 1; // Do not reset the player's movement while using the Thermal Thruster.
    tf_rocketpack_launch_absvelocity_preserved.IntValue = 1; // Do not reset the player's movement while using the Thermal Thruster.
    tf_rocketpack_toggle_duration.FloatValue = 0.7; // Take only 0.7s to equip the Thermal Thruster.
    tf_rocketpack_launch_push.IntValue = 500; // yeet

    // Go through players.
    for (CTFPlayer player = view_as<CTFPlayer>(1); player <= view_as<CTFPlayer>(MaxClients); ++player)
    {
        if (player.InGame)
        {
            // Prevent shortening the recharge duration for the Flying Guillotine.
            CEconEntity doesHaveWeapon = player.GetWeaponFromList({ 812, 833 }, 2);
            if (doesHaveWeapon != INVALID_ENTITY)
            {
                float regen = doesHaveWeapon.GetMemberFloat(Prop_Send, "m_flEffectBarRegenTime");
                if (regen != 0 && doesHaveWeapon.RechargeTime - regen == 1.50)
                {
                    regen = doesHaveWeapon.RechargeTime;
                    doesHaveWeapon.SetMemberFloat(Prop_Send, "m_flEffectBarRegenTime", regen);
                }
                doesHaveWeapon.RechargeTime = regen;
            }

            // If a player is no longer burning, disable the weapon checks.
            if (!player.m_Shared.InCond(TFCond_OnFire) && player.Alive)
            {
                player.FromDegreaser = false;
                if (GetGameTime() - 1.0 > player.TimeSinceStoppedBurning)
                    player.FromSVF = view_as<CTFWeaponBase>(INVALID_ENTITY);
                if (!player.m_Shared.InCond(TFCond_Gas))
                    player.FromGasPasser = false;
            }

            // Extend the Sandman ball recharge duration from 10s to 15s. Hacky, but it works.
            doesHaveWeapon = player.GetWeapon(44);
            if (doesHaveWeapon != INVALID_ENTITY)
                doesHaveWeapon.SetMemberFloat(Prop_Send, "m_flEffectBarRegenTime", doesHaveWeapon.GetMemberFloat(Prop_Send, "m_flEffectBarRegenTime") + TICK_RATE_PRECISION / 3);

            // Set the player's max speed if they are no longer stunned by the Sandman.
            if (player.TimeUntilSandmanStunEnd > 0.00 && player.TimeUntilSandmanStunEnd <= GetGameTime())
            {
                player.TimeUntilSandmanStunEnd = 0.00;
                player.SetMemberFloat(Prop_Send, "m_flMaxspeed", SDKCall(SDKCall_CTFPlayer_TeamFortress_CalculateMaxSpeed, player, false));
            }

            // Recharge management with the Gas Passer.
            doesHaveWeapon = player.GetWeapon(1180);
            if (doesHaveWeapon != INVALID_ENTITY)
            {
                if (player.Alive) 
                    doesHaveWeapon.RechargeTime = min(doesHaveWeapon.RechargeTime + 100.00 / (40.00 / TICK_RATE_PRECISION), 100.00);
                if (doesHaveWeapon.RechargeTime >= 100.00) // Make sure the player can actually use the Gas Passer.
                    player.SetAmmoCount(1, view_as<int>(TF_AMMO_GRENADES1));
                else
                    player.SetAmmoCount(0, view_as<int>(TF_AMMO_GRENADES1));
                
                player.SetMemberFloat(Prop_Send, "m_flItemChargeMeter", doesHaveWeapon.RechargeTime, 1);
            }

            // Cap at 3 crits with the Manmelter.
            doesHaveWeapon = player.GetWeapon(595);
            if (doesHaveWeapon != INVALID_ENTITY && player.GetMember(Prop_Send, "m_iRevengeCrits") > 3)
                player.SetMember(Prop_Send, "m_iRevengeCrits", 3);

            // Remove the rocket jump condition from the player if they are now grounded.
            if (player.Class != TFClass_DemoMan && player.Class != TFClass_Soldier && player.GetFlags() & (FL_ONGROUND | FL_INWATER) && player.m_Shared.InCond(TFCond_BlastJumping))
                player.m_Shared.RemoveCond(TFCond_BlastJumping);

            // Return the flame density back to normal after 0.5s has passed since the user has last been flamed, in 1.5s, with the flamethrowers.
            if (GetGameTime() - player.TimeSinceHitByFlames > 0.50)
                player.FlameDensity -= 0.50 * (TICK_RATE_PRECISION / 1.50);
        }
    }

    // Go through other entities.
    for (CBaseEntity entity = view_as<CBaseEntity>(MAXPLAYERS); entity < view_as<CBaseEntity>(MAX_ENTITY_COUNT); ++entity)
    {
        if (entity.Exists && entity.IsBaseCombatWeapon)
        {
            CTFWeaponBase weapon = ToTFWeaponBase(entity);
            
            // Return the spread multiplier back to normal after 1.5s has passed since the user has last shot, in 1s, with the Panic Attack.
            float consecutive;
            weapon.HookValueFloat(consecutive, "mult_spread_scales_consecutive");
            if (consecutive && GetGameTime() - weapon.LastShot > 1.50)
                weapon.SpreadMultiplier -= 0.50 * TICK_RATE_PRECISION;
        }
    }

    // Run vector debug every 10 seconds.
    /*
    if (frame % (TICK_RATE * 10) == 0)
    {
        DebugVectors();
    }
    */
}

//////////////////////////////////////////////////////////////////////////////
// SDKHOOK CALLBACKS                                                        //
//////////////////////////////////////////////////////////////////////////////

void EntitySpawn(int entityIndex)
{
    CBaseEntity entity = view_as<CBaseEntity>(entityIndex);
    entity.SpawnPosition = entity.GetAbsOrigin(.global = false);
    /*
    if (entity.ClassEquals("tf_projectile_energy_ring")) // Set the hitbox size of the Righteous Bison/Pomson 6000 projectiles.
    {
        Vector maxs = Vector(3.0, 3.0, 10.0, true);
        Vector mins = -maxs;
        entity.SetMemberVector(Prop_Send, "m_vecMaxs", maxs);
        entity.SetMemberVector(Prop_Send, "m_vecMins", mins);
        entity.SetMember(Prop_Send, "m_usSolidFlags", entity.GetMember(Prop_Send, "m_usSolidFlags") | FSOLID_USE_TRIGGER_BOUNDS);
        entity.SetMember(Prop_Send, "m_triggerBloat", 24);
    }
    */
}

Action EntityTouch(int entityIndex, int otherIndex)
{
    CBaseEntity self = view_as<CBaseEntity>(entityIndex);
    CBaseEntity other = view_as<CBaseEntity>(otherIndex);
    CTFPlayer victim = ToTFPlayer(other);
    if (victim != INVALID_ENTITY && self.ClassContains("tf_projectile") != -1)
    {
        victim.LastProjectileEncountered = self;
        victim.TimeSinceLastProjectileEncounter = GetGameTime();
        if (self.ClassEquals("tf_projectile_stun_ball"))
            pl_impact_stun_range_mutes = 2;
    }
    return Plugin_Continue;
}

void ClientEquippedWeapon(int index, int weapon)
{
    CTFPlayer client = view_as<CTFPlayer>(index);
    if (client.GetWeapon(weapon) == INVALID_ENTITY) // If the player picks up a dropped weapon, re-structurise their weapon list.
        client.StructuriseWeaponList();
}

// i literally have to use this just because fall damage isn't accounted for in my ontakedamage dhook...
Action ClientTookFallDamage(int victimIndex, int &attackerIndex, int &inflictor, float &damage, int &damagetype, int &weaponIndex, float damageForce[3], float damagePosition[3], int damagecustom)
{
    CTFPlayer victim = view_as<CTFPlayer>(victimIndex);
    if (victim.GetWeapon(444) != INVALID_ENTITY && damagetype & DMG_FALL) // 50% fall damage reduction with the Mantreads.
    {
        damage *= 0.50;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////////////////
// DHOOKS                                                                   //
//////////////////////////////////////////////////////////////////////////////

MRESReturn Deflected(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CBaseEntity projectile = view_as<CBaseEntity>(entity);
    projectile.SpawnPosition.Dispose();
    projectile.SpawnPosition = projectile.GetAbsOrigin(.global = false);
    return MRES_Ignored;
}

MRESReturn DispenseAmmo(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTFPlayer player = parameters.Get(1);
    if (player.GetActiveWeapon().ItemDefinitionIndex == 730 || player.TimeSinceSwitchFromNoAmmoWeapon + 10.00 > GetGameTime()) // Do not give ammo to players with the Beggar's Bazooka while equipping it less than 10 seconds after switching from it.
    {
        returnValue.Value = false;
        return MRES_Supercede;
    }
    return MRES_Ignored;
}

MRESReturn Deploy(int index, DHookReturn returnValue)
{
    CTFWeaponBase entity = view_as<CTFWeaponBase>(index);
    CTFPlayer player = ToTFPlayer(entity.Owner);
    if (!player.Exists)
        return MRES_Ignored;
    CTFWeaponBase lastWeapon = ToTFWeaponBase(player.GetMemberEntity(Prop_Send, "m_hLastWeapon"));

    // Weapon switch checks.
    if (lastWeapon != INVALID_ENTITY)
    {
        if (lastWeapon.ItemDefinitionIndex == 730) 
            player.TimeSinceSwitchFromNoAmmoWeapon = GetGameTime();

        // Checks for weapons with a slower holster speed.
        float multiplier = 1.0;
        float oldMultiplier = 1.0;
        lastWeapon.HookValueFloat(multiplier, "mult_switch_from_wep_deploy_time");
        if (player.LastWeaponWithSlowHolster.Exists)
            lastWeapon.HookValueFloat(oldMultiplier, "mult_switch_from_wep_deploy_time");
        if (multiplier > 1.0 && multiplier >= oldMultiplier)
            player.LastWeaponWithSlowHolster = lastWeapon;
    }

    // Re-wrote the deploy function for a couple of things.
    entity.SetMember(Prop_Send, "m_iReloadMode", TF_RELOAD_START);
    float flOriginalPrimaryAttack = entity.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack");
    float flOriginalSecondaryAttack = entity.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack");
    bool bDeploy = SDKCall(SDKCall_CBaseCombatWeapon_Deploy, index);
    if (bDeploy)
    {
        if (player == INVALID_ENTITY)
        {
            returnValue.Value = false;
            return MRES_Supercede;
        }

        float flWeaponSwitchTime = 0.50;

        // Overrides the anim length for calculating ready time.
        float flDeployTimeMultiplier = 1.00;
        entity.HookValueFloat(flDeployTimeMultiplier, "mult_single_wep_deploy_time");

        // Global weapon speed changes. The Reserve shooter is not affected by this.
        if (entity.ItemDefinitionIndex != 415)
            player.HookValueFloat(flDeployTimeMultiplier, "mult_deploy_time");
        
        if (lastWeapon != INVALID_ENTITY || player.GetMemberEntity(Prop_Send, "m_hGrapplingHookTarget") != INVALID_ENTITY) // I intentionally left out the checks for whether the player has had his previous weapon equippde for >=0.5s. I don't think that is necessary.
            lastWeapon.HookValueFloat(flDeployTimeMultiplier, "mult_switch_from_wep_deploy_time");
        if (lastWeapon != player.LastWeaponWithSlowHolster && player.LastWeaponWithSlowHolster.Exists && GetGameTime() - player.LastWeaponWithSlowHolster.LastHolsterTime < 0.5) // Still apply the slower holster attribute if the player has not switched from their slow holstering weapon for more than 0.5s.
            player.LastWeaponWithSlowHolster.HookValueFloat(flDeployTimeMultiplier, "mult_switch_from_wep_deploy_time");

        // swords deploy and holster 75% slower
        int iIsSword = 0;
        if (lastWeapon != INVALID_ENTITY)
            lastWeapon.HookValueInt(iIsSword, "is_a_sword");
        entity.HookValueInt(iIsSword, "is_a_sword");
        if (iIsSword)
            flDeployTimeMultiplier *= 1.75;

        if (player.m_Shared.InCond(TFCond_RuneAgility))
            flDeployTimeMultiplier /= 5.00;
        
        flDeployTimeMultiplier = max(flDeployTimeMultiplier, 0.00001);
        float flDeployTime = flWeaponSwitchTime * flDeployTimeMultiplier;
        float flPlaybackRate = clamp( ( 1.00 / flDeployTimeMultiplier ) * ( 0.67 / flWeaponSwitchTime ), -4.00, 12.00 ); // clamp between the range that's defined in send table
        if (player.GetMemberEntity(Prop_Send, "m_hViewModel") != INVALID_ENTITY)
            player.GetMemberEntity(Prop_Send, "m_hViewModel").SetMemberFloat(Prop_Send, "m_flPlaybackRate", flPlaybackRate);

        // Don't override primary attacks that are already further out than this. This prevents
        // people exploiting weapon switches to allow weapons to fire faster.
        entity.SetMemberFloat(Prop_Send, "m_flNextPrimaryAttack", max(flOriginalPrimaryAttack, GetGameTime() + flDeployTime));
        entity.SetMemberFloat(Prop_Send, "m_flNextSecondaryAttack", max(flOriginalSecondaryAttack, entity.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack")));

        player.SetMemberFloat(Prop_Send, "m_flNextAttack", entity.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack"));

        entity.m_flLastDeployTime = GetGameTime();
        if (lastWeapon != INVALID_ENTITY)
            lastWeapon.LastHolsterTime = GetGameTime();

        // Reset our deploy-lifetime kill counter.
        player.SetMember(Prop_Send, "m_iKillCountSinceLastDeploy", 0);
        player.SetMemberFloat(Prop_Send, "m_flFirstPrimaryAttack", entity.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack"));

        returnValue.Value = bDeploy;
        return MRES_Supercede;
    }
    return MRES_Ignored;
}

MRESReturn GetWeaponSpread(int index, DHookReturn returnValue)
{
    CTFWeaponBase entity = view_as<CTFWeaponBase>(index);

    // from server.so - CTFWeaponBaseGun::GetWeaponSpread:
    // v2 = *(float *)(*((_DWORD *)this + 429) + (*((_DWORD *)this + 426) << 6) + 1796);
    float spread = entity.m_pWeaponInfo.GetWeaponData(entity.m_iWeaponMode).m_flSpread;
    entity.HookValueFloat(spread, "mult_spread_scale");

    CTFPlayer player = ToTFPlayer(entity.Owner);
    if (player != INVALID_ENTITY)
    {
        if (player.m_Shared.InCond(TFCond_RunePrecision))
        {
            if (entity.ClassEquals("tf_weapon_minigun"))
                spread *= 0.4;
            else
                spread *= 0.1;
        }

        // I'm still keeping this because I have plans for adding the old Panic Attack back as a separate weapon.
        float reducedHealthBonus = 1.0;
        entity.HookValueFloat(reducedHealthBonus, "panic_attack_negative");
        if (reducedHealthBonus != 1.0)
        {
            reducedHealthBonus = RemapValClamped(player.HealthFraction(), 0.20, 0.90, reducedHealthBonus, 1.0);
            spread *= reducedHealthBonus;
        }

        // Re-write the Panic Attack spread worsening.
        float consecutive;
        entity.HookValueFloat(consecutive, "mult_spread_scales_consecutive");
        if (consecutive)
        {
            spread *= entity.SpreadMultiplier;
            entity.SpreadMultiplier += 0.10;
            entity.LastShot = GetGameTime();
        }
    }
    
    returnValue.Value = spread;
    return MRES_Supercede;
}

MRESReturn ExtinguishPlayerInternal(int index, DHookReturn returnValue, DHookParam parameters)
{
    // Used for the Manmelter.
    CTFWeaponBase weapon = view_as<CTFWeaponBase>(index);
    CTFPlayer target = view_as<CTFPlayer>(parameters.Get(1));
    CTFPlayer owner = view_as<CTFPlayer>(parameters.Get(2));
    returnValue.Value = false;
    if (target.m_Shared.InCond(TFCond_OnFire))
    {
        ExtinguishPlayer(weapon, owner, target, weapon.GetName());
        if (target.OriginalBurner.GetTeam() != target.GetTeam() && target.GetTeam() != owner.GetTeam())
            owner.SetMember(Prop_Send, "m_iRevengeCrits", owner.GetMember(Prop_Send, "m_iRevengeCrits") + 1);

        float currentNextAttack = weapon.GetMemberFloat(Prop_Send, "m_flNextPrimaryAttack");
        weapon.SetMemberFloat(Prop_Send, "m_flNextPrimaryAttack", currentNextAttack < GetGameTime() + 1.0 ? GetGameTime() + 1.0 : currentNextAttack );

        if (owner.GetMember(Prop_Send, "m_iRevengeCrits") == 1 && !owner.m_Shared.InCond(TFCond_Kritzkrieged))
            owner.m_Shared.AddCond(TFCond_Kritzkrieged);

        returnValue.Value = true;
    }
    return MRES_Supercede;
}

MRESReturn Explode(int index, DHookReturn returnValue, DHookParam parameters)
{
    // Create an actual explosion with the Gas Passer.
    CBaseEntity entity = view_as<CBaseEntity>(index);
    CTFWeaponBase weapon = ToTFWeaponBase(entity.GetMemberEntity(Prop_Send, "m_hLauncher"));
    CTakeDamageInfo newInfo = CTakeDamageInfo(entity, weapon.Owner, weapon, entity.GetAbsOrigin(), entity.GetAbsOrigin(), 75.00, DMG_BLAST | DMG_HALF_FALLOFF, 0, entity.GetAbsOrigin());
    CTFRadiusDamageInfo radiusInfo = CTFRadiusDamageInfo(newInfo, entity.GetAbsOrigin(), 146.00);
    g_pGameRules.RadiusDamage(radiusInfo);
    newInfo.Dispose();
    radiusInfo.Dispose();
    return MRES_Ignored;
}

MRESReturn CBaseObject_OnTakeDamage(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = CTakeDamageInfo.FromAddress(parameters.Get(1));
    CTFPlayer attacker = view_as<CTFPlayer>(info.m_hAttacker);
    if (!attacker.IsPlayer)
        return MRES_Ignored;

    // Buff the Righteous Bison and Pomson 6000 damage numbers.
    if (info.m_hWeapon.ItemDefinitionIndex == 442 || info.m_hWeapon.ItemDefinitionIndex == 588)
        info.m_flDamage = 60.00;

    return MRES_Ignored;
}

MRESReturn CTFPlayer_OnTakeDamage(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = CTakeDamageInfo.FromAddress(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    CTFPlayer attacker = view_as<CTFPlayer>(info.m_hAttacker);
    if (!attacker.IsPlayer)
        return MRES_Ignored;

    float oldDamage = info.m_flDamage;

    // Re-work the flame density system with Pyro's flamethrower.
    if (info.m_bitsDamageType & DMG_IGNITE && info.m_hWeapon != INVALID_ENTITY && info.m_hWeapon.ClassEquals("tf_weapon_flamethrower"))
    {
        float damage = 13.00 * victim.FlameDensity;
        info.m_hWeapon.HookValueFloat(damage, "mult_dmg");
        damage *= RemapValClamped(attacker.GetAbsOrigin().DistTo(victim.GetAbsOrigin()), tf_flamethrower_maxdamagedist.FloatValue / 2.00, tf_flamethrower_maxdamagedist.FloatValue, 1.00, 0.50);
        victim.TimeSinceHitByFlames = GetGameTime();
        victim.FlameDensity += 0.04;

        info.m_bitsDamageType &= ~DMG_USEDISTANCEMOD;
        info.m_flDamage = damage;

        PrintToChatAll("%f : %f", oldDamage, info.m_flDamage);
    }

    // Always mini-crit with the shield while charging and the next melee crit is CRIT_MINI. This allows the Caber to also mini-crit.
    if (attacker.GetMember(Prop_Send, "m_iNextMeleeCrit") == 1 && attacker.GetActiveWeapon() == attacker.GetWeaponFromSlot(TFWeaponSlot_Melee))
        info.SetCritType(victim, CRIT_MINI);

    // Increase the Caber self-explosive damage by 10%. Also rewrote the explosive damage ramp-up since it's currently finnicky.
    if (info.m_hWeapon.ItemDefinitionIndex == 307 && info.m_iDamageCustom == TF_CUSTOM_STICKBOMB_EXPLOSION)
    {
        if (victim == attacker)
            info.m_flDamage *= 1.1;
        else
        {
            info.m_bitsDamageType &= ~DMG_USEDISTANCEMOD; // Do not use internal rampup/falloff.
            info.m_flDamage = victim.CalculateRadiusDamage(info.m_vecDamagePosition, 146.00, 75.00, 1.10, 1.00);
        }
    }

    // Return between 4 and 2 HP with the Pretty Boy's Pocket Pistol, from a range of 0 to 512 HU.
    if (info.m_hWeapon.ItemDefinitionIndex == 773)
        attacker.Heal(RoundToCeil(RemapValClamped(attacker.GetAbsOrigin().DistTo(victim.GetAbsOrigin()), 0.00, 512.00, 4.00, 2.00)));

    // Give a 50% damage bonus with the Flying Guillotine on stunned targets.
    if ((info.m_hWeapon.ItemDefinitionIndex == 812 || info.m_hWeapon.ItemDefinitionIndex == 833) && victim.Stunned)
        info.m_flDamage *= 1.50;

    // Ignition checks.
    if (info.m_bitsDamageType & DMG_IGNITE)
    {
        victim.OnFire = victim.m_Shared.InCond(TFCond_OnFire);
        if (!victim.OnFire)
            victim.OriginalBurner = attacker;
    }

    // Force the damage number with a stun ball from the sandman to be 15, 30 with a moonshot. On moonshots fully stun the victim as well.
    // Also I'm gonna deal with stunning differently, because the current stun mechanic is quite bad.
    if (info.m_iDamageCustom == TF_CUSTOM_BASEBALL && info.m_hWeapon.ItemDefinitionIndex == 44)
    {
        float timeExisted = min(GetGameTime() - victim.LastProjectileEncountered.Timestamp, FLIGHT_TIME_TO_MAX_STUN);
        float duration = timeExisted / FLIGHT_TIME_TO_MAX_SLOWDOWN_RAMPUP * tf_scout_stunball_base_duration.FloatValue;
        info.m_flDamage = 15.00;
        victim.TimeUntilSandmanStunEnd = GetGameTime() + duration;
        victim.m_Shared.RemoveCond(TFCond_Dazed);
        if (timeExisted == FLIGHT_TIME_TO_MAX_STUN)
        {
            duration += 1.0; // 7 seconds in total.
            info.m_flDamage = 30.00;
            victim.m_Shared.StunPlayer(duration, 0.5, TF_STUN_CONTROLS | TF_STUN_SPECIAL_SOUND, attacker);
        }
    }

    // Deal crits on burning players with the Sun-on-a-Stick.
    if (info.m_hWeapon.ItemDefinitionIndex == 349 && !(info.m_bitsDamageType & DMG_BURN) && victim.m_Shared.InCond(TFCond_OnFire))
        info.SetCritType(victim, CRIT_FULL);

    // Deal crits on behind with the Backburner.
    if (info.m_hWeapon.ItemDefinitionIndex == 40 && victim.IsPlayerBehind(attacker, 0.75) && info.m_bitsDamageType & DMG_IGNITE)
        info.SetCritType(victim, CRIT_FULL);

    // Deal actual stomp damage with the Mantreads and Thermal Thruster.
    if (info.m_iDamageCustom == TF_CUSTOM_BOOTS_STOMP)
        info.m_flDamage = g_pGameRules.FlPlayerFallDamage(attacker) * 3 + 10.00;

    // Deal mini-crits on airblasted targets with the Reserve Shooter. Deal 15% less damage on grounded or airblasted targets.
    if (info.m_hWeapon.ItemDefinitionIndex == 415)
    {
        if (victim.m_Shared.InCond(TFCond_KnockedIntoAir))
            info.SetCritType(victim, CRIT_MINI);
        if (!victim.m_Shared.InCond(TFCond_BlastJumping) && !victim.m_Shared.InCond(TFCond_GrapplingHook) && !victim.m_Shared.InCond(TFCond_RocketPack))
            info.m_flDamage *= 0.85;
    }

    // Buff the Righteous Bison and Pomson 6000 damage numbers.
    if (info.m_hWeapon.ItemDefinitionIndex == 442 || info.m_hWeapon.ItemDefinitionIndex == 588)
    {
        // Damage numbers.
        info.m_bitsDamageType &= ~DMG_USEDISTANCEMOD; // Do not use internal rampup/falloff.
        info.m_flDamage = 60.00 * RemapValClamped((victim.LastProjectileEncountered.SpawnPosition - victim.GetAbsOrigin()).Length(), 50.00, 800.000, 1.5, 0.5); // Deal 60 base damage with 150% rampup, 50% falloff.
        victim.LastProjectileEncountered.Remove();
    }

    // Handle with blast jumping for all classes, except for Soldier and Demoman (these are already dealt with).
    if ((info.m_bitsDamageType & DMG_BLAST || info.m_iDamageCustom == TF_CUSTOM_FLARE_EXPLOSION) && attacker == victim && victim.Class != TFClass_DemoMan && victim.Class != TFClass_Soldier && !(victim.GetFlags() & (FL_ONGROUND | FL_INWATER)))
    {
        Event event = CreateEvent("rocket_jump");
        event.SetInt("userid", victim.GetUserID());
        event.SetBool("playsound", false);
        event.Fire();
        victim.m_Shared.AddCond(TFCond_BlastJumping);
    }
    
    // Gas Passer damage management.
    if (info.m_hWeapon.ItemDefinitionIndex == 1180)
    {
        victim.FromGasPasser = true;
        if (attacker == victim) // Deal 33% more self damage with the Gas Passer.
            info.m_flDamage *= 1.33;
        else if (victim.m_Shared.InCond(TFCond_OnFire) && info.m_bitsDamageType & DMG_BLAST && victim.TimeSinceLastProjectileEncounter == GetGameTime() && victim.LastProjectileEncountered.ClassEquals("tf_projectile_jar_gas")) // Deal mini-crit damage on direct hits.
            info.SetCritType(victim, CRIT_MINI);
    }

    // Damage that ignites the player will mini-crit while marked as a volcano from the Sharpened Volcano Fragment.
    if (victim.FromSVF.Exists && info.m_bitsDamageType & DMG_IGNITE)
        info.SetCritType(victim, CRIT_MINI);

    // Sharpened Volcano Fragment checks.
    if (info.m_hWeapon.ItemDefinitionIndex == 348 && (info.m_hAttacker.GetTeam() != victim.GetTeam() || info.m_hAttacker == victim))
        victim.FromSVF = info.m_hWeapon;

    // Re-write the rampup/falloff with the Air Strike to be between the projectile's original position and the victim.
    if (info.m_hWeapon.ItemDefinitionIndex == 1104 && victim != attacker && info.m_eCritType != CRIT_FULL)
    {
        float damage = 90.00;
        info.m_hWeapon.HookValueFloat(damage, "mult_dmg"); // can't pass methodmap properties by reference apparently.
        damage *= RemapValClamped((info.m_hInflictor.SpawnPosition - victim.GetAbsOrigin()).Length(), 50.00, 1024.00, 1.25, info.m_eCritType == CRIT_MINI ? 1.00 : 0.528); // 150% rampup, 52.8% falloff

        info.m_bitsDamageType &= ~DMG_USEDISTANCEMOD;
        info.m_flDamage = damage;
    }

    // Attribute hooks.
    if (info.m_hWeapon != INVALID_ENTITY)
    {
        // Fix the crit_while_airborne attribute so it works to any weapon with it.
        int value;
        info.m_hWeapon.HookValueInt(value, "crit_while_airborne");
        if (value && attacker.m_Shared.InCond(TFCond_BlastJumping))
            info.SetCritType(victim, CRIT_FULL);

        // Damage players connected onto the same dispenser beam with weapons using the damage_all_connected attribute.
        // This code is VERY janky but I don't know how else to get this to work without it crashing.
        value = 0;
        info.m_hWeapon.HookValueInt(value, "damage_all_connected");
        if (value && !attacker.RecursiveCheck)
        {
            for (int i = 0; i < victim.m_Shared.GetNumHealers(); ++i)
            {
                Healers_t healer = victim.m_Shared.m_aHealers.Get(i, healers_tSize);
                if (healer.m_bDispenserHeal)
                {
                    CObjectDispenser dispenser = view_as<CObjectDispenser>(healer.m_pHealer);
                    for (int v = 0; v < dispenser.m_hHealingTargets.Count(); ++v)
                    {
                        CTFPlayer player = ToTFPlayer(CBaseEntity.GetFromHandle(dispenser.m_hHealingTargets.Get(v)));
                        if (player != victim)
                        {
                            if (attacker.ConnectedInfo == NULL)
                                attacker.ConnectedInfo = info.Copy();
                            DataPack data = new DataPack();
                            data.WriteCell(attacker);
                            data.WriteCell(player);
                            RequestFrame(DamageAllConnected, data);
                            ++attacker.RecursiveCheck;
                        }
                    }
                }
            }
        }

        // Count players covered in gasoline as wet.
        value = 0;
        info.m_hWeapon.HookValueInt(value, "crit_vs_wet_players");
        if (value && (victim.m_Shared.InCond(TFCond_Gas) || victim.FromGasPasser))
            info.SetCritType(victim, CRIT_FULL);
    }
    
    return MRES_Ignored;
}

MRESReturn OnTakeDamagePost(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = CTakeDamageInfo.FromAddress(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    CTFPlayer attacker = view_as<CTFPlayer>(info.m_hAttacker);
    
    if (!attacker.IsPlayer)
        return MRES_Ignored;

    // Afterburn duration management.
    if ((info.m_bitsDamageType & DMG_IGNITE || info.m_hWeapon.ItemDefinitionIndex == 1180 || info.m_hWeapon.ItemDefinitionIndex == 348) && victim.Alive && victim.GetPlayerClass() != TFClass_Pyro && !victim.m_Shared.InCond(TFCond_AfterburnImmune))
    {
        float currentLength = victim.m_Shared.m_flBurnDuration;
        if ((info.m_hWeapon.ItemDefinitionIndex == 215 || victim.FromDegreaser)) // Degreaser.
        {
            victim.FromDegreaser = true;
            if (victim.OnFire) // Increase afterburn duration by 0.4, capped at up to 3s, with the Degreaser.
                victim.m_Shared.m_flBurnDuration = min(currentLength, 3.0);
            else
                victim.m_Shared.m_flBurnDuration = 1.0; // The Degreaser afterburn duration initially only lasts 1.0s.
        }
        else if (info.m_hWeapon.ItemDefinitionIndex == 740) // Scorch Shot.
            victim.m_Shared.m_flBurnDuration = 6.0; // Capped at only 6s with the Scorch Shot afterburn.
        else if (info.m_hWeapon.ItemDefinitionIndex == 348) // Sharpened Volcano Fragment.
            victim.m_Shared.m_flBurnDuration = 10.0; // Max afterburn.
    }

    // Ignite players from the back with the Sun-on-a-Stick.
    // this is so fucking stupid
    if (info.m_hWeapon.ItemDefinitionIndex == 349 && !(info.m_bitsDamageType & DMG_BURN) && victim.IsPlayerBehind(attacker))
    {
        victim.m_Shared.Burn(attacker, info.m_hWeapon, 1.5);
        victim.m_Shared.m_flBurnDuration = 1.5; // Prevent stacking with the afterburn duration.
    }

    return MRES_Ignored;
}

MRESReturn OnTakeDamageAlive(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = CTakeDamageInfo.FromAddress(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    CTFPlayer attacker = view_as<CTFPlayer>(info.m_hAttacker);

    // 30% less self damage from the flare guns and blast damage if the Third Degree is equipped.
    if (attacker == victim && (info.m_iDamageCustom == TF_CUSTOM_FLARE_EXPLOSION || info.m_bitsDamageType & DMG_BLAST) && victim.GetWeapon(593) != INVALID_ENTITY)
        info.m_flDamage *= 0.70;

    return MRES_Ignored;
}

MRESReturn OnTakeDamageAlivePost(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = CTakeDamageInfo.FromAddress(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    CTFPlayer attacker = view_as<CTFPlayer>(info.m_hAttacker);
    CEconEntity doesHaveWeapon;

    // Lose boost from taking damage with the Baby Face's Blaster (75 damage to bring player down from 100 to 0).
    if (victim.GetWeapon(772) != INVALID_ENTITY)
        victim.SetMemberFloat(Prop_Send, "m_flHypeMeter", max(0.00, victim.GetMemberFloat(Prop_Send, "m_flHypeMeter") - info.m_flDamage * 1.5));
    
    // Deal up to 750 damage to get max charge with the Gas Passer, if the damage is not dealt by the Gas Passer explosion.
    doesHaveWeapon = attacker.GetWeapon(1180);
    if (doesHaveWeapon != INVALID_ENTITY && victim != attacker && (info.m_hWeapon.ItemDefinitionIndex != 1180 || info.m_bitsDamageType & DMG_BLAST == 0))
        doesHaveWeapon.RechargeTime += info.m_flDamage / 7.5;
    
    return MRES_Ignored;
}

MRESReturn TeamFortress_CalculateMaxSpeed(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    
    // Decrease the player's speed by half if they are stunned by the Sandman.
    if (victim.TimeUntilSandmanStunEnd > GetGameTime())
    {
        returnValue.Value = view_as<float>(returnValue.Value) / 2;
        return MRES_Override;
    }
    return MRES_Ignored;
}

MRESReturn AddCond(Address thisPointer, DHookParam parameters)
{
    CTFPlayerShared shared = view_as<CTFPlayerShared>(thisPointer);
    CTFPlayer client = ToTFPlayer(shared.m_pOuter);
    TFCond condition = parameters.Get(1);
    /*
    float duration = parameters.Get(2);
    */
    if (condition == TFCond_Gas)
        client.FromGasPasser = true;
    return MRES_Ignored;
}

MRESReturn RemoveCond(Address thisPointer, DHookParam parameters)
{
    CTFPlayerShared shared = view_as<CTFPlayerShared>(thisPointer);
    CTFPlayer client = ToTFPlayer(shared.m_pOuter);
    TFCond condition = parameters.Get(1);

    if (condition == TFCond_Dazed)
    {
        CTFWeaponBase weapon = client.GetActiveWeapon();
        if (weapon != INVALID_ENTITY)
            weapon.SetMember(Prop_Send, "m_fEffects", weapon.GetMember(Prop_Send, "m_fEffects") & ~EF_NODRAW);
    }
    else if (condition == TFCond_OnFire)
        client.TimeSinceStoppedBurning = GetGameTime();
    return MRES_Ignored;
}

MRESReturn InCond(Address thisPointer, DHookReturn returnValue, DHookParam parameters)
{
    CTFPlayerShared shared = view_as<CTFPlayerShared>(thisPointer);
    CTFPlayer client = ToTFPlayer(shared.m_pOuter);
    CTFWeaponBase weapon = client.LastProjectileEncountered.Exists && client.LastProjectileEncountered.HasMember(Prop_Send, "m_hLauncher") ? view_as<CTFWeaponBase>(client.LastProjectileEncountered.GetMemberEntity(Prop_Send, "m_hLauncher")) : view_as<CTFWeaponBase>(INVALID_ENTITY);
    TFCond condition = parameters.Get(1);

    // Do not inflict greater knockback on burning targets. This is janky but it's the simplest solution. I might replace this with memory patching at some point.
    if (condition == TFCond_OnFire && client.TimeSinceLastProjectileEncounter == GetGameTime() && weapon.ItemDefinitionIndex == 740)
    {
        client.TimeSinceLastProjectileEncounter = 0.00;
        returnValue.Value = false;
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

MRESReturn FlPlayerFallDamage(Address thisPointer, DHookReturn returnValue, DHookParam parameters)
{
    CTFPlayer pPlayer = parameters.Get(1);
    if (returnValue.Value != 0.00 && notnheavy_tf2rebalance_use_fixed_falldamage.IntValue) // Re-calculate the fall damage, albeit without the randomness. Code taken from CTFGameRules::FlPlayerFallDamage.
    {
        // Old TFC damage formula
        float flFallDamage = 5 * (pPlayer.GetMemberFloat(Prop_Send, "m_flFallVelocity") / 300);

        // Fall damage needs to scale according to the player's max health, or
        // it's always going to be much more dangerous to weaker classes than larger.
        float flRatio = pPlayer.GetMember(Prop_Data, "m_iMaxHealth") / 100.0;
        flFallDamage *= flRatio;

        returnValue.Value = flFallDamage;
        return MRES_Override;
    }
    return MRES_Ignored;
}

//////////////////////////////////////////////////////////////////////////////
// OTHER HOOKS                                                              //
//////////////////////////////////////////////////////////////////////////////

public Action SoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entityIndex, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    // Stop the Sandman moonshot sound from playing too early, instead play the stock impact stun sound. The current Sandman's moonshot apparently occurs somewhat before the old one occurred.
    //CBaseEntity entity = view_as<CBaseEntity>(entityIndex);
    //CTFPlayer player = ToTFPlayer(entity);
    if (StrContains(sample, "pl_impact_stun_range") != -1 && pl_impact_stun_range_mutes > 0)
    {
        --pl_impact_stun_range_mutes;
        sample = "player/pl_impact_stun.wav";
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////////////////
// MEMORY                                                                   //
//////////////////////////////////////////////////////////////////////////////

int LoadEntityHandleFromAddress(Address addr) // From nosoop's stocksoup framework.
{
    return EntRefToEntIndex(LoadFromAddress(addr, NumberType_Int32) | (1 << 31));
}

void StoreEntityHandleToAddress(Address addr, int entity) // From nosoop's stocksoup framework.
{
	StoreToAddress(addr, IsValidEntity(entity)? EntIndexToEntRef(entity) & ~(1 << 31) : 0, NumberType_Int32);
}

int GetEntityFromAddress(Address pEntity) // From nosoop's stocksoup framework.
{
    static int offs_RefEHandle;
    if (offs_RefEHandle) 
    {
        return LoadEntityHandleFromAddress(pEntity + view_as<Address>(offs_RefEHandle));
    }

    // if we don't have it already, attempt to lookup offset based on SDK information
    // CWorld is derived from CBaseEntity so it should have both offsets
    int offs_angRotation = FindDataMapInfo(0, "m_angRotation"), offs_vecViewOffset = FindDataMapInfo(0, "m_vecViewOffset");
    if (offs_angRotation == -1) 
    {
        ThrowError("Could not find offset for ((CBaseEntity) CWorld)::m_angRotation");
    }
    else if (offs_vecViewOffset == -1) 
    {
        ThrowError("Could not find offset for ((CBaseEntity) CWorld)::m_vecViewOffset");
    } 
    else if ((offs_angRotation + 0x0C) != (offs_vecViewOffset - 0x04)) 
    {
        char game[32];
        GetGameFolderName(game, sizeof(game));
        ThrowError("Could not confirm offset of CBaseEntity::m_RefEHandle "
                ... "(incorrect assumption for game '%s'?)", game);
    }

    // offset seems right, cache it for the next call
    offs_RefEHandle = offs_angRotation + 0x0C;
    return GetEntityFromAddress(pEntity);
}

any Dereference(Address address, NumberType bitdepth = NumberType_Int32)
{
	return LoadFromAddress(address, bitdepth);
}

void WriteToValue(Address address, any value, NumberType bitdepth = NumberType_Int32)
{
    StoreToAddress(address, value, bitdepth);
}