//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CTFWeaponBaseGun* -> CTFWeaponBase -> CBaseCombatWeapon* -> CEconEntity -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFMINIGUN METHODMAP                                                     //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFMinigun < CTFWeaponBase
{
    public CTFMinigun(int index)
    {
        // Call parent constructor.
        CTFWeaponBase(index);

        return view_as<CTFMinigun>(index);
    }

    // CTFMinigun members.
    property float m_flNextRingOfFireAttackTime
    {
        public get() { return Dereference(this.Address + view_as<Address>(CTFMinigun_m_flNextRingOfFireAttackTime)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(CTFMinigun_m_flNextRingOfFireAttackTime), value); }
    }
    public void RingOfFireAttack(int damage)
    {
        SDKCall(SDKCall_CTFMinigun_RingOfFireAttack, this, damage);
    }
}