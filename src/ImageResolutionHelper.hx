package;

import components.UserLog;

import haxe.Int64;
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
            // Should be 32 bit, but we can't hold that and it shouldn't get that high anyways
            final chunkLength = (bytes.get(offset + 2) << 8) | bytes.get(offset + 3);
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

    // JPG Exif metadata tags
    static inline var XRESOLUTION:Int = 282; // 0x011A
    static inline var YRESOLUTION:Int = 283; // 0x011B

    static inline var RESOLUTIONUNIT:Int = 296; // 0x0128
    static inline var INCHES:Int = 2;
    static inline var CENTIMETERS:Int = 3;

    public static function fromJPG(bytes:Bytes):Int
    {
        if(!testJPGHeader(bytes))
        {
            UserLog.addError("Submitted file is not a valid JPG");
            return -1;
        }

        final start = findEXIFMarker(bytes);
        final tiffOffset = start + 6;
        if(start < 0)
        {
            UserLog.addWarning("JPG Exif chunk could not be found. Defaulting to 72 DPI");
            return 72;
        }

        // Nead to use the stream because it acknowledges endianness
        var stream = new BytesInput(bytes, start);
        if(stream.readString(4) != "Exif")
        {
            UserLog.addWarning("JPG Exif chunk could not be read. Defaulting to 72 DPI");
            return 72;
        }

        stream.position += 2; // Skip to endian determinant

        final endianness = stream.readUInt16();
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
            UserLog.addWarning("Invalid TIFF data (no 0x002A). Defaulting to 72 DPI");
            return 72;
        }

        final firstIFDOffset = readUInt32(stream).low; // We can cut off the high bits because the offset shouldn't be greater than 2^32
        if(firstIFDOffset < 8)
        {
            UserLog.addWarning("Invalid TIFF data (first offset less than 8). Defaulting to 72 DPI");
            return 72;
        }

        final data = findResolutionTiffTag(stream, tiffOffset, tiffOffset + firstIFDOffset);
        if(data.XRes != data.YRes)
            UserLog.addWarning("XResolution (" + data.XRes + ") does not match YResolution (" + data.YRes + ")");

        if(data.ResUnit != INCHES)
        {
            if(data.ResUnit == CENTIMETERS)
            {
                // Convert it
            }
            else
            {
                // Unknown unit, who knows
            }
        }

        stream.close();
        return data.XRes;
    }

    inline static function testJPGHeader(bytes:Bytes):Bool
    {
        return bytes.get(0) == 255 && bytes.get(1) == 216;
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
            offset += 2 + (bytes.get(offset + 2) << 8) | bytes.get(offset + 3); // readUInt16() equivalent
        }

        return -1;
    }

    static function findResolutionTiffTag(stream:BytesInput, tiffStart:Int, dirStart:Int):{XRes:Int, YRes:Int, ResUnit:Int}
    {
        stream.position = dirStart;
        final entries = stream.readUInt16();
        final data = {
            XRes: -1,
            YRes: -1,
            ResUnit: -1
        };

        for(i in 0...entries)
        {
            final entryOffset = dirStart + i * 12 + 2;
            stream.position = entryOffset;
            final tag = stream.readUInt16();
            if(tag == XRESOLUTION)
                data.XRes = readTagValue(stream, entryOffset, tiffStart);
            else if(tag == YRESOLUTION)
                data.YRes = readTagValue(stream, entryOffset, tiffStart);
            else if(tag == RESOLUTIONUNIT)
                data.ResUnit = readTagValue(stream, entryOffset, tiffStart);
        }

        if(data.XRes == -1)
        {
            UserLog.addWarning("XResolution Tiff tag could not be found. Defaulting to 72 DPI");
            data.XRes = 72;
        }
        if(data.YRes == -1)
        {
            UserLog.addWarning("YResolution Tiff tag could not be found. Defaulting to 72 DPI");
            data.XRes = 72;
        }
        if(data.ResUnit == -1)
        {
            UserLog.addWarning("ResolutionUnit Tiff tag could not be found. Defaulting to Inches");
            data.XRes = 2;
        }

        return data;
    }

    static function readTagValue(stream:BytesInput, entryOffset:Int, tiffStart:Int):Int
    {
        final type = stream.readUInt16(); // Should be 3 or 5 for resolution values
        final numValues = readUInt32(stream); // This shouldn't matter for our purpose because it can only BE one number
        final valueOffset = readUInt32(stream).low + tiffStart;

        if(type == 3) // Short
        {
            stream.position = entryOffset + 8;
            return stream.readUInt16();
        }
        else if(type == 5) // Rational: Two Longs, numerator and denominator
        {
            stream.position = valueOffset;
            final numerator = readUInt32(stream);
            final denominator = readUInt32(stream);
            return (numerator / denominator).low;
        }

        UserLog.addWarning("Resolution Tiff tag could not be read. Defaulting to 72 DPI");
        return 72;
    }

    /**
     * The Haxe basic Int is 32bit and cannot correctly store a UInt32.
     * Int64 should be able to hold the correct value
     */
    static function readUInt32(stream:BytesInput):Int64
    {
        var ch1 = stream.readByte();
        var ch2 = stream.readByte();
        var ch3 = stream.readByte();
        var ch4 = stream.readByte();
        return stream.bigEndian ? Int64.make(ch2 | (ch1 << 8), ch4 | (ch3 << 8)) : Int64.make(ch4 | (ch3 << 8), ch2 | (ch1 << 8));
    }
}
