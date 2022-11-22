import 'package:flutter/material.dart';
import 'package:project/Features/addguages.dart';
import 'package:project/Features/addswitch.dart';
import 'package:project/Page/add_device.dart';

class feature extends StatefulWidget {
  const feature({super.key});

  @override
  State<feature> createState() => _featureState();
}

class _featureState extends State<feature> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: ((context) => dashboard())));
              },
              icon: Icon(Icons.arrow_back))),
      body: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 1,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 80.0, left: 80.0),
            child: Row(children: const [
              SizedBox(width: 250, child: Gaugeboard()),
              SizedBox(width: 150),
              SizedBox(width: 200, child: Switchboard())
            ]),
          );
        },
      ),
    );
  }
}


// Column(children: [
//           SizedBox(height: 370, child: Gaugeboard()),
//           SizedBox(height: 500, child: Switchboard())
//         ]),