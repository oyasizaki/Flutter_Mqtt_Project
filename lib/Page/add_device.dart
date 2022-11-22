import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/Features/features.dart';
import 'package:sqflite/sqflite.dart';

class Device implements Comparable {
  final int id;
  final String firstName;
  final String lastName;

  const Device({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';

  Device.fromRow(Map<String, Object?> row)
      : id = row['ID'] as int,
        firstName = row['FIRST_NAME'] as String,
        lastName = row['LAST_NAME'] as String;

  @override
  int compareTo(covariant other) => other.id.compareTo(id);

  @override
  bool operator ==(covariant Device other) => id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Device, id = $id, firstName: $firstName, lastname: $lastName';

  static removeAt(int oldIndex) {
    Device;
  }

  static insert(int newIndex) {
    Device;
  }
}

class DeviceDB {
  final String dbName;
  Database? _db;
  List<Device> _devices = [];
  final _streamController = StreamController<List<Device>>.broadcast();

  DeviceDB({required this.dbName});

  Future<List<Device>> _fetchTool() async {
    final db = _db;
    if (db == null) {
      return [];
    }
    try {
      final read = await db.query(
        'DEVICE',
        distinct: true,
        columns: [
          'ID',
          'FIRST_NAME',
          'LAST_NAME',
        ],
        orderBy: 'ID',
      );

      final tool = read.map((row) => Device.fromRow(row)).toList();
      return tool;
    } catch (e) {
      print('Error fetching devices = $e');
      return [];
    }
  }

// C in CRUD
  Future<bool> create(String firstName, String lastName) async {
    final db = _db;
    if (db == null) {
      return false;
    }

    try {
      final id = await db.insert('DEVICE', {
        'FIRST_NAME': firstName,
        'LAST_NAME': lastName,
      });
      final device = Device(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
      _devices.add(device);
      _streamController.add(_devices);
      return true;
    } catch (e) {
      print('Error in creating device = $e');
      return false;
    }
  }

  Future<bool> delete(Device device) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final deleteCount =
          await db.delete('DEVICE', where: 'ID = ?', whereArgs: [device.id]);

      if (deleteCount == 1) {
        _devices.remove(device);
        _streamController.add(_devices);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Deletion failed with error $e');
      return false;
    }
  }

  Future<bool> close() async {
    final db = _db;
    if (db == null) {
      return false;
    }

    await db.close();
    return true;
  }

  Future<bool> open() async {
    if (_db != null) {
      return true;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$dbName';

    try {
      final db = await openDatabase(path);
      _db = db;

      // create table
      final create = '''CREATE TABLE IF NOT EXISTS DEVICE (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        FIRST_NAME STRING NOT NULL,
        LAST_NAME STRING NOT NULL
      )''';

      await db.execute(create);

      // read all existing Device objects from the db
      _devices = await _fetchTool();
      _streamController.add(_devices);
      return true;
    } catch (e) {
      print('Error = $e');
      return false;
    }
  }

  Future<bool> update(Device device) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final updateCount = await db.update(
        'DEVICE',
        {
          'FIRST_NAME': device.firstName,
          'LAST_NAME': device.lastName,
        },
        where: 'ID = ?',
        whereArgs: [device.id],
      );

      if (updateCount == 1) {
        _devices.removeWhere((other) => other.id == device.id);
        _devices.add(device);
        _streamController.add(_devices);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('failed to update device, error = $e');
      return false;
    }
  }

  Stream<List<Device>> all() =>
      _streamController.stream.map((devices) => devices..sort());
}

class dashboard extends StatefulWidget {
  const dashboard({super.key});

  @override
  State<dashboard> createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  late final DeviceDB _crudStorage;
  List<Device> _devices = [];
  Color _color = Color(0xfff9a826);

  @override
  void initState() {
    _crudStorage = DeviceDB(dbName: 'db.sqlite');
    _crudStorage.open();
    super.initState();
  }

  @override
  void dispose() {
    _crudStorage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
        stream: _crudStorage.all(),
        builder: (context, snapshot) {
          print(snapshot);
          switch (snapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.waiting:
              if (snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final tool = snapshot.data as List<Device>;
              return Column(
                children: [
                  ComposeWidget(
                    onCompose: (firstName, lastName) {
                      _crudStorage.create(firstName, lastName);
                    },
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: tool.length,
                      onReorder: (oldIndex, newIndex) => setState(() {
                        final index =
                            newIndex > oldIndex ? newIndex - 1 : newIndex;

                        final device = tool.removeAt(oldIndex);
                        tool.insert(index, device);
                      }),
                      itemBuilder: (context, index) {
                        final device = tool[index];
                        return Slidable(
                          key: Key('$index'),
                          startActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                backgroundColor: Colors.yellowAccent,
                                icon: Icons.edit,
                                label: 'Edit',
                                onPressed: (context) async {
                                  final editedDevice = await showUpdateDialog(
                                    context,
                                    device,
                                  );
                                  if (editedDevice != null) {
                                    await _crudStorage.update(editedDevice);
                                  }
                                },
                              )
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                  backgroundColor: Colors.redAccent,
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Delete',
                                  onPressed: (context) async {
                                    final shouldDelete =
                                        await showDeleteDialog(context);
                                    print(shouldDelete);
                                    if (shouldDelete) {
                                      await _crudStorage.delete(device);
                                    }
                                  })
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.blue, Colors.red],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: [Colors.blue, Colors.red]
                                        .last
                                        .withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 4,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _color, width: 4),
                              ),
                              child: ListTile(
                                key: Key('$index'),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) => feature())));
                                },
                                // title: Text(device.firstName),
                                // subtitle: Text(device.lastName),
                                title: Text(device.fullName),
                                subtitle: Text('ID: ${device.id}'),
                                // title: Container(
                                //     height: 100, width: 200, child: mqttgauge()),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

Future<bool> showDeleteDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  ).then((value) {
    if (value is bool) {
      return value;
    } else {
      return false;
    }
  });
}

final _firstNameController = TextEditingController();
final _lastNameController = TextEditingController();

Future<Device?> showUpdateDialog(BuildContext context, Device device) {
  _firstNameController.text = device.firstName;
  _lastNameController.text = device.lastName;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your updated Values here:'),
            TextField(
              controller: _firstNameController,
            ),
            TextField(
              controller: _lastNameController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final editedDevice = Device(
                id: device.id,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
              );
              Navigator.of(context).pop(editedDevice);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).then((value) {
    if (value is Device) {
      return value;
    } else {
      return null;
    }
  });
}

typedef OnCompose = void Function(String firstname, String lastName);

class ComposeWidget extends StatefulWidget {
  final OnCompose onCompose;
  const ComposeWidget({super.key, required this.onCompose});

  @override
  State<ComposeWidget> createState() => _ComposeWidgetState();
}

class _ComposeWidgetState extends State<ComposeWidget> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              hintText: 'Enter device name',
            ),
          ),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              hintText: 'Description',
            ),
          ),
          TextButton(
            onPressed: () {
              final firstName = _firstNameController.text;
              final lastName = _lastNameController.text;
              widget.onCompose(firstName, lastName);
              _firstNameController.text = '';
              _lastNameController.text = '';
            },
            child: Text(
              'Add to list',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
