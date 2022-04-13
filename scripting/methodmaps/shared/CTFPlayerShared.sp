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
    pOuter = 400,
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
    property CBaseEntity m_pOuter // TODO when methodmap declarations come out: return as CTFPlayer instead.
    {
        public get() { return GetCBaseEntityFromAddress(this.Address + view_as<Address>(pOuter)); }
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
}