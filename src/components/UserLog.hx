package components;

import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;

class UserLog extends ScrollView
{
    static var _instance:UserLog;

    public static function addMessage(message:String):Void
    {
        var label = new Label();
        label.text = "- " + message;
        label.customStyle.width = _instance.width - 20;
        _instance.addComponent(label);
    }

    public static function addWarning(message:String):Void
    {
        var label = new Label();
        label.text = '<font color="#FFB000">[*] ${message}</font>';
        label.customStyle.width = _instance.width - 20;
        _instance.addComponent(label);
    }

    public static function addError(message:String):Void
    {
        var label = new Label();
        label.text = '<font color="#C02317">[!] ${message}</font>';
        label.customStyle.width = _instance.width - 20;
        _instance.addComponent(label);
    }

    public static function addDivider():Void
    {
        var divider = new Box();
        divider.customStyle.width = _instance.width - 20;
        divider.customStyle.height = 1;
        divider.customStyle.backgroundColor = 0xFF454C56;
        _instance.addComponent(divider);
    }

    public function new()
    {
        super();

        _instance = this;
    }
}