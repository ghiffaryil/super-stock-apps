// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';

//FORM HALAMAN
import 'package:sistem_gudang/Home.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;

  //Variable Form
  var Username = TextEditingController();
  var Password = TextEditingController();

  bool _showHidePassword = true;
  bool isLoading = false;

  var presscount = 0;

  @override
  void initState() {
    super.initState();
    RefreshFungsi();
  }

  Future RefreshFungsi() async {
    await CekKoneksiInternet();
  }

  //FUNGSI CEK KONEKSI
  Future<void> CekKoneksiInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      setState(() {
        Terhubung_Ke_Internet = true;
      });
    } else {
      setState(() {
        Terhubung_Ke_Internet = false;
      });
    }
  }

// FUNGSI SHOW / HIDE PASSWORD
  void _toggle() {
    setState(() {
      _showHidePassword = !_showHidePassword;
    });
  }

  //FUNGSI LOGIN
  Future SubmitLogin() async {
    print('Submit Login');
    await CekKoneksiInternet();

    var Endpoint_API = "api/inti/v1/login/login.php";
    Map data_body = {
      "Username": Username.text,
      "Password": Password.text,
    };

    if (Terhubung_Ke_Internet == true) {
      try {
        print(Var_URL_API + Endpoint_API);
        print(data_body);
        final response = await http
            .post(
          Uri.parse(Var_URL_API + Endpoint_API),
          headers: {
            // "Content-Type": "multipart/form-data",
          },
          body: data_body,
        )
            .then((value) {
          print(value);
          if (value.statusCode == 200) {
            final data = jsonDecode(value.body);
            log(value.body);
            if (data['Status'] == "Sukses") {
              Map InformasiLogin = data['Data'];
              // FUNGSI SIMPAN DATA KE STORE LOCAL
              _DataSharedPreferences.SetDataSharedPreferences(
                  "Informasi_Login", InformasiLogin);
              // FUNGSI SIMPAN DATA KE STORE LOCAL

              // ALERT BERHASIL
              AlertDialog alert = AlertDialog(
                title: Text("Sukses"),
                content: Container(
                  child: Text("Login Berhasil"),
                ),
                actions: [
                  TextButton(
                    child: Text('Ok'),
                    onPressed: () {
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.push(
                          context,
                          //routing into add page
                          MaterialPageRoute(builder: (context) => Home()));
                    },
                  ),
                ],
              );
              showDialog(
                context: context,
                builder: (context) => alert,
                barrierDismissible: false,
              );
            } else {
              // ALERT GAGAL
              AlertDialog alert = AlertDialog(
                title: Text("Login Gagal"),
                content: Container(
                  child: Text("Username atau Password Salah"),
                ),
                actions: [
                  TextButton(
                    child: Text('Tutup'),
                    onPressed: () {
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
              showDialog(
                context: context,
                builder: (context) => alert,
                barrierDismissible: false,
              );
            }
          }
        });
      } catch (e) {
        print(e);
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        presscount++;
        if (presscount == 2) {
          exit(0);
        } else {
          var snackBar = SnackBar(
              content: Text(
                  'Tekan "kembali" sekali lagi untuk keluar dari aplikasi'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return false;
        }
      },
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: Container(
            padding: EdgeInsets.all(30.0),
            alignment: Alignment.center,
            width: double.infinity,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                        child: Image.asset('lib/media/logo/fsred.png',
                            width: 130, height: 130)),
                    SizedBox(height: 25),
                    Text(
                      'Super Stock',
                      style: TextStyle(
                          fontSize: 30,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 35),
                    TextFormField(
                      controller: Username,
                      decoration: InputDecoration(
                        labelText: "Username",
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: Icon(Icons.person, size: 24),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Username tidak boleh kosong!';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        value.trim().toLowerCase();
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: Password,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _showHidePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: Icon(Icons.lock_rounded, size: 24),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                          child: GestureDetector(
                            onTap: _toggle,
                            child: Icon(
                              _showHidePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Password tidak boleh kosong!';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 232, 18, 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          minimumSize: Size(200, 50),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                "Masuk",
                                style: TextStyle(color: Colors.white),
                              ),
                        onPressed: () {
                          //validate
                          if (_formKey.currentState!.validate()) {
                            //send data to database with this method
                            setState(() {
                              isLoading = true;
                            });
                            SubmitLogin();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
