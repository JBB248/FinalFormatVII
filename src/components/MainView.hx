package components;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.dialogs.OpenFileDialog;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.events.MouseEvent;

import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.net.URLRequest;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class MainView extends UIState
{
    var dialog:OpenFileDialog;

    var coverBitmap:BitmapData;
    var coverBitmapName:String;

	override public function create():Void
	{
        add(new flixel.addons.display.FlxBackdrop(new DebugSquare(0, 0)));

        super.create();

        dialog = new OpenFileDialog();
        dialog.onDialogClosed = loadCoverArt;
        dialog.options = {
            readContents: true,
            readAsBinary: true,
            multiple: false,
            extensions: [{label: "Image Files", extension: "png, jpeg, jpg"}],
            title: "Select Cover Art"
        };

        trace(outputCoverType.actualComponentWidth);
	}

	override public function update(elapsed:Float):Void
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
            dpi = 72;
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

    @:bind(launchButton, MouseEvent.CLICK)
    function onFindCoversButtonPressed(_):Void
        Lib.getURL(new URLRequest("https://www.thecoverproject.net/"), "_blank");

    @:bind(exportButton, MouseEvent.CLICK)
    function onExportButtonPressed(_):Void
    {
        if(coverBitmap == null)
            return UserLog.addError("No"); // For now

        var realPageSize = PageSizeHelper.getDimensionsFromString(outputPageType.selectedItem.text);
        if(realPageSize.width < 1 || realPageSize.height < 1)
            return UserLog.addError("The selected page size has no internal data");

        final dpi = Std.parseInt(outputDpi.text);
        final digitalPageWidth = Math.ceil(dpi * realPageSize.width);
        final digitalPageHeight = Math.ceil(dpi * realPageSize.height);

        var exBitmapData = new BitmapData(digitalPageWidth, digitalPageHeight, false);

        var realCoverSize = PageSizeHelper.getDimensionsFromString(outputCoverType.selectedItem.text);
        if(realCoverSize.width < 1 || realCoverSize.height < 1)
            return UserLog.addError("The selected cover size has no internal data");

        final digitalCoverWidth = Math.ceil(realCoverSize.width * dpi);
        final digitalCoverHeight = Math.ceil(realCoverSize.height * dpi);

        var stretchBitmap = new Bitmap(coverBitmap);
        stretchBitmap.width = digitalCoverWidth;
        stretchBitmap.height = digitalCoverHeight;

        final offsetX = (digitalPageWidth - digitalCoverWidth) / 2;
        final offsetY = (digitalPageHeight - digitalCoverHeight) / 2;

        exBitmapData.draw(stretchBitmap, new Matrix(1, 0, 0, 1, offsetX, offsetY));

        var bytes = ImageResolutionHelper.writeDPIToPNG(exBitmapData.encode(exBitmapData.rect, new PNGEncoderOptions()), dpi);
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
            name: outputPageType.selectedItem.text + "-" + split.join("") + ".png",
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
