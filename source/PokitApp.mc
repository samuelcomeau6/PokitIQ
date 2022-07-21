import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.BluetoothLowEnergy as Ble;

class PokitApp extends Application.AppBase {
    var bleDevice;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        bleDevice = new BleDevice();
		Ble.setDelegate(bleDevice);
		bleDevice.open();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new PokitView(bleDevice), new PokitDelegate(bleDevice) ] as Array<Views or InputDelegates>;
    }

}

function getApp() as PokitApp {
    return Application.getApp() as PokitApp;
}