package;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;

class ImageResolutionHelper
{
    /**
     * Finds the resolution value in DPI stored in a PNG image file.
     * If for any reason the process throws, the resolution will be defaulted to 72 DPI
     */
    public static function findDPIFromPNG(bytes:Bytes):Int
    {
        if(!testPNGHeader(bytes))
        {
            throw("Submitted file is not a valid PNG");
            return -1;
        }

        final marker = findpHYsMarker(bytes);
        if(marker < 1)
            throw("pHYs chunk not found. Defaulting to 72 DPI");

        final ppmX = (bytes.get(marker + 8) << 24) | (bytes.get(marker + 9) << 16) | (bytes.get(marker + 10) << 8) | bytes.get(marker + 11) >>> 0;
        final ppmY = (bytes.get(marker + 12) << 24) | (bytes.get(marker + 13) << 16) | (bytes.get(marker + 14) << 8) | bytes.get(marker + 15) >>> 0;

        if(ppmX != ppmY)
            throw("Horizontal ppm (" + ppmX + ") does not match vertical ppm (" + ppmY + ")");

        // Convert pixels per meter to dots per inch
        return Math.ceil(ppmX / 1000 * 25.4);
    }

    /**
     * Returns a *new* Bytes instance with the specified dpi written to the pHYs chunk.
     * If the pHYs chunk does not exist, it is added
     */
    public static function writeDPIToPNG(bytes:Bytes, dpi:Int):Bytes
    {
        dpi = Math.floor(dpi / 25.4 * 1000);
        final marker = findpHYsMarker(bytes);
        if(marker < 1)
        {
            final buffer = new BytesBuffer();
            final IHDRSize = (bytes.get(8) << 24) | (bytes.get(9) << 16) | (bytes.get(10) << 8) | bytes.get(11) >>> 0;
            final offset = 8 + IHDRSize + 12;
            buffer.addBytes(bytes, 0, offset); // Add the PNG header and IHDR chunk first
            addpHYsToBytes(buffer, dpi);
            buffer.addBytes(bytes, offset, bytes.length - offset);
            bytes = buffer.getBytes();
        }
        else
        {
            bytes = bytes.sub(0, bytes.length);

            bytes.set(marker + 8, dpi >> 24 & 0xFF); // ppmX
            bytes.set(marker + 9, dpi >> 16 & 0xFF);
            bytes.set(marker + 10, dpi >> 8 & 0xFF);
            bytes.set(marker + 11, dpi & 0xFF);

            bytes.set(marker + 12, dpi >> 24 & 0xFF); // ppmY
            bytes.set(marker + 13, dpi >> 16 & 0xFF);
            bytes.set(marker + 14, dpi >> 8 & 0xFF);
            bytes.set(marker + 15, dpi & 0xFF);
        }

        return bytes;
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

    static function findpHYsMarker(bytes:Bytes):Int
    {
        var offset = 8;
        while(offset < bytes.length)
        {
            final chunkLength = (bytes.get(offset) << 24) | (bytes.get(offset + 1) << 16) | (bytes.get(offset + 2) << 8) | bytes.get(offset + 3) >>> 0;
            final chunkType = bytes.getString(offset + 4, 4);
            if(chunkType == "pHYs")
                return offset;

            offset += chunkLength + 12;
        }
        
        return -1;
    }

    static function addpHYsToBytes(buffer:BytesBuffer, dpi:Int):Void
    {
        buffer.addByte(0); // Chunk Size: 9 bytes
        buffer.addByte(0);
        buffer.addByte(0);
        buffer.addByte(9);

        buffer.addString("pHYs"); // Label

        buffer.addByte(dpi >> 24 & 0xFF); // ppmX
        buffer.addByte(dpi >> 16 & 0xFF);
        buffer.addByte(dpi >> 8 & 0xFF);
        buffer.addByte(dpi & 0xFF);

        buffer.addByte(dpi >> 24 & 0xFF); // ppmY
        buffer.addByte(dpi >> 16 & 0xFF);
        buffer.addByte(dpi >> 8 & 0xFF);
        buffer.addByte(dpi & 0xFF);

        buffer.addByte(1);  // Unit Specifier

        buffer.addByte(0x78); // I have no idea what this is, but it needs to be here
        buffer.addByte(0xA5);
        buffer.addByte(0x3F);
        buffer.addByte(0x76);
    }

    // JPG Exif metadata tags
    static inline var ORIENTATION:Int = 274; // 0x0112
    static inline var XRESOLUTION:Int = 282; // 0x011A
    static inline var YRESOLUTION:Int = 283; // 0x011B
    static inline var RESOLUTIONUNIT:Int = 296; // 0x0128

    /**
     * Finds the `XResolution` value in DPI stored in a JPG image file.
     * If for any reason the process throws, the resolution will be defaulted to 72 DPI
     */
    public static function findDPIFromJPG(bytes:Bytes):Int
    {
        if(!testJPGHeader(bytes))
        {
            throw("Submitted file is not a valid JPG");
            return -1;
        }

        try
        {
            // Search the EXIF first
            return tryFromEXIF(bytes);
        }
        catch(error)
        {
            try
            {
                return tryFromJFIF(bytes);
            }
            catch(error2)
            {
                throw error2.message;
            }

            throw error.message;
        }
    }

    static function tryFromJFIF(bytes:Bytes):Int
    {
        var marker = findJFIFMarker(bytes);
        if(bytes.getString(marker, 4) != "JFIF")
            return -1;

        var offset = marker + 7; // Skip the identifier and major/minor versions
        final resUnit = bytes.get(offset);
        final XRes = (bytes.get(offset + 1) << 8) | bytes.get(offset + 2);
        final YRes = (bytes.get(offset + 3) << 8) | bytes.get(offset + 4);

        if(XRes != YRes)
            throw("XResolution (" + XRes + ") does not match YResolution (" + YRes + ")");

        if(resUnit != 1) // DPI
        {
            if(resUnit == 2) // DPCM
                return Math.ceil(XRes / 2.54);
            else
                throw("Unknown unit found in Resolution Unit");
        }

        return XRes;
    }

    // Note: When this function throws an error, it does not close the stream
    static function tryFromEXIF(bytes:Bytes):Int
    {
        final marker = findEXIFMarker(bytes);
        final tiffOffset = marker + 6;
        if(marker < 0)
            throw("JPG Exif chunk could not be found. Defaulting to 72 DPI");

        // Nead to use the stream because it acknowledges endianness
        var stream = new BytesInput(bytes, marker);
        if(stream.readString(4) != "Exif")
            throw("JPG Exif chunk could not be read. Defaulting to 72 DPI");

        stream.position += 2; // Skip to endian determinant

        final endianness = stream.readUInt16();
        if(endianness == 18761) // 0x4949
            stream.bigEndian = false;
        else if(endianness == 19789) // 0x4D4D
            stream.bigEndian = true;
        else
            throw("Could not determine endianness. Defaulting to 72 DPI");

        if(stream.readUInt16() != 42) // 0x002A
            throw("Invalid TIFF data (no 0x002A). Defaulting to 72 DPI");

        final firstIFDOffset = readUInt32(stream);
        if(firstIFDOffset < 8)
            throw("Invalid TIFF data (first offset less than 8). Defaulting to 72 DPI");

        final XRes = findTiffTag(stream, XRESOLUTION, tiffOffset, tiffOffset + firstIFDOffset);
        if(XRes == null)
            throw("XResolution Tiff tag could not be found. Defaulting to 72 DPI");

        final YRes = findTiffTag(stream, YRESOLUTION, tiffOffset, tiffOffset + firstIFDOffset);
        if(YRes == null)
            throw("YResolution Tiff tag could not be found. Defaulting to 72 DPI");

        final resUnit = findTiffTag(stream, RESOLUTIONUNIT, tiffOffset, tiffOffset + firstIFDOffset);
        if(resUnit == null)
            throw("ResolutionUnit Tiff tag could not be found. Defaulting to 72 DPI");

        if(XRes != YRes)
            throw("XResolution (" + XRes + ") does not match YResolution (" + YRes + ")");

        stream.close();

        if(resUnit != 2) // DPI
        {
            if(resUnit == 3) // DPCM
                return Math.ceil(XRes / 2.54);
            else
                throw("Unknown unit found in Resolution Unit");
        }

        return XRes;
    }

    inline static function testJPGHeader(bytes:Bytes):Bool
    {
        return bytes.get(0) == 255 && bytes.get(1) == 216;
    }

    static function findJFIFMarker(bytes:Bytes):Int
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
            if(marker == 224) // 0xE0
            {
                return offset + 4;
            }

            // Skip to the next chunk
            offset += 2 + (bytes.get(offset + 2) << 8) | bytes.get(offset + 3); // readUInt16() equivalent
        }

        return -1;
    }

    /**
     * Finds and returns the position of the JPG Exif marker
     */
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

    /**
     * Iterates through Tiff tags for XResolution, YResolution, and ResolutionUnit,
     * and returns each in a Haxe object
     *
     * @param tiffStart The position in the stream that the Tiff section starts at
     * @param dirStart  The position that the first tiff tag begins at
     */
    static function findTiffTag(stream:BytesInput, tagID:Int, tiffStart:Int, dirStart:Int):Null<Int>
    {
        final position = stream.position;
        final entries = stream.readUInt16();
        var value = null;
        for(i in 0...entries)
        {
            final entryOffset = dirStart + i * 12 + 2;
            stream.position = entryOffset;
            final tag = stream.readUInt16();
            if(tag == tagID)
            {
                value = readTagValue(stream, entryOffset, tiffStart);
                break;
            }
        }

        stream.position = position;
        return value;
    }

    /**
     * Reads the value indicated by a tag's offset value
     *
     * @param entryOffset   The position in the stream of the tag
     * @param tiffStart     The position in the stream that the Tiff section starts at
     */
    static function readTagValue(stream:BytesInput, entryOffset:Int, tiffStart:Int):Int
    {
        final type = stream.readUInt16(); // Should be 3 or 5 for resolution values
        final numValues = readUInt32(stream); // This shouldn't matter for our purpose because it can only BE one number
        final valueOffset = readUInt32(stream) + tiffStart;

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
            return Math.ceil(numerator / denominator);
        }

        throw("Resolution Tiff tag could not be read. Defaulting to 72 DPI");
    }

    /**
     * Pretty much the same as readInt32(), but it forces unsigned behavior
     *
     * This *could* lead to problems if the number exceeds the Int32 max value,
     * but that shouldn't happen in this context
     */
    static function readUInt32(stream:BytesInput):Int
    {
        var ch1 = stream.readByte();
        var ch2 = stream.readByte();
        var ch3 = stream.readByte();
        var ch4 = stream.readByte();
        return stream.bigEndian ? ((ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4) >>> 0 : ((ch4 << 24) | (ch3 << 16) | (ch2 << 8) | ch1) >>> 0;
    }
}
