package components;

import haxe.ui.components.Label;
import haxe.ui.containers.ScrollView;

class UserLog extends ScrollView
{
    static var _instance:UserLog;

    public static function addMessage(message:String):Void
    {
        var label = new Label();
        label.text = message;
        label.wordWrap = true;
        _instance.addComponent(label);
    }

    public static function addWarning(message:String):Void
    {
        var label = new Label();
        label.text = '<font color="#FFB000">[*] ${message}</font>';
        label.customStyle.width = _instance.width;
        _instance.addComponent(label);
    }

    public static function addError(message:String):Void
    {
        var label = new Label();
        label.text = '<font color="#C02317">[!] ${message}</font>';
        label.customStyle.width = _instance.width;
        _instance.addComponent(label);
    }

    public function new()
    {
        super();

        _instance = this;
    }
}