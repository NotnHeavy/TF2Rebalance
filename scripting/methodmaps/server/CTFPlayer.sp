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

    // Projectiles.
    CBaseEntity lastProjectileEncountered;

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

    // Public properties.
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
        if (this == INVALID_ENTITY)
            return;
        for (int i = 0; i < MAX_WEAPONS; ++i)
            ctfplayers[this].weapons[i] = view_as<CTFWeaponBase>(INVALID_ENTITY);

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
            if (entity == view_as<CEconEntity>(0))
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
            if (entity == view_as<CEconEntity>(0))
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
                    do
                    {
                        char key[256];
                        char value[256];
                        pair.GetSectionName(key, sizeof(key));
                        pair.GetString(NULL_STRING, value, sizeof(value));
                        
                        if (StrEqual(key, "name"))
                            menu.SetTitle(value);
                        else
                            menu.DrawText(value);
                    } while (pair.GotoNextKey(false));
                    pair.GoBack();
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
        Panel menu = new Panel();
        menu.SetTitle("Welcome to NotnHeavy's TF2Rebalance server!");
        menu.DrawText("Use !loadout (/loadout for silenced command) to check your loadout!");
        menu.DrawText("I am still working on rebalances though!");
        menu.DrawItem("Exit", ITEMDRAW_CONTROL);
        menu.Send(this.Index, ShowWelcomeMenuAction, 15);
        delete menu;
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