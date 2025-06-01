import 'dart:convert';
import 'package:boiling_point_app/models/boiling_point_action.dart';
import 'package:boiling_point_app/models/boiling_point.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

Future<List<BoingPointAction>> fetchActions() async {
  print('[fetchActions] Fetching actions...');
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

  print('[fetchActions] Simulated response: $responseData');
  final actions = responseData.map((json) => BoingPointAction.fromJson(json)).toList();
  print('[fetchActions] Parsed actions: $actions');
  return actions;
}

Future<BoilingPoint> getBoilingPointActions(String role, String location, String language) async {
  //const url = 'http://127.0.0.1:8000/get-actions';
  final url = 'http://10.0.2.2:8000/get-actions';

  final headers = {"Content-Type": "application/json"};
  final body = jsonEncode({
    "role": role,
    "location": location,
    "language": language // Add the required language field
  });

  print('[getBoilingPointActions] Sending POST to $url');
  print('[getBoilingPointActions] Headers: $headers');
  print('[getBoilingPointActions] Body: $body');

  try {
    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    print('[getBoilingPointActions] Response status: ${response.statusCode}');
    print('[getBoilingPointActions] Response body: ${response.body}');
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print('[getBoilingPointActions] Decoded JSON: $jsonResponse');
      return BoilingPoint.fromJson(jsonResponse);
    } else {
      print('[getBoilingPointActions] Failed with status: ${response.statusCode}');
      throw Exception('Failed with status: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    print('[getBoilingPointActions] Error: $e');
    print('[getBoilingPointActions] StackTrace: $stackTrace');
    throw Exception('Error: $e');
  }
}



Future<BoilingPointStepsResponse> fetchBoilingPointActionSteps(String emailId, String action, String role, String location, String selectedLanguage) async {
  // const url = 'http://127.0.0.1:8000/select-action';
  final url = 'http://10.0.2.2:8000/select-action';
  final headers = {"Content-Type": "application/json"};
  final body = jsonEncode({
    "email_id": emailId,
    "action": action,
    "role": role,
    "location": location,
    "language": selectedLanguage // Add the required language field
  });

  print('[fetchBoilingPointActionSteps] Sending POST to $url');
  print('[fetchBoilingPointActionSteps] Headers: $headers');
  print('[fetchBoilingPointActionSteps] Body: $body');

  try {
    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    print('[fetchBoilingPointActionSteps] Response status: ${response.statusCode}');
    print('[fetchBoilingPointActionSteps] Response body: ${response.body}');
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final stepsMap = jsonResponse['steps'] as Map<String, dynamic>;
      final message = jsonResponse['message']?.toString() ?? '';
      // Sort steps by key (e.g., "Step 1", "Step 2", ...)
      final sortedKeys = stepsMap.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      final steps = sortedKeys.map((k) => BoilingPointActionStep(description: stepsMap[k].toString(), title: '')).toList();
      print('steps: $steps');
      return BoilingPointStepsResponse(steps: steps, message: message);
    } else {
      throw Exception('Failed to fetch steps: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    print('[fetchBoilingPointActionSteps] Error: $e');
    print('[fetchBoilingPointActionSteps] StackTrace: $stackTrace');
    throw Exception('Error: $e');
  }
}
