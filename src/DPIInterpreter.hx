package;

import haxe.io.Bytes;

class DPIInterpreter
{
    public static function fromPNG(bytes:Bytes):Int
    {
        if(!testPNGHeader(bytes))
        {
            trace("PNG Header is invalid");
            return -1;
        }

        var offset = 8;
        var ppmX = -1;
        var ppmY = -1;
        while(offset < bytes.length)
        {
            final chunkLength = (bytes.get(offset) << 24) | (bytes.get(offset + 1) << 16) | (bytes.get(offset + 2) << 8) | bytes.get(offset + 3);
            final chunkType = bytes.getString(offset + 4, 4);
            if(chunkType == "pHYs")
            {
                ppmX = (bytes.get(offset + 8) << 24) | (bytes.get(offset + 9) << 16) | (bytes.get(offset + 10) << 8) | bytes.get(offset + 11);
                ppmY = (bytes.get(offset + 12) << 24) | (bytes.get(offset + 13) << 16) | (bytes.get(offset + 14) << 8) | bytes.get(offset + 15);
                break;
            }

            offset += chunkLength + 12;
        }

        if(ppmX < 0 || ppmY < 0)
        {
            trace("pHYs chunk not found. Defaulting to 72 DPI");
            return 72;
        }

        if(ppmX != ppmY)
            trace("Horizontal ppm (" + ppmX + ") does not match vertical ppm (" + ppmY + ")");

        // Convert pixels per meter to dots per inch
        return Math.ceil(ppmX / 1000 * 25.4);
    }

    inline static function testPNGHeader(bytes):Bool
    {
        return bytes.get(0) == 137
            && bytes.get(1) == 80
            && bytes.get(2) == 78
            && bytes.get(3) == 71
            && bytes.get(4) == 13
            && bytes.get(5) == 10
            && bytes.get(6) == 26
            && bytes.get(7) == 10;
    }
}
