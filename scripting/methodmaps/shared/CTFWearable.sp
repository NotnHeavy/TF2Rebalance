//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// Inheritance hierachy:
// this -> CEconWearable* -> CEconEntity -> CBaseAnimating* -> CBaseEntity

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFWEARABLE METHODMAP                                                    //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFWearable < CEconEntity
{
    public CTFWearable(int index)
    {
        // Call parent constructor.
        CEconEntity(index);

        return view_as<CTFWearable>(index);
    }

    // Public methods.
    public void ApplyNewAttributes()
    {
        switch (this.ItemDefinitionIndex)
        {
        }
    }
}