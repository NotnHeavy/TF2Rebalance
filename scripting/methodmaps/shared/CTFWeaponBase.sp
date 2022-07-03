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
    property CTFWeaponInfo m_pWeaponInfo
    {
        public get() { return Dereference(this.Address + CTFWeaponBase_m_pWeaponInfo); }
    }
    property int m_iWeaponMode
    {
        public get() { return Dereference(this.Address + CTFWeaponBase_m_iWeaponMode); }
        public set(int value) { WriteToValue(this.Address + CTFWeaponBase_m_iWeaponMode, value); }
    }
    public int GetMaxClip1()
    {
        if (!this.Exists)
            return 0;
        return SDKCall(SDKCall_CTFWeaponBase_GetMaxClip1, this);
    }
    public int GetName()
    {
        return SDKCall(SDKCall_CBaseCombatWeapon_GetName, this);
    }
    public int GetSlot()
    {
        return SDKCall(SDKCall_CBaseCombatWeapon_GetSlot, this);
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
                this.setAttribute("spread penalty", 1.00); // -0% less accurate
            }

            // Scout secondary.
            case 773: // Pretty Boy's Pocket Pistol.
            {
                // Remove old attributes.
                this.setAttribute("heal on hit for rapidfire", 0.00); // On Hit: Gain up to +0 health
                
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.75); // -25% damage penalty
            }

            // Scout melee.
            case 349: // Sun-on-a-Stick.
            {
                // Remove old attributes.
                this.setAttribute("damage penalty", 1.00); // -0% damage penalty
                this.setAttribute("crit vs burning players", 0.00); // 100% critical hit vs burning players. Dealt with internally.

                // Apply new attributes.
                this.setAttribute("dmg penalty vs nonburning", 0.50); // -50% damage vs non-burning players
                this.setAttribute("crit mod disabled", 0.00); // No random critical hits
            }
            case 355: // Fan O'War
            {
                // Apply new attributes.
                this.setAttribute("switch from wep deploy time decreased", 0.80); // This weapon holsters 20% faster
                this.setAttribute("single wep deploy time decreased", 0.80); // This weapon deploys 20% faster
            }

            // Soldier primary.
            case 18, 127: // Troll mode with the stock and Direct Hit rocket launchers.
            {
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("maxammo secondary increased", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }
            }
            case 414: // Liberty Launcher.
            {
                // Remove old attributes.
                this.setAttribute("damage penalty", 1.00); // -0% damage penalty
                this.setAttribute("clip size bonus", 1.00); // +0% clip size
                this.setAttribute("rocket jump damage reduction", 1.00); // -25% blast damage from rocket jumps

                // Apply new attributes.
                this.setAttribute("clip size penalty", 0.75); // -25% clip size
                this.setAttribute("Blast radius decreased", 0.75); // -25% explosion radius
                this.setAttribute("switch from wep deploy time decreased", 0.80); // This weapon holsters 20% faster
                this.setAttribute("single wep deploy time decreased", 0.80); // This weapon deploys 20% faster
            }
            case 730: // Beggar's Bazooka.
            {
                // Remove old attributes.
                this.setAttribute("Blast radius decreased", 1.00); // -0% explosive radius

                // Apply new attributes.
                this.setAttribute("damage penalty", 0.85); // -15% damage penalty
            }
            case 1104: // Air Strike.
            {
                // Apply new attributes.
                this.setAttribute("rocket jump damage reduction", 0.75); // -25% blast damage from rocket jumps
            }

            // Soldier secondary.
            case 442: // Righteous Bison.
            {
                // Apply new attributes.
                this.setAttribute("Reload time increased", 1.25); // 25% slower reload time
            }
            
            // Pyro primary.
            case 40: // Backburner.
            {
                // Remove old attributes.
                this.setAttribute("mod flamethrower back crit", 0.00);
            }
            case 215: // Degreaser.
            {
                // Remove old attributes.
                this.setAttribute("weapon burn dmg reduced", 1.00); // -0% afterburn damage penalty
                this.setAttribute("switch from wep deploy time decreased", 1.00); // This weapon holsters 0% faster
                this.setAttribute("single wep deploy time decreased", 1.00); // This weapon deploys 0% faster
                
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.75); // 35% damage penalty
                this.setAttribute("deploy time decreased", 0.5); // 50% faster weapon switch
            }

            // Pyro secondary.
            case 39, 351, 595: // Troll mode with the flare guns.
            {
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("maxammo secondary increased", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }
            }
            case 740: // Scorch Shot.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("maxammo secondary increased", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }

                // Remove old attributes.
                this.setAttribute("minicrit vs burning player", 0.00);

                // Apply new attributes.
                this.setAttribute("damage penalty", 0.50); // 50% damage penalty
            }
            case 1179: // Thermal Thruster.
            {
                // Apply new attributes.
                this.setAttribute("thermal_thruster_air_launch", 1.00); // Able to re-launch while already in-flight
                this.setAttribute("holster_anim_time", 0.5); // holster_anim_time
            }

            // Pyro melee.
            case 348: // Sharpened Volcano Fragment.
            {
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.10); // -90% damage penalty
                this.setAttribute("minicrit vs burning player", 1.00); // 100% minicrits vs burning players
            }
            case 593: // Third Degree.
            {
                // Apply new attributes.
                this.setAttribute("damage penalty", 0.75); // 25% damage penalty
                this.setAttribute("mod crit while airborne", 1.00); // Deals crits while the wielder is rocket jumping
                this.setAttribute("single wep holster time increased", 1.35); // This weapon holsters 35% slower
            }

            // Demoman primary.
            case 19, 206, 996, 1007, 1151: // Troll mode with all of Demo's grenade launchers.
            {
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }
            }
            case 308: // Loch-n-Load.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }

                // Remove old attributes.
                this.setAttribute("sticky air burst mode", 0.00); // Launched bombs shatter on surfaces

                // Apply new attributes.
                this.setAttribute("clip size penalty", 0.50); // -50% clip size
                this.setAttribute("Reload time increased", 1.25); // +25% slower reload time
                this.setAttribute("mod mini-crit airborne", 1.00); // Mini-crits targets launched airborne by explosions, grapple hooks or rocket packs
            }
            
            // Demoman melee.
            case 132, 266, 482, 1082: // Eyelander, Horseless Headless Horsemann's Headtaker and Nessie's Nine Iron.
            {
                // Apply new attributes.
                this.setAttribute("maxammo secondary reduced", 0.20); // -80% max secondary ammo on wearer
            }
            case 172: // Scotsman's Skullcutter.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                    this.setAttribute("damage bonus", 1000.00);

                // Apply new attributes.
                this.setAttribute("mod crit while airborne", 1.00); // Deals crits while the wielder is rocket jumping
            }
            case 307: // Ullapool Caber.
            {
                // Remove old attributes.
                this.setAttribute("single wep deploy time increased", 1.00); // This weapon deploys 0% slower

                // Apply new attributes.
                this.setAttribute("deploy time increased", 1.35); // 35% longer weapon switch
            }
            case 327: // Claidheamh Mòr.
            {
                // Apply new attributes.
                this.setAttribute("heal on kill", 15.00); // +15 health restored on kill
            }

            // Heavy primary.
            case 41: // Natascha.
            {
                // Remove old attributes.
                this.setAttribute("slow enemy on hit", 0.00); // On Hit: 0% chance to slow target
                this.setAttribute("spunup_damage_resistance", 1.00); // 0% damage resistance when below 50% health and spun up

                // Apply new attributes.
                this.setAttribute("heal on kill", 50.00); // +50% health restored on kill
            }
            case 312: // Brass Beast.
            {
                // Apply new attributes.
                this.setAttribute("aiming movespeed decreased", 0.60); // -40% slower move speed while deployed
                this.setAttribute("minigun spinup time increased", 1.40); // 40% slower spin up time
            }
            case 811, 832: // Huo-Long Heater.
            {
                // Remove old attributes.
                this.setAttribute("damage penalty", 1.00); // -0% damage penalty
                this.setAttribute("ring of fire while aiming", 0.00); // Creates a ring of flames while spun up
                this.setAttribute("uses ammo while aiming", 0.00); // Consumes an additional 0 ammo per second while spun up

                // Apply new attributes.
                this.setAttribute("dmg penalty vs nonburning", 0.90); // -10% damage vs non-burning players
            }

            // Heavy secondary.
            case 425: // Family Business.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                    this.setAttribute("move speed bonus", 100.00);
                }
            }

            // Heavy melee.
            case 310: // Warrior's Spirit.
            {
                // Remove old attributes.
                this.setAttribute("dmg taken increased", 1.00); // 0% damage vulnerability to wearer

                // Apply new attributes.
                this.setAttribute("fire rate penalty", 1.20); // 20% slower firing speed
            }
            case 331: // Fists of Steel.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("dmg from ranged reduced", 0.001);
                }

                // Remove old attributes.
                this.setAttribute("single wep holster time increased", 1.00); // This weapon holsters 0% slower

                // Apply new attributes.
                this.setAttribute("deploy time increased", 1.75); // 75% longer weapon switch
            }
            case 426: // Eviction Notice.
            {
                // Remove old attributes.
                this.setAttribute("mult_player_movespeed_active", 1.00); // 0% faster move speed on wearer
                this.setAttribute("mod_maxhealth_drain_rate", 0.00); // Maximum health is drained while item is active

                // Apply new attributes.
                this.setAttribute("fire rate bonus", 0.50); // 50% faster firing speed
            }

            // Engineer primary.
            case 588: // Pomson 6000.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                    this.setAttribute("Reload time decreased", 0.001);
                }

                // Remove old attributes.
                this.setAttribute("subtract victim medigun charge on hit", 0.00);
                this.setAttribute("subtract victim cloak on hit", 0.00);
            }

            // Spy primary.
            case 61: // Ambassador.
            {
                // Troll mode.
                if (notnheavy_tf2rebalance_troll_mode.BoolValue)
                {
                    this.setAttribute("clip size bonus", 100000000.00);
                    this.setAttribute("maxammo secondary increased", 1000.00);
                    this.setAttribute("fire rate bonus", 0.01);
                }
            }
        }
        if (this.ClassEquals("tf_weapon_jar")) // Jarate.
        {
            // Apply new attributes.
            this.setAttribute("allowed in medieval mode", 1.00); // allowed_in_medieval_mode
        }
    }
    public void SetAmmo(int ammo)
    {
        CBaseEntity owner = this.Owner;
        if (owner == INVALID_ENTITY)
            return;
        owner.SetMember(Prop_Send, "m_iAmmo", ammo, .offset = this.GetMember(Prop_Send, "m_iPrimaryAmmoType"));
    }
    public int GetAmmo()
    {
        CBaseEntity owner = this.Owner;
        if (owner == INVALID_ENTITY)
            return -1;
        return owner.GetMember(Prop_Send, "m_iAmmo", .offset = this.GetMember(Prop_Send, "m_iPrimaryAmmoType"));
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