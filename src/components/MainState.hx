package components;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.dialogs.OpenFileDialog;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.events.MouseEvent;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.JPEGEncoderOptions;
import openfl.geom.Matrix;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class MainState extends UIState
{
    var dialog:OpenFileDialog;

    var coverBitmap:BitmapData;
    var coverBitmapName:String;

	override public function create()
	{
        add(new flixel.addons.display.FlxBackdrop(new DebugSquare(0, 0)));

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
        coverBitmapName = dialog.selectedFiles[0].name;
        imageNameLabel.text = '<font color="#1E8BF0">${dialog.selectedFiles[0].name}</font>';
        imageNameLabel.tooltip = dialog.selectedFiles[0].fullPath;
        UserLog.addMessage(
            'Successfully loaded <font color="#1E8BF0">${coverBitmap.width}x${coverBitmap.height}</font> px image with a resolution of <font color="#1E8BF0">${dpi}</font> DPI');

        exportButton.disabled = false;
    }

    @:bind(loadButton, MouseEvent.CLICK)
    function onLoadButtonPressed(_):Void
        dialog.show();

    @:bind(exportButton, MouseEvent.CLICK)
    function onExportButtonPressed(_):Void
    {
        if(coverBitmap == null)
            return UserLog.addError("No"); // For now

        var realPageWidth:Float = PageDimensions.A4X;
        var realPafeHeight:Float = PageDimensions.A4Y;

        if(outputPageType.selectedItem == "B4")
        {
            realPageWidth = PageDimensions.B4X;
            realPafeHeight = PageDimensions.B4Y;
        }

        final dpi = Std.parseInt(outputDpi.text);
        final digitalPageWidth = Math.ceil(dpi * realPageWidth);
        final digitalPageHeight = Math.ceil(dpi * realPafeHeight);

        var exBitmapData = new BitmapData(digitalPageWidth, digitalPageHeight, false);

        var realCoverWidth:Float = PageDimensions.PS3X;
        var realCoverHeight:Float = PageDimensions.PS3Y;

        if(outputPageType.selectedItem == "Wii")
        {
            realCoverWidth = PageDimensions.WIIX;
            realCoverHeight = PageDimensions.WIIY;
        }

        var digitalCoverWidth = Math.ceil(realCoverWidth * dpi);
        var digitalCoverHeight = Math.ceil(realCoverHeight * dpi);

        var stretchBitmap = new Bitmap(coverBitmap);
        stretchBitmap.width = digitalCoverWidth;
        stretchBitmap.height = digitalCoverHeight;

        var offsetX = (digitalPageWidth - digitalCoverWidth) / 2;
        var offsetY = (digitalPageHeight - digitalCoverHeight) / 4;

        exBitmapData.draw(stretchBitmap, new Matrix(1, 0, 0, 1, offsetX, offsetY));

        var bytes = exBitmapData.encode(exBitmapData.rect, new JPEGEncoderOptions(100));
        var dialog = new SaveFileDialog();
        dialog.options = {
            title: "Save Formatted Cover Art",
            writeAsBinary: true
        }
        dialog.onDialogClosed = function(event) {
            if(event.button != DialogButton.OK) return;

            // Get rid of the export bitmap in memory
            exBitmapData.dispose();

            Dialogs.messageBox("File saved!", "Save Result", MessageBoxType.TYPE_INFO);
        }
        var split = coverBitmapName.split(".");
        split.pop(); // Remove extension
        dialog.fileInfo = {
            name: outputPageType.selectedItem.text + "-" + split.join("") + ".jpg",
            bytes: bytes
        }
        dialog.show();
    }

    override function destroy():Void
    {
        super.destroy();
    }
}

@:bitmap("base-grid-debug.png") class DebugSquare extends openfl.display.BitmapData { }
