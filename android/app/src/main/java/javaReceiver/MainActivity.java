import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;



public class MainActivity extends FlutterActivity {
    private static final String CHANNEL_NAME = "obd2"; // Replace with your channel name

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Create an instance of YourJavaClass and pass the method channel
        obd2Handler javahandler = new obd2Handler(
            new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME)
        );
    }
}