package components;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.OpenFileDialog;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.events.MouseEvent;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class MainState extends UIState
{
    var dialog:OpenFileDialog;

    var coverBitmap:BitmapData;

	override public function create()
	{
        add(new flixel.addons.display.FlxBackdrop(new DebugSquare(0, 0)));
        // add(sizeOutlineSprite);
        // add(coverSprite);

        super.create();

        dialog = new OpenFileDialog();
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
        try
        {
            if(path.endsWith("png"))
                dpi = ImageResolutionHelper.findDPIFromPNG(bytes);
            else if(path.endsWith(".jpg") || path.endsWith("jpeg"))
                dpi = ImageResolutionHelper.findDPIFromJPG(bytes);
            else if(path.endsWith("gif"))
                return UserLog.addError("gif file extension will not be supported. Please convert the image into png, or jpg");
            else if(path.endsWith("bmp"))
                return UserLog.addError("bmp file extension is not currently supported. Please convert the image into png, or jpg");
            else
                return UserLog.addError("Invalid file submitted. Please submit a png or jpg file");
        }
        catch(error)
        {
            UserLog.addWarning(error.message);
        }

        // Make sure we don't clog memory
        if(coverBitmap != null)
            coverBitmap.dispose();

        coverBitmap = BitmapData.fromBytes(bytes);
        imageNameLabel.text = '<font color="#1E8BF0">${dialog.selectedFiles[0].name}</font>';
        imageNameLabel.tooltip = dialog.selectedFiles[0].fullPath;
        UserLog.addMessage(
            'Successfully loaded <font color="#1E8BF0">${coverBitmap.width}x${coverBitmap.height}</font> px image with a resolution of <font color="#1E8BF0">${dpi}</font> DPI');
    }

    @:bind(loadButton, MouseEvent.CLICK)
    function onLoadButtonPressed(_):Void
        dialog.show();

    @:bind(exportButton, MouseEvent.CLICK)
    function onExportButtonPressed(_):Void
    {
        var fwidth:Float = PageDimensions.A4X;
        var fheight:Float = PageDimensions.A4Y;

        if(outputPageType.selectedItem == "B4")
        {
            fwidth = PageDimensions.B4X;
            fheight = PageDimensions.B4Y;
        }

        final dpi = Std.parseInt(outputDpi.text);
        final width = Math.ceil(dpi * fwidth);
        final height = Math.ceil(dpi * fheight);

        var exBitmapData = new BitmapData(width, height, false);

        var swidth:Float = PageDimensions.PS3X;
        var sheight:Float = PageDimensions.PS3Y;

        if(outputPageType.selectedItem == "Wii")
        {
            swidth = PageDimensions.WIIX;
            sheight = PageDimensions.WIIY;
        }

        var stretchBitmap = new Bitmap(coverBitmap);
        stretchBitmap.width = Math.ceil(swidth * dpi);
        stretchBitmap.height = Math.ceil(sheight * dpi);

        var offsetX = 0;
        var offsetY = 0;

        exBitmapData.draw(stretchBitmap);
        var bytes = exBitmapData.encode(exBitmapData.rect, new PNGEncoderOptions());
        var saveDialog = new SaveFileDialog({
            writeAsBinary: true,
            extensions: [{label: "Image Files", extension: "png, jpeg, jpg"}]
        });

        saveDialog.fileInfo = {
            bytes: bytes,
            isBinary: true
        };
        saveDialog.onDialogClosed = function(event:DialogEvent) {
            if(event.button != DialogButton.OK) return;
        };

        saveDialog.show();
    }

    override function destroy():Void
    {
        super.destroy();
    }
}

@:bitmap("base-grid-debug.png") class DebugSquare extends openfl.display.BitmapData { }
