class UT04Trial_GameReplicationInfo extends ASGameReplicationInfo;

simulated event Timer()
{
    // Skip the 'Reinforcements' code.
    super(GameReplicationInfo).Timer();
}

// No practice round for trials.
simulated function bool IsPracticeRound()
{
    return false;
}

// Everyone is an attacker under trials.
simulated function bool IsDefender(byte team)
{
    return false;
}

defaultproperties
{
    // Infinite
    MaxTeleportTime=0
    ERW_PracticeRoundEndedStr="Practice round over. Get ready!"
    ERW_RedAttackedStr="Red team scored the most objectives!"
    ERW_BlueAttackedStr="Blue team scored the most objectives!"
    ERW_RedDefendedStr="Red team scored the most objectives!"
    ERW_BlueDefendedStr="Blue team scored the most objectives!"
    ERW_RedMoreObjectivesStr="Red team scored the most objectives!"
    ERW_BlueMoreObjectivesStr="Blue team scored the most objectives!"
    ERW_RedMoreProgressStr="Red team scored the most objectives!"
    ERW_BlueMoreProgressStr="Blue team scored the most objectives!"
    ERW_RedGotSameOBJFasterStr="Red team scored the most objectives!"
    ERW_BlueGotSameOBJFasterStr="Blue team scored the most objectives!"
    ERW_DrawStr="Draw game."

    ServerName="UT2004 Trials Server"
    ShortName="Trials Server"
}
