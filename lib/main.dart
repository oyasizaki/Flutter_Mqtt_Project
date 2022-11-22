import 'package:flutter/material.dart';
import 'package:project/Page/devices_page.dart';
import 'package:project/helper/theme_data.dart';
import 'package:project/drawer/drawer_item.dart';
import 'package:project/drawer/drawer_items.dart';
import 'package:project/drawer/drawer_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Color.fromARGB(255, 53, 56, 82),
          primaryColor: CustomColors.clockBG,
        ),
        home: MainPage(),
      );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


// here we will decalre the variable inside a class which will decide the 
class _MainPageState extends State<MainPage> {
  late double xOffset;
  late double yOffset;
  late double scaleFactor;
  late bool isDrawerOpen;
  DrawerItem item = DrawerItems.home;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();

    closeDrawer();
  }

  void closeDrawer() => setState(() {
        xOffset = 0;
        yOffset = 0;
        scaleFactor = 1;
        isDrawerOpen = false;
      });

  void openDrawer() => setState(() {
        xOffset = 230;
        yOffset = 150;
        scaleFactor = 0.6;
        isDrawerOpen = true;
      });

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          buildDrawer(),
          buildPage(),
        ],
      ));

  Widget buildDrawer() => SafeArea(
        child: Container(
          width: xOffset,
          child: DrawerWidget(
            onSelectedItem: (item) {
              setState(() => this.item = item);
              closeDrawer();
            },
          ),
        ),
      );

  Widget buildPage() {
    return WillPopScope(
      onWillPop: () async {
        if (isDrawerOpen) {
          closeDrawer();

          return false;
        } else {
          return true;
        }
      },
      child: GestureDetector(
        onTap: closeDrawer,
        onHorizontalDragStart: (details) => isDragging = true,
        onHorizontalDragUpdate: (details) {
          if (!isDragging) return;

          const delta = 1;
          if (details.delta.dx > delta) {
            openDrawer();
          } else if (details.delta.dx < -delta) {
            closeDrawer();
          }

          isDragging = false;
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          transform: Matrix4.translationValues(xOffset, yOffset, 0)
            ..scale(scaleFactor),
          child: AbsorbPointer(
              absorbing: isDrawerOpen,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(isDrawerOpen ? 70 : 0),
                  child: Container(
                    color: isDrawerOpen
                        ? Colors
                            .transparent //-------------------------------- Can be changed if needed ---------------------------------//
                        : Theme.of(context).primaryColor,
                    child: getDrawerPage(),
                  ))),
        ),
      ),
    );
  }

  Widget getDrawerPage() {
    switch (item) {
      case DrawerItems.device:
        return DevicesPage(openDrawer: openDrawer);
      case DrawerItems.message:
        return DevicesPage(openDrawer: openDrawer);
      case DrawerItems.gauge:
        return DevicesPage(openDrawer: openDrawer);
      case DrawerItems.remote:
        return DevicesPage(openDrawer: openDrawer);
      case DrawerItems.home:
      default:
        return DevicesPage(openDrawer: openDrawer);
    }
  }
}
