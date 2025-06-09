import 'dart:io';

// Define  class LockerManager
class LockerManager {
  // Buat single instance
  // singleton pattern jadi semua part dari app ini share instance yang sama.
  static final LockerManager _instance = LockerManager._internal();

  // Factory constructor utk return instance yang sama
  factory LockerManager() {
    return _instance;
  }

  //  constructor privat
  LockerManager._internal();

  // variabel utk store noLocker
  int? noLocker;

  // Method tambah locker
  void addLocker(int paramAngka) {
    noLocker = paramAngka;
  }

  // remove image
  void removeLocker() {
    noLocker = null;
  }

  // Method getLocker
  int getLocker() {
    return noLocker!;
  }
}
