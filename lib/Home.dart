// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print, unused_import

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

//FORM TEMPLATE
import 'template/DrawerMenu.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';
import 'package:sistem_gudang/fungsi/currency_format/currency_format.dart';

//FORM HALAMAN
import 'package:sistem_gudang/Login.dart';
import 'package:sistem_gudang/halaman/gudang_besar/ListDataTransaksiGudangBesar.dart';
import 'package:sistem_gudang/halaman/gudang_kecil/ListDataTransaksiGudangKecil.dart';
import 'package:sistem_gudang/halaman/omset/ListDataOmset.dart';
import 'package:sistem_gudang/halaman/input_harian/ListDataInputHarian.dart';

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;
  Map InformasiLogin = {};

  //Variable Form
  Map DataCabangSaatIni = {};
  List ListDataCabang = [];

  @override
  void initState() {
    super.initState();
    RefreshFungsi();
  }

  //FUNGSI UNTUK REFRESH FUNGSI-FUNGSI TERTENTU
  Future RefreshFungsi() async {
    setState(() {
      Loading_Form = true;
    });

    //FUNGSI MENGAMBIL DATA DARI STORE LOCAL
    var DataLocalInformasiLogin =
        await _DataSharedPreferences.BacaDataSharedPreferences(
            "Informasi_Login",
            Tipe: "array_object");
    //FUNGSI MENGAMBIL DATA DARI STORE LOCAL

    if (DataLocalInformasiLogin == null) {
      // FUNGSI HAPUS DATA STORE LOCAL
      _DataSharedPreferences.HapusDataSharedPreferences("Informasi_Login");
      // FUNGSI HAPUS DATA STORE LOCAL
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login()));
      return;
    }

    setState(() {
      InformasiLogin = DataLocalInformasiLogin;
    });

    await CekKoneksiInternet();
    if (Terhubung_Ke_Internet == true) {
      await BacaDataPenggunaSaatIni();
      await BacaDataCabangSaatIni();
      await BacaListDataCabang();
    }

    setState(() {
      Loading_Form = false;
    });
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

  //FUNGSI MEMBACA DATA PENGGUNA SAAT INI
  Future BacaDataPenggunaSaatIni() async {
    print('Baca Data');

    var Endpoint_API = "api/inti/v1/data_pengguna/baca_data_pengguna.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
    };
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
            Map InformasiLoginSaatIni = data['Data'];
            InformasiLoginSaatIni['Token_Login_Saat_Ini'] =
                InformasiLogin['Token_Login_Saat_Ini'];

            // FUNGSI SIMPAN DATA KE STORE LOCAL
            _DataSharedPreferences.SetDataSharedPreferences(
                "Informasi_Login", InformasiLoginSaatIni);
            // FUNGSI SIMPAN DATA KE STORE LOCAL

            setState(() {
              InformasiLogin = InformasiLoginSaatIni;
            });
          } else {
            // FUNGSI HAPUS DATA STORE LOCAL
            _DataSharedPreferences.HapusDataSharedPreferences(
                "Informasi_Login");
            // FUNGSI HAPUS DATA STORE LOCAL
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => Login()));
            return;
          }
        } else {
          // FUNGSI HAPUS DATA STORE LOCAL
          _DataSharedPreferences.HapusDataSharedPreferences("Informasi_Login");
          // FUNGSI HAPUS DATA STORE LOCAL
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Login()));
          return;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI MEMBACA DATA CABANG SAAT INI
  Future BacaDataCabangSaatIni() async {
    print('Baca Data');

    var Endpoint_API = "api/sistem_gudang/v1/cabang/baca_data_cabang.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Cabang": InformasiLogin['Id_Cabang'],
    };
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
            setState(() {
              DataCabangSaatIni = data['Data'];
            });
          } else {
            setState(() {
              DataCabangSaatIni = {};
            });
          }
        } else {
          setState(() {
            DataCabangSaatIni = {};
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI MEMBACA LIST DATA CABANG
  Future BacaListDataCabang() async {
    print('Baca List Data');

    var Endpoint_API = "api/sistem_gudang/v1/cabang/baca_list_data_cabang.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
    };
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
            setState(() {
              ListDataCabang = data['Data'];
            });
          } else {
            setState(() {
              ListDataCabang = [];
            });
          }
        } else {
          setState(() {
            ListDataCabang = [];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI GANTI CABANG
  Future GantiCabang(Id_Cabang) async {
    print('Ganti Cabang');
    var UpdateInformasiLogin = InformasiLogin;
    UpdateInformasiLogin['Id_Cabang'] = Id_Cabang;

    // FUNGSI SIMPAN DATA KE STORE LOCAL
    _DataSharedPreferences.SetDataSharedPreferences(
        "Informasi_Login", UpdateInformasiLogin);
    // FUNGSI SIMPAN DATA KE STORE LOCAL

    await BacaDataCabangSaatIni();
    Navigator.pop(context);
  }

  // FUNGSI MODAL CABANG
  void ModalCabang(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "List Cabang :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Silahkan pilih salah satu cabang untuk beralih cabang",
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: false,
                  itemCount: Loading_Form
                      ? ListDataCabang.length + 1
                      : ListDataCabang.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index < ListDataCabang.length) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () {
                            GantiCabang(ListDataCabang[index]['Id_Cabang']);
                          },
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            semanticContainer: true,
                            child: Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${ListDataCabang[index]['Nama_Cabang']}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                '${ListDataCabang[index]['Alamat_Lengkap']}',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: EdgeInsets.only(top: 15.0, bottom: 20.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                  // separatorBuilder: (BuildContext context, int index) => const Divider(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //FUNGSI LOGOUT
  KonfirmasiLogout() {
    Widget continueButton = ElevatedButton(
      onPressed: () {
        SubmitLogout();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(
          color: Color.fromARGB(255, 232, 18, 17),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        "Ya",
        style: TextStyle(
          color: Color.fromARGB(255, 232, 18, 17),
        ),
      ),
    ); // set up the AlertDialog
    Widget cancelButton = ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 232, 18, 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(
        "Tidak",
      ),
    );
    AlertDialog alert = AlertDialog(
      title: Text("Logout"),
      content: Text("Anda yakin ingin keluar?"),
      actions: [
        continueButton,
        cancelButton,
      ],
    ); // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future SubmitLogout() async {
    // FUNGSI HAPUS DATA STORE LOCAL
    await _DataSharedPreferences.HapusDataSharedPreferences("Informasi_Login");
    // FUNGSI HAPUS DATA STORE LOCAL

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Login()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            backgroundColor: Colors.white,
            actionsPadding: EdgeInsets.symmetric(horizontal: 12.0),
            title: Text('Peringatan !'),
            content: Text(
              'Anda yakin ingin menutup aplikasi $Var_Judul_Aplikasi ?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            actions: <Widget>[
              TextButton(
                  child: Text(
                    'Ya',
                    style: TextStyle(
                      color: Color.fromARGB(255, 24, 163, 163),
                    ),
                  ),
                  onPressed: () {
                    print("Return True");
                    exit(0);
                  }),
              TextButton(
                  child: Text(
                    'Tidak',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    print("Return False");
                    Navigator.of(context).pop(false);
                  }),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 232, 18, 17),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
          centerTitle: true,
          title: Text(Var_Judul_Aplikasi),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () {
                KonfirmasiLogout();
              },
            ),
          ],
        ),
        body: InformasiLogin['Id_Cabang'] == null
            ? Container(
                padding: EdgeInsets.all(15.0),
                height: MediaQuery.of(context).size.height,
                child: Center(
                    child: Text(
                  "Anda Tidak Diberikan Akses Ke Cabang Manapun\nHarap Hubungi Administrator",
                  textAlign: TextAlign.center,
                )),
              )
            : SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(35.0),
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ModalCabang(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Center the entire GestureDetector
                            children: [
                              Row(
                                // Row for "CABANG" text and Icon
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align the text and icon at the top
                                children: [
                                  Text(
                                    'CABANG : ',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 20),
                                  ),
                                  Text(
                                    (DataCabangSaatIni['Nama_Cabang'] != null)
                                        ? DataCabangSaatIni['Nama_Cabang']
                                        : "",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.arrow_drop_down_circle),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Other widgets below GestureDetector
                      SizedBox(height: 35),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListDataTransaksiGudangBesar(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 25, horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            color: Color.fromARGB(255, 105, 3, 3),
                          ),
                          child: Column(
                            children: const [
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                          'Gudang Besar',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ])),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warehouse,
                                            color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListDataTransaksiGudangKecil(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 25, horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            color: Color.fromARGB(255, 165, 8, 8),
                          ),
                          child: Column(
                            children: const [
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                          'Gudang Kecil',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ])),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warehouse_outlined,
                                            color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListDataOmset(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 25, horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            color: Color.fromARGB(255, 203, 2, 2),
                          ),
                          child: Column(
                            children: const [
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                          'Input Omset',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ])),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.money, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListDataInputHarian(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 25, horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            color: Color.fromARGB(255, 217, 26, 26),
                          ),
                          child: Column(
                            children: const [
                              Row(
                                children: [
                                  Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                          'Input Harian',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ])),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.list_alt,
                                            color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        drawer: DrawerMenu(
          Nama_Lengkap: InformasiLogin['Nama_Lengkap'],
        ),
        // bottomNavigationBar: BottomMenu()
      ),
    );
  }
}
