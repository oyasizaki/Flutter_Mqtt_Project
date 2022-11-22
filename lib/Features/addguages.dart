import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/Options_features/Gauge/mqttgauge.dart';
import 'package:sqflite/sqflite.dart';

class Gauge implements Comparable {
  final int id;
  final String firstName;
  final String lastName;

  const Gauge({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';

  Gauge.fromRow(Map<String, Object?> row)
      : id = row['ID'] as int,
        firstName = row['FIRST_NAME'] as String,
        lastName = row['LAST_NAME'] as String;

  @override
  int compareTo(covariant other) => other.id.compareTo(id);

  @override
  bool operator ==(covariant Gauge other) => id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Gauge, id = $id, firstName: $firstName, lastname: $lastName';

  static removeAt(int oldIndex) {
    Gauge;
  }

  static insert(int newIndex) {
    Gauge;
  }
}

class GaugeDB {
  final String dbName;
  Database? _db;
  List<Gauge> _gauges = [];
  final _streamController = StreamController<List<Gauge>>.broadcast();

  GaugeDB({required this.dbName});

  Future<List<Gauge>> _fetchTool() async {
    final db = _db;
    if (db == null) {
      return [];
    }
    try {
      final read = await db.query(
        'GAUGE',
        distinct: true,
        columns: [
          'ID',
          'FIRST_NAME',
          'LAST_NAME',
        ],
        orderBy: 'ID',
      );

      final tool = read.map((row) => Gauge.fromRow(row)).toList();
      return tool;
    } catch (e) {
      print('Error fetching gauges = $e');
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
      final id = await db.insert('GAUGE', {
        'FIRST_NAME': firstName,
        'LAST_NAME': lastName,
      });
      final gauge = Gauge(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
      _gauges.add(gauge);
      _streamController.add(_gauges);
      return true;
    } catch (e) {
      print('Error in creating gauge = $e');
      return false;
    }
  }

  Future<bool> delete(Gauge gauge) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final deleteCount =
          await db.delete('GAUGE', where: 'ID = ?', whereArgs: [gauge.id]);

      if (deleteCount == 1) {
        _gauges.remove(gauge);
        _streamController.add(_gauges);
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
      final create = '''CREATE TABLE IF NOT EXISTS GAUGE (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        FIRST_NAME STRING NOT NULL,
        LAST_NAME STRING NOT NULL
      )''';

      await db.execute(create);

      // read all existing Gauge objects from the db
      _gauges = await _fetchTool();
      _streamController.add(_gauges);
      return true;
    } catch (e) {
      print('Error = $e');
      return false;
    }
  }

  Future<bool> update(Gauge gauge) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final updateCount = await db.update(
        'GAUGE',
        {
          'FIRST_NAME': gauge.firstName,
          'LAST_NAME': gauge.lastName,
        },
        where: 'ID = ?',
        whereArgs: [gauge.id],
      );

      if (updateCount == 1) {
        _gauges.removeWhere((other) => other.id == gauge.id);
        _gauges.add(gauge);
        _streamController.add(_gauges);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('failed to update gauge, error = $e');
      return false;
    }
  }

  Stream<List<Gauge>> all() =>
      _streamController.stream.map((gauges) => gauges..sort());
}

class Gaugeboard extends StatefulWidget {
  const Gaugeboard({super.key});

  @override
  State<Gaugeboard> createState() => _GaugeboardState();
}

class _GaugeboardState extends State<Gaugeboard> {
  late final GaugeDB _crudStorage;
  List<Gauge> _gauges = [];
  Color _color = Color(0xfff9a826);

  @override
  void initState() {
    _crudStorage = GaugeDB(dbName: 'db.sqlite');
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
              final tool = snapshot.data as List<Gauge>;
              return Column(
                children: [
                  ComposeWidget(
                    onCompose: (firstName, lastName) {
                      _crudStorage.create(firstName, lastName);
                    },
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      // shrinkWrap: true,
                      itemCount: tool.length,
                      onReorder: (oldIndex, newIndex) => setState(() {
                        final index =
                            newIndex > oldIndex ? newIndex - 1 : newIndex;

                        final gauge = tool.removeAt(oldIndex);
                        tool.insert(index, gauge);
                      }),
                      itemBuilder: (context, index) {
                        final gauge = tool[index];
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
                                  final editedGauge = await showUpdateDialog(
                                    context,
                                    gauge,
                                  );
                                  if (editedGauge != null) {
                                    await _crudStorage.update(editedGauge);
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
                                      await _crudStorage.delete(gauge);
                                    }
                                  })
                            ],
                          ),
                          child: Container(
                            height: 280,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.red, Colors.blueAccent],
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
                                        builder: ((context) => mqttgauge())));
                              },
                              // title: Text(gauge.firstName),
                              // subtitle: Text(gauge.lastName),
                              // title: Text(gauge.fullName),
                              // subtitle: Text('ID: ${gauge.id}'),
                              title: const SizedBox(
                                  height: 248, width: 100, child: mqttgauge()),
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

Future<Gauge?> showUpdateDialog(BuildContext context, Gauge gauge) {
  _firstNameController.text = gauge.firstName;
  _lastNameController.text = gauge.lastName;
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
              final editedGauge = Gauge(
                id: gauge.id,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
              );
              Navigator.of(context).pop(editedGauge);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).then((value) {
    if (value is Gauge) {
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
          // TextField(
          //   controller: _firstNameController,
          //   decoration: InputDecoration(
          //     hintText: 'Enter gauge name',
          //   ),
          // ),
          // TextField(
          //   controller: _lastNameController,
          //   decoration: InputDecoration(
          //     hintText: 'Description',
          //   ),
          // ),
          TextButton(
            onPressed: () {
              final firstName = _firstNameController.text;
              final lastName = _lastNameController.text;
              widget.onCompose(firstName, lastName);
              _firstNameController.text = '';
              _lastNameController.text = '';
            },
            child: Text(
              'Add a guage',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
