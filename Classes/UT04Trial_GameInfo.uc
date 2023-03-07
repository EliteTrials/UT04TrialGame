// Coded by 'Eliot van uytfanghe' @ 2009
Class UT04Trial_GameInfo Extends ASGameInfo
	abstract
	cacheexempt;

var const array<string> TrialHints;

var globalconfig bool bUnlimitedTrialRounds;

function Reset()
{
	LastDisabledObjective = none;
	BeginNewPairOfRounds();
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

	if ( IsPracticeRound() )
	{
		ASGameReplicationInfo(GameReplicationInfo).RoundWinner = ERW_PracticeRoundEnded;
		ASGameReplicationInfo(GameReplicationInfo).RoundOverTime = ASGameReplicationInfo(GameReplicationInfo).RoundTimeLimit - ASGameReplicationInfo(GameReplicationInfo).RoundStartTime + RemainingTime;
	}
	else
	{
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
	}

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

function AnnounceScore( int ScoringTeam )
{
	// Skip the ASGameInfo version of this.
	super(TeamGame).AnnounceScore( ScoringTeam );
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

function BroadCast_AssaultRole_Message( PlayerController C )
{
	// DO NOTHING HAHAH FUCKYEAH.jpg
}

// Keep us in the Assault's Browser
Function GetServerInfo( out ServerResponseLine ServerState )
{
	Super.GetServerInfo(ServerState);
	ServerState.GameType = "ASGameInfo";
}

// Overwrite hints
Static Function array<string> GetAllLoadHints( optional bool bThisClassOnly )
{
	return Default.TrialHints;
}

// Hack to change LoadingScreen
Static Function string GetLoadingHint( PlayerController PC, string MapName, Color ColorHint )
{
	local UT2K4ServerLoading Vig;

	ForEach PC.AllActors( Class'UT2K4ServerLoading', Vig )
	{
		Vig.Operations.Length = 1;
		Vig.Operations[0] = new Class'UT04Trial_DrawOpImage';
		UT04Trial_DrawOpImage(Vig.Operations[0]).Init( MapName );
		UT04Trial_DrawOpImage(Vig.Operations[0]).Vignette = Vig;
		UT04Trial_DrawOpImage(Vig.Operations[0]).CurMapHint = Super.GetLoadingHint(PC,MapName,ColorHint);
		return UT04Trial_DrawOpImage(Vig.Operations[0]).CurMapHint;
	}
	return Super.GetLoadingHint(PC,MapName,ColorHint);
}

function GetServerDetails( out ServerResponseLine ServerState )
{
	super(DeathMatch).GetServerDetails( ServerState );
}

static event bool AcceptPlayInfoProperty( string PropertyName )
{
	switch( PropertyName )
	{
		case "RoundLimit":
			return false;

		case "SpawnProtectionTime":
			return false;

		case "ReinforcementsFreq":
			return false;

		case "ReinforcementsValidTime":
			return false;

		case "bBalanceTeams":
			return false;

		case "bPlayersBalanceTeams":
			return false;

		case "FriendlyFireScale":
			return false;
	}
	return super.AcceptPlayInfoProperty( PropertyName );
}

DefaultProperties
{
	BeaconName="TR"
	Acronym="TR"

	MapListType="UT04TrialGame.UT04Trial_MapList"
	GameName="UT04 Trials"
	MapPrefix="STR,GTR,RTR"

	TrialHints(0)="J = Jump, DJ = Double Jump, WD = Wall Dodge, SD = Side Dodge"
	TrialHints(1)="SJ = Shield Jump, SWD = Shield Wall Dodge, SD = Shield Dodge, S = Shield"
	TrialHints(2)="Use %TOGGLEBEHINDVIEW% for Shield jumping"
	TrialHints(3)="RTR = Regular Trial, STR = Solo Trial and GTR = Group Trial"
	TrialHints(4)="In OpenTrial you have to find all the keys then you return to the objective"

    GameReplicationInfoClass=class'UT04Trial_GameReplicationInfo'

	// Override all settings that don't suit trials
	SpawnProtectionTime=0
	ReinforcementsFreq=0
	ReinforcementsValidTime=0
}
