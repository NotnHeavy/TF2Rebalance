//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

// Inheritance hierachy:
// this -> CBaseObject* -> CBaseCombatCharacter* -> CBaseFlex* -> CBaseAnimatingOverlay* -> CBaseAnimating* -> CBaseEntity

//////////////////////////////////////////////////////////////////////////////
// COBJECTDISPENSER METHODMAP                                                //
//////////////////////////////////////////////////////////////////////////////

methodmap CObjectDispenser < CBaseEntity
{
    // Constructor.
    public CObjectDispenser(int index)
    {
        return view_as<CObjectDispenser>(index);
    }

    // CObjectDispenser members.
    property CUtlVector m_hHealingTargets
    {
        public get() { return view_as<CUtlVector>(this.Address + CObjectDispenser_m_hHealingTargets); }
    }
}