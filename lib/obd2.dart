import 'package:obd2_plugin/obd2_plugin.dart';

String decodeHexASCII(String encoded) {
  List<String> hexValues = encoded.split(' ');
  List<int> decimalValues =
      hexValues.map((hex) => int.parse(hex, radix: 16)).toList();
  String decodedString = String.fromCharCodes(decimalValues);
  return decodedString;
}

String decodeHexASCII2(String encoded) {
  List<String> parts = encoded.split(' '); // Split the string by spaces

  String decodedString = '';

  for (String part in parts) {
    try {
      if (part.isNotEmpty) {
        if (part.length % 2 == 0) {
          // If the part has an even length
          List<int> bytes = [];

          for (int i = 0; i < part.length; i += 2) {
            String hex = part.substring(i, i + 2);
            bytes.add(int.parse(hex, radix: 16));
          }

          decodedString +=
              String.fromCharCodes(bytes); // Convert bytes to characters
        } else {
          decodedString += part; // Append non-hex parts directly
        }
      }
    } catch (e) {
      print(e);
    }
  }

  return decodedString;
}

class StringJson {
  String checkObd = '''[
    {
      "PID": "09 02",
      "length": 17,
      "title": "ECU name",
      "description": "<str>",
      "status": true
    }
  ]''';
  String params = '''[
    {
        "PID": "AT RV",
        "length": 4,
        "title": "Напрежение на акумулатора",
        "unit": "V",
        "description": "<str>",
        "status": true
    },
    {
        "PID": "01 0C",
        "length": 2,
        "title": "Обороти",
        "unit": "RPM",
        "description": "<double>, (( [0] * 256) + [1] ) / 4",
        "status": true
    },
    {
        "PID": "01 0D",
        "length": 1,
        "title": "Скорост на автомобила",
        "unit": "Kh",
        "description": "<int>, [0]",
        "status": true
    },
    {
        "PID": "01 05",
        "length": 1,
        "title": "Температура на двигателя",
        "unit": "°C",
        "description": "<int>, [0] - 40",
        "status": true
    },
    {
        "PID": "01 0B",
        "length": 1,
        "title": "Абсолютно налягане в колектора",
        "unit": "kPa",
        "description": "<int>, [0]",
        "status": true
    },
    {
      "PID": "09 02",
      "length": 17,
      "title": "VIN number",
      "description": "<str>",
      "status": true
    }
]''';

  String config = '''[
            {
                "command": "AT Z",
                "description": "",
                "status": true
            },
            {
                "command": "AT E0",
                "description": "",
                "status": true
            },
            {
                "command": "AT SP 0",
                "description": "",
                "status": true
            },
            {
                "command": "AT SH 81 10 F1",
                "description": "",
                "status": true
            },
            {
                "command": "AT H1",
                "description": "",
                "status": true
            },
            {
                "command": "AT S0",
                "description": "",
                "status": true
            },
            {
                "command": "AT M0",
                "description": "",
                "status": true
            },
            {
                "command": "AT AT 1",
                "description": "",
                "status": true
            },
            {
                "command": "01 00",
                "description": "",
                "status": true
            }
        ]''';

  String dtc = '''
            [
    {
        "id": 1,
        "created_at": "2021-12-05T16:33:18.965620Z",
        "command": "03",
        "response": "6",
        "status": true
    },
    {
        "id": 7,
        "created_at": "2021-12-05T16:35:01.516477Z",
        "command": "18 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 6,
        "created_at": "2021-12-05T16:34:51.417614Z",
        "command": "18 02 FF FF",
        "response": "",
        "status": true
    },
    {
        "id": 5,
        "created_at": "2021-12-05T16:34:23.837086Z",
        "command": "18 02 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 4,
        "created_at": "2021-12-05T16:34:12.496052Z",
        "command": "18 00 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 3,
        "created_at": "2021-12-05T16:33:38.323200Z",
        "command": "0A",
        "response": "6",
        "status": true
    },
    {
        "id": 2,
        "created_at": "2021-12-05T16:33:28.439547Z",
        "command": "07",
        "response": "6",
        "status": true
    },
    {
        "id": 34,
        "created_at": "2021-12-05T16:41:25.883408Z",
        "command": "17 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 35,
        "created_at": "2021-12-05T16:41:38.901888Z",
        "command": "13 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 36,
        "created_at": "2021-12-05T16:41:51.040962Z",
        "command": "19 02 AF",
        "response": "",
        "status": true
    },
    {
        "id": 37,
        "created_at": "2021-12-05T16:42:01.384228Z",
        "command": "19 02 AC",
        "response": "",
        "status": true
    },
    {
        "id": 38,
        "created_at": "2021-12-05T16:42:11.770741Z",
        "command": "19 02 8D",
        "response": "",
        "status": true
    },
    {
        "id": 39,
        "created_at": "2021-12-05T16:42:28.443368Z",
        "command": "19 02 23",
        "response": "",
        "status": true
    },
    {
        "id": 40,
        "created_at": "2021-12-05T16:42:39.200378Z",
        "command": "19 02 78",
        "response": "",
        "status": true
    },
    {
        "id": 41,
        "created_at": "2021-12-05T16:42:50.444404Z",
        "command": "19 02 08",
        "response": "",
        "status": true
    },
    {
        "id": 42,
        "created_at": "2021-12-05T16:43:00.466739Z",
        "command": "19 0F AC",
        "response": "",
        "status": true
    },
    {
        "id": 43,
        "created_at": "2021-12-05T16:43:10.645120Z",
        "command": "19 0F 8D",
        "response": "",
        "status": true
    },
    {
        "id": 44,
        "created_at": "2021-12-05T16:43:25.257023Z",
        "command": "19 0F 23",
        "response": "",
        "status": true
    },
    {
        "id": 45,
        "created_at": "2021-12-05T16:43:36.567099Z",
        "command": "19 D2 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 46,
        "created_at": "2021-12-05T17:15:56.352652Z",
        "command": "19 C2 FF 00",
        "response": "",
        "status": true
    },
    {
        "id": 47,
        "created_at": "2021-12-05T17:16:17.567797Z",
        "command": "19 FF FF 00",
        "response": "",
        "status": true
    }
]
          ''';
}
