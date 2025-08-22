package;

import components.UserLog;

import haxe.io.Bytes;
import haxe.io.BytesInput;

class ImageResolutionHelper
{
    public static function fromPNG(bytes:Bytes):Int
    {
        if(!testPNGHeader(bytes))
        {
            UserLog.addError("Submitted file is not a valid PNG");
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
            UserLog.addWarning("pHYs chunk not found. Defaulting to 72 DPI");
            return 72;
        }

        if(ppmX != ppmY)
            UserLog.addWarning("Horizontal ppm (" + ppmX + ") does not match vertical ppm (" + ppmY + ")");

        // Convert pixels per meter to dots per inch
        return Math.ceil(ppmX / 1000 * 25.4);
    }

    inline static function testPNGHeader(bytes:Bytes):Bool
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

    static final XR = 282; // 0x012A
    static final YR = 283; // 0x012B
    static final RU = 296; // 0x0128

    public static function fromJPG(bytes:Bytes):Int
    {
        if(!testJPGHeader(bytes))
        {
            UserLog.addError("Submitted file is not a valid JPG");
            return -1;
        }

        var start = findEXIFMarker(bytes);
        if(start < 0)
        {
            UserLog.addWarning("JPG Exif chunk could not be found. Defaulting to 72 DPI");
            return 72;
        }

        var stream = new BytesInput(bytes, start);
        if(stream.readString(4) != "Exif")
        {
            UserLog.addWarning("JPG Exif chunk could not be read. Defaulting to 72 DPI");
            return 72;
        }

        stream.position += 2; // Skip to endian determinant

        var endianness = stream.readUInt16();
        if(endianness == 18761) // 0x4949
            stream.bigEndian = false;
        else if(endianness == 19789) // 0x4D4D
            stream.bigEndian = true;
        else
        {
            UserLog.addWarning("Could not determine endianness. Defaulting to 72 DPI");
            return 72;
        }

        if(stream.readUInt16() != 42) // 0x002A
        {
            UserLog.addWarning("Invalid TIFF data. Defaulting to 72 DPI");
            return 72;
        }

        return findResolutionTiffTag(stream);
    }

    static function findEXIFMarker(bytes:Bytes):Int
    {
        var offset = 2;
        while(offset < bytes.length)
        {
            if(bytes.get(offset) != 255) // 0xFF
            {
                trace("Not a valid marker at offset: " + offset + ". Found: " + bytes.get(offset));
                return -1;
            }

            final marker = bytes.get(offset + 1);
            if(marker == 225) // 0xE1
            {
                return offset + 4;
            }

            // Skip to the next chunk
            offset += 2 + (bytes.get(offset + 2) << 8) | bytes.get(offset + 3);
        }

        return -1;
    }

    static function findResolutionTiffTag(stream:BytesInput):Int
    {
        return -1;
    }

    inline static function testJPGHeader(bytes:Bytes):Bool
    {
        return bytes.get(0) == 255 && bytes.get(1) == 216;
    }
}
