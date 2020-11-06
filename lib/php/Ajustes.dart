import 'dart:convert';
import 'dart:io';
import 'package:prestagroons/php/Inicio.dart';
import 'package:flutter/material.dart';
import 'package:prestagroons/php/meTodo.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

var baseurl = getUrlServer();

class ajustes extends StatefulWidget {
  @override
  _ajustesState createState() => _ajustesState();
}

class _ajustesState extends State<ajustes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajustes"),
      ),
      body: Container(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            _itemAjustes("Descargar copias", Icons.arrow_downward, descargarcopias()),
            _itemAjustes("Registrar empresa", Icons.add, crearEmpresa()),
            _itemAjustes("Mi cuenta", Icons.assignment, micuenta()),
            _itemAjustes("Subir copia", Icons.file_upload, subirCopia()),
            _itemAjustes("Caja", Icons.account_balance_wallet, caja()),
            _itemAjustes("Empleados", Icons.person_outline, empleadosDesig()),
          ],
        ),
      ),
    );
  }

  Widget _itemAjustes(String nombre, IconData icon, funcion) {
    return InkWell(
      onTap: () {
        Navigator.push(
            this.context, MaterialPageRoute(builder: (context) => funcion));
      },
      child: ListTile(
        leading: Icon(icon),
        title: Text(nombre),
      ),
    );
  }
}

class descargarcopias extends StatefulWidget {
  @override
  _descargarcopiasState createState() => _descargarcopiasState();
}

class _descargarcopiasState extends State<descargarcopias> {
  String message = "";
  bool visible = false;
  List items;

  Future<List> Recibir() async {
    var response = await leerEmpresas();
    setState(() {
      items = response;
      //print("termino $items");
    });
  }

  @override
  void initState() {
    visible = true;
    this.Recibir();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Descargar copias"),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Container(
              color: Colors.blueAccent.withOpacity(0.1),
              padding: EdgeInsets.fromLTRB(10, 30, 10, 10),
              child: Text(message),
            ),
            Container(
              color: Colors.blueAccent.withOpacity(0.1),
              alignment: Alignment.center,
              child: Visibility(
                  visible: visible,
                  child: Container(
                      margin: EdgeInsets.only(
                        bottom: 5,
                        top: 5,
                      ),
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ))),
            ),
            ListView.builder(
              scrollDirection: Axis.vertical,
              physics: PageScrollPhysics(),
              shrinkWrap: true,
              // Deja que ListView sepa cuántos elementos necesita para construir
              itemCount: items == null ? 0 : items.length,
              // Proporciona una función de constructor. ¡Aquí es donde sucede la magia! Vamos a
              // convertir cada elemento en un Widget basado en el tipo de elemento que es.
              itemBuilder: (context, index) {
                if (items == null) {
                  return CircularProgressIndicator();
                } else {
                  final item = items[index];
                  return _buildItem(item);
                }
              },
            ),
            OutlineButton(
              onPressed: () {
                setState(() {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => crearEmpresa()));
                });
              },
              child: Text("Registrar empresa"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(item) {
    return InkWell(
      onTap: () {
        descargar(item);
      },
      child: ListTile(
        title: new Text(item['nombre'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Future leerEmpresas() async {
    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || iduser == '_') {
      snackBar(this.context, "No hay usuario validado", 5);
      return;
    }

    setState(() {
      message = "Decargando datos";
      visible = true;
    });

    String url = baseurl + 'leerEmpresas.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    var jso = jsonDecode(response.body);

    print("respuesta server: ${jso}");

    if (jso.length <= 0) {
      message = "No hay empresas registradas";
    } else {
      message = "Selecciona una de las empresas para descargar la base de datos";
    }

    setState(() {
      visible = false;
    });

    return jso;
  }

  Future descargar(item) async {
    String empresa = item['nombre'];
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String idempresa = item['id'];
    String nombre = "admin.db";

    var data = {
      "iduser": iduser,
      "token": token,
      "empresa": idempresa,
      "nombre": nombre
    };

    print("data enviada: $data");

    setState(() {
      message = "Enviando solicitud";
    });

    String url = baseurl + "descargas.php";
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "admin.db");

    await deleteDatabase(path);
    print("borrada db");

    /*HttpClient client = new HttpClient();
    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response.pipe(new File(path).openWrite());
    });*/

    var response = await http.post(url, body: json.encode(data));
    int totalbytes = response.contentLength;
    print("response $totalbytes");
    if (totalbytes > 10000) {
      await new File(path).writeAsBytes(response.bodyBytes, flush: true);
      setState(() {
        message = "Descargado exitoso: $totalbytes bytes";
      });
    } else {
      setState(() {
        message = "Fallido no hay copias de esta empresa: $totalbytes bytes";
      });
    }

    setLocal("idempresa", idempresa);
    setLocal("empresa", empresa);

    Navigator.push(
        this.context, MaterialPageRoute(builder: (context) => inicio()));
    /*var db = await openDatabase(
      path,
      readOnly: false,
    );*/
  }
}

class crearEmpresa extends StatefulWidget {
  @override
  _crearEmpresaState createState() => _crearEmpresaState();
}

class _crearEmpresaState extends State<crearEmpresa> {
  bool visible = false;
  final txtnombre = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro de empresa"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          alignment: Alignment.centerLeft,
          color: Colors.grey.withOpacity(0.1),
          padding: EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nueva empresa",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 20),
                ),
              ),
              Divider(
                color: Colors.black26.withOpacity(0.0),
                height: 8,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Escriba el nuevo nombre, se usuara para guardar y descargar copias.",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ),
              Divider(color: Colors.black26.withOpacity(0.0)),
              Container(
                child: TextField(
                  controller: txtnombre,
                  decoration: InputDecoration(labelText: "Nombre empresa"),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: Visibility(
                    visible: visible,
                    child: Container(
                        margin: EdgeInsets.only(bottom: 30, top: 30),
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ))),
              ),
              Divider(
                color: Colors.black26.withOpacity(0.0),
                height: 8,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: OutlineButton.icon(
                  icon: Icon(Icons.save),
                  label: Text("Guardar"),
                  onPressed: () {
                    registrar();
                  },
                  textColor: Colors.green,
                  borderSide: BorderSide(
                    color: Colors.green,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future registrar() async {
    String name = txtnombre.text.trim();
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");

    if (name.length == 0) {
      dialogSimple(this.context, "Faltan datos! por favor complete el nombre ");
      return;
    }

    setState(() {
      visible = true;
    });

    String url = baseurl + 'crearempresa.php';

    var data = {
      "iduser": iduser,
      "token": token,
      "nombre": name,
    };
    var response = await http.post(url, body: json.encode(data));

    try {
      var estado = response.statusCode;
      if (estado == 200) {
        setState(() {
          visible = false;
          txtnombre.clear();
        });
        var json = jsonDecode(response.body);
        var item = json[0];
        print("item ${item}");
        String code = item['code'];
        String nivel = item['nivel'];
        String mensaje = item['msj'];
        //String email = item['email'];
        String nombre = item['nombre'];
        String iduser = item['iduser'];

        if (code == 10) {
          dialogSimple(this.context, "Exitoso: $mensaje");
        } else {
          dialogSimple(this.context, "Respuesta: $mensaje");
          //Navigator.push(this.context, MaterialPageRoute(builder: (context) => inico()));
        }
      } else {
        dialogCupertino(
            this.context, "Sin respuesta", "No hay respuesta del servidor ");
      }
    } catch (e) {
      print("error $e");
    }
  }
}

class micuenta extends StatefulWidget {
  @override
  _micuentaState createState() => _micuentaState();
}

class _micuentaState extends State<micuenta> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool visible = true;
  String correo = "";
  String nombre = "";
  String plan = "";
  String dias = "";
  String id = "";

  @override
  void initState() {
    validarusuario();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Mi cuenta"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Card(
              margin: EdgeInsets.all(10),
              child: Container(
                width: screenWidth(context),
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                width: 60,
                                alignment: Alignment.topLeft,
                                child: Text("Correo:",style: TextStyle(fontWeight: FontWeight.bold),)),
                            Container(
                                width: 60,
                                alignment: Alignment.topLeft,
                                child: Text("Nombre:",style: TextStyle(fontWeight: FontWeight.bold),)),
                            Container(
                                width: 60,
                                alignment: Alignment.topLeft,
                                child: Text("Plan:",style: TextStyle(fontWeight: FontWeight.bold),)),
                            Container(
                                width: 60,
                                alignment: Alignment.topLeft,
                                child: Text("Dias:",style: TextStyle(fontWeight: FontWeight.bold),)),
                            Container(
                                width: 60,
                                alignment: Alignment.topLeft,
                                child: Text("Id:",style: TextStyle(fontWeight: FontWeight.bold),)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Visibility(
                                visible: visible,
                                child: Container(
                                    width: 20,
                                    height: 20,
                                    margin: EdgeInsets.only(left: 20, top: 0),
                                    padding: EdgeInsets.all(2),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ))),
                            Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(correo)),
                            Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(nombre)),
                            Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(plan)),
                            Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(dias)),
                            Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(id,style: TextStyle(fontSize: 10),)),
                          ],
                        ),
                      ],
                    )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future validarusuario() async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || iduser == '_') {
      //snackBar( "No hay usuario validado", 5);
      return;
    }

    setState(() {
      visible = true;
    });

    String url = baseurl+'validartoken.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    var resp = jsonDecode(response.body);
    var item = resp[0];
    print('respuesta $item');
    String code = item['code'];
    String nivel = item['nivel'];
    String mensaje = item['msj'];
    String email = item['email'];
    String name = item['nombre'];
    //String iduser = item['iduser'];
    String licencia = item['licencia'];
    String dias1 = item['dias'];

    String pla = "Gratis";
    if(licencia == "2"){
      pla = "Plata";
    }else if(licencia == "3"){
      pla = "Bronce";
    }else if(licencia == "4"){
      pla = "ORO";
    }

    setState(() {
      visible = false;
      correo = email;
      nombre = name;
      plan = pla;
      dias = dias1;
      id = iduser;
    });

    if (code == "10") {
      setLocal("token",token);
      setLocal("iduser", iduser);
      setLocal("email", email);
      setLocal("nombre", name);
      setLocal("licencia", licencia);
      setLocal("dias", dias);

    } else {
      snackBar(this.context, mensaje, 5);
    }

  }

  snackBar(BuildContext context,String mensaje,int segundos){
      final snackBar = SnackBar(content: Text(mensaje));
      _scaffoldKey.currentState.showSnackBar(snackBar);
  }

}

class subirCopia extends StatefulWidget {
  @override
  _subirCopiaState createState() => _subirCopiaState();
}

class _subirCopiaState extends State<subirCopia> {
  bool visible = false;
  String message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Subir copia"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              alignment: Alignment.topLeft,
              child: Text(
                "Subir copia",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              alignment: Alignment.topLeft,
              child: Text(
                "Suba copia cuando haga cambios y quiera descargarlos en el computador de trabajo.",
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 20),
              alignment: Alignment.center,
              child: Visibility(
                  visible: visible,
                  child: Row(
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(
                            left: 5,
                            bottom: 5,
                            top: 5,
                          ),
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          )),
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Text(message),
                      )
                    ],
                  )),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              alignment: Alignment.topLeft,
              child: OutlineButton(
                onPressed: () {
                  subir();
                },
                child: Text("Subir copia"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void subir() async {
    setState(() {
      message = "Enviando datos";
    });

    File file;
    String idruta = await getLocal("idruta");
    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String url = baseurl + "subircopia.php";

    print("idempresa. $idruta token: $token iduser: $iduser");

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "admin.db");
    var exists = await databaseExists(path);
    if (exists) {
      file = File(path);
    } else {
      print("no existe el archivo ");
      setState(() {
        message = "No hay base de datos para subir";
      });
      return;
    }

    String base64Image = base64Encode(file.readAsBytesSync());
    String fileName = "admin.db"; //file.path.split("/").last;

    http.post(url, body: {
      "file": base64Image,
      "nombre": fileName,
      "idruta": idruta,
      "token": token,
      "iduser": iduser,
    }).then((res) {
      print("code: ${res.statusCode}");
      int status = res.statusCode;
      print("res: ${res.body}");
      if (status == 200) {
        var json = jsonDecode(res.body);
        var item = json[0];
        //print("json: ${json.length} item: $item");
        var code = item['code'];
        var msj = item['msj'];
        //print("item: $msj code $code");
        setState(() {
          visible = false;
          message = " $msj";
          //snackBar(this.context, msj, 5);
        });
      }
    }).catchError((err) {
      print("error: ${err.toString()}");
      setState(() {
        setState(() {
          //visible = false;
          message = "Error: ${err.toString()}";
        });
      });
    });
  }
}

class caja extends StatefulWidget {
  @override
  _cajaState createState() => _cajaState();
}

class _cajaState extends State<caja> {
  final txtcaja = TextEditingController();
  String caja;
  String message;
  Color color;
  bool restar;

  Future<void> getCaja() async {
    String caj = await cajaActual();
    setState(() {
      caja = caj;
    });
  }

  @override
  void initState() {
    caja = "0.0";
    message = "";
    color = Colors.blueGrey;
    restar = false;
    this.getCaja();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Caja"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Ajustes de la caja",
                  style: TextStyle(fontSize: 25, color: Colors.blueAccent),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.only(top: 20),
                child: Row(
                  children: <Widget>[
                    Container(
                        child: Text("Caja actual:",
                            style: TextStyle(fontSize: 20))),
                    Container(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          caja,
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.only(top: 20),
                child: TextField(
                  controller: txtcaja,
                  decoration: InputDecoration(
                    labelText: "Caja",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(0),
                child: CheckboxListTile(
                  onChanged: (value) {
                    setState(() {
                      restar = !restar;
                    });
                  },
                  title: Text("Restar a la caja"),
                  value: restar,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text(
                  message,
                  style: TextStyle(color: color),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                child: OutlineButton(
                  onPressed: () {
                    guardarcaja();
                  },
                  child: Text("Registrar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> guardarcaja() async {
    if (txtcaja.text.length <= 0) {
      setState(() {
        message = "Escriba un valor para sumar o restar";
        color = Colors.red;
      });
      return;
    }

    String accion = "Sumado";
    String fecha = fechaActual();
    String hora = horaActual();
    double agregar = double.parse(txtcaja.text);
    double caj = double.parse(caja);
    double total = 0;
    if (restar) {
      total = caj - agregar;
      accion = "Restado";
    } else {
      total = caj + agregar;
    }

    if (total < 0) {
      total = 0;
    }
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM caja');
    //list.forEach((row) => print(row));
    if (list.length > 0) {
      int count = await database.rawUpdate(
          'UPDATE caja SET caja = ?, fecha = ? WHERE id = ?',
          [total.toStringAsFixed(2), fecha, "1"]);
      //print('Actualizado caja exitoso: ');
      setState(() {
        message = " $accion exitoso";
        color = Colors.green;
        caja = total.toStringAsFixed(2);
      });
    } else {
      await database.transaction((txn) async {
        int id1 = await txn.rawInsert(
            'INSERT INTO caja(caja, fecha, hora) VALUES(?,?,?)',
            [total.toStringAsFixed(2), fecha, hora]);
      });
      setState(() {
        message = " $accion exitoso";
        color = Colors.blue;
        caja = total.toStringAsFixed(2);
      });
    }
    database.close();
  }
}

class Empleado {
  String id;
  String nombre;
  String codigo;

  Empleado({this.id, this.nombre, this.codigo});

  static List<Empleado> getEmpleados() {
    return <Empleado>[
      //Empleado(id: "0",codigo: "0",nombre: "Sin empleados"),
    ];
  }
}

class empleadosDesig extends StatefulWidget {
  @override
  _empleadosDesigState createState() => _empleadosDesigState();
}

class _empleadosDesigState extends State<empleadosDesig> {
  final _resumeDetectorKey = UniqueKey();
  List<Empleado> empleados;
  List<Empleado> selectedEmpleados;
  bool sort;

  Future<List<Empleado>> Recibir() async {
    var response = await getEmpleados();
    setState(() {
      empleados = response;
    });
  }

  @override
  void initState() {
    sort = false;
    selectedEmpleados = [];
    empleados = Empleado.getEmpleados();
    this.Recibir();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Administracion de empleados"),
      ),
      body: Container(
        child: FocusDetector(
          key: _resumeDetectorKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              Expanded(
                child: dataBody(),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 20, bottom: 20),
                      child: OutlineButton(
                        child: Text('SELECT ${selectedEmpleados.length}'),
                        onPressed: () {},
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20, bottom: 20),
                      child: OutlineButton(
                        child: Text(
                          'BORRAR ${selectedEmpleados.length}',
                          style: TextStyle(
                              color: selectedEmpleados.isEmpty
                                  ? null
                                  : Colors.red),
                        ),
                        onPressed: selectedEmpleados.isEmpty
                            ? null
                            : () {
                                deleteSelected();
                              },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20, bottom: 20),
                      child: OutlineButton(
                        child: Text(
                          'AGREGAR ',
                          style: TextStyle(color: Colors.green),
                        ),
                        onPressed: () {
                          Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                  builder: (context) => agregarempleados()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onFocusGained: () {
            //print('onFocuss');
            //sRecibir();
          },
        ),
      ),
    );
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (ascending) {
        empleados.sort((a, b) => a.nombre.compareTo(b.nombre));
      } else {
        empleados.sort((a, b) => b.nombre.compareTo(a.nombre));
      }
    }
  }

  onSelectedRow(bool selected, Empleado empleado) async {
    setState(() {
      if (selected) {
        selectedEmpleados.add(empleado);
      } else {
        selectedEmpleados.remove(empleado);
      }
    });
  }

  deleteSelected() async {
    Database database = await opendb();
    if (selectedEmpleados.isNotEmpty) {
      List<Empleado> temp = [];
      temp.addAll(selectedEmpleados);
      for (Empleado empleado in temp) {
        await database
            .rawDelete('DELETE FROM empleados WHERE id = ?', [empleado.id]);
        print("borrado: ${empleado.nombre} id: ${empleado.id}");
      }
    }
    database.close();

    setState(() {
      if (selectedEmpleados.isNotEmpty) {
        List<Empleado> temp = [];
        temp.addAll(selectedEmpleados);
        for (Empleado empleado in temp) {
          empleados.remove(empleado);
          selectedEmpleados.remove(empleado);
          //print("borrado: ${empleado.nombre} id: ${empleado.id}");
        }
      }
    });
  }

  SingleChildScrollView dataBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        sortAscending: sort,
        sortColumnIndex: 0,
        columns: [
          DataColumn(
              label: Text("NOMBRE"),
              numeric: false,
              onSort: (columnIndex, ascending) {
                setState(() {
                  sort = !sort;
                });
                onSortColum(columnIndex, ascending);
              }),
          DataColumn(
            label: Text("CODIGO"),
            numeric: false,
          ),
        ],
        rows: empleados
            .map(
              (emplead) => DataRow(
                  selected: selectedEmpleados.contains(emplead),
                  onSelectChanged: (b) {
                    print("Onselect");
                    onSelectedRow(b, emplead);
                  },
                  cells: [
                    DataCell(
                      Text(emplead.nombre),
                    ),
                    DataCell(
                      Text(emplead.codigo),
                    ),
                  ]),
            )
            .toList(),
      ),
    );
  }

  Future<List<Empleado>> getEmpleados() async {
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM empleados');
    await database.close();

    List<Empleado> lista = new List();

    if (list.length > 0) {
      list.forEach((row) {
        int id = row['id'];
        String nombre = row['nombre'];
        String codigo = row['codigo'];

        print('empleadosDesig getEmpleados(): $row');

        lista.add(Empleado(id: id.toString(), nombre: nombre, codigo: codigo));
      });
    }

    return lista;
  }

  void _settingModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(20),
                  child: TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Nombre empleado"),
                  ),
                )
              ],
            ),
          );
        });
  }
}

class agregarempleados extends StatefulWidget {
  @override
  _agregarempleadosState createState() => _agregarempleadosState();
}

class _agregarempleadosState extends State<agregarempleados> {
  String smjmodal = "";
  Color color = Colors.blueGrey;
  final txtnombre = TextEditingController();
  final txtcodigo = TextEditingController();
  final txtcc = TextEditingController();

  @override
  void initState() {
    txtnombre.addListener(_printLatestValue);
    super.initState();
  }

  @override
  void dispose() {
    txtnombre.removeListener(_printLatestValue);
    txtnombre.dispose();
    txtcodigo.dispose();
    txtcc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar empleados"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              width: screenWidth(context),
              padding: EdgeInsets.only(left: 20, top: 20, right: 20),
              child: Text(
                  "Registre empleados para que accedan al sistema en el computador con el codigo."),
            ),
            Container(
              width: screenWidth(context),
              padding: EdgeInsets.only(left: 20, top: 20, right: 20),
              child: TextField(
                controller: txtnombre,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Nombre empleado"),
              ),
            ),
            Container(
              width: screenWidth(context),
              padding: EdgeInsets.only(left: 20, top: 8, right: 20),
              child: TextField(
                controller: txtcodigo,
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Codigo empleado"),
              ),
            ),
            Container(
              width: screenWidth(context),
              padding: EdgeInsets.only(left: 20, top: 8, right: 20),
              child: TextField(
                controller: txtcc,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Identificacion empleado"),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 20, top: 5, right: 20),
              alignment: Alignment.topLeft,
              child: Text(
                smjmodal,
                style: TextStyle(color: color),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OutlineButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancelar"),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  OutlineButton(
                    onPressed: () {
                      guardar();
                    },
                    child: Text("Guardar empleado"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void guardar() async {
    String nombre = txtnombre.text;
    String codigo = txtcodigo.text;
    String cedula = txtcc.text;

    if (nombre.length == 0 || codigo.length == 0 || cedula.length == 0) {
      setState(() {
        smjmodal = "Complete todos los campos";
        color = Colors.orange;
      });
      return;
    }

    print("registrando...");

    Database database = await opendb();
    await database.transaction((txn) async {
      int id2 = await txn.rawInsert(
          'INSERT INTO empleados(codigo, creado, nombre,documento,nivel,ingreso) VALUES(?, ?, ?, ?, ?, ?)',
          [codigo, fechaActual(), nombre, cedula, "empleado", fechaActual()]);
    });

    print("registrado");

    setState(() {
      smjmodal = "Registro exitoso";
      color = Colors.green;
    });
  }

  _printLatestValue() {
    print("Second text field: ${txtnombre.text}");
  }
}
