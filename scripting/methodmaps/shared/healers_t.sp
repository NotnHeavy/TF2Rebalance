//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// HEALERS_T DATA                                                           //
//////////////////////////////////////////////////////////////////////////////

enum healers_tOffsets (+= 0x04)
{
    pHealer = 0,
    flAmount,
    flHealAccum,
    flOverhealBonus,
    flOverhealDecayMult,
    bDispenserHeal,
    pHealScorer,
    iKillsWhileBeingHealed,
    flHealedLastSecond,

    healers_tSize
}

//////////////////////////////////////////////////////////////////////////////
// WEAPONDATA_T METHODMAP                                                   //
//////////////////////////////////////////////////////////////////////////////

methodmap Healers_t
{
    // Constructor.
    public Healers_t(Address address)
    {
        return view_as<Healers_t>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // WeaponData_t members.
    property CBaseEntity m_pHealer
    {
        public get() { return view_as<CBaseEntity>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(pHealer))); }
        public set(CBaseEntity entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(pHealer), entity.Index); }
    }
    property float m_flAmount
    {
        public get() { return Dereference(this.Address + view_as<Address>(flAmount)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flAmount), value); }
    }
    property float m_flHealAccum
    {
        public get() { return Dereference(this.Address + view_as<Address>(flHealAccum)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flHealAccum), value); }
    }
    property float m_flOverhealBonus
    {
        public get() { return Dereference(this.Address + view_as<Address>(flOverhealBonus)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flOverhealBonus), value); }
    }
    property float m_flOverhealDecayMult
    {
        public get() { return Dereference(this.Address + view_as<Address>(flOverhealDecayMult)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flOverhealDecayMult), value); }
    }
    property bool m_bDispenserHeal
    {
        public get() { return Dereference(this.Address + view_as<Address>(bDispenserHeal), NumberType_Int8); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bDispenserHeal), value, NumberType_Int8); }
    }
    property CBaseEntity m_pHealScorer
    {
        public get() { return view_as<CBaseEntity>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(pHealScorer))); }
        public set(CBaseEntity entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(pHealScorer), entity.Index); }
    }
    property int m_iKillsWhileBeingHealed
    {
        public get() { return Dereference(this.Address + view_as<Address>(iKillsWhileBeingHealed)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iKillsWhileBeingHealed), value); }
    }
    property float m_flHealedLastSecond
    {
        public get() { return Dereference(this.Address + view_as<Address>(flHealedLastSecond)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flHealedLastSecond), value); }
    }
}