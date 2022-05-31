//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

#define NULL_CUSTOM_WEAPON view_as<CustomWeapon>(0)

//////////////////////////////////////////////////////////////////////////////
// CUSTOMWEAPON DATA                                                        //
//////////////////////////////////////////////////////////////////////////////

enum customweaponOffsets
{
    offsetObject = 0, // char Object[256];
    offsetName = 64, // char Name[256];
    offsetClasses = 128, // bool Classes[10];
    offsetItemDefinitionIndex = 131, // int ItemDefinitionIndex
    offsetSlot = 132, // int Slot
    customweaponSize = 133
}
static ArrayList customweaponCollection;

//////////////////////////////////////////////////////////////////////////////
// CUSTOMWEAPON METHODMAP                                                   //
//////////////////////////////////////////////////////////////////////////////

// These do not have a dispose function because they are permanent.
methodmap CustomWeapon
{
    // Create a new custom weapon definition.
    public CustomWeapon()
    {
        if (customweaponCollection == null)
        {
            customweaponCollection = new ArrayList(view_as<int>(customweaponSize)); // char Object[256]; char Name[256]; bool Classes[10]; int ItemDefinitionIndex; int Slot;
            customweaponCollection.Push(0); // NULL_CUSTOM_WEAPON
        }
        return view_as<CustomWeapon>(customweaponCollection.PushArray({0, 0, 0})); 
    }
    property int Index
    {
        public get() { return view_as<int>(this); }
    }

    // CustomWeapon members.
    public void GetObject(char buffer[256])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            buffer[i] = view_as<char>(customweaponCollection.Get(this.Index, view_as<int>(offsetObject) + i, true));
    }
    public void SetObject(char buffer[256])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            customweaponCollection.Set(this.Index, buffer[i], i, true);
    }
    public void GetName(char buffer[256])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            buffer[i] = view_as<char>(customweaponCollection.Get(this.Index, view_as<int>(offsetName) + i, true));
    }
    public void SetName(char buffer[256])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            customweaponCollection.Set(this.Index, buffer[i], view_as<int>(offsetName) + i, true);
    }
    public bool AllowedOnClass(TFClassType class)
    {
        return customweaponCollection.Get(this.Index, view_as<int>(offsetClasses) + view_as<int>(class), true);
    }
    public void ToggleClass(TFClassType class, bool toggle)
    {
        customweaponCollection.Set(this.Index, toggle, view_as<int>(offsetClasses) + view_as<int>(class), true);
    }

    property int ItemDefinitionIndex
    {
        public get() { return customweaponCollection.Get(this.Index, view_as<int>(offsetItemDefinitionIndex)); }
        public set(int value) { customweaponCollection.Set(this.Index, value, view_as<int>(offsetItemDefinitionIndex)); }
    }
    property int Slot
    {
        public get() { return customweaponCollection.Get(this.Index, view_as<int>(offsetSlot)); }
        public set(int value) { customweaponCollection.Set(this.Index, value, view_as<int>(offsetSlot)); }
    }

    /*
    property int ItemDefinitionIndex
    {
        public get() { return customweaponCollection.Get(this.Index, 512); }
        public set(int value) { customweaponCollection.Set(this.Index, value, 512); }
    }
    property TFClassType Class
    {
        public get() { return customweaponCollection.Get(this.Index, 513); }
        public set(TFClassType value) { customweaponCollection.Set(this.Index, value, 513); }
    }
    property int Slot
    {
        public get() { return customweaponCollection.Get(this.Index, 514); }
        public set(int value) { customweaponCollection.Set(this.Index, value, 514); }
    }
    */
    
    // Statics.
    public static CustomWeapon Length()
    {
        return view_as<CustomWeapon>(customweaponCollection.Length);
    }
    public static CustomWeapon FromItemDefinitionIndex(int index)
    {
        for (CustomWeapon definition = view_as<CustomWeapon>(1); definition != CustomWeapon.Length(); ++definition)
        {
            if (definition.ItemDefinitionIndex == index)
                return definition;
        }
        return NULL_CUSTOM_WEAPON;
    }
}