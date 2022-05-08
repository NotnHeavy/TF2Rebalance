//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFRADIUSDAMAGEINFO DATA                                                 //
//////////////////////////////////////////////////////////////////////////////

enum ctfradiusdamageinfoOffsets
{
    dmgInfo = 0,
    vecSrc = 4,
    flRadius = 16,
    pEntityIgnore = 20,
    flRJRadius = 24, // Radius to use to calculate RJ, to maintain RJs when damage/radius changes on a RL
    flForceScale = 28,
    pEntityTarget = 32, // Target being direct hit if any
    flFalloff = 36,

    ctfradiusdamageinfoSize = 40
}

//////////////////////////////////////////////////////////////////////////////
// CTFRADIUSDAMAGEINFO METHOD                                               //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFRadiusDamageInfo < Pointer
{
    public static CTFRadiusDamageInfo FromAddress(any block)
    {
        return view_as<CTFRadiusDamageInfo>(block);
    }

    // CTFRadiusDamageInfo members.
    property CTakeDamageInfo m_dmgInfo
    {
        public get() { return Dereference(this.Address + view_as<Address>(dmgInfo)); }
        public set(CTakeDamageInfo value) { WriteToValue(this.Address + view_as<Address>(dmgInfo), value); }
    }
    property Vector m_vecSrc
    {
        public get() { return Vector.Dereference(this.Address + view_as<Address>(vecSrc)); }
        public set(Vector vector) { vector.WriteToMemory(this.Address + view_as<Address>(vecSrc)); }
    }
    property float m_flRadius
    {
        public get() { return Dereference(this.Address + view_as<Address>(flRadius)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flRadius), value); }
    }
    property CBaseEntity m_pEntityIgnore
    {
        public get() { return view_as<CBaseEntity>(GetEntityFromAddress(this.Address + view_as<Address>(pEntityIgnore))); }
        public set(CBaseEntity entity) { WriteToValue(this.Address + view_as<Address>(pEntityIgnore), entity.Exists ? entity.Address : Address_Null); }
    }
    property float m_flRJRadius
    {
        public get() { return Dereference(this.Address + view_as<Address>(flRJRadius)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flRJRadius), value); }
    }
    property float m_flForceScale
    {
        public get() { return Dereference(this.Address + view_as<Address>(flForceScale)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flForceScale), value); }
    }
    property CBaseEntity m_pEntityTarget
    {
        public get() { return view_as<CBaseEntity>(GetEntityFromAddress(this.Address + view_as<Address>(pEntityTarget))); }
        public set(CBaseEntity entity) { WriteToValue(this.Address + view_as<Address>(pEntityTarget), entity.Exists ? entity.Address : Address_Null); }
    }
    property float m_flFalloff
    {
        public get() { return Dereference(this.Address + view_as<Address>(flFalloff)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flFalloff), value); }
    }

    // Constructor and deconstructor.
    public CTFRadiusDamageInfo(CTakeDamageInfo info, const Vector srcIn, float radiusIn, CBaseEntity ignore = ENTITY_NULL, float rjRadiusIn = 0.00, float forceScaleIn = 1.00)
    {
        Pointer pointer = Pointer(ctfradiusdamageinfoSize);
        CTFRadiusDamageInfo wrapper = CTFRadiusDamageInfo.FromAddress(pointer);

        wrapper.m_dmgInfo = info;
        wrapper.m_vecSrc = srcIn;
        wrapper.m_flRadius = radiusIn;
        wrapper.m_pEntityIgnore = ignore;
        wrapper.m_flRJRadius = rjRadiusIn;
        wrapper.m_flFalloff = 0.00;
        wrapper.m_flForceScale = forceScaleIn;
        wrapper.m_pEntityTarget = ENTITY_NULL;

        SDKCall(SDKCall_CTFRadiusDamageInfo_CalculateFalloff, wrapper.Address);

        return wrapper;
    }
}