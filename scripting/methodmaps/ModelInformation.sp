//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// MODELINFORMATION DATA                                                    //
//////////////////////////////////////////////////////////////////////////////

enum modelinformationOffsets
{
    modelinformationoffsetModel = 0, // char Model[PLATFORM_MAX_PATH];
    modelinformationoffsetTexture = 64, // char Texture[PLATFORM_MAX_PATH];

    modelinformationoffsetShowWhileTaunting = 128, // bool ShowWhileTaunting;
    modelinformationoffsetCache = 129, // int Cache;

    modelinformationoffsetFullModel = 130, // char FullModel[PLATFORM_MAX_PATH];

    modelinformationsize = 194 // sizeof(ModelInformation);
}

//////////////////////////////////////////////////////////////////////////////
// MODELINFORMATION METHODMAP                                               //
//////////////////////////////////////////////////////////////////////////////

// These still need to be garbage collected when the plugin finishes, since the memory is not being kept track of by SourceMod.
methodmap ModelInformation < Pointer
{
    // Create a new model record.
    public ModelInformation()
    {
        return view_as<ModelInformation>(Pointer(view_as<int>(modelinformationsize)));
    }

    // ModelInformation members.
    public void GetModel(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            buffer[i] = view_as<char>(this.Dereference(view_as<int>(modelinformationoffsetModel), NumberType_Int8));
    }
    public void SetModel(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            this.Write(buffer[i], view_as<int>(modelinformationoffsetModel), NumberType_Int8);
    }
    public void GetTexture(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            buffer[i] = view_as<char>(this.Dereference(view_as<int>(modelinformationoffsetTexture), NumberType_Int8));
    }
    public void SetTexture(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            this.Write(buffer[i], view_as<int>(modelinformationoffsetTexture), NumberType_Int8);
    }

    property bool ShowWhileTaunting
    {
        public get() { return this.Dereference(view_as<int>(modelinformationoffsetShowWhileTaunting), NumberType_Int8); }
        public set(bool value) { this.Write(value, view_as<int>(modelinformationoffsetShowWhileTaunting), NumberType_Int8); }
    }
    property int Cache
    {
        public get() { return this.Dereference(view_as<int>(modelinformationoffsetCache)); }
        public set(int value) { this.Write(value, view_as<int>(modelinformationoffsetCache)); }
    }

    public void GetFullModel(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            buffer[i] = view_as<char>(this.Dereference(view_as<int>(modelinformationoffsetFullModel), NumberType_Int8));
    }
    public void SetFullModel(char buffer[PLATFORM_MAX_PATH])
    {
        for (int i = 0; i < sizeof(buffer); ++i)
            this.Write(buffer[i], view_as<int>(modelinformationoffsetFullModel), NumberType_Int8);
    }
}