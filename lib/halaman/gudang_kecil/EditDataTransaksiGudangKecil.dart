// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:sistem_gudang/halaman/gudang_kecil/ListDataTransaksiGudangKecil.dart';
import 'package:dropdown_search/dropdown_search.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';
import 'package:sistem_gudang/fungsi/currency_format/currency_format.dart';

//FORM HALAMAN
import 'package:sistem_gudang/halaman/gudang_besar/ListDataTransaksiGudangBesar.dart';

class EditDataTransaksiGudangKecil extends StatefulWidget {
  String Id_Stok_Gudang_Kecil;
  EditDataTransaksiGudangKecil({required this.Id_Stok_Gudang_Kecil});

  @override
  State<EditDataTransaksiGudangKecil> createState() =>
      _EditDataTransaksiGudangKecilState();
}

class _EditDataTransaksiGudangKecilState
    extends State<EditDataTransaksiGudangKecil> {
  final _formKey = GlobalKey<FormState>();
  final _DataSharedPreferences = DataSharedPreferences();
  bool Loading_Form = false;
  bool Terhubung_Ke_Internet = false;
  Map InformasiLogin = {};

  //Variable Form
  Map EditData = {};
  List ListDataGudangBesar = [];
  List ListDataGudangKecil = [];
  List ListDataGudangBesarDanKecil = [];
  List ListDataItem = [];
  List ListArrayObjectItem = [];
  Map DataCabangSaatIni = {};
  var Nama_Cabang = TextEditingController();
  var Id_Gudang_Kecil;
  var Id_Item;
  var Tanggal_Item_Stok = TextEditingController();
  var Kode_Stok_Gudang_Kecil = TextEditingController();

  @override
  void initState() {
    RefreshFungsi();
  }

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
      await BacaListDataItem();
      await BacaDataYangAkanDiEdit();
      await BacaDataCabangDataIni();
      await BacaListDataGudangBesar();
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

  //FUNGSI BACA DATA YANG AKAN DIEDIT
  Future BacaDataYangAkanDiEdit() async {
    print('Baca Data Yang Akan Di Edit');

    var Endpoint_API = "api/sistem_gudang/v1/transaksi_gudang_kecil/baca_data_transaksi_gudang_kecil.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Kecil": widget.Id_Stok_Gudang_Kecil,
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
              EditData = data['Data'];
            });

            setState(() {
              Tanggal_Item_Stok.text = data['Data']['Tanggal_Item_Stok'];
              Id_Gudang_Kecil = data['Data']['Id_Gudang_Kecil'];
              Kode_Stok_Gudang_Kecil.text = data['Data']['Kode_Stok_Gudang_Kecil'];
            });

            var ListArrayObjectItem_Yang_Tersimpan_Pada_Database =
            jsonDecode(data['Data']['JSON_Item']);

            ListDataItem.forEach((data) {
              Map Data_Item_Detail = {
                "Nama_Item": data['Nama_Item'],
                "Id_Item": data['Id_Item'],
                "Stok_Akhir": null,
                "Sisa_Satuan_Terkecil": null,
              };

              ListArrayObjectItem_Yang_Tersimpan_Pada_Database.forEach(
                      (data_yang_tersimpan_pada_database) {
                    //JIKA ADA DATA YANG SAMA, MAKA AKAN DI OVVERIDE
                    if (data_yang_tersimpan_pada_database['Id_Item'] ==
                        data['Id_Item']) {
                      Data_Item_Detail = {
                        "Nama_Item": data['Nama_Item'],
                        "Id_Item": data['Id_Item'],
                        "Stok_Akhir": data_yang_tersimpan_pada_database['Stok_Akhir'],
                        "Sisa_Satuan_Terkecil": data_yang_tersimpan_pada_database['Sisa_Satuan_Terkecil'],
                      };
                    }
                  });

              List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
              ListArrayObjectItemSelanjutnya.add(Data_Item_Detail);
              setState(() {
                ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
              });
            });
          } else {
            setState(() {
              EditData = {};
            });
          }
        }
      });
    } catch (e) {
      print(e);
    }
  }

  //FUNGSI UPDATE
  Future SubmitUpdate() async {
    print('Submit Update');

    var ListArrayObjectItem_Terpakai = [];
    ListArrayObjectItem.forEach((data) {
      if((data['Stok_Akhir'] != "") || (data['Sisa_Satuan_Terkecil'] != "")){
        ListArrayObjectItem_Terpakai.add(data);
      }
    });

    var Endpoint_API = "api/sistem_gudang/v1/transaksi_gudang_kecil/update_data_transaksi_gudang_kecil.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Kecil": widget.Id_Stok_Gudang_Kecil,
      "Tanggal_Item_Stok": Tanggal_Item_Stok.text,
      "Id_Gudang_Kecil": Id_Gudang_Kecil,
      "JSON_Item": jsonEncode(ListArrayObjectItem),
    };

    if (Terhubung_Ke_Internet == true) {
      print("Update Dengan Koneksi Internet");
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
                  child: Text("Data berhasil diupdate"),
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
                                  ListDataTransaksiGudangKecil()));
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
                  child: Text("Terjadi kesalahan saat mengupdate data"),
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

  //FUNGSI HAPUS
  KonfirmasiHapusData() {
    print('Konfirmasi Hapus Data');

    // ALERT JIKA LOGIN BERHASIL
    AlertDialog alert = AlertDialog(
      title: Text("Perhatian"),
      content: Container(
        child: Text("Anda yakin ingin menghapus data ini ?"),
      ),
      actions: [
        TextButton(
          child: Text(
            'Ya',
            style: TextStyle(color: Colors.lightBlueAccent),
          ),
          onPressed: () {
            SubmitHapus();
          },
        ),
        TextButton(
          child: Text(
            'Tidak',
            style: TextStyle(color: Colors.red),
          ),
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

  //FUNGSI MEMBACA DATA CABANG DATA INI
  Future BacaDataCabangDataIni() async {
    print('Baca Data');

    var Endpoint_API = "api/sistem_gudang/v1/cabang/baca_data_cabang.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Cabang": EditData['Id_Cabang'],
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

  Future SubmitHapus() async {
    print('Submit Hapus');

    var Endpoint_API = "api/sistem_gudang/v1/transaksi_gudang_kecil/hapus_ke_tong_sampah_data_transaksi_gudang_kecil.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Kecil": widget.Id_Stok_Gudang_Kecil,
    };
    print(Terhubung_Ke_Internet);

    if(Terhubung_Ke_Internet == true) {
      print("Hapus Dengan Koneksi Internet");
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
                  child: Text("Data berhasil dihapus"),
                ),
                actions: [
                  TextButton(
                    child: Text('Ok'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          //routing into add page
                          MaterialPageRoute(builder: (context) => ListDataTransaksiGudangKecil()));
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
                  child: Text("Terjadi kesalahan saat menghapus data"),
                ),
                actions: [
                  TextButton(
                    child: Text('Close'),
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
    }else{
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

  //FUNGSI MEMBACA LIST DATA GUDANG BESAR
  Future BacaListDataGudangBesar() async {
    print('Baca List Data');

    var Endpoint_API =
        "api/sistem_gudang/v1/gudang_besar/baca_list_data_gudang_besar.php";
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
              ListDataGudangBesar = data['Data'];
            });
            var ListDataGudangBesarDanKecilSelanjutnya =
                ListDataGudangBesarDanKecil + data['Data'];
            setState(() {
              ListDataGudangBesarDanKecil =
                  ListDataGudangBesarDanKecilSelanjutnya;
            });
          } else {
            setState(() {
              ListDataGudangBesar = [];
            });
          }
        } else {
          setState(() {
            ListDataGudangBesar = [];
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
            var ListDataGudangBesarDanKecilSelanjutnya =
                ListDataGudangBesarDanKecil + data['Data'];
            setState(() {
              ListDataGudangBesarDanKecil =
                  ListDataGudangBesarDanKecilSelanjutnya;
            });
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

  //FUNGSI MEMBACA LIST DATA Item
  Future BacaListDataItem() async {
    print('Baca List Data');

    var Endpoint_API = "api/sistem_gudang/v1/item/baca_list_data_item.php";
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
              ListDataItem = data['Data'];
            });
          } else {
            setState(() {
              ListDataItem = [];
            });
          }
        } else {
          setState(() {
            ListDataItem = [];
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
      "Id_Item": ListDataItem[0]['Id_Item'],
      "Stok_Akhir": null,
      "Sisa_Satuan_Terkecil": null,
    };
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya.add(Data_Item_Detail);
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });

    print(ListArrayObjectItem);
  }

  //FUNGSI HAPUS ITEM
  Future SubmitHapusItem(index) async {
    print('Submit Hapus Item');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya.removeAt(index);
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
  }

  //FUNGSI GANTI NAMA ITEM
  Future GantiNamaItem(index, Id_Item) async {
    print('Ganti Nama Item');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['Id_Item'] = Id_Item;
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
  }

  //FUNGSI UBAH STOK AKHIR ITEM
  Future UbahStokAkhirItem(index, Value) async {
    print('Ubah Stok Akhir');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['Stok_Akhir'] = Value;
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
  }

  //FUNGSI UBAH SISA SATUAN TERKECIL
  Future UbahSisaSatuanTerkecilItem(index, Value) async {
    print('Ubah Sisa Satuan Terkecil');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['Sisa_Satuan_Terkecil'] = Value;
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
  }

  // FUNGSI AMBIL NAMA ITEM BERDASARKAN ID ITEM UNTUK DROPDOWN SEARCH
  AmbilNamaItemBerdasarkanIdItem(Id_Item) {
    final selected_Item = ListDataItem.firstWhere(
          (e) => "${e['Id_Item']}" == Id_Item,
      orElse: () => null,
    );
    if (selected_Item != null) {
      final Nama_Item = selected_Item['Nama_Item'];
      return Nama_Item;
    } else {
      return null;
    }
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
        title: Text('Edit Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Edit',
            onPressed: () {
              KonfirmasiHapusData();
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
                    controller: Kode_Stok_Gudang_Kecil,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Kode Stok Gudang Kecil",
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
                        return 'Kode Stok Gudang Kecil';
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
                                item['Kode_Gudang_Kecil'].toString() +
                                    " - " +
                                    item['Nama_Gudang'].toString()),
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
                    controller: Tanggal_Item_Stok,
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
                            Tanggal_Item_Stok.text = formattedDate;
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
                        ? ListArrayObjectItem.length + 1
                        : ListArrayObjectItem.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index < ListArrayObjectItem.length) {
                        return Container(
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(children: [
                                        TextFormField(
                                          initialValue: ListArrayObjectItem[index]['Nama_Item'],
                                          keyboardType: TextInputType.name,
                                          decoration: InputDecoration(
                                            labelText: "Item",
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10.0),
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
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            initialValue:
                                            (ListArrayObjectItem[index]
                                            ['Stok_Akhir'] == null) ? "" : ListArrayObjectItem[index]
                                            ['Stok_Akhir']
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: "Stok Akhir",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10.0),
                                              ),
                                              fillColor: Colors.white,
                                              filled: true,
                                              contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: 5,
                                                  horizontal: 10),
                                              // prefixIcon: Icon(Icons.person, size: 24),
                                            ),
                                            style: TextStyle(fontSize: 14),
                                            onChanged: (value) {
                                              UbahStokAkhirItem(index, value);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            initialValue:
                                            (ListArrayObjectItem[index]
                                            ['Sisa_Satuan_Terkecil'] == null) ? "" : ListArrayObjectItem[index]
                                            ['Sisa_Satuan_Terkecil']
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: "Sisa Gramasi",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10.0),
                                              ),
                                              fillColor: Colors.white,
                                              filled: true,
                                              contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: 5,
                                                  horizontal: 10),
                                              // prefixIcon: Icon(Icons.person, size: 24),
                                            ),
                                            style: TextStyle(fontSize: 14),
                                            onChanged: (value) {
                                              UbahSisaSatuanTerkecilItem(index, value);
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
                  // TOMBOL UPDATE
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
                            SubmitUpdate();
                          }
                        },
                        child: new Text('UPDATE'),
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