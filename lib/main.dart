import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prestagroons/Tienda.dart';
import 'package:prestagroons/meTodo.dart';
import 'package:prestagroons/Ajustes.dart';
import 'package:prestagroons/Balances.dart';
import 'package:prestagroons/Clientes.dart';
import 'package:prestagroons/ResumenDia.dart';
import 'package:prestagroons/ListaClientes.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

var baseurl = getUrlServer();
String ruta = null;
Map user = {"code":"0","nivel":"","msj":"","email":"","idadmin" :"no", "idruta" : "no","nombre":"","iduser":"","licencia":"2","diaspagos":"30","registro":"2020-09-28","fechapago":"2020-09-28","token":""};
String licenciaGlobal = "1";
String versionApp = "1.2.5";
String nombreempresa = "";
String telefonoempresa = "";

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]); //SystemUiOverlay.bottom
    WidgetsFlutterBinding.ensureInitialized();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PrestaGroonS',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colores.primario,//Colors.blueGrey[900],
        accentColor: Colores.secundario,//Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: InicioSesion(),
    );
  }
}

class InicioSesion extends StatefulWidget {
  @override
  _InicioSesionState createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {

  bool _passwordVisible = false;
  final txtcorreo = TextEditingController();
  final txtpass = TextEditingController();
  String msj = "";
  bool visiblemsj = false;

  @override
  void initState() {
    validarusuario();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  elevation: 5,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: Image.asset("assets/logo.png"),
                        ),
                        SizedBox(height: 10),
                        Text("Usuario y contraseña",style: TextStyle(color: Theme.of(context).primaryColorDark),),
                        TextField(
                          controller: txtcorreo,
                          decoration: InputDecoration(
                            labelText: "Correo",
                          ),
                        ),
                        TextFormField(
                          controller: txtpass,
                          keyboardType: TextInputType.text,
                          obscureText: !_passwordVisible,//This will obscure text dynamically
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            // Here is key idea
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).primaryColorDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: visiblemsj,
                          child: ListTile(
                          title: Text(msj),
                          leading: SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2,),),
                        ),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlineButton(
                              onPressed: (){
                                this.ingresar();
                              },
                              child: Text("Ingresar"),
                            ),
                            FlatButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>RegistrarUsuario()));
                              },
                              child: Text("Crear cuenta",style: TextStyle(color: Colores.primario),),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              FlatButton(
                onPressed: ()async{
                  String url = "https://groonsayuda.blogspot.com/";
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text("Ayuda en nuestro blog"),
              ),
              FlatButton(
                onPressed: ()async{
                  String url = "https://chat.whatsapp.com/DbFtyzAFOXiEho0nMjB0KN";
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text("Unete a nuestro grupo de WhatsApp"),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text("Esta aplicacion esta en modo beta, usela con precaucion.",style: TextStyle(fontSize: 10,color: Colors.blue),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future ingresar() async {

    try {
      String email = txtcorreo.text.trim();
      String password = txtpass.text;

      if (email.length == 0) {
        Flushbar(message: "Escriba el correo", duration: Duration(seconds: 3),)
            .show(context);
        return;
      }
      if (password.length == 0) {
        Flushbar(
          message: "Escriba la contraseña", duration: Duration(seconds: 3),)
            .show(context);
        return;
      }

      setState(() {
        msj = "Validando usuario";
        visiblemsj = true;
      });

      String url = baseurl + 'login.php';
      //print("enviando dato s a $url");

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

      print("token: $token");
      setState(() {
        msj = mensaje;
        visiblemsj = false;
      });

      if (code == "10") {
        String iduseractual = await getLocal("iduser");
        if(iduseractual!=iduser){
          //await setLocal("iduser", "no");
          await setLocal("ruta", "no");
          await setLocal("idruta", "no");
          //await setLocal("token", "no");
          await borrarDB();
          print("db borrada por que cambio el iduser");
        }
        //print("idactual $iduseractual idusernuevo $iduser");
        await setLocal("token", token);
        await setLocal("iduser", iduser);
        await setLocal("modo", nivel);
        //await setLocal("idadmin", currentUser.uid);

        Flushbar(message: "$mensaje", duration: Duration(seconds: 5),).show(context);
        validarusuario();
      } else {
        Flushbar(message: "$mensaje", duration: Duration(seconds: 5),).show(context);
      }
    }catch(e){
      setState(() {
        msj = "Error al ingresar verifique la red: ";
      });
    }
  }

  Future validarusuario() async{

    //Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboard()));

    try {
      String token = await getLocal("token");
      String iduser = await getLocal("iduser");

      if (token == '_' || token == "no" || iduser == '_' || iduser == "no") {
        Flushbar(
          message: "No hay usuario validado", duration: Duration(seconds: 5),)
            .show(context);
        return;
      }

      setState(() {
        msj = "Validando sesion";
        visiblemsj = true;
      });

      String url = baseurl + 'validartoken.php';

      var data = {"iduser": iduser, "token": token};

      var response = await http.post(url, body: json.encode(data));

      print("resp: ${response.body}");
      var resp = jsonDecode(response.body);
      Map item = resp[0];
      user = item;
      //print('respuesta $item');
      String code = item['code'];
      String nivel = item['nivel'];
      String mensaje = item['msj'];
      String email = item['email'];
      String nombre = item['nombre'];
      //String iduser = item['iduser'];
      String licencia = item['licencia'];
      String diaspagos = item['diaspagos'];

      setState(() {
        msj = mensaje;
        visiblemsj = false;
      });

      if (code == "10") {
        if (nivel == "admin") {

          Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboard()));
        } else {
          Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboardcobrador()));
          //Flushbar(message: "Cuenta de cobrador",duration: Duration(seconds: 5),).show(context);
        }
      } else {
        Flushbar(message: "$mensaje", duration: Duration(seconds: 5),).show(context);
      }
    }catch(e){
      setState(() {
        msj = "Error al validar: ";
      });
    }

  }

}

class RegistrarUsuario extends StatefulWidget {
  @override
  _RegistrarUsuarioState createState() => _RegistrarUsuarioState();
}

class _RegistrarUsuarioState extends State<RegistrarUsuario> {

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
        scrollDirection: Axis.vertical,
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Text("Registro de usuarios",style: TextStyle(fontSize: 25,color: Colors.blue),),
                SizedBox(height: 20,),
                TextField(
                  controller: txtnombre,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Nombre",
                  ),
                ),
                SizedBox(height: 10,),
                TextField(
                  controller: txtcorreo,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Correo",
                  ),
                ),
                SizedBox(height: 10,),
                TextField(
                  controller: txtpass,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Contraseña",
                  ),
                ),
                SizedBox(height: 10,),
                Text("Para ver las polticas visite groons.web.app/politicas.html",
                  style: TextStyle(
                    color: Colores.secundario,
                    fontSize: 12,
                  ),),
                CheckboxListTile(
                  title: Text("Acepto las politicas y condiciones"),
                  value: check,
                  activeColor: Colors.blue,
                  onChanged: (bool value){
                    setState(() {
                      check = value;
                    });
                  },
                ),
                SizedBox(height: 20,),
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
                OutlineButton(
                  child: Text("Registrarme"),
                  onPressed: () {
                    registrar();
                  },
                  textColor: Colors.indigo,
                  borderSide: BorderSide(
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future registrar() async {

    String name = txtnombre.text.trim();
    String email = txtcorreo.text.trim();
    String password = txtpass.text;

    if (name.length == 0 || email.length == 0 || password.length == 0) {
      Flushbar(message: "Complete los datos",duration: Duration(seconds: 3),).show(context);
      return;
    }
    //var email = "tony@starkindustries.com"
    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

    if(emailValid==false){
      Flushbar(message: "Correo $email invalido",duration: Duration(seconds: 3),).show(context);
      return;
    }

    if(password.length<=5){
      Flushbar(message: "La contraseña debe tener mas de 5 caracteres",duration: Duration(seconds: 3),).show(context);
      return;
    }


    if(check==false){
      Flushbar(message: "Si no acepta nuestras polticas no puede usar nuestro software",duration: Duration(seconds: 3),).show(context);
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
      "nivel": "admin",
      "idruta": "no",
      "idadmin": "no",
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
          Flushbar(message: "Registro exitoso",duration: Duration(seconds: 3),).show(context);
        }else{
          Flushbar(message: "$mensaje",duration: Duration(seconds: 3),).show(context);
          //Navigator.push(this.context, MaterialPageRoute(builder: (context) => inico()));
        }
      } else {
        Flushbar(message: "No hay respuesta del servidor",duration: Duration(seconds: 3),).show(context);
      }
    } catch (e) {
      print("error $e");
    }
  }


}


class dasboard extends StatefulWidget {
  @override
  _dasboardState createState() => _dasboardState();
}

class _dasboardState extends State<dasboard> with WidgetsBindingObserver {

  final _resumeDetectorKey = UniqueKey();
  int totalclientes = 0;

  List<FlSpot> listaganancia = [FlSpot(1, 0),];
  double promediodinero = 0;

  List<Map> tienda = new List();
  Map datosLicencia = {"plan":"GRATIS","dias":"0"};
  Map mensajeFinal = {"titulo": "Ola", "mensaje": "Cuerpo del mensaje", "obligatorio": "no","url": "http","version": "no","textoboton":""};
  bool visiblemensaje = false;

  cargardatosDasboart()async{
    int clientes = await getTotalClientes();
    totalclientes = clientes;
    await this.rutaSeleccionada();
    await this.getMensaje();
    await setCopiaLocal();
    await this.getDatosLicencia();
    await this.cargarGanancia();
    if (this.mounted) { // check whether the state object is in tree
      setState(() {
        totalclientes = clientes;
      });
    }
    //pasar foto a memoria local
    Uint8List byteshay = await getBytesFotos("logo");
    bool existelogo = byteshay==null?false:true;
    if(existelogo) {
      Directory ruta = await getExternalStorageDirectory();
      String path = ruta.path + "/logo.png";
      await new File(path).writeAsBytes(byteshay, flush: true);
      print("logo copiado $path");
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    this.cargardatosDasboart();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //print("estado: $state");
    if(state == AppLifecycleState.resumed){
      print("Usuario devuelta a nuestra aplicación");
      await this.cargarGanancia();
    }else if(state == AppLifecycleState.inactive){
      print("la aplicación está inactiva");
    }else if(state == AppLifecycleState.paused){
      print("el usuario está a punto de salir de nuestra aplicación temporalmente");
    }else if(state == AppLifecycleState.detached){
      print("separado");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PrestaGroonS',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colores.primario,//Colors.blueGrey[900],
        accentColor: Colores.secundario,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: FocusDetector(
          key: _resumeDetectorKey,
          child: Container(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: visiblemensaje,
                    child: Container(
                      color: Colores.secundario,
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${mensajeFinal['titulo']}",style: TextStyle(fontSize: 18),),
                          Text("${mensajeFinal['mensaje']}"),
                          OutlineButton(
                            onPressed: (){
                              irActualizar(mensajeFinal['url']);
                            },
                            child: Text("${mensajeFinal['textoboton']}"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    child: Column(
                      children: <Widget>[
                        ClipPath(
                          clipper: CurvedBottomClipper(),
                          child: Container(
                            color: Colores.primario,
                            padding: EdgeInsets.all(20),
                            height: 250.0,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("PLAN ${datosLicencia['plan']} ${datosLicencia['dias']} DIAS RESTANTES",style: TextStyle(color: Colors.white,fontSize: 12),),
                                    IconButton(onPressed: (){dialogCuenta();},icon: Icon(Icons.account_circle),color: Colores.secundario,)
                                  ],
                                ),
                                SizedBox(height: 20,),
                                Text("${user['email']}",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),
                                SizedBox(height: 10,),
                                Text("${user['nombre']}",style: TextStyle(color: Colores.secundario,fontSize: 12,),),
                                SizedBox(
                                  height: 20,
                                ),
                                ruta==null ? Container():Text("$ruta",style: TextStyle(color: Colores.secundario,fontSize: 25,fontWeight: FontWeight.bold),),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Material(
                                color: Colores.verdemuyclaro,
                                elevation: 20,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Informacion de cartera",style: TextStyle(color: Colores.moradoclaro),),
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: <Widget>[
                                            Text("$totalclientes ",style: TextStyle(color: Colores.moradoclaro,fontSize: 35,fontWeight: FontWeight.bold),),
                                            Text("clientes",style: TextStyle(color: Colores.moradoclaro,fontSize: 12,),),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            InkWell(
                                              onTap: (){
                                                clientes();
                                              },
                                              child: Container(
                                                child: Text("Clientes",style: TextStyle(color: Colors.white),),
                                                padding: EdgeInsets.only(left: 30,top: 15,right: 30,bottom: 15),
                                                decoration: BoxDecoration(
                                                  borderRadius: new BorderRadius.circular(30),
                                                  border: Border.all(width: 1, color: Colores.moradoclaro,),
                                                  color: Colores.moradoclaro,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: (){
                                                this.lista();
                                              },
                                              child: Container(
                                                child: Text("Lista",style: TextStyle(color: Colors.white),),
                                                padding: EdgeInsets.only(left: 30,top: 15,right: 30,bottom: 15),
                                                decoration: BoxDecoration(
                                                  borderRadius: new BorderRadius.circular(30),
                                                  border: Border.all(width: 1, color: Colores.moradooscuro,),
                                                  color: Colores.moradooscuro,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40,),
                              Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Container(
                                      width: screenWidth(context)/3,
                                      child: Material(
                                        elevation: 10,
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                        child: InkWell(
                                          onTap: (){
                                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Ajustes()));
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(30.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text("Ajustes",style: TextStyle(color: Colores.azul),),
                                                Icon(Icons.settings,color: Colores.azul,size: 50,),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: screenWidth(context)/3,
                                      child: Material(
                                        elevation: 10,
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                        child: InkWell(
                                          onTap: (){
                                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ResumenDia()));
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(30.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text("Resumen",style: TextStyle(color: Colores.rosadoclaro),),
                                                Icon(Icons.adb,color:Colores.rosadoclaro,size: 50,),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40,),
                              Container(
                                child: InkWell(
                                  onTap: (){
                                    balances();
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      graficaGanancia(),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40,),
                              Material(
                                color: Colores.azulclaro,
                                elevation: 20,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Comprar planes",style: TextStyle(color: Colores.verdeoliva),),
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: <Widget>[
                                            Text("Desde ",style: TextStyle(color: Colores.verdeoliva,fontSize: 12,),),
                                            Text("1 USD ",style: TextStyle(color: Colores.verdeoliva,fontSize: 35,fontWeight: FontWeight.bold),),
                                            Text("por ruta al mes.",style: TextStyle(color: Colores.verdeoliva,fontSize: 12,),),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 10,),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: <Widget>[
                                            InkWell(
                                              onTap: (){
                                                irTienda();
                                              },
                                              child: Container(
                                                child: Text("Ver planes disponibles",style: TextStyle(color: Colors.white),),
                                                padding: EdgeInsets.only(left: 30,top: 15,right: 30,bottom: 15),
                                                decoration: BoxDecoration(
                                                  borderRadius: new BorderRadius.circular(30),
                                                  border: Border.all(width: 1, color: Colores.verdeoliva,),
                                                  color: Colores.verdeoliva,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40,),
                              Text("Todos los derechos reservados GroonS",style: TextStyle(fontSize: 8),),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          onFocusGained: (){
            this.rutaSeleccionada();
          },
        ),
      ),
    );
  }

  void rutaSeleccionada() async {
    String iduser = await getLocal("iduser");
    if(iduser=="_"||iduser=="no"){
      Navigator.push(this.context, MaterialPageRoute(builder: (context) => InicioSesion()));
      return;
    }
    ruta = await getLocal("ruta");
    if (ruta == "_" || ruta == "no") {
      Navigator.push(this.context, MaterialPageRoute(builder: (context) => selecionarRutas()));
    }else{
      //setState(() {});
    }
  }

  void inicio(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Inicio()));
  }

  void ajustes(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Ajustes()));
  }

  void clientes(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>GrupoClientes()));
  }

  void lista(){
    if(licenciaGlobal!="0"&&licenciaGlobal!="1") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ListaClientes()));
    }else{
      Flushbar(title: "ADQUIERE UN PLAN",message: "No disponible sin plan",backgroundColor: Colors.deepPurpleAccent,duration: Duration(seconds: 5),).show(context);
    }
  }

  void resumenDia(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>ResumenDia()));
  }

  void balances()async{
    int balances = await getTotalBalances();
    if(balances>0) {
      if(licenciaGlobal!="0"&&licenciaGlobal!="1") {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MenuBalances()));
      }else{
        Flushbar(title: "ADQUIERE UN PLAN",message: "No disponible sin plan",backgroundColor: Colors.deepPurpleAccent,duration: Duration(seconds: 5),).show(context);
      }
    }else{
      Flushbar(message: "No hay balances sufucientes",backgroundColor: Colors.blue,duration: Duration(seconds: 5),).show(context);
    }
  }

  void irTienda()async{
    Navigator.push(context, MaterialPageRoute(builder: (context) => MenuTienda()));
  }

  void menutienda()async{
    int balances = await getTotalBalances();
    if(balances>0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MenuTienda()));
    }else{
      Flushbar(message: "Todavia no puedes comprar, registra clientes",backgroundColor: Colors.blue,duration: Duration(seconds: 5),).show(context);
    }
  }

  Widget graficaGanancia(){
    return Material(
      elevation: 20,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      color: Color(0xfff2e9e4),
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                Text("Ganancia ultimos 7 dias", style: TextStyle(color: Color(0xff0466c8), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center,),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                    child: LineChart(grafica(),
                      swapAnimationDuration: const Duration(milliseconds: 250),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartData grafica() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(show: false,),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: const TextStyle(color: Color(0xff72719b), fontWeight: FontWeight.bold, fontSize: 7,),
          margin: 10,
          getTitles: (value) {
            //print("value: ${value.toInt()}");
            /*switch (value.toInt()) {
              case 2:
                return 'SEPT';
              case 7:
                return 'OCT';
              case 12:
                return 'DEC';
            }*/
            return '${value.toInt()}';
          },
        ),
        leftTitles: SideTitles(showTitles: true,
          textStyle: const TextStyle(color: Color(0xff75729e), fontWeight: FontWeight.bold, fontSize: 7,),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1000:
                return '1mil';
              case 10000:
                return '10mil';
              case 100000:
                return '100mill';
              case 1000000:
                return '1millon';
              case 10000000:
                return '10millon';
              case 100000000:
                return '100millon';
              case 1000000000:
                return '1000millon';
            }
            return '';
          },
          margin: 8,
          reservedSize: 30,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(
              color: Color(0xff4e4965),
              width: 4
          ),
          left: BorderSide(
            color: Colors.transparent,
          ),
          right: BorderSide(
            color: Colors.transparent,
          ),
          top: BorderSide(
            color: Colors.transparent,
          ),
        ),
      ),
      minX: 1, //minimo derecho
      maxX: 7, //promedio maximo ancho
      maxY: promediodinero, //promedio maximo alto
      minY: 0, //minimo izquierdo
      lineBarsData: datosdelmes(),
    );
  }

  List<LineChartBarData> datosdelmes() {

    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: listaganancia,
      isCurved: true,
      colors: [
        const Color(0xff0466c8),
      ],
      barWidth: 3, //grosor de la linea
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    return [
      lineChartBarData1,
    ];
  }

  void cargarGanancia()async{

    int balances = await getTotalBalances();
    if(balances==0){
      return;
    }
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances ORDER BY id DESC');
    await database.close();

    listaganancia = new List();
    promediodinero = 0;
    int recorrido = 7;

    await Future.forEach(list, (balance){

      if(recorrido>0) {
        double gananc = double.parse(balance['ganancia'].toString());

        listaganancia.add(new FlSpot(recorrido.toDouble(), gananc));
        if (promediodinero < gananc) promediodinero = gananc;
        recorrido--;
      }

    });

    int clientes = await getTotalClientes();

    setState(() {
      totalclientes = clientes;
    });

    //print("gastos $gastos prestado $prestamos cobro $cobro promedio $promediodinero");

  }

  dialogCuenta()async{

    var baseDialog = BaseAlertDialog(
      title: Text("Cerrar sesion?",style: TextStyle(color: Colors.white),),
      content: Text("Si cierra la sesion se eliminara todo en el movil, recuerde antes de salir subir copias. No se podran recuperar si no hace copias",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("CERRAR SESION",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        await cerrarSesion();
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);

  }

  void cerrarSesion()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String url = baseurl+'cerrarsesion.php';

    //print("IDUSER: $iduser");

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    Map item = resp[0];
    String code = item['code'];

    if(code == "10"||code=="9"||code=="8"){
      await setLocal("iduser", "no");
      await setLocal("ruta", "no");
      await setLocal("idruta", "no");
      await setLocal("token", "no");
      await borrarDB();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) {return InicioSesion();}), ModalRoute.withName('/'));
    }else{
      Flushbar(message: "Imposible cerrar la sesion",duration: Duration(seconds: 5),).show(context);
    }
  }

  getDatosLicencia()async{

    //print("diaspagos ${user['diaspagos']} ${user['licencia']}");
    licenciaGlobal = user['licencia'];
    String fecha = user['fechapago'];
    //print("fechapago $fecha");
    List datos = fecha.split("-");
    String anio = datos[0];
    String mes = datos[1];
    String dia = datos[2];

    String fechapago = "$dia/$mes/$anio";
    int diaspagos = int.parse(user['diaspagos'].toString());

    String plan = "GRATIS";
    if(licenciaGlobal=="2"){
      plan = "PLATA";
    }else if(licenciaGlobal=="3"){
      plan = "BRONCE";
    }else if(licenciaGlobal=="4"){
      plan = "ORO";
    }

    int diaspasados = await diasCorridos(fechapago);
    int diasrestantes = diaspagos-diaspasados;

    if(diasrestantes<0){
      licenciaGlobal = "1";
    }

    Map mapalicencia = {"plan":plan,"dias":"$diasrestantes"};

    datosLicencia = mapalicencia;

  }

  getMensaje()async {
    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || token == "no" || iduser == '_' || iduser == "no") {
      //Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    String url = baseurl + 'actualizacion.php';

    var data = {"iduser": iduser, "token": token, "plataforma": "android"};
    var response = await http.post(url, body: json.encode(data));

    //print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    Map item = resp[0];
    //print('respuesta $item');
    String code = item['code'];
    String titulo = item['titulo'];
    String mensaje = item['mensaje'];
    String obligatorio = item['obligatorio'];
    String urlir = item['url'];
    String version = item['version'];
    String textoboton = item['textoboton'];

    mensajeFinal = {
      "titulo": titulo,
      "mensaje": mensaje,
      "obligatorio": obligatorio,
      "url": urlir,
      "version": version,
      "textoboton": textoboton
    };

    if (versionApp != version && version != "no") {
      if (obligatorio == "si") {
        //obligatorio actualizar
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ActualizacionObligatorio(mensajeFinal)));
      } else {
        //actualizar cuando quiera
        print("actualizar cuando quiera");
        visiblemensaje = true;
      }
    }
  }

  void irActualizar(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {

    // He tomado la altura aproximada de la parte curva de la vista
    // Cámbialo si tienes especificaciones exactas
    final roundingHeight = size.height * 3 / 8;

    // this is top part of path, rectangle without any rounding
    final filledRectangle = Rect.fromLTRB(0, 0, size.width, size.height - roundingHeight);

    // this is rectangle that will be used to draw arc
    // arc is drawn from center of this rectangle, so it's height has to be twice roundingHeight
    // also I made it to go 5 units out of screen on left and right, so curve will have some incline there
    final roundingRectangle = Rect.fromLTRB(-5, size.height - roundingHeight * 2, size.width + 5, size.height);

    final path = Path();
    path.addRect(filledRectangle);

    // so as I wrote before: arc is drawn from center of roundingRectangle
    // 2nd and 3rd arguments are angles from center to arc start and end points
    // 4th argument is set to true to move path to rectangle center, so we don't have to move it manually
    path.arcTo(roundingRectangle, pi, -pi, true);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    // returning fixed 'true' value here for simplicity, it's not the part of actual question, please read docs if you want to dig into it
    // basically that means that clipping will be redrawn on any changes
    return true;
  }
}


class dasboardcobrador extends StatefulWidget {

  @override
  _dasboardcobradorState createState() => _dasboardcobradorState();
}

class _dasboardcobradorState extends State<dasboardcobrador> {

  String correo = "";
  String copia = "";
  String empresa = "";
  String msj = "";
  Map mensajeFinal = {"titulo": "Ola", "mensaje": "Cuerpo del mensaje", "obligatorio": "no","url": "http","version": "no","textoboton":""};
  bool visiblemensaje = false;

  @override
  void initState(){
    iniciar();
    super.initState();
  }

  void iniciar()async{
    await this.getMensaje();
    await this.getDatosRuta();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: visiblemensaje,
                child: Container(
                  color: Colores.secundario,
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${mensajeFinal['titulo']}",style: TextStyle(fontSize: 18),),
                      Text("${mensajeFinal['mensaje']}"),
                      OutlineButton(
                        onPressed: (){
                          irActualizar(mensajeFinal['url']);
                        },
                        child: Text("${mensajeFinal['textoboton']}"),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                color: Colores.azuloscuro,
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("${user['email']}",style: TextStyle(fontSize: 12,color: Colors.white),),
                        IconButton(
                          onPressed: (){
                            dialogCuenta();
                          },
                          icon: Icon(Icons.power_settings_new,color: Colors.white,),
                        ),
                      ],
                    ),
                    SizedBox(height: 15,),
                    Text("Cuenta cobrador",style: TextStyle(fontSize: 20,color: Colors.white),),
                    SizedBox(height: 15,),
                    Text("$ruta",style: TextStyle(fontSize: 25,color: Colores.rosadooscuro),),
                    SizedBox(height: 15,),
                    Text("Ultima copia $copia",style: TextStyle(fontSize: 12,color: Colors.white),),
                    SizedBox(height: 30,),
                  ],
                ),
              ),
              Visibility(
                visible: licenciaGlobal!="1"&&licenciaGlobal!='0'?true:false,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              width: screenWidth(context)/3,
                              child: Material(
                                elevation: 10,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>GrupoClientes()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Column(
                                      children: <Widget>[
                                        Text("Clientes"),
                                        Icon(Icons.person,size: 50,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: screenWidth(context)/3,
                              child: Material(
                                elevation: 10,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ResumenDia()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Column(
                                      children: <Widget>[
                                        Text("Resumen"),
                                        Icon(Icons.adb,size: 50,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              width: screenWidth(context)/3,
                              child: Material(
                                elevation: 10,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>DescargarCopiasCobrador()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Column(
                                      children: <Widget>[
                                        Text("Descargar",style: TextStyle(fontSize: 12),),
                                        Icon(Icons.file_download,size: 50,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: screenWidth(context)/3,
                              child: Material(
                                elevation: 10,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                child: InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Inicio()));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Column(
                                      children: <Widget>[
                                        Text("Mi cuenta",style: TextStyle(fontSize: 12),),
                                        Icon(Icons.person_pin,size: 50,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],)
              ),
              Visibility(
                  visible: licenciaGlobal=="1"||licenciaGlobal=='0'?true:false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text("Su plan es gratis, no se puede usar la cuenta cobrador.",style: TextStyle(fontSize: 20,color: Colores.secundario),),
                      ),
                    ],)
              ),
            ],
          ),
        ),
      ),
    );
  }

  getDatosRuta()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String idruta = user['idruta'];

    if (token == '_' || token == 'no' || iduser == '_' || iduser == 'no') {
      Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    setState(() {
      msj = "Decargando datos";
    });

    String url = baseurl + 'inforuta.php';

    var data = {"idruta":idruta, "iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

   //print("respuesta server: ${response.body} idruta $idruta");
    List result = jsonDecode(response.body);
    Map item = result[0];
    print("respuesta server: ${item}");
    ruta = item['nombre'];
    copia = item['copia'];


    this.getDatosLicencia();

  }

  getDatosLicencia()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String idruta = user['idruta'];

    if (token == '_' || token == 'no' || iduser == '_' || iduser == 'no') {
      Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    setState(() {
      msj = "Decargando datos";
    });

    String url = baseurl + 'verlicencia.php';

    var data = {"idruta":idruta, "iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    //print("respuesta server: ${response.body} idruta $idruta");
    List result = jsonDecode(response.body);
    Map item = result[0];
    print("respuesta server: ${item}");

    licenciaGlobal = item['licencia'];
    String dias = item['diaspagos'].toString();
    String fecha = item['fechapago'];
    //print("fechapago $fecha");
    List datos = fecha.split("-");
    String anio = datos[0];
    String mes = datos[1];
    String dia = datos[2];

    String fechapago = "$dia/$mes/$anio";
    int diaspagos = int.parse(dias);

    String plan = "GRATIS";
    if(licenciaGlobal=="2"){
      plan = "PLATA";
    }else if(licenciaGlobal=="3"){
      plan = "BRONCE";
    }else if(licenciaGlobal=="4"){
      plan = "ORO";
    }

    int diaspasados = await diasCorridos(fechapago);
    int diasrestantes = diaspagos-diaspasados;

    if(diasrestantes<0){
      licenciaGlobal = "1";
    }


    setState(() {
      print("licenciaglobal $licenciaGlobal diasrestantes $diasrestantes pasados $diaspasados fecha $fechapago");
    });
  }

  getMensaje()async {
    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || token == "no" || iduser == '_' || iduser == "no") {
      //Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    String url = baseurl + 'actualizacion.php';

    var data = {"iduser": iduser, "token": token, "plataforma": "android"};
    var response = await http.post(url, body: json.encode(data));

    //print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    Map item = resp[0];
    //print('respuesta $item');
    String code = item['code'];
    String titulo = item['titulo'];
    String mensaje = item['mensaje'];
    String obligatorio = item['obligatorio'];
    String urlir = item['url'];
    String version = item['version'];
    String textoboton = item['textoboton'];

    mensajeFinal = {
      "titulo": titulo,
      "mensaje": mensaje,
      "obligatorio": obligatorio,
      "url": urlir,
      "version": version,
      "textoboton": textoboton
    };

    if (versionApp != version && version != "no") {
      if (obligatorio == "si") {
        //obligatorio actualizar
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ActualizacionObligatorio(mensajeFinal)));
      } else {
        //actualizar cuando quiera
        print("actualizar cuando quiera");
        visiblemensaje = true;
      }
    }
  }

  void irActualizar(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  dialogCuenta()async{

    var baseDialog = BaseAlertDialog(
      title: Text("Cerrar sesion?",style: TextStyle(color: Colors.white),),
      content: Text("Si cierra la sesion se eliminara todo en el movil, recuerde antes de salir subir copias. No se podran recuperar si no hace copias",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("CERRAR SESION",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        await cerrarSesion();
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);

  }

  void cerrarSesion()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String url = baseurl+'cerrarsesion.php';

    print("IDUSER: $iduser");

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    print("resp: ${response.body}");
    var resp = jsonDecode(response.body);
    Map item = resp[0];
    String code = item['code'];

    if(code == "10"||code=="9"||code=="8"){
      await setLocal("iduser", "no");
      await setLocal("ruta", "no");
      await setLocal("idruta", "no");
      await setLocal("token", "no");
      await borrarDB();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) {return InicioSesion();}), ModalRoute.withName('/'));
    }else{
      Flushbar(message: "Imposible cerrar la sesion",duration: Duration(seconds: 5),).show(context);
    }
  }

}

class DescargarCopiasCobrador extends StatefulWidget {
  @override
  _DescargarCopiasCobradorState createState() => _DescargarCopiasCobradorState();
}

class _DescargarCopiasCobradorState extends State<DescargarCopiasCobrador> {

  String msj = "";
  bool visiblecarga = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Descargar copia"),
              Text("Copia disponible para $ruta"),
              SizedBox(height: 20,),
              Visibility(
                visible: visiblecarga,
                child: ListTile(
                  title: Text(msj),
                  leading: SizedBox(width: 20,height: 20,child: CircularProgressIndicator(),),
                ),
              ),
              Text(msj),
              OutlineButton(
                onPressed: (){
                  this.descargardb();
                },
                child: Text("DESCARGAR"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future descargardb() async {

    //print("user: $user");

    String idruta = user['idruta'];
    String ruta = user['nombre'];
    String idadmin = user['idadmin'];
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String nombre = "admin.db";

    var data = {
      "iduser": iduser,
      "token": token,
      "idruta": idruta,
      "nombre": nombre,
    };

    setState(() {
      msj = "Descargando copia";
      visiblecarga = true;
    });

    String url = baseurl + "descargas.php";

    /*HttpClient client = new HttpClient();
    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response.pipe(new File(path).openWrite());
    });*/

    var response = await http.post(url, body: json.encode(data));
    int totalbytes = response.contentLength;
    String body = response.body;
    print("body: $body");
    print("response $totalbytes bytes");

    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");
    await deleteDatabase(path);
    //print("borrada db");

    if (totalbytes > 10000) {
      await new File(path).writeAsBytes(response.bodyBytes, flush: true);
      setState(() {
        msj = "Descargado exitoso: $totalbytes bytes";
        visiblecarga = false;
      });
    } else {
      setState(() {
        msj = "Fallido no hay copias de esta empresa: $totalbytes bytes";
        visiblecarga = false;
      });
    }

    await setLocal("idruta", idruta);
    await setLocal("ruta", ruta);
    await setLocal("copia", "copia");

    Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboardcobrador()));
    /*var db = await openDatabase(
      path,
      readOnly: false,
    );*/
  }

}



class ActualizacionObligatorio extends StatefulWidget {
  Map mensaje;
  ActualizacionObligatorio(this.mensaje);

  @override
  _ActualizacionObligatorioState createState() => _ActualizacionObligatorioState();
}

class _ActualizacionObligatorioState extends State<ActualizacionObligatorio> {

  Map mensajeFinal;

  @override
  void initState() {
    mensajeFinal = widget.mensaje;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async=>false,
      child: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            color: Colores.secundario,
            width: double.infinity,
            height: screenHeight(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${mensajeFinal['titulo']}",style: TextStyle(fontSize: 25,color: Colores.primario),),
                Text("${mensajeFinal['mensaje']}"),
                OutlineButton(
                  onPressed: (){
                    irActualizar(mensajeFinal['url']);
                  },
                  child: Text("${mensajeFinal['textoboton']}"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void irActualizar(String url) async {
    if(url.length>0) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }else{
      print("Sin url");
    }
  }
}



