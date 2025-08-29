class PageSizeHelper
{
    public static function getDimensionsFromString(type:String):{width:Float, height:Float}
    {
        return switch(type)
        {
            case CDFRONT | PS1FRONT:
                {width: CDFRONTX, height: CDFRONTX}

            case CDBACK | CDINLAY | PS1BACK | PS1INLAY:
                {width: CDBACKX, height: CDBACKY}

            case CDMULITDISK | PS1MULTIDISK:
                {width: MULITCDX, height: MULITCDY}

            case DVD| GAMECUBE | WII | WIIU | PS2 | XBOX | XBOX360:
                {width: DVDX, height: DVDY}

            case DVDSLIM | SWITCH | SWITCH2:
                {width: DVDSLIMX, height: DVDSLIMY}

            case BLURAY | PS3:
                {width: BLURAYX, height: BLURAYY}

            case BLURAYSLIM | XBOXONE | XBOXSERIESX:
                {width: BLURAYSLIMX, height: BLURAYSLIMY}

            case PS4 | PS5:
                {width: BLURAYPS4X, height: BLURAYPS4Y}

            case A4:
                {width: A4X, height: A4Y}

            case B4:
                {width: B4X, height: B4Y}

            default:
                {width: -1, height: -1}
        };
    }
}

private enum abstract BoxArtCovers(String) to String
{
    var PS1FRONT = "PS1 (Front)";
    var PS1BACK = "PS1 (Back)";
    var PS1INLAY = "PS1 (Inlay)";
    var PS1MULTIDISK = "PS1 Mulit-disk";
    var PS2 = "PS2";
    var PS3 = "PS3";
    var PS4 = "PS4";
    var PS5 = "PS5";
    
    var XBOX = "XBox";
    var XBOX360 = "XBox 360";
    var XBOXONE = "XBox One";
    var XBOXSERIESX = "XBox Series X";
    
    var GAMECUBE = "GameCube";
    var WII = "Wii";
    var WIIU = "WiiU";
    var SWITCH = "Switch";
    var SWITCH2 = "Switch 2";
    
    var BLURAY = "BLURAY";
    var BLURAYSLIM = "BLURAY SLIM";
    var CDFRONT = "CD (Front)";
    var CDBACK = "CD (Back)";
    var CDINLAY = "CD (Inlay)";
    var CDMULITDISK = "CD Mulit-disk";
    var DVD = "DVD";
    var DVDSLIM = "DVD SLIM";

    var A4 = "A4 (11.7x8.3in)";
    var B4 = "B4 (13.9x9.8in)"; 
}

private enum abstract CoverDimensions(Float) to Float
{
    var CDFRONTX = 4.74; // CD Jewel Front, PS1 Front
    var CDFRONTY = 4.67;

    var CDBACKX = 5.91; // CD Jewel Back and Rear Inlay, PS1 Back
    var CDBACKY = 4.59;

    var MULITCDX = 5.91; // Multi CD Jewel (All sides)
    var MULITCDY = 4.61;

    var DVDX = 10.75; // GameCube, Wii, WiiU, PS1 DVD, PS2, Xbox, Xbox360
    var DVDY = 7.25;

    var DVDSLIMX = 8.24; // Switch 1 & 2
    var DVDSLIMY = 6.34;

    var BLURAYX = 10.7; // PS3
    var BLURAYY = 5.81;

    var BLURAYSLIMX = 10; // Xbox One, Xbox series X
    var BLURAYSLIMY = 5.91;

    var BLURAYPS4X = 10.62; // PS4, PS5
    var BLURAYPS4Y = 6.69;

    var UMDX = 0.0; // PSP
    var UMDY = 0.0;

    var VITAX = 0.0; // PS Vita
    var VITAY = 0.0;

    var A4X = 11.69;
    var A4Y = 8.27;

    var B4X = 13.9;
    var B4Y = 9.8;
}
