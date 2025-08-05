import 'dart:io';
// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PatientCardPage extends StatefulWidget {
  final String nik;
  final String name;
  final String birthDate;
  final String address;
  final String phone;

  const PatientCardPage({
    super.key,
    required this.nik,
    required this.name,
    required this.birthDate,
    required this.address,
    required this.phone,
  });

  @override
  State<PatientCardPage> createState() => _PatientCardPageState();
}

class _PatientCardPageState extends State<PatientCardPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _saveCard() async {
    setState(() => _isSaving = true);

    try {
      // Capture the card as an image
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/patient_card_${DateTime.now().millisecondsSinceEpoch}.png';
      File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the image which allows saving to gallery
      await Share.shareXFiles([XFile(filePath)], text: 'My Patient Card');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save card: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Card'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon:
                _isSaving
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(Icons.save_alt),
            onPressed: _isSaving ? null : _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // The card widget that will be saved as an image
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.green[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 50,
                            color: Colors.green[700],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'KARTU KECAMATAN JEUMPA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Patient Info
                    _buildInfoRow('NIK', widget.nik),
                    _buildInfoRow('Name', widget.name),
                    _buildInfoRow('Date of Birth', widget.birthDate),
                    _buildInfoRow('Address', widget.address),
                    _buildInfoRow('Phone', widget.phone),

                    // Footer with barcode
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Kartu pasien rawat jalan kecamatan Jeumpa',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Icon(Icons.save_alt),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Patient Card',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(": ", style: TextStyle(fontSize: 16)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
