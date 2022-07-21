// vim: syntax=c

using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;

const DEVICE_NAME = "PokitPro";
const DEVICE_NAME_Z = "Pro";
const MM_SERVICE = Ble.stringToUuid("e7481d2f-5781-442e-bb9a-fd4e3441dadc");
const MM_SET_CHAR = Ble.stringToUuid("53dc9a7a-bc19-4280-b76b-002d0e23b078");
const MM_READINGS_CHAR = Ble.stringToUuid("047d3559-8bee-423a-b229-4417fa603b90");
const CCCD = Ble.cccdUuid();

class BleDevice extends Ble.BleDelegate {
	const UPDATE_INTERVAL = 100;
	var scanning = false;
	var device = null;
	var reading = 0;
	var scan_delay = 1;
	enum {MODE_IDLE=0, MODE_VDC=1, MODE_VAC, MODE_IDC, MODE_IAC, MODE_RESIST, MODE_DIODE, MODE_CONT, MODE_TEMP}
	enum {RANGE_AUTO=255}
	var mode = MODE_VAC;

	hidden function debug(str) {
		System.println("[ble] " + str);
	}

	function initialize() {
		BleDelegate.initialize();
		debug("initialize");
	}

	function isConnected(){
		return (device!=null);
	}

	function setMode(p){
		mode = p;
	}

	function getMode(){
		return mode;
	}
	function getModeLabel(){
		switch(mode){
			case 0:
				return "Error/Idle";
			case 1:
				return "DC Voltage";
			case 2:
				return "AC Voltage";
			case 3:
				return "DC Current";
			case 4:
				return "AC Current";
			case 5:
				return "Resistance";
			case 6:
				return "Diode";
			case 7:
				return "Continuity";
			case 8:
				return "Temperature";
			default:
				return "Pokit";
		}		
	}

	function nextMode(){
		mode++;
		if(mode > 8 || mode < 1){
			mode=1;
		}
	}
	function previousMode(){
		mode--;
		if(mode > 8 || mode < 1){
			mode=8;
		}
	}

	function startReading(mode){
		//Writes to device
		debug("startReading:begin: "+mode);
		var service;
		var ch;
		var status;
		var value = []b;
		service = device.getService(MM_SERVICE);
		ch = service.getCharacteristic(MM_SET_CHAR);
		switch(mode){
			case MODE_VDC:
			case MODE_VAC:
			case MODE_IAC:
			case MODE_IDC:
			case MODE_RESIST:
			case MODE_DIODE:
			case MODE_CONT:
			case MODE_TEMP:
				value.add(mode);
				value.add(RANGE_AUTO);//Autorange
				value.add(0);//Interval 1
				value.add(0);//Interval 2
				value.add(0);//Interval 3
				value.add(UPDATE_INTERVAL);//Interval 4
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
			debug("onCharacteristicRead: about to update");
			if(value[5]==0){
				mode=0;
			}
			reading = value.decodeNumber(NUMBER_FORMAT_FLOAT,{:offset => 1});
			debug("onCharacteristicRead: mode=" + mode);
			startReading(mode);
		}
	}
	function onCharacteristicChanged(ch, value){
		debug("char change " + ch.getUuid() + " " + value);
		if (ch.getUuid().equals(MM_READINGS_CHAR)) {
			debug("onCharacteristicChanged: about to update");
			if(value[5]==0){
				mode=0;
			}
			reading = value.decodeNumber(NUMBER_FORMAT_FLOAT,{:offset => 1});
		}
	}
	function notify(){
		var service;
		var ch;
		var cd;
		debug("notify(): start");
		if (device == null) {
			debug("notify(): not connected");
			return;
		}
		service = device.getService(MM_SERVICE);
		ch = service.getCharacteristic(MM_READINGS_CHAR);
		cd = ch.getDescriptor(CCCD);
		try{
			cd.requestWrite([0x01,0x00]b);
			debug("notify(): notify requested");
		} catch (ex){
			debug("notify(): notify request failed:"+ex.getErrorMessage());
		}

	}
	function read(){
		var service;
		var ch;
		var cd;
		debug("read(): start");
		if (device == null) {
			debug("read: not connected");
			return;
		}
		service = device.getService(MM_SERVICE);
		ch = service.getCharacteristic(MM_READINGS_CHAR);
		debug("read(): requesting read");
		try{
			ch.requestRead();
			debug("read(): read requested");
		} catch (ex){
			debug("read(): read request failed:"+ex.getErrorMessage());
			//ex.printStackTrace();
			//debug("");
		}

	}
	function getReading(){
		if(mode==MODE_TEMP){
			var temp = reading*1.8+32.0;
			return temp;
		}
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
				:descriptors => [CCCD],
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
			startReading(mode);
			debug("onConnectedStateChanged: read()()");
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
