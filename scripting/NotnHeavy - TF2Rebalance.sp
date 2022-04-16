// TODO: work on something similar to mini-crit impact sounds with the Flying Guillotine on stunned targets.
// TODO (idk if i wanna do this): make the equalizer throwable that deals normal melee damage and knockback on right click. i think this'll be hilarious lol

//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// This uses nosoop's fork of TF2Attributes.
// https://github.com/nosoop/tf2attributes

// This plugin also uses DHooks with Detours by Dr!fter. Unless compiled with >= SM 1.11, you'll have to include the plugin below:
// https://forums.alliedmods.net/showthread.php?t=180114

#pragma semicolon true 
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>
#include <dhooks>

#define EF_NODRAW 0x0020 // EF_NODRAW prevents any data about an entity from being transmitted to the client, without affecting it on the server. In other words, it makes the entity disappear from the player's view without deleting it.

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

static ConVar tf_scout_stunball_base_duration;
ConVar tf_weapon_criticals;
ConVar tf_use_fixed_weaponspreads;
ConVar notnheavy_tf2rebalance_use_fixed_falldamage;
bool initiatedConVars;

DHookSetup DHooks_CObjectDispenser_DispenseAmmo;

DHookSetup DHooks_CTFPlayer_OnTakeDamage;
DHookSetup DHooks_CTFPlayer_OnTakeDamage_Alive;
DHookSetup DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed;
DHookSetup DHooks_CTFPlayerShared_AddCond;
DHookSetup DHooks_CTFPlayerShared_RemoveCond;
DHookSetup DHooks_CTFGameRules_FlPlayerFallDamage;

Handle SDKCall_CTFWeaponBase_GetMaxClip1;

Handle SDKCall_CTFPlayer_TeamFortress_CalculateMaxSpeed;
Handle SDKCall_CTFPlayer_GetMaxAmmo;
Handle SDKCall_CTFPlayerShared_Burn;

Address CTFWeaponBase_m_flLastDeployTime;

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

#include "methodmaps/mathlib/Vector.sp"
#include "methodmaps/server/CBaseEntity.sp"
#include "methodmaps/shared/CEconEntity.sp"
#include "methodmaps/shared/CTFWeaponBase.sp"
#include "methodmaps/shared/CTFPlayerShared.sp"
#include "methodmaps/shared/CTFWearable.sp"
#include "methodmaps/server/CTFPlayer.sp"
#include "methodmaps/server/CTakeDamageInfo.sp"

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
    HookEvent("player_hurt", ClientHurt, EventHookMode_Pre);

    RegConsoleCmd("loadout", ShowLoadout);

    // Configs.
    GameData config = LoadGameConfigFile(PLUGIN_NAME);
    if (config == null)
    {
        SetFailState("The configuration file for plugin \"%s\" has failed to load. Please make sure that it is actually present in your gamedata directory.", PLUGIN_NAME);
    }

    // DHooks.
    DHooks_CTFPlayer_OnTakeDamage = DHookCreateFromConf(config, "CTFPlayer::OnTakeDamage");
    DHooks_CTFPlayer_OnTakeDamage_Alive = DHookCreateFromConf(config, "CTFPlayer::OnTakeDamage_Alive");
    DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed = DHookCreateFromConf(config, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
    DHooks_CTFPlayerShared_AddCond = DHookCreateFromConf(config, "CTFPlayerShared::AddCond");
    DHooks_CTFPlayerShared_RemoveCond = DHookCreateFromConf(config, "CTFPlayerShared::RemoveCond");
    DHooks_CObjectDispenser_DispenseAmmo = DHookCreateFromConf(config, "CObjectDispenser::DispenseAmmo");
    DHooks_CTFGameRules_FlPlayerFallDamage = DHookCreateFromConf(config, "CTFGameRules::FlPlayerFallDamage");

    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage, false, OnTakeDamage);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage, true, OnTakeDamagePost);
    DHookEnableDetour(DHooks_CTFPlayer_OnTakeDamage_Alive, true, OnTakeDamageAlivePost);
    DHookEnableDetour(DHooks_CTFPlayer_TeamFortress_CalculateMaxSpeed, true, TeamFortress_CalculateMaxSpeed);
    DHookEnableDetour(DHooks_CTFPlayerShared_AddCond, false, AddCond);
    DHookEnableDetour(DHooks_CTFPlayerShared_RemoveCond, false, RemoveCond);
    DHookEnableDetour(DHooks_CTFGameRules_FlPlayerFallDamage, true, FlPlayerFallDamage);

    // SDKCall.
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_CTFWeaponBase_GetMaxClip1 = EndPrepSDKCall();

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
    
    // Offsets.
    CTFWeaponBase_m_flLastDeployTime = view_as<Address>(GameConfGetOffset(config, "CTFWeaponBase::m_flLastDeployTime"));

    delete config;

    // ConVars.
    tf_scout_stunball_base_duration = FindConVar("tf_scout_stunball_base_duration");
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

public Action ClientHurt(Event event, const char[] name, bool dontBroadcast)
{
    CTFPlayer client = view_as<CTFPlayer>(GetClientOfUserId(event.GetInt("userid")));
    if (client.TakingMiniCritDamage)
        event.SetInt("bonuseffect", 1);
    client.TakingMiniCritDamage = false;
    return Plugin_Changed;
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
}

public void OnGameFrame()
{
    static int frame = 0;
    ++frame;
    pl_impact_stun_range_mutes = 0;

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
                if (regen != 0 && doesHaveWeapon.CleaverChargeMeter - regen == 1.50)
                {
                    regen = doesHaveWeapon.CleaverChargeMeter;
                    doesHaveWeapon.SetMemberFloat(Prop_Send, "m_flEffectBarRegenTime", regen);
                }
                doesHaveWeapon.CleaverChargeMeter = regen;
            }

            // If a player is no longer burning, disable the FromDegreaser check.
            if (!player.m_Shared.InCond(TFCond_OnFire))
                player.FromDegreaser = false;

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

Action EntityTouch(int entityIndex, int otherIndex)
{
    CBaseEntity self = view_as<CBaseEntity>(entityIndex);
    CBaseEntity other = view_as<CBaseEntity>(otherIndex);
    CTFPlayer victim = ToTFPlayer(other);
    if (victim != INVALID_ENTITY && self.ClassContains("tf_projectile") != -1)
    {
        victim.LastProjectileEncountered = self;
        if (self.ClassEquals("tf_projectile_stun_ball"))
            pl_impact_stun_range_mutes = 2;
    }
}

Action ClientDeployingWeapon(int clientIndex, int weaponIndex)
{
    CTFPlayer player = view_as<CTFPlayer>(clientIndex);
    CTFWeaponBase lastWeapon = ToTFWeaponBase(player.GetMemberEntity(Prop_Send, "m_hLastWeapon"));
    if (lastWeapon != INVALID_ENTITY) // Always force weapons to have the previous weapon's holster speed attribute applied.
    {
        lastWeapon.m_flLastDeployTime = 0.00;
        if (lastWeapon.ItemDefinitionIndex == 730)
            player.TimeSinceSwitchFromNoAmmoWeapon = GetGameTime();
    }
    return Plugin_Continue;
}

void ClientEquippedWeapon(int index, int weapon)
{
    CTFPlayer client = view_as<CTFPlayer>(index);
    if (client.GetWeapon(weapon) == INVALID_ENTITY) // If the player picks up a dropped weapon, re-structurise their weapon list.
        client.StructuriseWeaponList();
}

//////////////////////////////////////////////////////////////////////////////
// DHOOKS                                                                   //
//////////////////////////////////////////////////////////////////////////////

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

MRESReturn OnTakeDamage(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = view_as<CTakeDamageInfo>(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);
    if (!info.m_hAttacker.IsPlayer)
        return MRES_Ignored;

    // Always mini-crit with the shield while charging and the next melee crit is CRIT_MINI. This allows the Caber to also mini-crit.
    if (info.m_hAttacker.GetMember(Prop_Send, "m_iNextMeleeCrit") == 1 && info.m_hAttacker.GetActiveWeapon() == info.m_hAttacker.GetWeaponFromSlot(TFWeaponSlot_Melee))
        info.SetCritType(victim, CRIT_MINI);

    // Buff the Caber self-explosive damage by 10%. Also rewrote the explosive damage ramp-up since it's currently finnicky.
    if (info.m_hWeapon.ItemDefinitionIndex == 307 && info.m_iDamageCustom == TF_CUSTOM_STICKBOMB_EXPLOSION)
    {
        if (victim == info.m_hAttacker)
            info.m_flDamage *= 1.1;
        else
        {
            info.m_bitsDamageType ^= DMG_USEDISTANCEMOD; // Do not use internal rampup/falloff.
            info.m_flDamage = victim.CalculateRadiusDamage(info.m_vecDamagePosition, 146.00, 75.00, 1.10, 1.00);
        }
    }

    // Return between 4 and 2 HP with the Pretty Boy's Pocket Pistol, from a range of 0 to 512 HU.
    if (info.m_hWeapon.ItemDefinitionIndex == 773)
        info.m_hAttacker.Heal(RoundToCeil(RemapValClamped((info.m_hAttacker.GetAbsOrigin(.global = true) - victim.GetAbsOrigin(.global = true)).Length(), 0.00, 512.00, 4.00, 2.00)));

    // Give a 50% damage bonus with the Flying Guillotine on stunned targets.
    if ((info.m_hWeapon.ItemDefinitionIndex == 812 || info.m_hWeapon.ItemDefinitionIndex == 833) && victim.Stunned)
        info.m_flDamage *= 1.50;

    // Ignition checks.
    if (info.m_bitsDamageType & DMG_IGNITE)
        victim.OnFire = victim.m_Shared.InCond(TFCond_OnFire);

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
            victim.m_Shared.StunPlayer(duration, 0.5, TF_STUN_CONTROLS | TF_STUN_SPECIAL_SOUND, info.m_hAttacker);
        }
    }

    // Deal crits on burning players with the Sun-on-a-Stick.
    if (info.m_hWeapon.ItemDefinitionIndex == 349 && !(info.m_bitsDamageType & DMG_BURN) && victim.m_Shared.InCond(TFCond_OnFire))
        info.SetCritType(victim, CRIT_FULL);

    // Deal crits on behind with the Backburner.
    if (info.m_hWeapon.ItemDefinitionIndex == 40 && victim.IsPlayerBehind(info.m_hAttacker, 0.50) && info.m_bitsDamageType & DMG_IGNITE)
        info.SetCritType(victim, CRIT_FULL);
     
    return MRES_Ignored;
}

MRESReturn OnTakeDamagePost(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = view_as<CTakeDamageInfo>(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);

    // Manage the afterburn duration with the Degreaser.
    if (info.m_bitsDamageType & DMG_IGNITE && (info.m_hWeapon.ItemDefinitionIndex == 215 || victim.FromDegreaser) && victim.Alive && victim.GetPlayerClass() != TFClass_Pyro)
    {
        float currentLength = victim.m_Shared.m_flBurnDuration;
        victim.FromDegreaser = true;
        if (victim.OnFire) // Increase afterburn duration by 0.4, capped at up to 3s, with the Degreaser.
            victim.m_Shared.m_flBurnDuration = min(currentLength, 3.0);
        else
            victim.m_Shared.m_flBurnDuration = 1.0; // The Degreaser afterburn duration initially only lasts 1.0s.
    }

    // Ignite players from the back with the Sun-on-a-Stick.
    // this is so fucking stupid
    if (info.m_hWeapon.ItemDefinitionIndex == 349 && !(info.m_bitsDamageType & DMG_BURN))
    {
        if (victim.IsPlayerBehind(info.m_hAttacker))
        {
            victim.m_Shared.Burn(info.m_hAttacker, info.m_hWeapon, 1.5);
            victim.m_Shared.m_flBurnDuration = 1.5; // Prevent stacking with the afterburn duration.
        }
    }

    return MRES_Ignored;
}

MRESReturn OnTakeDamageAlivePost(int entity, DHookReturn returnValue, DHookParam parameters)
{
    CTakeDamageInfo info = view_as<CTakeDamageInfo>(parameters.Get(1));
    CTFPlayer victim = view_as<CTFPlayer>(entity);

    // Lose boost from taking damage with the Baby Face's Blaster (75 damage to bring player down from 100 to 0).
    if (victim.GetWeapon(772))
        victim.SetMemberFloat(Prop_Send, "m_flHypeMeter", max(0.00, victim.GetMemberFloat(Prop_Send, "m_flHypeMeter") - info.m_flDamage * 1.5));
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
    /*
    CTFPlayerShared shared = view_as<CTFPlayerShared>(thisPointer);
    CTFPlayer client = ToTFPlayer(shared.m_pOuter);
    TFCond condition = parameters.Get(1);
    float duration = parameters.Get(2);
    */
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