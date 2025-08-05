import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class CetakLaporan extends StatefulWidget {
  const CetakLaporan({super.key});

  @override
  State<CetakLaporan> createState() => _CetakLaporanState();
}

class _CetakLaporanState extends State<CetakLaporan> {
  final patiensRef = FirebaseFirestore.instance.collection('users');
  final doctorsRef = FirebaseFirestore.instance.collection('doctors');
  final appointmentsRef = FirebaseFirestore.instance.collection('appointments');
  Map<String, dynamic> patients = {};
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> appointments = [];
  DateTimeRange? selectedDateRange;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    getDataDokter();
    getDataPasien();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getDataDokter() async {
    final snap = await doctorsRef.orderBy('name', descending: true).get();
    final data =
        snap.docs.map((doc) => {'docID': doc.id, ...doc.data()}).toList();

    setState(() {
      doctors = data;
    });
  }

  void cetakPDFDataDokter() async {
    setState(() {
      isLoading = true;
    });

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (pw.Context context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Data Dokter Kec. Puedada',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Nama', 'Ruangan'],
                data:
                    doctors.map((dokter) {
                      return [
                        dokter['name'],
                        dokter['room_code'],
                        dokter['specialist'],
                      ];
                    }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
      ),
    );

    try {
      final outputDir =
          await getTemporaryDirectory(); // atau getApplicationDocumentsDirectory()
      final filePath = '${outputDir.path}/data_dokter_puedada.pdf';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // Buka file PDF setelah dibuat
      await OpenFile.open(file.path);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Membuat PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> cetakPDFDataPemeriksaan() async {
    setState(() {
      isLoading = true;
    });

    if (selectedDateRange == null) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mohon memilih tanggal terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final snap =
          await appointmentsRef
              .where('status', isEqualTo: 'selesai')
              .where(
                'janji_temu.tanggal',
                isGreaterThanOrEqualTo: selectedDateRange!.start,
              )
              .where(
                'janji_temu.tanggal',
                isLessThanOrEqualTo: selectedDateRange!.end,
              )
              .orderBy('janji_temu.tanggal')
              .get();

      final dataPemeriksaan =
          snap.docs.map((doc) {
            final pasien = patients[doc.data()['uid']];
            final dokter = doctors.firstWhere(
              (dt) => dt['docID'] == doc.data()['janji_temu']['doctor_id'],
            );

            return {
              'nama': pasien['nama'],
              'noHP': pasien['noHP'],
              'dokter': dokter['name'],
              'ruangan': "${dokter['specialist']}-${dokter['room_code']}",
              'keluhan': List<String>.from(doc.data()['keluhan'] ?? []),
            };
          }).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Laporan Data Pemeriksaan Pasien',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                ...dataPemeriksaan.map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Nama Pasien : ${item['nama']}'),
                        pw.Text('No. HP : ${item['noHP']}'),
                        pw.Text('Dokter : ${item['dokter']}'),
                        pw.Text('Ruangan : ${item['ruangan']}'),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Keluhan:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children:
                              (item['keluhan'] as List<String>)
                                  .map((k) => pw.Bullet(text: k))
                                  .toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/laporan_pemeriksaan.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        setState(() => isLoading = false);
      }

      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> getDataPasien() async {
    final snap = await patiensRef.get();
    final data = Map.fromEntries(
      snap.docs.map((doc) => MapEntry(doc.id, doc.data())),
    );

    setState(() {
      patients = data;
    });
  }

  Future<void> selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, 1, 1, 0, 0, 0);
    final lastDate = DateTime(now.year, 12, 31, 23, 59, 59);
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (dateRange != null) {
      setState(() {
        selectedDateRange = dateRange;
      });
    }
  }

  String convertDateRange(DateTimeRange? dateRange) {
    if (dateRange == null) return "";

    final first =
        "${dateRange.start.day}/${dateRange.start.month}/${dateRange.start.year}";
    final last =
        "${dateRange.end.day}/${dateRange.end.month}/${dateRange.end.year}";

    return "$first s/d $last";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        title: const Text('Cetak Laporan'),
        backgroundColor: Colors.green[700],
      ),
      body:
          isLoading
              ? Center(
                child: Text("Permintaan data sedang di proses, mohon tunggu."),
              )
              : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    eksporDataDokter(context),
                    SizedBox(height: 30, child: Divider()),
                    eksporDataRujukan(context),
                  ],
                ),
              ),
    );
  }

  Widget eksporDataDokter(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          if (isLoading) return;
          cetakPDFDataDokter();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text(
          'Ekspor Data Dokter',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget eksporDataRujukan(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          onTap: () => selectDateRange(context),
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Rentang Tanggal Rujukan Selesai',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => selectDateRange(context),
            ),
          ),
          controller: TextEditingController(
            text: convertDateRange(selectedDateRange),
          ),
          validator: (value) {
            if (selectedDateRange == null) {
              return 'Please select a date';
            }
            return null;
          },
        ),
        SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              if (isLoading) return;
              cetakPDFDataPemeriksaan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text(
              'Ekspor Data Rujukan',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
