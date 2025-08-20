package;

import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.OpenFileDialog;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class PlayState extends haxe.ui.backend.flixel.UIState
{
    var dialog = new OpenFileDialog();

    var coverSprite:FlxSprite;

	override public function create()
	{
        coverSprite = new FlxSprite();
        coverSprite.kill(); //why create something only to immeditely kill it-- this is the programming equivalant of an abortion

        add(new flixel.addons.display.FlxBackdrop(new DebugSquare(0, 0)));
        add(coverSprite);

        super.create();

        dialog.onDialogClosed = loadCoverArt;
        dialog.options = {
            readContents: true,
            readAsBinary: true,
            multiple: false,
            extensions: FileDialogTypes.IMAGES,
            title: "Select Cover Art"
        };
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

    function loadCoverArt(event:DialogEvent):Void
    {
        if(event.button != DialogButton.OK) return;

        coverSprite.loadGraphic(BitmapData.fromBytes(dialog.selectedFiles[0].bytes));
        coverSprite.revive();
        centerCoverSprite();
    }

    function centerCoverSprite():Void
    {
        coverSprite.setGraphicSize(0, (FlxG.height - topBox.height) * 0.9);
        coverSprite.updateHitbox();
        coverSprite.x = FlxG.width * 0.5 - coverSprite.width * 0.5;
        coverSprite.y = topBox.height + (FlxG.height - topBox.height) * 0.5 - coverSprite.height * 0.5;
    }

    @:bind(loadButton, MouseEvent.CLICK)
    function onLoadButtonPressed(_):Void
        dialog.show();

    override function destroy():Void
    {
        super.destroy();
    }
}

@:bitmap("base-grid-debug.png") class DebugSquare extends openfl.display.BitmapData { }
