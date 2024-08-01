// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';

//FORM HALAMAN
import 'package:sistem_gudang/halaman/input_harian/ListDataInputHarian.dart';

class TambahDataInputHarian extends StatefulWidget {
  const TambahDataInputHarian({Key? key}) : super(key: key);

  @override
  State<TambahDataInputHarian> createState() => _TambahDataInputHarianState();
}

class _TambahDataInputHarianState extends State<TambahDataInputHarian> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;
  Map InformasiLogin = {};

  //Variable Form
  Map DataCabang = {};
  List ListDataGudangKecil = [];
  List ListArrayObjectInputHarian = [];
  List ListDataItemInputHarian = [];
  Map DataCabangSaatIni = {};
  var Nama_Cabang = TextEditingController();
  var Id_Gudang_Kecil;
  var Tanggal_Input_Harian = TextEditingController();
  var Kode_Input_Harian = TextEditingController();

  @override
  void initState() {
    super.initState();
    RefreshFungsi();
  }

  Future RefreshFungsi() async {
    setState(() {
      Loading_Form = true;
    });

    DateTime Waktu_Sekarang = DateTime.now();
    String Tanggal_Hari_Ini = DateFormat('yyyy-MM-dd').format(Waktu_Sekarang);

    setState(() {
      Tanggal_Input_Harian.text = Tanggal_Hari_Ini;
    });

    setState(() {
      Kode_Input_Harian.text =
          "IPH${DateFormat("yyMMddHHmmss").format(DateTime.now())}";
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
      await BacaListDataItemInputHarian();
      await BacaDataCabang();
      await BacaListDataGudangKecil();
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
        "api/sistem_gudang/v1/input_harian/tambah_data_input_harian.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Cabang": InformasiLogin['Id_Cabang'],
      "Id_Gudang_Kecil": Id_Gudang_Kecil,
      "Tanggal_Item_Input_Harian": Tanggal_Input_Harian.text,
      "Kode_Item_Input_Harian": Kode_Input_Harian.text,
      "JSON_Input_Harian": jsonEncode(ListArrayObjectInputHarian),
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
                              builder: (context) => ListDataInputHarian()));
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
              DataCabang = data['Data'];
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

  //FUNGSI MEMBACA LIST DATA GUDANG KECIL
  Future BacaListDataGudangKecil() async {
    print('Baca List Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/gudang_kecil/baca_list_data_gudang_kecil.php";
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
              ListDataGudangKecil = data['Data'];
            });

            //UNTUK SET OTOMATIS GUDANG KECIL
            setState(() {
              Id_Gudang_Kecil = data['Data'][0]['Id_Gudang_Kecil'];
            });
            //UNTUK SET OTOMATIS GUDANG KECIL
          } else {
            setState(() {
              ListDataGudangKecil = [];
            });
          }
        } else {
          setState(() {
            ListDataGudangKecil = [];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI MEMBACA LIST DATA ITEM INPUT HARIAN
  Future BacaListDataItemInputHarian() async {
    print('Baca List Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/pengaturan_input_item_harian/baca_list_data_pengaturan_input_item_harian.php";
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
              ListDataItemInputHarian = data['Data'];
            });

            List ListArrayObjectInputHarianSelanjutnya =
                ListArrayObjectInputHarian;

            Future.forEach(ListDataItemInputHarian, (var DataItemInputHarian) {
              var Id_Item = DataItemInputHarian['Id_Item'];
              var Nama_Item = DataItemInputHarian['Nama_Item'];
              var Persentase_Pemakaian =
                  DataItemInputHarian['Persentase_Pemakaian'];

              Map Data_InputHarian_Detail = {
                "Id_Item": Id_Item,
                "Nama_Item": Nama_Item,
                "Persentase_Pemakaian": Persentase_Pemakaian,
                "Pemakaian": "0",
              };

              ListArrayObjectInputHarianSelanjutnya.add(
                  Data_InputHarian_Detail);
            });

            setState(() {
              ListArrayObjectInputHarian =
                  ListArrayObjectInputHarianSelanjutnya;
            });
          } else {
            setState(() {
              ListDataItemInputHarian = [];
            });
          }
        } else {
          setState(() {
            ListDataItemInputHarian = [];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI UBAH PENDAPATAN ITEM
  Future UbahPemakaianItem(index, Value) async {
    print('Ubah Pemakaian');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectInputHarian;
    ListArrayObjectItemSelanjutnya[index]['Pemakaian'] = Value;
    setState(() {
      ListArrayObjectInputHarian = ListArrayObjectItemSelanjutnya;
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
                          controller: Kode_Input_Harian,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: "Kode Input Harian",
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
                              return 'Kode Input Harian';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Gudang Kecil",
                            border: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                          child: Container(
                            child: DropdownButton(
                              isExpanded: true,
                              isDense: true,
                              hint: Text("Pilih Gudang Kecil"),
                              underline: Container(),
                              value: Id_Gudang_Kecil == ''
                                  ? null
                                  : Id_Gudang_Kecil,
                              items: ListDataGudangKecil.map((item) {
                                return DropdownMenuItem(
                                  value: item['Id_Gudang_Kecil'],
                                  child: Text(
                                      "${item['Kode_Gudang_Kecil']} - ${item['Nama_Gudang']}"),
                                );
                              }).toList(),
                              onTap: () {
                                setState(() {
                                  Id_Gudang_Kecil = '';
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  Id_Gudang_Kecil = value;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          controller: Tanggal_Input_Harian,
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
                            if (InformasiLogin['Sebagai'] != "Admin") {
                              return;
                            } else {
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
                                  Tanggal_Input_Harian.text = formattedDate;
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
                        Row(children: const [
                          Expanded(
                              child: Text(
                            "List Item : ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                        ]),

                        // LIST ITEM
                        ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          itemCount: Loading_Form
                              ? ListArrayObjectInputHarian.length + 1
                              : ListArrayObjectInputHarian.length,
                          itemBuilder: (BuildContext context, int index) {
                            if (index < ListArrayObjectInputHarian.length) {
                              return Container(
                                  child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                initialValue:
                                                    (ListArrayObjectInputHarian[
                                                                    index]
                                                                ['Nama_Item'] ==
                                                            null)
                                                        ? ""
                                                        : ListArrayObjectInputHarian[
                                                            index]['Nama_Item'],
                                                keyboardType:
                                                    TextInputType.name,
                                                decoration: InputDecoration(
                                                  labelText: "Item",
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
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
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              initialValue:
                                                  (ListArrayObjectInputHarian[
                                                                  index]
                                                              ['Pemakaian'] ==
                                                          null)
                                                      ? ""
                                                      : ListArrayObjectInputHarian[
                                                                  index]
                                                              ['Pemakaian']
                                                          .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: "Pemakaian",
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
                                                UbahPemakaianItem(index, value);
                                              },
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return 'Pemakaian tidak boleh kosong!';
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
                                backgroundColor:
                                    Color.fromARGB(255, 232, 18, 17),
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: () {
                                //validate
                                if (_formKey.currentState!.validate()) {
                                  //send data to database with this method
                                  SubmitSimpan();
                                }
                              },
                              child: Text('SIMPAN'),
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
