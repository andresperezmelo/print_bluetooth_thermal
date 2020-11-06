import 'package:flutter/material.dart';
import 'package:prestagroons/php/meTodo.dart';
import 'package:prestagroons/php/Inicio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:focus_detector/focus_detector.dart';

void main() => runApp(MyApp());

var baseurl = getUrlServer();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[900],
        accentColor: Colors.cyan[600],
      ),
      home: Scaffold(
          appBar: AppBar(
            title: Text("FarmaGroonS"),
          ),
          body: sesion()),
    );
  }
}

class sesion extends StatefulWidget {
  @override
  _sesionState createState() => _sesionState();
}

class _sesionState extends State<sesion> {

   final _resumedetectorkey = UniqueKey();
  String message = "";
  bool visible = false;
  final txtcorreo = TextEditingController();
  final txtpass = TextEditingController();

  @override
  void initState() {
    validarusuario();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      key: _resumedetectorkey,
      child: Container(
          margin: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: <Widget>[
                  Divider(),
                  Text(
                    "Inicio sesion",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 25,
                    ),
                  ),
                  Visibility(
                      visible: visible,
                      child: Container(
                          width: 20,
                          height: 20,
                          margin: EdgeInsets.only(bottom: 30, top: 30),
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: TextField(
                      controller: txtcorreo,
                      autocorrect: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Correo",
                        icon: Icon(Icons.email),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: TextField(
                      controller: txtpass,
                      autocorrect: true,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Contraseña",
                        icon: Icon(Icons.vpn_key),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(10),
                    child: Text(message,style: TextStyle(fontSize: 12,color: Colors.blueGrey),),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.fromLTRB(40, 10, 0, 0),
                        child: OutlineButton(
                          child: Text("Ingresar"),
                          onPressed: () {
                            ingresar();
                          },
                          textColor: Colors.green,
                          borderSide: BorderSide(
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(20, 10, 0, 0),
                        child: OutlineButton(
                          child: Text("Registrarse"),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => registrar()));
                          },
                          textColor: Colors.blue,
                          borderSide: BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )),
      onFocusGained: (){
        validarusuario();
      },
    );
  }

  Future ingresar() async {
    String email = txtcorreo.text.trim();
    String password = txtpass.text;

    if (email.length == 0) {
      snackBar(this.context, "Escriba el correo por favor", 5);
      return;
    }
    if (password.length == 0) {
      snackBar(this.context, "Escriba la contraseña por favor", 5);
      return;
    }

    setState(() {
      message = "validando usuario";
      visible = true;
    });

    String url = baseurl+'login.php';

    var data = {"email": email, "password": password};
    var response = await http.post(url, body: json.encode(data));

    print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    var item = resp[0];
    print('respuesta $item');
    String code = item['code'];
    String nivel = item['nivel'];
    String mensaje = item['msj'];
    //String email = item['email'];
    String nombre = item['nombre'];
    String iduser = item['iduser'];
    String token = item['token'];

    setState(() {
      message = mensaje;
      visible = false;
    });

    if (code == "10") {

      setLocal("token",token);
      setLocal("iduser", iduser);
      setLocal("email", email);
      setLocal("nombre", nombre);

      final snackBar = new SnackBar(
        content: new Text(mensaje),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: "Limpiar ",
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              txtcorreo.clear();
              txtpass.clear();
            });
          },
        ),
      );
      Scaffold.of(this.context).showSnackBar(snackBar);
      validarusuario();
    } else {
      snackBar(this.context, mensaje, 5);
    }
  }

  Future validarusuario() async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || iduser == '_') {
      snackBar(this.context, "No hay usuario validado", 5);
      return;
    }

    setState(() {
      message = "validando sesion";
      visible = true;
    });

    String url = baseurl+'validartoken.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    var item = resp[0];
    print('respuesta $item');
    String code = item['code'];
    String nivel = item['nivel'];
    String mensaje = item['msj'];
    String email = item['email'];
    String nombre = item['nombre'];
    //String iduser = item['iduser'];
    String licencia = item['licencia'];
    String dias = item['dias'];

    setState(() {
      message = mensaje;
      visible = false;
    });

    if (code == "10") {
      setLocal("token",token);
      setLocal("iduser", iduser);
      setLocal("email", email);
      setLocal("nombre", nombre);
      setLocal("licencia", licencia);
      setLocal("dias", dias);
      if(nivel=="admin") {
        Navigator.push(this.context, MaterialPageRoute(builder: (context) => inicio()));
      }else{
        snackBar(this.context, "Su cuenta debe ser administrador", 10);
      }
    } else {
      snackBar(this.context, mensaje, 5);
    }

  }

}

class registro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.lightBlue[900],
        accentColor: Colors.cyan[600],
      ),
      home: Scaffold(
          appBar: AppBar(
            title: Text("FarmaGroonS"),
          ),
          body: registrar()),
    );
  }
}

class registrar extends StatefulWidget {
  @override
  _registrarState createState() => _registrarState();
}

class _registrarState extends State<registrar> {
  bool visible = false;
  bool check = false;
  final txtnombre = TextEditingController();
  final txtcorreo = TextEditingController();
  final txtpass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro"),),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Divider(),
                Text("Registro de usuarios",style: TextStyle(fontSize: 25,color: Colors.blue),),
                Divider(height: 30,color: Colors.white,),
                Container(
                  child: TextField(
                    controller: txtnombre,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Nombre",
                    ),
                  ),
                ),
                Divider(height: 10,color: Colors.white,),
                Container(
                  child: TextField(
                    controller: txtcorreo,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Correo",
                    ),
                  ),
                ),
                Divider(height: 10,color: Colors.white,),
                Container(
                  child: TextField(
                    controller: txtpass,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Contraseña",
                    ),
                  ),
                ),
                Divider(height: 10,color: Colors.white,),
                Container(
                  child: Center()
                ),
                Visibility(
                    visible: visible,
                    child: Container(
                        width: 20,
                        height: 20,
                        margin: EdgeInsets.only(bottom: 30, top: 30),
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ))),
                Divider(height: 10,color: Colors.white,),
                Container(
                  child: CheckboxListTile(
                    title: Text("Acepto las politicas y condiciones"),
                    value: check,
                    activeColor: Colors.blue,
                    onChanged: (bool value){
                      setState(() {
                        check = value;
                      });
                    },
                  )
                ),
                Container(
                  child: Text("Para ver las polticas visite groons.web.app/politicas.html",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),),
                ),
                Container(
                  child: OutlineButton(
                    child: Text("Registrarme"),
                    onPressed: () {
                      registrar();
                    },
                    textColor: Colors.indigo,
                    borderSide: BorderSide(
                      color: Colors.indigo,
                    ),
                  ),
                ),
                Divider(height: 30,color: Colors.white,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future registrar() async {

    String name = txtnombre.text;
    String email = txtcorreo.text;
    String password = txtpass.text;

    if (name.length == 0 || email.length == 0 || password.length == 0) {
      dialogCupertino(this.context, "Faltan datos", "Por favor complete los datos ");
      return;
    }

    if(check==false){
      dialogCupertino(this.context, "Acepte las politicas", "Si no acepta nuestras polticas por favor no use nuestro software ");
      return;
    }

    setState(() {
      visible = true;
    });

    String url = baseurl+'crearusuario.php';

    var data = {
      "email": email,
      "password": password,
      "nombre": name,
      "nivel": "admin"
    };
    var response = await http.post(url, body: json.encode(data));

    try {
      var estado = response.statusCode;
      if (estado == 200) {
        setState(() {
          visible = false;
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

        if(code==10){
          dialogCupertino(this.context, "Exitoso", mensaje);
        }else{
          dialogCupertino(this.context, "Respuesta", mensaje);
          //Navigator.push(this.context, MaterialPageRoute(builder: (context) => inico()));
        }
      } else {
        dialogCupertino(this.context, "Sin respuesta", "No hay respuesta del servidor ");
      }
    } catch (e) {
      print("error $e");
    }
  }

}




