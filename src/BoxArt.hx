enum abstract BoxArt(String) from String
{
    public var PS1FRONT = "PS1 (Front)";
    public var PS1BACK = "PS1 (Back)";
    public var PS1INLAY = "PS1 (Inlay)";
    public var PS1MULTIDISK = "PS1 Mulit-disk";
    public var PS2 = "PS2";
    public var PS3 = "PS3";
    public var PS4 = "PS4";
    public var PS5 = "PS5";
    
    public var XBOX = "XBox";
    public var XBOX360 = "XBox 360";
    public var XBOXONE = "XBox One";
    public var XBOXSERIESX = "XBox Series X";
    
    public var GAMECUBE = "GameCube";
    public var WII = "Wii";
    public var WIIU = "WiiU";
    public var SWITCH = "Switch";
    public var SWITCH2 = "Switch 2";
    
    public var BLURAY = "BLURAY";
    public var BLURAYSLIM = "BLURAY SLIM";
    public var CDFRONT = "CD (Front)";
    public var CDBACK = "CD (Back)";
    public var CDINLAY = "CD (Inlay)";
    public var CDMULITDISK = "CD Mulit-disk";
    public var DVD = "DVD";
    public var DVDSLIM = "DVD SLIM";

    public var A4 = "A4 (11.7x8.3in)";
    public var B4 = "B4 (13.9x9.8in)";

    public function getDimensions():{width:Float, height:Float}
    {
        return switch(cast this: BoxArt)
        {
            case CDFRONT | PS1FRONT:
                {width: 4.74, height: 4.67}

            case CDBACK | CDINLAY | PS1BACK | PS1INLAY:
                {width: 5.91, height: 4.59}

            case CDMULITDISK | PS1MULTIDISK:
                {width: 5.91, height: 4.61}

            case DVD| GAMECUBE | WII | WIIU | PS2 | XBOX | XBOX360:
                {width: 10.75, height: 7.25}

            case DVDSLIM | SWITCH | SWITCH2:
                {width: 8.24, height: 6.34}

            case BLURAY | PS3:
                {width: 10.7, height: 5.81}

            case BLURAYSLIM | XBOXONE | XBOXSERIESX:
                {width: 10, height: 5.91}

            case PS4 | PS5:
                {width: 10.62, height: 6.69}

            case A4:
                {width: 11.69, height: 8.27}

            case B4:
                {width: 13.9, height: 9.8}

            default:
                {width: -1, height: -1}
        };
    }
}
