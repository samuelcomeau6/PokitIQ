import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Timer;
using Toybox.BluetoothLowEnergy as Ble;


class PokitView extends WatchUi.View {
    var bleDevice;
    var reading;
    var reading_mode="Pokit";
    var modeText;
    var readText;
    var counter;
    

    function timerCallback() {
        WatchUi.requestUpdate();
        //counter++;
        //reading = counter.toString();
        reading = compute().toString();
        reading_mode = bleDevice.getModeLabel();
    }

    function initialize(device) {
        View.initialize();
		reading = "Initializing...";
        counter = 0;
        bleDevice = device;
        var myTimer = new Timer.Timer();
        myTimer.start(method(:timerCallback), 100, true);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        modeText = new WatchUi.Text({
            :text=>"Pokit",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_LARGE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_TOP
        });
        readText = new WatchUi.Text({
            :text=>"Initializing.",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_LARGE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });
        //Connect
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        readText.setText(reading);
        modeText.setText(reading_mode);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        modeText.draw(dc);
        readText.draw(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        //delete my text?
    }
    function compute() {
        if(!bleDevice.isConnected()){
            bleDevice.scan();
        }

		if (bleDevice.scanning) {
			return "Scanning...";
		} else if (bleDevice.device == null) {
			return "Not Connected";
		}
		bleDevice.read();
		reading = bleDevice.getReading();

		return reading;
	}

}
