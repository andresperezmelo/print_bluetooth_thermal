import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:prestagroons/meTodo.dart';
import 'package:prestagroons/string.dart';
import 'package:prestagroons/meTodo.dart';
import 'package:image/image.dart' as Imag;
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:device_unlock/device_unlock.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info/device_info.dart';
import 'main.dart';

bool _connected = false;

class Ajustes extends StatefulWidget {
  @override
  _AjustesState createState() => _AjustesState();
}

class _AjustesState extends State<Ajustes> {

  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose()async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajustes"),
      ),
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Inicio()));
                },
                child: ListTile(
                  title: Text("Mi cuenta"),
                  leading: Icon(Icons.person_outline),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(
                      this.context,
                      MaterialPageRoute(
                          builder: (context) => selecionarRutas()));
                },
                child: ListTile(
                  title: Text("Descargar rutas"),
                  leading: Icon(Icons.file_download),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SubirCopia()));
                },
                child: ListTile(
                  title: Text("Subir copia"),
                  leading: Icon(Icons.cloud_upload),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(
                      this.context,
                      MaterialPageRoute(
                          builder: (context) => AjustresEmpresa()));
                },
                child: ListTile(
                  title: Text("Ajustes de empresa"),
                  leading: Icon(Icons.account_balance),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  if (licenciaGlobal != "0" && licenciaGlobal != "1") {
                    Navigator.push(
                        this.context,
                        MaterialPageRoute(
                            builder: (context) => AdministrarRutas()));
                  } else {
                    Flushbar(
                      title: "ADQUIERE UN PLAN",
                      message: "No disponible sin plan",
                      backgroundColor: Colors.deepPurpleAccent,
                      duration: Duration(seconds: 5),
                    ).show(context);
                  }
                },
                child: ListTile(
                  title: Text("Administrar rutas"),
                  leading: Icon(Icons.add_to_home_screen),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => caja()));
                },
                child: ListTile(
                  title: Text("Caja"),
                  leading: Icon(Icons.attach_money),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  if (licenciaGlobal != "0" && licenciaGlobal != "1") {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => gastos()));
                  } else {
                    Flushbar(
                      title: "ADQUIERE UN PLAN",
                      message: "No disponible sin plan",
                      backgroundColor: Colors.deepPurpleAccent,
                      duration: Duration(seconds: 5),
                    ).show(context);
                  }
                },
                child: ListTile(
                  title: Text("Gastos"),
                  leading: Icon(Icons.shopping_cart),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Flushbar(
                    title: "TRABAJANDO",
                    message: "Pronto estara disponible",
                    duration: Duration(seconds: 5),
                    backgroundColor: Color(0xff457b9d),
                  ).show(context);
                  if (licenciaGlobal != "0" && licenciaGlobal != "1") {
                    //Navigator.push(context, MaterialPageRoute(builder: (context)=>Apariencias()));
                  } else {
                    Flushbar(
                      title: "ADQUIERE UN PLAN",
                      message: "No disponible sin plan",
                      backgroundColor: Colors.deepPurpleAccent,
                      duration: Duration(seconds: 5),
                    ).show(context);
                  }
                },
                child: ListTile(
                  title: Text("Apariencia"),
                  leading: Icon(Icons.color_lens),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  //importdb();
                  buscardb();
                },
                child: ListTile(
                  title: Text("Importar db"),
                  leading: Icon(Icons.exit_to_app),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  //exportardb();
                  //exportdblocal();
                  compartirdb();
                },
                child: ListTile(
                  title: Text("Compartir db"),
                  leading: Icon(Icons.share),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  buscarlogo();
                },
                child: ListTile(
                  title: Text("Importar logo"),
                  leading: Icon(Icons.image),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => borrardb()));
                },
                child: ListTile(
                  title: Text("Borrar mi base de datos"),
                  leading: Icon(Icons.error),
                ),
              )),
              Container(
                  child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ImportarPrestaCOP()));
                },
                child: ListTile(
                  title: Text("Importar clientes de PrestaCOP"),
                  leading: Icon(Icons.card_travel),
                ),
              )),
              Divider(
                height: 30,
              ),
              Container(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditarResumenDia()));
                    },
                    child: ListTile(
                      title: Text("Eliminar resumen"),
                      leading: Icon(Icons.gradient),
                    ),
                  )),
              Divider(
                height: 30,
              ),
              Container(
                  child: InkWell(
                    onTap: () async{
                      String url = "https://chat.whatsapp.com/DbFtyzAFOXiEho0nMjB0KN";
                      if (await canLaunch(url)) {
                      await launch(url);
                      } else {
                      throw 'Could not launch $url';
                      }
                    },
                    child: ListTile(
                      title: Text("Unete a nuestro grupo de WhatsApp"),
                      leading: Icon(Icons.group),
                    ),
                  )
              ),
              Container(
                  child: InkWell(
                    onTap: () async{
                      String url = "https://api.whatsapp.com/send?phone=573504706990";
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: ListTile(
                      title: Text("Escribenos al chat de WhatsApp"),
                      leading: Icon(Icons.send),
                    ),
                  )
              ),
              Container(
                  child: InkWell(
                    onTap: () async{
                      String url = "https://groonsayuda.blogspot.com/";
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: ListTile(
                      title: Text("Consulta nuestro blog de ayuda"),
                      leading: Icon(Icons.sticky_note_2_sharp),
                    ),
                  )
              ),
              /*
              Container(
                  child: InkWell(
                    onTap: () async{
                      Navigator.push(context, MaterialPageRoute(builder: (context) => descargaprogreso()));
                    },
                    child: ListTile(
                      title: Text("progreso descarga"),
                      leading: Icon(Icons.arrow_circle_down),
                    ),
                  )
              ),
              Container(
                  child: InkWell(
                    onTap: () async{
                      Navigator.push(context, MaterialPageRoute(builder: (context) => progresodecarga()));
                    },
                    child: ListTile(
                      title: Text("progreso carga"),
                      leading: Icon(Icons.upload_file),
                    ),
                  )
              ),*/
              /*Container(
                  child: InkWell(
                    onTap: () {
                      pruebasetsave();
                      //Navigator.push(context, MaterialPageRoute(builder: (context) => DemoPage()));
                    },
                    child: ListTile(
                      title: Text("save db"),
                      leading: Icon(Icons.print),
                    ),
                  )),*/
            ],
          ),
        ),
      ),
    );
  }

  void inicio() {
    Navigator.push(
        this.context, MaterialPageRoute(builder: (context) => Inicio()));
  }

  void botonunlock() {
    Navigator.push(
        this.context, MaterialPageRoute(builder: (context) => Unlock()));
  }

  Future<Flushbar> exportardb() async {
    await exportdb();
    return Flushbar(
      message: "Exportado exitoso en memoria interna /Android/data/app.web.groons.prestagroons/files/admin.db",
      backgroundColor: Colors.green,
      duration: Duration(seconds: 5),
    )..show(this.context);
  }

  Future<Flushbar> buscardb() async {

    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String pathlocal = result.files.single.path;

      String filename = pathlocal.split("/").last;
      List type = filename.split(".");
      String name = type[0];
      String tipo = type[1];
      print("tipo: $tipo");

      if (tipo == "db") {
        await importadb(pathlocal);
        return Flushbar(
          message: "Importado exitoso",
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        )..show(this.context);
      } else {
        return Flushbar(
          title: "Fallo",
          message: "El archivo importado no es una base de datos",
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        )..show(this.context);
      }
    }
  }

  Future<Flushbar> buscarlogo() async {

    if (licenciaGlobal != "0" && licenciaGlobal != "1") {
    } else {
      return Flushbar(
        title: "ADQUIERE UN PLAN",
        message: "No disponible sin plan",
        backgroundColor: Colors.deepPurpleAccent,
        duration: Duration(seconds: 5),
      ).show(context);
    }

    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String pathlocal = result.files.single.path;
      File file = File(result.files.single.path);

      String filename = pathlocal.split("/").last;
      List type = filename.split(".");
      String name = type[0];
      String tipo = type[1];
      //print("tipo: $tipo");

      if (tipo != "png" && tipo != "jpg") {
        return Flushbar(
          title: "ARCHIVO NO VALIDO",
          message: "$filename no es compatible, el logo debe ser png o jpg",
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        )..show(this.context);
      }

      Uint8List bytes = file.readAsBytesSync();

      var decodeImage = await decodeImageFromList(file.readAsBytesSync());
      int tamanio = file.lengthSync();
      int ancho = decodeImage.width;
      int alto = decodeImage.height;

      //print("tamaño: ${file.lengthSync()} ancho: ${decodeImage.width} alto: ${decodeImage.height} filename: $filename");

      if (tamanio > 30000) {
        return Flushbar(
          title: "LOGO MUY PESADO",
          message: "Peso $tamanio (maximo 30000 bytes) ",
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        )..show(this.context);
      } else if (ancho > 350) {
        return Flushbar(
          title: "LOGO MUY ANCHO",
          message: "Logo actual ancho $ancho px (maximo 350 px)",
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        )..show(this.context);
      } else if (alto > 200) {
        return Flushbar(
          title: "LOGO MUY ALTO",
          message: "Logo actual alto $alto px (maximo 200 px) ",
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        )..show(this.context);
      }

      File file2 = new File(pathlocal);
      Directory ruta = await getExternalStorageDirectory();
      var copy = await file2.copy("${ruta.path}/logo.png");

      Uint8List byteshay = await getBytesFotos("logo"); //es necesario ejecutarlo antes para crear la tabla si no esta
      await Future.delayed(const Duration(milliseconds: 500), () {});
      await setBytesFotos("logo", bytes);

      return Flushbar(
        message: "Importado logo exitoso",
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      )..show(this.context);
    }
  }

}

class Inicio extends StatefulWidget {
  @override
  _InicioState createState() => _InicioState();
}

class _InicioState extends State<Inicio> {

  final _resumeDetectorKey = UniqueKey();
  Uint8List bytesfile = null;
  List listaSesiones = new List();
  String tokenahora = "";
  String msj = "";
  bool visiblecarga = false;
  Map sesionSelecciono = {};

  @override
  void initState() {
    this.leerDatosCuenta();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mi cuenta"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: screenWidth(context),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white10, Colors.white10],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 100,
                height: 50,
                child: bytesfile!=null?CircleAvatar(
                  child: Image.memory(bytesfile),
                  radius: 60,
                  backgroundColor: Colors.transparent,
                ):null,
              ),
              Text(
                "$ruta",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
              Text(
                "${user['nombre']}",
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "${user['email']}",
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text("Si necesita ayuda visita nuestro blog o visita nuestro grupo de WhatsApp.",
                style: TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              Visibility(
                visible: visiblecarga,
                child: ListTile(
                  title: Text(msj),
                  leading: SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2,),),
                ),
              ),
              Container(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: listaSesiones == null ? 0 : listaSesiones.length,
                    itemBuilder: (context,index){
                      if (listaSesiones == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaSesiones[index];
                        String id = item['id'];
                        String token = item['token'];
                        String hora = item['hora'];
                        String fecha = item['fecha'];
                        String validez = item['validezminutos'];
                        return Padding(
                          padding: EdgeInsets.all(5),
                          child: Material(
                            elevation: 5,
                            child: Container(
                              width:130,
                              margin: EdgeInsets.only(left: 10,right: 10,top: 5,bottom: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(width: 1,color: Colores.primario),
                              ),
                              child: ListTile(
                                title: Text("Iniciado ${item['fecha']} ${item['hora']}",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold,color: Colores.primario),),
                                subtitle: Text("Validez ${item['validezminutos']} minutos",style: TextStyle(fontSize: 10, color: Colores.primario),),
                                trailing:  tokenahora==item['token']?Text("Esta sesion",style: TextStyle(color: Colors.green),):RaisedButton(
                                  onPressed: () {
                                    sesionSelecciono = item;
                                    this.dialogCuenta();
                                  },
                                  color: Colores.secundario,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text('Cerrar sesion',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                ),
                              ),
                            ),
                          )
                          ,
                        );
                      }
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void rutaSeleccionada() async {

    String iduser = await getLocal("iduser");
    if (iduser == "_" || iduser == "") {
      Navigator.push(this.context, MaterialPageRoute(builder: (context) => InicioSesion()));
      return;
    } else {}
    ruta = await getLocal("ruta");
    if (ruta == "_" || ruta == "") {
      //Navigator.push(this.context, MaterialPageRoute(builder: (context) => selecionarRutas()));
    } else {
      setState(() {});
    }
  }

  void leerDatosCuenta()async{

    Uint8List byteshay = await getBytesFotos("logo");
    bool existelogo = byteshay==null?false:true;
    if(existelogo){
      bytesfile = byteshay;
    }

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    tokenahora = token;

    if (token == '_' || token == 'no' || iduser == '_' || iduser == 'no') {
      Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    setState(() {
      msj = "Buscando sesiones";
      visiblecarga = true;
    });

    String url = baseurl + 'sesiones.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    var jso = jsonDecode(response.body);

    //print("respuesta server: ${jso}");

    if (jso.length <= 0) {
      msj = "No hay mas sesiones";
    } else {
      msj = "Selecciona una sesion para cerrarla";
    }

    print("llego: $jso ");

    setState(() {
      listaSesiones = jso;
      visiblecarga = false;
    });
  }

  dialogCuenta()async{

    var baseDialog = BaseAlertDialog(
      title: Text("Cerrar sesion?",style: TextStyle(color: Colors.white),),
      content: Text("Se retirara esta sesion, se necesita volver a ingresar donde se cerro la sesion, es importante cerrar todas las sesiones que no usa ",style: TextStyle(color: Colors.white),),
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

    //String token = await getLocal("token");
    String token = sesionSelecciono['token'];
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
      //await setLocal("iduser", "no");
      //await setLocal("ruta", "no");
      //await setLocal("idruta", "no");
      //await setLocal("token", "no");
      //await borrarDB();
      Flushbar(message: "Sesion cerrada",duration: Duration(seconds: 3),).show(context);
      this.leerDatosCuenta();
    }else{
      Flushbar(message: "Imposible cerrar la sesion",duration: Duration(seconds: 5),).show(context);
    }
  }
}

class selecionarRutas extends StatefulWidget {
  @override
  _selecionarRutasState createState() => _selecionarRutasState();
}

class _selecionarRutasState extends State<selecionarRutas> {

  int buscado = 0;
  final _resumeDetectorKey = UniqueKey();
  List rutas = new List();
  String msj = "";
  bool visiblecarga = false;
  int _total = 0, _received = 0;
  http.StreamedResponse _response;
  List<int> _bytes = [];

  @override
  void initState() {
    this.leerRutas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seleccione una ruta"),
      ),
      body: FocusDetector(
        key: _resumeDetectorKey,
        child: Container(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: visiblecarga,
                  child: ListTile(
                    title: Text(msj),
                    leading: SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2,),),
                  ),
                ),
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  physics: PageScrollPhysics(),
                  shrinkWrap: true,
                  // Deja que ListView sepa cuántos elementos necesita para construir
                  itemCount: rutas == null ? 0 : rutas.length,
                  // Proporciona una función de constructor. ¡Aquí es donde sucede la magia! Vamos a
                  // convertir cada elemento en un Widget basado en el tipo de elemento que es.
                  itemBuilder: (context, index) {
                    if (rutas == null) {
                      return CircularProgressIndicator();
                    } else {
                      final item = rutas[index];
                      return InkWell(
                        onTap: () {
                          _downloadFile(item);
                          //descargardb(item);
                        },
                        child: ListTile(
                          title: Text(item['nombre'], style: TextStyle(fontWeight: FontWeight.bold,)),
                          subtitle: Text("${item['clientes'].toString()} clientes"),
                          trailing: Text(item['copia'], style: TextStyle(fontSize: 12)),
                        ),
                      );
                    }
                  },
                ),
                OutlineButton(
                  onPressed: () {
                    buscado=0;
                    Navigator.push(this.context, MaterialPageRoute(builder: (context) => registrarRuta()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Registrar ruta',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onFocusGained: (){
          this.leerRutas();
        },
      ),
    );
  }

  Future leerRutas() async {

    if(visiblecarga||buscado>=1) {
      print("detenido busqueda de rutas esta descargando");
      return;
    }

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || token == 'no' || iduser == '_' || iduser == 'no') {
      Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    setState(() {
      msj = "Buscando rutas";
      visiblecarga = true;
    });

    String url = baseurl + 'leerrutas.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    var jso = jsonDecode(response.body);

    //print("respuesta server: ${jso}");

    if (jso.length <= 0) {
      msj = "No hay rutas registradas";
    } else {
      msj = "Selecciona una de las rutas para descargar la base de datos";
    }

    print("llego: $jso ");

    buscado++;


    setState(() {
      rutas = jso;
      visiblecarga = false;
    });
  }

  Future descargardb(Map item) async {

    //idruta: 24957cbb1902006b2e96, idref: 0fc3def73bd211ee8187f9583b9d831ca4844d16,
    //  nombre: RUTA TRES, cobrador: Andres, copia: , device: ,  idtelefono: ,  ingreso: ,  clientes: }
    String idruta = item['idruta'];
    String ruta = item['nombre'];
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
      msj = "Descargando...";
      visiblecarga = true;
    });

    String url = baseurl + "descargas.php";
    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");

    await deleteDatabase(path);
    //print("borrada db");

    /*HttpClient client = new HttpClient();
    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      return request.close();
    }).then((HttpClientResponse response) {
      response.pipe(new File(path).openWrite());
    });*/

    var response = await http.post(url, body: json.encode(data));
    int totalbytes = response.contentLength;
    print("response $totalbytes bytes");
    if (totalbytes > 10000) {
      await new File(path).writeAsBytes(response.bodyBytes, flush: true);
      setState(() {
        msj = "Descargado exitoso: $totalbytes bytes";
        visiblecarga = true;
      });
    } else {
      setState(() {
        msj = "Fallido no hay copias de esta empresa: $totalbytes bytes";
        visiblecarga = true;
      });
    }

    await setLocal("idruta", idruta);
    await setLocal("ruta", ruta);
    await setLocal("copia", "copia");

    Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboard()));
    /*var db = await openDatabase(
      path,
      readOnly: false,
    );*/
  }

  Future<void> _downloadFile(Map item) async {

    String url = baseurl + "descargas.php";

    String idruta = item['idruta'];
    String ruta = item['nombre'];
    //String idruta = await getLocal("idruta");
    //String ruta = await getLocal("ruta");
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String nombre = "admin.db";
    var data = {
      "iduser": iduser,
      "token": token,
      "idruta": idruta,
      "nombre": nombre,
    };

    print("enviando $data");

    setState(() {
      msj = "Descargando...";
      visiblecarga = true;
    });


    final request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(data);
    _response = await http.Client().send(request);
    _total = _response.contentLength;
    //print("total $_total");
    _response.stream.listen((value) {
      setState(() {
        _bytes.addAll(value);
        _received += value.length;
        String percentage = (_received/_total*100).toStringAsFixed(2);
        msj = "${_received ~/ 1024}/${_total ~/ 1024} KB - $percentage % descargado";
        //print(msj);
      });
    }).onDone(() async {
      //print("descargo byetes lentg ${_bytes.length}");
      var pathdb = await getPathDB();
      var path = p.join(pathdb, "admin.db");
      await deleteDatabase(path);
      int totalbytes = _bytes.length;
      if (totalbytes > 10000) {
        await new File(path).writeAsBytes(_bytes, flush: true);
        setState(() {
          msj = "Descargado exitoso: $totalbytes bytes";
        });
      } else {
        setState(() {
          msj = "Fallido no hay copias de esta empresa: $totalbytes bytes";
        });
      }
      //final file = File("${(await getApplicationDocumentsDirectory()).path}/image.png");
      //await file.writeAsBytes(_bytes);

      await setLocal("idruta", idruta);
      await setLocal("ruta", ruta);
      await setLocal("copia", "copia");

      Navigator.push(this.context, MaterialPageRoute(builder: (context) => dasboard()));

    });
  }

}

class registrarRuta extends StatefulWidget {
  @override
  _registrarRutaState createState() => _registrarRutaState();
}

class _registrarRutaState extends State<registrarRuta> {

  final _txtnombre = TextEditingController();
  final _txtcobrador = TextEditingController();
  bool _validatenombre = false;
  bool _validatecobrador = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _txtnombre.dispose();
    _txtcobrador.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registre una una ruta"),
      ),
      body: Container(
          child: Center(
            child: ListView(
              children: <Widget>[
                SizedBox(height: 20),
                Container(
                    margin:
                    EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 30),
                    child: Text(Strings.mensajeregistrorutas)),
                Container(
                  margin:
                  EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 10),
                  child: TextField(
                    controller: _txtnombre,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la ruta',
                      errorText: _validatenombre
                          ? 'El valor no puede estar vacío'
                          : null,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Container(
                  margin:
                  EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 20),
                  child: TextField(
                    controller: _txtcobrador,
                    decoration: InputDecoration(
                      labelText: 'Nombre del cobrador',
                      errorText: _validatecobrador
                          ? 'El valor no puede estar vacío'
                          : null,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(left: 20, right: 20),
                  child: OutlineButton(
                    onPressed: () {
                      setState(() {
                        _txtnombre.text.isEmpty
                            ? _validatenombre = true
                            : _validatenombre = false;
                        _txtcobrador.text.isEmpty
                            ? _validatecobrador = true
                            : _validatecobrador = false;
                        if (_validatenombre == false &&
                            _validatecobrador == false) {
                          registrar();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        'Registrar ruta',
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
      )
    );
  }

  Future registrar() async {

    String ruta = _txtnombre.text.trim();
    String cobrador = _txtcobrador.text.trim();
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");

    if (ruta.length == 0 || cobrador.length == 0) {
      Flushbar(message: "Faltan datos! por favor complete los datos",duration: Duration(seconds: 5),).show(context);
      return;
    }

    String url = baseurl + 'crearruta.php';

    var data = {
      "iduser": iduser,
      "token": token,
      "nombre": _txtnombre.text.toUpperCase().trim(),
      "cobrador": primeraLetraMayuzcula(_txtcobrador.text.trim()),
      "copia": "no",
      "device": "no",
      "idtelefono": "no",
      "ingreso": "no",
      "clientes": "0",
    };

    var response = await http.post(url, body: json.encode(data));

    try {
      var estado = response.statusCode;
      if (estado == 200) {
        setState(() {
          //_txtnombre.clear();
        });
        print("llego: ${response.body}");
        var json = jsonDecode(response.body);
        var item = json[0];
        //print("item ${item}");
        String code = item['code'];
        String nivel = item['nivel'];
        String mensaje = item['msj'];
        //String email = item['email'];
        String nombre = item['nombre'];
        String iduser = item['iduser'];

        if (code == 10) {
          Flushbar(message: "Exitoso: $mensaje",duration: Duration(seconds: 5),).show(context);
        } else {
          Flushbar(message: "Respuesta: $mensaje",duration: Duration(seconds: 5),).show(context);
          //Navigator.push(this.context, MaterialPageRoute(builder: (context) => inico()));
        }
      } else {
        Flushbar(message: "Sin respuesta: No hay respuesta del servidor ",duration: Duration(seconds: 5),).show(context);
      }
    } catch (e) {
      print("error $e");
    }
  }

}

class SubirCopia extends StatefulWidget {
  @override
  _SubirCopiaState createState() => _SubirCopiaState();
}

class _SubirCopiaState extends State<SubirCopia> {

  String tipomodo = "";
  String msj = "Subir copias todos los dias es importante";
  bool visiblecarga = false;
  String fechacopia = "";
  String clientescopia = "0";
  bool copialocal = false;
  String url = baseurl + "fileupload.php";
  Response response;

  @override
  void initState() {
    this.verUltimaCopia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 20,
              ),
              Text(
                "$tipomodo",
                style: TextStyle(fontSize: 20),
              ),
              Text(
                "Suba copias todos los dias al finalizar de trabajar para poderla descargar por si el telefoino se averia o se pierde",
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(
                height: 20,
              ),
              Divider(),
              Text("$fechacopia"),
              SizedBox(
                height: 20,
              ),
              Text("$msj",style: TextStyle(color: Colors.green),),
              SizedBox(
                height: 20,
              ),
              Visibility(
                visible: visiblecarga,
                child: ListTile(
                  title: Text(msj),
                  leading: SizedBox(width: 20,height: 20,child: CircularProgressIndicator(strokeWidth: 2,),),
                ),
              ),
              OutlineButton.icon(
                onPressed: () {
                  if (licenciaGlobal != "0" && licenciaGlobal != "1") {
                    this.modalConfirmarSubir();
                  } else {
                    setState(() {
                      copialocal = true;
                    });
                    return Flushbar(
                      title: "ADQUIERE UN PLAN",
                      message: "No disponible sin plan",
                      backgroundColor: Colors.deepPurpleAccent,
                      duration: Duration(seconds: 5),
                    ).show(context);
                  }
                },
                icon: Icon(Icons.file_upload, color: Colores.primario),
                label: Text("Subir copia",style: TextStyle(color: Colores.primario),),
              ),
              SizedBox(
                height: 50,
              ),
              Visibility(
                visible: copialocal,
                child: Column(
                  children: [
                    Text(
                      "Su plan es gratis",
                      style: TextStyle(fontSize: 25),
                    ),
                    Text("Debe compartir la copia local y subirla a algun servidor o guardarla en algun lugar, para posterior a eso descargarla cuando necesite restaurar los clientes. "
                        "(guardela en su lugar seguro como OneDrive, GoogleDrive, o una memoria usb, para posterior a eso importarla cuando necesite restaurar los clientes en otro telefono)"),
                    Text(
                      "Si no paga un plan no nos hacemos responsables si manipula mal las copias",
                      style: TextStyle(fontSize: 10, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
              OutlineButton.icon(
                onPressed: () async {
                  compartirdb();
                  //return Flushbar(message: "Exportado exitoso en memoria interna /Android/data/app.web.groons.prestagroons/files/admin.db", backgroundColor: Colors.green, duration: Duration(seconds: 5),)..show(this.context);
                },
                label: Text("Compartir base de datos",style: TextStyle(color: Colores.secundario),),
                icon: Icon(Icons.share, color: Colores.secundario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  verUltimaCopia() async {
    String modo = await getLocal("modo");
    if (modo == "admin") {
      tipomodo = "Modo admin";
    } else {
      tipomodo = "Modo cobrador";
    }

    List<Map> info = await getInfo();
    await Future.forEach(info, (item){
      String name = item['nombre'];
      String valor = item['valor'];
      if(name=="fechacopia"){
        fechacopia = valor;
      }else if(name=="clientescopia"){
        clientescopia = valor;
      }
    });
    if (fechacopia == "no") fechacopia = "(ninguna)";
    if (clientescopia == "_") clientescopia = "";
    setState(() {
      fechacopia = "Ultima copia $fechacopia ($clientescopia clientes)";
    });
  }

  modalConfirmarSubir() async {
    int totalclientes = await getTotalClientes();
    if (totalclientes == 0) {
      return Flushbar(
        title: "NO PERMITIDO",
        message:
            "No se le permite subir copias sin clientes, para subir copias necesita tener clientes registrados",
        backgroundColor: Colors.orange,
      ).show(context);
    }

    var baseDialog = BaseAlertDialog(
      title: Text(
        "SUBIR COPIA?",
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        "Suba copias una sola vez al dia, al finalizar de trabajar, importante que espere hasta que diga subida correcta",
        style: TextStyle(color: Colors.white),
      ),
      fondoColor: Color.fromRGBO(21, 67, 96, 0.8),
      yes: Text(
        "SUBIR COPIA",
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
      yesOnPressed: () async {
        Navigator.pop(this.context);
        _uploadFile();
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(this.context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);
  }

  void subir() async {

    setState(() {
      msj = "Subiendo copia espere...";
      visiblecarga = true;
    });

    int totalclientes = await getTotalClientes();
    String fecha = fechaActual();
    String hora = horaActual();
    File file;
    String idruta = await getLocal("idruta");
    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String url = baseurl + "subircopia.php";

    //print("idempresa. $idruta token: $token iduser: $iduser");

    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");
    var exists = await databaseExists(path);
    if (exists) {
      file = File(path);
    } else {
      print("no existe el archivo ");
      setState(() {
        msj = "No hay base de datos para subir";
      });
      return;
    }

    int bytes = file.lengthSync();
    String kb = dejarDosDecimales(bytes/1000);
    setState(() {
      msj = "Subiendo $kb Kb";
      visiblecarga = true;
    });

    String base64Image = base64Encode(file.readAsBytesSync());
    String fileName = "admin.db"; //file.path.split("/").last;

    http.post(url, body: {
      "file": base64Image,
      "nombre": fileName,
      "idruta": idruta,
      "token": token,
      "iduser": iduser,
    }).then((res)async {
      //print("code: ${res.statusCode}");
      int status = res.statusCode;
      print("res: ${res.body}");
      if (status == 200) {
        var json = jsonDecode(res.body);
        var item = json[0];
        //print("json: ${json.length} item: $item");
        var code = item['code'];
        var msjserver = item['msj'];
        //print("item: $msj code $code");

        await setInfo("fechacopia","$fecha $hora");
        await setInfo("clientescopia","$totalclientes");

        setState(() {
          msj = " $msjserver";
          visiblecarga = false;
        });
      }
    }).catchError((err) {
      print("error: ${err.toString()}");
      setState(() {
        setState(() {
          msj = "Error: ${err.toString()}";
          visiblecarga = false;
        });
      });
    });
  }

  Future<void> _uploadFile() async {

    int totalclientes = await getTotalClientes();
    String fecha = fechaActual();
    String hora = horaActual();

    String idruta = await getLocal("idruta");
    String ruta = await getLocal("ruta");
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String nombre = "admin.db";
    File file;

    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");
    var exists = await databaseExists(path);
    if (exists) {
      file = File(path);
    } else {
      print("no existe el archivo ");
      setState(() {
        msj = "No hay base de datos para subir";
      });
      return;
    }

    setState(() {
      visiblecarga = true;
    });

    int bytes = file.lengthSync();
    String kb = dejarDosDecimales(bytes/1024);
    //print("Subiendo $kb Kb idruta $idruta");

    FormData fromdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        file.path,
        filename: nombre,
      ),
      "nombre": "admin.db",
      "idruta": idruta,
      "token": token,
      "iduser": iduser,
    });

    Dio dio = new Dio();
    response = await dio.post(
        url,
        data: fromdata,
        onSendProgress: (int sent, int total){
          String percentage = (sent/total*100).toStringAsFixed(2);
          //print("subido $sent total: $total");
          setState(() {
            msj = "${sent~/ 1024} / ${total~/ 1024} kb - " +  percentage + " % subido.";
          });
        });

    //print(response.data.toString());

    int status = response.statusCode;
    print("res: ${response.data}");
    if (status == 200) {
      var json = jsonDecode(response.data);
      var item = json[0];
      //print("json: ${json.length} item: $item");
      var code = item['code'];
      var msjserver = item['msj'];
      //print("item: $msj code $code");

      await setInfo("fechacopia","$fecha $hora");
      await setInfo("clientescopia","$totalclientes");

      setState(() {
        msj = " $msjserver";
        visiblecarga = false;
      });
    }

  }

}

class AdministrarRutas extends StatefulWidget {
  @override
  _AdministrarRutasState createState() => _AdministrarRutasState();
}

class _AdministrarRutasState extends State<AdministrarRutas> {

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  String idtelefono = "Desconocido";
  List listaRutas = new List();
  String rutaSeleccionada = "";
  String _device = 'Desconocido';
  final txtcorreo = TextEditingController();
  final txtpass = TextEditingController();
  bool _passwordVisible = false;
  bool visibleruta = false;
  bool visiblecrear = false;
  String msj = "";
  Map datosruta = {
    "idruta": "",
    "cobrador": "",
    "copia": "",
    "idtelefono": "",
    "device": "",
    "correo": "",
    "pass": "",
    "urldb": "",
    "ingreso": "",
    "nombre": ""
  };

  @override
  void initState() {
    this.initPlatformState();
    this.leerRutas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 80,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    //physics: NeverScrollableScrollPhysics(),
                    itemCount: listaRutas == null ? 0 : listaRutas.length,
                    itemBuilder: (context, index) {
                      if (listaRutas == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaRutas[index];
                        return InkWell(
                          onTap: () {
                            rutaSeleccionada = item['nombre'];
                            datosruta = item;
                            this.getEstadoruta();
                          },
                          child: Container(
                            width: 175,
                            margin: EdgeInsets.only(
                                left: 10, right: 10, top: 5, bottom: 5),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              border: Border.all(
                                  width: 1,
                                  color: rutaSeleccionada == item['nombre']
                                      ? Colors.blue
                                      : Colors.black26),
                            ),
                            child: ListTile(
                              title: Text(
                                "${item['nombre']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rutaSeleccionada == item['nombre']
                                        ? Colors.blue
                                        : Colors.black),
                              ),
                              subtitle: Text(
                                "${item['cobrador']}",
                                style: TextStyle(
                                    color: rutaSeleccionada == item['nombre']
                                        ? Colors.blue
                                        : Colors.black,
                                    fontSize: 9),
                              ),
                            ),
                          ),
                        );
                      }
                    }),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  elevation: 5,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "$rutaSeleccionada",
                          style: TextStyle(fontSize: 30),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Visibility(
                          visible: visibleruta,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Datos de ingreso del cobrador",
                                style: TextStyle(
                                    color: Theme.of(context).primaryColorDark),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Dispositivo cobrador"),
                                  Text("${datosruta['device']}"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Id telefono"),
                                  Text("${datosruta['idtelefono']}"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Correo"),
                                  Text("${datosruta['correo']}"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Contraseña"),
                                  Text("${datosruta['pass']}"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Ultimo ingreso"),
                                  Text("${datosruta['ingreso']}"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Ultimo copia"),
                                  Text("${datosruta['copia']}"),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              /*OutlineButton(
                                onPressed: (){
                                  pasarEnlaceCobrador();
                                },
                                child: Text("Activar enlace descarga"),
                              ),*/
                              ListTile(
                                onTap: () {
                                  deleteUserRuta();
                                },
                                title: Text(
                                  "Eliminar correo",
                                  style: TextStyle(color: Colors.red),
                                ),
                                trailing: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Visibility(
                          visible: visiblecrear,
                          child: Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Crearle usuario al cobrador",
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).primaryColorDark),
                                ),
                                TextField(
                                  controller: txtcorreo,
                                  decoration: InputDecoration(
                                    labelText: "Correo para el cobrador",
                                  ),
                                ),
                                TextFormField(
                                  controller: txtpass,
                                  keyboardType: TextInputType.text,
                                  obscureText: !_passwordVisible,
                                  //This will obscure text dynamically
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña para el cobrador',
                                    // Here is key idea
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlineButton(
                                      onPressed: () {
                                        crearusuarioCobrador();
                                      },
                                      child: Text("Registrar",style: TextStyle(color: Colors.blue),),
                                    ),
                                    OutlineButton(
                                      onPressed: () {
                                        this.dialogEliminarRuta();
                                      },
                                      child: Text("Eliminar ruta",style: TextStyle(color: Colors.red),),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  leerRutas() async {

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    if (token == '_' || token == 'no' || iduser == '_' || iduser == 'no') {
      Flushbar(message: "No hay usuario validado",duration: Duration(seconds: 5),).show(context);
      return;
    }

    setState(() {
      msj = "Decargando datos";
    });

    String url = baseurl + 'leerrutas.php';

    var data = {"iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    var jso = jsonDecode(response.body);

    //print("respuesta server: ${jso}");

    if (jso.length <= 0) {
      msj = "No hay empresas registradas";
    } else {
      msj = "Selecciona una de las empresas para descargar la base de datos";
    }

    print("llego: $jso ");


    datosruta = {
      "idruta": "",
      "cobrador": "",
      "copia": "",
      "idtelefono": "",
      "device": "",
      "correo": "",
      "pass": "",
      "urldb": "",
      "ultimaconexion": "",
      "nombre": ""
    };
    rutaSeleccionada = "";
    setState(() {
      listaRutas = jso;
    });
  }

  Future<void> initPlatformState() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo build = await deviceInfoPlugin.androidInfo;
        _device = "${build.brand} ${build.model}";
        idtelefono = build.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo build = await deviceInfoPlugin.iosInfo;
        _device = "${build.name} ${build.model}";
        idtelefono = build.identifierForVendor;
      }
    } on PlatformException {
      _device = "Desconocido error";
    }

    setState(() {
      //_deviceData = deviceData;
    });
  }

  getEstadoruta() async {

    String correo = datosruta['correo'];
    if (correo == "no" || correo == "") {
      visiblecrear = true;
      visibleruta = false;
    } else {
      visiblecrear = false;
      visibleruta = true;
    }

    setState(() {});
  }

  crearusuarioCobrador() async  {

    String idadmin = await getLocal("iduser");
    String ruta = await getLocal("ruta");
    String idruta = datosruta['idruta'];
    String correo = txtcorreo.text.trim();
    String pass = txtpass.text.trim();

    if (correo.length < 6) {
      Flushbar(message: "Falta el correo",duration: Duration(seconds: 4),).show(this.context);
      return;
    } else if (pass.length < 6) {
      Flushbar(message: "Falta la contraseña", duration: Duration(seconds: 4),).show(this.context);
      return;
    }

    //var email = "tony@starkindustries.com"
    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(correo);

    if(emailValid==false){
      Flushbar(message: "Correo $correo invalido",duration: Duration(seconds: 3),).show(context);
      return;
    }

    if(pass.length<=5){
      Flushbar(message: "La contraseña debe tener mas de 5 caracteres",duration: Duration(seconds: 3),).show(context);
      return;
    }

    String url = baseurl+'crearusuario.php';

    var data = {
      "email": correo,
      "password": pass,
      "nombre": ruta,
      "nivel": "cobrador",
      "idruta": idruta,
      "idadmin": idadmin,
    };

    var response = await http.post(url, body: json.encode(data));

    try {
      var estado = response.statusCode;
      if (estado == 200) {

        var json = jsonDecode(response.body);
        var item = json[0];
        print("item ${item}");
        String code = item['code'];
        String mensaje = item['msj'];

        if(code=="10"){
          await actualizarRuta(correo, pass);
          Flushbar(message: "Cuenta creada ",duration: Duration(seconds: 3),).show(context);
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

  actualizarRuta(String correo,String pass)async{

    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String idruta = datosruta['idruta'];
    String url = baseurl+'actualizarruta.php';

    var data = {
      "email": correo,
      "password": pass,
      "idruta": idruta,
      "iduser": iduser,
      "token": token,
    };

    var response = await http.post(url, body: json.encode(data));

    print("llego: ${response.body}");
    try {
      var estado = response.statusCode;
      if (estado == 200) {

        var json = jsonDecode(response.body);
        var item = json[0];
        //print("llego update ruta:=> ${item}");
        //String code = item['code'];
        this.leerRutas();

      } else {
        Flushbar(message: "No hay respuesta del servidor",duration: Duration(seconds: 3),).show(context);
      }
    } catch (e) {
      print("error $e");
    }

  }

  deleteUserRuta() async {

    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String idruta = datosruta['idruta'];
    String correo = datosruta['correo'];
    String url = baseurl+'deleteuserruta.php';

    var data = {
      "correo": correo,
      "idruta": idruta,
      "iduser": iduser,
      "token": token,
    };

    var response = await http.post(url, body: json.encode(data));

    //print("llego: ${response.body}");
    try {
      var estado = response.statusCode;
      if (estado == 200) {

        var json = jsonDecode(response.body);
        var item = json[0];
        //print("llego update ruta:=> ${item}");
        //String code = item['code'];

        visiblecrear = true;
        visibleruta = false;

        this.leerRutas();

      } else {
        Flushbar(message: "No hay respuesta del servidor",duration: Duration(seconds: 3),).show(context);
      }
    } catch (e) {
      print("error $e");
    }
    //Flushbar(message: "Implemetar borrar user",duration: Duration(seconds: 5),).show(context);

  }

  dialogEliminarRuta()async{

    var baseDialog = BaseAlertDialog(
      title: Text("ELIMINAR RUTA",style: TextStyle(color: Colors.white),),
      content: Text("Si elimina la ruta se eliminara todo en el servidor, y no se podra recuperar nada si no tiene copias guardadas en OneDrive o GoogleDrive.",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("ELIMINAR RUTA",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        await deleteRuta();
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);

  }

  deleteRuta() async{

    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String idruta = datosruta['idruta'];
    String idrutalocal = await getLocal("idruta");
    String url = baseurl+'deleteruta.php';

    if(idrutalocal==idruta){
      Flushbar(message: "No puede eliminar la ruta que esta en este telefono",duration: Duration(seconds: 5),backgroundColor: Colors.orange,).show(context);
      return;
    }
    if(idruta.length==0){
      Flushbar(message: "Seleccione ruta para eliminar",duration: Duration(seconds: 5),backgroundColor: Colors.orange,).show(context);
      return;
    }

    var data = {
      "idruta": idruta,
      "iduser": iduser,
      "token": token,
    };

    var response = await http.post(url, body: json.encode(data));
    print("response ${response.body}");

    try {
      var estado = response.statusCode;
      if (estado == 200) {

        var json = jsonDecode(response.body);
        var item = json[0];
        //print("llego update ruta:=> ${item}");
        //String code = item['code'];

        visiblecrear = false;
        visibleruta = false;

        this.leerRutas();

      } else {
        Flushbar(message: "No hay respuesta del servidor",duration: Duration(seconds: 3),).show(context);
      }
    } catch (e) {
      print("error eliminar user $e");
    }
  }


}

class caja extends StatefulWidget {
  @override
  _cajaState createState() => _cajaState();
}

class _cajaState extends State<caja> {
  final txtcaja = TextEditingController();
  final txtinterescapital = TextEditingController();
  final txtinteresatraso = TextEditingController();
  final txtinteresvencido = TextEditingController();
  final txtdiasatraso = TextEditingController();
  final txtdiasvencido = TextEditingController();

  String msj = "";
  String id = "0";
  String caja = "0";
  String interescapital = "0";
  String interesatraso = "0";
  String interesvencido = "0";
  String diasatraso = "0";
  String diasvencido = "0";
  String movimientos = "";

  @override
  void initState() {
    this.cargarCaja();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajustes caja")),
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: txtcaja,
                  decoration: InputDecoration(
                    labelText: "Agregar caja",
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: txtinterescapital,
                  decoration: InputDecoration(
                    labelText: "Interes capital",
                  ),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        controller: txtinteresatraso,
                        decoration: InputDecoration(
                          labelText: "Interes atraso",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Flexible(
                      child: TextField(
                        controller: txtinteresvencido,
                        decoration: InputDecoration(
                          labelText: "Interes vencido",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        controller: txtdiasatraso,
                        decoration: InputDecoration(
                          labelText: "Dias atraso cobrar",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Flexible(
                      child: TextField(
                        controller: txtdiasvencido,
                        decoration: InputDecoration(
                          labelText: "Dias vencido cobrar",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Text("$msj"),
                SizedBox(
                  height: 10,
                ),
                RaisedButton(
                  onPressed: () {
                    registrar();
                  },
                  child: Text("Guardar caja"),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  child: Text(
                    "$movimientos",
                    style: TextStyle(fontSize: 8),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void cargarCaja() async {
    Map datos = await getCaja();
    //print("caja $datos");
    String id = datos['id'].toString();
    String caja = "0";
    String interescapital = "0";
    String interesatraso = "0";
    String interesvencido = "0";
    String diasatraso = "0";
    String diasvencido = "0";
    String movimient = "";
    movimientos = "";
    String enter = "\n";

    if (id == "1") {
      caja = datos['caja'].toString();
      interescapital = datos['interescapital'].toString();
      interesatraso = datos['interesatraso'].toString();
      interesvencido = datos['interesvencido'].toString();
      diasatraso = datos['diasatraso'].toString();
      diasvencido = datos['diasvencido'].toString();
      movimient = datos['movimientos'].toString();

      List movimients = movimient.split("*");
      movimients.removeAt(0); //elimina un asterisco que no tiene nada
      await Future.forEach(movimients, (movi) {
        movimientos = movimientos + "*" + movi + enter;
      });
    } else {
      print("no hay datos");
    }

    txtcaja.text = caja;
    txtinterescapital.text = interescapital;
    txtinteresatraso.text = interesatraso;
    txtinteresvencido.text = interesvencido;
    txtdiasatraso.text = diasatraso;
    txtdiasvencido.text = diasvencido;

    setState(() {});
  }

  void registrar() async {
    String caja = txtcaja.text;
    String interescapital = txtinterescapital.text;
    String interesatraso = txtinteresatraso.text;
    String interesvencido = txtinteresvencido.text;
    String diasatraso = txtdiasatraso.text;
    String diasvencido = txtdiasvencido.text;
    String movimiento = "*Caja:$caja %capital:$interescapital %atraso:$interesatraso %vencido:$interesvencido diasatraso:$diasatraso diasvencido:$diasvencido ${fechaActual()} ${horaActual()}";

    msj = "";
    if (caja.length <= 0 || caja == "null") {
      msj = "Falta el valor de caja";
    } else if (interescapital.length <= 0 || interescapital == "null") {
      msj = "Falta el valor de interes capital";
    } else if (interesatraso.length <= 0 || interesatraso == "null") {
      msj = "Falta el valor de interes atraso";
    } else if (interesvencido.length <= 0 || interesvencido == "null") {
      msj = "Falta el valor de interes vencido";
    } else if (diasatraso.length <= 0 || diasatraso == "null") {
      msj = "Falta el valor de los dias atraso para aplicar la mora";
    } else if (diasvencido.length <= 0 || diasvencido == "null") {
      msj = "Falta el valor de los dias vencido para aplicar la mora";
    }
    ;

    if (msj.length > 0) {
      setState(() {});
      return;
    }

    Database database = await opendb();
    List<Map> list =
        await database.rawQuery("SELECT * FROM caja WHERE id=?", ["1"]);

    String movimientos = "";
    if (list.length > 0) {
      movimientos = "${list[0]['movimientos']} $movimiento \n";
    } else {
      movimientos = movimiento + "\n";
    }

    if (list.length <= 0) {
      await database.transaction((txn) async {
        int id = await txn.rawInsert(
            'INSERT INTO caja(id,caja,interescapital,interesatraso,interesvencido,diasatraso,diasvencido,movimientos) VALUES(?,?,?,?,?,?,?,?)',
            [
              "1",
              caja,
              interescapital,
              interesatraso,
              interesvencido,
              diasatraso,
              diasvencido,
              movimientos
            ]);
        print('Caja nueva ');
      });
    } else {
      //actualizar datos
      int count = await database.rawUpdate(
          'UPDATE caja SET caja =?,interescapital=?,interesatraso=?,interesvencido=?,diasatraso=?,diasvencido=?,movimientos=? WHERE id = ?',
          [
            caja,
            interescapital,
            interesatraso,
            interesvencido,
            diasatraso,
            diasvencido,
            movimientos,
            "1"
          ]);
      print('caja actualizada $count');
    }
    await database.close();

    msj = "Registro exitoso ";

    await agregarResumenDia("caja", movimiento, "0", "0", "0", "0", "1");

    await cargarCaja();
  }
}

class gastos extends StatefulWidget {
  @override
  _gastosState createState() => _gastosState();
}

class _gastosState extends State<gastos> {
  final txtgasto = TextEditingController();
  final txtvalor = TextEditingController();
  String msj = "";
  Color color = Colors.blueGrey;
  bool visible = false;

  String diaseleccionado;
  String anioseleccionado;
  String diahoy;
  List<Map> diasmes;
  List<Map> gastodia;

  @override
  void initState() {
    leergastoMes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gastos")),
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: txtgasto,
                      decoration: InputDecoration(
                        labelText: "Motivo gasto",
                      ),
                      onChanged: (text) {
                        if (msj.length > 0) {
                          setState(() {
                            visible = false;
                            msj = "";
                            color = Colors.blueGrey;
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: txtvalor,
                      decoration: InputDecoration(
                        labelText: "Valor gasto",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (text) {
                        if (msj.length > 0) {
                          setState(() {
                            visible = false;
                            msj = "";
                            color = Colors.blueGrey;
                          });
                        }
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Visibility(
                      visible: visible,
                      child: Text(
                        "$msj",
                        style: TextStyle(color: color),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    RaisedButton(
                      onPressed: () {
                        registrarGasto();
                      },
                      child: Text("Guardar gasto"),
                    ),
                  ],
                ),
              ),
              Container(
                height: 100,
                padding: EdgeInsets.only(
                  top: 30,
                ),
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: diasmes == null ? 0 : diasmes.length,
                    itemBuilder: (context, index) {
                      if (diasmes == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = diasmes[index];
                        return InkWell(
                          onTap: () {
                            diaseleccionado = item['dia'];
                            anioseleccionado = item['anio'];
                            leergastoDia();
                          },
                          child: SizedBox(
                            width: 120,
                            height: 50,
                            child: Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: diaseleccionado == item['dia'] &&
                                            anioseleccionado == item['anio']
                                        ? Colors.lightBlue
                                        : Colors.blueGrey),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                " ${item['dia']}/${item['mes']}/${item['anio']}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }
                    }),
              ),
              SizedBox(
                height: 20,
              ),
              ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: gastodia == null ? 0 : gastodia.length,
                  itemBuilder: (context, index) {
                    if (gastodia == null) {
                      return CircularProgressIndicator();
                    } else {
                      final item = gastodia[index];
                      print("diashoy $diahoy itemdia ${item['dia']}");
                      return ListTile(
                        title: Text("${item['valor']} ${item['gasto']}"),
                        subtitle: Text("Hora ${item['hora']}"),
                        leading: Icon(Icons.shopping_cart),
                        trailing: int.parse(diahoy) ==
                                int.parse(item['dia'].toString())
                            ? InkWell(
                                onTap: () {
                                  eliminarGasto(item);
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            : null,
                      );
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void registrarGasto() async {
    String motivogasto = txtgasto.text;
    String valorgasto = txtvalor.text;
    String fecha = fechaActual();
    List fech = fecha.split("/");
    String dia = fech[0];
    String mes = fech[1];
    String anio = fech[2];
    String hora = horaActual();

    if (motivogasto.length <= 0) {
      setState(() {
        msj = "Escriba el motivo de gasto";
        color = Colores.naranja;
        visible = true;
      });
      return;
    } else if (valorgasto.length <= 0) {
      setState(() {
        msj = "Escriba el valor del gasto";
        color = Colores.naranja;
        visible = true;
      });
      return;
    }

    motivogasto = primeraLetraMayuzcula(motivogasto);

    int id;
    Database database = await opendb();
    await database.transaction((txn) async {
      id = await txn.rawInsert(
          'INSERT INTO gastos(gasto, valor,dia,mes,anio,hora) VALUES(?,?,?,?,?,?)',
          [motivogasto, valorgasto, dia, mes, anio, hora]);
      print('insertado: gasto:$motivogasto $valorgasto');
    });
    await database.close();
    setState(() {
      msj = "Registro del gasto exitoso";
      color = Colores.verde;
      visible = true;
      txtgasto.text = "";
      txtvalor.text = "";
    });
    await leergastoMes();
    String tipo = "gasto";
    String movimiento = "$motivogasto";
    String capital = "0";
    String interes = "0";
    String porcentaje = "0";
    await agregarResumenDia(tipo, movimiento, valorgasto, capital, interes,
        porcentaje, id.toString());
  }

  Future<Map> leergastoMes() async {
    String fecha = fechaActual();
    List valor = fecha.split("/");
    String dia = valor[0];
    String mes = valor[1];
    String anio = valor[2];

    diahoy = dia;
    diaseleccionado = dia;
    anioseleccionado = anio;

    Database database = await opendb();
    List<Map> list = await database.rawQuery(
        "SELECT * FROM gastos WHERE mes =? and anio=? ORDER BY id DESC",
        [mes, anio]);
    await database.close();

    gastodia = new List();
    diasmes = new List();

    String diaya = "";
    await Future.forEach(list, (gasto) {
      String id = gasto['id'].toString();
      String day = gasto['dia'].toString();
      String anio = gasto['anio'].toString();

      if (day != diaya) {
        diasmes.add({"id": id, "dia": day, "mes": mes, "anio": anio});
        diaya = day;
      }
      if (day == dia) {
        gastodia.add(gasto);
      }
    });

    setState(() {});
  }

  Future<Map> leergastoDia() async {
    String fecha = fechaActual();
    List valor = fecha.split("/");
    //String dia = valor[0];
    String dia = diaseleccionado;
    String mes = valor[1];
    String anio = anioseleccionado;

    Database database = await opendb();
    List<Map> list = await database
        .rawQuery("SELECT * FROM gastos WHERE mes =? AND anio=?", [mes, anio]);
    await database.close();

    gastodia = new List();

    String diaya = "";
    await Future.forEach(list, (gasto) {
      String day = gasto['dia'].toString();

      if (day == dia) {
        gastodia.add(gasto);
      }
    });

    setState(() {});
  }

  void eliminarGasto(Map gasto) async {
    String id = gasto['id'].toString();
    Database database = await opendb();
    int count =
        await database.rawDelete('DELETE FROM gastos WHERE id = ?', [id]);
    await database.close();
    print("id $count gasto eliminado");

    await leergastoDia();

    String tipo = "eliminogasto";
    String movimiento =
        "elimino ${gasto['gasto']} del ${gasto['dia']}/${gasto['mes']}/${gasto['anio']} ";
    String valor = gasto['valor'];
    String capital = "0";
    String interes = "0";
    String porcentaje = "0";
    await agregarResumenDia(
        tipo, movimiento, valor, capital, interes, porcentaje, id.toString());
  }
}

class Apariencias extends StatefulWidget {
  @override
  _AparienciasState createState() => _AparienciasState();
}

class _AparienciasState extends State<Apariencias> with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = new TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      print("click ${_tabController.index}");
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Apariencia"),
        bottom: TabBar(
          unselectedLabelColor: Colors.white,
          labelColor: Colors.amber,
          tabs: [
            new Tab(icon: new Icon(Icons.list)),
            new Tab(
              icon: new Icon(Icons.receipt),
            ),
            new Tab(
              icon: new Icon(Icons.content_paste),
            )
          ],
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        bottomOpacity: 1,
      ),
      body: TabBarView(
        children: [
          new Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Text("Apariencia de las lista de clientes"),
                  SizedBox(
                    height: 30,
                  ),
                  Material(
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Diseño uno",
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                                left: 10, top: 5, right: 10, bottom: 5),
                            child: ListTile(
                              title: Text('NOMBRE DEL CLIENTE',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.0)),
                              subtitle: Text('Direccion del cliente',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12.0)),
                              leading: Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  color: Colors.green,
                                ),
                                child: SizedBox(
                                  width: 25,
                                  height: 25,
                                ),
                              ),
                              trailing: Icon(
                                Icons.alarm,
                                color: Colors.deepOrange,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Diseño dos",
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                                left: 10, top: 5, right: 10, bottom: 5),
                            child: Material(
                              elevation: 1.0,
                              borderRadius: BorderRadius.circular(10),
                              shadowColor: Color(0x802196F3),
                              color: Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ListTile(
                                      title: Text('NOMBRE DEL CLIENTE',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20.0)),
                                      subtitle: Text('Direccion del cliente',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0)),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)),
                                          color: Colors.green,
                                        ),
                                        child: SizedBox(
                                          width: 25,
                                          height: 25,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.alarm,
                                        color: Colors.deepOrange,
                                        size: 50,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          new Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Text("Apariencia de los recibos"),
                ],
              ),
            ),
          ),
          new Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Text("Apariencia de la ventana de pagos"),
                ],
              ),
            ),
          ),
        ],
        controller: _tabController,
      ),
    );
  }
}

class AjustresEmpresa extends StatefulWidget {
  @override
  _AjustresEmpresaState createState() => _AjustresEmpresaState();
}

class _AjustresEmpresaState extends State<AjustresEmpresa> {

  final txtnombreempresa = TextEditingController();
  final txttelefonoempresa = TextEditingController();
  final txtsimbolodemoneda = TextEditingController();
  final txtnombrepropietario = TextEditingController();

  String msj = "";
  bool visible = false;

  @override
  void initState() {
    this.leerInformacion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajustes empresa"),
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                child: TextField(
                  controller: txtnombreempresa,
                  decoration: InputDecoration(
                    labelText: "Nombre empresa",
                  ),
                ),
              ),
              Container(
                child: TextField(
                  controller: txttelefonoempresa,
                  decoration: InputDecoration(
                    labelText: "Telefono empresa",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Container(
                child: TextField(
                  controller: txtsimbolodemoneda,
                  decoration: InputDecoration(
                    labelText: "Simbolo de moneda",
                  ),
                ),
              ),
              Container(
                child: TextField(
                  controller: txtnombrepropietario,
                  decoration: InputDecoration(
                    labelText: "Nombre propietario",
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Visibility(
                visible: visible,
                child: Text("$msj"),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                child: RaisedButton(
                  onPressed: () {
                    guradarInformacion();
                  },
                  child: Text("Guardar informacion"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void leerInformacion() async {

    String nombreempresa = "";
    String telefonoempresa = "";
    String simbolomoneda = "";
    String nombrepropietario = "";

    List<Map> lista = await getInfo();
    await Future.forEach(lista, (item) {
      String name = item['nombre'];
      String valor = item['valor'];
      if(name=="nombreempresa"){
        nombreempresa = valor;
      }else if(name=="telefonoempresa"){
        telefonoempresa = valor;
      }else if(name=="simbolomoneda"){
        simbolomoneda = valor;
      }else if(name=="nombrepropietario"){
        nombrepropietario = valor;
      }
    });

    if (nombreempresa == "") nombreempresa = "*";
    if (telefonoempresa == "") telefonoempresa = "*";
    if (simbolomoneda == "") simbolomoneda = "\$";
    if (nombrepropietario == "") nombrepropietario = "*";

    txtnombreempresa.text = nombreempresa;
    txttelefonoempresa.text = telefonoempresa;
    txtsimbolodemoneda.text = simbolomoneda;
    txtnombrepropietario.text = nombrepropietario;

    setState(() {});
  }

  void guradarInformacion() async {

    String nombreempresa = txtnombreempresa.text.trim();
    String telefonoempresa = txttelefonoempresa.text.trim();
    String simbolomoneda = txtsimbolodemoneda.text.trim();
    String nombrepropietario = txtnombrepropietario.text.trim();

    if (nombreempresa == "_" || nombreempresa == "") nombreempresa = "PrestaGroonS";
    if (telefonoempresa == "_" || telefonoempresa == "") telefonoempresa = "3504706990";
    if (simbolomoneda == "_" || simbolomoneda == "") simbolomoneda = "\$";
    if (nombrepropietario == "_" || nombrepropietario == "") nombrepropietario = "GroonS";

    nombrepropietario = primeraLetraMayuzcula(nombrepropietario);

    /*await setLocal("nombreempresa", nombreempresa);
    await setLocal("telefonoempresa", telefonoempresa);
    await setLocal("simbolomoneda", simbolomoneda);
    await setLocal("nombrepropietario", nombrepropietario);*/

    List<Map> lista = await getInfo();
    await setInfo("nombreempresa", nombreempresa);
    await setInfo("telefonoempresa", telefonoempresa);
    await setInfo("simbolomoneda", simbolomoneda);
    await setInfo("nombrepropietario", nombrepropietario);
    /*if(lista==null){
      await agregarTabla("CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)");
    }else{
      await setInfo("nombreempresa", nombreempresa);
      await setInfo("telefonoempresa", telefonoempresa);
      await setInfo("simbolomoneda", simbolomoneda);
      await setInfo("nombrepropietario", nombrepropietario);
    }*/
    msj = "Datos actualizados exitosamente ${horaActual()}";
    visible = true;
    //print("lista: $lista");

    leerInformacion();
  }
}

class borrardb extends StatefulWidget {
  @override
  _borrardbState createState() => _borrardbState();
}

class _borrardbState extends State<borrardb> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gastos")),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              child: Text(
                  "Si borra la base de datos se eliminan clientes, gastos, balances, etc, se limpia todo, Borrar base de datos?"),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              child: RaisedButton(
                onPressed: () {
                  setState(() {
                    visible = true;
                  });
                },
                child: Text("Borrar base de datos"),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Visibility(
              visible: visible,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: Colores.gris)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Borrar base de datos",
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      "Esto dejara todo limpio en su telefono",
                      style: TextStyle(color: Colors.orange),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        OutlineButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Cancelar"),
                        ),
                        OutlineButton(
                          onPressed: () {
                            borrarDB();
                            Flushbar(
                              message: "Se borro la base de datos",
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            )..show(context);
                          },
                          child: Text(
                            "Borrar",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportarPrestaCOP extends StatefulWidget {
  @override
  _ImportarPrestaCOPState createState() => _ImportarPrestaCOPState();
}

class _ImportarPrestaCOPState extends State<ImportarPrestaCOP> {
  bool importodb = false;
  bool importodbpagos = false;
  bool importoclientes = false;
  bool importobalances = false;

  bool visibleclientes = true;
  bool visiblepagos = false;
  bool visibleimportoclientes = false;
  bool visibleordenobalances = false;
  bool visibleimportobalances = false;
  bool visibleexitoso = false;

  String msj = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Importar de PrestaCOP"),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      children: <Widget>[
                        importodb
                            ? Icon(
                                Icons.check,
                                color: Colors.blue,
                              )
                            : SizedBox(),
                        Container(
                          child: Text(
                            "Clientes",
                            style: TextStyle(
                                color:
                                    importodb ? Colors.blue : Colors.black12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      children: <Widget>[
                        importodbpagos
                            ? Icon(
                                Icons.check,
                                color: Colors.blue,
                              )
                            : SizedBox(),
                        Container(
                          child: Text(
                            "Pagos",
                            style: TextStyle(
                                color: importodbpagos
                                    ? Colors.blue
                                    : Colors.black12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      children: <Widget>[
                        importoclientes
                            ? Icon(
                                Icons.check,
                                color: Colors.blue,
                              )
                            : SizedBox(),
                        Container(
                          child: Text(
                            "Importados",
                            style: TextStyle(
                                color: importoclientes
                                    ? Colors.blue
                                    : Colors.black12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 10),
                    child: Column(
                      children: <Widget>[
                        importobalances
                            ? Icon(
                                Icons.check,
                                color: Colors.blue,
                              )
                            : SizedBox(),
                        Container(
                          child: Text(
                            "Balances",
                            style: TextStyle(
                                color: importobalances
                                    ? Colors.blue
                                    : Colors.black12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
              ),
              Visibility(
                visible: visibleclientes,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Importar la base de datos de clientes admin.db"),
                      OutlineButton(
                        onPressed: () {
                          buscardb();
                        },
                        child: Text("Importar admin.db"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: visiblepagos,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Importar la base de datos de pagos pagos.db"),
                      OutlineButton(
                        onPressed: () {
                          buscardbpagos();
                        },
                        child: Text("Importar pagos.db"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: visibleimportoclientes,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Agregar clientes y pagos a PrestaGroonS"),
                      OutlineButton(
                        onPressed: () {
                          addclientesCOP();
                        },
                        child: Text("Agregar clientes"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: visibleordenobalances,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Ordenar los balances"),
                      OutlineButton(
                        onPressed: () {
                          ordenarbalancesCOP();
                        },
                        child: Text("Ordenar los balances"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: visibleimportobalances,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          "Importar los balances, se importaran los balances existentes de cobro, pagos, caja, gastos"),
                      OutlineButton(
                        onPressed: () {
                          pasarbalancescopaGroons();
                        },
                        child: Text("Importar balances"),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Visibility(
                visible: visibleexitoso,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Importaciones exitosas"),
                      Text(
                          "Tus importacion fueron exitosas, los clientes, pagos y balances deben aparecer bien")
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                child: Text(
                  "$msj",
                  style: TextStyle(fontSize: 10),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Flushbar> buscardb() async {

    /*FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db',],
    );*/
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String pathlocal = result.files.single.path;
      File file = File(result.files.single.path);

      var pathdb = await getPathDB();
      var path = p.join(pathdb, "admincop.db");
      File newfile = new File('$pathlocal');
      var copy = await newfile.copy(path);

      importodb = true;
      visibleclientes = false;
      visiblepagos = true;

      setState(() {
        msj = "admin.db importado exitoso";
      });

      return Flushbar(
        message: "Importado exitoso",
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      )..show(this.context);
    }
  }

  Future<Flushbar> buscardbpagos() async {

    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String pathlocal = result.files.single.path;
      File file = File(result.files.single.path);

      var pathdb = await getPathDB();
      var path = p.join(pathdb, "pagoscop.db");
      File newfile = new File('$pathlocal');
      var copy = await newfile.copy(path);

      visiblepagos = false;
      visibleimportoclientes = true;
      importodbpagos = true;

      setState(() {
        msj = "pagos.db importado exitoso";
      });

      return Flushbar(
        message: "Importado exitoso",
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      )..show(this.context);
    }
  }

  addclientesCOP() async {
    var pathdb = await getPathDB();
    String pathnew = pathdb+ "/admincop.db";
    Database db = await openDatabase(pathnew);

    //codigo: 1, nombre: VIRGELINA AMADO III, cedula: 123, telefono: , cota: 20000, saldo: 0, direccion: san antonio otra virgelina de 100, cobrador: andres,
    // posicion: 141, fecha: 03/04/2018, plazo: 30, observacion: 3228225688, modalidad: Diario, diapago: 06/11/2018, reporte: null, calificacion: , cantidadprestamos: ,
    // dato1: 321600.0, dato2: 240000, dato3: A/A/, porcentaje: 20, alarma: 0, grupo: Principal, descontar_dias: 73
    List<Map> clientes = await db.rawQuery('SELECT * FROM clientes');
    //{codigo: 1, fecha: 10/07/2020, saldo: 1, entro: 6210408.56999994, salio: null, dato1: 20.0, dato2: 20.0, dato3: 3}
    List<Map> caja = await db.rawQuery('SELECT * FROM caja');

    double cajatotal = double.parse(caja[0]['entro'].toString());
    //String saldomora = caja[0]['dato1'].toString();
    String interesmora = caja[0]['dato2'].toString();
    String diasatraso = caja[0]['dato3'].toString();
    String tipointeres = caja[0]['saldo'].toString();

    String diasvencido = "0";
    String diasmora = "0/0";

    if (tipointeres == "1") {
      //solo cobra por vencido
      diasmora = "0/1";
    } else if (tipointeres == "2") {
      //solo atraso
      diasmora = "$diasatraso/0";
    } else if (tipointeres == "3") {
      //cobra ambos
      diasmora = "$diasatraso/1";
    }

    String porcentajemora = "$interesmora/$interesmora";

    await borrarTabla("clientes");
    await borrarTabla("prestamos");
    await borrarTabla("caja");
    await borrarTabla("resumendia");
    await setCaja(cajatotal.toString(), "agrego caja importado de PrestaCOP");

    int i = 0;

    await Future.forEach(clientes, (cliente) async {
      String key = Uuid().v1();
      print("key $key");

      /*if(i>50){
        print("retorno");
        return;
      }*/
      i++;

      try {
        String nombre = cliente['nombre'];
        String cedula = cliente['cedula'].toString();
        String telefono = cliente['telefono'].toString();
        String cuota = cliente['cota'].toString();
        double saldo = double.parse(cliente['saldo'].toString());
        String direccion = cliente['direccion'];
        String cobrador = cliente['cobrador'];
        String posicion = cliente['posicion'].toString();
        String fecha = cliente['fecha'];
        double plazo = double.parse(cliente['plazo'].toString());
        String observacion = cliente['observacion'];
        String modalidad = cliente['modalidad'];
        String diapago = cliente['diapago'];
        String reporte = cliente['reporte'];
        //String calificacion = cliente['calificacion'];
        String diasmoracobrado = cliente['cantidadprestamos'].toString();
        if(diasmoracobrado==""||diasmoracobrado==null);
        if (diasmoracobrado.length == 0) diasmoracobrado = "0";
        String diasmoracobrados = "${dejarSinDecimales(
            double.parse(diasmoracobrado))}/${dejarSinDecimales(
            double.parse(diasmoracobrado))}";
        print("diasmoracobrado:$diasmoracobrados");
        String mora = cliente['dato1'].toString();
        String abonomora = cliente['dato2'].toString();
        String diasnocobra = cliente['dato3'].toString();
        String porcentaje = cliente['porcentaje'].toString();
        String alarma = cliente['alarma'];
        String grupo = cliente['grupo'];
        String descontar_dias = cliente['descontar_dias'].toString();
        String oculto = "";
        if (diapago == "oculto") grupo = "oculto";
        if (diapago == "oculto") diapago = fecha;
        String pagos = await getpagosCOP(cedula);
        String diascuota = "1";
        if (modalidad == "Semanal") {
          diascuota = "7";
          plazo = plazo / 7;
        }
        if (modalidad == "Quincenal") {
          diascuota = "15";
          plazo = plazo / 15;
        }
        if (modalidad == "Mensual") {
          diascuota = "30";
          plazo = plazo / 30;
        }

        Database database = await opendb();
        await database.transaction((txn) async {
          int id = await txn.rawInsert(
              'INSERT INTO clientes(key,nombre,cedula,direccion,telefono,posicion,grupo,cupo) VALUES(?,?,?,?,?,?,?,?)',
              [
                key,
                nombre,
                cedula,
                direccion,
                telefono,
                posicion,
                grupo,
                "no"
              ]);
          print("add cliente $nombre");
        });

        if (saldo > 0) {
          await database.transaction((txn) async {
            int id = await txn.rawInsert(
                'INSERT INTO prestamos(pertenece,fecha,capital,interes,porcentajecapital,diasinterescobrado,mora,porcentajemora,diasmoracobrado,diasmora,modalidad,diascuota,interesconsecutivo,plazo,cuota,alarma,descontardias,diasnocobra,ultimopago,pagos,movimientos) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                [
                  key,
                  fecha,
                  saldo,
                  "0",
                  porcentaje,
                  plazo.toInt(),
                  "0",
                  porcentajemora,
                  "0/0",
                  diasmora,
                  modalidad,
                  diascuota,
                  "no",
                  plazo.toInt(),
                  cuota,
                  alarma,
                  descontar_dias,
                  diasnocobra,
                  diapago,
                  pagos,
                  "${fechaActual()} ${horaActual()} importado de PrestaCOP"
                ]);
            print('=> add prestamo: $nombre saldo: $saldo key $key');
          });
        }

        await database.close();

        setState(() {
          msj = "Importado: $nombre saldo: $saldo";
        });

      }catch(e){
        setState(() {
          msj = "Error: $e";
        });
      }
    });

    importoclientes = true;
    visibleimportoclientes = false;
    visibleordenobalances = true;

    setState(() {
      msj = "Clientes importados exitosos";
    });

    await db.close();
  }

  Future<String> getpagosCOP(String cedula) async {

    try {
      var pathdb = await getPathDB();
      String pathnew = pathdb + "/pagoscop.db";
      Database db = await openDatabase(pathnew);

      String pagos = "";
      List<Map> items = await db.rawQuery("SELECT * FROM a$cedula");

      if (items.length > 0) {
        await Future.forEach(items, (pago) {
          String fecha = pago['fecha'].toString();
          String abono = pago['abono'].toString();
          String saldo = pago['saldo'].toString();
          String hora = pago['hora'].toString();
          String id = pago['identificador'].toString();
          String itempago = "$fecha $hora Abono $abono $saldo $id";
          pagos = pagos + itempago + "-";
        });
      }
      await db.close();

      return pagos;
    }catch(e){
      return "";
    }
  }

  ordenarbalancesCOP() async {

    var pathdb = await getPathDB();
    String pathnew = pathdb+"/admincop.db";
    Database db = await openDatabase(pathnew);

    //codigo: 1, fecha: 05/02/2019, cobrado: 0, totalcalle: 46479000, prestamos: 0, gastos: 0, otro: 13908851.3333331, dato1: 0, dato2: 10858000, dato3: null
    List<Map> balances = await db.rawQuery('SELECT * FROM balancesrecogidos');

    await crearTablabalance();
    await limpiarBalances();

    await Future.forEach(balances, (balance) async {

      var pathdb = await getPathDB();
      String pathnew = pathdb+"/admincop.db";
      Database db = await openDatabase(pathnew);

      String fecha = balance['fecha'].toString();
      if(fecha==""||fecha==null){
        fecha = fechaActual();
      }
      List valor = fecha.split("/");
      int dia = int.parse(valor[0].toString());
      int mes = int.parse(valor[1].toString());
      int anio = int.parse(valor[2].toString());
      String cobrado = balance['cobrado'].toString();
      String dinerocalle = balance['totalcalle'].toString();
      String valorprestado = balance['prestamos'].toString();
      String gastos = balance['gastos'].toString();
      String pagos = balance['dato1'].toString();
      String caja = balance['otro'].toString();

      List<Map> list = await db.rawQuery('SELECT * FROM balance WHERE dia=? AND mes=? AND anio=?', [dia, mes, anio]);

      if (list.length > 0) {
        String id = list[0]['id'].toString();
        String cobrad = list[0]['cobrado'].toString();
        String pags = list[0]['pagos'].toString();
        String presta = list[0]['prestado'].toString();
        print(
            "=> deberia sumar balance $fecha cob:$cobrado pag:$pagos a (cob$cobrad pags:$pags)");
        if (double.parse(cobrado) < double.parse(cobrad)) {
          int count = await db.rawUpdate(
              'UPDATE balance SET cobrado=?,prestamos=?,pagos=?,gastos=?,caja=? WHERE id = ?',
              [cobrado, valorprestado, pagos, gastos, caja, id]);
          print(
              "=> add $fecha cob:$cobrado pag:$pagos a (cob$cobrad pags:$pags)");
        }
      } else if (double.parse(cobrado) > 0) {
        await db.transaction((txn) async {
          int id = await txn.rawInsert(
              'INSERT INTO balance(dia, mes, anio, cobrado,prestamos,pagos,gastos,caja,calle) VALUES(?,?,?,?,?,?,?,?,?)',
              [
                dia,
                mes,
                anio,
                cobrado,
                valorprestado,
                pagos,
                gastos,
                caja,
                dinerocalle
              ]);
          print("add balance $id");
        });
      }

      setState(() {
        msj = "Balance: $fecha ordenado";
      });

      await db.close();
    });

    visibleordenobalances = false;
    visibleimportobalances = true;

    setState(() {
      msj = "balances ordenados";
    });

    await db.close();
  }

  pasarbalancescopaGroons() async {

    var pathdb = await getPathDB();
    String pathnew = pathdb+"/admincop.db";
    Database db = await openDatabase(pathnew);

    //codigo: 1, fecha: 05/02/2019, cobrado: 0, totalcalle: 46479000, prestamos: 0, gastos: 0, otro: 13908851.3333331, dato1: 0, dato2: 10858000, dato3: null
    List<Map> balances = await db.rawQuery('SELECT * FROM balance ORDER BY anio ASC, mes ASC, dia ASC');

    await borrarTabla("balances");

    await Future.forEach(balances, (balance) async {
      int dia = int.parse(balance['dia'].toString());
      int mes = int.parse(balance['mes'].toString());
      int anio = int.parse(balance['anio'].toString());
      String cobrado = balance['cobrado'].toString();
      String capital = "0";
      String interes = "0";
      String ganancia = "0";
      String dinerocalle = balance['calle'].toString();
      String clientesnuevos = "0";
      String numeroprestamos = "0";
      String valorprestado = balance['prestamos'].toString();
      String pagos = balance['pagos'].toString();
      String mora = "0";
      String impresiones = "0";
      String compartidos = "0";
      String editados = "0";
      String gastos = balance['gastos'].toString();
      String caja = balance['caja'].toString();
      String movimientoscaja = "*movimientos de la caja";
      String movimientosdia = "*movimientos del dia";

      Database database = await opendb();
      List<Map> list = await database.rawQuery(
          'SELECT * FROM balances WHERE dia=? AND mes=? AND anio=?',
          [dia, mes, anio]);

      if (list.length > 0) {
        String id = list[0]['id'].toString();
        String cobrad = list[0]['cobrado'].toString();
        String pags = list[0]['pagos'].toString();
        //int count = await database.rawUpdate('INSERT balances SET cobrado=?,valorprestado=?,pagos=?,gastos=?,caja=? WHERE id = ?', [cobrado,valorprestado,pagos,gastos,caja,id]);
        print(
            "=> deberia sumar balance $dia $mes $anio cob:$cobrado pag:$pagos a (cob$cobrad pags:$pags)");
      } else {
        await database.transaction((txn) async {
          int id = await txn.rawInsert(
              'INSERT INTO balances(dia, mes, anio, cobrado,capital,interes,ganancia,dinerocalle,clientesnuevos,numeroprestamos,valorprestado,pagos,mora,impresiones,compartidos,editados,gastos,caja,movimientoscaja,movimientosdia,liquidaciones) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
              [
                dia,
                mes,
                anio,
                cobrado,
                capital,
                interes,
                ganancia,
                dinerocalle,
                clientesnuevos,
                numeroprestamos,
                valorprestado,
                pagos,
                mora,
                impresiones,
                compartidos,
                editados,
                gastos,
                caja,
                movimientoscaja,
                movimientosdia,
                ""
              ]);
          print("add balance $id");
        });
      }

      setState(() {
        msj = "Importado $dia/$mes/$anio";
      });

      await database.close();
    });

    visibleimportobalances = false;
    visibleexitoso = true;
    importobalances = true;
    setState(() {
      msj = "Todo importado exitosamente";
    });

    await db.close();
  }

  readPagosCOP() async {

    var pathdb = await getPathDB();
    String pathnew = pathdb+"/pagoscop.db";
    Database db = await openDatabase(pathnew);

    //List<Map> pagos = await db.rawQuery("SELECT * FROM pagos ORDER BY saldo DESC");
    List<Map> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    print(" tables ${tables.length}");
    //print(" tables ${tables}");

    await Future.forEach(tables, (tabla) async {
      String name = tabla['name'].toString();
      if (name == "android_metadata") return;
      if (name == "resumendia") return;
      List<Map> items = await db.rawQuery("SELECT * FROM $name");
      print("nombre = $name tabla ${items.length}");
    });

    await db.close();
  }

  void limpiarBalances() async {

    var pathdb = await getPathDB();
    String pathnew = pathdb+"/admincop.db";
    Database db = await openDatabase(pathnew);
    await db.delete("balance");
    await db.close();
    print("limpio balances ");
  }

  void crearTablabalance() async {

    var pathdb = await getPathDB();
    String pathnew = pathdb+"/admincop.db";
    Database db = await openDatabase(pathnew);
    await db.execute(
        "CREATE TABLE IF NOT EXISTS balance(id INTEGER PRIMARY KEY, dia TEXT,mes TEXT,anio TEXT, cobrado TEXT, prestamos TEXT, gastos TEXT, pagos TEXT,caja TEXT, calle TEXT)");
    await db.close();
    print("tabla creada");
  }

  void exportdbcop() async {
    File file;
    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admincop.db");
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
    await file.copy('$pathdirectorio/admincop.db');
    print("copia db exitosa $pathdirectorio");
  }
}

class EditarResumenDia extends StatefulWidget {
  @override
  _EditarResumenDiaState createState() => _EditarResumenDiaState();
}

class _EditarResumenDiaState extends State<EditarResumenDia> {

  String msj = "";
  List<Map> resumenDia = new List();

  @override
  void initState() {
    this.getResumenDia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              SizedBox(height: 20,),
              Text("$msj"),
              ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: resumenDia == null ? 0 : resumenDia.length,
                  itemBuilder: (context,index){
                    if (resumenDia.length == 0) {
                      return CircularProgressIndicator();
                    } else {
                      final item = resumenDia[index];
                      //print("diashoy $diahoy itemdia ${item['dia']}");
                      return ListTile(
                        onTap: (){
                          //Navigator.push(context, MaterialPageRoute(builder: (context)=>HacerPagos(item['key'],item['nombre'])));
                        },
                        title: Text("${item['tipo']} "),
                        subtitle: Text("${item['movimiento']}"),
                        leading: Text("${item['id']}"),
                        trailing: InkWell(
                          onTap: (){
                            this.dialogEliminar(item);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.delete,color: Colors.red,),
                          ),
                        ),
                      );
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  getResumenDia()async{
    Database database = await opendb();
    List<Map> resumendia = await database.rawQuery("SELECT * FROM resumendia");
    await database.close();

    resumenDia.clear();

    if(resumendia.length>0){
      await Future.forEach(resumendia, (dia) {

        //print("dia:$dia");
        String id = dia['id'].toString();
        String fecha = dia['fecha'].toString();
        String hora = dia['hora'].toString();
        String tipo = dia['tipo'].toString();
        String movimiento = dia['movimiento'].toString();
        double valor = double.parse(dia['valor'].toString());
        String modo = dia['modo'].toString();
        double capitalL = double.parse(dia['capital'].toString());
        double interesL = double.parse(dia['interes'].toString());
        double porcentaje = double.parse(dia['porcentaje'].toString());
        String idref = dia['idref'].toString();


        String enter = "\n";
        String movi = "*$tipo $fecha $hora $movimiento $valor $porcentaje";

        Map movimien = {"id":id,"tipo":tipo,"movimiento":movimiento};
        resumenDia.add(movimien);

      });

    }else{
      print("No hay resumendia");
      //resumen = getResumenVacio();
    }

    setState(() {

    });
  }

  dialogEliminar(Map item)async{

    var baseDialog = BaseAlertDialog(
      title: Text("ELIMINAR RESUMEN",style: TextStyle(color: Colors.red),),
      content: Text("Se eliminara el resumen (id: ${item['id']} tipo: ${item['tipo']})",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("ELIMINAR",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        this.eliminarResumen(item);
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);

  }

  void eliminarResumen(Map item)async{

    String id = item['id'];
    String tipo = item['tipo'];

    Database database = await opendb();
    int count = await database.rawDelete('DELETE FROM resumendia WHERE id = ?', [id]);
    await database.close();

    if(count==1){
      await agregarResumenDia("borroresumen", "elimino el resumen $tipo id: $id", "0", "0", "0", "0", "0");
      Flushbar(message: "Resumen eliminado $tipo",duration: Duration(seconds: 4),backgroundColor: Colors.red,).show(context);
      this.getResumenDia();
    }

  }
}

//codigo de ejemplo modal abajo

void _settingModalBottomSheet(context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          child: new Wrap(
            children: <Widget>[
              Card(
                shape: OutlineInputBorder(),
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Datos del cliente",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: EdgeInsets.only(),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Nombre",
                            icon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Direccion",
                            icon: Icon(Icons.home),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Telefono",
                            icon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      });
}

//codigo de desbloquo por huella o fracial o codigo
class Unlock extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<Unlock> {
  var _textToShow = 'Hidden Text';
  var _btnText = 'Show';
  DeviceUnlock deviceUnlock;

  @override
  void initState() {
    super.initState();
    deviceUnlock = DeviceUnlock();
  }

  void pressedButton() async {
    if (_btnText == 'Oculto') {
      setState(() {
        _textToShow = 'Hidden Text';
        _btnText = 'Show';
      });
    } else {
      var unlocked = false;

      /*try {
        if (await deviceUnlock.request(localizedReason: "Necesitamos verificar su identidad.")) {
          // Desbloqueado con éxito.
        } else {
          // No pasó la validación de cara, toque o pin.
        }
      } on RequestInProgress {
        // Se envió una nueva solicitud antes de que finalice la primera.
      } on DeviceUnlockUnavailable {
        // El dispositivo no tiene seguridad de cara, táctil o pin disponible.
      }*/

      try {
        unlocked = await deviceUnlock.request(
          localizedReason:
              "Necesitamos verificar sus credenciales para permitirle ver el texto oculto",
        );
      } on DeviceUnlockUnavailable {
        unlocked = true;
      } on RequestInProgress {
        unlocked = true;
      }

      if (unlocked) {
        setState(() {
          _textToShow = 'Texto secreto ahora disponible';
          _btnText = 'Oculto';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock example app'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_textToShow),
            Container(
              margin: EdgeInsets.only(top: 50),
              child: FlatButton(
                child: Text(_btnText),
                color: Colors.blue,
                onPressed: pressedButton,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Carroussel extends StatefulWidget {
  @override
  _CarrousselState createState() => new _CarrousselState();
}

class _CarrousselState extends State<Carroussel> {
  PageController controller;
  int currentpage = 0;

  @override
  initState() {
    super.initState();
    controller = new PageController(
      initialPage: currentpage,
      keepPage: false,
      viewportFraction: 0.5,
    );
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Container(
          child: new PageView.builder(
              onPageChanged: (value) {
                setState(() {
                  currentpage = value;
                });
              },
              controller: controller,
              itemBuilder: (context, index) => builder(index)),
        ),
      ),
    );
  }

  builder(int index) {
    return new AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = 1.0;
        if (controller.position.haveDimensions) {
          value = controller.page - index;
          value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
        }

        return new Center(
          child: new SizedBox(
            height: Curves.easeOut.transform(value) * 300,
            width: Curves.easeOut.transform(value) * 250,
            child: child,
          ),
        );
      },
      child: new Container(
        margin: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? Colors.blue : Colors.red,
      ),
    );
  }
}

//carrusel
/*
class carrusel extends StatefulWidget {
  @override
  _carruselState createState() => _carruselState();
}

class _carruselState extends State<carrusel> {
  List items = ["A", "B", "c", "d"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          CarouselSlider.builder(
            itemCount: 15,
            itemBuilder: (BuildContext context, int itemIndex) => Container(
              color: Colors.blueAccent,
              width: double.infinity,
              child: Text(
                itemIndex.toString(),
              ),
            ),
            options: CarouselOptions(
              height: 200,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 5),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                print("click $index reason $reason");
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
        ],
      ),
    );
  }
}
 */

//impresion solo android
class MyApp2 extends StatefulWidget {
  @override
  _MyAppState2 createState() => _MyAppState2();
}

class _MyAppState2 extends State<MyApp2> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  bool conceted = false;
  List items = new List();

  Future<void> getBluetoots()async{
    final List bluetooths = await PrintBluetoothThermal.getBluetooths;
    print("impresion $bluetooths");
    setState(() {
      items = bluetooths;
    });
  }

  Future<void> setConectar(String mac)async{
    final String result = await PrintBluetoothThermal.conectar(mac);
    print("impresion $result");
    if(result=="true") conceted = true;
    setState(() {

    });

  }

  Future<void> imprimirTicket()async{
    Ticket ticket = await reciboPrueba();
    final result = await PrintBluetoothThermal.writeBytes(ticket.bytes);
    print("impresion $result");
  }

  Future<void> imprimirTextoPersonalizado()async{
    String size1 = "1/Impresora térmica ñ \n *";
    String size2 = "2/Impresora térmica ñ \n ";
    String size3 = "3/Impresora térmica ñ \n *";
    String size4 = "4/Impresora térmica ñ \n *";
    String size5 = "5/Impresora térmica ñ \n *";
    final result1 = await PrintBluetoothThermal.writeText(size1);
    final result2 = await PrintBluetoothThermal.writeText(size2);
    final result3 = await PrintBluetoothThermal.writeText(size3);
    final result4 = await PrintBluetoothThermal.writeText(size4);
    final result5 = await PrintBluetoothThermal.writeText(size5);
    //print("impresion $result");
  }

  Future<Ticket> reciboPrueba()async{

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    ticket.text('Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    ticket.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ', styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('Special 2: blåbærgrød', styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('Special 3: Impresora térmica ñ', styles: PosStyles(codeTable: 'CP1252'));

    ticket.text('Bold text', styles: PosStyles(bold: true));
    ticket.text('Reverse text', styles: PosStyles(reverse: true));
    ticket.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    ticket.text('Align left', styles: PosStyles(align: PosAlign.left));
    ticket.text('Align center', styles: PosStyles(align: PosAlign.center));
    ticket.text('Align right', styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    ticket.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    ticket.text('Text size 200%', styles: PosStyles(
      height: PosTextSize.size2,
      width: PosTextSize.size2,
    ));

    // Print image:
    final ByteData data = await rootBundle.load('assets/logo.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final Imag.Image imagen = Imag.decodeImage(bytes);
    ticket.image(imagen);
    // Print image using an alternative (obsolette) command
    // ticket.imageRaster(image);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    ticket.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // ticket.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    //ticket.feed(2);

    ticket.cut();

    return ticket;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Running on: $_platformVersion\n'),
              Text("Buscar bluetooth vinculados"),
              OutlineButton(
                onPressed: (){
                  this.getBluetoots();
                },
                child: Text("Buscar"),
              ),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: items.length>0?items.length:0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: (){
                        String select = items[index];
                        List lista = select.split("#");
                        String name = lista[0];
                        String mac = lista[1];
                        this.setConectar(mac);
                      },
                      title: Text('${items[index]}'),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 30,
              ),
              OutlineButton(
                onPressed: conceted? this.imprimirTicket:null,
                child: Text("Imprimir ticket"),
              ),
              OutlineButton(
                onPressed: conceted?this.imprimirTextoPersonalizado:null,
                child: Text("Imprimir texto"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//progreso descargar
class descargaprogreso extends StatefulWidget {
  @override
  _descargaprogresoState createState() => _descargaprogresoState();
}

class _descargaprogresoState extends State<descargaprogreso> {


  String msj = "";
  String url = baseurl + "descargas.php";
  //String url = "https://upload.wikimedia.org/wikipedia/commons/f/ff/Pizigani_1367_Chart_10MB.jpg";
  //descargar con progreso
  int _total = 0, _received = 0;
  http.StreamedResponse _response;
  File _image;
  List<int> _bytes = [];

  Future<void> _downloadImage() async {

    String idruta = await getLocal("idruta");
    String ruta = await getLocal("ruta");
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String nombre = "admin.db";
    var data = {
      "iduser": iduser,
      "token": token,
      "idruta": idruta,
      "nombre": nombre,
    };


    final request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(data);
    _response = await http.Client().send(request);
    _total = _response.contentLength;
    print("total $_total");
    _response.stream.listen((value) {
      setState(() {
        _bytes.addAll(value);
        _received += value.length;
      });
    }).onDone(() async {
      print("descargo byetes lentg ${_bytes.length}");
      var pathdb = await getPathDB();
      var path = p.join(pathdb, "admin.db");
      await deleteDatabase(path);
      int totalbytes = _bytes.length;
      if (totalbytes > 10000) {
        await new File(path).writeAsBytes(_bytes, flush: true);
        setState(() {
          msj = "Descargado exitoso: $totalbytes bytes";
        });
      } else {
        setState(() {
          msj = "Fallido no hay copias de esta empresa: $totalbytes bytes";
        });
      }
      //final file = File("${(await getApplicationDocumentsDirectory()).path}/image.png");
      //await file.writeAsBytes(_bytes);
      setState(() {
        //_image = file;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(msj),
            FloatingActionButton.extended(
              label: _bytes.length>0?Text("${_received ~/ 1024}/${_total ~/ 1024} KB"):Text("Descargar"),
              icon: Icon(Icons.file_download),
              onPressed: _downloadImage,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: SizedBox.fromSize(
                  size: Size(100, 50),
                  child: _image == null ? Placeholder() : Image.file(_image, fit: BoxFit.fill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//progreso subir
class progresodecarga extends StatefulWidget {
  @override
  _progresodecargaState createState() => _progresodecargaState();
}

class _progresodecargaState extends State<progresodecarga> {


  String msj = "";
  String url = baseurl + "subircopia.php";
  Response response;

  Future<void> _uploadFile() async {

    String idruta = await getLocal("idruta");
    String ruta = await getLocal("ruta");
    String iduser = await getLocal("iduser");
    String token = await getLocal("token");
    String nombre = "admin.db";
    File file;

    var pathdb = await getPathDB();
    var path = p.join(pathdb, "admin.db");
    var exists = await databaseExists(path);
    if (exists) {
      file = File(path);
    } else {
      print("no existe el archivo ");
      return;
    }

    int bytes = file.lengthSync();
    String kb = dejarDosDecimales(bytes/1024);
    print("Subiendo $kb Kb idruta $idruta");

    FormData fromdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(
          file.path,
          filename: nombre,
      ),
      "nombre": "admin.db",
      "idruta": idruta,
      "token": token,
      "iduser": iduser,
    });

    /*
    String base64Image = base64Encode(file.readAsBytesSync());
    String fileName = "admin.db"; //file.path.split("/").last;
    var data = {
      "file": base64Image,
      "nombre": fileName,
      "idruta": idruta,
      "token": token,
      "iduser": iduser,
    };*/

    Dio dio = new Dio();
    response = await dio.post(
        url,
        data: fromdata,
        onSendProgress: (int sent, int total){
          String percentage = (sent/total*100).toStringAsFixed(2);
          //print("subido $sent total: $total");
          setState(() {
            msj = "$sent" + " Bytes of " "$total Bytes - " +  percentage + " % uploaded";
          });
    });
    print(response.data.toString());

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("$msj"),
            Center(
              child: RaisedButton(
                onPressed: _uploadFile,
                child: Text("subir"),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

//sin uso
class MultipartRequest extends http.MultipartRequest {
  /// Creates a new [MultipartRequest].
  MultipartRequest(
      String method,
      Uri url, {
        this.onProgress,
      }) : super(method, url);

  final void Function(int bytes, int totalBytes) onProgress;

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = this.contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress(bytes, total);
        sink.add(data);
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}





