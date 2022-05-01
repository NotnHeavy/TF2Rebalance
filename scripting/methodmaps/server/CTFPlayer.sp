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
    char lastLoadoutEntry[256];
    bool shownWelcomeMenu;

//////////////////////////////////////////////////////////////////////////////
// PUBLIC                                                                   //
//////////////////////////////////////////////////////////////////////////////

    float timeSinceSwitchFromNoAmmoWeapon;
    CTFWeaponBase lastWeaponWithSlowHolster;

    // Projectiles.
    CBaseEntity lastProjectileEncountered;

    // Sandman.
    float timeUntilSandmanStunEnd;

    // Degreaser.
    bool onFire;
    bool fromDegreaser;

    // Manmelter.
    CBaseEntity originalBurner;
    int revengeCrits;

    // Third Degreee.
    bool recursiveCheck;

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
        SDKHook(index, SDKHook_WeaponEquipPost, ClientEquippedWeapon);
        SDKHook(index, SDKHook_OnTakeDamage, ClientTookFallDamage);
        ctfplayers[index].shownWelcomeMenu = false;

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
    public Vector EyeAngles(bool global = true)
    {
        float buffer[3];
        GetClientEyeAngles(this.Index, buffer);
        return Vector(buffer[0], buffer[1], buffer[2], global);
    }
    public int GetMaxAmmo(int ammoIndex, int classIndex = -1)
    {
        return SDKCall(SDKCall_CTFPlayer_GetMaxAmmo, this.Index, ammoIndex, classIndex);
    }
    public void SetAmmoCount(int count, int ammoIndex)
    {
        this.SetMember(Prop_Send, "m_iAmmo", count, _, ammoIndex);
    }
    public CTFWeaponBase GetActiveWeapon()
    {
        return view_as<CTFWeaponBase>(this.GetMemberEntity(Prop_Send, "m_hActiveWeapon"));
    }
    public int GetUserID()
    {
        return GetClientUserId(this.Index);
    }

    // Public properties.
    property float TimeSinceSwitchFromNoAmmoWeapon
    {
        public get() { return ctfplayers[this].timeSinceSwitchFromNoAmmoWeapon; }
        public set(float value) { ctfplayers[this].timeSinceSwitchFromNoAmmoWeapon = value; }
    }
    property CTFWeaponBase LastWeaponWithSlowHolster
    {
        public get() { return ctfplayers[this].lastWeaponWithSlowHolster; }
        public set(CTFWeaponBase value) { ctfplayers[this].lastWeaponWithSlowHolster = value; }
    }
    property CBaseEntity LastProjectileEncountered
    {
        public get() { return ctfplayers[this].lastProjectileEncountered; }
        public set(CBaseEntity value) { ctfplayers[this].lastProjectileEncountered = value; }
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
    property CBaseEntity OriginalBurner
    {
        public get() { return ctfplayers[this].originalBurner; }
        public set(CBaseEntity value) { ctfplayers[this].originalBurner = value; }
    }
    property int RevengeCrits
    {
        public get() { return ctfplayers[this].revengeCrits; }
        public set(int value) { ctfplayers[this].revengeCrits = value; }
    }
    property bool RecursiveCheck
    {
        public get() { return ctfplayers[this].recursiveCheck; }
        public set(bool toggle) { ctfplayers[this].recursiveCheck = toggle; }
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
        public get() { return this.IsPlayer && IsClientInGame(this.Index); }
    }
    property bool Stunned
    {
        public get() { return TF2_IsPlayerInCondition(this.Index, TFCond_Dazed) || this.TimeUntilSandmanStunEnd > GetGameTime(); }
    }
    property TFClassType Class
    {
        public get() { return TF2_GetPlayerClass(this.Index); }
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
    }

    // Methods that should only be used within this class and inherited classes (protected).
    // This would've been a part of another methodmap (IHasAttributes) but multiple inheritance is not a feature.
    public void setAttribute(const char[] attribute, float value)
    {
        TF2Attrib_SetByName(this.Index, attribute, value);
    }

    // Public methods.
    public CTFWeaponBase GetWeaponFromSlot(int slot)
    {
        return view_as<CTFWeaponBase>(GetPlayerWeaponSlot(this.Index, slot));
    }
    public void StructuriseWeaponList()
    {
        // Reset weapon structure.
        if (this == INVALID_ENTITY)
            return;
        for (int i = 0; i < MAX_WEAPONS; ++i)
            ctfplayers[this].weapons[i] = view_as<CEconEntity>(INVALID_ENTITY);

        // Iterate through weapons.
        for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Item2; ++i)
        {
            CTFWeaponBase weapon = this.GetWeaponFromSlot(i);
            if (weapon != INVALID_ENTITY)
            {
                this.registerToWeaponList(weapon);
                weapon.ApplyNewAttributes();
            }
        }

        // Iterate through wearables.
        for (CTFWearable entity = view_as<CTFWearable>(MAXPLAYERS); entity < view_as<CTFWearable>(MAX_ENTITY_COUNT); ++entity)
        {
            if (entity.Exists && entity.IsWearable && entity.Owner == this)
            {
                this.registerToWeaponList(entity);
                entity.ApplyNewAttributes();
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
            if (entity == INVALID_ENTITY)
                break;
            if (entity.Exists && entity.ItemDefinitionIndex == itemDefinition)
                return entity;
        }
        return view_as<CEconEntity>(INVALID_ENTITY);
    }
    // Returns INVALID_ENTITY if invalid.
    public CEconEntity GetWeaponFromClassname(char[] className)
    {
        if (!this.InGame)
            return view_as<CEconEntity>(INVALID_ENTITY);
        for (int i = 0; i < MAX_WEAPONS; ++i)
        {
            CEconEntity entity = ctfplayers[this].weapons[i];
            if (entity == INVALID_ENTITY)
                break;
            if (entity.Exists && entity.ClassEquals(className))
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
        return RemapValClamped((this.GetAbsOrigin(center) - damagePosition).Length(), 0.00, radius, damage * rampup, damage * falloff);
    }
    public void ResetLoadoutLastEntry()
    {
        ctfplayers[this].lastLoadoutEntry = "";
    }
    public int CreateLoadoutPanel()
    {
        // Create the file name for the weapon changes list.
        static char list[PLATFORM_MAX_PATH];
        if (list[0] == '\0')
            Format(list, PLATFORM_MAX_PATH, "addons/sourcemod/configs/%s - Weapons.txt", PLUGIN_NAME);
        if (!FileExists(list, true))
            ThrowError("%s does not exist in your /tf/ directory!", list);

        // Load the file with the keyvalues methodmap.
        KeyValues pair = new KeyValues("WeaponChanges");
        pair.ImportFromFile(list);
        if (ctfplayers[this].lastLoadoutEntry[0] != '\0')
            pair.JumpToKey(ctfplayers[this].lastLoadoutEntry);
        else if (!pair.GotoFirstSubKey())
        {
            delete pair;
            return 1;
        }

        // Compare the player's loadout with the keyvalues pair.
        Panel menu = new Panel();
        char buffer[256];
        bool found = false;
        bool foundNext = false;
        do
        {
            pair.GetSectionName(buffer, sizeof(buffer));
            int index = StringToInt(buffer);
            if (this.GetWeapon(index) != INVALID_ENTITY || this.GetWeaponFromClassname(buffer) != INVALID_ENTITY)
            {
                if (found)
                {
                    strcopy(ctfplayers[this].lastLoadoutEntry, 256, buffer);
                    foundNext = true;
                    break;
                }
                if (pair.GotoFirstSubKey(false))
                {
                    bool forClass = true;
                    do
                    {
                        char key[256];
                        char value[256];
                        pair.GetSectionName(key, sizeof(key));
                        pair.GetString(NULL_STRING, value, sizeof(value));
                        
                        if (StrEqual(key, "name"))
                            menu.SetTitle(value);
                        else if (StrEqual(key, "class"))
                        {
                            TFClassType class = view_as<TFClassType>(StringToInt(value));
                            if (this.Class != class)
                            {
                                forClass = false;
                                break;
                            }
                        }
                        else
                            menu.DrawText(value);
                    } while (pair.GotoNextKey(false));
                    pair.GoBack();
                    if (forClass)
                        found = true;
                }
            }
        } while (pair.GotoNextKey());

        // Send the menu to the client.
        if (!found)
        {
            delete pair;
            return 1;
        }
        menu.DrawItem("Exit", ITEMDRAW_CONTROL);
        if (foundNext)
            menu.DrawItem("Next", ITEMDRAW_CONTROL);
        menu.Send(this.Index, ShowLoadoutMenuAction, MENU_TIME_FOREVER);
        delete pair;
        delete menu;
        return 0;
    }
    public void ShowWelcomePanel()
    {
        if (ctfplayers[this].shownWelcomeMenu)
            return;
        ctfplayers[this].shownWelcomeMenu = true;
        char buffer[256];

        Panel menu = new Panel();
        menu.SetTitle("Welcome to NotnHeavy's TF2Rebalance server!");
        menu.DrawText("Use !loadout (/loadout for silenced command) to check your loadout!");
        menu.DrawText("I am still working on rebalances though!");
        menu.DrawText(" ");
        
        Format(buffer, sizeof(buffer), "Random crits: %s", tf_weapon_criticals.IntValue ? "on" : "off");
        menu.DrawText(buffer);
        Format(buffer, sizeof(buffer), "Random bullet spread: %s", tf_use_fixed_weaponspreads.IntValue ? "off" : "on");
        menu.DrawText(buffer);
        Format(buffer, sizeof(buffer), "Random fall damage modifier: %s", !initiatedConVars || notnheavy_tf2rebalance_use_fixed_falldamage.IntValue ? "off" : "on");
        menu.DrawText(buffer);

        menu.DrawItem("Exit", ITEMDRAW_CONTROL);
        menu.Send(this.Index, ShowWelcomeMenuAction, 15);

        delete menu;
    }
    public bool IsPlayerBehind(CTFPlayer other, float angle = 0.00)
    {
        Vector toEnt = Vector(.global = true);
        toEnt.Assign(this.GetAbsOrigin() - other.GetAbsOrigin());
        toEnt.Z = 0.00;
        toEnt.NormalizeInPlace();
        
        Vector entForward;
        AngleVectors(this.EyeAngles(), entForward);

        return toEnt.Dot(entForward) > angle;
    }
    public void Regenerate()
    {
        for (int ammo = 0; ammo < view_as<int>(TF_AMMO_COUNT); ++ammo)
            this.SetAmmoCount(this.GetMaxAmmo(ammo), ammo);
        for (int i = 0; i < MAX_WEAPONS; ++i)
        {
            CTFWeaponBase entity = ToTFWeaponBase(ctfplayers[this].weapons[i]);
            if (entity == view_as<CTFWeaponBase>(INVALID_ENTITY))
                break;
            
            // Do not get max clip and start firing straight away with the Beggar's Bazooka.
            int auto_fires_full_clip = 0;
            entity.HookValueInt(auto_fires_full_clip, "auto_fires_full_clip");
            if (auto_fires_full_clip)
                continue;

            entity.SetMember(Prop_Send, "m_iClip1", entity.GetMaxClip1());
        }
        this.TimeSinceSwitchFromNoAmmoWeapon = 0.00;
    }
    
    // These would've been a part of another methodmap (IHasAttributes) but multiple inheritance is not a feature, at least as of SM 1.10.
    public float GetAttribute(const char[] attribute)
    {
        Address address = TF2Attrib_GetByName(this.Index, attribute);
        return address != Address_Null ? TF2Attrib_GetValue(address) : -1.00;
    }
    public void HookValueFloat(float& value, const char[] attribute)
    {
        value = TF2Attrib_HookValueFloat(value, attribute, this.Index);
    }
    public void HookValueInt(int& value, const char[] attribute)
    {
        value = TF2Attrib_HookValueInt(value, attribute, this.Index);
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