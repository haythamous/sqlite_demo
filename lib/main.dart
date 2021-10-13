import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(SqliteApp());
}

class SqliteApp extends StatefulWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  _SqliteAppState createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
          ),
        ),
        body: Center(
          child: FutureBuilder<List<Car>>(
              future: DatabaseHelper.instance.getCars(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Car>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Loading...'));
                }
                return snapshot.data!.isEmpty
                    ? Center(child: Text('No Cars in the List.'))
                    : ListView(
                  children: snapshot.data!.map((car) {
                    return Center(
                      child: Card(
                        color: selectedId == car.id
                            ? Colors.white70
                            : Colors.white,
                        child: ListTile(
                          title: Text(car.name),
                          onTap: () {
                            setState(() {
                              if (selectedId == null) {
                                textController.text = car.name;
                                selectedId = car.id;
                              } else {
                                textController.text = '';
                                selectedId = null;
                              }
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              DatabaseHelper.instance.remove(car.id!);
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance.update(
              Car(id: selectedId, name: textController.text),
            )
                : await DatabaseHelper.instance.add(
              Car(name: textController.text),
            );
            setState(() {
              textController.clear();
              selectedId = null;
            });
          },
        ),
      ),
    );
  }
}

class Car {
  final int? id;
  final String name;

  Car({this.id, required this.name});

  factory Car.fromMap(Map<String, dynamic> json) => new Car(
    id: json['id'],
    name: json['name'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cars.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars(
          id INTEGER PRIMARY KEY,
          name TEXT
      )
      ''');
  }

  Future<List<Car>> getCars() async {
    Database db = await instance.database;
    var cars = await db.query('cars', orderBy: 'name');
    List<Car> carList = cars.isNotEmpty
        ? cars.map((c) => Car.fromMap(c)).toList()
        : [];
    return carList;
  }

  Future<int> add(Car car) async {
    Database db = await instance.database;
    return await db.insert('cars', car.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Car car) async {
    Database db = await instance.database;
    return await db.update('cars', car.toMap(),
        where: "id = ?", whereArgs: [car.id]);
  }
}