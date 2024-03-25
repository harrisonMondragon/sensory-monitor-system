import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.BluetoothLowEnergy as BLE;
using Toybox.FitContributor;
using Toybox.ActivityRecording;

// ------------------------------ GLOBALS ------------------------------
// Current Values
var SOUND_VAL;
var TEMP_VAL;
var SUBSCRIPTION_COUNT = 0;
var SETTINGS_AVAILABLE = false;

// Default Thresholds
var SOUND_THRESHOLD = 80; // max sound threshold in dB
var TEMP_MIN_THRESHOLD = 20; // min temperature threshold in ˚C
var TEMP_MAX_THRESHOLD = 35; // max temperature threshold in ˚C

// Threshold Ranges
var SOUND_THRESH_RANGE_LOW = 5; // Lowest available sound threshold in dB
var SOUND_THRESH_RANGE_HI = 200; // Highest available sound threshold in dB
var TEMP_THRESH_RANGE_LOW = -20; // Lowest available temp threshold in ˚C
var TEMP_THRESH_RANGE_HI = 40; // Highest available temp threshold in ˚C

// Threshold Picker Increments
var SOUND_THRESH_INCREMENT = 5; // Sound threshold increment for the picker in dB
var TEMP_THRESH_INCREMENT = 1; // Temp threshold increment for the picker in ˚C

// Enum of back pickers for threshold change confirmation page
enum BACK_PICKERS {
    SOUND_PICKER,
    TEMP_MIN_PICKER,
    TEMP_MAX_PICKER,
}

// Delays
var NOTIFICATION_DELAY = 15000; // notification delay in ms
var VIBE_DURATION = 2000; // vibration duration in ms

// Delegates
var BLE_DELEGATE;

// Activity variables for historical plotting
var SENSORY_ACTIVITY_SESSION;
var SOUND_VALUE_FIELD;
var SOUND_THRESH_FIELD;
var TEMP_VALUE_FIELD;
var TEMP_MIN_THRESH_FIELD;
var TEMP_MAX_THRESH_FIELD;

// ------------------------------ CLASSES ------------------------------
class CIQApp extends Application.AppBase {

    private var _view;

    function initialize() {
        AppBase.initialize();
        _view = new BLEScanner();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        // set up/check BLE connection here
        BLE_DELEGATE = new Delegate();
        BLE.setDelegate(BLE_DELEGATE);

        // Setup activity session
        SENSORY_ACTIVITY_SESSION = ActivityRecording.createSession({:sport=>Activity.SPORT_GENERIC, :name=>"Sensory Overload Monitor"});
        SOUND_VALUE_FIELD = SENSORY_ACTIVITY_SESSION.createField("Current Sound Value", 1, FitContributor.DATA_TYPE_UINT8, {:mesgType => FitContributor.MESG_TYPE_RECORD});
        SOUND_THRESH_FIELD = SENSORY_ACTIVITY_SESSION.createField("Maximum Sound Threshold", 2, FitContributor.DATA_TYPE_UINT8, {:mesgType => FitContributor.MESG_TYPE_RECORD});
        TEMP_VALUE_FIELD = SENSORY_ACTIVITY_SESSION.createField("Current Temperature Value", 3, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_RECORD});
        TEMP_MIN_THRESH_FIELD = SENSORY_ACTIVITY_SESSION.createField("Minimum Temperature Threshold", 4, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_RECORD});
        TEMP_MAX_THRESH_FIELD = SENSORY_ACTIVITY_SESSION.createField("Maximum Temperature Threshold", 5, FitContributor.DATA_TYPE_FLOAT, {:mesgType => FitContributor.MESG_TYPE_RECORD});
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        SENSORY_ACTIVITY_SESSION.stop();
        SENSORY_ACTIVITY_SESSION.save();
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ _view ] as Array<Views or InputDelegates>; // use home view var
    }

}

function getApp() as CIQApp {
    return Application.getApp() as CIQApp;
}