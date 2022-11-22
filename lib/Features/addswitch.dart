import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/Options_features/Switch/mqttswitch.dart';

import 'package:sqflite/sqflite.dart';

class Stch implements Comparable {
  final int id;
  final String firstName;
  final String lastName;

  const Stch({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';

  Stch.fromRow(Map<String, Object?> row)
      : id = row['ID'] as int,
        firstName = row['FIRST_NAME'] as String,
        lastName = row['LAST_NAME'] as String;

  @override
  int compareTo(covariant other) => other.id.compareTo(id);

  @override
  bool operator ==(covariant Stch other) => id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Stch, id = $id, firstName: $firstName, lastname: $lastName';

  static removeAt(int oldIndex) {
    Stch;
  }

  static insert(int newIndex) {
    Stch;
  }
}

class StchDB {
  final String dbName;
  Database? _db;
  List<Stch> _stchs = [];
  final _streamController = StreamController<List<Stch>>.broadcast();

  StchDB({required this.dbName});

  Future<List<Stch>> _fetchTool() async {
    final db = _db;
    if (db == null) {
      return [];
    }
    try {
      final read = await db.query(
        'STCH',
        distinct: true,
        columns: [
          'ID',
          'FIRST_NAME',
          'LAST_NAME',
        ],
        orderBy: 'ID',
      );

      final tool = read.map((row) => Stch.fromRow(row)).toList();
      return tool;
    } catch (e) {
      print('Error fetching switches = $e');
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
      final id = await db.insert('STCH', {
        'FIRST_NAME': firstName,
        'LAST_NAME': lastName,
      });
      final stch = Stch(
        id: id,
        firstName: firstName,
        lastName: lastName,
      );
      _stchs.add(stch);
      _streamController.add(_stchs);
      return true;
    } catch (e) {
      print('Error in creating switch = $e');
      return false;
    }
  }

  Future<bool> delete(Stch stch) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final deleteCount =
          await db.delete('STCH', where: 'ID = ?', whereArgs: [stch.id]);

      if (deleteCount == 1) {
        _stchs.remove(stch);
        _streamController.add(_stchs);
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
      final create = '''CREATE TABLE IF NOT EXISTS STCH (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        FIRST_NAME STRING NOT NULL,
        LAST_NAME STRING NOT NULL
      )''';

      await db.execute(create);

      // read all existing Switch objects from the db
      _stchs = await _fetchTool();
      _streamController.add(_stchs);
      return true;
    } catch (e) {
      print('Error = $e');
      return false;
    }
  }

  Future<bool> update(Stch stch) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final updateCount = await db.update(
        'STCH',
        {
          'FIRST_NAME': stch.firstName,
          'LAST_NAME': stch.lastName,
        },
        where: 'ID = ?',
        whereArgs: [stch.id],
      );

      if (updateCount == 1) {
        _stchs.removeWhere((other) => other.id == stch.id);
        _stchs.add(stch);
        _streamController.add(_stchs);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('failed to update stch, error = $e');
      return false;
    }
  }

  Stream<List<Stch>> all() =>
      _streamController.stream.map((stchs) => stchs..sort());
}

class Switchboard extends StatefulWidget {
  const Switchboard({super.key});

  @override
  State<Switchboard> createState() => _SwitchboardState();
}

class _SwitchboardState extends State<Switchboard> {
  late final StchDB _crudStorage;
  List<Stch> _stchs = [];
  Color _color = Color(0xfff9a826);

  @override
  void initState() {
    _crudStorage = StchDB(dbName: 'db.sqlite');
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
              final tool = snapshot.data as List<Stch>;
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

                        final stch = tool.removeAt(oldIndex);
                        tool.insert(index, stch);
                      }),
                      itemBuilder: (context, index) {
                        final stch = tool[index];
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
                                  final editedStch = await showUpdateDialog(
                                    context,
                                    stch,
                                  );
                                  if (editedStch != null) {
                                    await _crudStorage.update(editedStch);
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
                                      await _crudStorage.delete(stch);
                                    }
                                  })
                            ],
                          ),
                          child: Container(
                            height: 150,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.red, Colors.blue],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: [Colors.red, Colors.blue]
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
                                        builder: ((context) => mqttswitch())));
                              },
                              // title: Text(stch.firstName),
                              // subtitle: Text(stch.lastName),
                              // title: Text(stch.fullName),
                              // subtitle: Text('ID: ${stch.id}'),
                              title: Container(
                                  height: 100, width: 200, child: mqttswitch()),
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

Future<Stch?> showUpdateDialog(BuildContext context, Stch stch) {
  _firstNameController.text = stch.firstName;
  _lastNameController.text = stch.lastName;
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
              final editedStch = Stch(
                id: stch.id,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
              );
              Navigator.of(context).pop(editedStch);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).then((value) {
    if (value is Stch) {
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
          //     hintText: 'Enter switch name',
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
              'Add a Switch',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
