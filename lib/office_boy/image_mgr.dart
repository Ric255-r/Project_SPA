import 'dart:io';

// Define  class GlobalImageManager
class GlobalImageManager {
  // Buat single instance
  // singleton pattern jadi semua part dari app ini share instance yang sama.
  static final GlobalImageManager _instance = GlobalImageManager._internal();

  // Factory constructor utk return instance yang sama
  factory GlobalImageManager() {
    return _instance;
  }

  //  constructor privat
  GlobalImageManager._internal();

  // List utk simpan images
  List<File> imageList = [];

  // Method tambah image ke list
  void addImage(File image) {
    imageList.add(image);
  }

  // remove image
  void removeImage(int index) {
    imageList.removeAt(index);
  }

  void clearAllData() {
    imageList.clear();
  }

  // Method getDatImage
  List<File> getImages() {
    return imageList;
  }
}
