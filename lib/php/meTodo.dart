import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

snackBar(BuildContext context,String mensaje,int segundos){
  final snackBar = new SnackBar(content: new Text(mensaje), backgroundColor: Colors.blueGrey,duration: Duration(seconds: segundos));
  return Scaffold.of(context).showSnackBar(snackBar);
}

dialogSimple(BuildContext context,String mensaje){
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: new Text(mensaje),
        actions: <Widget>[
          FlatButton(
            child: new Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

dialogCupertino(BuildContext context,String titulo,String mensaje){
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return  CupertinoAlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(mensaje),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

String fechaActual(){
  return DateFormat("dd/MM/yyyy").format(DateTime.now());
}

String horaActual(){
  return DateFormat("HH:mm:ss").format(DateTime.now());
}

String mesActual(){
  return DateFormat("MM").format(DateTime.now());
}

String dejarDosDecimales(double numero){
  String result = numero.toStringAsFixed(2);
  return result;
}

Future<Database> opendblocal() async{
  // Abre la base de datos y guarda la referencia.
  final Future<Database> database = openDatabase(
    // Establecer la ruta a la base de datos. Nota: Usando la función `join` del
    // complemento `path` es la mejor práctica para asegurar que la ruta sea correctamente
    // construida para cada plataforma.
    join(await getDatabasesPath(), 'local.db'),
    // Cuando la base de datos se crea por primera vez, crea una tabla para almacenar dogs
    onCreate: (db, version) {
      return db.execute("CREATE TABLE local(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)",);
    },
    // Establece la versión. Esto ejecuta la función onCreate y proporciona una
    // ruta para realizar actualizacones y defradaciones en la base de datos.
    version: 1,
  );

  return await database;
}

Future<Database> opendb() async{
  // Abre la base de datos y guarda la referencia.
  final Future<Database> database = openDatabase(
    // Establecer la ruta a la base de datos. Nota: Usando la función `join` del
    // complemento `path` es la mejor práctica para asegurar que la ruta sea correctamente
    // construida para cada plataforma.
    join(await getDatabasesPath(), 'admin.db'),
    // Cuando la base de datos se crea por primera vez, crea una tabla para almacenar dogs
    onCreate: (db, version) {
      db.execute("CREATE TABLE caja(id INTEGER PRIMARY KEY, caja TEXT, fecha TEXT, hora TEXT)");
      db.execute("CREATE TABLE empleados(id INTEGER PRIMARY KEY, codigo TEXT, creado TEXT, nombre TEXT, documento TEXT, nivel TEXT, ingreso TEXT)");
      db.execute("CREATE TABLE formulas(id INTEGER PRIMARY KEY, producto TEXT, uso TEXT, dosis TEXT, combo TEXT)");
      db.execute("CREATE TABLE gastos(id INTEGER PRIMARY KEY, gasto TEXT, valor TEXT, fecha TEXT, hora TEXT)");
      db.execute("CREATE TABLE productos(id INTEGER PRIMARY KEY, producto TEXT, unidadesensobre DOUBLE, sobresencaja DOUBLE, ganancia DOUBLE TEXT, laboratorio TEXT, comision DOUBLE, comercial TEXT, iva DOUBLE, uso TEXT)");
      db.execute("CREATE TABLE resumendia(id INTEGER PRIMARY KEY, hora TEXT, fecha TEXT, movimiento TEXT, detalle TEXT, valor DOUBLE, empleado TEXT,comision DOUBLE,subido TEXT)");
      db.execute("CREATE TABLE scaner(id INTEGER PRIMARY KEY, codigobarras TEXT, idref TEXT, valorfactura DOUBLE, agregados TEXT, unidades DOUBLE, valorcaja DOUBLE, valorsobre DOUBLE, valorunidad DOUBLE, fecharegistro TEXT, vencimiento TEXT)");
      return db.execute("CREATE TABLE balances(id INTEGER PRIMARY KEY, fecha TEXT, vendido TEXT, gastos TEXT, comision TEXT, caja TEXT, clientes TEXT )",);
    },
    // Establece la versión. Esto ejecuta la función onCreate y proporciona una
    // ruta para realizar actualizacones y defradaciones en la base de datos.
    version: 1,
  );

  return await database;
}

Future<void> setLocal(String nombre,String valor) async{

  String val = await getLocal(nombre);
  Database database = await opendblocal();

  if(val=="_") {
    await database.transaction((txn) async {
      int id1 = await txn.rawInsert('INSERT INTO local(nombre, valor) VALUES(?, ?)', [nombre, valor]);
      //print('insertado: $id1 nombre: $nombre valor: $valor');
    });
  }else{
    //actualizar datos
    int count = await database.rawUpdate('UPDATE local SET valor = ? WHERE nombre = ?', [valor,nombre]);
  }
  //await database.close();
}

Future<String> getLocal(String nombre) async{
  String valor = "_";
  Database database = await opendblocal();
  List<Map> list = await database.rawQuery('SELECT * FROM local WHERE nombre=?', [nombre]);
  //list.forEach((row) => print(row));
  if(list.length>0){
    valor = list[0]['valor'];
  };
  //await database.close();
  return valor;
}

String getUrlServer(){
  bool produccion = true;
  String baseurl;
  if(produccion){
    baseurl = 'https://softcop.000webhostapp.com/farmagroons/';
  }else{
    baseurl = 'http://10.0.2.2/farmacop/';
  }

  return baseurl;
}

Future<String> cajaActual() async{
  String valor = "0";
  Database database = await opendb();
  List<Map> list = await database.rawQuery('SELECT * FROM caja');
  //list.forEach((row) => print(row));
  if(list.length>0){
    valor = list[0]['caja'];
  };
  await database.close();
  return valor;
}

Size screenSize(BuildContext context) {
  return MediaQuery.of(context).size;
}

double screenHeight(BuildContext context) {
  return screenSize(context).height;
}

double screenWidth(BuildContext context) {
  return screenSize(context).width;
}

logmio(String mensaje){
  print("Logmio => $mensaje");
}



Future<void> nuevoejemplodb() async{
  // Obtenga una ubicación usando getDatabasesPath
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'demo.db');

// Eliminar la base de datos
  await deleteDatabase(path);

// abrir la base de datos
  Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
      });

// Insertar algunos registros en una transacción
  await database.transaction((txn) async {
    int id1 = await txn.rawInsert(
        'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
    print('inserted1: $id1 name: some name');
    int id2 = await txn.rawInsert(
        'INSERT INTO Test(name, value, num) VALUES(?, ?, ?)',
        ['another name', 12345678, 3.1416]);
    print('inserted2: $id2');
  });

// Actualizar algún registro
  int count = await database.rawUpdate(
      'UPDATE Test SET name = ?, value = ? WHERE name = ?',
      ['updated name', '9876', 'some name']);
  print('updated: $count');

// Obtener los registros
  List<Map> list = await database.rawQuery('SELECT * FROM Test');
  List<Map> expectedList = [
    {'name': 'updated name', 'id': 1, 'value': 9876, 'num': 456.789},
    {'name': 'another name', 'id': 2, 'value': 12345678, 'num': 3.1416}
  ];
  print('lista: $list');
  //print(expectedList);
  //assert(const DeepCollectionEquality().equals(list, expectedList));

// Cuenta los registros
  count = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM Test'));
  //assert(count == 2);

// Eliminar un registro
  count = await database.rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
  //assert(count == 1);

  List<Map> lista = await database.rawQuery('SELECT * FROM Test');

  logmio('lista nueva $lista');

// Cerrar la base de datos
  await database.close();
}