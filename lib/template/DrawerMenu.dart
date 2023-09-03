// ignore_for_file: unused_field, prefer_const_constructors, avoid_print, unused_import, must_be_immutable, non_constant_identifier_names, file_names
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:sistem_gudang/konfigurasi/konfigurasi.dart';

class DrawerMenu extends StatelessWidget {
  DrawerMenu(
      {super.key, required this.Nama_Lengkap,});
  String Nama_Lengkap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padKeyding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 232, 18, 17),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset('lib/media/logo/fswhite.png',
                      width: 80, height: 80),
                ),
                SizedBox(
                  height: 10,
                ),
                Center(
                  child: Text(
                    Nama_Lengkap,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
          ListTile(
            title: Center(child: Text(Var_Judul_Aplikasi + "\n" + Var_Versi_Aplikasi, textAlign: TextAlign.center)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
