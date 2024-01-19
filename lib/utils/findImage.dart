import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';

Future<String?> findImageByName(String name) async{
  // Read the contents of data.json file
  String jsonData = await rootBundle.loadString('lib/images/car_logos/data.json');
  String path = 'lib/images/car_logos/';
  String image = '';

  // Parse the JSON data
  List<dynamic> data = jsonDecode(jsonData);

  // Find the image URL by name
  for (var item in data) {
    if (item['name'] == name) {
      image = item['image']['localOptimized'].substring(2);
      return path + image;
      //break;
    }
  }

  // Return null if image not found
  return null;
}
