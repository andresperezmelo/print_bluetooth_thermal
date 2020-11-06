import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:device_info/device_info.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moor/moor.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

String getUrlServer(){
  bool produccion = true;
  String baseurl;
  if(produccion){
    baseurl = 'https://prestacop.000webhostapp.com/prestagroons/';
  }else{
    baseurl = 'http://10.0.2.2/prestagroons/';
  }

  return baseurl;
}

Future<String> getPathDB()async{
  var pathdb = await getDatabasesPath();
  final dbFolder = await getApplicationDocumentsDirectory();
  //print("path1: $pathdb path2: ${dbFolder.path}");
  //path1: /data/user/0/app.web.groons.prestagroons/databases path2: /data/user/0/app.web.groons.prestagroons/app_flutter

  return pathdb;
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

Future<int> diasCorridos(String fecha) async{

  var difference = 0;
  try{
    List<String> fec = fecha.split("/");
    int dia = int.parse(fec[0]);
    int mes = int.parse(fec[1]);
    int anio = int.parse(fec[2]);

    final fechavieja = DateTime(anio, mes, dia);
    final fechaactual = DateTime.now();
    difference = fechaactual.difference(fechavieja).inDays;
  }catch(e){
    print("Error: fecha mal formatiada $fecha");
  }
  return difference;
}

Future<int> diasPasados(String fecha,String diasNoCobra) async{

  var dias = 0;
  try{
    dias = await diasCorridos(fecha);
    Map mapDias = await getSabadosDomingos(fecha);
    int nSabados = mapDias['sabados'];
    int nDomingos = mapDias['domingos'];

    List<String> diassemana = diasNoCobra.split("/");
    String sabado = diassemana[0];
    String domingo = diassemana[1];

    if(sabado=="S"){
      dias = dias-nSabados;
    }
    if(domingo=="D"){
      dias = dias-nDomingos;
    }

  }catch(e){
    print("Error: dias pasados $e");
  }
  return dias;
}

Future<int> diasCorridosDosFechas(String fechaInicial,String fechaFinal) async{

  var difference = 0;
  try{
    List<String> fec = fechaInicial.split("/");
    int dia = int.parse(fec[0]);
    int mes = int.parse(fec[1]);
    int anio = int.parse(fec[2]);

    List<String> fecNew = fechaFinal.split("/");
    int dian = int.parse(fecNew[0]);
    int mesn = int.parse(fecNew[1]);
    int anion = int.parse(fecNew[2]);

    final fechainical = DateTime(anio, mes, dia);
    final fechafinal = DateTime(anion, mesn, dian);
    difference = fechafinal.difference(fechainical).inDays;
  }catch(e){
    print("Error: fechas mal formatiada Incial:$fechaInicial Final:$fechaFinal");
  }
  return difference;
}

Map getSabadosDomingos(String fechainicial){

  int sabados = 0;
  int domingos = 0;
  List<String> fec = fechainicial.split("/");
  int dia = int.parse(fec[0]);
  int mes = int.parse(fec[1]);
  int anio = int.parse(fec[2]);

  String fechahoy = fechaActual();
  List<String> fech = fechahoy.split("/");
  int diah = int.parse(fech[0]);
  int mesh = int.parse(fech[1]);
  int anioh = int.parse(fech[2]);

  final fechaInicial = DateTime(anio, mes, dia);
  final fechaactual = DateTime(anioh,mesh,diah);
  DateTime currentDay = fechaInicial;
  while (currentDay.isBefore(fechaactual)) {
    currentDay = currentDay.add(Duration(days: 1));
    //currentDay.weekday = (numero dia) eje: domingo=1,lunes=2, etc
    if (currentDay.weekday == 6) {
      sabados += 1;
    }
    if (currentDay.weekday == 7) {
      domingos += 1;
    }
  }
  Map dias = new Map();
  dias={
    "sabados": sabados,
    "domingos": domingos,
  };
  return dias;
}

int getDifferenceSabadosDomingos(DateTime startDate, DateTime endDate) {
  int nbDays = 0;
  DateTime currentDay = startDate;
  while (currentDay.isBefore(endDate)) {
    currentDay = currentDay.add(Duration(days: 1));
    //currentDay.weekday = (numero dia) eje: domingo=1,lunes=2, etc
    print("dia ${currentDay.weekday}");
    if (currentDay.weekday != DateTime.saturday && currentDay.weekday != DateTime.sunday) {
      nbDays += 1;
    }
  }
  return nbDays;
}

Future<Database> opendblocal() async{

  var pathdb = await getPathDB();

  // Abre la base de datos y guarda la referencia.
  final Future<Database> database = openDatabase(
    // Establecer la ruta a la base de datos. Nota: Usando la función `join` del
    // complemento `path` es la mejor práctica para asegurar que la ruta sea correctamente
    // construida para cada plataforma.
    p.join(pathdb, 'local.db'),
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

  var pathdb = await getPathDB();

  // Abre la base de datos y guarda la referencia.
  final Future<Database> database = openDatabase(
    // Establecer la ruta a la base de datos. Nota: Usando la función `join` del
    // complemento `path` es la mejor práctica para asegurar que la ruta sea correctamente
    // construida para cada plataforma.
    p.join(pathdb, 'admin.db'),
    // Cuando la base de datos se crea por primera vez, crea una tabla para almacenar dogs
    onCreate: (db, version) {
      db.execute("CREATE TABLE clientes(id INTEGER PRIMARY KEY,key TEXT NOT NULL UNIQUE,nombre TEXT,cedula TEXT,direccion TEXT,telefono TEXT,posicion NUMERIC, grupo TEXT,cupo NUMERIC)");
      db.execute("CREATE TABLE prestamos(id INTEGER PRIMARY KEY,pertenece TEXT NOT NULL,fecha TEXT,capital NUMERIC,interes TEXT,porcentajecapital TEXT,diasinterescobrado TEXT,mora TEXT,porcentajemora TEXT,diasmoracobrado TEXT,diasmora TEXT,modalidad TEXT,diascuota TEXT,interesconsecutivo TEXT,plazo INTEGER,cuota NUMERIC,alarma TEXT,descontardias NUMERIC,diasnocobra TEXT,ultimopago TEXT,pagos TEXT,movimientos TEXT)");
      db.execute("CREATE TABLE caja(id INTEGER PRIMARY KEY, caja TEXT,interescapital TEXT,interesatraso TEXT,interesvencido TEXT,diasatraso TEXT,diasvencido TEXT, movimientos TEXT)");
      db.execute("CREATE TABLE gastos(id INTEGER PRIMARY KEY, gasto TEXT, valor TEXT, dia NUMERIC,mes NUMERIC,anio NUMERIC, hora TEXT)");
      db.execute("CREATE TABLE resumendia(id INTEGER PRIMARY KEY, fecha TEXT,hora TEXT,tipo TEXT, movimiento TEXT, valor TEXT, modo TEXT, capital TEXT, interes TEXT,porcentaje TEXT,idref TEXT)");
      db.execute("CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)");
      db.execute("CREATE TABLE fotos(id INTEGER PRIMARY KEY, nombre TEXT, bytes BLOB)");
      return db.execute("CREATE TABLE balances(id INTEGER PRIMARY KEY, dia NUMERIC,mes NUMERIC,anio NUMERIC, cobrado TEXT, capital TEXT, interes TEXT, ganancia TEXT, dinerocalle TEXT, clientesnuevos TEXT, numeroprestamos TEXT, valorprestado TEXT, pagos TEXT, mora TEXT, impresiones TEXT, compartidos TEXT, editados TEXT, gastos TEXT,  caja TEXT, movimientoscaja TEXT, movimientosdia TEXT, liquidaciones TEXT)",);
    },
    // Establece la versión. Esto ejecuta la función onCreate y proporciona una
    // ruta para realizar actualizacones y defradaciones en la base de datos.
    version: 1,
  );

  return await database;
}

Future<void> exportdb() async{
  File file;
  var pathdb = await getPathDB();
  var path = p.join(pathdb, "admin.db");
  var exists = await databaseExists(path);
  if (exists) {
    file = File(path);
  } else {
    print("No hay db");
    return;
  }
  Directory dir = await getExternalStorageDirectory();
  String pathdirectorio = dir.path;

  await file.copy('$pathdirectorio/admin.db');
  print("copia db exitosa $pathdirectorio");
}

Future<void> exportdblocal() async{
  File file;
  var pathdb = await getPathDB();
  var path = p.join(pathdb, "local.db");
  var exists = await databaseExists(path);
  if (exists) {
    file = File(path);
  } else {
    print("No hay db");
    return;
  }
  Directory dir = await getExternalStorageDirectory();
  String pathdirectorio = dir.path;
  //File newfile = File(pathdirectorio);

  // copy file
  await file.copy('$pathdirectorio/local.db');
  print("copia db local exitosa $pathdirectorio");
}

Future<void> importdb()async{

  var pathdb = await getPathDB();
  var path = p.join(pathdb, "admin.db");

  Directory dir = await getExternalStorageDirectory();
  String pathdirectorio = dir.path;
  File file = new File('$pathdirectorio/admin.db');

  var copy = file.copy(path);

  print("db inmportada de $pathdirectorio result $copy");
}

Future<void> importadb(String pathlocal)async{

  var pathdb = await getPathDB();
  var path = p.join(pathdb, "admin.db");
  File file = new File('$pathlocal');

  var copy = await file.copy(path);

  print("resultado: ${copy.path}");

  print("db inmportada de $pathlocal result $copy");
}

Future<void> borrarDB()async{
  var pathdb = await getPathDB();
  var path = p.join(pathdb, "admin.db");
  await deleteDatabase(path);
  print("db borrada");
}

Future<void> borrarTabla(String tabla)async{
  Database database = await opendb();
  await database.delete(tabla);
  print("borro tabla $tabla");
  await database.close();
}

Future<void> crearCarpeta(String path)async{

  Directory dir = await getExternalStorageDirectory();
  String pathdirectorio = dir.path;
  new Directory("$pathdirectorio/$path").create().then((Directory directory) {
    //print("==>Carpeta creada: ${directory.path}");
  });

}

Future<void> agregarTabla(String sql,)async{
  Database database = await opendb();
  //String sql = "CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT);"
  await database.rawQuery(sql);
  print("agrago tabla a la db");
  await database.close();
}

Future<void> agregarColumnaTabla(String tabla,String nombreColumna)async{
  Database database = await opendb();
  await database.rawQuery('ALTER TABLE $tabla ADD COLUMN $nombreColumna TEXT');
  print("agrago columna $nombreColumna a la tabla $tabla");
  await database.close();
}

Future<void> copiarFile(File file,String nombre)async{

  Directory dir = await getExternalStorageDirectory();
  String pathdirectorio = dir.path;
  await file.copy('$pathdirectorio/$nombre');
  print("Archivo copiado");
}

Future<void> crearFile(ByteData data,String nombre)async {
  Directory dir = await getExternalStorageDirectory();
  String path = dir.path+"/"+nombre;
  final buffer = data.buffer;
  await new File(path).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  //await File(desiredDestinationPath).writeAsBytes(bytes);
  print("archivo creado");
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
  await database.close();
}

Future<String> getLocal(String nombre) async{
  String valor = "_";
  Database database = await opendblocal();
  List<Map> list = await database.rawQuery('SELECT * FROM local WHERE nombre=?', [nombre]);
  //list.forEach((row) => print(row));
  if(list.length>0){
    valor = list[0]['valor'];
  };
  await database.close();
  return valor;
}

Future<List<Map>> getLocalTodo() async{
  Database database = await opendblocal();
  List<Map> list = await database.rawQuery('SELECT * FROM local');
  await database.close();
  return list;
}

Future<void> setInfo(String nombre,String valor) async{

  bool existe = false;
  Database database = await opendb();

  List<Map> list = await database.rawQuery('SELECT * FROM info WHERE nombre=?', [nombre]);
  if(list.length>0){
    existe = true;
  };

  if(existe) {
    //actualizar datos
    int count = await database.rawUpdate('UPDATE info SET valor = ? WHERE nombre = ?', [valor,nombre]);
  }else{
    //insertar primera vez
    await database.transaction((txn) async {
      int id1 = await txn.rawInsert('INSERT INTO info(nombre, valor) VALUES(?, ?)', [nombre, valor]);
      //print('insertado: $id1 nombre: $nombre valor: $valor');
    });
  }
  await database.close();
}

Future<List<Map>> getInfo() async{
  try {
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM info');
    await database.close();
    return list;
  }catch(e){
    await agregarTabla("CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)");
    return null;
  }
}

Future<void> setBytesFotos(String nombre,Uint8List valor) async{

  bool existe = false;
  Database database = await opendb();

  List<Map> list = await database.rawQuery('SELECT * FROM fotos WHERE nombre=?', [nombre]);
  if(list.length>0){
    existe = true;
  };

  if(existe) {
    //actualizar datos
    int count = await database.rawUpdate('UPDATE fotos SET bytes = ? WHERE nombre = ?', [valor,nombre]);
  }else{
    //insertar primera vez
    await database.transaction((txn) async {
      int id1 = await txn.rawInsert('INSERT INTO fotos(nombre, bytes) VALUES(?, ?)', [nombre, valor]);
      //print('insertado: $id1 nombre: $nombre valor: $valor');
    });
  }
  await database.close();
}

Future<Uint8List> getBytesFotos(String nombre) async{

  Database database = await opendb();
  try {

    List<Map> list = await database.rawQuery('SELECT * FROM fotos where nombre=?',[nombre]);
    await database.close();
    if(list.length>0) {
      Map result = list[0];
      var imgbytes = result['bytes'];
      Uint8List bytes = imgbytes;
      return bytes;
    }else{
      return null;
    }
  }catch(e){
    print("Error en getBytesFotos $e");
    await database.close();
    try {
      await agregarTabla("CREATE TABLE fotos(id INTEGER PRIMARY KEY, nombre TEXT, bytes BLOB)");
    }catch(e){
      print("error en error $e");
    }
    return null;
  }
}

Future<Map> getInfoDispositivo() async {

  Map mapa;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
      Map map = {
        'version.securityPatch': build.version.securityPatch,
        'version.sdkInt': build.version.sdkInt,
        'version.release': build.version.release,
        'version.previewSdkInt': build.version.previewSdkInt,
        'version.incremental': build.version.incremental,
        'version.codename': build.version.codename,
        'version.baseOS': build.version.baseOS,
        'board': build.board,
        'bootloader': build.bootloader,
        'brand': build.brand,
        'device': build.device,
        'display': build.display,
        'fingerprint': build.fingerprint,
        'hardware': build.hardware,
        'host': build.host,
        'id': build.id,
        'manufacturer': build.manufacturer,
        'model': build.model,
        'product': build.product,
        'supported32BitAbis': build.supported32BitAbis,
        'supported64BitAbis': build.supported64BitAbis,
        'supportedAbis': build.supportedAbis,
        'tags': build.tags,
        'type': build.type,
        'isPhysicalDevice': build.isPhysicalDevice,
        'androidId': build.androidId,
        'systemFeatures': build.systemFeatures,
      };
      mapa = {
        "device":build.brand,
        "modelo":build.model,
        "id":build.id,
      };

    } else if (Platform.isIOS) {
      IosDeviceInfo data = await deviceInfoPlugin.iosInfo;
      Map map = {
        'name': data.name,
        'systemName': data.systemName,
        'systemVersion': data.systemVersion,
        'model': data.model,
        'localizedModel': data.localizedModel,
        'identifierForVendor': data.identifierForVendor,
        'isPhysicalDevice': data.isPhysicalDevice,
        'utsname.sysname:': data.utsname.sysname,
        'utsname.nodename:': data.utsname.nodename,
        'utsname.release:': data.utsname.release,
        'utsname.version:': data.utsname.version,
        'utsname.machine:': data.utsname.machine,
      };
      mapa = {
        "device":data.name,
        "modelo":data.model,
        "id":data.identifierForVendor,
      };
    }
  } on PlatformException {
    mapa = {
      "device":"Desconocido",
      "modelo":"Desconocido",
      "id":"Desconocido",
    };;
  }

  return mapa;

}

Future<String> getDatoCliente(String key,String dato) async{
  //datos: key ,nombre,cedula ,direccion,telefono,posicion,grupo
  String valor = "_";
  Database database = await opendb();
  List<Map> list = await database.rawQuery('SELECT * FROM clientes WHERE key=?', [key]);
  await database.close();
  //list.forEach((row) => print(row));
  if(list.length>0){
    valor = list[0]['$dato'].toString();
  };
  return valor;
}

Future<int> getTotalClientes()async {

  Database database = await opendb();
  List<Map> clientes = await database.rawQuery("SELECT * FROM clientes");
  await database.close();

  return clientes.length;

}

Future<int> getTotalBalances()async {

  try {
    Database database = await opendb();
    List<Map> balances = await database.rawQuery("SELECT * FROM balances");
    await database.close();

    return balances.length;
  }catch(e){
    return 0;
  }

}

Future<double> getTotalCalle()async {

  Database database = await opendb();
  List<Map> clientes = await database.rawQuery("SELECT * FROM prestamos WHERE capital>'0' ");
  await database.close();

  double totalcalle = 0;
  if(clientes.length>0){

    await Future.forEach(clientes, (cliente){
      double capital = double.parse(cliente['capital'].toString());
      double interes = double.parse(cliente['interes'].toString());
      totalcalle = totalcalle+(capital+interes);
    });

  }

  return totalcalle;

}

Future<void> setCopiaLocal()async{
  String ruta = await getLocal("ruta");
  String copialocal = await getLocal("copialocal");
  String fecha = fechaActual();
  List fec = fecha.split("/");
  String dia = fec[0];
  await crearCarpeta("backup");
  if(copialocal!=fecha){
    File file;
    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");
    var exists = await databaseExists(path);
    if (exists) {
      file = File(path);
    } else {
      print("No hay db");
      return;
    }
    String nombre = "${ruta}(dia$dia).db";
    Directory dir = await getExternalStorageDirectory();
    String pathdirectorio = dir.path;

    // copy file
    await file.copy('$pathdirectorio/backup/$nombre');
    print("copia db exitosa $pathdirectorio");
  }
}

void compartirdb()async{
  File file;
  var pathdb = await getPathDB();
  var path = p.join(pathdb, "admin.db");
  var exists = await databaseExists(path);
  if (exists) {
    file = File(path);
  } else {
    print("No hay db");
    return;
  }

  List<int> bytes = await file.readAsBytes();
  await Share.file('Copia de base de datos', 'admin.db', bytes, 'application/db');

}

String getTrasformarNumeroGrafica(double numero){

  String nuevo = numero.toString();
  if(numero>=1000000){
    double newnumber = numero/1000000;
    nuevo = "$newnumber millon";
  }else if(numero>=1000){
    double newnumber = numero/1000;
    nuevo = "$newnumber mil";
  }

  return nuevo;
}

Future<void> esperar(int milisegundos){
  Future.delayed(const Duration(milliseconds: 500), () {

  });
  /*
  Future.delayed(const Duration(milliseconds: 500), () {

  });*/
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

String getMesEnLetras(String mes){
  switch (int.parse(mes)){
    case 1:
      return 'ENERO';
    case 2:
      return 'FEBRERO';
    case 3:
      return 'MARZO';
    case 4:
      return 'ABRIL';
    case 5:
      return 'MAYO';
    case 6:
      return 'JUNIO';
    case 7:
      return 'JULIO';
    case 8:
      return 'AGOSTO';
    case 9:
      return 'SEPTIEMBRE';
    case 10:
      return 'OCTUBRE';
    case 11:
      return 'NOVIEMBRE';
    case 12:
      return 'DICIEMBRE';
  }
  return '';
}

String primeraLetraMayuzcula(String texto){
  return texto[0].toUpperCase()+texto.substring(1);
}

String dejarDosDecimales(double numero){
  String result = numero.toStringAsFixed(2);
  return result;
}

String dejarUnDecimales(double numero){
  String result = numero.toStringAsFixed(1);
  return result;
}

String dejarSinDecimales(double numero){
  String result = numero.toStringAsFixed(0);
  return result;
}

int convertirPositivo(int numero){
  int numpositvo = (numero < 0) ? numero * -1 : numero;
  return numpositvo;
}

double convertirPositivoDouble(double numero){
  double numpositvo = (numero < 0) ? numero * -1 : numero;
  return numpositvo;
}

Map verCapitalInteres(double total,double porcentaje){
  double interes = (total*porcentaje)/(100+porcentaje);
  double capital = total-interes;
  Map map = new Map();
  map = {
    "capital": dejarDosDecimales(capital),
    "interes": dejarDosDecimales(interes),
  };
  return map;
}

Future<Map> getCaja()async {

  Database database = await opendb();
  List<Map> listcaja = await database.rawQuery("SELECT * FROM caja WHERE id=?",["1"]);
  await database.close();

  Map caja;
  if(listcaja.length>0){
    caja = listcaja[0];
  }else{
    caja = {
      "id": "2", "caja": "0", "interescapital": "0", "interesatraso": "0", "interesvencido": "0", "diasatraso": "0", "diasvencido": "0", "movimientos":"",
    };
  }

  return caja;

}

void setCaja(String caja,String movimiento) async{

  Database database = await opendb();
  List<Map> list = await database.rawQuery("SELECT * FROM caja WHERE id=?",["1"]);

  String movimientos = "";
  if(list.length>0) {
    movimientos = "${list[0]['movimientos']} *$movimiento \n";
  }else{
    movimientos = "*"+movimiento;
  }

  if(list.length<=0) {
    await database.transaction((txn) async {
      int id = await txn.rawInsert('INSERT INTO caja(id,caja,interescapital,interesatraso,interesvencido,diasatraso,diasvencido,movimientos) VALUES(?,?,?,?,?,?,?,?)', ["1",caja,"0","0","0","0","0",movimientos]);
      print('Caja nueva ');
    });
  }else{
    //actualizar datos
    int count = await database.rawUpdate('UPDATE caja SET caja =?,movimientos=? WHERE id = ?', [caja,movimientos,"1"]);
    print('caja actualizada $movimiento');
  }
  await database.close();
}

void setCajaLimpiarMovimientos(double caja) async{

  Database database = await opendb();
  List<Map> list = await database.rawQuery("SELECT * FROM caja WHERE id=?",["1"]);

  if(list.length<=0) {
    await database.transaction((txn) async {
      int id = await txn.rawInsert('INSERT INTO caja(id,caja,interescapital,interesatraso,interesvencido,diasatraso,diasvencido,movimientos) VALUES(?,?,?,?,?,?,?,?)', ["1",caja,"0","0","0","0","0",""]);
      print('Caja nueva ');
    });
  }else{
    //actualizar datos
    int count = await database.rawUpdate('UPDATE caja SET caja=?, movimientos=? WHERE id = ?', [caja,"","1"]);
    print('caja actualizada ');
  }
  await database.close();
}

void setUltimaconexion()async{
  String id = await getLocal("iduser");

  var data = {
    "ultimaconexion": fechaActual(),
  };

}

Future<Map> getDatosMensaje()async{

  Map resultado = {"titulo": "Ola", "mensaje": "Cuerpo del mensaje", "obligatorio": "no","url": "http","version": "no"};

  return resultado;

}

String dejarSinDecimalSiTerminaEnCeros(String numero){

  String llego = numero;
  String numerofinal = numero;
  List partes = llego.split(".");
  String parteuno = partes[0].toString();
  String partedos = partes[1].toString();

  int decimales = int.parse(partedos);

  if(decimales==0){
    numerofinal = parteuno;
  }

  return numerofinal;

}

Future<String> verSaldo(String idprestamo)async{

  double saldo = 0;
  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  await database.close();
  if(prestamo.length>0){
    //String id = prestamo[0]['id'].toString();
    String fecha = prestamo[0]['fecha'].toString();
    String modalidad = prestamo[0]['modalidad'];
    double capital = double.parse(prestamo[0]['capital'].toString());
    double interes = double.parse(prestamo[0]['interes'].toString());
    int diascuota = int.parse(prestamo[0]['diascuota'].toString());
    int plazo = int.parse(prestamo[0]['plazo'].toString());
    String interesconsecutivo = prestamo[0]['interesconsecutivo'].toString();
    double porcentajecapital = double.parse(prestamo[0]['porcentajecapital'].toString());
    int diasinteres = int.parse(prestamo[0]['diasinterescobrado'].toString());
    String diasnocobra = prestamo[0]['diasnocobra'].toString();
    saldo = capital + interes;

    if(interesconsecutivo=="si") {
      int diaspasados = await diasPasados(fecha,diasnocobra);
      int diasmes = 30;
      int plazodias = plazo;
      if (modalidad == "Semanal") {
        diasmes = 28;
        plazodias = plazo*7;
      }else if (modalidad == "Quincenal") {
        plazodias = plazo*15;
      }else if (modalidad == "Mensual") {
        plazodias = plazo*30;
      }else if (modalidad == "Personalizado") {
        plazodias = plazo * diascuota;
      }
      int diassepaso = diaspasados;//-plazodias;
      int faltadias = diassepaso - diasinteres;
      //print("diasepaso: $diassepaso diasinteres: $diasinteres diaspasados: $diaspasados faltadias: $faltadias");
      if (faltadias>0) {

        double interesmensual = capital * porcentajecapital / 100;
        double interesdiario = interesmensual / diasmes;
        double agregarinteres = interesdiario * faltadias;
        double newInteres = interes + agregarinteres;
        newInteres = double.parse(dejarDosDecimales(newInteres));
        saldo = capital + newInteres;
        //print("add consecutivo: agregado $agregarinteres por $faltadias dias ");
        Database database = await opendb();
        int count = await database.rawUpdate('UPDATE prestamos SET interes =?, diasinterescobrado = ? WHERE id = ?', [dejarDosDecimales(newInteres), diassepaso, idprestamo]);
        await database.close();
        if (count == 1) {
          String movimiento = "Interes actualizado agregado: ${dejarDosDecimales(agregarinteres)} por $faltadias dias";
          print(movimiento);
          agregarMovimientoPrestamo(idprestamo, movimiento);
        }
      }
    }
  }

  return saldo.toString();
}

Future<Map> verEstadoPrestamo(String idprestamo)async {

  double saldo = 0;
  double capital = 0;
  double interes = 0;
  double valorcuota = 0;
  double totalPrestado = 0;
  double atraso = 0;
  int tiempoTrascurrido = 0;
  int diassepaso = 0;
  String letras = "";
  String periodo = "";
  String estado = "";
  String ava = "atrasado";
  double cuotaspagas = 0;
  double cuotaspendientes = 0;
  double dineroAtrasado = 0;
  double dineroCompletarCuota = 0;
  bool interesConsecutivo = false;
  int ultimopagohace = 0;
  bool alarma = false;
  List<Color> color = new List();
  color = [Colores.normal,Colores.normal1];

  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  await database.close();
  //List<Map> prestamo = getPrestamo();
  //print("info: $prestamo");

  if(prestamo.length>0){
    Map item = prestamo[0];

    String fecha = item['fecha'].toString();
    String key = item['pertenece'].toString();
    saldo = double.parse( await verSaldo(idprestamo)); //saldoreal
    capital = double.parse(item['capital'].toString());
    interes = double.parse(item['interes'].toString());
    //saldo = capital+interes; //esto se debe quitar
    double porcentajecapital = double.parse(item['porcentajecapital'].toString());
    int diasinterescobrado = int.parse(item['diasinterescobrado'].toString());
    String interesconsecutivo = item['interesconsecutivo'].toString();

    double mora = double.parse(item['mora'].toString());
    String porcentajemora = item['porcentajemora'].toString();
    String diasmora = item['diasmora'].toString();
    List datadias = diasmora.split("/");
    int diasPorAtraso  = int.parse(datadias[0]);
    int diasPorVencido = int.parse(datadias[1]);
    String diasmoracobrados = item['diasmoracobrado'].toString();//dias mora cobrados

    String modalidad = item['modalidad'];
    int diascuota = int.parse(item['diascuota'].toString());
    double cuota = double.parse(item['cuota'].toString());
    int plazo = int.parse(item['plazo'].toString());
    int plazodias = plazo;
    int descontardias = int.parse(item['descontardias'].toString());
    String diasnocobra = item['diasnocobra'].toString();
    String ultimopago = item['ultimopago'].toString();
    ultimopagohace = await diasCorridos(ultimopago);

    String alarm = item['alarma'].toString();
    if (alarm == fechaActual()) {
      alarma = true;
    } else {
      if(alarm.length>=4) {
        int diaslarma = await diasCorridos(alarm);
        if (diaslarma > 0) {
          alarma = true;
        }
      }
    }

    valorcuota = cuota;

    int diaspasados = await diasPasados(fecha,diasnocobra);
    diaspasados = diaspasados-descontardias; //aqui descontardias para descontarlos
    tiempoTrascurrido = diaspasados;

    cuotaspendientes = saldo / cuota;
    cuotaspagas = plazo - cuotaspendientes;
    totalPrestado = cuota * plazo;

    //print("plazo $plazo diaspasados:$diaspasados cuotaspagas:$cuotaspagas cuotaspendientes:$cuotaspendientes saldo:$saldo");

    if(modalidad=="Diario"){
      if(interesconsecutivo=="si") {
        interesConsecutivo = true;
        dineroAtrasado = interes;
        atraso = diasinterescobrado.toDouble();
        letras = "Interes generado";
        periodo = "dias";
        color = [Colores.incrementable,Colores.incrementable1];
      }else{
        atraso = diaspasados - cuotaspagas;
        letras = "Atrasado";
        periodo = "dias";
        dineroAtrasado = atraso * cuota;
        //print("atraso $atraso por cuota $cuota igual $dineroAtrasado");
        //calcula el dinero para completar la cuota
        List<String> cuotasobra = cuotaspendientes.toString().split(".");
        double sobro = double.parse("0."+cuotasobra[1]);
        dineroCompletarCuota = sobro*cuota;

        if(diaspasados>plazodias){
          color = [Colores.vencido,Colores.vencido1];
          atraso = (diaspasados-plazodias).toDouble();
          dineroAtrasado = saldo;
          letras = "Vencido hace";
          ava = "vencido";
        }else if(atraso>5){
          color = [Colores.atrasado,Colores.atrasado1];
        }else if(atraso<0){
          ava = "adelantado";
          color = [Colores.adelantado,Colores.adelantado1];
          atraso = convertirPositivoDouble(atraso);
          dineroAtrasado = convertirPositivoDouble(dineroAtrasado);
          letras = "Adelantado";
          periodo = "dias";
        }
      }
      diassepaso = atraso.toInt();
      estado = "$letras ${dejarDosDecimales(atraso)} $periodo";
    }else if(modalidad=="Semanal"){
      periodo = "semenas";
      int diastipo = 7;
      plazodias = plazo*diastipo;
      double periodopasado = diaspasados/diastipo;
      diassepaso = 0;
      if(interesconsecutivo=="si"){
        interesConsecutivo = true;
        dineroAtrasado = interes;
        color = [Colores.incrementable,Colores.incrementable1];
        atraso = diasinterescobrado / diastipo;
        if(diasinterescobrado>=diastipo){
          diassepaso = diasinterescobrado%diastipo;
        }else{
          diassepaso = diasinterescobrado;
        }
        letras = "Interes aplicado";
      }else{
        atraso = periodopasado - cuotaspagas;
        dineroAtrasado = atraso * cuota;
        //calcula el dinero para completar la cuota
        List<String> cuotasobra = cuotaspendientes.toString().split(".");
        double sobro = double.parse("0."+cuotasobra[1]);
        dineroCompletarCuota = sobro*cuota;

        double undiavale = 1/diastipo;
        double diasatraso = atraso/undiavale;
        if(diasatraso>=diastipo){
          color = [Colores.semanal,Colores.semanal1];
          diassepaso = diasatraso.toInt()%diastipo;
        }else{
          diassepaso = diasatraso.toInt();
        }
        if(atraso<0) {
          ava = "adelantado";
          color = [Colores.adelantado,Colores.adelantado1];
          atraso = convertirPositivoDouble(atraso);
          letras = "Adelantado";
          dineroAtrasado = convertirPositivoDouble(dineroAtrasado);
          double undiavale = 1/diastipo;
          double adelantodias = atraso/undiavale;
          adelantodias = convertirPositivoDouble(adelantodias);
          if(adelantodias>=diastipo){
            diassepaso = adelantodias.toInt() % diastipo;
          }else {
            diassepaso = adelantodias.toInt();
          }
          
        }else if(plazodias<diaspasados){
          ava = "vencido";
          dineroAtrasado = saldo;
        }else{
          letras = "Atrasado";
        }
      }
      if(plazodias<diaspasados&&interesconsecutivo=="no"){
        letras = "Vencido hace";
        color = [Colores.vencido,Colores.vencido1];
        diassepaso = diaspasados-plazodias;
        atraso = diassepaso.toDouble();
        dineroAtrasado = saldo;
        estado = "$letras $diassepaso dias";
      }else{
        estado = "$letras ${atraso.toInt()} $periodo y $diassepaso dias";
      }

    }else if(modalidad=="Quincenal"){
      periodo = "quincenas";
      int diastipo = 15;
      plazodias = plazo*diastipo;
      double periodopasado = diaspasados/diastipo;
      diassepaso = 0;
      if(interesconsecutivo=="si"){
        interesConsecutivo = true;
        dineroAtrasado = interes;
        color = [Colores.incrementable,Colores.incrementable1];
        atraso = diasinterescobrado / diastipo;
        if(diasinterescobrado>=diastipo){
          diassepaso = diasinterescobrado%diastipo;
        }else{
          diassepaso = diasinterescobrado;
        }
        letras = "Interes aplicado";
      }else{
        atraso = periodopasado - cuotaspagas;
        dineroAtrasado = atraso * cuota;
        //calcula el dinero para completar la cuota
        List<String> cuotasobra = cuotaspendientes.toString().split(".");
        double sobro = double.parse("0."+cuotasobra[1]);
        dineroCompletarCuota = sobro*cuota;

        double undiavale = 1/diastipo;
        double diasatraso = atraso/undiavale;
        if(diasatraso>=diastipo){
          color = [Colores.semanal,Colores.semanal1];
          diassepaso = diasatraso.toInt()%diastipo;
        }else{
          diassepaso = diasatraso.toInt();
        }
        if(atraso<0) {
          ava = "adelantado";
          color = [Colores.adelantado,Colores.adelantado1];
          atraso = convertirPositivoDouble(atraso);
          letras = "Adelantado";
          dineroAtrasado = convertirPositivoDouble(dineroAtrasado);
          double undiavale = 1/diastipo;
          double adelantodias = atraso/undiavale;
          adelantodias = convertirPositivoDouble(adelantodias);
          if(adelantodias>=diastipo){
            diassepaso = adelantodias.toInt() % diastipo;
          }else {
            diassepaso = adelantodias.toInt();
          }

        }else if(plazodias<diaspasados){
          ava = "vencido";
        }else{
          letras = "Atrasado";
        }
      }

      if(plazodias<diaspasados&&interesconsecutivo=="no"){
        letras = "Vencido hace";
        color = [Colores.vencido,Colores.vencido1];
        diassepaso = diaspasados-plazodias;
        atraso = diassepaso.toDouble();
        dineroAtrasado = saldo;
        estado = "$letras $diassepaso dias";
      }else{
        estado = "$letras ${atraso.toInt()} $periodo y $diassepaso dias";
      }

    }else if(modalidad=="Mensual"){
      periodo = "meses";
      int diastipo = 30;
      plazodias = plazo*diastipo;
      double periodopasado = diaspasados/diastipo;
      diassepaso = 0;
      if(interesconsecutivo=="si"){
        interesConsecutivo = true;
        dineroAtrasado = interes;
        color = [Colores.incrementable,Colores.incrementable1];
        atraso = diasinterescobrado / diastipo;
        if(diasinterescobrado>=diastipo){
          diassepaso = diasinterescobrado%diastipo;
        }else{
          diassepaso = diasinterescobrado;
        }
        letras = "Interes aplicado";
      }else{
        atraso = periodopasado - cuotaspagas;
        dineroAtrasado = atraso * cuota;
        //calcula el dinero para completar la cuota
        List<String> cuotasobra = cuotaspendientes.toString().split(".");
        double sobro = double.parse("0."+cuotasobra[1]);
        dineroCompletarCuota = sobro*cuota;

        double undiavale = 1/diastipo;
        double diasatraso = atraso/undiavale;
        if(diasatraso>=diastipo){
          color = [Colores.semanal,Colores.semanal1];
          diassepaso = diasatraso.toInt()%diastipo;
        }else{
          diassepaso = diasatraso.toInt();
        }
        if(atraso<0) {
          ava = "adelantado";
          color = [Colores.adelantado,Colores.adelantado1];
          atraso = convertirPositivoDouble(atraso);
          letras = "Adelantado";
          dineroAtrasado = convertirPositivoDouble(dineroAtrasado);
          double undiavale = 1/diastipo;
          double adelantodias = atraso/undiavale;
          adelantodias = convertirPositivoDouble(adelantodias);
          if(adelantodias>=diastipo){
            diassepaso = adelantodias.toInt() % diastipo;
          }else {
            diassepaso = adelantodias.toInt();
          }

        }else if(plazodias<diaspasados){
          ava = "vencido";
        }else{
          letras = "Atrasado";
        }
      }

      if(plazodias<diaspasados&&interesconsecutivo=="no"){
        letras = "Vencido hace";
        color = [Colores.vencido,Colores.vencido1];
        diassepaso = diaspasados-plazodias;
        atraso = diassepaso.toDouble();
        dineroAtrasado = saldo;
        estado = "$letras $diassepaso dias";
      }else{
        estado = "$letras ${atraso.toInt()} $periodo y $diassepaso dias";
      }

    }else if(modalidad=="Personalizado"){
      periodo = "*";
      int diastipo = diascuota;
      plazodias = plazo*diastipo;
      double periodopasado = diaspasados/diastipo;
      diassepaso = 0;
      if(interesconsecutivo=="si"){
        interesConsecutivo = true;
        dineroAtrasado = interes;
        color = [Colores.incrementable,Colores.incrementable1];
        atraso = diasinterescobrado / diastipo;
        if(diasinterescobrado>=diastipo){
          diassepaso = diasinterescobrado%diastipo;
        }else{
          diassepaso = diasinterescobrado;
        }
        letras = "Interes aplicado";
      }else{
        atraso = periodopasado - cuotaspagas;
        dineroAtrasado = atraso * cuota;
        //calcula el dinero para completar la cuota
        List<String> cuotasobra = cuotaspendientes.toString().split(".");
        double sobro = double.parse("0."+cuotasobra[1]);
        dineroCompletarCuota = sobro*cuota;

        double undiavale = 1/diastipo;
        double diasatraso = atraso/undiavale;
        if(diasatraso>=diastipo){
          color = [Colores.semanal,Colores.semanal1];
          int sobrodias = diasatraso.toInt()%diastipo;
          if(diastipo<=diasPorAtraso){
            diassepaso = ((atraso.toInt() * diascuota) + sobrodias).toInt();
          }else {
            diassepaso = sobrodias;
          }
        }else{
          diassepaso = diasatraso.toInt();
        }
        if(atraso<0) {
          ava = "adelantado";
          color = [Colores.adelantado,Colores.adelantado1];
          atraso = convertirPositivoDouble(atraso);
          letras = "Adelantado";
          dineroAtrasado = convertirPositivoDouble(dineroAtrasado);
          double undiavale = 1/diastipo;
          double adelantodias = atraso/undiavale;
          adelantodias = convertirPositivoDouble(adelantodias);
          if(adelantodias>=diastipo){
            diassepaso = adelantodias.toInt() % diastipo;
          }else {
            diassepaso = adelantodias.toInt();
          }

        }else if(plazodias<diaspasados){
          ava = "vencido";
          diassepaso = diaspasados-plazodias;
        }else{
          letras = "Cuotas de atraso";
        }
      }

      if(plazodias<diaspasados&&interesconsecutivo=="no"){
        letras = "Vencido hace";
        color = [Colores.vencido,Colores.vencido1];
        diassepaso = diaspasados-plazodias;
        atraso = diassepaso.toDouble();
        dineroAtrasado = saldo;
        estado = "$letras $diassepaso dias";
      }else{
        estado = "$letras ${atraso.toInt()} $periodo y $diassepaso dias";
      }

    }else if(modalidad=="Fijo"){
      periodo = "dias";
      int diastipo = diascuota;
      plazodias = plazo;
      diassepaso = 0;

      atraso = (plazodias - diaspasados).toDouble();
      dineroAtrasado = saldo;
      cuotaspendientes = saldo/cuota;
      cuotaspagas = 1-cuotaspendientes;

      if(plazodias<diaspasados) {
        ava = "vencido";
        color = [Colores.vencido,Colores.vencido1];
        atraso = (diaspasados-plazodias).toDouble();
        letras = "Vencido hace";
        diassepaso = atraso.toInt();
      }else{
        letras = "Se cumple el plazo en";
        color = [Colores.fijo,Colores.fijo1];
      }

      estado = "$letras ${atraso.toInt()} $periodo ";
    }

    if(saldo<=0){
      int diasdemas = await diasCorridosDosFechas(fecha, ultimopago);
      diasdemas = diasdemas-descontardias;
      estado = "Demoro $diasdemas de $plazodias dias de plazo";
      color = [Colores.gris,Colores.azulgris];
    }

    Map estadoprestamo = new Map();
    estadoprestamo = {
      "id": idprestamo,
      "key": key,
      "modalidad": modalidad,
      "fecha": fecha,
      "cuota": valorcuota,
      "plazo": plazo,
      "saldo" : saldo,
      "capital" : capital,
      "interes" : interes,
      "totalprestado" : totalPrestado,
      "atraso" : atraso,
      "tiempotrascurrido" : tiempoTrascurrido,
      "diassepaso" : diassepaso,
      "letras" : letras,
      "periodo" : periodo,
      "estado" : estado,
      "ava" : ava,
      "cuotaspagas" : cuotaspagas,
      "cuotaspendientes" : cuotaspendientes,
      "dineroatrasado" : dejarDosDecimales(dineroAtrasado),
      "dinerocompletarcuota" : dejarDosDecimales(dineroCompletarCuota),
      "interesconsecutivo" : interesConsecutivo,
      "ultimopagohace": ultimopagohace,
      "alarma": alarma,
      "diaspasados": diaspasados,
      "color": color,
      "mora" : mora,
      "porcentajemora": porcentajemora,
      "diasmora": diasmora,
      "diasmoracobrado": diasmoracobrados,
    };

    //print("atraso=>: $letras ${atraso.toInt()} $periodo y $diassepaso dias (atrasonormal:$atraso) dinerocompletarcuota:$dineroCompletarCuota");
    //print("estado: $estado");
    //print("mapafinal=>: $estadoprestamo");

    return estadoprestamo;

  }else{
    return getEstadoPrestamoBlanco();
  }

}

List<Map> getPrestamo(){
  List<Map> listamapa = new List();
  Map prestamo = {
    "id": 5, "pertenece": "d48c83d0-b657-11ea-9b6a-b963eefdc1c9", "fecha": "01/06/2020", "capital": "100000", "interes": "20000", "porcentajecapital": "20",
    "diasinterescobrado": "30", "mora": "0", "porcentajemora": "5/10", "diasmoracobrado": "0/0", "diasmora": "3/1", "modalidad": "Fijo", "diascuota": "30",
    "interesconsecutivo": "no", "plazo": "30", "cuota": "120000", "alarma": "0", "descontardias": "0", "diasnocobra": "A/A", "ultimopago": "24/06/2020", "pagos": "",
    "movimientos": "creado prestamo 24/06/2020 15:23:01",
  };

  listamapa.add(prestamo);

  return listamapa;
}

Map getEstadoPrestamoBlanco(){

  Map estadoprestamo = {
    "id": "0",
    "key " : "0",
    "modalidad": "no",
    "fecha": "fecha",
    "cuota": "valorcuota",
    "plazo": "plazo",
    "saldo" : "saldo",
    "capital" : "capital",
    "interes" : "interes",
    "totalprestado" : "totalPrestado",
    "atraso" : "atraso",
    "tiempotrascurrido" : "tiempoTrascurrido",
    "diassepaso" : "diassepaso",
    "letras" : "letras",
    "periodo" : "periodo",
    "estado" : "estado",
    "ava" : "ava",
    "cuotaspagas" : 0.0,
    "cuotaspendientes" : 0.0,
    "dineroatrasado" : "dineroAtrasado",
    "dinerocompletarcuota" : "dineroCompletarCuota",
    "interesconsecutivo" : false,
    "ultimopagohace": "ultimopagohace",
    "alarma": "no",
    "diaspasados": "diaspasados",
    "color": "color",
    "mora" : "mora",
    "porcentajemora": "porcentajemora",
    "diasmora": "diasmora",
    "diasmoracobrado": "diasmoracobrados",
  };

  return estadoprestamo;
}

Map getPrestamoBlanco(){

  Map prestamo = {
    "id": 5, "pertenece": "d48c83d0-b657-11ea-9b6a-b963eefdc1c9", "fecha": "00/00/0000", "capital": "0", "interes": "0", "porcentajecapital": "0",
    "diasinterescobrado": "0", "mora": "0", "porcentajemora": "0/0", "diasmoracobrado": "0/0", "diasmora": "0/0", "modalidad": "", "diascuota": "0",
    "interesconsecutivo": "no", "plazo": "0", "cuota": "0", "alarma": "0", "descontardias": "0", "diasnocobra": "A/A", "ultimopago": "00/00/0000", "pagos": "",
    "movimientos": "creado prestamo 00/00/0000 15:23:01",
  };

  return prestamo;
}

Map prestamo = {
  "id": 5, "pertenece": "d48c83d0-b657-11ea-9b6a-b963eefdc1c9", "fecha": "01/06/2020", "capital": "100000", "interes": "20000", "porcentajecapital": "20",
  "diasinterescobrado": "30", "mora": "0", "porcentajemora": "5/10", "diasmoracobrado": "0/0", "diasmora": "3/1", "modalidad": "Fijo", "diascuota": "30",
  "interesconsecutivo": "no", "plazo": "30", "cuota": "120000", "alarma": "0", "descontardias": "0", "diasnocobra": "A/A", "ultimopago": "24/06/2020", "pagos": "",
  "movimientos": "creado prestamo 24/06/2020 15:23:01",
};

Future<Map> verMora(String idprestamo)async{

  Map mapmora = new Map();
  double morafinal = 0;
  double interesatraso = 0;
  double interesvencido = 0;
  double interespordia = 0;
  String diasmora = "0/0";

  Map estado = await verEstadoPrestamo(idprestamo);
  //print("estado $estado");
  String ava = estado['ava'];
  bool isinteresconsecutivo = estado['interesconsecutivo'];
  double atraso = estado['atraso'];
  int diassepaso = estado['diassepaso'];
  double saldo = estado['saldo'];
  double cuota = estado['cuota'];
  double mora = estado['mora'];

  String porcentajemora = estado['porcentajemora'];
  List dataporcen = porcentajemora.split("/");
  interesatraso = double.parse(dataporcen[0]);
  interesvencido = double.parse(dataporcen[1]);
  diasmora = estado['diasmora'];
  List datadias = diasmora.split("/");
  int diasPorAtraso  = int.parse(datadias[0]);
  int diasPorVencido = int.parse(datadias[1]);
  String diasmoracobrados = estado['diasmoracobrado'];
  List datacobrados = diasmoracobrados.split("/");
  int diascobradoatraso = int.parse(datacobrados[0]);
  int diascobradovencido = int.parse(datacobrados[1]);
  /*
  print("--------> atraso: $atraso diassepaso: $diassepaso atrasado_vencido_adelantado: $ava isconsecutivo: $isinteresconsecutivo");
  print("mora $mora % $porcentajemora dias $diasmora diascobrados $diasmoracobrados");
  print("%atraso $interesatraso %vencido $interesvencido diasPorAtraso $diasPorAtraso diasporvencido $diasPorVencido diasatrasocobrado $diascobradoatraso diascobradovencido $diascobradovencido");
  */
  if(ava=="atrasado"&&isinteresconsecutivo==false){//si esta atrasado y no es interesconsecutivo

    if(diassepaso>=diasPorAtraso &&atraso>1 && diasPorAtraso>0){
      int faltadias = diassepaso-diascobradoatraso;
      double dinerototal = atraso*cuota;
      double interes = (dinerototal*interesatraso)/100;
      interespordia = interes/30;
      double agregarinteres = interespordia*faltadias;
      morafinal = mora+agregarinteres;
      print("add atraso $agregarinteres");

      if(morafinal>mora){
        String nuevodiasmoracobrados = "$diassepaso/$diascobradovencido";
        Database database = await opendb();
        int count = await database.rawUpdate('UPDATE prestamos SET mora = ?, diasmoracobrado =?  WHERE id = ?', [dejarDosDecimales(morafinal),nuevodiasmoracobrados, idprestamo]);
        await database.close();
        String movimiento = "Agrego interes atraso ${dejarDosDecimales(agregarinteres)} por $faltadias dias (total:${dejarDosDecimales(morafinal)})";
        await agregarMovimientoPrestamo(idprestamo, movimiento);
        print("print $movimiento");
      }
    }else{
      morafinal = mora;
    }

  }else if(ava=="vencido" &&isinteresconsecutivo==false){//si esta vencido
    if(diassepaso>=diasPorVencido && diasPorVencido>0){
      int faltadias = diassepaso-diascobradovencido;
      double dinerototal = saldo;
      double interes = (dinerototal*interesvencido)/100;
      interespordia = interes/30;
      double agregarinteres = interespordia*faltadias;
      morafinal = mora+agregarinteres;
      print("add vencido $agregarinteres");

      if(morafinal>mora){
        String nuevodiasmoracobrados = "$diascobradoatraso/$diassepaso";
        Database database = await opendb();
        int count = await database.rawUpdate('UPDATE prestamos SET mora = ?, diasmoracobrado =?  WHERE id = ?', [dejarDosDecimales(morafinal),nuevodiasmoracobrados, idprestamo]);
        await database.close();
        String movimiento = "Agrego interes vencido ${dejarDosDecimales(agregarinteres)} por $faltadias dias (total:${dejarDosDecimales(morafinal)})";
        agregarMovimientoPrestamo(idprestamo, movimiento);
        print("print $movimiento");
      }
    }else{
      morafinal = mora;
    }
  }else{
    morafinal = mora;
  }

  mapmora = {
    "mora": dejarDosDecimales(morafinal),
    "interesdia": dejarDosDecimales(interespordia),
    "interesatraso": interesatraso.toString(),
    "interesvencido": interesvencido.toString(),
    "diasmora": diasmora,
  };

  //print("mora: $mapmora");


  return mapmora;
}

Future<List<Color>> verColor(String idprestamo)async{

  List<Color> lista = new List();
  //lista.add(Colores.normal);
  Color color1 = Colores.normal;
  Color color2 = Colores.normal1;
  Color color;

  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  await database.close();
  if(prestamo.length>0) {
    //String id = prestamo[0]['id'].toString();
    double saldo = double.parse(await verSaldo(idprestamo));
    if (saldo>0) {
      String fecha = prestamo[0]['fecha'].toString();
      String modalidad = prestamo[0]['modalidad'];
      double cuota = double.parse(prestamo[0]['cuota'].toString());
      int periodo = int.parse(prestamo[0]['plazo'].toString());
      String diasnocobra = prestamo[0]['diasnocobra'].toString();
      int descontardias = int.parse(prestamo[0]['descontardias'].toString());
      int plazo = periodo;
      String interesconsecutivo = prestamo[0]['interesconsecutivo'].toString();
      int diaspasados = await diasPasados(fecha,diasnocobra);
      diaspasados = diaspasados-descontardias;
      double atraso = double.parse(await verAtraso(idprestamo));

      //print("modalidad $modalidad atraso $atraso interesconsecutivo $interesconsecutivo diaspasados $diaspasados");

      if(modalidad=="Diario"){
        if(interesconsecutivo=="si"){

        }else{
          if(atraso>5){
            color = Colors.orange;
            color1 = Colores.atrasado;
            color2 = Colores.atrasado1;
          }
        }
      }else if(modalidad=="Semanal"){
        if(interesconsecutivo=="si"){

        }else{
          plazo = (plazo*7).toInt();
          if(atraso>=1){
            color = Colors.blue;
            color1 = Colores.semanal;
            color2 = Colores.semanal1;
          }
        }
      }else if(modalidad=="Quincenal"){
        if(interesconsecutivo=="si"){

        }else{
          plazo = (plazo*15).toInt();
          if(atraso>=1){
            color = Colors.blue;
            color1 = Colores.semanal;
            color2 = Colores.semanal1;
          }
        }
      }else if(modalidad=="Mensual"){
        if(interesconsecutivo=="si"){

        }else{
          plazo = (plazo*30).toInt();
          if(atraso>=1){
            color = Colors.blue;
            color1 = Colores.semanal;
            color2 = Colores.semanal1;
          }
        }
      }else if(modalidad == "Personalizado"){
        if(interesconsecutivo=="si"){

        }else{
          if(atraso>5){
            color = Colors.orange[700];
            color1 = Colores.personalizado;
            color2 = Colores.personalizado1;
          }
        }
      }else if(modalidad=="Fijo"){
        if(interesconsecutivo=="si"){

        }else{
          if(atraso>=1){
            color = Colors.red;
            color1 = Colores.vencido;
            color2 = Colores.vencido1;
          }
        }
      }
      if(diaspasados>plazo){
        if(interesconsecutivo=="si"){
          color = Colors.purple;
          color1 = Colores.incrementable;
          color2 = Colores.incrementable1;
        }else{
          color = Colors.red;
          color1 = Colores.vencido;
          color2 = Colores.vencido1;
        }
      }else{
        if(atraso<0){
          color = Colors.green;
          color1 = Colores.adelantado;
          color2 = Colores.adelantado1;
        }
      }
    }//saldo es menor o 0
  }

  lista.add(color1);
  lista.add(color2);

  return lista;
}

Future<Map> getLiQuidacionesDiaAnterior()async{

  Database database = await opendb();
  List<Map> list = await database.rawQuery("SELECT * FROM balances ORDER BY anio DESC, mes DESC, dia DESC");
  await database.close();

  int balances = list.length;
  int liquidacionesdia = 0;
  String fecha = fechaActual();
  String fecha2;
  if(balances>=2){
    Map diauno = list[0];
    int dia = diauno['dia'];
    String diaf = dia.toString();
    if(dia<10)diaf = "0$dia";
    int mes = diauno['mes'];
    String mesf = mes.toString();
    if(mes<10)mesf = "0$mes";
    String anio = diauno['anio'].toString();
    fecha2 = "$diaf/$mesf/$anio";

    if(fecha2==fecha){
      Map diados = list[1];
      String liquidaciones = diados['liquidaciones'];
      List<String> liqui = liquidaciones.split("*");
      liquidacionesdia = liqui.length;
    }else{
      String liquidaciones = diauno['liquidaciones'];
      List<String> liqui = liquidaciones.split("*");
      liquidacionesdia = liqui.length;
    }
  }else if(balances==1){
    Map diauno = list[0];
    String dia = diauno['dia'].toString();
    String mes = diauno['mes'].toString();
    String anio = diauno['anio'].toString();
    fecha2 = "$dia/$mes/$anio";

    if(fecha2!=fecha){
      String liquidaciones = diauno['liquidaciones'];
      List<String> liqui = liquidaciones.split("*");
      liquidacionesdia = liqui.length;
    }
  }

  print("liquidaciones $liquidacionesdia ");
  Map map = {"fecha":fecha2,"liquidaciones":liquidacionesdia};
  return map;

}

Future<String> verAtraso(String idprestamo)async{

  double atraso = 0;

  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  await database.close();
  if(prestamo.length>0) {
    //String id = prestamo[0]['id'].toString();
    double saldo = double.parse(await verSaldo(idprestamo));
    if (saldo>0) {
      String fecha = prestamo[0]['fecha'].toString();
      String modalidad = prestamo[0]['modalidad'];
      double cuota = double.parse(prestamo[0]['cuota'].toString());
      double plazo = double.parse(prestamo[0]['plazo'].toString());
      String diasnocobra = prestamo[0]['diasnocobra'].toString();
      int diascuota = int.parse(prestamo[0]['diascuota'].toString());
      int descontardias = int.parse(prestamo[0]['descontardias'].toString());
      int periodosdado = plazo.toInt();
      int diaspasados = await diasPasados(fecha,diasnocobra);
      diaspasados = diaspasados-descontardias;
      String interesconsecutivo = prestamo[0]['interesconsecutivo'].toString();

      int plazodias = plazo.toInt();
      /*if(interesconsecutivo=="si"){
        if(modalidad=="Diario")plazo = diaspasados/1;
        if(modalidad=="Semanal")plazo = diaspasados/7;
        if(modalidad=="Quincenal")plazo = diaspasados/15;
        if(modalidad=="Mensual")plazo = diaspasados/30;
        if(modalidad=="Personalizado")plazo = diaspasados/diascuota;
      }*/
      //print("plazo en atraso consecutivo $plazo");
      double periodopasado = diaspasados.toDouble();
      if(modalidad == "Diario"){

      }else if (modalidad == "Semanal") {
        periodopasado = diaspasados / 7;
        plazodias = (plazo*7).toInt();
      } else if (modalidad == "Quincenal") {
        periodopasado = diaspasados / 15;
        plazodias = (plazo*15).toInt();
      } else if (modalidad == "Mensual") {
        periodopasado = diaspasados / 30;
        plazodias = (plazo*30).toInt();
      } else if(modalidad == "Personalizado"){
        periodopasado = diaspasados / diascuota;
        plazodias = (plazo*diascuota).toInt();
      }else if (modalidad == "Fijo") {
        if(periodopasado>plazo){
          atraso = (diaspasados - plazodias).toDouble();
          return atraso.toString();
        }else {
          atraso = 0;
          return atraso.toString();
        }
      }

      double cuotaspendientes = saldo / cuota;
      double cuotaspagas = periodosdado - cuotaspendientes;
      atraso = periodopasado - cuotaspagas;
      /*if(interesconsecutivo=="si"){
        atraso = atraso-plazodias;
      }*/

      //print("1=> saldo $saldo atraso $atraso priodopasado $periodopasado cuotaspagas $cuotaspagas cuotaspendientes $cuotaspendientes");
      //print("2=> atraso $atraso modalidad $modalidad cuotaspagas $cuotaspagas plazo $plazo periodosdado $periodosdado diaspasados $diaspasados");
      if(interesconsecutivo=="si"){
        //print("interesconsecutivo $interesconsecutivo atraso: $atraso ");
      }else {
        if (diaspasados > plazodias) {
          atraso = (diaspasados - plazodias).toDouble();
        } else {
          //atraso = diaspasados - cuotaspagas;
        }
      }
    }//saldo es menor o 0
  }

  //print("atraso: $atraso ");

  return atraso.toString();
}

Future<void> ordenarClientes(List<Map> lista)async{
  int i = 0;
  Database database = await opendb();
  await Future.forEach(lista, (element)async{
    String id = element['id'];
    int count = await database.rawUpdate('UPDATE clientes SET posicion = ? WHERE id = ?', [i,id]);
    print("nombre: ${element['nombre']} posici: $i id: $id");
    i++;
  });
  await database.close();
}

Future agregarHistorialPago(String idprestamo,String pago)async{

  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  String pagos = prestamo[0]['pagos'].toString();
  pagos = pagos+pago+"-";
  int count = await database.rawUpdate('UPDATE prestamos SET pagos = ? WHERE id = ?', [pagos,idprestamo]);
  await database.close();
}

Future agregarMovimientoPrestamo(String idprestamo,String movimiento)async{

  Database database = await opendb();
  List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
  String movimientos = prestamo[0]['movimientos'].toString();
  String tiempo = "${fechaActual()} ${horaActual()}";
  movimientos = movimientos+"-"+tiempo+" "+movimiento;
  int count = await database.rawUpdate('UPDATE prestamos SET movimientos = ? WHERE id = ?', [movimientos,idprestamo]);
  await database.close();
}

Future agregarResumenDia(String tipo,String movimiento,String valor,String capital,String interes,String porcentaje,String idref)async{

  //se necesita fecha, hora, tipo, movimiento, valor, modo(si cobrador o admin) pordentaje y idref(id de cliente, gasto, etc)

  String fecha = fechaActual();
  String hora = horaActual();
  String modo = "Cobrador";

  Database database = await opendb();
  await database.transaction((txn) async {
    int id1 = await txn.rawInsert('INSERT INTO resumendia(fecha, hora,tipo, movimiento,valor,modo,capital,interes,porcentaje,idref) VALUES(?,?,?,?,?,?,?,?,?,?)', [fecha,hora,tipo,movimiento,valor,modo,capital,interes,porcentaje,idref]);
    //print('insertado: $id1 nombre: $nombre valor: $valor');
  });
  await database.close();
}

String idUnico(){
  Random random = new Random();
  int randomNumber = random.nextInt(100)+1000;
  String tiempo = DateFormat("ddMMyyyyHHmmss").format(DateTime.now());
  String resultado = tiempo+"$randomNumber";
  return resultado;
}



class Colores{
  static Color primario = Color(0xFF003f88);
  static Color secundario = Color(0xFFfdc500);
  static Color tercero = Color(0xff00296b);

  static Color normal = Color(0xFF5D6D7E);
  static Color normal1 = Color(0xFFBFC9CA);
  static Color atrasado = Color(0xFFff9100);
  static Color atrasado1 = Color(0xFFFFC77D);
  static Color adelantado = Color(0xFF245501);
  static Color adelantado1 = Color(0xFF73a942);
  static Color vencido = Color(0xFFd90429);
  static Color vencido1 = Color(0xFFff5a5f);
  static Color semanal = Color(0xFF006494);
  static Color semanal1 = Color(0xFF00a6fb);
  static Color incrementable = Color(0xFF4e148c);
  static Color incrementable1 = Color(0xFFa600fe);
  static Color personalizado = Color(0xffFF6B6B);
  static Color personalizado1 = Color(0xffFFA96C);
  static Color fijo = Color(0xff5f0f40);
  static Color fijo1 = Color(0xff9e0059);


  static Color rosadoclaro = Color(0xffff6b6b);
  static Color rosadooscuro = Color(0xffef476f);
  static Color verdeoscuro = Color(0xff028090);
  static Color verdeclaro = Color(0xff4ecdc4);
  static Color verdeoliva = Color(0xff80b918);
  static Color verdeolivaoscuro = Color(0xff283618);
  static Color verdeveis = Color(0xffa8dadc);
  static Color verdemuyclaro = Color(0xffd8e2dc);
  static Color moradoclaro = Color(0xff9e0059);
  static Color morado =  Color(0xFF4e148c);
  static Color moradooscuro = Color(0xff5f0f40);
  static Color piel = Color(0xffe6beae);
  static Color piel2 = Color(0xffeae2b7);
  static Color pielclaro = Color(0xffeee4e1);
  static Color vinotinto = Color(0xff9a031e);
  static Color amarillo = Color(0xfffcbf49);
  static Color naranja = Color(0xfff77f00);
  static Color azulado = Color(0xff247ba0);
  static Color azul = Color(0xff414288);
  static Color azulclaro = Color(0xffedf6f9);
  static Color gris = Color(0xffa2a3bb);
  static Color grisclaro = Color(0xfff5f5f5);
  static Color azulgris = Color(0xffaec5eb);
  static Color azuloscuro = Color(0xff190933);
  static Color verde = Color(0xff387d7a);

}

class BaseAlertDialog extends StatelessWidget {

  //When creating please recheck 'context' if there is an error!

  Color _colorFondo;
  Widget _title;
  Widget _content;
  Widget _yes;
  Widget _no;
  Function _yesOnPressed;
  Function _noOnPressed;

  BaseAlertDialog({Widget title, Widget content, Function yesOnPressed, Function noOnPressed, Widget yes = const Text("Si"), Widget no = const Text("No"),Color fondoColor = const Color.fromRGBO(33, 47, 60, 1)}){
    this._title = title;
    this._content = content;
    this._yesOnPressed = yesOnPressed;
    this._noOnPressed = noOnPressed;
    this._yes = yes;
    this._no = no;
    this._colorFondo = fondoColor;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6,sigmaY: 6),
      child: AlertDialog(
        title: this._title,
        content: this._content,
        backgroundColor: this._colorFondo,
        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(15)),
        actions: <Widget>[
          FlatButton(
            onPressed: (){
              this._yesOnPressed();
            },
            child: _yes,
          ),
          FlatButton(
            onPressed: (){
              this._noOnPressed();
            },
            child: _no,
          ),
        ],
      ),
    );
  }
}

class BaseAlertDialogWidget extends StatelessWidget {

  //When creating please recheck 'context' if there is an error!

  Color _colorFondo;
  Widget _title;
  Widget _content;

  BaseAlertDialog({Widget title = const Text(""),Widget content = const Text(""),Color fondoColor = const Color.fromRGBO(33, 47, 60, 1)}){
    this._colorFondo = fondoColor;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6,sigmaY: 6),
      child: AlertDialog(
        title: this._title,
        content: this._content,
        backgroundColor: this._colorFondo,
        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(15)),
      ),
    );
  }
}

/*
Future<void> _uploadFile() async {
  File file;
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, "admin.db");
  var exists = await databaseExists(path);
  if (exists) {
    file = File(path);
  } else {
    print("no existe el archivo ");
    setState(() {
      print("No hay base de datos para subir");
    });
    return;
  }

  final StorageReference postimegen = FirebaseStorage.instance
      .ref()
      .child("imagenes"); //crea la carpeta donde guardar la imagen
  var time = DateTime.now();
  final StorageUploadTask uploadTask =
  postimegen.child("admin.db").putFile(file);
  String imagenUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
  url = imagenUrl.toString();
  print("url $url");
}

Future<void> _downloadFile() async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, "admin.db");

  //await deleteDatabase(path);
  print("borrada db");

  //var response = await http.post(url);
  final http.Response response = await http.get(url);
  int totalbytes = response.contentLength;
  print("response $totalbytes");
  await new File(path).writeAsBytes(response.bodyBytes, flush: true);
  setState(() {
    print("Descargado exitoso: $totalbytes bytes");
  });
  /*if (totalbytes > 10000) {
      await new File(path).writeAsBytes(response.bodyBytes, flush: true);
      setState(() {
        print("Descargado exitoso: $totalbytes bytes");
      });
    } else {
      setState(() {
        print("Fallido no hay copias de esta empresa: $totalbytes bytes");
      });
    }*/
}
*/