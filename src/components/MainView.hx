package components;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.dialogs.OpenFileDialog;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.StageQuality;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.net.URLRequest;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("src/components/main.xml"))
class MainView extends UIState
{
    var coverBitmap:BitmapData;
    var coverBitmapName:String;

	override public function create():Void
	{
        add(new flixel.addons.display.FlxBackdrop(new DebugSquare(0, 0)));

        super.create();
	}

    override function onReady():Void
    {
        imagePathButton.registerEvent(MouseEvent.CLICK, loadFrontBoxArt);
    }

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

    function loadFrontBoxArt(_):Void
    {
        openFileSelectDialog(function(button:DialogButton, selectedFiles:Array<SelectedFileInfo>)
        {
            if(button != DialogButton.OK) return;

            var fileInfo = selectedFiles[0];
            if(fileInfo.name.length > 25)
                fileInfo.name = "..." + fileInfo.name.substring(fileInfo.name.length - 25, fileInfo.name.length);

            imagePathButton.text = '<font color="#1E8BF0">${fileInfo.name}</font>';
            imagePathButton.userData = {fullPath: fileInfo.fullPath, name: fileInfo.name};

            displaySelectedFileInfo(fileInfo);

            exportButton.disabled = false;
        });
    }

    function openFileSelectDialog(callback:(DialogButton, Array<SelectedFileInfo>) -> Void):Void
    {
        new OpenFileDialog({
            readContents: true,
            readAsBinary: true,
            multiple: false,
            extensions: [{label: "Image Files", extension: "png, jpeg, jpg"}]}, callback).show();
    }

    function displaySelectedFileInfo(fileInfo:SelectedFileInfo):Void
    {
        var dpi = 72;
        var bytes = fileInfo.bytes;
        var path = fileInfo.fullPath.toLowerCase();
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

        exportButton.disabled = false;

        // Make sure we don't clog memory
        if(coverBitmap != null)
            coverBitmap.dispose();

        coverBitmap = BitmapData.fromBytes(bytes);
        coverBitmapName = fileInfo.name;
        UserLog.addMessage(
            'Successfully loaded <font color="#1E8BF0">' + 
            coverBitmap.width + 'x' + coverBitmap.height + 
            '</font> px image with a resolution of <font color="#1E8BF0">' + dpi + '</font> DPI');
    }

    @:bind(launchButton, MouseEvent.CLICK)
    function onFindCoversButtonPressed(_):Void
        Lib.getURL(new URLRequest("https://www.thecoverproject.net/"), "_blank");

    @:bind(outputCoverType, UIEvent.CHANGE)
    function outputCoverTypeChanged(_):Void
    {
        // This is how you would access the dropdown's list. Horrible
        // @:privateAccess var listview = cast(outputCoverType._compositeBuilder, DropDownBuilder).handler.component;
        
        // FORCE the dropdown to redraw itself so that the stupid text doesn't get cut off in the middle
        // I'd like to just flag the listview as invalid layout, but that doesn't seem to do anything
        // This will work even though it's stupid
        outputCoverType.dropdownWidth = outputCoverType.dropdownWidth == 100 ? 105 : 100;
    }

    @:bind(stretchChecker, UIEvent.CHANGE)
    function onStretchCheckerChanged(_):Void
        guidesChecker.disabled = !stretchChecker.selected;

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

        var exportBitmapData = new BitmapData(digitalPageWidth, digitalPageHeight, false);

        var realCoverSize = PageSizeHelper.getDimensionsFromString(outputCoverType.selectedItem.text);
        if(realCoverSize.width < 1 || realCoverSize.height < 1)
            return UserLog.addError("The selected cover size has no internal data");

        final digitalCoverWidth = Math.ceil(realCoverSize.width * dpi);
        final digitalCoverHeight = Math.ceil(realCoverSize.height * dpi);

        var matrix = new Matrix();
        matrix.scale(digitalCoverWidth / coverBitmap.rect.width, digitalCoverHeight / coverBitmap.rect.height);
        matrix.translate((digitalPageWidth - digitalCoverWidth) / 2, (digitalPageHeight - digitalCoverHeight) / 2);
        exportBitmapData.drawWithQuality(coverBitmap, matrix, null, null, null, true, StageQuality.BEST);
        // Draw borders
        exportBitmapData.fillRect(new Rectangle((digitalPageWidth - digitalCoverWidth) / 2 - 5, 0, 5, digitalPageHeight), 0xFF000000);
        exportBitmapData.fillRect(new Rectangle(0, (digitalPageHeight - digitalCoverHeight) / 2 - 5, digitalPageWidth, 5), 0xFF000000);
        exportBitmapData.fillRect(new Rectangle(digitalPageWidth - (digitalPageWidth - digitalCoverWidth) / 2, 0, 5, digitalPageHeight), 0xFF000000);
        exportBitmapData.fillRect(new Rectangle(0, digitalPageHeight - (digitalPageHeight - digitalCoverHeight) / 2, digitalPageWidth, 5), 0xFF000000);

        var bytes = ImageResolutionHelper.writeDPIToPNG(exportBitmapData.encode(exportBitmapData.rect, new PNGEncoderOptions()), dpi);
        var dialog = new SaveFileDialog({
                title: "Save Formatted Cover Art",
                writeAsBinary: true
            }, 
            (button, result, fullPath) -> {
                if(button != DialogButton.OK) return;
                exportBitmapData.dispose(); // Get rid of the export bitmap in memory
                Dialogs.messageBox('File saved to ${fullPath}!', "Save Result", MessageBoxType.TYPE_INFO);
            });

        var split = imagePathButton.userData.name.split(".");
        split.pop(); // Remove extension
        dialog.fileInfo = {
            name: outputPageType.selectedItem.text + "-" + dpi + "-" + split.join("") + ".png",
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
