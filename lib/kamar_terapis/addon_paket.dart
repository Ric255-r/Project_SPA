import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';

class PaketAddOn extends StatefulWidget {
  const PaketAddOn({super.key});

  @override
  State<PaketAddOn> createState() => _PaketAddOnState();
}

class _PaketAddOnState extends State<PaketAddOn> {
  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Add On (+)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        padding: const EdgeInsets.only(left: 80, right: 80),
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                "Paket Penambahan Pelayanan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 30),
              Container(
                height: 250,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 item 1 row
                            crossAxisSpacing: 60, // space horizontal tiap item
                            mainAxisSpacing: 25, // space vertical tiap item

                            childAspectRatio: 20 / 12,
                          ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        RxBool _isTapped = false.obs;

                        return GestureDetector(
                          onTapDown: (_) {
                            _isTapped.value = true;
                          },
                          onTapUp: (_) {
                            _isTapped.value = false;
                          },
                          onTapCancel: () {
                            _isTapped.value = false;
                          },
                          onTap: () {
                            print("Pencet Paket");
                          },
                          child: Obx(
                            () => Transform.scale(
                              scale: _isTapped.isTrue ? 0.95 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 64, 97, 55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.feed_outlined,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      "Item ${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      "Rp. 50000",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                "List Pesanan: ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Burger",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "x1",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Rp. 80000",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "X",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(child: Text("")),
                  Expanded(
                    child: Text(
                      "Total Add On: ",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Rp. 80000",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                        Expanded(child: Text("")),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    minimumSize: Size(100, 40),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Proses",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
