Class UT04Trial_DrawOpImage Extends DrawOpImage;

var Material CurMapShot;

Function Init(string MapName)
{
    local LevelSummary Level;
    local int NumItems, StartIndex, ItemIndex, i;

    CurMapShot = None;
    Level = LevelSummary(DynamicLoadObject(MapName$".LevelSummary", Class'LevelSummary', True));
    if (Level == None)
        return;

    if (MaterialSequence(Level.ScreenShot) != None)
    {
        NumItems = MaterialSequence(Level.ScreenShot).SequenceItems.Length;
        if (NumItems > 0)
        {
            StartIndex = Rand(NumItems);
            for (i = 0; i < NumItems; i++)
            {
                ItemIndex = (StartIndex + i) % NumItems;
                CurMapShot = MaterialSequence(Level.ScreenShot).SequenceItems[ItemIndex].Material;
                if (CurMapShot != None)
                    break;
            }
        }
    }
    else CurMapShot = Level.ScreenShot;
}

function DrawSolidRect(Canvas C, float X, float Y, float W, float H, Color FillColor)
{
    if (W <= 0 || H <= 0)
        return;

    C.SetPos(X, Y);
    C.Style = 1;
    C.DrawColor = FillColor;
    C.DrawTile(Texture'Engine.WhiteTexture', W, H, 0, 0, Texture'Engine.WhiteTexture'.USize, Texture'Engine.WhiteTexture'.VSize);
}

function DrawOutline(Canvas C, float X, float Y, float W, float H, float Thickness, Color BorderColor)
{
    DrawSolidRect(C, X, Y, W, Thickness, BorderColor);
    DrawSolidRect(C, X, Y + H - Thickness, W, Thickness, BorderColor);
    DrawSolidRect(C, X, Y + Thickness, Thickness, H - Thickness * 2, BorderColor);
    DrawSolidRect(C, X + W - Thickness, Y + Thickness, Thickness, H - Thickness * 2, BorderColor);
}

function Draw(Canvas C)
{
    local float PanelX, PanelY, PanelW, PanelH, MarginX, MarginY;
    local float ImageX, ImageY, ImageW, ImageH, ImageAspect, ViewAspect;
    local float SourceU, SourceV, SourceUSize, SourceVSize, Border;
    local Color BackColor, BorderColor, ShadowColor;

    if (C.ClipX <= 0 || C.ClipY <= 0)
        return;

    PanelW = C.ClipX * 0.37;
    PanelH = C.ClipY * 0.28;
    MarginX = C.ClipX * 0.01;
    MarginY = C.ClipY * 0.03;
    PanelX = C.ClipX - PanelW - MarginX;
    PanelY = C.ClipY - PanelH - MarginY;
    Border = 2;

    BackColor = C.MakeColor(0, 0, 0, 255);
    BorderColor = C.MakeColor(175, 181, 190, 255);
    ShadowColor = C.MakeColor(16, 18, 22, 255);

    // Keep a fully opaque backing for map shots that contain transparent pixels.
    DrawSolidRect(C, PanelX, PanelY, PanelW, PanelH, BackColor);

    ImageX = PanelX + Border;
    ImageY = PanelY + Border;
    ImageW = PanelW - Border * 2;
    ImageH = PanelH - Border * 2;
    DrawSolidRect(C, ImageX, ImageY, ImageW, ImageH, BackColor);

    if (CurMapShot != None)
    {
        SourceU = 0;
        SourceV = 0;
        SourceUSize = CurMapShot.MaterialUSize();
        SourceVSize = CurMapShot.MaterialVSize();
        if (SourceUSize > 0 && SourceVSize > 0)
        {
            ImageAspect = SourceUSize / SourceVSize;
            ViewAspect = ImageW / ImageH;

            // Crop the longer dimension so the preview fills the whole frame without distortion.
            if (ImageAspect > ViewAspect)
            {
                SourceUSize = SourceVSize * ViewAspect;
                SourceU = (CurMapShot.MaterialUSize() - SourceUSize) * 0.5;
            }
            else if (ImageAspect < ViewAspect)
            {
                SourceVSize = SourceUSize / ViewAspect;
                SourceV = (CurMapShot.MaterialVSize() - SourceVSize) * 0.5;
            }

            C.SetPos(ImageX, ImageY);
            C.Style = 1;
            C.DrawColor = C.MakeColor(255, 255, 255, 255);
            C.DrawTile(CurMapShot, ImageW, ImageH, SourceU, SourceV, SourceUSize, SourceVSize);
        }
    }

    DrawOutline(C, PanelX, PanelY, PanelW, PanelH, Border, ShadowColor);
    DrawOutline(C, PanelX + 1, PanelY + 1, PanelW - 2, PanelH - 2, 1, BorderColor);
}
