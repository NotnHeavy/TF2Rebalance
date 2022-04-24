//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// WEAPONDATA_T DATA                                                        //
//////////////////////////////////////////////////////////////////////////////

enum weapondata_tOffsets (+= 0x04)
{
    nDamage = 0,
    nBulletsPerShot,
    flRange,
	flSpread,
	flPunchAngle,
	flTimeFireDelay,   // Time to delay between firing
	flTimeIdle,		   // Time to idle after firing
	flTimeIdleEmpty,   // Time to idle after firing last bullet in clip
	flTimeReloadStart, // Time to start into a reload (ie. shotgun)
	flTimeReload,	   // Time to reload
	bDrawCrosshair,	   // Should the weapon draw a crosshair
	iProjectile,	   // The type of projectile this mode fires
	iAmmoPerShot,      // How much ammo each shot consumes
	flProjectileSpeed, // Start speed for projectiles (nail, etc.), NOTE: union with something non-projectile
	flSmackDelay,	   // how long after swing should damage happen for melee weapons
	bUseRapidFireCrits,

    weapondata_tSize
}

//////////////////////////////////////////////////////////////////////////////
// WEAPONDATA_T METHODMAP                                                   //
//////////////////////////////////////////////////////////////////////////////

methodmap WeaponData_t
{
    // Constructor.
    public WeaponData_t(Address address)
    {
        return view_as<WeaponData_t>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // WeaponData_t members.
    property int m_nDamage
    {
        public get() { return Dereference(this.Address + view_as<Address>(nDamage)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(nDamage), value); }
    }
    property int m_nBulletsPerShot
    {
        public get() { return Dereference(this.Address + view_as<Address>(nBulletsPerShot)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(nBulletsPerShot), value); }
    }
    property float m_flRange
    {
        public get() { return Dereference(this.Address + view_as<Address>(flRange)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flRange), value); }
    }
    property float m_flSpread
    {
        public get() { return Dereference(this.Address + view_as<Address>(flSpread)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flSpread), value); }
    }
    property float m_flPunchAngle
    {
        public get() { return Dereference(this.Address + view_as<Address>(flPunchAngle)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flPunchAngle), value); }
    }
    property float m_flTimeFireDelay
    {
        public get() { return Dereference(this.Address + view_as<Address>(flTimeFireDelay)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flTimeFireDelay), value); }
    }
    property float m_flTimeIdle
    {
        public get() { return Dereference(this.Address + view_as<Address>(flTimeIdle)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flTimeIdle), value); }
    }
    property float m_flTimeIdleEmpty
    {
        public get() { return Dereference(this.Address + view_as<Address>(flTimeIdleEmpty)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flTimeIdleEmpty), value); }
    }
    property float m_flTimeReloadStart
    {
        public get() { return Dereference(this.Address + view_as<Address>(flTimeReloadStart)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flTimeReloadStart), value); }
    }
    property float m_flTimeReload
    {
        public get() { return Dereference(this.Address + view_as<Address>(flTimeReload)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flTimeReload), value); }
    }
    property bool m_bDrawCrosshair
    {
        public get() { return Dereference(this.Address + view_as<Address>(bDrawCrosshair), NumberType_Int8); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bDrawCrosshair), value, NumberType_Int8); }
    }
    property int m_iProjectile
    {
        public get() { return Dereference(this.Address + view_as<Address>(iProjectile)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iProjectile), value); }
    }
    property int m_iAmmoPerShot
    {
        public get() { return Dereference(this.Address + view_as<Address>(iAmmoPerShot)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(iAmmoPerShot), value); }
    }
    property float m_flProjectileSpeed
    {
        public get() { return Dereference(this.Address + view_as<Address>(flProjectileSpeed)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flProjectileSpeed), value); }
    }
    property float m_flSmackDelay
    {
        public get() { return Dereference(this.Address + view_as<Address>(flSmackDelay)); }
        public set(float value) { WriteToValue(this.Address + view_as<Address>(flSmackDelay), value); }
    }
    property bool m_bUseRapidFireCrits
    {
        public get() { return Dereference(this.Address + view_as<Address>(bUseRapidFireCrits), NumberType_Int8); }
        public set(bool value) { WriteToValue(this.Address + view_as<Address>(bUseRapidFireCrits), value, NumberType_Int8); }
    }
}