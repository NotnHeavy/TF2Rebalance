//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> FileWeaponInfo_t*

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFWEAPONINFO METHODMAP                                                  //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFWeaponInfo
{
    // Constructor.
    public CTFWeaponInfo(Address address)
    {
        return view_as<CTFWeaponInfo>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // CTFWeaponInfo members.
    public WeaponData_t GetWeaponData(int weapon)
    {
        return view_as<WeaponData_t>(this.Address + view_as<Address>(weapon * view_as<int>(weapondata_tSize)) + CTFWeaponInfo_m_WeaponData);
    }
}