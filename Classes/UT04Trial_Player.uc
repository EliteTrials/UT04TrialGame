class UT04Trial_Player extends xPlayer;

// Practically removed the suicide interval.
exec function Suicide()
{
    if ( (Pawn != None) && (Level.TimeSeconds - Pawn.LastStartTime > 0.1) )
        Pawn.Suicide();
}

state PlayerWalking
{
    function bool NotifyLanded(vector HitNormal)
    {
        if (DoubleClickDir == DCLICK_Active)
        {
            DoubleClickDir = DCLICK_Done;
            ClearDoubleClick();
            // Pawn.Velocity *= Vect(0.1,0.1,1.0);
            Pawn.Velocity *= Vect(0.8,0.8,1.0);
        }
        else
            DoubleClickDir = DCLICK_None;

        if ( Global.NotifyLanded(HitNormal) )
            return true;

        return false;
    }
}

state Dead
{
	function BeginState()
    {
        super.BeginState();

        bFrozen = false;
    }
}

defaultproperties
{
    PawnClass=Class'UT04Trial_Pawn'
}
