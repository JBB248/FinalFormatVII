package;

import flixel.FlxG;
import flixel.FlxSprite;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.OpenFileDialog;
import haxe.ui.events.MouseEvent;

import openfl.display.BitmapData;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class PlayState extends UIState
{
    var dialog = new OpenFileDialog();

    var coverSprite:FlxSprite;

	override public function create()
	{
        coverSprite = new FlxSprite();
        coverSprite.kill();

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

        var dpi = -1;
        var bytes = dialog.selectedFiles[0].bytes;
        var path = dialog.selectedFiles[0].fullPath.toLowerCase();
        if(path.endsWith("png"))
        {
            dpi = DPIInterpreter.fromPNG(bytes);
        }
        else if(path.endsWith("gif"))
        {
            trace("gif file extension is not supported. Please convert the image into png, or jpg");
            return;
        }
        else if(path.endsWith("bmp"))
        {
            trace("bmp file extension is not supported. Please convert the image into png, or jpg");
            return;
        }
        else
        {
            trace("Invalid file submitted");
            return;
        }

        dpiLabel.text = "DPI: " + dpi;

        var bitmap = BitmapData.fromBytes(bytes);
        coverSprite.loadGraphic(bitmap);
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
