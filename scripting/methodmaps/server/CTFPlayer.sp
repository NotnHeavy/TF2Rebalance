//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CBaseMultiplayerPlayer* -> CBasePlayer* -> CBaseCombatCharacter* -> CBaseFlex* -> CBaseAnimatingOverlay* -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

#define MAX_WEAPONS 48

//////////////////////////////////////////////////////////////////////////////
// CTFPLAYER DATA                                                           //
//////////////////////////////////////////////////////////////////////////////

enum struct ctfplayerData
{
//////////////////////////////////////////////////////////////////////////////
// PRIVATE                                                                  //
//////////////////////////////////////////////////////////////////////////////

    CEconEntity weapons[MAX_WEAPONS];
    
//////////////////////////////////////////////////////////////////////////////
// PUBLIC                                                                   //
//////////////////////////////////////////////////////////////////////////////

    // Projectiles.
    CBaseEntity lastProjectileEncountered;

    // Flying Guillotine.
    float cleaverChargeMeter;

    // Sandman.
    float timeUntilSandmanStunEnd;

    // Degreaser.
    bool onFire;
    bool fromDegreaser;

    // Ullapool Caber.
    bool takingMiniCritDamage;
}
static ctfplayerData ctfplayers[MAXPLAYERS + 1];

//////////////////////////////////////////////////////////////////////////////
// CTFPLAYER METHODMAP                                                      //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFPlayer < CBaseEntity
{
    // Constructor.
    public CTFPlayer(int index)
    {
        // Call parent constructor.
        CBaseEntity(index);

        // CTFPlayer code.
        SDKHook(index, SDKHook_WeaponCanSwitchTo, ClientDeployingWeapon);
        SDKHook(index, SDKHook_WeaponEquipPost, ClientEquippedWeapon);

        return view_as<CTFPlayer>(index);
    }
    property int Index
    {
        public get() { return view_as<int>(this); }
    }

    // CTFPlayer members.
    property CTFPlayerShared m_Shared
    {
        public get() { return view_as<CTFPlayerShared>(this.Address + view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"))); }
    }
    public TFClassType GetPlayerClass()
    {
        return TF2_GetPlayerClass(this.Index);
    }

    // Public properties.
    property CBaseEntity LastProjectileEncountered
    {
        public get() { return ctfplayers[this].lastProjectileEncountered; }
        public set(CBaseEntity value) { ctfplayers[this].lastProjectileEncountered = value; }
    }
    property float CleaverChargeMeter
    {
        public get() { return ctfplayers[this].cleaverChargeMeter; }
        public set(float value) { ctfplayers[this].cleaverChargeMeter = value; }
    }
    property float TimeUntilSandmanStunEnd
    {
        public get() { return ctfplayers[this].timeUntilSandmanStunEnd; }
        public set(float value) { ctfplayers[this].timeUntilSandmanStunEnd = value; }
    }
    property bool OnFire
    {
        public get() { return ctfplayers[this].onFire; }
        public set(bool toggle) { ctfplayers[this].onFire = toggle; }
    }
    property bool FromDegreaser
    {
        public get() { return ctfplayers[this].fromDegreaser; }
        public set(bool toggle) { ctfplayers[this].fromDegreaser = toggle; }
    }
    property bool TakingMiniCritDamage
    {
        public get() { return ctfplayers[this].takingMiniCritDamage; }
        public set(bool toggle) { ctfplayers[this].takingMiniCritDamage = toggle; }
    }

    // Property wrappers.
    property bool Alive
    {
        public get() { return IsPlayerAlive(this.Index); }
    }
    property bool InGame
    {
        public get() { return IsClientInGame(this.Index); }
    }
    property bool Stunned
    {
        public get() { return TF2_IsPlayerInCondition(this.Index, TFCond_Dazed) || this.TimeUntilSandmanStunEnd > GetGameTime(); }
    }

    // Methods that should only be used within this class (private).
    public void registerToWeaponList(CEconEntity weapon)
    {
        weapon.Owner = this;
        for (int i = 0; i < MAX_WEAPONS; ++i)
        {
            if (ctfplayers[this].weapons[i] == INVALID_ENTITY)
            {
                ctfplayers[this].weapons[i] = weapon;
                break;
            }
        }
        if (weapon.IsBaseCombatWeapon)
            ToTFWeaponBase(weapon).ApplyNewAttributes();
    }

    // Methods that should only be used within this class and inherited classes (protected).
    // This would've been a part of another methodmap (IHasAttributes) but multiple inheritance is not a feature.
    public void setAttribute(const char[] attribute, float value)
    {
        TF2Attrib_SetByName(view_as<int>(this), attribute, value);
    }

    // Public methods.
    public CTFWeaponBase GetWeaponFromSlot(int slot)
    {
        return view_as<CTFWeaponBase>(GetPlayerWeaponSlot(this.Index, slot));
    }
    public void StructuriseWeaponList()
    {
        // Reset weapon structure.
        for (int i = 0; i < MAX_WEAPONS; ++i)
            ctfplayers[this].weapons[i] = view_as<CTFWeaponBase>(INVALID_ENTITY);

        // Iterate through weapons.
        for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Item2; ++i)
        {
            CTFWeaponBase weapon = this.GetWeaponFromSlot(i);
            if (weapon != INVALID_ENTITY)
                this.registerToWeaponList(weapon);
        }

        // Iterate through wearables.
        for (CBaseEntity entity = view_as<CBaseEntity>(MAXPLAYERS); entity < view_as<CBaseEntity>(MAX_ENTITY_COUNT); ++entity)
        {
            if (entity.Exists)
            {
                if (entity.ClassContains("tf_wearable") != -1 && entity.Owner.Index == this.Index)
                    this.registerToWeaponList(entity);
            }
        }
    }
    // Returns INVALID_ENTITY if invalid.
    public CEconEntity GetWeapon(int itemDefinition)
    {
        if (!this.InGame)
            return view_as<CEconEntity>(INVALID_ENTITY);
        for (int i = 0; i < MAX_WEAPONS; ++i)
        {
            CEconEntity entity = ctfplayers[this].weapons[i];
            if (entity.Exists && entity.ItemDefinitionIndex == itemDefinition)
                return entity;
        }
        return view_as<CEconEntity>(INVALID_ENTITY);
    }
    // Returns INVALID_ENTITY if invalid.
    public CEconEntity GetWeaponFromList(int[] itemDefinitions, int length)
    {
        for (int i = 0; i < length; ++i)
        {
            CEconEntity entity = this.GetWeapon(itemDefinitions[i]);
            if (entity != INVALID_ENTITY)
                return entity;
        }
        return view_as<CEconEntity>(INVALID_ENTITY);
    }
    public void Heal(int add, bool capOnEvent = false)
    {
        // Show that player got healed.
        int currentHealth = GetClientHealth(this.Index);
        int maxHealth = GetEntProp(this.Index, Prop_Data, "m_iMaxHealth");
        int added = capOnEvent ? maxHealth - currentHealth : add;
        if (added > 0)
        {
            Handle event = CreateEvent("player_healonhit", true);
            SetEventInt(event, "amount", added);
            SetEventInt(event, "entindex", this.Index);
            FireEvent(event);
        }

        // Set health.
        SetEntityHealth(this.Index, intMin(maxHealth, currentHealth + add));
    }
    public float CalculateRadiusDamage(Vector damagePosition, float radius, float damage, float rampup, float falloff, bool center = true)
    {
        // Calculate length.
        Vector absOrigin = this.GetAbsOrigin(center);
        float length = (absOrigin - damagePosition).Length();
        absOrigin.Dispose();

        // Calculate the damage.
        return RemapValClamped(length, 0.00, radius, damage * rampup, damage * falloff);
    }
}

//////////////////////////////////////////////////////////////////////////////
// PUBLIC METHODS                                                           //
//////////////////////////////////////////////////////////////////////////////

stock CTFPlayer GetCTFPlayerFromAddress(Address address)
{
    return view_as<CTFPlayer>(GetEntityFromAddress(address));
}

stock CTFPlayer ToTFPlayer(CBaseEntity entity)
{
    if (!entity.Exists || !entity.IsPlayer)
        return view_as<CTFPlayer>(INVALID_ENTITY); // why does this need to be casted
    return view_as<CTFPlayer>(entity);
}