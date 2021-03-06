//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// I'm just going to combine the functions for QAngles/Vectors into one methodmap.

#pragma semicolon true
#pragma newdecls required

#define GLOBAL_VECTOR_SIZE 64
#define VECTOR_NULL view_as<Vector>(0)

//////////////////////////////////////////////////////////////////////////////
// VECTOR DATA                                                              //
//////////////////////////////////////////////////////////////////////////////

enum vectorOffsets
{
    VECTOR_OFFSET_X = 0,
    VECTOR_OFFSET_Y = 4,
    VECTOR_OFFSET_Z = 8,
    VECTOR_SIZE = 12
}

static int globalIndex = 0;
static float globalVectors[GLOBAL_VECTOR_SIZE][3];

//////////////////////////////////////////////////////////////////////////////
// VECTOR METHODMAP                                                         //
//////////////////////////////////////////////////////////////////////////////

methodmap Vector < Pointer
{
    // Create a new vector. Must be disposed via "Vector.Dispose()" when no longer used, unless marked as global.
    public Vector(float x = 0.00, float y = 0.00, float z = 0.00, bool global = false)
    {
        float buffer[3];
        buffer[0] = x;
        buffer[1] = y;
        buffer[2] = z;

        if (global)
        {
            int index = globalIndex;
            globalIndex = globalIndex + 1 < GLOBAL_VECTOR_SIZE ? globalIndex + 1: 0;
            memcpy(AddressOfArray(globalVectors[index]), AddressOfArray(buffer), VECTOR_SIZE);
            return view_as<Vector>(index);
        }
        
        Vector pointer = malloc(VECTOR_SIZE);
        memcpy(pointer, AddressOfArray(buffer), VECTOR_SIZE);
        return pointer;
    }
    property bool Global
    {
        public get() { return view_as<int>(this) < GLOBAL_VECTOR_SIZE; }
    }
    property Address Address
    {
        public get() { return this.Global ? AddressOfArray(globalVectors[view_as<int>(this)]) : view_as<Address>(this); }
    }

    // Dispose this vector.
    public void Dispose()
    {
        if (!this.Global && this)
            free(this);
    }

    // Vector co-ordinates.
    property float X
    {
        public get() { return Dereference(this.Address + view_as<Address>(VECTOR_OFFSET_X)); }
        public set(float X) { WriteToValue(this.Address + view_as<Address>(VECTOR_OFFSET_X), X); }
    }
    property float Y
    {
        public get() { return Dereference(this.Address + view_as<Address>(VECTOR_OFFSET_Y)); }
        public set(float X) { WriteToValue(this.Address + view_as<Address>(VECTOR_OFFSET_Y), X); }
    }
    property float Z
    {
        public get() { return Dereference(this.Address + view_as<Address>(VECTOR_OFFSET_Z)); }
        public set(float X) { WriteToValue(this.Address + view_as<Address>(VECTOR_OFFSET_Z), X); }
    }

    // Vector functions.
    public void GetBuffer(float buffer[3])
    {
        memcpy(AddressOfArray(buffer), this.Address, VECTOR_SIZE);
    }
    public void SetBuffer(float buffer[3])
    {
        memcpy(this.Address, AddressOfArray(buffer), VECTOR_SIZE);
    }
    public float Length(bool squared = false)
    {
        float buffer[3];
        this.GetBuffer(buffer);
        return GetVectorLength(buffer, squared);
    }
    public float DistTo(Vector other, bool squared = false)
    {
        float buffer[3];
        float bufferOther[3];
        this.GetBuffer(buffer);
        other.GetBuffer(bufferOther);
        return GetVectorDistance(buffer, bufferOther, squared);
    }
    public float Dot(Vector other)
    {
        float buffer[3];
        float bufferOther[3];
        this.GetBuffer(buffer);
        other.GetBuffer(bufferOther);
        return GetVectorDotProduct(buffer, bufferOther);
    }
    public Vector Cross(Vector other)
    {
        float buffer[3];
        float bufferOther[3];
        float result[3];
        this.GetBuffer(buffer);
        other.GetBuffer(bufferOther);
        GetVectorCrossProduct(buffer, bufferOther, result);
        return Vector(result[0], result[1], result[2], true); 
    }
    public float NormalizeInPlace()
    {
        float buffer[3];
        float result[3];
        this.GetBuffer(buffer);
        float normalized = NormalizeVector(buffer, result);
        this.SetBuffer(result);
        return normalized;
    }

    // operator=
    public void Assign(const Vector right)
    {
        this.X = right.X;
        this.Y = right.Y;
        this.Z = right.Z;
    }

    // Memory.
    public static Vector Dereference(Address block, bool global = true)
    {
        float x = Dereference(block);
        float y = Dereference(block + view_as<Address>(0x04));
        float z = Dereference(block + view_as<Address>(0x08));
        return Vector(x, y, z, global);
    }
    public void WriteToMemory(Address block)
    {
        WriteToValue(block, this.X);
        WriteToValue(block + view_as<Address>(0x04), this.Y);
        WriteToValue(block + view_as<Address>(0x08), this.Z);
    }
}

//////////////////////////////////////////////////////////////////////////////
// VECTOR OPERATORS                                                         //
//////////////////////////////////////////////////////////////////////////////

stock Vector operator+(const Vector left, const Vector right)
{
    return Vector(left.X + right.X, left.Y + right.Y, left.Z + right.Z, true);
}
stock Vector operator-(const Vector left, const Vector right)
{
    return Vector(left.X - right.X, left.Y - right.Y, left.Z - right.Z, true);
}
stock Vector operator*(const Vector left, const Vector right)
{
    return Vector(left.X * right.X, left.Y * right.Y, left.Z * right.Z, true);
}
stock Vector operator/(const Vector left, const Vector right)
{
    return Vector(left.X / right.X, left.Y / right.Y, left.Z / right.Z, true);
}

stock Vector operator+(const Vector left, const float right)
{
    return Vector(left.X + right, left.Y + right, left.Z + right, true);
}
stock Vector operator-(const Vector left, const float right)
{
    return Vector(left.X - right, left.Y - right, left.Z - right, true);
}
stock Vector operator*(const Vector left, const float right)
{
    return Vector(left.X * right, left.Y * right, left.Z * right, true);
}
stock Vector operator/(const Vector left, const float right)
{
    return Vector(left.X / right, left.Y / right, left.Z / right, true);
}

stock Vector operator-(const Vector self)
{
    return Vector(-self.X, -self.Y, -self.Z, true);
}

//////////////////////////////////////////////////////////////////////////////
// PUBLIC METHODS                                                           //
//////////////////////////////////////////////////////////////////////////////

stock void VectorVectors(Vector vector, Vector right = VECTOR_NULL, Vector up = VECTOR_NULL)
{
    float forwardBuffer[3];
    float rightBuffer[3];
    float upBuffer[3];
    
    vector.GetBuffer(forwardBuffer);
    if (right)
        right.GetBuffer(rightBuffer);
    if (up)
        up.GetBuffer(upBuffer);
    
    GetVectorVectors(forwardBuffer, rightBuffer, upBuffer);
    
    vector.SetBuffer(forwardBuffer);
    if (right)
        right.SetBuffer(rightBuffer);
    if (up)
        up.SetBuffer(upBuffer);
}

stock void AngleVectors(Vector angles, Vector forwardVector, Vector right = VECTOR_NULL, Vector up = VECTOR_NULL)
{
    float anglesBuffer[3];
    float forwardBuffer[3];
    float rightBuffer[3];
    float upBuffer[3];

    angles.GetBuffer(anglesBuffer);
    forwardVector.GetBuffer(forwardBuffer);
    if (right)
        right.GetBuffer(rightBuffer);
    if (up)
        up.GetBuffer(upBuffer);

    GetAngleVectors(anglesBuffer, forwardBuffer, rightBuffer, upBuffer);

    forwardVector.SetBuffer(forwardBuffer);
    if (right)
        right.SetBuffer(rightBuffer);
    if (up)
        up.SetBuffer(upBuffer);
}

//////////////////////////////////////////////////////////////////////////////
// MISCELLANEOUS                                                            //
//////////////////////////////////////////////////////////////////////////////

stock Vector vec3_origin = VECTOR_NULL;