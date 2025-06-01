

import 'dart:convert';
import 'package:boiling_point_app/models/boiling_point_action.dart';
import 'package:http/http.dart' as http;

Future<List<BoingPointAction>> fetchActions() async {
  // final response = await http.get(Uri.parse('https://your-api-endpoint.com/actions'));

  // if (response.statusCode == 200) {
  //   List<dynamic> data = jsonDecode(response.body);
  //   return data.map((json) => BoingPointAction.fromJson(json)).toList();
  // } else {
  //   throw Exception('Failed to load data');
  // }


  // Simulated API response
  final List<Map<String, dynamic>> responseData = [
    {
      "action": "Use coconut husks, banana leaves, sugarcane trash, or dry grass as mulch to cover soil between crop rows.",
      "reward_points": 10,
      "status": "Pending",
      "target_date": "2024-07-01"
    },
    {
      "action": "Shift irrigation schedules to before 9 AM or after 5 PM to reduce evaporation loss.",
      "reward_points": 8,
      "status": "Pending",
      "target_date": "2024-07-05"
    },
    {
      "action": "Plant fast-growing native shade trees (e.g., Gliricidia, Neem, Pongamia) along farm borders.",
      "reward_points": 15,
      "status": "Pending",
      "target_date": "2024-07-10"
    }
  ];

  return responseData.map((json) => BoingPointAction.fromJson(json)).toList();
}
