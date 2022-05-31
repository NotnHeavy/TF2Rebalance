//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CBaseMultiplayerPlayer* -> CBasePlayer* -> CBaseCombatCharacter* -> CBaseFlex* -> CBaseAnimatingOverlay* -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

#define MAX_WEAPONS 48
#define CLASSES 9

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
    int savedID;

//////////////////////////////////////////////////////////////////////////////
// PUBLIC                                                                   //
//////////////////////////////////////////////////////////////////////////////

    int equipMenuSlotChosen;

    float timeSinceSwitchFromNoAmmoWeapon;
    CTFWeaponBase lastWeaponWithSlowHolster;

    // Projectiles.
    CBaseEntity lastProjectileEncountered;
    float timeSinceLastProjectileEncounter;

    // Sandman.
    float timeUntilSandmanStunEnd;

    // Flamethrowers.
    float flameDensity;
    float timeSinceHitByFlames;

    // Degreaser.
    bool onFire;
    bool fromDegreaser;

    // Manmelter.
    CBaseEntity originalBurner;
    int revengeCrits;

    // Gas Passer.
    bool fromGasPasser;

    // Sharpened Volcano Fragment.
    float timeSinceStoppedBurning;
    CTFWeaponBase fromSVF;

    // Third Degreee.
    Pointer connectedInfo;
    int recursiveCheck;

    // Ullapool Caber.
    bool takingMiniCritDamage;

    // Warrior's Spirit.
    float timeUntilNoPounceCrits;
}
static ctfplayerData ctfplayers[MAXPLAYERS + 1];
static CustomWeapon customWeapons[MAXPLAYERS + 1][CLASSES + 1][3]; // sourcemod let me put this inside enum structs dfsjjidfssdfsgfmsifksfd

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
        SDKHook(index, SDKHook_OnTakeDamage, ClientOnTakeDamage);
        ctfplayers[index].shownWelcomeMenu = false;

        for (int i = 0; i < sizeof(customWeapons[]); ++i)
        {
            for (int v = 0; v < sizeof(customWeapons[][]); ++v)
                customWeapons[index][i][v] = NULL_CUSTOM_WEAPON;
        }

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
    property CUtlVector m_hMyWearables
    {
        public get() { return view_as<CUtlVector>(this.Address + CTFPlayer_m_hMyWearables); }
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
    public int GetAmmoCount(int ammoIndex = 1)
    {
        return this.GetMember(Prop_Send, "m_iAmmo", _, ammoIndex);
    }
    public void SetAmmoCount(int count, int ammoIndex = 1)
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
    public void EquipWearable(CBaseEntity wearable)
    {
        SDKCall(SDKCall_CTFPlayer_EquipWearable, this, wearable);
    }

    // Public properties.
    property int EquipMenuSlotChosen
    {
        public get() { return ctfplayers[this].equipMenuSlotChosen; }
        public set(int value) { ctfplayers[this].equipMenuSlotChosen = value; }
    }
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
    property float TimeSinceLastProjectileEncounter
    {
        public get() { return ctfplayers[this].timeSinceLastProjectileEncounter; }
        public set(float value) { ctfplayers[this].timeSinceLastProjectileEncounter = value; }
    }
    property float TimeUntilSandmanStunEnd
    {
        public get() { return ctfplayers[this].timeUntilSandmanStunEnd; }
        public set(float value) { ctfplayers[this].timeUntilSandmanStunEnd = value; }
    }
    property float FlameDensity
    {
        public get() { return ctfplayers[this].flameDensity; }
        public set(float value) { ctfplayers[this].flameDensity = clamp(value, 0.50, 1.00); }
    }
    property float TimeSinceHitByFlames
    {
        public get() { return ctfplayers[this].timeSinceHitByFlames; }
        public set(float value) { ctfplayers[this].timeSinceHitByFlames = value; }
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
    property float TimeSinceStoppedBurning
    {
        public get() { return ctfplayers[this].timeSinceStoppedBurning; }
        public set(float value) { ctfplayers[this].timeSinceStoppedBurning = value; }
    }
    property CTFWeaponBase FromSVF
    {
        public get() { return ctfplayers[this].fromSVF; }
        public set(CTFWeaponBase value) { ctfplayers[this].fromSVF = value; }
    }
    property bool FromGasPasser
    {
        public get() { return ctfplayers[this].fromGasPasser; }
        public set(bool toggle) { ctfplayers[this].fromGasPasser = toggle; }
    }
    property Pointer ConnectedInfo
    {
        public get() { return ctfplayers[this].connectedInfo; }
        public set(Pointer value) { ctfplayers[this].connectedInfo = value; }
    }
    property int RecursiveCheck
    {
        public get() { return ctfplayers[this].recursiveCheck; }
        public set(int toggle) { ctfplayers[this].recursiveCheck = toggle; }
    }
    property bool TakingMiniCritDamage
    {
        public get() { return ctfplayers[this].takingMiniCritDamage; }
        public set(bool toggle) { ctfplayers[this].takingMiniCritDamage = toggle; }
    }
    property float TimeUntilNoPounceCrits
    {
        public get() { return ctfplayers[this].timeUntilNoPounceCrits; }
        public set(float value) { ctfplayers[this].timeUntilNoPounceCrits = value; }
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
    public int GetSteamAccountID()
    {
        return GetSteamAccountID(this.Index);
    }
    public void AddCustomAttribute(const char[] attribute, float value, float duration = -1.0)
    {
        TF2Attrib_AddCustomPlayerAttribute(this.Index, attribute, value, duration);
    }
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

        // Iterate through wearables. [ Will be removed soon. This code does not work due to m_hOwnerEntity not always being set on time. ]
        /*
        for (CTFWearable entity = view_as<CTFWearable>(MAXPLAYERS); entity < view_as<CTFWearable>(MAX_ENTITY_COUNT); ++entity)
        {
            if (entity.Exists && entity.IsWearable && entity.Owner == this)
            {
                this.registerToWeaponList(entity);
                entity.ApplyNewAttributes();
            }
        }
        */
        // Iterate through wearables.
        for (int i = 0, v = this.m_hMyWearables.Count(); i < v; ++i)
        {
            CTFWearable entity = view_as<CTFWearable>(CBaseEntity.GetFromHandle(this.m_hMyWearables.Get(i)));
            if (entity.Exists)
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
    public void GetAllWeapons(CEconEntity weapons[MAX_WEAPONS])
    {
        MemCopy(AddressOfArray(weapons), AddressOfArray(ctfplayers[this].weapons), sizeof(weapons));
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
        return RemapValClamped(this.GetAbsOrigin(center).DistTo(damagePosition), 0.00, radius, damage * rampup, damage * falloff);
    }
    public void ResetLoadoutLastEntry()
    {
        ctfplayers[this].lastLoadoutEntry = "";
        ctfplayers[this].savedID = 0;
    }
    public int CreateLoadoutPanel()
    {
        // Load the file with the keyvalues methodmap.
        KeyValues pair = new KeyValues("WeaponChanges");
        pair.ImportFromFile(configList);
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
        char override[256] = "\0";
        do
        {
            pair.GetSectionName(buffer, sizeof(buffer));
            int index = StringToInt(buffer);
            CEconEntity foundWeapon = index != 0 ? this.GetWeapon(index) : view_as<CEconEntity>(INVALID_ENTITY); 
            if (foundWeapon == INVALID_ENTITY)
                foundWeapon = this.GetWeaponFromClassname(buffer);
            if (foundWeapon == INVALID_ENTITY) // The weapon title might contain multiple weapon indexes.
            {
                char indexes[10][256];
                ExplodeString(buffer, " ", indexes, sizeof(indexes), sizeof(indexes[]), true);
                for (int i = 0; i < sizeof(indexes); ++i)
                {
                    int splitIndex = StringToInt(indexes[i]);
                    foundWeapon = splitIndex != 0 ? this.GetWeapon(splitIndex) : view_as<CEconEntity>(INVALID_ENTITY);
                    if (foundWeapon != INVALID_ENTITY)
                    {
                        index = splitIndex;
                        break;
                    }
                }
            }
            if (foundWeapon != INVALID_ENTITY)
            {
                if (foundWeapon.ClassEquals(override))
                {
                    found = false;
                    override = "\0";
                }
                if (found)
                {
                    strcopy(ctfplayers[this].lastLoadoutEntry, 256, buffer);
                    foundNext = true;
                    break;
                }
                if (pair.GotoFirstSubKey(false))
                {
                    int count = 0;
                    do
                    {
                        if (count < ctfplayers[this].savedID)
                        {
                            ++count;
                            continue;
                        }
                        ctfplayers[this].savedID = 0;
                        char key[256];
                        char value[256];
                        pair.GetSectionName(key, sizeof(key));
                        pair.GetString(NULL_STRING, value, sizeof(value));

                        if (menu.TextRemaining - strlen(value) < 0)
                        {
                            foundNext = true;
                            ctfplayers[this].savedID = count;
                            strcopy(ctfplayers[this].lastLoadoutEntry, 256, buffer);
                            break;
                        }
                        
                        if (StrEqual(key, "override") && StrEqual(value, "true"))
                            strcopy(override, sizeof(override), buffer);
                        else if (StrEqual(key, "name") || (StringToInt(key) == index && StringToInt(key) != 0))
                            menu.SetTitle(value);
                        else if (StrEqual(key, "macro"))
                        {
                            for (int i = 0; i < sizeof(configMacros); ++i)
                            {
                                if (StrEqual(value, configMacros[i][0]))
                                {
                                    menu.DrawText(configMacros[i][1]);
                                    break;
                                }
                            }
                        }
                        else if (StrEqual(key, "change"))
                            menu.DrawText(value);
                        
                        ++count;
                    } while (pair.GotoNextKey(false));
                    pair.GoBack();
                    found = true;
                    if (foundNext)
                        break;
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
        menu.DrawText("Use !loadout (/loadout for silenced command) to check your loadout.");
        menu.DrawText("Use !equip (/equip for silenced comamnd) to equip custom weapons.");
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

        if (this.GetPlayerClass() == TFClass_Heavy)
            this.setAttribute("boots falling stomp", 1.00);
        else
            this.setAttribute("boots falling stomp", 0.00);

        this.TimeSinceSwitchFromNoAmmoWeapon = 0.00;
    }
    public void RemoveWeaponSlot(int slot)
    {
        if (this.GetWeaponFromSlot(slot) != INVALID_ENTITY)
            TF2_RemoveWeaponSlot(this.Index, slot);
        else
        {
            CEconEntity weapons[MAX_WEAPONS];
            this.GetAllWeapons(weapons);
            for (int i = 0; i < sizeof(weapons); ++i)
            {
                CTFWearable wearable = view_as<CTFWearable>(weapons[i]);
                if (wearable != INVALID_ENTITY && wearable.IsWearable && wearable.GetDefaultItemSlot() == slot)
                {
                    TF2_RemoveWearable(this.Index, wearable.Index);
                    break;
                }
            }
        }
    }
    public void EquipWeapon(CEconEntity weapon)
    {
        if (weapon.IsWearable)
            this.EquipWearable(weapon);
        else if (weapon.IsBaseCombatWeapon)
        {
            CTFWeaponBase tfweapon = ToTFWeaponBase(weapon);
            EquipPlayerWeapon(this.Index, tfweapon.Index);
            int ammoType = tfweapon.GetMember(Prop_Send, "m_iPrimaryAmmoType");
            if (ammoType != -1)
                this.SetAmmoCount(tfweapon.GetMaxClip1(), tfweapon.GetMember(Prop_Send, "m_iPrimaryAmmoType"));
        }
    }
    public void AllocateNewWeapon(char name[256], int index)
    {
        // Create weapon.
        TF2_TranslateWeaponEntForClass(this.Class, name, sizeof(name));
        CEconEntity weapon = CBaseEntity.Create(name);
        weapon.SetMember(Prop_Send, "m_iItemDefinitionIndex", index);
        weapon.SetMember(Prop_Send, "m_bInitialized", 1);
        weapon.Dispatch();

        // Set owner.
        weapon.SetMember(Prop_Send, "m_iAccountID", this.GetSteamAccountID());
        weapon.SetMemberEntity(Prop_Send, "m_hOwnerEntity", this);

        // Equip weapon.
        this.RemoveWeaponSlot(weapon.GetDefaultItemSlot());
        this.EquipWeapon(weapon);
    }
    public void ApplyCustomWeapons()
    {
        for (int i = 0; i < sizeof(customWeapons[]); ++i)
        {
            for (int v = 0; v < sizeof(customWeapons[][]); ++v)
            {
                if (i == view_as<int>(this.Class) && customWeapons[this][i][v] != NULL_CUSTOM_WEAPON)
                {
                    char objectName[256];
                    customWeapons[this][i][v].GetObject(objectName);
                    this.AllocateNewWeapon(objectName, customWeapons[this][i][v].ItemDefinitionIndex);
                }
            }
        }
    }
    /*
    // This gives the player the Gunboats.
    public void temp()
    {
        customWeapons[this][view_as<int>(TFClass_DemoMan)][1] = view_as<CustomWeapon>(1);
    }
    */
    public void CreateEquipMenu()
    {
        Menu menu = new Menu(ShowEquipMenuAction);
        menu.OptionFlags = MENUFLAG_NO_SOUND;
        menu.ExitButton = true;
        if (this.EquipMenuSlotChosen == -1)
        {
            menu.SetTitle("Choose the loadout slot:");
            menu.AddItem("Primary", "Primary");
            menu.AddItem("Secondary", "Secondary");
            menu.AddItem("Melee", "Melee");
            
        }
        else
        {
            menu.Pagination = true;
            menu.SetTitle("Choose your weapon:");
            menu.AddItem("0", "Default");
            for (CustomWeapon definition = view_as<CustomWeapon>(1); definition != CustomWeapon.Length(); ++definition)
            {
                if (definition.Slot == this.EquipMenuSlotChosen && definition.AllowedOnClass(this.Class) /*definition.Class == this.Class*/)
                {
                    char name[256];
                    char index[256];
                    definition.GetName(name);
                    IntToString(definition.Index, index, sizeof(index));
                    if (customWeapons[this][view_as<int>(this.Class)][definition.Slot] == definition)
                        Format(name, sizeof(name), "(Equipped) %s", name);
                    menu.AddItem(index, name);
                }
            }
        }
        menu.Display(this.Index, MENU_TIME_FOREVER);
    }
    public void SetCustomWeapon(int slot, CustomWeapon definition)
    {
        customWeapons[this][view_as<int>(this.Class)][slot] = definition;
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