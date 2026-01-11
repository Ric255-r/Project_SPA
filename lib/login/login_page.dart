// login_page.dart (Stateless)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:Project_SPA/function/confirm_logout.dart'; // untuk showPopupExit
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final c = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async => await showPopupExit(),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.yellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 150),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(width: 0, color: Colors.black),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/spa.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 100),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        margin: const EdgeInsets.only(top: 40),
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          focusNode: c.firstFocus,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            FocusScope.of(context).requestFocus(c.secondFocus);
                          },
                          controller: c.userC,
                          decoration: const InputDecoration(
                            hintText: 'Isi User ID',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        margin: const EdgeInsets.only(top: 20),
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          focusNode: c.secondFocus,
                          textInputAction: TextInputAction.done,
                          controller: c.passC,
                          decoration: const InputDecoration(
                            hintText: 'Isi Password',
                            border: InputBorder.none,
                          ),
                          obscureText: true,
                          onSubmitted: (_) => c.login(context),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (c.userC.text.isNotEmpty && c.passC.text.isNotEmpty) {
                                await c.login(context);
                              } else {
                                CherryToast.warning(
                                  title: const Text('Warning'),
                                  description: const Text('Inputan Username / Password Kosong'),
                                ).show(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                            child: const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }
}
