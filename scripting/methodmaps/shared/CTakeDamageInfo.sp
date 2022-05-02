//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

#define FLT_MAX view_as<float>(0x7f7fffff)
#define BASEDAMAGE_NOT_SPECIFIED FLT_MAX

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

    eCritType = 100,

    ctakedamageinfoSize = 104
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

methodmap CTakeDamageInfo < MemoryBlock
{
    public static CTakeDamageInfo FromAddress(Address block)
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
        public get() { return Vector.Dereference(this.Address + view_as<Address>(vecDamageForce)); }
        public set(Vector vector) { vector.WriteToMemory(this.Address + view_as<Address>(vecDamageForce)); }
    }
    property Vector m_vecDamagePosition
    {
        public get() { return Vector.Dereference(this.Address + view_as<Address>(vecDamagePosition)); }
        public set(Vector vector) { vector.WriteToMemory(this.Address + view_as<Address>(vecDamagePosition)); }
    }
    property Vector m_vecReportedPosition
    {
        public get() { return Vector.Dereference(this.Address + view_as<Address>(vecDamageForce)); }
        public set(Vector vector) { vector.WriteToMemory(this.Address + view_as<Address>(vecDamageForce)); }
    }
    property CBaseEntity m_hInflictor
    {
        public get() { return view_as<CBaseEntity>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hInflictor))); }
        public set(CBaseEntity entity) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hInflictor), entity.Index); }
    }
    property CBaseEntity m_hAttacker
    {
        public get() { return view_as<CTFPlayer>(LoadEntityHandleFromAddress(this.Address + view_as<Address>(hAttacker))); }
        public set(CBaseEntity player) { StoreEntityHandleToAddress(this.Address + view_as<Address>(hAttacker), player.Index); }
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
        public get() { return Dereference(this.Address + view_as<Address>(bForceFriendlyFire), NumberType_Int8); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bForceFriendlyFire), value, NumberType_Int8); }
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

    // Constructor.
    public CTakeDamageInfo(CBaseEntity inflictor, CBaseEntity attacker, CBaseEntity weapon, const Vector damageForce, const Vector damagePosition, float damage, int damageType, int killType, Vector reportedPosition)
    {
        MemoryBlock data = new MemoryBlock(ctakedamageinfoSize);
        CTakeDamageInfo wrapper = CTakeDamageInfo.FromAddress(data.Address);

        wrapper.m_hInflictor = inflictor;
        if (attacker.Exists)
            wrapper.m_hAttacker = attacker;
        else
            wrapper.m_hAttacker = inflictor;
        
        wrapper.m_hWeapon = view_as<CTFWeaponBase>(weapon);

        wrapper.m_flDamage = damage;
        
        wrapper.m_flBaseDamage = BASEDAMAGE_NOT_SPECIFIED;

        wrapper.m_bitsDamageType = damageType;
        wrapper.m_iDamageCustom = killType;

        wrapper.m_flMaxDamage = damage;
        wrapper.m_vecDamageForce = damageForce;
        wrapper.m_vecDamagePosition = damagePosition;
        wrapper.m_vecReportedPosition = reportedPosition;
        wrapper.m_iAmmoType = -1;
        wrapper.m_iDamagedOtherPlayers = 0;
        wrapper.m_iPlayerPenetrationCount = 0;
        wrapper.m_flDamageBonus = 0.00;
        wrapper.m_bForceFriendlyFire = false;
        wrapper.m_flDamageForForce = 0.00;
        wrapper.m_eCritType = CRIT_NONE;

        return view_as<CTakeDamageInfo>(data);
    }

    // Copy constructor.
    public CTakeDamageInfo Copy()
    {
        MemoryBlock data = new MemoryBlock(ctakedamageinfoSize);
        for (int offset = 0; offset < view_as<int>(ctakedamageinfoSize); offset += 4)
            data.StoreToOffset(offset, Dereference(this.Address + view_as<Address>(offset)), NumberType_Int32);
        return view_as<CTakeDamageInfo>(data);
    }
}