import 'package:boiling_point_app/models/boiling_point.dart';
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
  late Future<BoilingPoint> boilingPoint;  
  late Future<BoilingPointStepsResponse> boilingPointStepsResponse;  
  final List<String> regions = [
    // States & Union Territories (regions)
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Chandigarh',
    'Puducherry',
    'Jammu and Kashmir',
    'Ladakh',
    'Andaman and Nicobar Islands',
    'Lakshadweep',
    'Dadra and Nagar Haveli and Daman and Diu',

    // Major cities
    'Mumbai',
    'Delhi',
    'Bengaluru',
    'Hyderabad',
    'Ahmedabad',
    'Chennai',
    'Kolkata',
    'Surat',
    'Pune',
    'Jaipur',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Pimpri-Chinchwad',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Coimbatore',
    'Agra',
    'Madurai',
  ];
  final List<String> livelihoods = ['Farming', 'Fishing', 'Trading', 'Labor'];
  final List<String> languages = ['Hindi', 'Tamil', 'Telugu', 'Kannada', 'English'];

  String? selectedRegion;
  String? selectedLivelihood;
  String? selectedLanguage;


  @override
  void initState() {    
    super.initState();
    actions = fetchActions();
    boilingPoint = getBoilingPointActions('Farmer', 'Bengaluru');  
    boilingPointStepsResponse = fetchBoilingPointActionSteps('arshitvyas123@gmail.com', 'Promote eco-friendly dog waste management');    

    boilingPoint.then((bp) {
      debugPrint('BoilingPoint loaded: input=${bp.input}, role=${bp.role}, location=${bp.location}, actions=${bp.actions.length}');
    }).catchError((e) {
      debugPrint('Error loading BoilingPoint: $e');
    });

    boilingPointStepsResponse.then((bp) {
      debugPrint('BoilingPoint loaded: message=${bp.message}, steps=${bp.steps.length}');
    }).catchError((e) {
      debugPrint('Error loading BoilingPoint: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boiling Point Actions'),
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
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Region'),
                  value: selectedRegion,
                  items: regions
                  .map((region) => DropdownMenuItem(
                    value: region,
                    child: Text(region),
                    ))
                  .toList(),
                  onChanged: (val) {
                  setState(() {
                  selectedRegion = val;
                  });
                  },
                  onSaved: (val) => selectedRegion = val,
                  validator: (val) =>
                  val != null && val.isNotEmpty ? null : 'Select a region',
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Livelihood'),
                  value: selectedLivelihood,
                  items: livelihoods
                  .map((livelihood) => DropdownMenuItem(
                    value: livelihood,
                    child: Text(livelihood),
                    ))
                  .toList(),
                  onChanged: (val) {
                  setState(() {
                  selectedLivelihood = val;
                  });
                  },
                  onSaved: (val) => selectedLivelihood = val,
                  validator: (val) =>
                  val != null && val.isNotEmpty ? null : 'Select a livelihood',
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Language'),
                  value: selectedLanguage,
                  items: languages
                  .map((language) => DropdownMenuItem(
                    value: language,
                    child: Text(language),
                    ))
                  .toList(),
                  onChanged: (val) {
                  setState(() {
                  selectedLanguage = val;
                  });
                  },
                  onSaved: (val) => selectedLanguage = val,
                  validator: (val) =>
                  val != null && val.isNotEmpty ? null : 'Select a language',
                ),
                ElevatedButton(
                  onPressed: () {
                  final form = _formKey.currentState!;
                  if (form.validate()) {
                    form.save();
                    // Debug log
                    debugPrint('Selected Region: $selectedRegion, Livelihood: $selectedLivelihood, Language: $selectedLanguage');
                    setState(() {
                    boilingPoint = getBoilingPointActions(
                      selectedLivelihood ?? 'User',
                      selectedRegion ?? 'Andhra Pradesh',
                    );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                      'Region: $selectedRegion, Livelihood: $selectedLivelihood, Language: $selectedLanguage'),
                    ),
                    );
                  }
                  },
                  child: const Text('Get My Actions'),
                ),
                const SizedBox(height: 10),
                ],
              ),
              ),
              const SizedBox(height: 32),
              const Text(
              'My Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<BoilingPoint>(
              future: boilingPoint,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || (snapshot.data?.actions.isEmpty ?? true)) {
                  return const Text('No data available');
                }
                final boilingPointData = snapshot.data!;
                final actionsList = boilingPointData.actions;
                // UI according to the JSON structure
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input: ${boilingPointData.input}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Role: ${boilingPointData.role}'),
                    Text('Location: ${boilingPointData.location}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Actions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actionsList.length,
                      itemBuilder: (context, index) {
                        final action = actionsList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ExpansionTile(
                          title: Text(action.title),
                          subtitle: Text(action.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            ElevatedButton(
                              onPressed: () async {
                              // Replace with actual user email if available
                              const email = 'arshitvyas123@gmail.com';
                              final actionDescription = action.description;
                              final stepsResponse = await fetchBoilingPointActionSteps(email, actionDescription);
                              debugPrint('StepsResponse: message=${stepsResponse.message}, steps=${stepsResponse.steps.map((s) => s.description).toList()}');
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                title: Text('Steps for "${action.title}"'),
                                content: stepsResponse.steps.isNotEmpty
                                  ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...stepsResponse.steps.map<Widget>((step) => ListTile(
                                        leading: const Icon(Icons.check_circle_outline),
                                        title: Text(step.description.isNotEmpty ? step.description : 'Step'),
                                        ),
                                      ),
                                    ],
                                    )
                                  : const Text('No steps available.'),
                                actions: [
                                  TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                  ),
                                ],
                                ),
                              );
                              },
                              child: const Text('Steps'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                              // Replace with actual user id and action name as needed
                              const userId = 'arshitvyas123@gmail.com';
                              final actionName = action.title;
                              if (actionName.isNotEmpty) {
                                Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActionSubmissionScreen(
                                  actionName: actionName,
                                  userId: userId,
                                  ),
                                ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No action available to complete.')),
                                );
                              }
                              },
                              child: const Text('Complete'),
                            ),
                            ],
                          ),
                          children: const [
                            // No local steps property, so always show "No steps available."
                            Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No steps available.'),
                            ),
                          ],
                          ),
                        );
                      },
                    ),
                  ],
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