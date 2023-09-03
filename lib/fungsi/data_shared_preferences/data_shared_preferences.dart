// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names, use_build_context_synchronously, prefer_typing_uninitialized_variables, avoid_unnecessary_containers, unused_local_variable, unused_field, prefer_const_constructors, avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataSharedPreferences {
  //UNTUK MEMBACA DATA DARI PENYIMPANAN SHARED PREFERENCES
  Future BacaDataSharedPreferences(Nama_Data, {Tipe = ""}) async {
    var DataSharedPreferences;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DataSharedPreferences = prefs.getString(Nama_Data);
    if (DataSharedPreferences != null) {
      if(Tipe == "array_object") {
        return jsonDecode(DataSharedPreferences);
      }else{
        return DataSharedPreferences;
      }
    } else {
      if(Tipe == "array_object"){
        return null;
      }else{
        return null;
      }
    }
  }

  //UNTUK SET DATA DARI PENYIMPANAN SHARED PREFERENCES
  Future SetDataSharedPreferences(Nama_Data, DataSharedPreferences) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Nama_Data, jsonEncode(DataSharedPreferences));
  }

  //UNTUK HAPUS SEMUA DATA DARI PENYIMPANAN SHARED PREFERENCES
  Future HapusDataSharedPreferences(Nama_Data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(Nama_Data);
  }
}
