class PageSizeHelper
{
    public static function getDimensionsFromString(type:String):{width:Float, height:Float}
    {
        return switch(type)
        {
            case "CD (Front)" | "PS1 (Front)":
                {width: CoverDimensions.CDFRONTX, height: CoverDimensions.CDFRONTX}

            case "CD (Back)" | "CD (Inlay)" | "PS1 (Back)" | "PS1 (Inlay)":
                {width: CoverDimensions.CDBACKX, height: CoverDimensions.CDBACKY}

            case "CD Mulit-disk" | "PS1 Mulit-disk":
                {width: CoverDimensions.MULITCDX, height: CoverDimensions.MULITCDY}

            case "DVD" | "GameCube" | "Wii" | "WiiU" | "PS2" | "XBox" | "XBox 360":
                {width: CoverDimensions.DVDX, height: CoverDimensions.DVDY}

            case "DVD SLIM" | "Switch" | "Switch 2":
                {width: CoverDimensions.DVDSLIMX, height: CoverDimensions.DVDSLIMY}

            case "BLURAY" | "PS3":
                {width: CoverDimensions.BLURAYX, height: CoverDimensions.BLURAYY}

            case "BLURAY SLIM" | "XBox One" | "XBox Series X":
                {width: CoverDimensions.BLURAYSLIMX, height: CoverDimensions.BLURAYSLIMY}

            case "PS4" | "PS5":
                {width: CoverDimensions.BLURAYPS4X, height: CoverDimensions.BLURAYPS4Y}

            case "A4 (11.7x8.3in)":
                {width: CoverDimensions.A4X, height: CoverDimensions.A4Y}

            case "B4 (13.9x9.8in)":
                {width: CoverDimensions.B4X, height: CoverDimensions.B4Y}

            default:
                {width: -1, height: -1}
        };
    }
}

enum abstract CoverDimensions(Float) to Float
{
    var CDFRONTX = 4.74; // CD Jewel Front, PS1 Front
    var CDFRONTY = 4.67;

    var CDBACKX = 5.91; // CD Jewel Back and Rear Inlay, PS1 Back
    var CDBACKY = 4.59;

    var MULITCDX = 5.91; // Multi CD Jewel (All sides)
    var MULITCDY = 4.61;

    var DVDX = 10.75; // GameCube, Wii, WiiU, PS1 DVD, PS2, Xbox, Xbox360
    var DVDY = 7.25;

    var DVDSLIMX = 10.47; // Switch 1 & 2
    var DVDSLIMY = 7.2;

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
