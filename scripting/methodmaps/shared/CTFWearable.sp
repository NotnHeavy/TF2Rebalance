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
            case 444: // Mantreads.
            {
                // Apply new attributes.
                this.setAttribute("rocket jump damage reduction", 0.75); // -25% blast damage from rocket jumps
            }
        }
    }
}