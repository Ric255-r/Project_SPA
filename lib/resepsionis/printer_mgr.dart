// ignore_for_file: unnecessary_string_interpolations

import 'dart:async';
import 'dart:developer';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';

// Utk yg LAN
class PrinterHelper {
  static int gSubTotal = 0;
  static int gNominalDisc = 0;
  static List<dynamic> gNamaPaketYgMember = [];

  static Future<Map<String, dynamic>> _cekMember(idTrans) async {
    var dio = Dio();
    try {
      var response = await dio.get('${myIpAddr()}/listtrans/cek_struk_member?id_trans=$idTrans');
      return {"first_time_buy": response.data['first_time_buy'], "detail_member": response.data['detail_member']};
    } catch (e) {
      // log("Error di CekFirstTimeBuy $e");
      // return false;
      if (e is DioException) {
        throw Exception("Error di Dio pas cek firsttimemember ${e.response!.data}");
      }
      throw Exception("Error cekFirstTimeMember $e");
    }
  }

  static Future<void> printReceipt({
    required String idTrans,
    required double disc,
    required int jenisPembayaran,
    required int noLoker,
    required String namaTamu,
    required String metodePembayaran,
    required String namaBank,
    required double pajak,
    required int gTotalStlhPajak,
    required NetworkPrinter printer,
    required List<dynamic> dataProduk,
    required List<dynamic> dataPaket,
    required List<dynamic> dataFood,
    required List<dynamic> dataFasilitas,
    required List<Map<String, dynamic>> combinedAddOn,
    required List<dynamic> dataMemberFirstTime,
  }) async {
    // reset dlu static global variable disini supaya dia ga ngestack valuenya
    gSubTotal = 0;
    gNominalDisc = 0;
    gNamaPaketYgMember.clear();
    // End Reset
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);

    // Ini Utk Cek klo dia firstTime atau bukan, lalu currentDataMember isinya bisa banyak
    // sehingga ga cocok diprint pas first time beli. firsttime beli ambil dari parameter
    // dataMemberFirstTime
    var getFirstTimeMember = await _cekMember(idTrans);
    bool isFirstTimeMember = getFirstTimeMember['first_time_buy'];
    List<dynamic> currentDataMember = getFirstTimeMember['detail_member'] ?? [];
    // End Cek

    try {
      // print header
      printer.text('PLATINUM', styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));

      // alamat
      printer.text('Jl. Teuku Umar, Komplek Pontianak Mall', styles: const PosStyles(align: PosAlign.center));

      printer.text('Phone: (123) 456-7890', styles: const PosStyles(align: PosAlign.center));
      // Hr untuk pemisah title
      printer.hr();

      // info transaksi
      printer.row([
        PosColumn(text: 'Id Transaksi', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: idTrans, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.row([
        PosColumn(text: 'No Loker', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: noLoker.toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.row([
        PosColumn(text: 'Nama Tamu', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: namaTamu, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.row([
        PosColumn(text: 'Tanggal', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: DateTime.now().toString().split(".")[0], width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      printer.row([
        PosColumn(text: 'Metode Bayar', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: metodePembayaran, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (namaBank != "-") {
        printer.row([
          PosColumn(text: 'Nama Bank', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: namaBank, width: 8, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      printer.hr();

      // Print item berdasarkan data
      _printPackages(printer, dataPaket, jenisPembayaran, disc, currentDataMember, pajak);
      _printProducts(printer, dataProduk, jenisPembayaran, disc, pajak);
      _printFood(printer, dataFood, jenisPembayaran, disc, pajak);
      _printFasilitas(printer, dataFasilitas, jenisPembayaran, disc, pajak);
      _printAddOn(printer, combinedAddOn, jenisPembayaran, disc, pajak);

      // ⬇️ Pindahkan dan jalankan filtering di sini. krn proses filtering dilakukan di fungsi _printPackages sama _fasilitas
      List<dynamic> filteredDataMember = currentDataMember.where((item) => gNamaPaketYgMember.contains(item['nama_promo'])).toList();
      log("Isi Filtered Member $filteredDataMember");
      log("Isi gNamaPaketYgMember $gNamaPaketYgMember");

      if (isFirstTimeMember) {
        _printMember(printer, dataMemberFirstTime, jenisPembayaran, disc, true, pajak);
      } else {
        _printMember(printer, filteredDataMember, jenisPembayaran, disc, false, pajak);
      }
      // End Print Item

      // print subtotal
      // double subtotal = _calculateSubtotal(dataProduk, dataPaket, dataFood, dataFasilitas, combinedAddOn, jenisPembayaran, disc);
      // double nominalDisc = subtotal * disc;
      // double total = subtotal - nominalDisc;

      int subtotal = gSubTotal;
      int nominalDisc = 0;
      // jika akhir, jgn make global disc. lgsg kalikan disc aja
      if (jenisPembayaran == 1) {
        nominalDisc = (subtotal * disc).toInt();
      } else {
        // jika awal
        nominalDisc = gNominalDisc;
      }
      int total = subtotal - nominalDisc;

      printer.hr();
      printer.row([
        PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: isFirstTimeMember ? formatter.format(subtotal * pajak + subtotal) : formatter.format(subtotal), //timpa dgn subtotal asli
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      printer.row([
        PosColumn(text: 'Disc Total ${jenisPembayaran == 1 ? "${(disc * 100).toInt()}%" : ""}', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      // int nominalPjk = (total * pajak).ceil();
      // int ttlStlhPjk = total + nominalPjk;

      // printer.row([
      //   PosColumn(text: 'Pajak', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      //   PosColumn(
      //     text: '${pajak.toInt()}%', // Replace with actual total
      //     width: 6,
      //     styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true),
      //   ),
      // ]);

      printer.row([
        PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(
          text: isFirstTimeMember ? formatter.format(subtotal * pajak + subtotal) : '${formatter.format(total)}', // Replace with actual total
          width: 6,
          styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true),
        ),
      ]);

      // payment method
      printer.hr();
      printer.text('Payment Method: ${jenisPembayaran == 1 ? "Akhir" : "Awal"} ', styles: const PosStyles(bold: true));

      // Footer
      printer.feed(2);
      printer.text('Terimakasih Atas Kunjungannya', styles: const PosStyles(align: PosAlign.center));

      printer.feed(2);
      printer.cut();
    } catch (e) {
      gSubTotal = 0;
      gNominalDisc = 0;
      gNamaPaketYgMember.clear();
      log("Error di Printing $e");
      debugPrint("Printing Error $e");
      rethrow;
    }
  }

  static void _printProducts(NetworkPrinter printer, List<dynamic> products, int jenisPembayaran, double disc, double pajak) {
    if (products.isEmpty) return;

    printer.text("Produk", styles: const PosStyles(bold: true, underline: true));

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    for (var product in products) {
      double hargaItem = product['harga_item'] * pajak + product['harga_item'];
      int maxNameLength = 15; // Example: Adjust this value
      List<String> nameLines = _splitTextIntoLines(product['nama_produk'], maxNameLength);

      if (nameLines.isNotEmpty) {
        printer.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${product['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '${formatter.format(hargaItem)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '${formatter.format(product['qty'] * hargaItem)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name
        for (int i = 1; i < nameLines.length; i++) {
          printer.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1), // Empty columns to align
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      totalProduk += (hargaItem).toInt();

      // printer.row([
      //   PosColumn(text: product['nama_produk'], width: 4),
      //   PosColumn(text: 'x${product['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
      //   PosColumn(text: '${formatter.format(product['harga_item'])}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      //   PosColumn(text: '${formatter.format(product['harga_total'])}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      // ]);
      // totalProduk += (product['harga_total'] as int);
    }

    // jika beli di awal
    if (jenisPembayaran == 0 && disc > 0) {
      double nominalDisc = totalProduk * disc;

      printer.row([
        PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
        PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      gNominalDisc += nominalDisc.toInt();
    }

    gSubTotal += totalProduk;

    printer.feed(1);
  }

  // Helper function to split text into lines
  static List<String> _splitTextIntoLines(String text, int maxLength) {
    List<String> lines = [];
    String currentLine = '';
    List<String> words = text.split(' ');

    for (String word in words) {
      if ((currentLine + word).length <= maxLength) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  static void _printPackages(
    NetworkPrinter printer,
    List<dynamic> packages,
    int jenisPembayaran,
    double disc,
    List<dynamic> currentDataMember,
    double pajak,
  ) async {
    if (packages.isEmpty) return;

    // Pisahin yg retur sm yg nda
    final regularPaket = packages.where((p) => p['is_returned'] == 0).toList();
    final returPaket = packages.where((p) => p['is_returned'] == 1).toList();

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    List<dynamic> isiDetailMember = currentDataMember;

    if (regularPaket.isNotEmpty) {
      printer.text('Paket', styles: const PosStyles(bold: true, underline: true));
      for (var package in regularPaket) {
        // Query utk Masukin nama yg sama ke namaPaketMember
        var terdaftar = isiDetailMember.where((p) => p['nama_promo'] == package['nama_paket_msg']).toList();
        if (terdaftar.isNotEmpty) {
          for (var el in terdaftar) {
            gNamaPaketYgMember.add(el['nama_promo']);
          }
        }
        // End Query

        double hargaItem = package['harga_item'] * pajak + package['harga_item'];
        int maxNameLength = 15; // Example: Adjust this value
        List<String> nameLines = _splitTextIntoLines(package['nama_paket_msg'], maxNameLength);

        if (nameLines.isNotEmpty) {
          printer.row([
            PosColumn(text: nameLines[0], width: 4),
            PosColumn(text: 'x${package['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: '${formatter.format(hargaItem)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: '${formatter.format(package['qty'] * hargaItem)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
          ]);

          // Print subsequent lines without the other columns, just the name
          for (int i = 1; i < nameLines.length; i++) {
            printer.row([
              PosColumn(text: nameLines[i], width: 4),
              PosColumn(text: '', width: 1), // Empty columns to align
              PosColumn(text: '', width: 3),
              PosColumn(text: '', width: 4),
            ]);
          }
        }

        totalProduk += (hargaItem).toInt();
      }

      // jika beli di awal
      if (jenisPembayaran == 0 && disc > 0) {
        double nominalDisc = totalProduk * disc;

        printer.row([
          PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
          PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);

        gNominalDisc += nominalDisc.toInt();
      }

      gSubTotal += totalProduk;
    }

    if (returPaket.isNotEmpty) {
      printer.text('Retur-Paket', styles: const PosStyles(bold: true, underline: true));
      for (var package in returPaket) {
        int hargaItem = package['harga_item'] * pajak + package['harga_item'];
        int maxNameLength = 15; // Example: Adjust this value
        List<String> nameLines = _splitTextIntoLines(package['nama_paket_msg'], maxNameLength);

        printer.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${package['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '(-${formatter.format(hargaItem)})', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '(-${formatter.format(package['qty'] + hargaItem)})', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name
        for (int i = 1; i < nameLines.length; i++) {
          printer.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1), // Empty columns to align
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }

        // printer.row([
        //   PosColumn(text: package['nama_paket_msg'], width: 4),
        //   PosColumn(text: 'x${package['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
        //   PosColumn(text: '(-${formatter.format(package['harga_item'])})', width: 3, styles: const PosStyles(align: PosAlign.right)),
        //   PosColumn(text: '(-${formatter.format(package['harga_total'])})', width: 4, styles: const PosStyles(align: PosAlign.right)),
        // ]);
      }
    }

    printer.feed(1);
  }

  static void _printFood(NetworkPrinter printer, List<dynamic> foods, int jenisPembayaran, double disc, double pajak) {
    if (foods.isEmpty) return;

    printer.text('FnB', styles: const PosStyles(bold: true, underline: true));

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp. ", decimalDigits: 0);
    int totalProduk = 0;

    for (var data in foods) {
      double hargaItem = data['harga_item'] * pajak + data['harga_item'];
      int maxNameLength = 15; // Example: Adjust this value
      List<String> nameLines = _splitTextIntoLines(data['nama_fnb'], maxNameLength);

      if (nameLines.isNotEmpty) {
        printer.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '${formatter.format(hargaItem)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '${formatter.format(data['qty'] * hargaItem)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name
        for (int i = 1; i < nameLines.length; i++) {
          printer.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1), // Empty columns to align
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      totalProduk += (hargaItem).toInt();

      // printer.row([
      //   PosColumn(text: data['nama_fnb'], width: 4),
      //   PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
      //   PosColumn(text: '${formatter.format(data['harga_item'])}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      //   PosColumn(text: '${formatter.format(data['harga_total'])}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      // ]);

      // totalProduk += (data['harga_total'] as int);
    }

    // jika beli di awal
    if (jenisPembayaran == 0 && disc > 0) {
      double nominalDisc = totalProduk * disc;

      printer.row([
        PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
        PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      gNominalDisc += nominalDisc.toInt();
    }

    gSubTotal += totalProduk;

    printer.feed(1);
  }

  static void _printFasilitas(NetworkPrinter printer, List<dynamic> fasilitas, int jenisPembayaran, double disc, double pajak) {
    if (fasilitas.isEmpty) return;

    printer.text('Fasilitas', styles: const PosStyles(bold: true, underline: true));

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    for (var data in fasilitas) {
      double hargaItem = data['harga'] * pajak + data['harga'];
      int maxNameLength = 15; // Example: Adjust this value
      List<String> nameLines = _splitTextIntoLines(data['nama_fasilitas'], maxNameLength);

      if (nameLines.isNotEmpty) {
        printer.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '${formatter.format(hargaItem)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '${formatter.format(data['qty'] * hargaItem)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name
        for (int i = 1; i < nameLines.length; i++) {
          printer.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1), // Empty columns to align
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      totalProduk += (hargaItem).toInt();

      // printer.row([
      //   PosColumn(text: data['nama_fasilitas'], width: 4),
      //   PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
      //   PosColumn(text: '${formatter.format(data['harga'])}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      //   PosColumn(text: '${formatter.format(data['harga'])}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      // ]);

      // totalProduk += (data['harga'] as int);
    }

    // jika beli di awal
    if (jenisPembayaran == 0 && disc > 0) {
      double nominalDisc = totalProduk * disc;

      printer.row([
        PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
        PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      gNominalDisc += nominalDisc.toInt();
    }

    gSubTotal += totalProduk;

    printer.feed(1);
  }

  static void _printAddOn(NetworkPrinter printer, List<dynamic> addOns, int jenisPembayaran, double disc, double pajak) {
    if (addOns.isEmpty) return;

    printer.text('AddOn', styles: const PosStyles(bold: true, underline: true));

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    for (var data in addOns) {
      double hargaItem = data['harga_item'] * pajak + data['harga_item'];
      int maxNameLength = 15; // Example: Adjust this value
      List<String> nameLines = _splitTextIntoLines(data['nama_item'], maxNameLength);

      if (nameLines.isNotEmpty) {
        printer.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '${formatter.format(hargaItem)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '${formatter.format(data['qty'] * hargaItem)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name
        for (int i = 1; i < nameLines.length; i++) {
          printer.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1), // Empty columns to align
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      totalProduk += (hargaItem).toInt();

      // printer.row([
      //   PosColumn(text: data['nama_item'], width: 4),
      //   PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
      //   PosColumn(text: '${formatter.format(data['harga_item'])}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      //   PosColumn(text: '${formatter.format(data['harga_total'])}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      // ]);

      // totalProduk += (data['harga_total'] as int);
    }

    // bagian addOn Beda cerita. kalo payment d akhir, dpt disc, klo awal, nd dpt
    // jika beli di awal
    // if (jenisPembayaran == 1 && disc > 0) {
    //   double nominalDisc = totalProduk * disc;

    //   // printer.row([
    //   //   PosColumn(
    //   //     text: "Disc(${(disc * 100).toInt()}%)",
    //   //     width: 6,
    //   //   ),
    //   //   PosColumn(
    //   //     text: '-${formatter.format(nominalDisc)}',
    //   //     width: 6,
    //   //     styles: const PosStyles(align: PosAlign.right),
    //   //   ),
    //   // ]);

    //   gNominalDisc += nominalDisc.toInt();
    // }

    gSubTotal += totalProduk;

    printer.feed(1);
  }

  static void _printMember(NetworkPrinter printer, List<dynamic> dataMember, int jenisPembayaran, double disc, bool isFirstTimeMember, double pajak) async {
    if (dataMember.isEmpty) return;

    printer.text("Program Member", styles: const PosStyles(bold: true, underline: true));

    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    printer.row([
      PosColumn(text: "Nama Member: ", width: 6),
      PosColumn(text: '${dataMember[0]['nama_member'] ?? dataMember[0]['nama'] ?? "-"}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.row([
      PosColumn(text: "NoHp Member: ", width: 6),
      PosColumn(text: '${dataMember[0]['no_hp']}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.row([
      PosColumn(text: "Member Sejak", width: 6),
      PosColumn(text: '${(dataMember[0]['created_at']).toString().split("T")[0]}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.row([
      PosColumn(text: "Tanggal Berakhir", width: 6),
      PosColumn(text: (dataMember[0]['exp_tahunan'] ?? "-").toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    printer.row([
      PosColumn(text: "Sisa Pemakaian", width: 6),
      PosColumn(text: (dataMember[0]['sisa_kunjungan'] ?? "-").toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    printer.text('', styles: const PosStyles(align: PosAlign.center));

    printer.row([
      PosColumn(text: "Nama Paket Awal", width: 6, styles: const PosStyles(bold: true, underline: true)),
      PosColumn(text: 'Harga Paket', width: 6, styles: const PosStyles(bold: true, underline: true, align: PosAlign.right)),
    ]);

    for (var product in dataMember) {
      printer.row([
        PosColumn(text: product['nama_promo'], width: 6),
        PosColumn(
          text: isFirstTimeMember ? formatter.format(product['harga_promo'] * pajak + product['harga_promo']) : '(${formatter.format(product['harga_promo'])})',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      totalProduk += (product['harga_promo'] as int);
    }

    gSubTotal += isFirstTimeMember ? totalProduk : 0;

    printer.feed(1);
  }

  // static double _calculateSubtotal(
  //   List<dynamic> products,
  //   List<dynamic> packages,
  //   List<dynamic> foods,
  //   List<dynamic> fasilitas,
  //   List<dynamic> addon,
  //   int jenisPembayaran,
  //   double disc,
  // ) {
  //   double subtotal = 0;

  //   subtotal += products.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));
  //   for (var i = 0; i < packages.length; i++) {
  //     if (packages[i]['is_returned'] == 0) {
  //       subtotal += packages[i]['harga_total'];
  //     }
  //   }
  //   subtotal += foods.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));
  //   subtotal += fasilitas.fold(0, (sum, item) => sum + (item['harga_fasilitas'] * item['qty']));
  //   subtotal += addon.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));

  //   return subtotal;
  // }
}

// Utk Yg USB
class PrinterHelperUSB {
  static Future<List<int>> buildReceiptContent({
    required String idTrans,
    required double disc,
    required int jenisPembayaran,
    required List<dynamic> dataProduk,
    required List<dynamic> dataPaket,
    required List<dynamic> dataFood,
    required List<dynamic> dataFasilitas,
    required List<Map<String, dynamic>> combinedAddOn,
  }) async {
    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text('PLATINUM SPA', styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
    bytes += generator.text('Jl. Teuku Umar, Komplek Pontianak Mall', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Phone: (123) 456-7890', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Transaction Info
    bytes += generator.row([
      PosColumn(text: "Id Transaksi", width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: idTrans, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Tanggal", width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: DateTime.now().toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();

    // print setiap category
    bytes += _printItems(generator, "Paket", dataPaket, 'nama_paket_msg', 'harga_item');
    bytes += _printItems(generator, "Produk", dataProduk, 'nama_produk', 'harga_item');
    bytes += _printItems(generator, "FnB", dataFood, 'nama_fnb', 'harga_item');
    bytes += _printItems(generator, "Fasilitas", dataFasilitas, 'nama_fasilitas', 'harga_fasilitas');
    bytes += _printItems(generator, "AddOn", combinedAddOn, 'nama_item', 'harga_item');

    // Calculate Subtotal
    final subtotal = _calculateSubtotal(dataProduk, dataPaket, dataFood, dataFasilitas, combinedAddOn);
    final total = subtotal - disc;

    // Totals
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '\Rp. ${subtotal.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Disc', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '${(disc * 100)}%', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: '\Rp. ${total.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
    ]);

    // payment method
    bytes += generator.hr();
    bytes += generator.text('Payment Method: ${_getPaymentMethod(jenisPembayaran)}', styles: const PosStyles(bold: true));

    // Footer
    bytes += generator.feed(2);
    bytes += generator.text('Terimakasih Atas Kunjungannya', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  static String _getPaymentMethod(int jenisPembayaran) {
    switch (jenisPembayaran) {
      case 0:
        return 'Awal';
      case 1:
        return 'Akhir';
      default:
        return '';
    }
  }

  static List<int> _printItems(Generator generator, String title, List<dynamic> items, String nameKey, String priceKey) {
    if (items.isEmpty) return [];

    List<int> bytes = [];
    bytes += generator.text(title, styles: const PosStyles(bold: true, underline: true));

    for (var item in items) {
      bytes += generator.row([
        PosColumn(text: item[nameKey], width: 8),
        PosColumn(text: 'x${item['qty']}', width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: '\$${item[priceKey]}', width: 2, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.feed(1);
    return bytes;
  }

  static double _calculateSubtotal(List<dynamic> products, List<dynamic> packages, List<dynamic> foods, List<dynamic> fasilitas, List<dynamic> addon) {
    double subtotal = 0;

    subtotal += products.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));
    subtotal += packages.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));
    subtotal += foods.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));
    subtotal += fasilitas.fold(0, (sum, item) => sum + (item['harga_fasilitas'] * item['qty']));
    subtotal += addon.fold(0, (sum, item) => sum + (item['harga_item'] * item['qty']));

    return subtotal;
  }
}
