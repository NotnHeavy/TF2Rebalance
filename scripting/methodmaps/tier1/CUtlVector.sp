//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// hgisdejafnksfdjofidakdjfa

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CUTLVECTOR DATA                                                          //
//////////////////////////////////////////////////////////////////////////////

enum cutlvectorOffsets
{
    Memory = 0,
    Size = 12,
    pElements = 16,
    cutlvectorSize = 20
}

//////////////////////////////////////////////////////////////////////////////
// CUTLVECTOR METHODMAP                                                     //
//////////////////////////////////////////////////////////////////////////////

// This code is limited because I don't see the point in implementing literally everything.

methodmap CUtlVector
{
    // Constructor.
    public CUtlVector(Address address)
    {
        return view_as<CUtlVector>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // CUtlVector members.
    property CUtlMemory m_Memory
    {
        public get() { return view_as<CUtlMemory>(this.Address + view_as<Address>(Memory)); }
    }
    property int m_Size
    {
        public get() { return Dereference(this.Address + view_as<Address>(Size)); }
        public set(int value) { WriteToValue(this.Address + view_as<Address>(Size), value); }
    }
    public int Count()
    {
        return this.m_Size;
    }

    // Element access.
    public any Get(int index, int size = 4)
    {
        return this.m_Memory.Get(index, size);
    }
    public void Set(int index, any value, int size = 4, int offset = 0)
    {
        this.m_Memory.Set(index, value, size, offset);
    }
}