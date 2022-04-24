//////////////////////////////////////////////////////////////////////////////
// MADE BY NOTNHEAVY. USES GPL-3, AS PER REQUEST OF SOURCEMOD               //
//////////////////////////////////////////////////////////////////////////////

#pragma semicolon true 
#pragma newdecls required

//////////////////////////////////////////////////////////////////////////////
// CTFGAMERULES METHODMAP                                                   //
//////////////////////////////////////////////////////////////////////////////

methodmap CTFGameRules
{
    // CTFGameRules members.
    public float FlPlayerFallDamage(CTFPlayer player)
    {
        return SDKCall(SDKCall_CTFGameRules_FlPlayerFallDamage, player.Index);
    }
    public void RadiusDamage(MemoryBlock info)
    {
        SDKCall(SDKCall_CTFGameRules_RadiusDamage, info.Address);
    }
}