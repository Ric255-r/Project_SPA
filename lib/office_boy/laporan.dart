import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'dart:io'; // For file operations
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/office_boy/image_mgr.dart';
import 'package:Project_SPA/office_boy/main_ob.dart';
import 'package:dio/dio.dart';

class Lapor extends StatefulWidget {
  final int idLaporan;
  final String idOb;
  const Lapor({super.key, required this.idLaporan, required this.idOb});

  @override
  State<Lapor> createState() => _LaporState();
}

class _LaporState extends State<Lapor> {
  // Custom Class
  GlobalImageManager _imageManager = GlobalImageManager();
  ScrollController _scrollController = ScrollController();
  RxBool _isUploading = false.obs;

  Future<void> captureImage() async {
    final picker = ImagePicker();

    final XFile? imageFile = await picker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      // print("Image Captured ${imageFile.path}");
      // saveImageToStorage(File(imageFile.path));
      File storedImages = await saveImageToStorage(File(imageFile.path));

      // Masukkan Ke List yg global
      _imageManager.addImage(storedImages);

      // print("Image saved: ${storedImages.path}");
      // print("Total images captured: ${_imageManager.getImages().length}");
    } else {
      print("No Image Captured");
    }
  }

  Future<void> _fnLaporFile() async {
    // for (var image in _imageManager.getImages()) {
    //   print("Image Path: ${image.path}");
    // }

    List<File> images = _imageManager.getImages();
    _isUploading.value = true;

    // Upload File ke Dio
    await _uploadKeDb(images);
  }

  var dio = Dio();
  TextEditingController _txtLaporan = TextEditingController();

  Future<void> _uploadKeDb(List<File> images) async {
    try {
      // Create Form Data
      FormData formData = FormData();

      for (var image in images) {
        formData.files.add(
          MapEntry(
            'files', // sesuaikan dengan parameter fastapi
            await MultipartFile.fromFile(image.path,
                filename: image.path.split('/').last),
          ),
        );
      }

      formData.fields.add(MapEntry('laporan', _txtLaporan.text));
      formData.fields.add(MapEntry('id_laporan', "${widget.idLaporan}"));
      formData.fields.add(MapEntry('id_karyawan', widget.idOb));

      var response = await dio.put(
        '${myIpAddr()}/ob/update_laporan',
        data: formData,
      );

      if (response.statusCode == 200) {
        print("Images uploaded successfully");
        _isUploading.value = false;
      } else {
        print("Failed to upload images: ${response.statusCode}");
      }
    } catch (e) {
      log("error di uploadkedb $e");
    }
  }

  Future<File> saveImageToStorage(File image) async {
    // Ambil directory app
    var directory = await getApplicationDocumentsDirectory();
    var path = directory.path;

    // buat file di storage directory
    var fileName = "image_${DateTime.now().millisecondsSinceEpoch}.jpg";
    File newImage = File('$path/$fileName');

    await image.copy(newImage.path);

    print("Image Tersimpan di ${newImage.path}");
    return newImage;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _txtLaporan.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int pjg = _imageManager.imageList.length;
    List<File> images = _imageManager.getImages();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0XFFFFE0B2),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              "HASIL FOTO RUANGAN",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: const EdgeInsets.only(left: 80, right: 80),
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 280,
                width: Get.width - 100,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: pjg,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Foto Ke-${index + 1}",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Get.dialog(
                                          AlertDialog(
                                            title: Text(
                                              "Hapus Foto",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            content: Text(
                                              "Anda Yakin Ingin Menghapus?",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Get.back();
                                                },
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _imageManager.removeImage(
                                                    index,
                                                  );

                                                  Get.back();
                                                  setState(() {});
                                                },
                                                child: Text(
                                                  "OK",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Hapus Foto?",
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 270,
                            width: double.infinity,
                            child: Image.file(images[index], fit: BoxFit.cover),
                          ),
                          SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Input Permasalahan Ruangan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                ),
              ),
              TextField(
                controller: _txtLaporan,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await captureImage();

                      // setstate kosong utk refresh widget
                      // because calling setState() tells Flutter that the state of the widget has changed
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(120, 120),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.camera, size: 80),
                        Text(
                          "Tambah Foto",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: _isUploading.isFalse
                          ? ElevatedButton(
                              onPressed: () {
                                // Pindah ke ui sebelumnya.
                                // atau bs pake  Get.off(() => MainOb()); // Replaces current screen with MainOb
                                _isUploading.value = true;

                                _fnLaporFile().then((_) {
                                  Get.back();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(120, 120),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.check, size: 80),
                                  Text(
                                    "Lapor",
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(120, 120),
                              ),
                              child: Column(
                                children: [
                                  Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
