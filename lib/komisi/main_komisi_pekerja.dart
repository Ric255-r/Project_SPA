import 'package:Project_SPA/function/our_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class PageKomisiPekerja extends StatefulWidget {
  const PageKomisiPekerja({super.key});

  @override
  State<PageKomisiPekerja> createState() => _PageKomisiPekerjaState();
}

class _PageKomisiPekerjaState extends State<PageKomisiPekerja> {
  ScrollController _scrollControllerTab0 = ScrollController();
  ScrollController _scrollControllerTab1 = ScrollController();
  ScrollController _scrollControllerTab2 = ScrollController();

  RxInt activeTab = 0.obs;
  RxDouble totalkomisi = 0.0.obs;
  RxDouble totalkomisibulanan = 0.0.obs;
  var isloadingkomisiharian = true.obs;
  var isloadingkomisibulanan = true.obs;

  RxList<Map<String, dynamic>> listdatakomisi = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> listdatakomisibulanan =
      <Map<String, dynamic>>[].obs;

  var dio = Dio();
  var idkaryawan = '';
  var namakaryawan = '';
  var jabatan = '';
  RxString selectedvalue = DateTime.now().month.toString().obs;
  RxString selectedyearvalue = DateTime.now().year.toString().obs;
  String hurufpertamanama = '';
  String dateonly = '';
  String formatrupiah(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    refreshdatalistkomisi();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> getdatalistkomisi() async {
    try {
      isloadingkomisiharian.value = true;
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisi',
        data: {
          "id_user": idkaryawan,
          "month": int.parse(selectedvalue.value),
          "year": int.parse(selectedyearvalue.value),
        },
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nominal_komisi": item['nominal_komisi'],
              "created_at": DateTime.parse(item['created_at']),
            };
          }).toList();
      setState(() {
        listdatakomisi.clear();
        listdatakomisi.assignAll(fetcheddata);
        listdatakomisi.refresh();
      });
      isloadingkomisiharian.value = false;
    } catch (e) {
      log("Error di fn getdatalistkomisi : $e");
      isloadingkomisiharian.value = false;
    }

    for (int i = 0; i < listdatakomisi.length; i++) {
      totalkomisi.value += listdatakomisi[i]['nominal_komisi'];
    }
  }

  Future<void> getidkaryawan() async {
    try {
      final prefs = await getTokenSharedPref();
      var response = await getMyData(prefs);

      Map<String, dynamic> responseData = response['data'];
      log("data yang aku ambil $responseData");
      idkaryawan = responseData['id_karyawan'];
      namakaryawan = responseData['nama_karyawan'];
      jabatan = responseData['jabatan'];
    } catch (e) {
      log("Error di getidkaryawan $e");
    }
  }

  Future<void> refreshdatalistkomisi() async {
    await Future.delayed(Duration(seconds: 1));
    await getidkaryawan();
    await getdatalistkomisi();
    await getdatalistkomisibulanan();
    hurufpertamanama = namakaryawan[0];
  }

  Future<void> getdatalistkomisibulanan() async {
    isloadingkomisibulanan.value = true;
    try {
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisimonthly',
        data: {
          "id_user": idkaryawan,
          "year": int.parse(selectedyearvalue.value),
        },
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "month": item['month'],
              "year": item['year'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        log('list data bulanan : ${fetcheddata.toString()}');
        listdatakomisibulanan.clear();
        listdatakomisibulanan.assignAll(fetcheddata);
        listdatakomisibulanan.refresh();
      });
      isloadingkomisibulanan.value = false;
    } catch (e) {
      log("Error di fn getdatalistkomisibulanan : $e");
      isloadingkomisibulanan.value = false;
    }
    for (int i = 0; i < listdatakomisibulanan.length; i++) {
      totalkomisibulanan.value += listdatakomisibulanan[i]['total_komisi'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0XFFFFE0B2),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: Text("", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.landscape
              ? SingleChildScrollView(
                child: Container(
                  height: 700,
                  width: Get.width,
                  decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: Get.width - 20,
                        padding: const EdgeInsets.only(left: 20, top: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: SizedBox(
                                    height: 70,
                                    width: 70,
                                    child: CircleAvatar(
                                      child: Text(
                                        hurufpertamanama,
                                        style: TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          namakaryawan,
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          jabatan,
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Laporan Komisi",
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Obx(
                        () => Row(
                          children: [
                            activeTab.value == 0
                                ? Container(
                                  margin: EdgeInsets.only(left: 30),
                                  child: Text(
                                    'Bulan : ',
                                    style: TextStyle(fontSize: 25),
                                  ),
                                )
                                : SizedBox.shrink(),
                            activeTab.value == 0
                                ? Obx(
                                  () => Container(
                                    width: 140,
                                    height: 55,
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                      ),
                                      value: selectedvalue.value,
                                      items:
                                          <String>[
                                            '1',
                                            '2',
                                            '3',
                                            '4',
                                            '5',
                                            '6',
                                            '7',
                                            '8',
                                            '9',
                                            '10',
                                            '11',
                                            '12',
                                          ].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value == '1'
                                                    ? 'Januari'
                                                    : value == '2'
                                                    ? 'Februari'
                                                    : value == '3'
                                                    ? 'Maret'
                                                    : value == '4'
                                                    ? 'April'
                                                    : value == '5'
                                                    ? 'Mei'
                                                    : value == '6'
                                                    ? 'Juni'
                                                    : value == '7'
                                                    ? 'Juli'
                                                    : value == '8'
                                                    ? 'Agustus'
                                                    : value == '9'
                                                    ? 'September'
                                                    : value == '10'
                                                    ? 'Oktober'
                                                    : value == '11'
                                                    ? 'September'
                                                    : 'Desember',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        selectedvalue.value = newValue!;
                                      },
                                    ),
                                  ),
                                )
                                : SizedBox.shrink(),
                            Container(
                              margin: EdgeInsets.only(left: 30),
                              child: Text(
                                'Tahun : ',
                                style: TextStyle(fontSize: 25),
                              ),
                            ),
                            Obx(
                              () => Container(
                                width: 140,
                                height: 55,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                  value: selectedyearvalue.value,
                                  items:
                                      List.generate(
                                        DateTime.now().year - 2000 + 1,
                                        (index) => 2000 + index,
                                      ).map((int year) {
                                        return DropdownMenuItem<String>(
                                          value: year.toString(),
                                          child: Text(year.toString()),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    selectedyearvalue.value = newValue!;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Container(
                              width: 100,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  totalkomisi.value = 0;
                                  totalkomisibulanan.value = 0;
                                  isloadingkomisiharian.value = true;
                                  isloadingkomisibulanan.value = true;
                                  refreshdatalistkomisi();
                                },
                                // ignore: sort_child_properties_last
                                child: Text(
                                  'Cek',
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.black,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFCEFCB),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 20),
                                width: Get.width - 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: ClipRRect(
                                  // Moved ClipRRect inside
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: TabBar(
                                    onTap: (index) {
                                      activeTab.value = index;
                                      print(
                                        "Tab Aktif Skrg ${activeTab.value}",
                                      );
                                    },
                                    indicator: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelColor: Colors.black,
                                    unselectedLabelColor: Colors.black38,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    tabs: const [
                                      Tab(text: "Daily"),
                                      Tab(text: "Monthly"),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: 300,
                                width: Get.width - 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                ),
                                child: TabBarView(
                                  children: [
                                    // Konten 1
                                    Obx(
                                      () => Container(
                                        width: Get.width,
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
                                        child:
                                            isloadingkomisiharian.value == true
                                                ? Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                                : listdatakomisi.isEmpty
                                                ? Center(
                                                  child: Text(
                                                    'Tidak ada data komisi untuk bulan $selectedvalue di tahun $selectedyearvalue',
                                                  ),
                                                )
                                                : Scrollbar(
                                                  thumbVisibility: true,
                                                  controller:
                                                      _scrollControllerTab0,
                                                  child: ListView.builder(
                                                    controller:
                                                        _scrollControllerTab0,
                                                    itemCount:
                                                        listdatakomisi.length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      var item =
                                                          listdatakomisi[index];
                                                      DateTime tanggalkerja =
                                                          item['created_at'];
                                                      String
                                                      formattanggalkerja =
                                                          "${tanggalkerja.year}-${tanggalkerja.month}-${tanggalkerja.day} / ${tanggalkerja.hour}:${tanggalkerja.minute.toString().padLeft(2, '0')}";
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 10,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    formattanggalkerja
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    formatrupiah(
                                                                      item['nominal_komisi'],
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Divider(),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                      ),
                                    ),
                                    // Konten 2
                                    Obx(
                                      () => Container(
                                        width: Get.width,
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
                                        child:
                                            isloadingkomisibulanan.value == true
                                                ? Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                                : listdatakomisibulanan.isEmpty
                                                ? Center(
                                                  child: Text(
                                                    'Tidak ada data komisi untuk tahun $selectedyearvalue',
                                                  ),
                                                )
                                                : Scrollbar(
                                                  thumbVisibility: true,
                                                  controller:
                                                      _scrollControllerTab2,
                                                  child: ListView.builder(
                                                    controller:
                                                        _scrollControllerTab2,
                                                    itemCount:
                                                        listdatakomisibulanan
                                                            .length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      var item =
                                                          listdatakomisibulanan[index];
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 10,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    "${item['month']} - ${item['year']}",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    formatrupiah(
                                                                      item['total_komisi'],
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Divider(),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Obx(
                                () => Container(
                                  height: 50,
                                  width: Get.width - 70,
                                  padding: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    color: Colors.grey[200],
                                  ),
                                  child:
                                      activeTab.value == 0
                                          ? Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Total Komisi Daily",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                SizedBox(width: 30),
                                                Text(
                                                  formatrupiah(
                                                    totalkomisi.value,
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Total Komisi Monthly",
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 20,
                                                ),
                                              ),
                                              SizedBox(width: 30),
                                              Text(
                                                formatrupiah(
                                                  totalkomisibulanan.value,
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SizedBox.shrink();
        },
      ),

      drawer: OurDrawer(),
    );
  }
}
