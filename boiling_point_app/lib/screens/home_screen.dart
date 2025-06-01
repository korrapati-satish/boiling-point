import 'package:boiling_point_app/models/boiling_point.dart';
import 'package:boiling_point_app/models/boiling_point_action.dart';
import 'package:boiling_point_app/screens/user_profle_screen.dart';
import 'package:boiling_point_app/screens/action_submission_screen.dart';
import 'package:boiling_point_app/services/boilling_point_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  static Route routeFromArgs(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] as String? ?? '';
    debugPrint('HomeScreen.routeFromArgs: email = $email');
    return MaterialPageRoute(
      builder: (_) => HomeScreen(email: email),
      settings: settings,
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRegion;
  String? selectedLivelihood;
  String? selectedLanguage;
  
  late Future<BoilingPoint> boilingPoint;
  late Future<BoilingPointStepsResponse> boilingPointStepsResponse;

  final List<String> regions = [
    'Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Ahmedabad', 'Chennai', 'Kolkata', 'Surat', 'Pune', 'Jaipur', 'Lucknow', 'Kanpur', 'Nagpur', 'Indore', 'Thane', 'Bhopal', 'Visakhapatnam', 'Pimpri-Chinchwad', 'Patna', 'Vadodara', 'Ghaziabad', 'Ludhiana', 'Coimbatore', 'Agra', 'Madurai',
  ];
  final List<String> livelihoods = ['Farming', 'Fishing', 'Trading', 'Labor'];
  final List<String> languages = ['Hindi', 'Tamil', 'Telugu', 'Kannada', 'English'];

  late String email;

  @override
  void initState() {
    super.initState();
    email = widget.email.isNotEmpty ? widget.email : 'john@gmail.com';
    debugPrint('HomeScreen initialized with email: $email');
    // Log the email if it's not empty
    if (email.isNotEmpty) {
      debugPrint('User email: $email');
    }

    //boilingPoint = getBoilingPointActions('Farmer', 'Bengaluru', 'English');

    boilingPointStepsResponse = fetchBoilingPointActionSteps(
      email,
      'Promote eco-friendly dog waste management',
      selectedLivelihood ?? 'Farming',
      selectedRegion ?? 'Andhra Pradesh',
      selectedLanguage ?? 'English',
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Boiling Point Actions', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722), Color(0xFFD84315)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Card for form
                    Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    margin: const EdgeInsets.fromLTRB(24, 4, 24, 16), // Reduced top margin
                    child: Padding(
                      padding: const EdgeInsets.all(20), // Slightly reduced padding
                      child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                        Text(
                          'Personalize Your Actions',
                          style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange[800],
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced space
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
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
                          validator: (val) => val != null && val.isNotEmpty ? null : 'Select a region',
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Livelihood', border: OutlineInputBorder()),
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
                          validator: (val) => val != null && val.isNotEmpty ? null : 'Select a livelihood',
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
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
                          validator: (val) => val != null && val.isNotEmpty ? null : 'Select a language',
                        ),
                        const SizedBox(height: 14), // Reduced space
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final form = _formKey.currentState!;
                            if (form.validate()) {
                            form.save();
                            setState(() {
                              boilingPoint = getBoilingPointActions(
                              selectedLivelihood ?? 'Farming',
                              selectedRegion ?? 'Bangalore',
                              selectedLanguage ?? 'English',
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
                          child: const Text('Get My Actions', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        ],
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Actions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<BoilingPoint>(
                          future: boilingPoint,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                            } else if (!snapshot.hasData || (snapshot.data?.actions.isEmpty ?? true)) {
                              return const Text('No data available', style: TextStyle(color: Colors.white));
                            }
                            final boilingPointData = snapshot.data!;
                            final actionsList = boilingPointData.actions;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Role: ${selectedLivelihood ?? 'Farming'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Location: ${selectedRegion ?? 'Bengaluru'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Language: ${selectedLanguage ?? 'English'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Actions:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: actionsList.length,
                                  itemBuilder: (context, index) {
                                    final action = actionsList[index];
                                    return Card(
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 4,
                                      child: ExpansionTile(
                                        title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(action.description),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange[700],
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  icon: const Icon(Icons.list_alt),
                                                  label: const Text('Steps'),
                                                  onPressed: () async {                                                  
                                                    final stepsResponse = await fetchBoilingPointActionSteps(
                                                      email,
                                                      action.description,
                                                      selectedLivelihood ?? 'Farming',
                                                      selectedRegion ?? 'Andhra Pradesh',
                                                      selectedLanguage  ?? 'English',
                                                    );
                                                    if (!mounted) return;
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: Text('Steps for "${action.title}"'),
                                                        content: SizedBox(
                                                          width: double.maxFinite,
                                                          child: stepsResponse.steps.isNotEmpty
                                                              ? SingleChildScrollView(
                                                                  child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      ...stepsResponse.steps.map<Widget>(
                                                                        (step) => ListTile(
                                                                          leading: const Icon(Icons.check_circle_outline),
                                                                          title: Text(step.description.isNotEmpty
                                                                              ? step.description
                                                                              : 'Step'),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : const Text('No steps available.'),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            child: const Text('Close'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.deepOrange,
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  icon: const Icon(Icons.check),
                                                  label: const Text('Complete'),
                                                  onPressed: () {                                                  
                                                    final actionName = action.description;
                                                    if (actionName.isNotEmpty) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ActionSubmissionScreen(
                                                            actionName: actionName,
                                                            userId: email,
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('No action available to complete.')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
