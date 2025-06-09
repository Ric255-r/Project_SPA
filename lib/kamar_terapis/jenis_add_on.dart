// import 'package:Project_SPA/kamar_terapis/addon_extend.dart';
// import 'package:Project_SPA/kamar_terapis/addon_food.dart';
// import 'package:Project_SPA/kamar_terapis/addon_paket.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class JenisAddOn extends StatefulWidget {
//   const JenisAddOn({super.key});

//   @override
//   State<JenisAddOn> createState() => _JenisAddOnState();
// }

// class _JenisAddOnState extends State<JenisAddOn> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
//         width: Get.width,
//         height: Get.height,
//         child: Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.only(top: Get.height * 0.1),
//               child: Text(
//                 'PLATINUM',
//                 style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.only(top: 40),
//               child: Text(
//                 "Pilih Jenis Add On (+)",
//                 style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.only(top: 60, left: 50, right: 50),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Get.to(PaketAddOn());
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white),
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       height: 240,
//                       width: 210,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.only(top: 40, right: 15),
//                             child: Icon(FontAwesomeIcons.spa, size: 110),
//                           ),

//                           Padding(
//                             padding: EdgeInsets.only(top: 20),
//                             child: Column(
//                               children: [
//                                 Text(
//                                   'Penambahan',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontFamily: 'Poppins',
//                                   ),
//                                 ),
//                                 Text(
//                                   'Paket',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontFamily: 'Poppins',
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Get.to(FoodAddOn());
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white),
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       height: 240,
//                       width: 210,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Icon(Icons.local_dining_rounded, size: 160),
//                           Text(
//                             'Food & Beverages',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontFamily: 'Poppins',
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Get.to(());
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white),
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       height: 240,
//                       width: 210,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.only(top: 40, right: 20),
//                             child: Icon(
//                               FontAwesomeIcons.cartShopping,
//                               size: 110,
//                             ),
//                           ),

//                           Padding(
//                             padding: EdgeInsets.only(top: 20),
//                             child: Column(
//                               children: [
//                                 Text(
//                                   'Penambahan',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontFamily: 'Poppins',
//                                   ),
//                                 ),
//                                 Text(
//                                   'Produk',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontFamily: 'Poppins',
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Get.to(ExtendAddOn(idDetailTransaksi: ''));
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white),
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       height: 240,
//                       width: 210,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.only(top: 30),
//                             child: Icon(Icons.timer, size: 140),
//                           ),

//                           Padding(
//                             padding: EdgeInsets.only(top: 12),
//                             child: Text(
//                               'Extends Jam',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontFamily: 'Poppins',
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
