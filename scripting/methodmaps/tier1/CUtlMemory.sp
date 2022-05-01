//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CUTLMEMORY DATA                                                          //
//////////////////////////////////////////////////////////////////////////////

enum cutlmemoryOffsets (+= 0x04)
{
    pMemory = 0,
    nAllocationCount,
    nGrowSize,
    cutlmemorySize
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
        return view_as<Address>(address);
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
    public void Set(int index, any value, NumberType size = NumberType_Int32)
    {
        int sizeBytes = size == NumberType_Int32 ? 4 : size == NumberType_Int16 ? 2 : 1;
        WriteToValue(this.Address + view_as<Address>(pMemory) + view_as<Address>(index * sizeBytes), value, size);
    }
}