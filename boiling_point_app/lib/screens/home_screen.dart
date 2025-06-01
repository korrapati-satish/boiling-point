import 'package:boiling_point_app/models/boiling_point_action.dart';
import 'package:boiling_point_app/screens/user_profle_screen.dart';
import 'package:boiling_point_app/services/action_submission.dart';
import 'package:boiling_point_app/services/boilling_point_service.dart';
import 'package:flutter/material.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String role = '';
  String coordinates = '';
  late Future<List<BoingPointAction>> actions;


  @override
  void initState() {    
    super.initState();
    actions = fetchActions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boiling Point'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userName: 'John Doe',
                    role: 'User',
                    detail: 'NGO Volunteer',
                    greenPoints: 75,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Role'),
                      onSaved: (val) => role = val ?? '',
                      validator: (val) =>
                          val != null && val.isNotEmpty ? null : 'Enter your role',
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Location Coordinates'),
                      onSaved: (val) => coordinates = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Enter coordinates (e.g., 12.34, 56.78)',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final form = _formKey.currentState!;
                        if (form.validate()) {
                          form.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Role: $role, Coordinates: $coordinates'),
                            ),
                          );
                        }
                      },
                      child: const Text('Submit'),
                    ),
                    // const SizedBox(height: 10),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const PostRequestWithButton(),
                    //       ),
                    //     );
                    //   },
                    //   child: const Text('Post'),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Action Table',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
                FutureBuilder<List<BoingPointAction>>(
                future: actions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No data available');
                  }
                  return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                    child: DataTable(
                    dataRowMinHeight: 60, // Set minimum row height
                    dataRowMaxHeight: 80, // Optionally set maximum row height
                    columns: const [
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                      label: Row(
                        children: [
                        Icon(Icons.eco, color: Colors.green)
                        ],
                      ),
                      ),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),                      
                      DataColumn(label: Text('Submit', style: TextStyle(fontWeight: FontWeight.bold))), // New column
                    ],
                    rows: snapshot.data!.map((item) {
                      return DataRow(cells: [
                      DataCell(
                        ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          item.action,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          maxLines: 3,
                        ),
                        ),
                      ),
                      DataCell(Text(item.rewardPoints.toString())),
                      DataCell(Text(item.status)),                      
                      DataCell(
                        ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActionSubmissionScreen(),
                            ),
                          );
                        },
                        child: const Text('Submit'),
                        ),
                      ),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}