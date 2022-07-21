// vim: syntax=c

using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;

const DEVICE_NAME = "PokitPro";
const DEVICE_NAME_Z = "Pro";
const MM_SERVICE = Ble.stringToUuid("e7481d2f-5781-442e-bb9a-fd4e3441dadc");
const MM_SET_CHAR = Ble.stringToUuid("53dc9a7a-bc19-4280-b76b-002d0e23b078");
const MM_READINGS_CHAR = Ble.stringToUuid("047d3559-8bee-423a-b229-4417fa603b90");
//hidden const LBS_BUTTON_DESC = Ble.cccdUuid();

class BleDevice extends Ble.BleDelegate {
	var scanning = false;
	var device = null;
	var reading = 0;
	var scan_delay = 1;
	var parameter = "Vac";

	hidden function debug(str) {
		//System.println("[ble] " + str);
	}

	function initialize() {
		BleDelegate.initialize();
		debug("initialize");
	}

	function isConnected(){
		return (device!=null);
	}

	function setParameter(p){
		parameter = p;
	}

	function getParameter(){
		return parameter;
	}

	function nextMode(){
		switch(parameter){
			case "Vdc":
				parameter = "Vac";
				break;
			case "Vac":
				parameter = "temperature";
				break;
			case "temperature":
				parameter = "Vdc";
				break;
			default:
				parameter = "Vac";
				break;
		}
	}

	function startReading(parameter){
		//Writes to device
		debug("startReading:begin: "+parameter);
		var service;
		var ch;
		var status;
		var value = []b;
		service = device.getService(MM_SERVICE);
		ch = service.getCharacteristic(MM_SET_CHAR);
		switch(parameter){
			case "Vdc":
				value.add(1);//DC voltage
				value.add(255);//Autorange
				value.add(0);//Interval 1
				value.add(0);//Interval 2
				value.add(0);//Interval 3
				value.add(50);//Interval 4
				debug("startReading: about to write: "+value);
			break;
			case "Vac":
				value.add(2);//AC voltage
				value.add(255);//Autorange
				value.add(0);//Interval 1
				value.add(0);//Interval 2
				value.add(0);//Interval 3
				value.add(50);//Interval 4
				debug("startReading: about to write: "+value);
			break;
			case "temperature":
				//Temp
				value.add(8);//Temp
				value.add(0);//NA
				value.add(0);//Interval 1
				value.add(0);//Interval 2
				value.add(3);//Interval 3
				value.add(240);//Interval 4
				debug("startReading: about to write: "+value);
			break;
		}
		try{
			ch.requestWrite(value,{:writeType => Ble.WRITE_TYPE_WITH_RESPONSE});
			debug("startReading: write success");
		} catch (ex) {
			debug("startReading: can't start char read");
		}
	}
	function onCharacteristicWrite(ch, status){
		var status_str = status ? "failed" : "success";
		debug("onCharacteristicWrite:" +ch.getUuid() + " status:" +status+"-"+status_str);
	}
	function onCharacteristicRead(ch, status, value) {
		debug("char read " + ch.getUuid() + " " + value);
		if (ch.getUuid().equals(MM_READINGS_CHAR)) {
			debug("onCharacteristicChanged: about to update");
			//reading = value[5];
			if(value[5]==0){
				startReading(parameter);
			}
			reading = value.decodeNumber(NUMBER_FORMAT_FLOAT,{:offset => 1});
			debug("onCharacteristicRead: parameter=" + parameter);
			debug("onCharacteristicRead: old reading is " + reading);
			if(parameter.equals("temperature")){
				reading = reading*1.8+32.0;
				debug("onCharacteristicRead: new reading is " + reading);
			}
			startReading(parameter);
		}
	}

	function read(){
		var service;
		var ch;
		debug("setReadingNotifications: start");
		if (device == null) {
			debug("setReadingNotifications: not connected");
			return;
		}
		service = device.getService(MM_SERVICE);
		ch = service.getCharacteristic(MM_READINGS_CHAR);
		debug("setReadingNotifications: requesting read");
		try{
			ch.requestRead();
			debug("setReadingNotifications: read requested");
		} catch (ex){
			debug("setReadingNotifications: read request failed:"+ex.getErrorMessage());
			//ex.printStackTrace();
			//debug("");
		}

	}
	function getReading(){
		return reading;
	}

	function onProfileRegister(uuid, status) {
		debug("registered: " + uuid + " " + status);
	}

	function registerProfiles() {
		debug("registerProfiles: registering profile");
		var profile = {
			:uuid => MM_SERVICE,
			:characteristics => [{
				:uuid => MM_SET_CHAR,
                        }, {
				:uuid => MM_READINGS_CHAR,
				//:descriptors => [LBS_BUTTON_DESC],
			}]
		};

		BluetoothLowEnergy.registerProfile(profile);
	}

	function onScanStateChange(scanState, status) {
		debug("scanstate: " + scanState + " " + status);
		if (scanState == Ble.SCAN_STATE_SCANNING) {
			scanning = true;
		} else {
			scanning = false;
		}
	}

	function onConnectedStateChanged(device, state) {
		debug("connected: " + device.getName() + " " + state);
		if (state == Ble.CONNECTION_STATE_CONNECTED) {
			self.device = device;
			//TODO put the initialization code here
			//setButtonNotifications(1);
			debug("onConnectedStateChanged: startReading(voltage)");
			startReading(parameter);
			debug("onConnectedStateChanged: setReadingNotifications()");
			read();
		} else {
			self.device = null;
			debug("onConnectedStateChanged: not connected");
		}
	}

	private function connect(result) {
		debug("connect");
		Ble.setScanState(Ble.SCAN_STATE_OFF);
		Ble.pairDevice(result);
		debug("connect: paired");
	}

	private function dumpUuids(iter) {
		for (var x = iter.next(); x != null; x = iter.next()) {
			debug("uuid: " + x);
		}
	}

	private function dumpMfg(iter) {
		for (var x = iter.next(); x != null; x = iter.next()) {
			debug("mfg: companyId: " + x.get(:companyId) + " data: " + x.get(:data));
		}
	}

	function onScanResults(scanResults) {
		debug("scan results");
		var appearance, name, rssi;
		var mfg, uuids, service;
		for (var result = scanResults.next(); result != null; result = scanResults.next()) {
			appearance = result.getAppearance();
			name = result.getDeviceName();
			rssi = result.getRssi();
			mfg = result.getManufacturerSpecificDataIterator();
			uuids = result.getServiceUuids();

			debug("device: appearance: " + appearance + " name: " + name + " rssi: " + rssi);
			dumpUuids(uuids);
			dumpMfg(mfg);

			if (rssi>-60) {
				reading = "Connecting..";
				connect(result);
				return;
			}
		}
	}

	function open() {
		registerProfiles();
	}

	function scan() {
		if (scan_delay == 0) {
			return;
		}

		debug(scan_delay);

		scan_delay--;
		if (scan_delay) {
			return;
		}

		debug("scan on");
		reading = "Scanning..";
		Ble.setScanState(Ble.SCAN_STATE_SCANNING);
	}

	function close() {
		debug("close");
		if (scanning) {
			Ble.setScanState(Ble.SCAN_STATE_OFF);
		}
		if (device != null) {
			Ble.unpairDevice(device);
		}
	}
}
