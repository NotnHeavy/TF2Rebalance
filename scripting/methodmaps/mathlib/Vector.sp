//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

// This would've been a lot easier to do if I could actually overload operators with enum structs or at least return them from methodmaps.
// Also I know this code isn't the best but I don't know what else to do.

// Also I'm just going to combine the functions for QAngles/Vectors into one methodmap.

// NOTE: I may rewrite this code, with the addition of the SM-Memory extension. This code was written before I included that extension.

#pragma semicolon true
#pragma newdecls required

#define GLOBAL_VECTOR_SIZE 64
#define INVALID_VECTOR view_as<Vector>(-GLOBAL_VECTOR_SIZE - 1)
#define VECTOR_NULL view_as<Vector>(0)

//////////////////////////////////////////////////////////////////////////////
// VECTOR DATA                                                              //
//////////////////////////////////////////////////////////////////////////////

static ArrayList vectorCollection;
static int globalIndex = 0;
static float globalVectors[GLOBAL_VECTOR_SIZE][3];

//////////////////////////////////////////////////////////////////////////////
// VECTOR METHODMAP                                                         //
//////////////////////////////////////////////////////////////////////////////

methodmap Vector
{
    // Create a new vector. Must be disposed via "Vector.Dispose()" when no longer used, unless marked as global.
    public Vector(float x = 0.00, float y = 0.00, float z = 0.00, bool global = false)
    {
        if (vectorCollection == null)
        {
            vectorCollection = new ArrayList(4, -1);
            vectorCollection.PushArray({0.00, 0.00, 0.00, 0.00}); // vec_origin
        }

        any buffer[4];
        buffer[0] = x;
        buffer[1] = y;
        buffer[2] = z;

        if (global)
        {
            int index = globalIndex;
            globalIndex = globalIndex + 1 < GLOBAL_VECTOR_SIZE ? globalIndex + 1: 0;
            globalVectors[index][0] = buffer[0];
            globalVectors[index][1] = buffer[1];
            globalVectors[index][2] = buffer[2];
            return view_as<Vector>(-index - 1);
        }
        buffer[3] = vectorCollection.PushArray(buffer);
        vectorCollection.Set(buffer[3], buffer[3], 3);
        return view_as<Vector>(buffer[3]);
    }
    property int Index
    {
        public get() { return view_as<int>(this); }
    }
    property bool Exists
    {
        public get() { return this.Index > -1 && this.Index < vectorCollection.Length && vectorCollection.Get(this.Index, 3) != INVALID_VECTOR; }
    }
    property bool Global
    {
        public get() { return this.Index < 0 && this.Index > -GLOBAL_VECTOR_SIZE - 1; }
    }
    property int GlobalIndex
    {
        public get() { return -this.Index - 1; }
    }

    // Dispose the vector from the internal array list.
    public void Dispose()
    {
        if (vectorCollection == null || this.Index < 0 || this.Index + 1 > vectorCollection.Length)
            return;
        vectorCollection.Set(this.Index, INVALID_VECTOR, 3);
        for (int i = vectorCollection.Length - 1; i > -1; --i)
        {
            if (vectorCollection.Get(i, 3) != INVALID_VECTOR)
                break;
            vectorCollection.Erase(i);
        }
    }

    // Vector co-ordinates.
    property float X
    {
        public get()
        {
            if (this.Global)
                return globalVectors[this.GlobalIndex][0];
            return vectorCollection.Get(this.Index, 0);
        }
        public set(float X)
        {
            if (this.Global)
            {
                globalVectors[this.GlobalIndex][0] = X;
                return;
            }
            vectorCollection.Set(this.Index, X, 0);
        }
    }
    property float Y
    {
        public get()
        {
            if (this.Global)
                return globalVectors[this.GlobalIndex][1];
            return vectorCollection.Get(this.Index, 1);
        }
        public set(float Y)
        {
            if (this.Global)
            {
                globalVectors[this.GlobalIndex][1] = Y;
                return;
            }
            vectorCollection.Set(this.Index, Y, 1);
        }
    }
    property float Z
    {
        public get()
        {
            if (this.Global)
                return globalVectors[this.GlobalIndex][2];
            return vectorCollection.Get(this.Index, 2);
        }
        public set(float Z)
        {
            if (this.Global)
            {
                globalVectors[this.GlobalIndex][2] = Z;
                return;
            }
            vectorCollection.Set(this.Index, Z, 2);
        }
    }

    // Vector functions.
    public void GetBuffer(float[3] buffer)
    {
        if (this.Global)
        {
            buffer[0] = globalVectors[this.GlobalIndex][0];
            buffer[1] = globalVectors[this.GlobalIndex][1];
            buffer[2] = globalVectors[this.GlobalIndex][2];
            return;
        }
        vectorCollection.GetArray(this.Index, buffer, 3);
    }
    public void SetBuffer(float[3] buffer)
    {
        if (this.Global)
        {
            globalVectors[this.GlobalIndex][0] = buffer[0];
            globalVectors[this.GlobalIndex][1] = buffer[1];
            globalVectors[this.GlobalIndex][2] = buffer[2];
            return;
        }
        vectorCollection.SetArray(this.Index, buffer, 3);
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

stock void VectorVectors(Vector vector, Vector right = INVALID_VECTOR, Vector up = INVALID_VECTOR)
{
    float forwardBuffer[3];
    float rightBuffer[3];
    float upBuffer[3];
    
    vector.GetBuffer(forwardBuffer);
    if (right != INVALID_VECTOR)
        right.GetBuffer(rightBuffer);
    if (up != INVALID_VECTOR)
        up.GetBuffer(upBuffer);
    
    GetVectorVectors(buffer, rightBuffer, upBuffer);
    
    vector.SetBuffer(forwardBuffer);
    if (right != INVALID_VECTOR)
        right.SetBuffer(rightBuffer);
    if (up != INVALID_VECTOR)
        up.SetBuffer(upBuffer);
}

stock void AngleVectors(Vector angles, Vector forwardVector, Vector right = INVALID_VECTOR, Vector up = INVALID_VECTOR)
{
    float anglesBuffer[3];
    float forwardBuffer[3];
    float rightBuffer[3];
    float upBuffer[3];

    angles.GetBuffer(anglesBuffer);
    forwardVector.GetBuffer(forwardBuffer);
    if (right != INVALID_VECTOR)
        right.GetBuffer(rightBuffer);
    if (up != INVALID_VECTOR)
        up.GetBuffer(upBuffer);

    GetAngleVectors(anglesBuffer, forwardBuffer, rightBuffer, upBuffer);

    forwardVector.SetBuffer(forwardBuffer);
    if (right != INVALID_VECTOR)
        right.SetBuffer(rightBuffer);
    if (up != INVALID_VECTOR)
        up.SetBuffer(upBuffer);
}

//////////////////////////////////////////////////////////////////////////////
// MISCELLANEOUS                                                            //
//////////////////////////////////////////////////////////////////////////////

stock Vector vec3_origin = VECTOR_NULL;

stock void DebugVectors()
{
    PrintToServer("Initiating vector debug.\nLength of vector collection: %i", vectorCollection.Length);
    for (int i = 0; i < vectorCollection.Length; ++i)
        PrintToServer("Vector %i, is it being used: %s", i, vectorCollection.Get(i, 3) == INVALID_VECTOR ? "no" : "yes");
    PrintToServer("Ending vector debug.");
}