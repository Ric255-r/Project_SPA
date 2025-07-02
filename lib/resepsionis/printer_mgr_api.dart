import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';

class PrinterHelper {
  // g = global variabel
  // static int gSubTotal = 0;
  // static int gNominalDisc = 0;
  static double gSubTotal = 0.0;
  static double gNominalDisc = 0.0;
  static List<dynamic> gNamaPaketYgMember = [];

  static Future<Map<String, dynamic>> _cekMember(idTrans) async {
    var dio = Dio();
    try {
      var response = await dio.get('${myIpAddr()}/listtrans/cek_struk_member?id_trans=$idTrans');
      return {"first_time_buy": response.data['first_time_buy'], "detail_member": response.data['detail_member']};
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error di Dio pas cek firsttimemember ${e.response!.data}");
      }
      throw Exception("Error cekFirstTimeMember $e");
    }
  }

  static Future<List<int>> generateReceipt({
    required String idTrans,
    required double disc,
    required int jenisPembayaran,
    required int noLoker,
    required String namaTamu,
    required String metodePembayaran,
    required String namaBank,
    required double pajak,
    required int gTotalStlhPajak,
    required List<dynamic> dataProduk,
    required List<dynamic> dataPaket,
    required List<dynamic> dataFood,
    required List<dynamic> dataFasilitas,
    required List<Map<String, dynamic>> combinedAddOn,
    required List<dynamic> dataMemberFirstTime,
  }) async {
    // Reset static variables
    gSubTotal = 0;
    gNominalDisc = 0;
    gNamaPaketYgMember.clear();

    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Ini Utk Cek klo dia firstTime atau bukan, lalu currentDataMember isinya bisa banyak
    // sehingga ga cocok diprint pas first time beli. firsttime beli ambil dari parameter
    // dataMemberFirstTime
    var getFirstTimeMember = await _cekMember(idTrans);
    bool isFirstTimeMember = getFirstTimeMember['first_time_buy'];
    List<dynamic> currentDataMember = getFirstTimeMember['detail_member'] ?? [];

    // Print header
    bytes += _printHeader(generator, noLoker, namaTamu, metodePembayaran, namaBank, idTrans);

    // Print items
    bytes += _printPackages(generator, dataPaket, jenisPembayaran, disc, currentDataMember, pajak);
    // bytes += _printProducts(generator, dataProduk, jenisPembayaran, disc, pajak);
    // bytes += _printFood(generator, dataFood, jenisPembayaran, disc, pajak);
    // bytes += _printFasilitas(generator, dataFasilitas, jenisPembayaran, disc, pajak);

    // NEW: Using the refactored function
    bytes += _printItemSection(
      generator: generator,
      title: 'Produk',
      items: dataProduk,
      nameKey: 'nama_produk',
      priceKey: 'harga_item',
      jenisPembayaran: jenisPembayaran,
      disc: disc,
      pajak: pajak,
    );

    bytes += _printItemSection(
      generator: generator,
      title: 'FnB',
      items: dataFood,
      nameKey: 'nama_fnb',
      priceKey: 'harga_item',
      jenisPembayaran: jenisPembayaran,
      disc: disc,
      pajak: pajak,
    );

    bytes += _printItemSection(
      generator: generator,
      title: 'Fasilitas',
      items: dataFasilitas,
      nameKey: 'nama_fasilitas',
      priceKey: 'harga',
      jenisPembayaran: jenisPembayaran,
      disc: disc,
      pajak: pajak,
    );

    bytes += _printAddOn(generator, combinedAddOn, jenisPembayaran, disc, pajak);

    // Filter member data
    List<dynamic> filteredDataMember = currentDataMember.where((item) => gNamaPaketYgMember.contains(item['nama_promo'])).toList();

    if (isFirstTimeMember) {
      bytes += _printMember(generator, dataMemberFirstTime, jenisPembayaran, disc, true, pajak);
    } else {
      bytes += _printMember(generator, filteredDataMember, jenisPembayaran, disc, false, pajak);
    }

    // Print totals
    bytes += _printTotals(generator, disc, jenisPembayaran, isFirstTimeMember, pajak);

    // Print footer
    bytes += _printFooter(generator);

    return bytes;
  }

  static List<int> _printHeader(Generator generator, int noLoker, String namaTamu, String metodePembayaran, String namaBank, String idTrans) {
    List<int> bytes = [];
    // var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);

    bytes += generator.text('PLATINUM', styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
    bytes += generator.text('Jl. Teuku Umar, Komplek Pontianak Mall', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Phone: 0853-4820-9415', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Id Transaksi', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: idTrans, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'No Loker', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: noLoker.toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Nama Tamu', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: namaTamu, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Tanggal', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: DateTime.now().toString().split(".")[0], width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Metode Bayar', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: metodePembayaran, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (namaBank != "-") {
      bytes += generator.row([
        PosColumn(text: 'Nama Bank', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: namaBank, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();
    return bytes;
  }

  // static List<int> _printProducts(Generator generator, List<dynamic> products, int jenisPembayaran, double disc, double pajak) {
  //   if (products.isEmpty) return [];

  //   List<int> bytes = [];
  //   var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
  //   double totalProduk = 0;

  //   bytes += generator.text("Produk", styles: const PosStyles(bold: true, underline: true));

  //   for (var product in products) {
  //     double hargaItem = product['harga_item'] * pajak + product['harga_item'];
  //     int maxNameLength = 15;
  //     List<String> nameLines = _splitTextIntoLines(product['nama_produk'], maxNameLength);
  //     double hargaTotalItem = product['qty'] * hargaItem;
  //     // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;

  //     if (nameLines.isNotEmpty) {
  //       bytes += generator.row([
  //         PosColumn(text: nameLines[0], width: 4),
  //         PosColumn(text: 'x${product['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
  //         PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
  //         // PosColumn(text: formatter.format(stlhRoundTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
  //         PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
  //       ]);

  //       for (int i = 1; i < nameLines.length; i++) {
  //         bytes += generator.row([
  //           PosColumn(text: nameLines[i], width: 4),
  //           PosColumn(text: '', width: 1),
  //           PosColumn(text: '', width: 3),
  //           PosColumn(text: '', width: 4),
  //         ]);
  //       }
  //     }

  //     // totalProduk += stlhRoundTotalItem;
  //     totalProduk += hargaTotalItem;
  //   }

  //   if (jenisPembayaran == 0 && disc > 0) {
  //     double nominalDisc = totalProduk * disc;
  //     bytes += generator.row([
  //       PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
  //       PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
  //     ]);
  //     // originalnya ada .toInt()
  //     gNominalDisc += nominalDisc;
  //   }

  //   gSubTotal += totalProduk;
  //   bytes += generator.feed(1);
  //   return bytes;
  // }

  static List<int> _printPackages(
    Generator generator,
    List<dynamic> packages,
    int jenisPembayaran,
    double disc,
    List<dynamic> currentDataMember,
    double pajak,
  ) {
    if (packages.isEmpty) return [];

    List<int> bytes = [];

    // Pisahin yg retur sm yg nda
    final regularPaket = packages.where((p) => p['is_returned'] == 0).toList();
    final returPaket = packages.where((p) => p['is_returned'] == 1).toList();
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    double totalProduk = 0;

    List<dynamic> isiDetailMember = currentDataMember;

    if (regularPaket.isNotEmpty) {
      bytes += generator.text('Paket', styles: const PosStyles(bold: true, underline: true));
      for (var package in regularPaket) {
        // Query utk Masukin nama yg sama ke namaPaketMember
        var terdaftar = isiDetailMember.where((p) => p['nama_promo'] == package['nama_paket_msg']).toList();
        if (terdaftar.isNotEmpty) {
          for (var el in terdaftar) {
            gNamaPaketYgMember.add(el['nama_promo']);
          }
        }
        // End query

        double hargaItem = package['harga_item'] * pajak + package['harga_item'];
        double hargaTotalItem = package['qty'] * hargaItem;
        // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;
        int maxNameLength = 15; // panjang karakter utk printer
        List<String> nameLines = _splitTextIntoLines(package['nama_paket_msg'], maxNameLength);

        if (nameLines.isNotEmpty) {
          bytes += generator.row([
            PosColumn(text: nameLines[0], width: 4),
            PosColumn(text: 'x${package['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
            PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
          ]);

          for (int i = 1; i < nameLines.length; i++) {
            bytes += generator.row([
              PosColumn(text: nameLines[i], width: 4),
              PosColumn(text: '', width: 1), // empty column utk align
              PosColumn(text: '', width: 3),
              PosColumn(text: '', width: 4),
            ]);
          }
        }

        totalProduk += hargaTotalItem;
      }

      // Jika beli diawal
      if (jenisPembayaran == 0 && disc > 0) {
        double nominalDisc = totalProduk * disc;
        bytes += generator.row([
          PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
          PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Original ada .toInt()
        gNominalDisc += nominalDisc;
      }

      gSubTotal += totalProduk;
    }

    if (returPaket.isNotEmpty) {
      bytes += generator.text('Retur-Paket', styles: const PosStyles(bold: true, underline: true));
      for (var package in returPaket) {
        int hargaItem = package['harga_item'] * pajak + package['harga_item'];
        int maxNameLength = 15;
        List<String> nameLines = _splitTextIntoLines(package['nama_paket_msg'], maxNameLength);

        bytes += generator.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${package['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: '(-${formatter.format(hargaItem)})', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: '(-${formatter.format(package['qty'] * hargaItem)})', width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines without the other columns, just the name

        for (int i = 1; i < nameLines.length; i++) {
          bytes += generator.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1),
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }
    }

    bytes += generator.feed(1);
    return bytes;
  }

  static List<int> _printItemSection({
    required Generator generator,
    required String title,
    required List<dynamic> items,
    required String nameKey,
    required String priceKey,
    required int jenisPembayaran,
    required double disc,
    required double pajak,
  }) {
    if (items.isEmpty) return [];

    List<int> bytes = [];
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    double totalSection = 0;

    bytes += generator.text(title, styles: const PosStyles(bold: true, underline: true));

    for (var item in items) {
      // Use the priceKey to get the price, defaulting to 0.0 if not found
      double hargaAsli = (item[priceKey] ?? 0.0).toDouble();
      double hargaItem = hargaAsli * pajak + hargaAsli;
      double hargaTotalItem = item['qty'] * hargaItem;
      // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;
      int maxNameLength = 15;

      // Use the nameKey to get the name
      List<String> nameLines = _splitTextIntoLines(item[nameKey], maxNameLength);

      if (nameLines.isNotEmpty) {
        bytes += generator.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${item['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
          // // PosColumn(text: formatter.format(stlhRoundTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        // Print subsequent lines for long item names
        for (int i = 1; i < nameLines.length; i++) {
          bytes += generator.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1),
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      // totalSection += stlhRoundTotalItem;
      totalSection += hargaTotalItem;
    }

    // Apply discount only for "Awal" payment type
    if (jenisPembayaran == 0 && disc > 0) {
      double nominalDisc = totalSection * disc;
      bytes += generator.row([
        PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
        PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      gNominalDisc += nominalDisc; // Accumulate global discount
    }

    gSubTotal += totalSection; // Accumulate global subtotal
    bytes += generator.feed(1);
    return bytes;
  }

  // static List<int> _printFood(Generator generator, List<dynamic> foods, int jenisPembayaran, double disc, double pajak) {
  //   if (foods.isEmpty) return [];

  //   List<int> bytes = [];
  //   bytes += generator.text('FnB', styles: const PosStyles(bold: true, underline: true));
  //   var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp. ", decimalDigits: 0);
  //   double totalProduk = 0;

  //   for (var data in foods) {
  //     double hargaItem = data['harga_item'] * pajak + data['harga_item'];
  //     int maxNameLength = 15;
  //     List<String> nameLines = _splitTextIntoLines(data['nama_fnb'], maxNameLength);
  //     double hargaTotalItem = data['qty'] * hargaItem;
  //     // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;

  //     if (nameLines.isNotEmpty) {
  //       bytes += generator.row([
  //         PosColumn(text: nameLines[0], width: 4),
  //         PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
  //         PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
  //         // PosColumn(text: formatter.format(stlhRoundTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
  //         PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
  //       ]);

  //       for (int i = 1; i < nameLines.length; i++) {
  //         bytes += generator.row([
  //           PosColumn(text: nameLines[i], width: 4),
  //           PosColumn(text: '', width: 1),
  //           PosColumn(text: '', width: 3),
  //           PosColumn(text: '', width: 4),
  //         ]);
  //       }
  //     }

  //     // totalProduk += stlhRoundTotalItem
  //     totalProduk += hargaTotalItem;
  //   }

  //   // jika beli di awal
  //   if (jenisPembayaran == 0 && disc > 0) {
  //     double nominalDisc = totalProduk * disc;
  //     bytes += generator.row([
  //       PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
  //       PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
  //     ]);
  //     gNominalDisc += nominalDisc;
  //   }

  //   gSubTotal += totalProduk;
  //   bytes += generator.feed(1);
  //   return bytes;
  // }

  // static List<int> _printFasilitas(Generator generator, List<dynamic> fasilitas, int jenisPembayaran, double disc, double pajak) {
  //   if (fasilitas.isEmpty) return [];

  //   List<int> bytes = [];
  //   bytes += generator.text('Fasilitas', styles: const PosStyles(bold: true, underline: true));
  //   var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
  //   double totalProduk = 0;

  //   for (var data in fasilitas) {
  //     double hargaItem = data['harga'] * pajak + data['harga'];
  //     int maxNameLength = 15;
  //     List<String> nameLines = _splitTextIntoLines(data['nama_fasilitas'], maxNameLength);
  //     double hargaTotalItem = data['qty'] * hargaItem;
  //     // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;

  //     if (nameLines.isNotEmpty) {
  //       bytes += generator.row([
  //         PosColumn(text: nameLines[0], width: 4),
  //         PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
  //         PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
  //         PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
  //       ]);

  //       for (int i = 1; i < nameLines.length; i++) {
  //         bytes += generator.row([
  //           PosColumn(text: nameLines[i], width: 4),
  //           PosColumn(text: '', width: 1),
  //           PosColumn(text: '', width: 3),
  //           PosColumn(text: '', width: 4),
  //         ]);
  //       }
  //     }

  //     totalProduk += hargaTotalItem;
  //   }

  //   // jika beli di awal
  //   if (jenisPembayaran == 0 && disc > 0) {
  //     double nominalDisc = totalProduk * disc;
  //     bytes += generator.row([
  //       PosColumn(text: "Disc(${(disc * 100).toInt()}%)", width: 6),
  //       PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
  //     ]);
  //     gNominalDisc += nominalDisc.toInt();
  //   }

  //   gSubTotal += totalProduk;
  //   bytes += generator.feed(1);
  //   return bytes;
  // }

  static List<int> _printAddOn(Generator generator, List<dynamic> addOns, int jenisPembayaran, double disc, double pajak) {
    if (addOns.isEmpty) return [];

    List<int> bytes = [];
    bytes += generator.text('AddOn', styles: const PosStyles(bold: true, underline: true));
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    double totalProduk = 0;

    for (var data in addOns) {
      double hargaItem = data['harga_item'] * pajak + data['harga_item'];
      int maxNameLength = 15;
      List<String> nameLines = _splitTextIntoLines(data['nama_item'], maxNameLength);
      double hargaTotalItem = data['qty'] * hargaItem;
      // int stlhRoundTotalItem = (hargaTotalItem / 1000).round() * 1000;

      if (nameLines.isNotEmpty) {
        bytes += generator.row([
          PosColumn(text: nameLines[0], width: 4),
          PosColumn(text: 'x${data['qty']}', width: 1, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: formatter.format(hargaItem), width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: formatter.format(hargaTotalItem), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);

        for (int i = 1; i < nameLines.length; i++) {
          bytes += generator.row([
            PosColumn(text: nameLines[i], width: 4),
            PosColumn(text: '', width: 1),
            PosColumn(text: '', width: 3),
            PosColumn(text: '', width: 4),
          ]);
        }
      }

      totalProduk += hargaTotalItem;
    }

    gSubTotal += totalProduk;
    bytes += generator.feed(1);
    return bytes;
  }

  static List<int> _printMember(Generator generator, List<dynamic> dataMember, int jenisPembayaran, double disc, bool isFirstTimeMember, double pajak) {
    if (dataMember.isEmpty) return [];

    List<int> bytes = [];
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);
    int totalProduk = 0;

    bytes += generator.text("Program Member", styles: const PosStyles(bold: true, underline: true));

    bytes += generator.row([
      PosColumn(text: "Nama Member: ", width: 6),
      PosColumn(text: '${dataMember[0]['nama_member'] ?? dataMember[0]['nama'] ?? "-"}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "NoHp Member: ", width: 6),
      PosColumn(text: '${dataMember[0]['no_hp']}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Member Sejak", width: 6),
      // ignore: unnecessary_string_interpolations
      PosColumn(text: '${(dataMember[0]['created_at']).toString().split("T")[0]}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Tanggal Berakhir", width: 6),
      PosColumn(text: (dataMember[0]['exp_tahunan'] ?? "-").toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Sisa Pemakaian", width: 6),
      PosColumn(text: (dataMember[0]['sisa_kunjungan'] ?? "-").toString(), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text('', styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: "Nama Paket Awal", width: 6, styles: const PosStyles(bold: true, underline: true)),
      PosColumn(text: 'Harga Paket', width: 6, styles: const PosStyles(bold: true, underline: true, align: PosAlign.right)),
    ]);

    for (var product in dataMember) {
      bytes += generator.row([
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
    bytes += generator.feed(1);
    return bytes;
  }

  static List<int> _printTotals(Generator generator, double disc, int jenisPembayaran, bool isFirstTimeMember, double pajak) {
    List<int> bytes = [];
    var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);

    // Round only ONCE at the very end
    int finalSubtotal = gSubTotal.round();
    int finalNominalDisc = 0;

    if (jenisPembayaran == 1) {
      // Akhir
      finalNominalDisc = (gSubTotal * disc).round();
    } else {
      // Awal
      finalNominalDisc = gNominalDisc.round();
    }

    int total = finalSubtotal - finalNominalDisc;

    // Use the final rounded values for printing
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: formatter.format(finalSubtotal), // Use rounded value
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Disc Total ${jenisPembayaran == 1 ? "${(disc * 100).toInt()}%" : ""}', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '-${formatter.format(finalNominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)), // Use rounded value
    ]);

    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: formatter.format(total), // Use final calculated total
        width: 6,
        styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true),
      ),
    ]);

    bytes += generator.hr();
    bytes += generator.text('Payment Method: ${jenisPembayaran == 1 ? "Akhir" : "Awal"} ', styles: const PosStyles(bold: true));
    return bytes;
  }

  // static List<int> _printTotals(Generator generator, double disc, int jenisPembayaran, bool isFirstTimeMember, double pajak) {
  //   List<int> bytes = [];
  //   var formatter = NumberFormat.currency(locale: "en_ID", symbol: "Rp.", decimalDigits: 0);

  //   int subtotal = gSubTotal;
  //   int nominalDisc = 0;

  //   // jika akhir, jgn make global disc. lgsg kalikan disc aja
  //   if (jenisPembayaran == 1) {
  //     nominalDisc = (subtotal * disc).toInt();
  //   } else {
  //     // awal
  //     nominalDisc = gNominalDisc;
  //   }

  //   int total = subtotal - nominalDisc;

  //   bytes += generator.hr();
  //   bytes += generator.row([
  //     PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(bold: true)),
  //     PosColumn(
  //       text: isFirstTimeMember ? formatter.format(subtotal * pajak + subtotal) : formatter.format(subtotal),
  //       width: 6,
  //       styles: const PosStyles(align: PosAlign.right),
  //     ),
  //   ]);

  //   bytes += generator.row([
  //     PosColumn(text: 'Disc Total ${jenisPembayaran == 1 ? "${(disc * 100).toInt()}%" : ""}', width: 6, styles: const PosStyles(bold: true)),
  //     PosColumn(text: '-${formatter.format(nominalDisc)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
  //   ]);

  //   bytes += generator.row([
  //     PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
  //     PosColumn(
  //       text: isFirstTimeMember ? formatter.format(subtotal * pajak + subtotal) : formatter.format(total),
  //       width: 6,
  //       styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true),
  //     ),
  //   ]);

  //   bytes += generator.hr();
  //   bytes += generator.text('Payment Method: ${jenisPembayaran == 1 ? "Akhir" : "Awal"} ', styles: const PosStyles(bold: true));
  //   return bytes;
  // }

  static List<int> _printFooter(Generator generator) {
    List<int> bytes = [];
    bytes += generator.feed(2);
    bytes += generator.text('Terimakasih Atas Kunjungannya', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

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
}
