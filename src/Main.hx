package;

import flixel.FlxGame;
import flixel.util.typeLimit.NextState;

import haxe.ui.Toolkit;

class Main extends openfl.display.Sprite
{
    var initialState:InitialState = components.MainView.new;

	public function new()
	{
		super();

        initHaxeUI();

		addChild(new FlxGame(0, 0, initialState, 60, 60, true));

        flixel.FlxG.mouse.useSystemCursor = true;
	}

    function initHaxeUI():Void
    {
        Toolkit.init();
        Toolkit.theme = "dark-compact";
        Toolkit.autoScale = false;

        haxe.ui.focus.FocusManager.instance.autoFocus = false;
        haxe.ui.tooltips.ToolTipManager.defaultDelay = 800;
    }
}
