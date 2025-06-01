class BoilingPointAction {
  final String title;
  final String description;

  BoilingPointAction({
    required this.title,
    required this.description,
  });

  factory BoilingPointAction.fromJson(String key, String value) {
    return BoilingPointAction(
      title: key,
      description: value,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}

class BoilingPoint {
  final String input;
  final String role;
  final String location;
  final List<BoilingPointAction> actions;

  BoilingPoint({
    required this.input,
    required this.role,
    required this.location,
    required this.actions,
  });

  factory BoilingPoint.fromJson(Map<String, dynamic> json) {
    final output = json['output'] as Map<String, dynamic>;
    final actions = output.entries
        .map((e) => BoilingPointAction.fromJson(e.key, e.value))
        .toList();

    return BoilingPoint(
      input: json['input'] as String,
      role: json['role'] as String,
      location: json['location'] as String,
      actions: actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'input': input,
        'role': role,
        'location': location,
        'output': {
          for (var action in actions) action.title: action.description,
        },
      };
}
class BoilingPointStepsResponse {
  final String message;
  final List<BoilingPointActionStep> steps;

  BoilingPointStepsResponse({
    required this.message,
    required this.steps,
  });

  factory BoilingPointStepsResponse.fromJson(Map<String, dynamic> json) {
    final stepsMap = json['steps'] as Map<String, dynamic>;
    final stepsList = stepsMap.entries
        .map((e) => BoilingPointActionStep.fromJson(e.key, e.value))
        .toList();

    return BoilingPointStepsResponse(
      message: json['message'] as String,
      steps: stepsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'steps': {
          for (var step in steps) step.title: step.description,
        },
      };
  
  // Add a convenience factory for Map<String, String> input
  factory BoilingPointStepsResponse.fromMap({
    required String message,
    required Map<String, String> steps,
  }) {
    final stepsList = steps.entries
        .map((e) => BoilingPointActionStep(title: e.key, description: e.value))
        .toList();
    return BoilingPointStepsResponse(message: message, steps: stepsList);
  }
}

class BoilingPointActionStep {
  final String title;
  final String description;

  BoilingPointActionStep({
    required this.title,
    required this.description,
  });

  factory BoilingPointActionStep.fromJson(String key, String value) {
    return BoilingPointActionStep(
      title: key,
      description: value,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };
}