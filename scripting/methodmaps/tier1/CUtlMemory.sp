//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CUTLMEMORY DATA                                                          //
//////////////////////////////////////////////////////////////////////////////

enum cutlmemoryOffsets
{
    pMemory = 0,
    nAllocationCount = 4,
    nGrowSize = 8,
    cutlmemorySize = 16
}

//////////////////////////////////////////////////////////////////////////////
// CUTLMEMORY METHODMAP                                                     //
//////////////////////////////////////////////////////////////////////////////

// This code is limited because I don't see the point in implementing literally everything.

methodmap CUtlMemory
{
    // Constructor.
    public CUtlMemory(Address address)
    {
        return view_as<CUtlMemory>(address);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // CUtlMemory members.
    property Address m_pMemory
    {
        public get() { return Dereference(this.Address + view_as<Address>(pMemory)); }
    }

    // Element access.
    public any Get(int index, int size = 4)
    {
        return this.m_pMemory + view_as<Address>(index * size);
    }
    public void Set(int index, any value, int size = 4, int offset = 0)
    {
        NumberType bitdepth = size == 4 ? NumberType_Int32 : size == 2 ? NumberType_Int16 : NumberType_Int8;
        WriteToValue(this.m_pMemory + view_as<Address>(index * size + offset), value, bitdepth);
    }
}