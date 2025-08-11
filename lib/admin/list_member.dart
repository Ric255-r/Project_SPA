import 'dart:convert';
import 'dart:developer';

import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:dio/dio.dart';
import 'package:cherry_toast/cherry_toast.dart';

class ListMember extends StatefulWidget {
  const ListMember({super.key});

  @override
  State<ListMember> createState() => _ListMemberState();
}

class _ListMemberState extends State<ListMember> {
  ScrollController _scrollController = ScrollController();
  RxList<dynamic> _ListMember = [].obs;

  var dio = Dio();
  Future<void> _getMember() async {
    try {
      var response = await dio.get('${myIpAddr()}/listmember/member');

      List<dynamic> responseData = response.data;

      _ListMember.assignAll(responseData); // main list
      _ListMemberFiltered.assignAll(
        responseData,
      ); // filtered list starts as full list

      log("Isi List Member: $_ListMember");
    } catch (e) {
      log("Gagal ambil data member: $e");
    }
  }

  Future<void> fetchQRMember(Map<String, dynamic> member) async {
    try {
      final idMember = member['id_member'];
      final response = await dio.get(
        '${myIpAddr()}/history/detail_member/$idMember',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Inject qr_url into the member map
        member['qr_url'] = data['qr_url'];
      } else {
        print("Failed to fetch QR Member. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching QR Member: $e");
    }
  }

  List<dynamic> historyMember = [];
  Future<void> _fetchHistoryMember(String id_member) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/history/historymember/$id_member',
      ); // API request
      if (response.statusCode == 200) {
        setState(() {
          historyMember = response.data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching ID: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error fetching ID: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching ID")));
    }
  }

  // Bagian idKaryawan
  RxString _idKaryawan = "".obs;
  // Bagian Old Pass
  RxBool _obscureOldPasswd = true.obs;
  TextEditingController _passwdOldController = TextEditingController();
  // Bagian New Pass
  RxBool _obscureNewPasswd = true.obs;
  TextEditingController _passwdNewController = TextEditingController();
  // Bagian Confirm Pass
  RxBool _obscureConfirmPasswd = true.obs;
  TextEditingController _passwdConfirmController = TextEditingController();
  // Hak Akses
  RxString _hakAkses = "".obs;
  RxString _namaHakAkses = "".obs;
  // RxList<dynamic> _roleOptions = [].obs;
  RxList<dynamic> _hakAksesTambahan = [].obs;
  RxList<dynamic> _selectedHakAksesTambah = [].obs;
  // End Hak Akses

  Widget dialogDetail(int index) {
    final member = _ListMember[index];
    return AlertDialog(
      title: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(),
                Text(
                  "Detail Data Member",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.cancel),
                ),
              ],
            ),
            Divider(),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Container(
          height: Get.height - 100,
          width: Get.width - 100,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  Container(
                    height: 30,
                    width: 170,
                    child: Text(
                      "Kode Promo",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    height: 30,
                    width: 140,
                    child: Text(
                      "Nama Promo",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 80),
                  Container(
                    height: 30,
                    width: 170,
                    child: Text(
                      "Sisa Kunjungan",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 18),
                  Container(
                    height: 50,
                    width: 150,
                    child: Text(
                      "Kunjungan\nBerlaku Sampai",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 30),
                  Container(
                    height: 50,
                    width: 160,
                    child: Text(
                      "Tahunan\nBerlaku Sampai",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                height: 270,
                width: Get.width - 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child:
                    historyMember.isEmpty
                        ? Center(
                          child: Text(
                            "Tidak Ada Data",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        )
                        : ListView.builder(
                          itemCount: historyMember.length,
                          itemBuilder: (context, index) {
                            final item = historyMember[index];
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 120,
                                        child: Text(
                                          item['kode_promo'] ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                        child: Text(
                                          "|",
                                          style: TextStyle(fontSize: 21),
                                        ),
                                      ),
                                      Container(
                                        width: 240,
                                        child: Text(
                                          item['nama_promo'] ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 75,
                                        child: Text(
                                          "|",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 21),
                                        ),
                                      ),
                                      Container(
                                        width: 110,
                                        child: Text(
                                          item['sisa_kunjungan'] != null &&
                                                  item['sisa_kunjungan'] != ''
                                              ? '${item['sisa_kunjungan']} Kali'
                                              : '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          "|",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 21),
                                        ),
                                      ),
                                      Container(
                                        width: 135,
                                        child: Text(
                                          item['exp_kunjungan'] != null &&
                                                  item['exp_kunjungan'] != ''
                                              ? '${item['exp_kunjungan']}'
                                              : '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          "|",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 21),
                                        ),
                                      ),
                                      Container(
                                        width: 100,
                                        child: Text(
                                          item['exp_tahunan'] != null &&
                                                  item['exp_tahunan'] != ''
                                              ? '${item['exp_tahunan']}'
                                              : '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                  height: 1,
                                ),
                              ],
                            );
                          },
                        ),
              ),
              SizedBox(height: 20),
              if (member['qr_url'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.network(
                    member['qr_url'],
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('QR code not available');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMember(int index) async {
    try {
      var id_member = _ListMember[index]['id_member'];

      var response = await dio.delete(
        '${myIpAddr()}/listmember/deletemember/${id_member}',
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Data berhasil dihapus')).show(context);

        _getMember();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Delete User ${e.response?.data}");
      }
    }
  }

  TextEditingController _searchController = TextEditingController();
  RxList<dynamic> _ListMemberFiltered = [].obs;
  void _runSearch() {
    String keyword = _searchController.text.toLowerCase().trim();

    if (keyword.isEmpty) {
      _ListMemberFiltered.assignAll(_ListMember); // reset to full list
      return;
    }

    final filtered =
        _ListMember.where((item) {
          final nama = (item['nama'] ?? '').toString().toLowerCase().trim();
          final kode =
              (item['id_member'] ?? '').toString().toLowerCase().trim();
          final matches = nama.contains(keyword) || kode.contains(keyword);
          print(
            "Checking → id_member: $kode, nama: $nama, keyword: $keyword → Matches: $matches",
          );
          return matches;
        }).toList();

    _ListMemberFiltered.assignAll(filtered);
    print("Filtered result count: ${_ListMemberFiltered.length}");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getMember().then((_) => _runSearch());
    _searchController.clear();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _passwdOldController.dispose();
    _passwdNewController.dispose();
    _passwdConfirmController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final bool isMobile = shortest < 600 || shortest > 700;
    log("isi Shortest Side ${MediaQuery.of(context).size.shortestSide}");
    // =======================================================================

    // 1. Tentukan lebar desain dasar Anda
    // 660 ini lebar terkecil DP tablet yg kita patok.
    const double tabletDesignWidth = 660;
    const double tabletDesignHeight = 1024;

    // 2. Tentukan faktor penyesuaian untuk mobile.
    const double mobileAdjustmentFactor = 1.25; // UI akan 25% lebih kecil

    // 3. Hitung designSize yang efektif berdasarkan tipe perangkat
    final double effectiveDesignWidth =
        isMobile
            ? tabletDesignWidth * mobileAdjustmentFactor
            : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile
            ? tabletDesignHeight * mobileAdjustmentFactor
            : tabletDesignHeight;
    return isMobile
        ? WidgetListMemberMobile()
        : Scaffold(
          drawer: AdminDrawer(),
          appBar: AppBar(
            leading: Builder(
              builder:
                  (context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(Icons.menu),
                  ),
            ),
            backgroundColor: const Color(0XFFFFE0B2),
            toolbarHeight: 100,
            title: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset('assets/spa.jpg', height: 80, width: 80),
                ),
              ),
            ),
          ),
          body: Container(
            height: Get.height,
            width: Get.width,
            decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "List Member",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontSize: 30,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 70),
                    width: 220,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _runSearch();
                      },
                      decoration: InputDecoration(
                        hintText: "Cari nama atau id member",
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  height: 400,
                  width: Get.width - 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Id Member",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Nama Member",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "No HP",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Status",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Aksi",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      // Data Row
                      SizedBox(
                        height: 300,
                        child: Obx(() {
                          if (_ListMember.isEmpty) {
                            return Center(child: Text("No Data"));
                          }
                          return Scrollbar(
                            thumbVisibility: true,
                            radius: Radius.circular(10),
                            controller: _scrollController,
                            child: Obx(
                              () => ListView.builder(
                                controller: _scrollController,
                                itemCount: _ListMemberFiltered.length,
                                itemBuilder: (context, index) {
                                  final member = _ListMemberFiltered[index];
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${member['id_member'] ?? '-'}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "${member['nama'] ?? '-'}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${member['no_hp']}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${member['status']}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                // Show loading
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (_) => Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                );

                                                await _fetchHistoryMember(
                                                  member['id_member'],
                                                );
                                                await fetchQRMember(member);

                                                Navigator.pop(
                                                  context,
                                                ); // remove loading dialog

                                                // Show your custom dialog
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (_) =>
                                                          dialogDetail(index),
                                                );
                                              },
                                              child: Text("Detail"),
                                            ),

                                            SizedBox(width: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.dialog(
                                                  AlertDialog(
                                                    title: Text('Confirm'),
                                                    content: Text(
                                                      'Yakin menghapus data?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Get.back();
                                                        },
                                                        child: Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          await _deleteMember(
                                                            index,
                                                          );
                                                          Get.back();
                                                          _getMember();
                                                        },
                                                        child: Text('Confirm'),
                                                      ),
                                                    ],
                                                  ),
                                                  barrierDismissible: false,
                                                );
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class WidgetListMemberMobile extends StatefulWidget {
  const WidgetListMemberMobile({super.key});

  @override
  State<WidgetListMemberMobile> createState() => _WidgetListMemberMobileState();
}

class _WidgetListMemberMobileState extends State<WidgetListMemberMobile> {
  ScrollController _scrollController = ScrollController();
  RxList<dynamic> _ListMember = [].obs;

  var dio = Dio();
  Future<void> _getMember() async {
    try {
      var response = await dio.get('${myIpAddr()}/listmember/member');

      List<dynamic> responseData = response.data;

      _ListMember.assignAll(responseData); // main list
      _ListMemberFiltered.assignAll(
        responseData,
      ); // filtered list starts as full list

      log("Isi List Member: $_ListMember");
    } catch (e) {
      log("Gagal ambil data member: $e");
    }
  }

  Future<void> fetchQRMember(Map<String, dynamic> member) async {
    try {
      final idMember = member['id_member'];
      final response = await dio.get(
        '${myIpAddr()}/history/detail_member/$idMember',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Inject qr_url into the member map
        member['qr_url'] = data['qr_url'];
      } else {
        print("Failed to fetch QR Member. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching QR Member: $e");
    }
  }

  List<dynamic> historyMember = [];
  Future<void> _fetchHistoryMember(String id_member) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/history/historymember/$id_member',
      ); // API request
      if (response.statusCode == 200) {
        setState(() {
          historyMember = response.data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching ID: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error fetching ID: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching ID")));
    }
  }

  // Bagian idKaryawan
  RxString _idKaryawan = "".obs;
  // Bagian Old Pass
  RxBool _obscureOldPasswd = true.obs;
  TextEditingController _passwdOldController = TextEditingController();
  // Bagian New Pass
  RxBool _obscureNewPasswd = true.obs;
  TextEditingController _passwdNewController = TextEditingController();
  // Bagian Confirm Pass
  RxBool _obscureConfirmPasswd = true.obs;
  TextEditingController _passwdConfirmController = TextEditingController();
  // Hak Akses
  RxString _hakAkses = "".obs;
  RxString _namaHakAkses = "".obs;
  // RxList<dynamic> _roleOptions = [].obs;
  RxList<dynamic> _hakAksesTambahan = [].obs;
  RxList<dynamic> _selectedHakAksesTambah = [].obs;
  // End Hak Akses

  Widget dialogDetail(int index) {
    final member = _ListMember[index];
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Spacer(),
                      Text(
                        "Detail Data Member",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(Icons.cancel),
                      ),
                    ],
                  ),
                  Divider(),
                ],
              ),
            ),
            Container(
              height: Get.height + 200,
              width: Get.width,
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 10),
                      Container(
                        height: 30,
                        width: 140,
                        child: Text(
                          "Kode Promo",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 30,
                        width: 115,
                        child: Text(
                          "Nama Promo",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 55),
                      Container(
                        height: 50,
                        width: 100,
                        child: Text(
                          "Sisa\nKunjungan",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 5),
                      Container(
                        height: 50,
                        width: 120,
                        child: Text(
                          "Kunjungan\nBerlaku Sampai",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 5),
                      Container(
                        height: 50,
                        width: 115,
                        child: Text(
                          "Tahunan\nBerlaku Sampai",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 250,
                    width: Get.width - 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    child:
                        historyMember.isEmpty
                            ? Center(
                              child: Text(
                                "Tidak Ada Data",
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            )
                            : ListView.builder(
                              itemCount: historyMember.length,
                              itemBuilder: (context, index) {
                                final item = historyMember[index];
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                        horizontal: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            child: Text(
                                              item['kode_promo'] ?? '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                            child: Text(
                                              "|",
                                              style: TextStyle(fontSize: 21),
                                            ),
                                          ),
                                          Container(
                                            width: 220,
                                            child: Text(
                                              item['nama_promo'] ?? '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              "|",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(fontSize: 21),
                                            ),
                                          ),
                                          Container(
                                            width: 70,
                                            child: Text(
                                              item['sisa_kunjungan'] != null &&
                                                      item['sisa_kunjungan'] !=
                                                          ''
                                                  ? '${item['sisa_kunjungan']} Kali'
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 25,
                                            child: Text(
                                              "|",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(fontSize: 21),
                                            ),
                                          ),
                                          Container(
                                            width: 95,
                                            child: Text(
                                              item['exp_kunjungan'] != null &&
                                                      item['exp_kunjungan'] !=
                                                          ''
                                                  ? '${item['exp_kunjungan']}'
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 25,
                                            child: Text(
                                              "|",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(fontSize: 21),
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            child: Text(
                                              item['exp_tahunan'] != null &&
                                                      item['exp_tahunan'] != ''
                                                  ? '${item['exp_tahunan']}'
                                                  : '',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      thickness: 1,
                                      color: Colors.grey.shade300,
                                      height: 1,
                                    ),
                                  ],
                                );
                              },
                            ),
                  ),
                  SizedBox(height: 20),
                  if (member['qr_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Image.network(
                        member['qr_url'],
                        width: 200,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Text('QR code not available');
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMember(int index) async {
    try {
      var id_member = _ListMember[index]['id_member'];

      var response = await dio.delete(
        '${myIpAddr()}/listmember/deletemember/${id_member}',
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Data berhasil dihapus')).show(context);

        _getMember();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Delete User ${e.response?.data}");
      }
    }
  }

  TextEditingController _searchController = TextEditingController();
  RxList<dynamic> _ListMemberFiltered = [].obs;
  void _runSearch() {
    String keyword = _searchController.text.toLowerCase().trim();

    if (keyword.isEmpty) {
      _ListMemberFiltered.assignAll(_ListMember); // reset to full list
      return;
    }

    final filtered =
        _ListMember.where((item) {
          final nama = (item['nama'] ?? '').toString().toLowerCase().trim();
          final kode =
              (item['id_member'] ?? '').toString().toLowerCase().trim();
          final matches = nama.contains(keyword) || kode.contains(keyword);
          print(
            "Checking → id_member: $kode, nama: $nama, keyword: $keyword → Matches: $matches",
          );
          return matches;
        }).toList();

    _ListMemberFiltered.assignAll(filtered);
    print("Filtered result count: ${_ListMemberFiltered.length}");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getMember().then((_) => _runSearch());
    _searchController.clear();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _passwdOldController.dispose();
    _passwdNewController.dispose();
    _passwdConfirmController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: Icon(Icons.menu),
              ),
        ),
        backgroundColor: const Color(0XFFFFE0B2),
        toolbarHeight: 100,
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset('assets/spa.jpg', height: 80, width: 80),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: Get.height,
          width: Get.width,
          decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "List Member",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 30,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(right: 70),
                  width: 220,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _runSearch();
                    },
                    decoration: InputDecoration(
                      hintText: "Cari nama atau id member",
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                height: 260,
                width: Get.width - 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id Member",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Nama Member",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "No HP",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Status",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "Aksi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    // Data Row
                    SizedBox(
                      height: 180,
                      child: Obx(() {
                        if (_ListMember.isEmpty) {
                          return Center(child: Text("No Data"));
                        }
                        return Scrollbar(
                          thumbVisibility: true,
                          radius: Radius.circular(10),
                          controller: _scrollController,
                          child: Obx(
                            () => ListView.builder(
                              controller: _scrollController,
                              itemCount: _ListMemberFiltered.length,
                              itemBuilder: (context, index) {
                                final member = _ListMemberFiltered[index];
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${member['id_member'] ?? '-'}",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "${member['nama'] ?? '-'}",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${member['no_hp']}",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${member['status']}",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Show loading
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (_) => Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                              );

                                              await _fetchHistoryMember(
                                                member['id_member'],
                                              );
                                              await fetchQRMember(member);

                                              Navigator.pop(
                                                context,
                                              ); // remove loading dialog

                                              // Show your custom dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => dialogDetail(index),
                                              );
                                            },
                                            child: Text("Detail"),
                                          ),

                                          SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.dialog(
                                                AlertDialog(
                                                  title: Text('Confirm'),
                                                  content: Text(
                                                    'Yakin menghapus data?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Get.back();
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await _deleteMember(
                                                          index,
                                                        );
                                                        Get.back();
                                                        _getMember();
                                                      },
                                                      child: Text('Confirm'),
                                                    ),
                                                  ],
                                                ),
                                                barrierDismissible: false,
                                              );
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
