import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Timer;

using Toybox.BluetoothLowEnergy as BLE;

class Delegate extends BLE.BleDelegate {
    // Callback class for BLE functions and state changes
    // Delegate initialized in CIQAPP.mc
    var sensorScanResult = null;
    var queue;

    // Sensor UUIDs
    public const SERVICE_UUID = BluetoothLowEnergy.stringToUuid("5d390f04-f945-4b02-9e4a-307f6a53b492");
    const SOUND_UUID = BLE.stringToUuid("d7df8570-d653-4ff9-a473-0352de9d0e7c");
    const TEMP_UUID = BLE.stringToUuid("c4c7df1d-9cd1-4c15-aeb6-bdd362d8d344");

    // Device connection info
    var device;

    function initialize() {
        BleDelegate.initialize();
        registerProfiles(); // register custom profiles
        queue = new Sub2NotifQueue();
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
            var sound_char = device.getService(SERVICE_UUID).getCharacteristic(SOUND_UUID);
            var temp_char = device.getService(SERVICE_UUID).getCharacteristic(TEMP_UUID);

            // Queue characteristics for subscription
            queue.add(sound_char);
            queue.add(temp_char);

            queue.run(); // begin subscription process

            WatchUi.switchToView(new Connecting(), new SensoryBehaviorDelegate(new BLEScanner(), null), WatchUi.SLIDE_IMMEDIATE);
        } else {
            SENSORY_ACTIVITY_SESSION.stop();
            SENSORY_ACTIVITY_SESSION.discard();
            self.device = null;
            SUBSCRIPTION_COUNT = 0;
            WatchUi.switchToView(new SensorDisconnected(), new SensoryBehaviorDelegate(new BLEScanner(), null), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onDescriptorWrite(descriptor, status) {
        if (status == BLE.STATUS_WRITE_FAIL) {
            System.println("Failed subscribe to a notification.");
        }
        else if (status == BLE.STATUS_SUCCESS) {
            SUBSCRIPTION_COUNT = SUBSCRIPTION_COUNT + 1;
            System.println("Subscribed to " + SUBSCRIPTION_COUNT + " notification(s).");
            if (SUBSCRIPTION_COUNT >= 2){ // subscribed to our chars
                SENSORY_ACTIVITY_SESSION.start();
                WatchUi.switchToView(new HomeDisplay(), new SensoryBehaviorDelegate(null, null), WatchUi.SLIDE_IMMEDIATE);
            } else { // still missing one
                queue.run();
            }
        }
    }

    function onCharacteristicChanged(char, val) {
        if(char.getUuid().equals(TEMP_UUID)){
            TEMP_VAL = val.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {});
            // System.println("Temp changed to: " + TEMP_VAL);

            // Record data in the session
            TEMP_VALUE_FIELD.setData(TEMP_VAL);
            if (TEMP_MIN_THRESHOLD != null){
                TEMP_MIN_THRESH_FIELD.setData(TEMP_MIN_THRESHOLD);
            }
            if (TEMP_MAX_THRESHOLD != null){
                TEMP_MAX_THRESH_FIELD.setData(TEMP_MAX_THRESHOLD);
            }
        }

        else if (char.getUuid().equals(SOUND_UUID)){
            SOUND_VAL = val.decodeNumber(NUMBER_FORMAT_UINT8, {});
            // System.println("Sound changed to: " + SOUND_VAL);

            // Record data in the session
            SOUND_VALUE_FIELD.setData(SOUND_VAL);
            if (SOUND_THRESHOLD != null){
                SOUND_THRESH_FIELD.setData(SOUND_THRESHOLD);
            }
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
