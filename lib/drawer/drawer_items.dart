import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project/drawer/drawer_item.dart';

class DrawerItems {
  static const home = DrawerItem(title: 'Home', icon: FontAwesomeIcons.house);
  static const device =
      DrawerItem(title: 'Device', icon: FontAwesomeIcons.toolbox);
  static const message =
      DrawerItem(title: 'Message', icon: FontAwesomeIcons.message);
  static const gauge = DrawerItem(title: 'Gauge', icon: FontAwesomeIcons.gauge);
  static const remote =
      DrawerItem(title: 'Switch', icon: FontAwesomeIcons.toggleOn);

  static final List<DrawerItem> all = [
    home,
    device,
    message,
    gauge,
    remote,
  ];
}
