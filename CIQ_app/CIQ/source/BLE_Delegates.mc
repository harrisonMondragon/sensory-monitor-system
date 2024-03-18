import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;

using Toybox.BluetoothLowEnergy as BLE;

class Delegate extends BLE.BleDelegate {
    // Callback class for BLE functions and state changes
    // Delegate initialized in CIQAPP.mc
    var sensorScanResult = null;

    // Sensor UUIDs
    public const SERVICE_UUID = BluetoothLowEnergy.stringToUuid("5d390f04-f945-4b02-9e4a-307f6a53b492");
    const SOUND_UUID = BLE.stringToUuid("d7df8570-d653-4ff9-a473-0352de9d0e7c");
    const TEMP_UUID = BLE.stringToUuid("c4c7df1d-9cd1-4c15-aeb6-bdd362d8d344");

    // Device connection info
    var device;

    function initialize() {
        BleDelegate.initialize();
        registerProfiles(); // register custom profiles
    }

    function onScanResults(scanResults) {
        // Within scanning time period, check each scan result for specified
        // sensor information (hard coded UUID for MVP) and connect.
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            if (result instanceof BLE.ScanResult) {
                var iter = result.getServiceUuids();
                for (var uuid = iter.next(); uuid != null; uuid = iter.next()) {
                    if (uuid.equals(SERVICE_UUID)) {
                        sensorScanResult = result;
                    }
                }
            }
        }
    }

    function onConnectedStateChanged(device, state) {
        if (state == BLE.CONNECTION_STATE_CONNECTED) {
            self.device = device;

            // Subscribe to sound notifications
            var sound_desc = device.getService(SERVICE_UUID).getCharacteristic(SOUND_UUID).getDescriptor(BLE.cccdUuid());
            sound_desc.requestWrite([0x01, 0x00]b);

            // Need to either delay oe queue requestWrite calls, see:
            // https://forums.garmin.com/developer/connect-iq/f/discussion/258434/how-to-do-multiple-successive-btle-characteristic-requestwrite/1234530#1234530
            var subscribeDelayTimer = new Timer.Timer();
            subscribeDelayTimer.start(method(:subscribeDelayDone), 10000, false);

            WatchUi.switchToView(new Connecting(), new SensoryBehaviorDelegate(new BLEScanner(), null), WatchUi.SLIDE_IMMEDIATE);
        } else {
            self.device = null;
            SUBSCRIPTION_COUNT = 0;
            WatchUi.switchToView(new SensorDisconnected(), new SensoryBehaviorDelegate(new BLEScanner(), null), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // Subscribe to temp notifications after a delay between sound subscription
    function subscribeDelayDone() as Void{
        System.println("Finished subscribe delay");
        var temp_desc = device.getService(SERVICE_UUID).getCharacteristic(TEMP_UUID).getDescriptor(BLE.cccdUuid());
        temp_desc.requestWrite([0x01, 0x00]b);
    }

    function onDescriptorWrite(descriptor, status) {
        if (status == BLE.STATUS_WRITE_FAIL) {
            System.println("Failed subscribe to a notification.");
        }
        else if (status == BLE.STATUS_SUCCESS) {
            SUBSCRIPTION_COUNT = SUBSCRIPTION_COUNT + 1;
            System.println("Subscribed to " + SUBSCRIPTION_COUNT + " notification(s).");
            if (SUBSCRIPTION_COUNT >= 2){
                WatchUi.switchToView(new HomeDisplay(), new SensoryBehaviorDelegate(null, null), WatchUi.SLIDE_IMMEDIATE);
            }
        }
    }

    function onCharacteristicChanged(char, val) {
        if(char.getUuid().equals(TEMP_UUID)){
            System.println("Temp changed to: " + val);
            TEMP_VAL = val[0];
        }

        else if (char.getUuid().equals(SOUND_UUID)){
            System.println("Sound changed to: " + val);
            SOUND_LEVEL = val[0];
        }
        WatchUi.requestUpdate(); // update what ever watch face is displayed
    }

    function getScanResult() {
        return sensorScanResult;
    }

    function connect () {
        BLE.setScanState(BLE.SCAN_STATE_OFF);
        BLE.pairDevice(sensorScanResult);
    }

    function registerProfiles() {
       var profile = {                     // Set the Profile
           :uuid => SERVICE_UUID,
           :characteristics => [
                    {         // Define the characteristics
                    :uuid => SOUND_UUID,     // UUID of the first characteristic
                    :descriptors => [       // Descriptors of the characteristic
                        BLE.cccdUuid()
                    ]
                    },
                    {
                    :uuid => TEMP_UUID,
                    :descriptors => [
                        BLE.cccdUuid()
                    ]
                    },
                       ]
       };

       // Make the registerProfile call
       BLE.registerProfile( profile );
    }
}