// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

//FUNGSI
import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';
import 'package:sistem_gudang/fungsi/data_shared_preferences/data_shared_preferences.dart';
import 'package:sistem_gudang/fungsi/currency_format/currency_format.dart';

//FORM HALAMAN
import 'package:sistem_gudang/halaman/gudang_besar/ListDataTransaksiGudangBesar.dart';

class EditDataTransaksiGudangBesar extends StatefulWidget {
  String Id_Stok_Gudang_Besar;

  EditDataTransaksiGudangBesar({required this.Id_Stok_Gudang_Besar});

  @override
  State<EditDataTransaksiGudangBesar> createState() =>
      _EditDataTransaksiGudangBesarState();
}

class _EditDataTransaksiGudangBesarState
    extends State<EditDataTransaksiGudangBesar> {
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
  var Id_Gudang_Besar;
  var Id_Item;
  var Tanggal_Item_Stok = TextEditingController();
  var Kode_Stok_Gudang_Besar = TextEditingController();

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
      await BacaListDataGudangKecil();
      await BacaListDataGudangBesar();
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

    var Endpoint_API =
        "api/sistem_gudang/v1/transaksi_gudang_besar/baca_data_transaksi_gudang_besar.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Besar": widget.Id_Stok_Gudang_Besar,
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
              Id_Gudang_Besar = data['Data']['Id_Gudang_Besar'];
              Kode_Stok_Gudang_Besar.text =
                  data['Data']['Kode_Stok_Gudang_Besar'];
            });

            var ListArrayObjectItem_Yang_Tersimpan_Pada_Database =
                jsonDecode(data['Data']['JSON_Item']);

            ListDataItem.forEach((data) {
              Map Data_Item_Detail = {
                "Nama_Item": data['Nama_Item'],
                "Id_Item": data['Id_Item'],
                "QTY": "",
                "Tipe": "Tambah Stok",
                "Id_Gudang_Kecil": null,
                "Id_Gudang_Besar": null,
                "Nama_Gudang": "",
              };

              ListArrayObjectItem_Yang_Tersimpan_Pada_Database.forEach(
                  (data_yang_tersimpan_pada_database) {
                //JIKA ADA DATA YANG SAMA, MAKA AKAN DI OVVERIDE
                if (data_yang_tersimpan_pada_database['Id_Item'] ==
                    data['Id_Item']) {
                  Data_Item_Detail = {
                    "Nama_Item": data['Nama_Item'],
                    "Id_Item": data['Id_Item'],
                    "QTY": data_yang_tersimpan_pada_database['QTY'],
                    "Tipe": data_yang_tersimpan_pada_database['Tipe'],
                    "Id_Gudang_Kecil": data_yang_tersimpan_pada_database['Id_Gudang_Kecil'],
                    "Id_Gudang_Besar": data_yang_tersimpan_pada_database['Id_Gudang_Besar'],
                    "Nama_Gudang": data_yang_tersimpan_pada_database['Nama_Gudang'],
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
      if(data['QTY'] != ""){
        ListArrayObjectItem_Terpakai.add(data);
      }
    });

    var Endpoint_API =
        "api/sistem_gudang/v1/transaksi_gudang_besar/update_data_transaksi_gudang_besar.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Besar": widget.Id_Stok_Gudang_Besar,
      "Tanggal_Item_Stok": Tanggal_Item_Stok.text,
      "Id_Gudang_Besar": Id_Gudang_Besar,
      "JSON_Item": jsonEncode(ListArrayObjectItem_Terpakai),
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
                                  ListDataTransaksiGudangBesar()));
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

  Future SubmitHapus() async {
    print('Submit Hapus');

    var Endpoint_API =
        "api/sistem_gudang/v1/transaksi_gudang_besar/hapus_ke_tong_sampah_data_transaksi_gudang_besar.php";
    Map data_body = {
      "Token_Login": InformasiLogin['Token_Login_Saat_Ini'],
      "Id_Pengguna": InformasiLogin['Id_Pengguna'],
      "Id_Stok_Gudang_Besar": widget.Id_Stok_Gudang_Besar,
    };
    print(Terhubung_Ke_Internet);

    if (Terhubung_Ke_Internet == true) {
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
                          MaterialPageRoute(
                              builder: (context) =>
                                  ListDataTransaksiGudangBesar()));
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
            if(InformasiLogin['Sebagai'] != "Admin") {

            }else{
              var ListDataGudangBesarDanKecilSelanjutnya =
                  ListDataGudangBesarDanKecil + data['Data'];
              setState(() {
                ListDataGudangBesarDanKecil =
                    ListDataGudangBesarDanKecilSelanjutnya;
              });
            }


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
      "QTY": 1,
      "Tipe": "Tambah Stok",
      "Id_Gudang_Kecil": null,
      "Id_Gudang_Besar": null,
      "Nama_Gudang": "",
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

  //FUNGSI UBAH QTY Item
  Future UbahQTYItem(index, Value) async {
    print('Ubah QTY Item');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['QTY'] = Value;
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
  }

  //FUNGSI TOMBOL TAMBAH STOK
  Future TombolTambahStok(index) async {
    print('Tombol Tambah Item');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['Tipe'] = "Tambah Stok";
    ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Besar'] = null;
    ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Kecil'] = null;
    ListArrayObjectItemSelanjutnya[index]['Nama_Gudang'] = "";
    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });

    print(ListArrayObjectItem);
  }

  //FUNGSI TOMBOL KURANGI STOK
  Future TombolKurangiStok(index, Jenis_Gudang, Id_Gudang) async {
    print('Tombol Kurangi Item');
    List ListArrayObjectItemSelanjutnya = ListArrayObjectItem;
    ListArrayObjectItemSelanjutnya[index]['Tipe'] = "Kurangi Stok";
    if (Jenis_Gudang == "Gudang Besar") {
      ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Besar'] = Id_Gudang;
      ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Kecil'] = null;

      var Data_Gudang;
      Data_Gudang = ListDataGudangBesar.firstWhere(
          (item) => item["Id_Gudang_Besar"] == Id_Gudang,
          orElse: () => null);

      ListArrayObjectItemSelanjutnya[index]['Nama_Gudang'] =
          Data_Gudang["Nama_Gudang"];
    } else {
      ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Besar'] = null;
      ListArrayObjectItemSelanjutnya[index]['Id_Gudang_Kecil'] = Id_Gudang;

      var Data_Gudang;
      Data_Gudang = ListDataGudangKecil.firstWhere(
          (item) => item["Id_Gudang_Kecil"] == Id_Gudang,
          orElse: () => null);

      ListArrayObjectItemSelanjutnya[index]['Nama_Gudang'] =
          Data_Gudang["Nama_Gudang"];
    }

    setState(() {
      ListArrayObjectItem = ListArrayObjectItemSelanjutnya;
    });
    Navigator.pop(context);
  }

  // FUNGSI MODAL GUDANG
  void ModalGudang(BuildContext context, index_item) {
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
                "List Gudang :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Silahkan pilih salah satu gudang",
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: false,
                  itemCount: Loading_Form
                      ? ListDataGudangBesarDanKecil.length + 1
                      : ListDataGudangBesarDanKecil.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index < ListDataGudangBesarDanKecil.length) {
                      if(Id_Gudang_Besar == ListDataGudangBesarDanKecil[index]
                      ['Id_Gudang_Besar']){
                        return Container();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () {
                            if (ListDataGudangBesarDanKecil[index]
                                    ['Id_Gudang_Besar'] !=
                                null) {
                              TombolKurangiStok(
                                  index_item,
                                  "Gudang Besar",
                                  ListDataGudangBesarDanKecil[index]
                                      ['Id_Gudang_Besar']);
                            } else {
                              TombolKurangiStok(
                                  index_item,
                                  "Gudang Kecil",
                                  ListDataGudangBesarDanKecil[index]
                                      ['Id_Gudang_Kecil']);
                            }
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
                                              if (ListDataGudangBesarDanKecil[
                                                          index]
                                                      ['Id_Gudang_Besar'] !=
                                                  null) ...[
                                                Text(
                                                  'Gudang Besar \n${ListDataGudangBesarDanKecil[index]['Kode_Gudang_Besar']} - ${ListDataGudangBesarDanKecil[index]['Nama_Gudang']}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'Gudang Kecil \n${ListDataGudangBesarDanKecil[index]['Kode_Gudang_Kecil']} - ${ListDataGudangBesarDanKecil[index]['Nama_Gudang']}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                              SizedBox(height: 10),
                                              Text(
                                                '${ListDataGudangBesarDanKecil[index]['Alamat_Lengkap']}',
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
                          controller: Kode_Stok_Gudang_Besar,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: "Kode Stok Gudang Besar",
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
                              return 'Kode Stok Gudang Besar';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Gudang Besar",
                            border: OutlineInputBorder(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                          child: Container(
                            child: DropdownButton(
                              isExpanded: true,
                              isDense: true,
                              hint: Text("Pilih Gudang Besar"),
                              underline: Container(),
                              value: Id_Gudang_Besar == ''
                                  ? null
                                  : Id_Gudang_Besar,
                              items: ListDataGudangBesar.map((item) {
                                return DropdownMenuItem(
                                  value: item['Id_Gudang_Besar'],
                                  child: Text(
                                      item['Kode_Gudang_Besar'].toString() +
                                          " - " +
                                          item['Nama_Gudang'].toString()),
                                );
                              }).toList(),
                              onTap: () {
                                setState(() {
                                  Id_Gudang_Besar = '';
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  Id_Gudang_Besar = value;
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
                                            initialValue:
                                                ListArrayObjectItem[index]
                                                    ['Nama_Item'],
                                            keyboardType: TextInputType.name,
                                            decoration: InputDecoration(
                                              labelText: "Item",
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
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue:
                                              ListArrayObjectItem[index]['QTY']
                                                  .toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "QTY",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
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
                                            UbahQTYItem(index, value);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      (ListArrayObjectItem[
                                                                      index]
                                                                  ['Tipe'] ==
                                                              "Tambah Stok")
                                                          ? Colors.green
                                                          : Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 1,
                                                      horizontal: 1),
                                                ),
                                                onPressed: () {
                                                  TombolTambahStok(index);
                                                },
                                                child: new Icon(
                                                  Icons.add,
                                                  color: (ListArrayObjectItem[
                                                              index]['Tipe'] ==
                                                          "Tambah Stok")
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              )),
                                              SizedBox(width: 5),
                                              Expanded(
                                                  child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      (ListArrayObjectItem[
                                                                      index]
                                                                  ['Tipe'] ==
                                                              "Kurangi Stok")
                                                          ? Colors.red
                                                          : Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 1,
                                                      horizontal: 1),
                                                ),
                                                onPressed: () {
                                                  ModalGudang(context, index);
                                                },
                                                child: new Icon(
                                                  Icons.remove,
                                                  color: (ListArrayObjectItem[
                                                              index]['Tipe'] ==
                                                          "Kurangi Stok")
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              )),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: (ListArrayObjectItem[
                                                            index]['Tipe'] ==
                                                        "Tambah Stok")
                                                    ? Text(
                                                        "Tambah Stok",
                                                        style: TextStyle(
                                                            fontSize: 10),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )
                                                    : (ListArrayObjectItem[
                                                                    index]
                                                                ['Tipe'] ==
                                                            "Kurangi Stok")
                                                        ? Text(
                                                            "Kurangi Stok",
                                                            style: TextStyle(
                                                                fontSize: 10),
                                                            textAlign: TextAlign
                                                                .center,
                                                          )
                                                        : Text(
                                                            "",
                                                            style: TextStyle(
                                                                fontSize: 10),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                              )
                                            ],
                                          ),
                                          if ((ListArrayObjectItem[index]
                                                      ['Tipe'] ==
                                                  "Kurangi Stok") &&
                                              (ListArrayObjectItem[index]
                                                      ['Id_Gudang_Besar'] !=
                                                  null)) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  "Gudang Besar",
                                                  style:
                                                      TextStyle(fontSize: 10),
                                                  textAlign: TextAlign.center,
                                                )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  ListArrayObjectItem[index]
                                                      ['Nama_Gudang'],
                                                  style:
                                                      TextStyle(fontSize: 10),
                                                  textAlign: TextAlign.center,
                                                )),
                                              ],
                                            ),
                                          ],
                                          if ((ListArrayObjectItem[index]
                                                      ['Tipe'] ==
                                                  "Kurangi Stok") &&
                                              (ListArrayObjectItem[index]
                                                      ['Id_Gudang_Kecil'] !=
                                                  null)) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  "Gudang Kecil",
                                                  style:
                                                      TextStyle(fontSize: 10),
                                                  textAlign: TextAlign.center,
                                                )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  ListArrayObjectItem[index]
                                                      ['Nama_Gudang'],
                                                  style:
                                                      TextStyle(fontSize: 10),
                                                  textAlign: TextAlign.center,
                                                )),
                                              ],
                                            ),
                                          ]
                                        ],
                                      )),
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
                                backgroundColor:
                                    Color.fromARGB(255, 232, 18, 17),
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
