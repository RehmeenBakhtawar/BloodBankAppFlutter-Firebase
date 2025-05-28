import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final box = GetStorage();
  String? selectedGroup;

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  void logout() {
    FirebaseAuth.instance.signOut();
    box.remove('uid');
    Get.offAllNamed('/login');
  }

  String url(String number) {
    return "https://api.whatsapp.com/send?phone=$number&text=";
  }

  void openWhatsApp(String number) async {
    final Uri uri = Uri.parse(url(number));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB71C1C);
    const cardBg = Color(0xFFFFEBEE);
    const background = Color(0xFFFDF2F2);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: const Text('Blood Requests Feed'),
        centerTitle: false,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/form'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🩸 Blood Group Filter UI
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Blood Group',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bloodGroups.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final group = bloodGroups[index];
                      final isSelected = selectedGroup == group;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGroup = isSelected ? null : group;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red[100] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.red : Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              group,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedGroup = null;
                        });
                      },
                      child: const Text("Show All"),
                    ),
                  ),
                ],
              ),
            ),

            // 🔄 Blood Requests List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (selectedGroup == null) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['blood_group'] == selectedGroup;
                }).toList();

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No blood requests found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      color: cardBg,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _tagChip(data['type'], primaryColor),
                                const SizedBox(width: 8),
                                _tagChip('Group: ${data['blood_group']}', Colors.black87),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['description'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            if (data['location_or_hospital'] != null)
                              Text(
                                'Location: ${data['location_or_hospital']}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (data['whatsapp'] != null)
                              GestureDetector(
                                onTap: () => openWhatsApp(data['whatsapp']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(UniconsLine.whatsapp,
                                          size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        data['whatsapp'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
