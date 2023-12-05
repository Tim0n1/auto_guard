import 'package:obd2_plugin/obd2_plugin.dart';

class StringJson {
  String params = '''[
    {
        "PID": "AT RV",
        "length": 4,
        "title": "ولتاژ باطری",
        "unit": "V",
        "description": "<str>",
        "status": true
    },
    {
        "PID": "01 0C",
        "length": 2,
        "title": "دور موتور",
        "unit": "RPM",
        "description": "<double>, (( [0] * 256) + [1] ) / 4",
        "status": true
    },
    {
        "PID": "01 0D",
        "length": 1,
        "title": "سرعت خودرو",
        "unit": "Kh",
        "description": "<int>, [0]",
        "status": true
    },
    {
        "PID": "01 05",
        "length": 1,
        "title": "دمای موتور",
        "unit": "°C",
        "description": "<int>, [0] - 40",
        "status": true
    },
    {
        "PID": "01 0B",
        "length": 1,
        "title": "فشار مطلق منیفولد",
        "unit": "kPa",
        "description": "<int>, [0]",
        "status": true
    }
]''';
}
