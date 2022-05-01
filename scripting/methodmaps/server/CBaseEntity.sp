//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

#define MAX_ENTITY_COUNT 2048
#define INVALID_ENTITY view_as<CBaseEntity>(-1)
#define ENTITY_NULL view_as<CBaseEntity>(0)

//////////////////////////////////////////////////////////////////////////////
// CBASEENTITY DATA                                                         //
//////////////////////////////////////////////////////////////////////////////

enum struct cbaseentityData
{
//////////////////////////////////////////////////////////////////////////////
// PUBLIC                                                                   //
//////////////////////////////////////////////////////////////////////////////

    CBaseEntity owner;
    Vector spawnPosition;
    char class[MAX_NAME_LENGTH];
    float timestamp;
    float rechargeTime;
    float lastHolsterTime;
    
    // Panic Attack.
    float spreadMultiplier;
    float lastShot;
}
static cbaseentityData cbaseentities[MAX_ENTITY_COUNT];

//////////////////////////////////////////////////////////////////////////////
// CBASEENTITY METHODMAP                                                    //
//////////////////////////////////////////////////////////////////////////////

methodmap CBaseEntity
{
    property int Index
    {
        public get() { return view_as<int>(this); }
    }

    // SetEntProp/GetEntProp/HasEntProp wrappers.
    public bool HasMember(PropType type, char[] buffer)
    {
        return HasEntProp(this.Index, type, buffer);
    }
    public int GetMember(PropType type, char[] buffer, int size = 4, int offset = 0)
    {
        return GetEntProp(this.Index, type, buffer, size, offset);
    }
    public float GetMemberFloat(PropType type, char[] buffer, int offset = 0)
    {
        return GetEntPropFloat(this.Index, type, buffer, offset);
    }
    public CBaseEntity GetMemberEntity(PropType type, char[] buffer, int offset = 0)
    {
        return view_as<CBaseEntity>(GetEntPropEnt(this.Index, type, buffer, offset));
    }
    public Vector GetMemberVector(PropType type, char[] buffer, int offset = 0, bool global = false)
    {
        float vector[3];
        GetEntPropVector(this.Index, type, buffer, vector, offset);
        return Vector(vector[0], vector[1], vector[2], global);
    }
    public void SetMember(PropType type, char[] buffer, int value, int size = 4, int offset = 0)
    {
        SetEntProp(this.Index, type, buffer, value, size, offset);
    }
    public void SetMemberFloat(PropType type, char[] buffer, float value, int offset = 0)
    {
        SetEntPropFloat(this.Index, type, buffer, value, offset);
    }
    public void SetMemberVector(PropType type, char[] buffer, Vector value, int offset = 0)
    {
        float vector[3];
        value.GetBuffer(vector);
        SetEntPropVector(this.Index, type, buffer, vector, offset);
    }

    // Public properties.
    property CBaseEntity Owner // TODO when methodmap declarations come out: return as CTFPlayer instead.
    {
        public get()
        {
            if (cbaseentities[this].owner) // Stored owner from the weapon structurising list.
                return cbaseentities[this].owner;
            if (this.HasMember(Prop_Send, "m_hOwnerEntity")) // Grab from m_hOwnerEntity. In most case scenarios this will be the value returned.
            {
                CBaseEntity player = this.GetMemberEntity(Prop_Send, "m_hOwnerEntity");
                if (player != INVALID_ENTITY)
                    return player;
            }
            if (this.HasMember(Prop_Send, "m_iAccountID")) // m_hOwnerEntity did not have any value... fall back to m_iAccountID to see if we get a chance. Usually used with weapon drops.
            {
                int owner = this.GetMember(Prop_Send, "m_iAccountID");
                for (int i = 1; i <= MaxClients; ++i)
                {
                    if (IsClientInGame(i) && GetSteamAccountID(i) == owner)
                        return view_as<CBaseEntity>(i);
                }
            }
            return INVALID_ENTITY;
        }
        public set(CBaseEntity entity) { cbaseentities[this].owner = entity; }
    }
    property Vector SpawnPosition
    {
        public get() { return cbaseentities[this].spawnPosition; }
        public set(Vector value) { cbaseentities[this].spawnPosition = value; }
    }
    property float Timestamp
    {
        public get() { return cbaseentities[this].timestamp; }
    }
    property float RechargeTime
    {
        public get() { return cbaseentities[this].rechargeTime; }
        public set(float value) { cbaseentities[this].rechargeTime = value; }
    }
    property float LastHolsterTime
    {
        public get() { return cbaseentities[this].lastHolsterTime; }
        public set(float value) { cbaseentities[this].lastHolsterTime = value; }
    }
    property float SpreadMultiplier
    {
        public get() { return cbaseentities[this].spreadMultiplier; }
        public set(float value) { cbaseentities[this].spreadMultiplier = clamp(value, 1.00, 1.50); }
    }
    property float LastShot
    {
        public get() { return cbaseentities[this].lastShot; }
        public set(float value) { cbaseentities[this].lastShot = value; }
    }

    // Property wrappers.
    property bool Exists
    {
        public get() { return IsValidEntity(this.Index); }
    }
    property Address Address
    {
        public get()
        {
            if (this.Exists)
                return GetEntityAddress(this.Index);
            return Address_Null;
        }
    }

    // Public methods.
    // Returns -1 on failure, character index representing starting point of substring on success.
    public int ClassContains(char[] other)
    {
        return StrContains(cbaseentities[this].class, other);
    }
    public bool ClassEquals(char[] other)
    {
        return StrEqual(cbaseentities[this].class, other);
    }
    public Vector GetAbsOrigin(bool center = true, bool global = true)
    {
        Vector absOrigin = this.GetMemberVector(Prop_Data, "m_vecAbsOrigin", .global = global);
        if (center && this.HasMember(Prop_Send, "m_vecMins"))
        {
            Vector mins = this.GetMemberVector(Prop_Send, "m_vecMins", .global = true);
            Vector maxs = this.GetMemberVector(Prop_Send, "m_vecMaxs", .global = true);
            absOrigin.Assign(absOrigin + (mins + maxs * 0.5));
        }
        return absOrigin;
    }
    public void SetRenderMode(RenderMode renderMode)
    {
        SetEntityRenderMode(this.Index, renderMode);
    }
    public void Remove()
    {
        RemoveEntity(this.Index);
    }
    public float HealthFraction()
    {
        if (this.GetMember(Prop_Data, "m_iMaxHealth") == 0)
            return 1.0;
        return clamp(float(this.GetMember(Prop_Data, "m_iHealth")) / float(this.GetMember(Prop_Data, "m_iMaxHealth")), 0.00, 1.00);
    }
    public TFTeam GetTeam()
    {
        return view_as<TFTeam>(this.GetMember(Prop_Send, "m_iTeamNum"));
    }
    public int GetFlags()
    {
        return GetEntityFlags(this.Index);
    }
    public int TakeDamage(MemoryBlock info)
    {
        return SDKCall(SDKCall_CBaseEntity_TakeDamage, this.Index, info);
    }

    // CBaseEntity members.
    property bool IsPlayer
    {
        public get() { return this.Index > 0 && this.Index <= MaxClients; }
    }
    property bool IsWearable
    {
        public get() { return this.ClassContains("tf_wearable") != -1; }
    }
    property bool IsBaseCombatWeapon
    {
        public get() { return this.ClassContains("tf_weapon") != -1;}
    }

    // Constructor.
    public CBaseEntity(int index)
    {
        // Set entity data.
        CBaseEntity entity = view_as<CBaseEntity>(index);
        cbaseentities[index].timestamp = GetGameTime();
        cbaseentities[index].rechargeTime = 0.00;
        cbaseentities[index].spawnPosition.Dispose();
        cbaseentities[index].spreadMultiplier = 1.00;
        cbaseentities[index].lastShot = 0.00;
        GetEntityClassname(index, cbaseentities[index].class, MAX_NAME_LENGTH);

        // SDKHooks.
        SDKHook(index, SDKHook_SpawnPost, EntitySpawn);
        SDKHook(index, SDKHook_Touch, EntityTouch);

        // DHooks.
        if (StrEqual(cbaseentities[index].class, "prop_physics_override") || StrEqual(cbaseentities[index].class, "obj_dispenser"))
            DHookEntity(DHooks_CObjectDispenser_DispenseAmmo, false, index, _, DispenseAmmo);
        else if (StrEqual(cbaseentities[index].class, "tf_projectile_jar_gas"))
            DHookEntity(DHooks_CTFProjectile_Jar_Explode, true, index, _, Explode);
        else if (StrContains(cbaseentities[index].class, "tf_projectile_") != -1)
            DHookEntity(DHooks_CBaseEntity_Deflected, false, index, _, Deflected);

        return entity;
    }
}

//////////////////////////////////////////////////////////////////////////////
// PUBLIC METHODS                                                           //
//////////////////////////////////////////////////////////////////////////////

stock CBaseEntity GetCBaseEntityFromAddress(Address address)
{
    return view_as<CBaseEntity>(GetEntityFromAddress(Dereference(address)));
}
stock CBaseEntity GetCBaseEntityHandleFromAddress(Address address)
{
    return view_as<CBaseEntity>(LoadEntityHandleFromAddress(address));
}