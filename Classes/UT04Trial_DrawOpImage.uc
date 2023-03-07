// Coded by 'Eliot van uytfanghe' @ 2009
Class UT04Trial_DrawOpImage Extends DrawOpImage;

var string CurMapName;
var string CurMapAuthor;
var string CurMapDesc;
var string CurMapHint;
var Material CurMapShot;

var UT2K4ServerLoading Vignette;

Function Init( string MapName )
{
	local LevelSummary Level;
	local int NumItems;

	CurMapName = MapName;

	Level = LevelSummary(DynamicLoadObject( MapName$".LevelSummary", Class'LevelSummary', True ));
	if( Level != None )
	{
		CurMapAuthor = Level.Author;
		CurMapDesc = Level.Description;

		if( MaterialSequence(Level.ScreenShot) != None )
		{
			NumItems = MaterialSequence(Level.ScreenShot).SequenceItems.Length;
			if( NumItems > 0 )
				CurMapShot = MaterialSequence(Level.ScreenShot).SequenceItems[Rand( NumItems )].Material;
		}
		else CurMapShot = Level.ScreenShot;
	}
}

Function Draw( Canvas C )
{
	local float XL, YL;
	local string S;
	local int NumBackgrounds;
	local Material RandBG;

	// BG
	C.SetPos( 0, 0 );
	C.DrawColor = C.MakeColor( 255, 255, 255, 255 );

	C.ColorModulate.X = 0.5;
	C.ColorModulate.Y = 0.5;
	C.ColorModulate.Z = 0.5;

	if( CurMapShot != None )
		C.DrawTile( CurMapShot, C.ClipX, C.ClipY, 0, 0, 512, 256 );
	else
	{
		NumBackgrounds = Vignette.Backgrounds.Length;
		if( NumBackgrounds > 0 )
		{
			RandBG = Vignette.DLOTexture( Vignette.Backgrounds[Rand( NumBackgrounds )] );
			if( RandBG != None )
				C.DrawTile( RandBG, C.ClipX, C.ClipY, 0, 0, 1024, 768 );
		}
	}
	C.ColorModulate = C.Default.ColorModulate;

	//C.DrawColor = C.MakeColor( 255, 255, 255 );

	// BG of title
	S = "Loading "$CurMapName$"...";
	C.Font = GetFont( "GUI2K4.fntUT2k4SmallHeader", C.SizeX );
	C.StrLen( S, XL, YL );
	C.SetPos( 0, (C.ClipY*0.5)-(YL*0.5) );
	C.DrawColor = C.MakeColor( 0, 0, 0, 150 );
	C.Style = 1;
	C.DrawTile( Texture'HudContent.Generic.HUD', C.ClipX, YL+YL, 168, 211, 166, 44 );
	C.Style = 3;

	// Title
	C.SetPos( 16, (C.ClipY*0.5) );
	C.DrawColor = C.MakeColor( 255, 255, 255 );
	C.DrawText( S, True );

	// Info
	if( CurMapAuthor != "" )
	{
		S = "Author"@CurMapAuthor;
		C.StrLen( S, XL, YL );
		C.SetPos( 0, 32-(YL*0.5) );
		C.DrawColor = C.MakeColor( 0, 0, 0, 150 );
		C.Style = 1;
		C.DrawTile( Texture'HudContent.Generic.HUD', C.ClipX, YL+YL, 168, 211, 166, 44 );
		C.Style = 3;

		C.SetPos( 16, 32 );
		C.DrawColor = C.MakeColor( 255, 255, 255 );
		C.DrawText( S, True );
	}

	if( CurMapDesc != "" )
	{
		C.StrLen( CurMapDesc, XL, YL );
		C.SetPos( 0, (C.ClipY*0.25)-(YL*0.5) );
		C.DrawColor = C.MakeColor( 0, 0, 0, 150 );
		C.Style = 1;
		C.DrawTile( Texture'HudContent.Generic.HUD', C.ClipX, YL+(YL*0.5), 168, 211, 166, 44 );
		C.Style = 3;

		C.SetPos( 16, C.ClipY*0.25 );
		C.DrawColor = C.MakeColor( 255, 255, 255 );
		C.DrawText( CurMapDesc, True );
	}

	if( CurMapHint != "" )
	{
		C.StrLen( CurMapHint, XL, YL );
		C.SetPos( 0, (C.ClipY*0.75)-(YL*0.5) );
		C.DrawColor = C.MakeColor( 0, 0, 0, 150 );
		C.Style = 1;
		C.DrawTile( Texture'HudContent.Generic.HUD', C.ClipX, YL+YL, 168, 211, 166, 44 );
		C.Style = 3;

		C.SetPos( 16, C.ClipY*0.75 );
		C.DrawColor = C.MakeColor( 255, 255, 255 );
		C.DrawText( CurMapHint, True );
	}
}
