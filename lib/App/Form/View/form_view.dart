import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormScreen extends StatefulWidget {
  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final whatsappController = TextEditingController();

  final type = ''.obs;
  final bloodGroup = ''.obs;

  final existingRequestId = RxnString();

  final types = ['Donate', 'Receive'];
  final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _whatsappFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _whatsappFocusNode.addListener(() {
      if (!_whatsappFocusNode.hasFocus) {
        _checkExistingRequest();
      }
    });
  }

  @override
  void dispose() {
    descController.dispose();
    locationController.dispose();
    whatsappController.dispose();
    _whatsappFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRequest() async {
    final whatsapp = whatsappController.text.trim();
    if (whatsapp.isEmpty) {
      _clearExistingRequestData(clearWhatsApp: false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('whatsapp', isEqualTo: whatsapp)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        existingRequestId.value = doc.id;

        // Fill form fields with existing data
        type.value = doc['type'] ?? '';
        bloodGroup.value = doc['blood_group'] ?? '';
        locationController.text = doc['location_or_hospital'] ?? '';
        descController.text = doc['description'] ?? '';

        setState(() {});

        Get.snackbar(
          'Request Found',
          'You can edit or delete your previous request.',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else {
        _clearExistingRequestData(clearWhatsApp: false);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check existing request.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _clearExistingRequestData({bool clearWhatsApp = true}) {
    existingRequestId.value = null;
    type.value = '';
    bloodGroup.value = '';
    locationController.clear();
    descController.clear();
    if (clearWhatsApp) whatsappController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F2),
      appBar: AppBar(
        title: const Text('Blood Request'),
        centerTitle: true,
        backgroundColor: const Color(0xFFB71C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offNamed('/feed'),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Submit Blood Request',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Instruction message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      '📢 Enter your WhatsApp number to check if you have already submitted a request. '
                      'If found, your details will auto-fill and you can Edit or Delete your request.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildDropdown('Type', types, type),
                  const SizedBox(height: 12),

                  _buildDropdown('Blood Group', bloodGroups, bloodGroup),
                  const SizedBox(height: 12),

                  _buildTextField(locationController, 'Location or Hospital'),
                  const SizedBox(height: 12),

                  _buildTextField(descController, 'Description', maxLines: 3),
                  const SizedBox(height: 12),

                  _buildTextField(
                    whatsappController,
                    'WhatsApp Number',
                    focusNode: _whatsappFocusNode,
                  ),
                  const SizedBox(height: 20),

                  Obx(() {
                    final hasRequest = existingRequestId.value != null;
                    if (!hasRequest) {
                      return ElevatedButton.icon(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB71C1C),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'Submit Request',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _handleEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Edit Request',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton.icon(
                            onPressed: _handleDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              'Delete Request',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, RxString selected) {
    return Obx(() => DropdownButtonFormField<String>(
          value: selected.value.isEmpty ? null : selected.value,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFFCE4EC),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => selected.value = value ?? '',
        ));
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFFEBEE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType:
          label == 'WhatsApp Number' ? TextInputType.phone : TextInputType.text,
    );
  }

  void _handleSubmit() async {
    if (type.value.isEmpty ||
        bloodGroup.value.isEmpty ||
        locationController.text.isEmpty ||
        descController.text.isEmpty ||
        whatsappController.text.isEmpty) {
      Get.snackbar(
        'Missing Fields',
        'Please complete all fields.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('blood_requests').add({
        'type': type.value,
        'blood_group': bloodGroup.value,
        'location_or_hospital': locationController.text.trim(),
        'description': descController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Your request has been submitted!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _clearExistingRequestData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleEdit() async {
    final id = existingRequestId.value;
    if (id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(id)
          .update({
        'type': type.value,
        'blood_group': bloodGroup.value,
        'location_or_hospital': locationController.text.trim(),
        'description': descController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Your request has been updated!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update your request.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleDelete() async {
    final id = existingRequestId.value;
    if (id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(id)
          .delete();

      Get.snackbar(
        'Deleted',
        'Your request has been deleted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _clearExistingRequestData();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete your request.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
