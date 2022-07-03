//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFPLAYERSHARED DATA                                                     //
//////////////////////////////////////////////////////////////////////////////

enum ctfplayersharedOffsets
{
    ConditionData = 8,
    pOuter = 400,
    aHealers = 404,
    flBurnDuration = 520
}

//////////////////////////////////////////////////////////////////////////////
// CTFPLAYERSHARED METHODMAP                                                //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFPlayerShared
{
    // Constructor.
    public CTFPlayerShared(Address address)
    {
        return view_as<CTFPlayerShared>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // CTFPlayerShared members.
    property CUtlVector m_ConditionData
    {
        public get() { return view_as<CUtlVector>(this.Address + view_as<Address>(ConditionData)); }
    }
    property CBaseEntity m_pOuter // TODO when methodmap declarations come out: return as CTFPlayer instead.
    {
        public get() { return CBaseEntity.Dereference(this.Address + view_as<Address>(pOuter)); }
    }
    property CUtlVector m_aHealers
    {
        public get() { return view_as<CUtlVector>(this.Address + view_as<Address>(aHealers)); }
    }
    property float m_flBurnDuration
    {
        public get() { return Dereference(this.Address + view_as<Address>(flBurnDuration)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flBurnDuration), value); }
    }

    // CTFPlayerShared methods.
    public void AddCond(TFCond condition, float duration = TFCondDuration_Infinite, CBaseEntity inflictor = INVALID_ENTITY)
    {
        TF2_AddCondition(this.m_pOuter.Index, condition, duration, inflictor != INVALID_ENTITY ? inflictor.Index : -1);
    }
    public void RemoveCond(TFCond condition)
    {
        TF2_RemoveCondition(this.m_pOuter.Index, condition);
    }
    public bool InCond(TFCond condition)
    {
        return TF2_IsPlayerInCondition(this.m_pOuter.Index, condition);
    }
    public void StunPlayer(float time, float reduction, int flags, CBaseEntity attacker) // Use ctfplayer when methodmap declarations is a thing.
    {
        TF2_StunPlayer(this.m_pOuter.Index, time, reduction, flags, attacker != INVALID_ENTITY ? attacker.Index : 0);
    }
    public void Burn(CBaseEntity attacker, CTFWeaponBase weapon, float burningTime) // use ctfplayer when method declarations is a thing.
    {
        SDKCall(SDKCall_CTFPlayerShared_Burn, this.Address, attacker.Index, weapon.Index, burningTime);
    }
    public int GetNumHealers()
    {
        return this.m_pOuter.GetMember(Prop_Send, "m_nNumHealers");
    }
}