//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTAKEDAMAGEINFO DATA                                                     //
//////////////////////////////////////////////////////////////////////////////

enum ctakedamageinfoOffsets
{
    vecDamageForce = 0,
    vecDamagePosition = 12,
    vecReportedPosition = 24,  // Position players are told damage is coming from
    hInflictor = 36,
    hAttacker = 40,
    hWeapon = 44,
    flDamage = 48,
    flMaxDamage = 52,
    flBaseDamage = 56,         // The damage amount before skill leve adjustments are made. Used to get uniform damage forces.
    bitsDamageType = 60,
    iDamageCustom = 64,
    iDamageStats = 68,
    iAmmoType = 72,            // AmmoType of the weapon used to cause this damage, if any
    iDamagedOtherPlayers = 76,
    iPlayerPenetrationCount = 80,
    flDamageBonus = 84,        // Anything that increases damage (crit) - store the delta
    hDamageBonusProvider = 88, // Who gave us the ability to do extra damage?
    bForceFriendlyFire = 92,   // Ideally this would be a dmg type, but we can't add more

    flDamageForForce = 96,

    eCritType = 100
}

enum ECritType
{
    CRIT_NONE = 0,
    CRIT_MINI,
    CRIT_FULL,
};

//////////////////////////////////////////////////////////////////////////////
// CTAKEDAMAGEINFO METHODMAP                                                //
//////////////////////////////////////////////////////////////////////////////

methodmap CTakeDamageInfo
{
    // Constructor.
    public CTakeDamageInfo(Address block)
    {
        return view_as<CTakeDamageInfo>(block);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // CTakeDamageInfo members.
    property Vector m_vecDamageForce
    {
        public get() { return GetVectorFromAddress(this.Address + view_as<Address>(vecDamageForce)); }
        public set(Vector vector) { WriteToVector(this.Address + view_as<Address>(vecDamageForce), vector); }
    }
    property Vector m_vecDamagePosition
    {
        public get() { return GetVectorFromAddress(this.Address + view_as<Address>(vecDamagePosition)); }
        public set(Vector vector) { WriteToVector(this.Address + view_as<Address>(vecDamagePosition), vector); }
    }
    property Vector m_vecReportedPosition
    {
        public get() { return GetVectorFromAddress(this.Address + view_as<Address>(vecDamageForce)); }
        public set(Vector vector) { WriteToVector(this.Address + view_as<Address>(vecDamageForce), vector); }
    }
    property CBaseEntity m_hInflictor
    {
        public get() { return view_as<CBaseEntity>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hInflictor))); }
        public set(CBaseEntity entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hInflictor), entity.Index); }
    }
    property CTFPlayer m_hAttacker
    {
        public get() { return view_as<CTFPlayer>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hAttacker))); }
        public set(CTFPlayer player) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hAttacker), player.Index); }
    }
    property CTFWeaponBase m_hWeapon
    {
        public get() { return view_as<CTFWeaponBase>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hWeapon))); }
        public set(CTFWeaponBase entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hWeapon), entity.Index); }
    }
    property float m_flDamage
    {
        public get() { return Dereference(this.Address + view_as<Address>(flDamage)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flDamage), value); }
    }
    property float m_flMaxDamage
    {
        public get() { return Dereference(this.Address + view_as<Address>(flMaxDamage)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flMaxDamage), value); }
    }
    property float m_flBaseDamage
    {
        public get() { return Dereference(this.Address + view_as<Address>(flBaseDamage)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flBaseDamage), value); }
    }
    property int m_bitsDamageType
    {
        public get() { return Dereference(this.Address + view_as<Address>(bitsDamageType)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(bitsDamageType), value); }
    }
    property int m_iDamageCustom
    {
        public get() { return Dereference(this.Address + view_as<Address>(iDamageCustom)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iDamageCustom), value); }
    }
    property int m_iDamageStats
    {
        public get() { return Dereference(this.Address + view_as<Address>(iDamageStats)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iDamageStats), value); }
    }
    property int m_iAmmoType
    {
        public get() { return Dereference(this.Address + view_as<Address>(iAmmoType)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iAmmoType), value); }
    }
    property int m_iDamagedOtherPlayers
    {
        public get() { return Dereference(this.Address + view_as<Address>(iDamagedOtherPlayers)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iDamagedOtherPlayers), value); }
    }
    property int m_iPlayerPenetrationCount
    {
        public get() { return Dereference(this.Address + view_as<Address>(iPlayerPenetrationCount)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iPlayerPenetrationCount), value); }
    }
    property float m_flDamageBonus
    {
        public get() { return Dereference(this.Address + view_as<Address>(flDamageBonus)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flDamageBonus), value); }
    }
    property CTFPlayer m_hDamageBonusProvider
    {
        public get() { return view_as<CTFPlayer>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hDamageBonusProvider))); }
        public set(CTFPlayer player) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hDamageBonusProvider), player.Index); }
    }
    property bool m_bForceFriendlyFire
    {
        public get() { return Dereference(this.Address + view_as<Address>(bForceFriendlyFire)); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bForceFriendlyFire), value); }
    }
    
    property float m_flDamageForForce
    {
        public get() { return Dereference(this.Address + view_as<Address>(flDamageForForce)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flDamageForForce), value); }
    }

    property ECritType m_eCritType
    {
        public get() { return Dereference(this.Address + view_as<Address>(eCritType)); }
        public set(ECritType value) { WriteToValue(this.Address + view_as<Address>(eCritType), value); }
    }

    // Functions.
    public void SetCritType(CTFPlayer victim, ECritType type)
    {
        // don't let CRIT_MINI override CRIT_FULL
        if ((this.m_eCritType == CRIT_FULL || this.m_bitsDamageType & DMG_CRIT) && type == CRIT_MINI)
            return;
        this.m_eCritType = type;

        if (type == CRIT_FULL)
            this.m_bitsDamageType |= DMG_CRIT;
        else
            this.m_bitsDamageType &= ~DMG_CRIT;
        
        if (type == CRIT_MINI)
            victim.TakingMiniCritDamage = true;
        else
            victim.TakingMiniCritDamage = false;
    }
}