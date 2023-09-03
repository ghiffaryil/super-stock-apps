// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';
import 'package:sistem_gudang/fungsi/currency_format/currency_format.dart';

//FORM HALAMAN
import 'package:sistem_gudang/halaman/omset/ListDataOmset.dart';

class TambahDataOmset extends StatefulWidget {
  const TambahDataOmset({Key? key}) : super(key: key);

  @override
  State<TambahDataOmset> createState() =>
      _TambahDataOmsetState();
}

class _TambahDataOmsetState
    extends State<TambahDataOmset> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;
  Map InformasiLogin = {};

  //Variable Form
  Map DataCabang = {};
  List ListArrayObjectOmset = [];
  List ListDataPembayaran = [];
  Map DataCabangSaatIni = {};
  var Nama_Cabang = TextEditingController();
  var Tanggal_Omset = TextEditingController();
  var Kode_Omset = TextEditingController();

  @override
  void initState() {
    RefreshFungsi();
  }

  Future RefreshFungsi() async {
    setState(() {
      Loading_Form = true;
    });

    DateTime Waktu_Sekarang = DateTime.now();
    String Tanggal_Hari_Ini = DateFormat('yyyy-MM-dd').format(Waktu_Sekarang);

    setState(() {
      Tanggal_Omset.text = Tanggal_Hari_Ini;
    });

    setState(() {
      Kode_Omset.text =
          "OMT" + DateFormat("yyMMddHHmmss").format(DateTime.now());
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
      await BacaDataCabangSaatIni();
      await BacaListDataPembayaran();
      await BacaDataCabang();
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

  //FUNGSI SIMPAN
  Future SubmitSimpan() async {
    print('Submit Simpan');

    var Endpoint_API =
        "api/sistem_gudang/v1/omset/tambah_data_omset.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Cabang": InformasiLogin['Id_Cabang'],
      "Tanggal_Omset": Tanggal_Omset.text,
      "Kode_Omset": Kode_Omset.text,
      "JSON_Omset": jsonEncode(ListArrayObjectOmset),
    };

    if (Terhubung_Ke_Internet == true) {
      print("Simpan Dengan Koneksi Internet");
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
              // ALERT BERHASIL
              AlertDialog alert = AlertDialog(
                title: Text("Info"),
                content: Container(
                  child: Text("Data berhasil tersimpan"),
                ),
                actions: [
                  TextButton(
                    child: Text('Ok'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          //routing into add page
                          MaterialPageRoute(
                              builder: (context) =>
                                  ListDataOmset()));
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
                title: Text("Error"),
                content: Container(
                  child: Text("Terjadi kesalahan saat menyimpan data"),
                ),
                actions: [
                  TextButton(
                    child: Text('Ok'),
                    onPressed: () {
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
    } else {
      print("Tidak Ada Koneksi Internet");
      // ALERT GAGAL
      AlertDialog alert = AlertDialog(
        title: Text("Error"),
        content: Container(
          child: Text("Tidak Ada Koneksi Internet"),
        ),
        actions: [
          TextButton(
            child: Text('Ok'),
            onPressed: () {
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
              Nama_Cabang.text = data['Data']['Nama_Cabang'];
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
  Future BacaDataCabang() async {
    print('Baca Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/cabang/baca_data_cabang.php";
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
              DataCabang = data['Data'];
            });

            List ListArrayObjectOmsetSelanjutnya = ListArrayObjectOmset;
            var Array_Object_Pembayaran = jsonDecode(data['Data']['Array_Object_Id_Pembayaran']);

            Future.forEach(Array_Object_Pembayaran, (var Id_Pembayaran) {
              var Ambil_Nama_Pembayaran = ListDataPembayaran.firstWhere((data) => data["Id_Pembayaran"] == Id_Pembayaran.toString(), orElse: () => null);
              var Nama_Pembayaran = "-";
              if (Ambil_Nama_Pembayaran != null) {
                Nama_Pembayaran = Ambil_Nama_Pembayaran["Nama_Pembayaran"];
              }else{
                Nama_Pembayaran = "-";
              }
              Map Data_Omset_Detail = {
                "Id_Pembayaran": Id_Pembayaran,
                "Nama_Pembayaran": Nama_Pembayaran,
                "Pendapatan": "0",
              };

              ListArrayObjectOmsetSelanjutnya.add(Data_Omset_Detail);
            });

            setState(() {
              ListArrayObjectOmset = ListArrayObjectOmsetSelanjutnya;
            });


          } else {
            setState(() {
              DataCabang = {};
            });
          }
        } else {
          setState(() {
            DataCabang = {};
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI MEMBACA LIST DATA PEMBAYARAN
  Future BacaListDataPembayaran() async {
    print('Baca List Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/pembayaran/baca_list_data_pembayaran.php";
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
              ListDataPembayaran = data['Data'];
            });
          } else {
            setState(() {
              ListDataPembayaran = [];
            });
          }
        } else {
          setState(() {
            ListDataPembayaran = [];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI TAMBAH ITEM
  Future SubmitTambahItem() async {
    print('Submit Tambah Item');
    Map Data_Item_Detail = {
      "Id_Item": null,
      "Stok_Akhir": null,
      "Sisa_Satuan_Terkecil": null,
    };
    List ListArrayObjectItemSelanjutnya = ListArrayObjectOmset;
    ListArrayObjectItemSelanjutnya.add(Data_Item_Detail);
    setState(() {
      ListArrayObjectOmset = ListArrayObjectItemSelanjutnya;
    });

    print(ListArrayObjectOmset);
  }

  //FUNGSI UBAH PENDAPATAN ITEM
  Future UbahPendapatanOmset(index, Value) async {
    print('Ubah Pendapatan');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectOmset;
    ListArrayObjectItemSelanjutnya[index]['Pendapatan'] = Value;
    setState(() {
      ListArrayObjectOmset = ListArrayObjectItemSelanjutnya;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 232, 18, 17),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Menu',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text('Tambah Data'),
        actions: const [],
      ),
      body: Loading_Form == true
          ? Container(
        padding: EdgeInsets.all(15.0),
        height: MediaQuery.of(context).size.height,
        child: Center(child: CircularProgressIndicator()),
      )
          : Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(0.0),
          width: double.infinity,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: Nama_Cabang,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Cabang",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      // prefixIcon: Icon(Icons.person, size: 24),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Cabang';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  TextFormField(
                    controller: Kode_Omset,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Kode Omset",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      // prefixIcon: Icon(Icons.person, size: 24),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Kode Omset';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  TextFormField(
                    controller: Tanggal_Omset,
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: 'Tanggal',
                      hintText: 'Tanggal',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    readOnly: true,
                    onTap: () async {
                      if(InformasiLogin['Sebagai'] != "Admin"){
                        return;
                      }else{
                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101));

                        if (pickedDate != null) {
                          print(pickedDate);
                          String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                          print(formattedDate);

                          setState(() {
                            Tanggal_Omset.text = formattedDate;
                          });
                        } else {
                          print("Date is not selected");
                        }
                      }
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Tanggal tidak boleh kosong!';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  Divider(color: Colors.black),
                  Row(children: [
                    Expanded(
                        child: Text(
                          "List Pendapatan : ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                  ]),

                  // LIST ITEM
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: Loading_Form
                        ? ListArrayObjectOmset.length + 1
                        : ListArrayObjectOmset.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index < ListArrayObjectOmset.length) {
                        return Container(
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      flex:1,
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextFormField(
                                              initialValue:(ListArrayObjectOmset[index]
                                              ['Nama_Pembayaran'] == null) ? "" : ListArrayObjectOmset[index]
                                              ['Nama_Pembayaran']
                                                  .toString(),
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                labelText: "Pembayaran",
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(10.0),
                                                ),
                                                fillColor: Colors.white,
                                                filled: true,
                                                // prefixIcon: Icon(Icons.person, size: 24),
                                              ),
                                              readOnly: true,
                                            ),
                                      ]),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      flex:2,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            initialValue:
                                            (ListArrayObjectOmset[index]
                                            ['Pendapatan'] == null) ? "" : ListArrayObjectOmset[index]
                                            ['Pendapatan']
                                                .toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                              labelText: "Pendapatan",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10.0),
                                              ),
                                              fillColor: Colors.white,
                                              filled: true,
                                              // prefixIcon: Icon(Icons.person, size: 24),
                                            ),
                                            onChanged: (value) {
                                              UbahPendapatanOmset(index, value);
                                            },
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return 'Pendapatan tidak boleh kosong!';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ));
                      } else {
                        return Padding(
                          padding:
                          EdgeInsets.only(top: 15.0, bottom: 20.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                    // separatorBuilder: (BuildContext context, int index) =>
                    //     const Divider(),
                  ),


                  SizedBox(height: 30),
                  // TOMBOL SIMPAN
                  Center(
                    child: Container(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 232, 18, 17),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () {
                          //validate
                          if (_formKey.currentState!.validate()) {
                            //send data to database with this method
                            SubmitSimpan();
                          }
                        },
                        child: new Text('SIMPAN'),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
