//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CECONENTITY METHODMAP                                                    //
//////////////////////////////////////////////////////////////////////////////

methodmap CEconEntity < CBaseEntity
{
    // Constructor.
    public CEconEntity(int index)
    {
        // Call parent constructors.
        CBaseEntity(index);

        return view_as<CEconEntity>(index);
    }

    // Methods that should only be used within this class and inherited classes (protected).
    // This would've been a part of another methodmap (IHasAttributes) but multiple inheritance is not a feature.
    public void setAttribute(const char[] attribute, float value)
    {
        TF2Attrib_SetByName(view_as<int>(this), attribute, value);
    }

    // Property wrappers.
    property int ItemDefinitionIndex // This is a part of m_AttributeManager, m_hItem, but I'm not digging that far for just one member.
    {
        public get()
        {
            if (!IsValidEntity(this.Index) || !HasEntProp(this.Index, Prop_Send, "m_iItemDefinitionIndex"))
                return -1;
            return GetEntProp(this.Index, Prop_Send, "m_iItemDefinitionIndex");
        }
    }

    // Public methods.
    // These would've been a part of another methodmap (IHasAttributes) but multiple inheritance is not a feature, at least as of SM 1.10.
    public float GetAttribute(const char[] attribute)
    {
        Address address = TF2Attrib_GetByName(this.Index, attribute);
        return address != Address_Null ? TF2Attrib_GetValue(address) : -1.00;
    }
    public void HookValueFloat(float& value, const char[] attribute)
    {
        value = TF2Attrib_HookValueFloat(value, attribute, this.Index);
    }
    public void HookValueInt(int& value, const char[] attribute)
    {
        value = TF2Attrib_HookValueInt(value, attribute, this.Index);
    }
}