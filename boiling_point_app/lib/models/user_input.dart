class UserInput {
  final String role;
  final String location;

  UserInput({required this.role, required this.location});

  Map<String, dynamic> toJson() => {
        'role': role,
        'location': location,
      };
}