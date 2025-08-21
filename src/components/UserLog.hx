package components;

import haxe.ui.components.TextField;

class UserLog extends TextField
{
    static var _instance:UserLog;

    public static function addMessage(message:String):Void
    {
        _instance.text += message + "\n";
    }

    public function new()
    {
        super();

        _instance = this;
    }
}