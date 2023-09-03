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
import 'package:sistem_gudang/fungsi/currency_format/currency_format.dart';

//FORM HALAMAN
import 'package:sistem_gudang/halaman/omset/TambahDataOmset.dart';
import 'package:sistem_gudang/halaman/omset/EditDataOmset.dart';
import 'package:sistem_gudang/Home.dart';

class ListDataOmset extends StatefulWidget {
  const ListDataOmset({Key? key}) : super(key: key);

  @override
  State<ListDataOmset> createState() =>
      _ListDataOmsetState();
}

class _ListDataOmsetState
    extends State<ListDataOmset> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;
  Map InformasiLogin = {};

  //Variable Form
  List ListDataOmset = [];

  @override
  void initState() {
    super.initState();
    RefreshFungsi();
  }

  //FUNGSI UNTUK REFRESH
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

    setState(() {
      InformasiLogin = DataLocalInformasiLogin;
    });

    await CekKoneksiInternet();
    if (Terhubung_Ke_Internet == true) {
      await BacaListDataOmset();
    }

    setState(() {
      Loading_Form = false;
    });
  }

  // FUNGSI REFRESH FORM
  Future<Null> RefreshForm() async {
    await Future.delayed(Duration(seconds: 2));
    RefreshFungsi();
    return null;
  }

  //FUNGSI MEMBACA LIST DATA
  Future BacaListDataOmset() async {
    print('Baca List Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/omset/baca_list_data_omset.php";
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
              ListDataOmset = data['Data'];
            });
          } else {
            setState(() {
              ListDataOmset = [];
            });
          }
        } else {
          setState(() {
            ListDataOmset = [];
          });
        }
      });
    } catch (e) {
      print(e);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 232, 18, 17),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Home(),
              ),
            );
          },
        ),
        centerTitle: true,
        title: Text('List Omset'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline_outlined, color: Colors.white),
            tooltip: 'Tambah Data',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TambahDataOmset()));
            },
          ),
        ],
      ),
      body: Loading_Form == true
          ? Container(
        padding: EdgeInsets.all(15.0),
        height: MediaQuery.of(context).size.height,
        child: Center(child: CircularProgressIndicator()),
      )
          : RefreshIndicator(
        onRefresh: RefreshForm,
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LIST VIEW //
              Loading_Form == true
                  ? Container(
                margin: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              )
                  : Expanded(
                flex: 9,
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: Loading_Form
                      ? ListDataOmset.length + 1
                      : ListDataOmset.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index <
                        ListDataOmset.length) {
                      return Container(
                          margin:
                          const EdgeInsets.only(bottom: 10.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EditDataOmset(
                                            Id_Omset:
                                            '${ListDataOmset[index]['Id_Omset']}',
                                          )));
                            },
                            child: Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              semanticContainer: true,
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Text(
                                                    '${ListDataOmset[index]['Kode_Omset']}',
                                                    style: TextStyle(
                                                        fontSize:
                                                        12,
                                                        color: Colors
                                                            .black,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold),
                                                  ),
                                                  SizedBox(
                                                    height: 2,
                                                  ),
                                                  Text(
                                                    '${ListDataOmset[index]['Tanggal_Omset']}',
                                                    style: TextStyle(
                                                        fontSize:
                                                        15,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold,
                                                        color: Colors
                                                            .black),
                                                  ),
                                                  SizedBox(
                                                    height: 2,
                                                  ),
                                                  Text(CurrencyFormat.convertToIdr(ListDataOmset[index]['Total_Pendapatan'], 0),
                                                    style: TextStyle(
                                                        color: Colors
                                                            .black),
                                                  ),
                                                ]),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .end,
                                                children: [
                                                  Text(
                                                    '${ListDataOmset[index]['Nama_Lengkap']}',
                                                    style: TextStyle(
                                                        fontSize:
                                                        12,
                                                        fontStyle:
                                                        FontStyle
                                                            .italic),
                                                  ),
                                                  Text(
                                                    '${ListDataOmset[index]['Waktu_Simpan_Data']}',
                                                    style: TextStyle(
                                                        fontSize:
                                                        12,
                                                        fontStyle:
                                                        FontStyle
                                                            .italic),
                                                  ),
                                                ]),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ));
                    } else {
                      return Padding(
                        padding: EdgeInsets.only(
                            top: 15.0, bottom: 20.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                  // separatorBuilder: (BuildContext context, int index) =>
                  //     const Divider(),
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: Footer()
    );
  }
}
