import Toybox.Lang;
import Toybox.WatchUi;

class PokitDelegate extends WatchUi.BehaviorDelegate {
    var bleDevice;

    function initialize(device) {
        bleDevice = device;
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new PokitMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    function onNextPage(){
        bleDevice.nextMode();
    }
    function onPreviousPage(){
        bleDevice.previousMode();
    }

}