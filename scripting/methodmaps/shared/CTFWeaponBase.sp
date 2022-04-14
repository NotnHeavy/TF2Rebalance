//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CBaseCombatWeapon* -> CEconEntity -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFWEAPONBASE METHODMAP                                                  //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFWeaponBase < CEconEntity
{
    public CTFWeaponBase(int index)
    {
        // Call parent constructor.
        CEconEntity(index);

        return view_as<CTFWeaponBase>(index);
    }

    // CTFWeaponBase members.
    property float m_flLastDeployTime
    {
        public get() { return Dereference(this.Address + CTFWeaponBase_m_flLastDeployTime); }
        public set(float value) { WriteToValue(this.Address + CTFWeaponBase_m_flLastDeployTime, value); }
    }

    // Public methods.
    public void ApplyNewAttributes()
    {
        switch (this.ItemDefinitionIndex)
        {
            // Scout primary.
            case 220: // Shortstop.
            {
                // Apply new attributes.
                this.setAttribute("reload time increased hidden", 1.35); // 35% slower reload time (HIDDEN)
                this.setAttribute("healing received bonus", 1.20); // +20% bonus healing while deployed.
            }
            case 772: // Baby Face's Blaster.
            {
                // Remove old attributes.
                this.setAttribute("lose hype on take damage", 0.00); // Boost reduced when hit

                // Apply new attributes.
                this.setAttribute("hype resets on jump", 50.00); // Boost reduced on air jumps
            }
            case 1103: // Back Scatter.
            {
                // Remove old attributes.
                this.setAttribute("spread penalty", 0.00); // -0% less accurate
            }

            // Scout secondary.
            case 773: // Pretty Boy's Pocket Pistol.
            {
                // Remove old attributes.
                this.setAttribute("heal on hit for rapidfire", 0.00); // On Hit: Gain up to +0 health
                
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.85); // -25% damage penalty
            }
            
            // Pyro.
            case 215: // Degreaser.
            {
                // Remove old attributes.
                this.setAttribute("weapon burn dmg reduced", 1.00); // -0% afterburn damage penalty
                this.setAttribute("switch from wep deploy time decreased", 1.00); // This weapon holsters 0% faster
                this.setAttribute("single wep deploy time decreased", 1.00); // This weapon deploys 0% faster
                
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.65); // 35% damage penalty
                this.setAttribute("deploy time decreased", 0.5); // 50% faster weapon switch
            }

            // Demoman.
            case 307: // Ullapool Caber.
            {
                // Remove old attributes.
                this.setAttribute("single wep deploy time increased", 1.00); // This weapon deploys 0% slower

                // Apply new attributes.
                this.setAttribute("deploy time increased", 1.35); // 35% longer weapon switch
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
// PUBLIC METHODS                                                           //
//////////////////////////////////////////////////////////////////////////////

stock CTFWeaponBase ToTFWeaponBase(CBaseEntity entity)
{
    if (!entity.Exists || !entity.IsBaseCombatWeapon)
        return view_as<CTFWeaponBase>(INVALID_ENTITY); // why does this need to be casted
    return view_as<CTFWeaponBase>(entity);
}