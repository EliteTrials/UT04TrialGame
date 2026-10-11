/** A Trials specific implementation of Assault -- EliotVU */
class UT04Trial_GameInfo extends ASGameInfo
    abstract
    cacheexempt;

var const array<string> TrialHints;

var globalconfig bool bUnlimitedTrialRounds;

event Reset()
{
    LastDisabledObjective = none;
    BeginNewPairOfRounds();
}

event InitGame( string Options, out string Error )
{
    // Skip Assault and TeamGame options.
    super(DeathMatch).InitGame( Options, Error );

    RoundTimeLimit		= Max( 0, GetIntOption( Options, "RoundTimeLimit", RoundTimeLimit ) );
    PracticeTimeLimit	= Max( 0, GetIntOption( Options, "PracticeTimeLimit", PracticeTimeLimit ) );

    RoundLimit	= 1;
    MaxRounds	= 1;

    ResetTimeDelay		= Max(0, GetIntOption( Options, "ResetTimeDelay", ResetTimeDelay ));

    // Disable TimeLimit
    TimeLimit		= 0;
    RemainingTime	= (RoundTimeLimit + ResetTimeDelay + 1) * 60;
    if ( GameReplicationInfo != None )
        GameReplicationInfo.RemainingTime = RemainingTime;
}

function InitGameReplicationInfo()
{
    super(DeathMatch).InitGameReplicationInfo();

    ASGameReplicationInfo(GameReplicationInfo).MaxRounds = 1;
}

function bool NeedPlayers()
{
    return false; // solo mode
}

function bool AddBot(optional string botName)
{
    // Never add any bots, regardless of settings, trials is not designed to be played against bots.
    return false;
}

event PlayerController Login
(
    string Portal,
    string Options,
    out string Error
)
{
    local	PlayerController	PC;
    local	bool				bSpectator;

    PC = super(DeathMatch).Login( Portal, Options, Error );
    if ( PC != None )
    {
        if ( Level.NetMode == NM_StandAlone )
        {
            bSpectator = ( ParseOption( Options, "SpectatorOnly" ) ~= "1" );
            // Let's not start at round 1
            // CurrentRound = 1;							// No PracticeRound offline
            if ( !bQuickStart && !bSpectator && !PC.PlayerReplicationInfo.bOnlySpectator )
                TriggerEvent('IntroScene', Self, None);		// try to play Matinee intro
        }
    }

    return PC;
}

function BeginRound()
{
    local Controller		C, NextC;
    local GameObjective	GO;

    log("ASGameInfo::BeginRound");

    CurrentAttackingTeam = 0;
    BeginNewPairOfRounds();

    LastDisabledObjective	= None;
    CurrentObjective		= None;

    ASGameReplicationInfo(GameReplicationInfo).bTeamZeroIsAttacking	= (CurrentAttackingTeam == 0);
    ASGameReplicationInfo(GameReplicationInfo).ObjectiveProgress	= 0;
    ASGameReplicationInfo(GameReplicationInfo).CurrentRound			= CurrentRound;
    ASGameReplicationInfo(GameReplicationInfo).RoundWinner			= ERW_None;
    RoundStartTime													= RemainingTime;	// local round start stamp
    ASGameReplicationInfo(GameReplicationInfo).RoundStartTime		= RemainingTime;	// replicated round start stamp
    GameReplicationInfo.RemainingTime								= RemainingTime;	// for new players joining..
    GameReplicationInfo.RemainingMinute								= RemainingTime;	// re-synch current players
    GameReplicationInfo.NetUpdateTime								= Level.TimeSeconds - 1;

    // Set Round Time Limit
    ASGameReplicationInfo(GameReplicationInfo).RoundTimeLimit = RoundTimeLimit * 60;		// default round time limit

    ResetLevel();

    // Force objective DefenderTeamIndex
    for ( GO=Teams[0].AI.Objectives; GO!=None; GO=GO.NextObjective )
    {
        GO.DefenderTeamIndex = 1 - CurrentAttackingTeam;
        GO.NetUpdateTime = Level.TimeSeconds - 1;
    }

    if ( bWeakObjectives )
        WeakObjectives();

    HighlightCurrentPhysicalObjectives();

    // re spawn players
    C = Level.ControllerList;
    while ( C != None )
    {
        NextC = C.NextController;

        if ( C.IsA('PlayerController') && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator )
            RestartPlayer( C );

        C = NextC;
    }

    TriggerEvent('StartRound', Self, None);
    if ( !IsPracticeRound() )
        GameEvent("AS_BeginRound", ""$CurrentRound, None);

    SetGameSpeed( GameSpeed );
}

// Modified to fit Trials, we don't care about the team mostly so we will give some love for "defenders".
// Removed:AnnounceScore
// Pair round win logic.
// The game will never officially end instead a round is the "end" with unlimited rounds which have to be instigated by "QuickStart" provided by external mutator(s).
function EndRound(ERER_Reason RoundEndReason, Pawn Instigator, String Reason)
{
    local int					ScoringTeam;
    local PlayerReplicationInfo	PRI;
    local PlayerController		PC;
    local Controller			C, NextC;
    local GameObjective			ObjectiveFocus;
    local bool					bObjectiveHasEndCam;

    // Ignore EndRound during reset countdown
    if( !IsPlaying() )
        return;

    log("ASGameInfo::EndRound - Reason:"@Reason);

    // Find real round end instigator
    if ( LastDisabledObjective != None && LastDisabledObjective.DisabledBy != None )
        PRI = LastDisabledObjective.DisabledBy;
    else if ( Instigator != None )
        PRI = Instigator.PlayerReplicationInfo;

    ObjectiveFocus = GetCurrentObjective();
    SuccessfulAssaultTimeLimit = 0;

    // Reward player who instigated the win!
    if ( PRI != None && PRI.IsA('ASPlayerReplicationInfo') )
    {
        ++ ASPlayerReplicationInfo(PRI).DisabledFinalObjective;
        GameEvent("EndRound_Trophy", "", PRI);
    }

    if( RoundEndReason == ERER_AttackersWin )
    {
        ScoringTeam = CurrentAttackingTeam;
        GameEvent("AS_attackers_win", ""$ScoringTeam, PRI);
    }
    else if( RoundEndReason == ERER_AttackersLose )
    {
        ScoringTeam = 1 - CurrentAttackingTeam;
        GameEvent("AS_defenders_win", ""$ScoringTeam, PRI);
    }

    // Removed AnnounceScore, this will be handled by an external mutator instead.
    SetPairOfRoundWinner();

    // Play End of Round cinematic...
    if ( EndCinematic != None )
    {
        EndCinematic.Trigger( Self, None );
    }
    else
    {
        // If failed to attack display current objective, otherwise, display last disabled (=final one)
        if ( ObjectiveFocus == None && LastDisabledObjective != None )
            ObjectiveFocus = LastDisabledObjective;

        if ( ObjectiveFocus != None )
        {
            ObjectiveFocus.bAlwaysRelevant = true;
            if ( ObjectiveFocus.EndCamera != None && ASCinematic_Camera(ObjectiveFocus.EndCamera) != None )
                bObjectiveHasEndCam = true;

            C = Level.ControllerList;
            while ( C != None  )
            {
                NextC = C.NextController;
                if ( C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator )
                {
                    PC = PlayerController(C);
                    if ( PC != None )
                    {
                        if ( bObjectiveHasEndCam )	// Objective has a special End Cam setup...
                            ASCinematic_Camera(ObjectiveFocus.EndCamera).ViewFixedObjective( PC, ObjectiveFocus );
                        else						// Otherwise, just spectate objective in behindview/freecam
                        {
                            PC.ClientSetViewTarget( ObjectiveFocus );
                            PC.SetViewTarget( ObjectiveFocus );
                        }
                        PC.ClientRoundEnded();
                    }
                    C.RoundHasEnded();
                }
                C = NextC;
            }
        }
    }

    /*
    super(GameInfo).EndGame(None, "roundlimit");
    */

    GotoState( 'MatchOver' );

    TriggerEvent('EndRound', Self, Instigator);

    if( bUnlimitedTrialRounds )
    {
        ResetCountDown = ResetTimeDelay+1;
        QueueAnnouncerSound( NewRoundSound, 1, 255 );
    }
}

function AnnounceScore(int scoringTeam)
{
    // Skip the ASGameInfo version of this.
    super(TeamGame).AnnounceScore(scoringTeam);
}

function SetPairOfRoundWinner()
{
    local byte winningTeam;

    winningTeam = GetPairOfRoundWinner();
    if( winningTeam == 255 )
    {
        return;
    }

    TeamScoreEvent( winningTeam, 1, "pair_of_round_winner" );
}

function BroadCast_AssaultRole_Message(PlayerController C);

function Bool IsPracticeRound()
{
    return false;
}

function AnnounceNextObjective(GameObjective NewObjective)
{
    if ( !IsPlaying() )
        return;

    if ( NewObjective.Announcer_ObjectiveInfo == None )
        QueueAnnouncerSound( '', 1, CurrentAttackingTeam, AP_NoDuplicates, 200 );
    else
        QueueAnnouncerSound( NewObjective.Announcer_ObjectiveInfo.Name, 1, CurrentAttackingTeam, AP_NoDuplicates, 200 );
}

function ShowPathTo(PlayerController P, Int TeamNum)
{
    local GameObjective			G, Best;
    local class<WillowWhisp>	WWclass;
    local ASGameReplicationInfo	ASGRI;

    ASGRI = ASGamereplicationInfo(GameReplicationInfo);

    Best = GetCurrentObjective();
    if ( Best == None || !Best.IsActive() )
    {
        for ( G=Teams[0].AI.Objectives; G!=None; G=G.NextObjective )
            if ( !G.bOptionalObjective && CheckObjectivePriority( G ) )
            {
                Best = G;
                break;
            }
    }

    if ( Best != None )
    {
        // Spawn Willow Whisp
        if ( P.FindPathToward(Best, false) != None )
        {
            WWclass = class<WillowWhisp>(DynamicLoadObject(PathWhisps[TeamNum], class'Class'));
            Spawn(WWclass, P,, P.Pawn.Location);
        }
    }
}

// Disallow team changing.
// But, we still should pick a team so that players can disable objectives :/
function bool ChangeTeam(Controller Other, int N, bool bNewTeam)
{
    local UnrealTeamInfo NewTeam;

    NewTeam = Teams[PickTeam(CurrentAttackingTeam,Other)];

    // check if already on this team
    if ( Other.PlayerReplicationInfo.Team == NewTeam )
        return false;

    Other.StartSpot = None;

    if ( Other.PlayerReplicationInfo.Team != None )
        Other.PlayerReplicationInfo.Team.RemoveFromTeam(Other);

    return NewTeam.AddToTeam(Other);
}

// Keep us in the Assault's Browser
function GetServerInfo(out ServerResponseLine serverState)
{
    super.GetServerInfo(serverState);

    serverState.GameType = "ASGameInfo";
}

// Overwrite hints
static function array<string> GetAllLoadHints(optional bool bThisClassOnly)
{
    return default.TrialHints;
}

// Hack to change LoadingScreen
static function string GetLoadingHint( PlayerController PC, string MapName, Color ColorHint )
{
    local UT2K4ServerLoading Vig;

    foreach PC.AllActors( Class'UT2K4ServerLoading', Vig )
    {
        Vig.Operations.Length = 1;
        Vig.Operations[0] = new Class'UT04Trial_DrawOpImage';
        UT04Trial_DrawOpImage(Vig.Operations[0]).Init( MapName );
        UT04Trial_DrawOpImage(Vig.Operations[0]).Vignette = Vig;
        UT04Trial_DrawOpImage(Vig.Operations[0]).CurMapHint = super.GetLoadingHint(PC,MapName,ColorHint);

        return UT04Trial_DrawOpImage(Vig.Operations[0]).CurMapHint;
    }

    return super.GetLoadingHint(PC,MapName,ColorHint);
}

function GetServerDetails(out ServerResponseLine serverState)
{
    // Skip Assault specific details
    super(DeathMatch).GetServerDetails(serverState);
}

static function FillPlayInfo(PlayInfo playInfo)
{
    super.FillPlayInfo(playInfo);

    // ??
}

static event bool AcceptPlayInfoProperty(string propertyName)
{
    switch (propertyName)
    {
        case "RoundLimit": return false;
        case "ResetTimeDelay": return false;
        case "SpawnProtectionTime": return false;
        case "ReinforcementsFreq": return false;
        case "PracticeTimeLimit": return false;
        case "ReinforcementsValidTime": return false;
        case "bBalanceTeams": return false;
        case "bPlayersBalanceTeams": return false;
        case "FriendlyFireScale": return false;
        case "BotMode": return false;
        case "MinPlayers": return false;
        case "GameDifficulty": return false;
        case "MaxLives": return false;
        case "bWeaponStay": return false;
        case "bAllowWeaponThrowing": return false;
        case "bAdjustSkill": return false;
    }

    return super.AcceptPlayInfoProperty(propertyName);
}

defaultproperties
{
    BeaconName="TR"
    GameName="Trials"
    MapPrefix="AS"
    Acronym="TR"

    Description="Overcome the various trials set in wild environments."
    TrialHints(0)="J = Jump, DJ = Double Jump, WD = Wall Dodge, SD = Side Dodge."
    TrialHints(1)="SJ = Shield Jump, SWD = Shield Wall Dodge, SD = Shield Dodge, S = Shield."
    TrialHints(2)="Use %TOGGLEBEHINDVIEW% for Shield jumping."
    TrialHints(3)="RTR = Regular Trial, STR = Solo Trial and GTR = Group Trial."
    TrialHints(4)="In OpenTrial you have to find all the keys and bring them to the objective."

    GameReplicationInfoClass=class'UT04Trial_GameReplicationInfo'
    ScoreBoardType="XInterface.ScoreBoardDeathMatch"
    MutatorClass="UT04TrialGame.UT04Trial_Mutator"
    PlayerControllerClassName="UT04TrialGame.UT04Trial_Player"
    DefaultPlayerClassName="UT04TrialGame.UT04Trial_Pawn"
    PathWhisps[0]="UT04TrialGame.UT04Trial_WillowWhisp"
    PathWhisps[1]="UT04TrialGame.UT04Trial_WillowWhisp"
    DecoTextName="XGame.Deathmatch"

    // Override all settings that don't suit trials
    SpawnProtectionTime=0
    ReinforcementsFreq=0
    ReinforcementsValidTime=0
    PracticeTimeLimit=0
    EndTimeDelay=30
    RoundTimeLimit=60
    RoundLimit=1
    NetWait=0
    bTeamGame=false
    bBalanceTeams=false
    bAllowNonTeamChat=true
    bAllowBehindView=true
    bScoreTeamKills=false
    bCanChangeSkin=true
    GoalScore=0
    NumRounds=1
    bMustHaveMultiplePlayers=false

    // No bots for trials
    NumBots=0
    bAutoNumBots=true
}
