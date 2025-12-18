class UT04Trial_Mutator extends ASMutator
    HideDropDown
    CacheExempt;

function bool IsRelevant(Actor Other, out byte bSuperRelevant)
{
    if ( Other.IsA('AdrenalinePickup') )
    {
        bSuperRelevant = 0;
        return false;
    }
    if ( Controller(Other) != None && MessagingSpectator(Other) == None )
    {
        Controller(Other).bAdrenalineEnabled = false;
        Controller(Other).PlayerReplicationInfoClass = class'UT04Trial_PlayerReplicationInfo';
    }

    return Super(DMMutator).IsRelevant(Other, bSuperRelevant);
}

public function Bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    // Spawn pickups immediately.
    if (bool(xPickupBase(other)))
    {
        xPickupBase(other).bDelayedSpawn = false;
        return true;
    }

    return super.CheckReplacement(Other, bSuperRelevant);
}

defaultproperties
{

}