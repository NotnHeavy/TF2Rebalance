//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CTFWeaponBaseGrenadeProj -> CBaseGrenade* -> CBaseProjectile* -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFWEARABLE METHODMAP                                                    //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFGrenadePipebombProjectile < CTFWeaponBaseGrenadeProj
{
    public CTFGrenadePipebombProjectile(int index)
    {
        // Call parent constructor.
        CTFWeaponBaseGrenadeProj(index);

        return view_as<CTFGrenadePipebombProjectile>(index);
    }

    // CTFGrenadePipebombProjectile members.
    property bool m_bWallShatter
    {
        public get() { return Dereference(this.Address + CTFGrenadePipebombProjectile_m_bWallShatter, NumberType_Int8); }
        public set(bool toggle) { WriteToValue(this.Address + CTFGrenadePipebombProjectile_m_bWallShatter, toggle, NumberType_Int8); }
    }
    public int GetDamageType()
    {
        return SDKCall(SDKCall_CTFGrenadePipebombProjectile_GetDamageType, this);
    }
}