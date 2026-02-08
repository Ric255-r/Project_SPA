import 'package:flutter/material.dart';

// Model data utk Chart
class ChartData {
  final Color color; // warna piechart
  final double value; // nilai persentase
  final String label; // labek kategori, misal makanan
  final IconData? icon; // icon opsional

  ChartData({required this.color, required this.value, required this.label, this.icon});
}

// LineChart
class MonthlySales {
  final String month; // Nama bulan (Jan, Feb, dst)
  final double revenue; // Pendapatan bulanan

  MonthlySales(this.month, this.revenue);
}

const Map<String, String> hariInggrisKeIndonesia = {
  'Sunday': 'Minggu',
  'Monday': 'Senin',
  'Tuesday': 'Selasa',
  'Wednesday': 'Rabu',
  'Thursday': 'Kamis',
  'Friday': 'Jumat',
  'Saturday': 'Sabtu',
};

final monthNames = {
  "01": "Jan",
  "02": "Feb",
  "03": "Mar",
  "04": "Apr",
  "05": "Mei",
  "06": "Jun",
  "07": "Jul",
  "08": "Aug",
  "09": "Sep",
  "10": "Okt",
  "11": "Nov",
  "12": "Des",
};

class HarianData {
  final String namaHari;
  final String tanggal;
  final int total;
  HarianData(this.namaHari, this.tanggal, this.total);
}

class PenjualanTerapisData {
  final String namaKaryawan;
  final double total;
  PenjualanTerapisData(this.namaKaryawan, this.total);
}

// Helper for nice Y-axis interval
// Minimal 1 supaya tidak pernah 0 (pakai 1000/100000 kalau mau skala Rupiah besar)
double safeNiceInterval(double maxY) {
  if (maxY <= 0) return 1;
  // bikin 4 grid line: bagi 4 lalu bundarkan ke 1jt terdekat
  final raw = maxY / 4;
  // bundar ke 100.000 terdekat biar rapih; bisa ganti ke 1.000.000 jika mau
  const unit = 100000.0; // sesuaikan kebutuhanmu
  final v = (raw / unit).ceil() * unit;
  return v > 0 ? v : 1;
}
