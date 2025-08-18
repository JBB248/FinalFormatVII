package burst.util;

class StringUtil
{
    public static var startsWithNumRegex(default, never):EReg = ~/^\d+/;
    public static var endsWithNumRegex(default, never):EReg = ~/\d+$/;

    public static function compareTo(a:String, b:String):Int
    {
        if(a == b)
            return 0;

        var min = Std.int(Math.min(a.length, b.length));
        for(i in 0...min)
        {
            var ac = a.charCodeAt(i);
            var bc = b.charCodeAt(i);
            if(ac != bc)
                return ac - bc;
        }

        return a.length - b.length;
    }

    public static function startsWithNumber(a:String):Bool
    {
        return startsWithNumRegex.match(a);
    }

    public static function compareToByNumberPrefix(a:String, b:String):Int
    {
        startsWithNumRegex.match(a);
        var data1 = startsWithNumRegex.matchedPos();
        startsWithNumRegex.match(b);
        var data2 = startsWithNumRegex.matchedPos();
        return compareByNumberHelper(a, data1, b, data2);
    }

    public static function endsWithNumber(a:String):Bool
    {
        return endsWithNumRegex.match(a);
    }

    public static function compareToByNumberPostfix(a:String, b:String):Int
    {
        endsWithNumRegex.match(a);
        var data1 = endsWithNumRegex.matchedPos();
        endsWithNumRegex.match(b);
        var data2 = endsWithNumRegex.matchedPos();
        return compareByNumberHelper(a, data1, b, data2);
    }

    static function compareByNumberHelper(a:String, ad:{pos:Int, len:Int}, b:String, bd:{pos:Int, len:Int}):Int
    {
        var str1 = a.substring(0, ad.pos);
        var str2 = b.substring(0, bd.pos);
        if(str1 == str2)
            return Std.parseInt(a.substr(ad.pos, ad.len)) - Std.parseInt(b.substr(bd.pos, bd.len));
        else
            return compareTo(a, b);
    }
}