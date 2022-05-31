//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CBaseGrenade* -> CBaseProjectile* -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFWEARABLE METHODMAP                                                    //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFWeaponBaseGrenadeProj < CBaseEntity
{
    public CTFWeaponBaseGrenadeProj(int index)
    {
        // Call parent constructor.
        CBaseEntity(index);

        return view_as<CTFWeaponBaseGrenadeProj>(index);
    }

    // CTFWeaponBaseGrenadeProj members.
    public void Detonate()
    {
        SDKCall(SDKCall_CTFWeaponBaseGrenadeProj_Detonate, this);
    }
}