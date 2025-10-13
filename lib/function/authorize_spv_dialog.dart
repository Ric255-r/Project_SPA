// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCancelTransactionDialog(BuildContext context, void Function(String) onConfirm) async {
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Use an RxBool for reactive state management with GetX
  final RxBool isPasswordVisible = false.obs;

  Get.dialog(
    AlertDialog(
      title: const Text("Batal Transaksi"),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan Password untuk membatalkan transaksi"),
            const SizedBox(height: 10),
            Obx(
              // Obx listens to changes in observable variables
              () => TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible.value, // Access value with .value
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      isPasswordVisible.toggle(); // Toggle the RxBool value
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // Use Get.back() to close dialog
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Get.back(); // Close dialog
              onConfirm(passwordController.text); // Handle password
            }
          },
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
}


  // Cara Caching. Minusnya Ntr Klo Update tktny g fungsi
  // Expanded(
  //   // Use a single FutureBuilder to fetch the data once.
  //   child: Builder(
  //     builder: (context) {
  //       // Gunakan data yang sudah di-cache
  //       final dataOri = c.detailTrans[item['id_transaksi']] ?? {};
  //       List<dynamic> dataAddOn = dataOri['all_addon'] ?? [];
  //       int totalAddOnAll = 0;

  //       // Calculate the total for all add-ons with tax, performed only once.
  //       if (item['total_addon'] != 0) {
  //         for (var addon in dataAddOn) {
  //           double pajak = addon['type'] == 'fnb' ? c.pajakFnb.value : c.pajakMsg.value;
  //           double nominalPjk = addon['harga_total'] * pajak;
  //           double addOnSblmBulat = addon['harga_total'] + nominalPjk;
  //           totalAddOnAll += (addOnSblmBulat / 1000).round() * 1000;
  //         }
  //       }

  //       // Build the Row with the calculated data.
  //       return Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           // First child: Conditionally display the "Unpaid" status.
  //           if (item['status'] == "unpaid" ||
  //               item['status'] == 'done-unpaid' ||
  //               item['status'] == 'done-unpaid-addon' ||
  //               item['total_addon'] != 0) ...[
  //             Builder(
  //               builder: (context) {
  //                 String teks;
  //                 int totalDanAddon = item['gtotal_stlh_pajak'] + totalAddOnAll;
  //                 int jlhBayar = item['jumlah_bayar'] - item['jumlah_kembalian'];

  //                 if (item['status'] == "done-unpaid" || item['status'] == "unpaid") {
  //                   teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
  //                 } else {
  //                   teks = "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
  //                 }

  //                 return Text(
  //                   teks,
  //                   style: TextStyle(
  //                     fontFamily: 'Poppins',
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.red.shade700,
  //                   ),
  //                 );
  //               },
  //             ),
  //           ] else ...[
  //             // Render an empty Text to maintain space if the condition is false.
  //             Text(""),
  //           ],

  //           // Second child: Always display the final total.
  //           Text(
  //             'Total: ${c.currencyFormatter.format(item['gtotal_stlh_pajak'] + totalAddOnAll)}',
  //             style: TextStyle(
  //               fontFamily: 'Poppins',
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.blue.shade700,
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   ),
  // ),
  //  Cara Awal
  // Expanded(
  //   child: Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       if (item['status'] == "unpaid" ||
  //           item['status'] == 'done-unpaid' ||
  //           item['status'] == 'done-unpaid-addon' ||
  //           item['total_addon'] != 0) ...[

  //         // Pake widget builder buat bs anok fungsi
  //         Builder(
  //           builder: (context) {
  //             var teks = "";

  //             int totalAddOnOri = item['total_addon'];
  //             var totalAddOnAll = 0;
  //             if (item['total_addon'] != 0) {
  //               double desimalPjk = item['pajak'];
  //               double nominalPjk = totalAddOnOri * desimalPjk;
  //               // Pembulatan 1000
  //               double addOnSblmBulat = totalAddOnOri + nominalPjk;
  //               totalAddOnAll = (addOnSblmBulat / 1000).round() * 1000;
  //             }

  //             int totalDanAddon = item['gtotal_stlh_pajak'] + totalAddOnAll;
  //             int jlhBayar = item['jumlah_bayar'] - item['jumlah_kembalian'];

  //             if (item['status'] == "done-unpaid" || item['status'] == "unpaid") {
  //               teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";

  //               // Case kalo dia udh bayar, tp ganti paket yg lebih mahal
  //               // if (totalDanAddon > jlhBayar) {
  //               //   teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
  //               // }
  //             } else {
  //               teks = "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
  //             }
  //             return Text(
  //               teks,
  //               style: TextStyle(
  //                 fontFamily: 'Poppins',
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.red.shade700,
  //               ),
  //             );
  //           },
  //         ),
  //       ] else ...[
  //         Text(""),
  //       ],

  //       Builder(
  //         builder: (context) {
  //           int totalAddOnOri = item['total_addon'];
  //           var totalAddOnAll = 0;
  //           if (item['total_addon'] != 0) {
  //             double desimalPjk = item['pajak'];
  //             double nominalPjk = totalAddOnOri * desimalPjk;
  //             // Pembulatan 1000
  //             double addOnSblmBulat = totalAddOnOri + nominalPjk;
  //             totalAddOnAll = (addOnSblmBulat / 1000).round() * 1000;
  //           }

  //           return Text(
  //             'Total: ${c.currencyFormatter.format(item['gtotal_stlh_pajak'] + totalAddOnAll)}',
  //             style: TextStyle(
  //               fontFamily: 'Poppins',
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.blue.shade700,
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   ),
  // ),