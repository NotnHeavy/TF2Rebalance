//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

#define NULL view_as<Pointer>(0)

//////////////////////////////////////////////////////////////////////////////
// POINTER METHODMAP                                                        //
//////////////////////////////////////////////////////////////////////////////

methodmap Pointer
{
    // Constructor and deconstructor.
    public Pointer(int size)
    {
        return malloc(size);
    }
    public void Dispose()
    {
        free(this);
    }
    property Address Address
    {
        public get() { return view_as<Address>(this); }
    }

    // Methods.
    public void Dereference(any offset = 0, NumberType bits = NumberType_Int32)
    {
        Dereference(this.Address + offset, bits);
    }
    public void Write(any value, any offset = 0, NumberType bits = NumberType_Int32)
    {
        WriteToValue(this.Address + offset, value, bits);
    }
}