import 'package:flutter/material.dart';
import 'package:project/drawer/drawer_menu_widget.dart';
import 'package:project/Page/add_device.dart';

class DevicesPage extends StatefulWidget {
  final VoidCallback openDrawer;

  const DevicesPage({
    Key? key,
    required this.openDrawer,
  }) : super(key: key);

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Color.fromARGB(
            255, 53, 56, 82), //------------body color------------//
        //--------------------------- App Bar Text & icons --------------------------- //
        appBar: AppBar(
          leading: DrawerMenuWidget(onClicked: widget.openDrawer),
          title: const Text('SmApp'),
          backgroundColor: Colors.transparent,
          centerTitle: true,

          //------------------ App bar color customizatuion ------------------//

          shadowColor: const Color.fromARGB(255, 89, 241, 168),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      Color.fromARGB(255, 76, 39, 176),
                      Color.fromARGB(255, 113, 228, 248)
                    ]),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 15, 4, 80),
                    offset: Offset(
                      5.0,
                      5.0,
                    ),
                    blurRadius: 20.0,
                    spreadRadius: 2.0,
                  )
                ]),
          ),
        ),
        body: const dashboard(),
      );
}
