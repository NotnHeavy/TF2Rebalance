//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CONDITION_SOURCE_T DATA                                                  //
//////////////////////////////////////////////////////////////////////////////

enum condition_source_tOffsets (+= 0x04)
{
    nPreventedDamageFromCondition = 4,
    flExpireTime,
    pProvider,
    bPrevActive,
    
    condition_source_tSize
}

//////////////////////////////////////////////////////////////////////////////
// CONDITION_SOURCE_T METHODMAP                                             //
//////////////////////////////////////////////////////////////////////////////

methodmap Condition_Source_t
{
    // Constructor.
    public Condition_Source_t(Address address)
    {
        return view_as<Condition_Source_t>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // WeaponData_t members.
    property int m_nPreventedDamageFromCondition
    {
        public get() { return Dereference(this.Address + view_as<Address>(nPreventedDamageFromCondition)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(nPreventedDamageFromCondition), value); }
    }
    property float m_flExpireTime
    {
        public get() { return Dereference(this.Address + view_as<Address>(flExpireTime)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flExpireTime), value); }
    }
    property CBaseEntity m_pProvider
    {
        public get() { return view_as<CBaseEntity>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(pProvider))); }
        public set(CBaseEntity entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(pProvider), entity.Index); }
    }
    property bool m_bPrevActive
    {
        public get() { return Dereference(this.Address + view_as<Address>(bPrevActive), NumberType_Int8); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bPrevActive), value, NumberType_Int8); }
    }
}