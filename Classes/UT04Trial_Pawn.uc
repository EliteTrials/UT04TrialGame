class UT04Trial_Pawn extends xPawn;

function Suicide()
{
    Died(Controller, Class'Suicided', Location);
}

event Landed(Vector hitNormal)
{
    super.Landed(hitNormal);

    if (Inventory != none) { // no authority check; I want this simulated.
        Inventory.OwnerEvent('Landed');
    }
}

function DoDoubleJump(bool bUpdating)
{
    local float lastZ;

    lastZ = Velocity.Z;
    super.DoDoubleJump(bUpdating);

    // Verify that the double jump was in fact applied.
    if (Inventory != none && Velocity.Z != lastZ && Physics == PHYS_Falling) { // no authority check; I want this simulated.
        Inventory.OwnerEvent('DoubleJumped');
    }
}

// Inform the inventory chain of this precious event after the dodge has been successfully applied :)
function bool PerformDodge(eDoubleClickDir doubleClickMove, vector dir, vector cross)
{
    if (super.PerformDodge(doubleClickMove, dir, cross)) {
        if (Inventory != none) { // no authority check; I want this simulated.
            Inventory.OwnerEvent('Dodged');
        }

        return true;
    }

    return false;
}

defaultproperties
{

}
