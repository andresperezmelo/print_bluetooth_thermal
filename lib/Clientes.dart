import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:prestagroons/CanvasRecibo.dart';
import 'package:prestagroons/Ajustes.dart';
import 'package:prestagroons/ResumenDia.dart';
import 'package:prestagroons/string.dart';
import 'package:prestagroons/meTodo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as Imag;
import 'package:http/http.dart' as http;
import 'main.dart';

String msj = 'No hay impresora conectada';
bool _connected = false;

String nombreempresa = "GroonS";
String telefonoempresa = "+57 3504706990";
String simbolomoneda = "";

class Clientes extends StatefulWidget {
  @override
  _ClientesState createState() => _ClientesState();
}

class _ClientesState extends State<Clientes> {

  ScrollController scrollController;
  bool dialVisible = true;
  List<Map> listaClientes = new List();

  actualizarLista()async{
    List<Map> map = await getClientes();
    //print("listamap $map");
    setState(() {
      listaClientes = map;
    });
  }

  @override
  void initState() {
    scrollController = ScrollController()
      ..addListener(() {setDialVisible(scrollController.position.userScrollDirection == ScrollDirection.forward);
      });
    this.actualizarLista();
    this.getDatosEmpresa();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clientes"),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.search),
              onPressed: () {
                listaClientes==null?Container():showSearch(context: context, delegate: DataSearch(listaClientes));
              }),
        ],
      ),
      floatingActionButton: menuFlotante(),
      body: ReorderableListView(
        children: listaClientes == null
            ? CircularProgressIndicator()
            : List.generate(
                listaClientes == null ? 0 : listaClientes.length,
                (index) {
                  return Container(
                    key: Key('$index'),
                    height: 160,
                    child: itemCliente(listaClientes[index]),
                  );
                }),
        onReorder: (int start, int current) {
          //print("star $start current $current");
          // arrastrando de arriba a abajo
          if (start < current) {
            int end = current - 1;
            Map startItem = listaClientes[start];
            int i = 0;
            int local = start;
            do {
              listaClientes[local] = listaClientes[++local];
              i++;
            } while (i < end - start);
            listaClientes[end] = startItem;
          }
          // arrastrando de abajo hacia arriba
          else if (start > current) {
            Map startItem = listaClientes[start];
            for (int i = start; i > current; i--) {
              listaClientes[i] = listaClientes[i - 1];
            }
            listaClientes[current] = startItem;
          }
          setState(() {
            /*lista.forEach((element) {
              print("orden: ${element.nombre}");
            });*/
          });
          ordenarClientes(listaClientes);
        },
      ),
    );
  }

  Widget itemCliente(Map item){
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
          child: Material(
            elevation: 14.0,
            borderRadius: BorderRadius.circular(10),
            shadowColor: Color(0x802196F3),
            color: Colors.white,
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HacerPagos(item['key'],item['nombre']))),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${item['nombre']}',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 20.0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text('${item['modalidad']}', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w700, fontSize:10.0)),
                          ],
                        ),
                        Material(
                          borderRadius: BorderRadius.circular(5.0),
                          color: item['prestamos']=="Unico prestamo"?Colors.green:Colors.blue,
                          child: Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Text("${item['prestamos']}", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        Divider(
                          color: Colors.white,
                          height: 10,
                        ),
                        Text('${item['direccion']} ', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16.0, top: 25),
            child: SizedBox.fromSize(
              size: Size.fromRadius(50.0),
              child: Material(
                elevation: 20.0,
                color: item['color'],
                shadowColor: item['color'],
                shape: CircleBorder(),
                child: Center(
                    child: item['alarma'] ? Icon(Icons.alarm,color: Colors.white,size: 50,) : Text("${item['saldo']}",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<Map>> getClientes() async{

    List<Map> listmapa = List();

    Database database = await opendb();
    List<Map> clientes = await database.rawQuery('SELECT * FROM clientes ORDER BY posicion ASC');
    await database.close();
    String key = "0";
    await Future.forEach(clientes, (cliente) async {

      String oculto = cliente['oculto'].toString();
      if(oculto=="oculto")return;

      key = cliente['key'].toString();
      String idcliente = cliente['id'].toString();
      String nombre = cliente['nombre'].toString();
      String direccion = cliente['direccion'].toString();
      bool alarma = false;

      //print("nombre $nombre");

      database = await opendb();
      List<Map> prest = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece =? AND capital>'0' ORDER BY id DESC", [key]);
      await database.close();
      int count = prest.length;

      //print("prestamo $prest");

      if(prest.length>0) {
        int prestamos = count - 1;
        double saldo = 0;
        String modalidad = "";
        List<Color> color;
        String letrasprestamos = "Unico prestamo";
        if (count > 1) {
          letrasprestamos = "+$prestamos prestamos";
        }
        for (int i = 0; i < count; i++) {
          Map item = prest[i];
          String id = item['id'].toString();
          modalidad = item['modalidad'].toString();
          String alarm = item['alarma'].toString();

          String sald = await verSaldo(id);
          saldo = saldo + double.parse(sald);

          color = await verColor(id);
          if (alarm == fechaActual()) {
            alarma = true;
          } else {
            if (alarm.length >= 4) {
              int diaslarma = await diasCorridos(alarm);
              if (diaslarma > 0) {
                alarma = true;
              }
            }
          }
        }

        Map map = {
          "id": idcliente,
          "key": key,
          "nombre": nombre,
          "direccion": nombre,
          "direccion": direccion,
          "saldo": dejarDosDecimales(saldo),
          "modalidad": modalidad,
          "prestamos": letrasprestamos,
          "alarma": alarma,
          "color": color[0]
        };


        listmapa.add(map);
      }

    });
    //print("finalizo cargar lista");

    return listmapa;
  }

  void registro() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroClientes("")));
  }

  void gastosopen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => gastos()));
  }

  void resumendia() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ResumenDia()));
  }

  SpeedDial menuFlotante() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      child: Icon(Icons.add),
      onOpen: () {},
      onClose: () {},
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.accessibility, color: Colors.white),
          backgroundColor: Colors.green,
          onTap: () => registro(),
          labelWidget: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                color: Colors.green,
              ),
              child: Text('Registro',style: TextStyle(color: Colors.white),),
            ),
        ),
        SpeedDialChild(
          child: Icon(Icons.bug_report, color: Colors.white),
          backgroundColor: Colors.deepOrange,
          onTap: () => resumendia(),
          labelWidget: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                color: Colors.deepOrange,
              ),
              child: Text('Resumen',style: TextStyle(color: Colors.white),),
            ),
        ),
        SpeedDialChild(
          child: Icon(Icons.shopping_cart, color: Colors.white),
          backgroundColor: Colors.blue,
          onTap: () => gastosopen(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.blue,
            ),
            child: Text('Gastos',style: TextStyle(color: Colors.white),),
          ),
        ),
      ],
    );
  }

  void setDialVisible(bool value) {
    setState(() {
      dialVisible = value;
    });
  }

  Widget buildBody() {
    return ListView.builder(
      controller: scrollController,
      itemCount: 30,
      itemBuilder: (ctx, i) => ListTile(title: Text('Item $i')),
    );
  }

  getDatosEmpresa()async{
    List<Map> lista = await getInfo();
    if(lista==null){
      //await agregarTabla("CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)");
    }else{
      await Future.forEach(lista, (item){
        String name = item['nombre'];
        String valor = item['valor'];
        print("name $name valor $valor");
        if(name=="nombreempresa"){
          nombreempresa = valor;
        }else if(name=="telefonoempresa"){
          telefonoempresa = valor;
        }else if(name=="simbolomoneda"){
          simbolomoneda = valor;
        }
      });
    }
  }

}

class DataSearch extends SearchDelegate<String> {

  final List<Map> listaClientes;

  DataSearch(this.listaClientes): super(searchFieldLabel: "Nombre o direccion");

  @override
  List<Widget> buildActions(BuildContext context) {
    //Actions for app bar
    return [IconButton(icon: Icon(Icons.clear), onPressed: () {
      query = '';
      close(context, null);
      print("limpio");
    })];
  }

  @override
  Widget buildLeading(BuildContext context) {
    //icono principal a la izquierda de la barra de aplicaciones
    return IconButton(
        icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow,
          progress: transitionAnimation,
        ),
        onPressed: () {
          close(context, null);
          print("salio");
        });
  }

  @override
  Widget buildResults(BuildContext context) {
    // mostrar algún resultado basado en la selección
    final suggestionList = listaClientes;

    /*return ListView.builder(itemBuilder: (context, index) => ListTile(
      title: Text(listaClientes[index].nombre,style: TextStyle(color: Colors.green),),
      subtitle: Text(listaClientes[index].direccion,style: TextStyle(color: Colors.green),),
    ),
      itemCount: suggestionList.length,
    );*/
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // show when someone searches for something

    final suggestionList = query.isEmpty
        ? listaClientes
        : listaClientes.where((p) => p['nombre'].contains(RegExp(query, caseSensitive: false))||p['direccion'].contains(RegExp(query, caseSensitive: false))).toList();


    return ListView.builder(itemBuilder: (context, index) => ListTile(
      onTap: () {
        Map item = suggestionList[index];
        print("selecciono ${item['nombre']}");
        close(context, null);
        Navigator.push(context, MaterialPageRoute(builder: (context) => HacerPagos(item['key'],item['nombre']),),);
      },
      trailing: Text(suggestionList[index]['grupo'],style: TextStyle(color: Colors.grey),),
      /*title: RichText(
        text: TextSpan(text: suggestionList[index].nombre.substring(0, query.length), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            children: [TextSpan(text: suggestionList[index].nombre.substring(query.length), style: TextStyle(color: Colors.blueGrey)),
            ]),
      ),*/
      title: Text(suggestionList[index]['nombre'],style: TextStyle(color: Colores.primario,fontWeight: FontWeight.bold),),
      subtitle: Text(suggestionList[index]['direccion'],style: TextStyle(color: Colors.grey),),
    ),
      itemCount: suggestionList.length,
    );
  }

}

//pagos grupos
class GrupoClientes extends StatefulWidget {
  @override
  _GrupoClientesState createState() => _GrupoClientesState();
}

class _GrupoClientesState extends State<GrupoClientes> {

  String msj = "";
  bool dialVisible = true;
  List<Map> listaGrupos;
  List<Map> listaClientesGrupo;
  List<Map> listaClientesBuscar = new List();
  int totalclientes = 0;
  String grupoSelecionado = "";
  bool cargadosclientes = true;
  double progreso = 0;
  bool conPrestamo = true;
  bool sinPrestamo = false;

  @override
  void initState() {
    this.getListaGrupos();
    this.getDatosEmpresa();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clientes"),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.search),
              onPressed: () {
                listaClientesBuscar==null?Container():showSearch(context: context, delegate: DataSearch(listaClientesBuscar));
              }),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                height: 90,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    //physics: NeverScrollableScrollPhysics(),
                    itemCount: listaGrupos == null ? 0 : listaGrupos.length,
                    itemBuilder: (context,index){
                      if (listaGrupos == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaGrupos[index];
                        return InkWell(
                          onTap: (){
                            //Navigator.push(context, MaterialPageRoute(builder: (context)=>ClientesGrupo(item['grupo'])));
                            grupoSelecionado = item['grupo'];
                            getClientesGrupo(true);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Material(
                              elevation: 5,
                              child: Container(
                                width:130,
                                margin: EdgeInsets.only(left: 10,right: 10,top: 5,bottom: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                  border: Border.all(width: 1,color: grupoSelecionado == item['grupo']?Colors.blue:Colors.black26),
                                ),
                                child: ListTile(
                                  title: Text("${item['grupo']}",style: TextStyle(fontWeight: FontWeight.bold,color: grupoSelecionado == item['grupo']?Colors.blue:Colors.black),),
                                  subtitle: Text("Clientes ${item['total']}",style: TextStyle(color: grupoSelecionado == item['grupo']?Colors.blue:Colors.black),),
                                ),
                              ),
                            )
                            ,
                          ),
                        );
                      }
                    }),
              ),
              Visibility(
                visible: cargadosclientes?false:true,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: LiquidCircularProgressIndicator(
                          value: progreso, // El valor predeterminado es 0.5
                          valueColor: AlwaysStoppedAnimation(Colores.secundario), //El valor predeterminado es accentColor del tema actual.
                          backgroundColor: Colors.white, // Por defecto es backgroundColor del tema actual.
                          borderColor: Colores.secundario,
                          borderWidth: 2.0,
                          direction: Axis.vertical, //La dirección en que se mueve el líquido (Axis.vertical = de abajo hacia arriba, Axis.horizontal = de izquierda a derecha). El valor predeterminado es Axis.vertical.
                          center: Text("Cargando...",style: TextStyle(color: Colors.black12),),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: cargadosclientes,
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 10,),
                    Text("$msj",style: TextStyle(fontSize: 12),),
                    Visibility(
                      visible: grupoSelecionado.length>0?true:false,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            RaisedButton.icon(
                              label: Text("Con saldo"),
                              icon: conPrestamo ? Icon(Icons.check_circle) : Icon(Icons.close),
                              onPressed: () {
                                getClientesGrupo(true);
                              },
                              color: conPrestamo ? Colors.blue : Colors.white,
                              textColor: conPrestamo ? Colors.white : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: conPrestamo ?Colors.blue:Colors.white),
                              ),
                            ),
                            RaisedButton.icon(
                              label: Text("Sin saldo"),
                              icon: sinPrestamo ? Icon(Icons.check_circle) : Icon(Icons.close),
                              onPressed: () {
                                getClientesGrupo(false);
                              },
                              color: sinPrestamo ? Colors.blueGrey : Colors.white,
                              textColor: sinPrestamo ? Colors.white : Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: sinPrestamo ? Colors.blueGrey : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: listaClientesGrupo == null ? 0 : listaClientesGrupo.length,
                          itemBuilder: (context,index){
                            if (listaClientesGrupo == null) {
                              return SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(strokeWidth: 1,),
                              );
                            } else {
                              final item = listaClientesGrupo[index];
                              return InkWell(
                                onTap: (){
                                  int prestamos = item['totalprestamos'];
                                  Navigator.of(context).push(MaterialPageRoute(builder: (conext) => HacerPagos(item['key'], item['nombre'])));
                                  /*if(prestamos>0) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (conext) => HacerPagos(item['key'], item['nombre'])));
                              }else{
                                Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroClientes(item['cedula'])));
                              }*/
                                },
                                child: Container(
                                  margin: EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
                                  child: Material(
                                    elevation: 1.0,
                                    borderRadius: BorderRadius.circular(10),
                                    shadowColor: Color(0x802196F3),
                                    color: item['pagohoy']?Color(0xff3d5a80):Colors.white,
                                    child: Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          ListTile(
                                            title: Text('${item['nombre']}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15.0)),
                                            subtitle: Text('${item['direccion']}', style: TextStyle(color: Colors.black, fontSize: 12.0)),
                                            leading: Container(decoration:BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20)),color: item['color'][1],),child: SizedBox(width: 25,height: 25,),),
                                            trailing: item['alarma']?Icon(Icons.alarm,color: Colors.deepOrange,size: 30,):SizedBox(),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }),
                    ),
                  ],
                ),
              ),
            ],
          )
        ),
      ),
      floatingActionButton: menuFlotante(),
    );
  }

  getListaGrupos()async{

    listaGrupos = new List();
    listaClientesBuscar = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();

    totalclientes = clientes.length;
    List<Map> lista = new List();

    String fechaactual = fechaActual();
    int total = 0;
    int alarmas = 0;
    int recorrido = 0;
    String grupova = "";
    if(clientes.length>0){

      //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
      // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
      await Future.forEach(clientes, (cliente){

        String key = cliente['key'].toString();
        String grupo = cliente['grupo'].toString();
        String nombre = cliente['nombre'].toString();
        String direccion = cliente['direccion'].toString();

        if(grupova!=grupo&&total>0){
          lista.add({"grupo": grupova, "total": total});
          grupova = grupo;
          total = 1;
        }else{
          total++;
          grupova = grupo;
        }
        recorrido++;
        if(clientes.length==recorrido){
          lista.add({"grupo": grupova, "total": total});
        }

        listaClientesBuscar.add({"key":key,"nombre":nombre,"direccion":direccion,"grupo":grupo});

      });

    }else{

    }

    setState(() {
      listaGrupos = lista;
      msj = "Total $totalclientes clientes";
    });
  }

  getClientesGrupo(bool conprestamo)async{

    //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
    // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
    listaClientesGrupo = new List();
    cargadosclientes = false;
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes WHERE grupo=? ORDER BY posicion ASC",[grupoSelecionado]);
    await database.close();

    //codigo para cambiar los botones
    if(conprestamo){
      conPrestamo = true;
      sinPrestamo = false;
    }else{
      conPrestamo = false;
      sinPrestamo = true;
    }

    totalclientes = 0;
    String fechaactual = fechaActual();
    List<Map> lista = new List();
    double aumentar = 1/clientes.length;
    int recorrido = 0;
    await Future.forEach(clientes, (cliente) async {

      String id = cliente['id'].toString();
      String key = cliente['key'];
      String nombre = cliente['nombre'];
      String direccion = cliente['direccion'];
      String cedula = cliente['cedula'];
      List<Color> color;
      Color color1 = Colores.normal;
      Color color2 = Colores.normal1;
      color = [color1,color2];

      Database database = await opendb();
      List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=? AND capital>'0' ",[key]);
      await database.close();

      int totalprestamos = prestamos.length;
      bool alarma = false;
      bool pagohoy = false;

      await Future.forEach(prestamos, (prestamo)async{

        String ultimopago = prestamo['ultimopago'].toString();
        if(ultimopago==fechaactual)pagohoy=true;
        String alarm = prestamo['alarma'];
        if (alarm == fechaActual()) {
          alarma = true;
        } else {
          if (alarm.length >= 4) {
            int diaslarma = await diasCorridos(alarm);
            if (diaslarma > 0) {
              alarma = true;
            }
          }
        }
        if(conprestamo){
          if(totalprestamos>0){
            color = await verColor(prestamo['id'].toString());
          }
        }

      });

      if(conprestamo) {
        if(totalprestamos>0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "key": key,
            "totalprestamos": totalprestamos,
            "alarma": alarma,
            "cedula": cedula,
            "pagohoy": pagohoy,
            "color" : color,
          });
          totalclientes++;
        }
      }else{
        if(totalprestamos<=0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "key": key,
            "totalprestamos": totalprestamos,
            "alarma": alarma,
            "cedula": cedula,
            "pagohoy": pagohoy,
            "color" : color,
          });
          totalclientes++;
        }
      }

      recorrido++;
      setState(() {
        msj = "$nombre";
        progreso = recorrido*aumentar;
      });

    });

    setState(() {
      listaClientesGrupo = lista;
      cargadosclientes = true;
      msj = conprestamo? "Con prestamo $totalclientes clientes ($grupoSelecionado)":"Sin prestamo $totalclientes clientes ($grupoSelecionado)";
    });

  }

  SpeedDial menuFlotante() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      child: Icon(Icons.add),
      onOpen: () {},
      onClose: () {},
      visible: dialVisible,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.person_add, color: Colors.white),
          backgroundColor: Colors.green,
          onTap: () => registro(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.green,
            ),
            child: Text('Registro',style: TextStyle(color: Colors.white),),
          ),
        ),
        SpeedDialChild(
          child: Icon(Icons.bug_report, color: Colors.white),
          backgroundColor: Colors.deepOrange,
          onTap: () => resumendia(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.deepOrange,
            ),
            child: Text('Resumen',style: TextStyle(color: Colors.white),),
          ),
        ),
        SpeedDialChild(
          child: Icon(Icons.shopping_cart, color: Colors.white),
          backgroundColor: Colors.blue,
          onTap: () => gastosopen(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.blue,
            ),
            child: Text('Gastos',style: TextStyle(color: Colors.white),),
          ),
        ),
        SpeedDialChild(
          child: Icon(Icons.alarm, color: Colors.white),
          backgroundColor: Colors.deepPurpleAccent,
          onTap: () => alarmasopen(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.deepPurpleAccent,
            ),
            child: Text('Alarmas',style: TextStyle(color: Colors.white),),
          ),
        ),
        SpeedDialChild(
          child: Icon(Icons.dehaze, color: Colors.white),
          backgroundColor: Colors.amber,
          onTap: () => ordenar(),
          labelWidget: Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(50)),
              color: Colors.amber,
            ),
            child: Text('Ordenar',style: TextStyle(color: Colors.white),),
          ),
        ),
      ],
    );
  }

  void registro() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroClientes("")));
  }

  void gastosopen() {
    if(licenciaGlobal!="0"&&licenciaGlobal!="1") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => gastos()));
    }else{
      Flushbar(title: "ADQUIERE UN PLAN",message: "No disponible sin plan",backgroundColor: Colors.deepPurpleAccent,duration: Duration(seconds: 5),).show(context);
    }
  }

  void resumendia() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ResumenDia()));
  }

  void alarmasopen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Alarmas()));
  }

  void ordenar() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Ordenar()));
  }

  void getDatosEmpresa()async{
    List<Map> lista = await getInfo();
    if(lista==null){
      //await agregarTabla("CREATE TABLE info(id INTEGER PRIMARY KEY, nombre TEXT, valor TEXT)");
    }else{
      await Future.forEach(lista, (item){
        String name = item['nombre'];
        String valor = item['valor'];
        if(name=="nombreempresa"){
          nombreempresa = valor;
        }else if(name=="telefonoempresa"){
          telefonoempresa = valor;
        }else if(name=="simbolomoneda"){
          simbolomoneda = valor;
        }
        //print("name $name valor $valor");
      });

    }
  }

}

class Alarmas extends StatefulWidget {
  @override
  _AlarmasState createState() => _AlarmasState();
}

class _AlarmasState extends State<Alarmas> {

  List<Map> listaClientesAlarma = new List();
  String msj = "";

  @override
  void initState() {
    this.getClientesAlarma();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("$msj"),
              ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: listaClientesAlarma == null ? 0 : listaClientesAlarma.length,
                  itemBuilder: (context,index){
                    if (listaClientesAlarma == null) {
                      return CircularProgressIndicator();
                    } else {
                      final item = listaClientesAlarma[index];
                      return InkWell(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>HacerPagos(item['key'],item['nombre'])));
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 10,right: 10,top: 5,bottom: 5),
                          child: ListTile(
                            title: Text("${item['nombre']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colores.primario),),
                            subtitle: Text("${item['direccion']}",style: TextStyle(color: Colores.tercero),),
                            leading: Text("${item['hace']}"),
                            trailing: Text("${item['grupo']}"),
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

  void getClientesAlarma()async{

    listaClientesAlarma = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();

    List<Map> lista = new List();

    int totalclientes = clientes.length;
    int recorrido = 0;
    String fechaactual = fechaActual();
    int alarmas = 0;

    if(clientes.length>0){

      //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
      // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
      await Future.forEach(clientes, (cliente)async{

        String key = cliente['key'].toString();
        String grupo = cliente['grupo'].toString();
        String nombre = cliente['nombre'].toString();
        String direccion = cliente['direccion'].toString();

        recorrido++;
        setState(() {
          msj = "Analizando $recorrido de $totalclientes clientes (alarmas $alarmas)";
        });

        Database database = await opendb();
        List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=?",[key]);
        await database.close();

        //{id: 181, pertenece: bbeb2d30-ef9c-11ea-812e-539e91a7e193, fecha: 11/10/2019, capital: 120000, interes: 0, porcentajecapital: 20, diasinterescobrado: 30,
        // mora: 0, porcentajemora: 20.0/20.0, diasmoracobrado: 0/0, diasmora: 0/1, modalidad: Diario, diascuota: 1, interesconsecutivo: no, plazo: 30, cuota: 4000,
        // alarma: 10/12/2019, descontardias: 73, diasnocobra: A/A/, ultimopago: 11/10/2019, pagos: , movimientos: 05/09/2020 12:25:03 importado de PrestaCOP}
        await Future.forEach(prestamos, (prestamo) async{

          String alarma = prestamo['alarma'].toString();
          if(alarma==fechaactual){
            lista.add({"key":key,"nombre":nombre,"direccion":direccion,"hace":"hoy","grupo":grupo});
            alarmas++;
          }
          int diasalarma = await diasCorridos(alarma);
          if(diasalarma>0){
            lista.add({"key":key,"nombre":nombre,"direccion":direccion,"hace":"$diasalarma dias","grupo":grupo});
            alarmas++;
          }

        });

      });

    }else{

    }

    setState(() {
      listaClientesAlarma = lista;
      //msj = "";
    });

  }

}

//hacer pagos principal
class HacerPagos extends StatefulWidget {

  final String keyCliente;
  final String nombre;
  HacerPagos(this.keyCliente,this.nombre);

  @override
  _HacerPagosState createState() => _HacerPagosState();
}

class _HacerPagosState extends State<HacerPagos> {

  String key = null;
  String idprestamo = null;
  String idPrestamoFinal = "";
  String nombre = null;
  String cedula  = null;
  String direccion = null;
  String telefono = null;
  int totalprestamos = 0;
  String modo = "Cobrador";

  PageController controller;

  List<String> listacalificacion = ["*","*"];
  Color color = Colores.primario;
  int _index = 0;
  bool moviendo = false;
  Map estadoPrestamo;
  List<Map> listaPrestamos;
  Map datosPrestamosbruto;
  List<Pagos> listapagos;
  Map mapmora;

  bool _checkimprimir = true;
  bool _abonocapital = false;
  bool _checkimprimirmora = false;

  final txtabono = TextEditingController();
  final txtabonomora = TextEditingController();
  Map cancelarpago;
  Flushbar flush;

  leerPrestamosActivos(bool consaldo)async{

    cedula = await getDatoCliente(key, "cedula");
    direccion = await getDatoCliente(key, "direccion");
    telefono = await getDatoCliente(key, "telefono");

    listaPrestamos = new List();
    Database database = await opendb();
    List<Map> list;
    if(consaldo) {
      list = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece =? AND capital>'0' ORDER BY id ASC", [key]);
    }else{
      list = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece =? ORDER BY id ASC", [key]);
    }
    await database.close();
    if (list.length > 0) {
      await Future.forEach(list, (item) async {
        String id = item['id'].toString();
        Map estado = await verEstadoPrestamo(id);
        listaPrestamos.add(estado);
      });
      setState(() {
        if(idprestamo==null) {
          idprestamo = listaPrestamos[0]['id'];
          totalprestamos = list.length;
          List result = key.split("-");
          String idpres = result[0];
          idPrestamoFinal = idprestamo+idpres.toUpperCase();
        }
      });
      await actualizarestadoPrestamo();
      if(list.length>1){
        _index = 1;
        await mover();
      }
    }else{
      //no hay prestamos
    }

  }

  Future<void> mover()async  {
    if(controller!=null) {
      moviendo = true;
      await Duration(milliseconds: 1000);
      await controller.nextPage(
          duration: Duration(milliseconds: 400), curve: Curves.easeIn);
      //await Duration(seconds: 1);
      await controller.previousPage(
          duration: Duration(milliseconds: 400), curve: Curves.easeIn);
      _index = 0;
      moviendo = false;
    }
  }

  actualizarestadoPrestamo()async{

    modo = await getLocal("modo");
    Map estado = await verEstadoPrestamo(idprestamo);
    List<Color> lcolor = estado['color'];
    setState(() {
      estadoPrestamo = estado;
      mapmora = null;
      listapagos = null;
      color = lcolor[0];
      txtabono.text = estado['cuota'].toString();
    });

    await ActualizarCalificacion();
    await ActualizarMora();
    await leerPrestamoEnBruto();

  }

  leerPrestamoEnBruto()async{
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM prestamos WHERE id=?', [idprestamo]);
    await database.close();
    if(list.length>0) {
      setState(() {
        datosPrestamosbruto = list[0];
      });
    }
  }

  ActualizarMora()async{
    Map mora = await verMora(idprestamo);
    setState(() {
      mapmora = mora;
    });
  }

  ActualizarCalificacion()async{
    List<String> calificacion = await vercalificacion();
    setState(() {
      listacalificacion = calificacion;
    });
  }

  @override
  void initState() {
    key = widget.keyCliente;
    nombre = widget.nombre;
    controller = new PageController(
      initialPage: _index,
      keepPage: true,
      viewportFraction: 0.8,
    );
    estadoPrestamo = getEstadoPrestamoBlanco();
    datosPrestamosbruto = getPrestamoBlanco();
    this.leerPrestamosActivos(true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text("$nombre",style: TextStyle(color: Colores.azul),), backgroundColor: Colors.white,iconTheme: IconThemeData(color: Colores.primario),),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          child: Text("$nombre",style: TextStyle(color: Colores.azul,fontSize: 30,fontWeight: FontWeight.bold),)
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Material(
                              elevation: 10,
                              child: FlatButton(
                                onPressed: (){
                                  this.leerPrestamosActivos(false);
                                },
                                child: Text("TODOS",style: TextStyle(color: Colores.azul),),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              elevation: 10,
                              child: IconButton(
                                onPressed: (){
                                  launch("tel:$telefono");
                                },
                                icon: Icon(Icons.call,color: Colores.azul),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              elevation: 10,
                              child: FlatButton(
                                onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroClientes(cedula)));
                                },
                                child: Text("NUEVO PRESTAMO",style: TextStyle(color: Colores.azul),),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                          child: Text("${listacalificacion[0]} ${listacalificacion[1]}",style: TextStyle(color: Colores.azul,fontSize: 20,fontWeight: FontWeight.bold),)
                      ),
                      Row(
                        children: <Widget>[
                          Text("Total prestamos",style: TextStyle(color: Colores.azul,fontWeight: FontWeight.bold),),
                          SizedBox(width: 10,),
                          Text("$totalprestamos",style: TextStyle(color: Colores.azul,fontWeight: FontWeight.bold),),
                          SizedBox(width: 10,),
                        ],
                      ),
                      SizedBox(height: 10,),
                    ],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  height: 170, // card height
                  child: PageView.builder(
                      itemCount: listaPrestamos == null ? 0 : listaPrestamos.length,
                      onPageChanged: (value) {
                        setState(() {
                          if(moviendo==false) {
                            _index = value;
                            idprestamo = listaPrestamos[value]["id"];

                            List result = key.split("-");
                            String idpres = result[0];
                            idPrestamoFinal = idprestamo+idpres.toUpperCase();

                            flush != null ? flush.dismiss(true) : null;
                            this.actualizarestadoPrestamo();
                          }
                        });
                      },
                      controller: controller,
                      itemBuilder: (context, index) {
                        if (listaPrestamos == null) {
                          return Center(child: CircularProgressIndicator());
                        } else {
                          final item = listaPrestamos[index];
                          List<Color> colores = item['color'];
                          Color uno = colores[0];
                          Color dos = colores[1];

                          return AnimatedBuilder(
                            animation: controller,
                            builder: (context, child) {
                              double value = 1.0;
                              if (controller.position.haveDimensions) {
                                value = controller.page - index;
                                value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
                                //print("value $value");
                              }
                              return new Center(
                                child: new SizedBox(
                                  height: Curves.easeOut.transform(value) * 250,
                                  width: Curves.easeOut.transform(value) * 500,
                                  child: child,
                                ),
                              );
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Container(
                                margin: EdgeInsets.only(left: 10,right: 10,top: 10,bottom: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      colors: [
                                        uno,
                                        dos,
                                      ],
                                    )),
                                child:Padding(
                                  padding: EdgeInsets.all(25.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.max,
                                            children: <Widget>[
                                              Text('${item['modalidad']}', style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                              Text('${idPrestamoFinal.toUpperCase()}', style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Text('$simbolomoneda${item['saldo']}', style: TextStyle(
                                                  color: Colors.amber[300],
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 34.0)),
                                              Icon(item['alarma'] ? Icons.alarm : null,
                                                  color: Colors.white, size: 24.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text('Iniciado hace',
                                              style: TextStyle(color: Colors.white)),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                                            child: Text(
                                                '${item['diaspasados']} dias', style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text('${item['estado']}  ',
                                              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text('Ultimo pago hace ${item['ultimopagohace']} dias',
                                              style: TextStyle(
                                                  color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20,top: 20,right: 20,bottom: 20),
                child: Material(
                  elevation: 5,
                  color: estadoPrestamo['ultimopagohace']==0?estadoPrestamo['color'][1]:Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 0,left: 20,right: 20,bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(height: 20,),
                            Visibility(
                              visible: estadoPrestamo['interesconsecutivo'],
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    child: Column(
                                      children: <Widget>[
                                        RaisedButton.icon(
                                          label: Text(_abonocapital?"Anono capital":"Abono interes"),
                                          icon: _abonocapital ? Icon(Icons.monetization_on) : Icon(Icons.attach_money),
                                          onPressed: () {
                                            setState(() {
                                              _abonocapital = !_abonocapital;
                                            });
                                          },
                                          color: _abonocapital ? Colores.verdeoliva : Colores.incrementable,
                                          textColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: _abonocapital ?Colores.verdeoliva:Colores.incrementable),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 120,
                                    child: Column(
                                      children: <Widget>[
                                        RaisedButton.icon(
                                          label: Text("Imprimir"),
                                          icon: _checkimprimir ? Icon(Icons.check_circle) : Icon(
                                              Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _checkimprimir = !_checkimprimir;
                                            });
                                          },
                                          color: _checkimprimir ? color : Colors.white,
                                          textColor: _checkimprimir ? Colors.white : color,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: color),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: TextField(
                                      controller: txtabono,
                                      decoration: InputDecoration(
                                        labelText: "Abono",
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  RaisedButton(
                                    onPressed: (){
                                      pagar();
                                    },
                                    onLongPress: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
                                    },
                                    child: Text("Pagar",style: TextStyle(color: Colors.white),),
                                    color: color,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Text("Saldo",style: TextStyle(fontWeight: FontWeight.bold),),
                                ),
                                Flexible(
                                  child: Text("${estadoPrestamo['saldo']}",style: TextStyle(color: color,fontWeight: FontWeight.bold),),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Text("Cuota",style: TextStyle(fontWeight: FontWeight.bold),),
                                ),
                                Flexible(
                                  child: Text("${estadoPrestamo['cuota']}",style: TextStyle(fontWeight: FontWeight.bold),),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Text(estadoPrestamo['ava']=="adelantado"?"Dinero adelantado":"Dinero atrasado",style: TextStyle(fontWeight: FontWeight.bold),),
                                ),
                                Flexible(
                                  child: Text("${estadoPrestamo['dineroatrasado']}",style: TextStyle(fontWeight: FontWeight.bold),),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Text("Completar cuota"),
                                ),
                                Flexible(
                                  child: Text("${estadoPrestamo['dinerocompletarcuota']}"),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: estadoPrestamo['interesconsecutivo']?Text("Capital"):Text("Cuotas pagas"),
                                ),
                                Flexible(
                                  child: Text(estadoPrestamo['interesconsecutivo']?estadoPrestamo['capital'].toString():"${dejarDosDecimales(estadoPrestamo['cuotaspagas'])}"),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: estadoPrestamo['interesconsecutivo']?Text("Interes"):Text("Cuotas pendientes"),
                                ),
                                Flexible(
                                  child: Text(estadoPrestamo['interesconsecutivo']?estadoPrestamo['interes'].toString():"${dejarDosDecimales(estadoPrestamo['cuotaspendientes'])}"),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Text("Total prestado"),
                                ),
                                Flexible(
                                  child: Text("${estadoPrestamo['totalprestado']}"),
                                ),
                              ],
                            ),
                            Divider(height: 1,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              mapmora==null||mapmora['mora'].toString()=="0.00"?Container():Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("Interes mora aplicado",style: TextStyle(color: Colores.rosadooscuro,fontSize: 20,fontWeight: FontWeight.bold),),
                    SizedBox(height: 10,),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: 120,
                            child: Column(
                              children: <Widget>[
                                RaisedButton.icon(
                                  label: Text("Imprimir"),
                                  icon: _checkimprimirmora ? Icon(Icons.check_circle) : Icon(
                                      Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _checkimprimirmora = !_checkimprimirmora;
                                    });
                                  },
                                  color: _checkimprimirmora ? Colores.verdeoliva : Colors.white,
                                  textColor: _checkimprimirmora ? Colors.white : Colores.verdeoliva,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colores.verdeoliva),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: txtabonomora,
                              decoration: InputDecoration(
                                labelText: "Abono",
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          RaisedButton(
                            onPressed: (){
                              pagarmora();
                            },
                            onLongPress: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
                            },
                            child: Text("Pagar",style: TextStyle(color: Colors.white),),
                            color: Colores.verdeoliva,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Interes mora"),
                        Text("${mapmora['mora']}",style: TextStyle(color: Colores.rosadooscuro,fontWeight: FontWeight.bold),),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Interes por dia"),
                        Text("${mapmora['interesdia']}"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Interes atraso"),
                        Text("${mapmora['interesatraso']} %"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Interes vencido"),
                        Text("${mapmora['interesvencido']} %"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Despues atraso/vencido"),
                        Text("${mapmora['diasmora']} dias"),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      onTap:(){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Historialpagos(idprestamo)));
                      },
                      leading: Icon(Icons.assignment),
                      title: Text("Historial de pagos"),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      onTap:(){
                        if(licenciaGlobal!="0"&&licenciaGlobal!="1") {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>movimientosprestamo(idprestamo)));
                        }else{
                          Flushbar(title: "ADQUIERE UN PLAN",message: "No disponible sin plan",backgroundColor: Colors.deepPurpleAccent,duration: Duration(seconds: 5),).show(context);
                        }
                      },
                      leading: Icon(Icons.assignment),
                      title: Text("Movimientos del prestamo"),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Cedula"),
                        ),
                        Flexible(
                          child: Text("$cedula"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Direccion"),
                        ),
                        Flexible(
                          child: Text("$direccion"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Telefono"),
                        ),
                        Flexible(
                          child: Text("$telefono"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Fecha de Prestado"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['fecha']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Plazo"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['plazo']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Modalidad"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['modalidad']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Dias no cobrados"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['diasnocobra']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Porcentaje al capital"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['porcentajecapital']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("% mora/vencido"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['porcentajemora']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Interes consecutivo"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['interesconsecutivo']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Ultimo pago"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['ultimopago']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Dias descontados"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['descontardias']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text("Alarma"),
                        ),
                        Flexible(
                          child: Text("${datosPrestamosbruto['alarma']}"),
                        ),
                      ],
                    ),
                    Divider(height: 1,),
                    Visibility(
                      visible: modo=="admin"?true:false,
                      child: Container(
                        alignment: Alignment.center,
                        child: OutlineButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>EditarPrestamo(key,idprestamo)));
                          },
                          child: Text("Editar prestamo"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      child: FlatButton(
                        onPressed: (){
                          observacion();
                        },
                        child: Text("Agregar observacion"),

                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: OutlineButton(
                            onPressed: (){
                              this.setAlerta();
                            },
                            child: Text("Alerta"),
                          ),
                        ),
                        Expanded(
                          child: OutlineButton(
                            onLongPress: (){
                              this.borrarAlarma();
                            },
                            onPressed: (){
                              _alarma(context);
                            },
                            child: Text("Alarma"),
                          ),
                        ),
                        Expanded(
                          child: OutlineButton(
                            child: Text("Reportar"),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void pagar()async{
    Map datopago = new Map();

    String estadoprint = await PrintBluetoothThermal.estadoConexion;
    print("estado print $estadoprint");
    if(estadoprint=="false"){
      conectarImpresora();
      _connected = false;
      return;
    }

    String abon = txtabono.text;
    if(abon.trim().length==0){
      Flushbar(message: "Escriba un abono",icon: Icon(Icons.close,color: Colors.white,),backgroundColor: Colors.red,duration: Duration(seconds: 2),)..show(context);
      return;
    }
    double abono = double.parse(abon);
    Database database = await opendb();
    List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
    await database.close();
    if(prestamo.length>0) {

      double capital = double.parse(prestamo[0]['capital'].toString());
      double interes = double.parse(prestamo[0]['interes'].toString());
      String fecha =  prestamo[0]['fecha'].toString();
      String interescapital = prestamo[0]['porcentajecapital'].toString();
      String interesconsecutivo = prestamo[0]['interesconsecutivo'].toString();
      String modalidad = prestamo[0]['modalidad'].toString();
      String diasnocobra = prestamo[0]['diasnocobra'].toString();
      String diascuota = prestamo[0]['diascuota'].toString();
      String idunico = idUnico();
      double saldo = capital + interes;
      double resultado = saldo-abono;
      String tiempo = fechaActual() + " " + horaActual();
      String fechaactual = fechaActual();
      String tipopago = "";

      //abono consecutivo
      if (interesconsecutivo=="si") {
        if(_abonocapital==false){
          if (abono > interes) {
            Flushbar(message: "El abono es mayor que el interes",
              icon: Icon(Icons.info, color: Colors.white,),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),)..show(context);
            return;
          }
          double saldointeres = interes - abono;
          Database database = await opendb();
          int count = await database.rawUpdate('UPDATE prestamos SET alarma = ?, interes = ?, ultimopago =? WHERE id = ?', ["no",saldointeres,fechaactual, idprestamo]);
          await database.close();
          tipopago = "AbonoInteres";
          String pago = tiempo + " $tipopago $abono $resultado $idunico";
          await agregarHistorialPago(idprestamo, pago);
          await agregarMovimientoPrestamo(idprestamo, "Abonado a interes $abono ");
          await agregarResumenDia("interes", "Abono a $nombre",  "0", "0", abono.toString(),interescapital, idprestamo);
          //print("saldo interes: $saldointeres");
        }else{
          if (abono > capital) {
            Flushbar(message: "El abono es mayor que el capital",
              icon: Icon(Icons.info, color: Colors.white,),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),)..show(context);
            return;
          }
          double saldocapital = capital - abono;
          Database database = await opendb();
          int count = await database.rawUpdate('UPDATE prestamos SET alarma = ?, capital =?, ultimopago =? WHERE id = ?', ["no",saldocapital,fechaactual, idprestamo]);
          await database.close();
          tipopago = "AbonoCapital";
          String pago = tiempo + " $tipopago $abono $resultado $idunico";
          await agregarHistorialPago(idprestamo, pago);
          await agregarMovimientoPrestamo(idprestamo, "Abonado a capital: $abono saldocapital $saldocapital");
          await agregarResumenDia("capital", "Abono a $nombre",  "0", abono.toString(), "0",interescapital, idprestamo);
          //print("saldos: capital. $saldocapital");
        }
      }
      //abono normal
      else {
        if (abono > saldo) {
          Flushbar(message: "El abono es mayor que el saldo",
            icon: Icon(Icons.info, color: Colors.white,),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),)..show(context);
          return;
        }

        tipopago = "Abono";

        if (abono <= interes) {
          double saldointeres = interes - abono;
          Database database = await opendb();
          int count = await database.rawUpdate('UPDATE prestamos SET alarma = ?, interes = ?, ultimopago =? WHERE id = ?', ["no", saldointeres,fechaactual, idprestamo]);
          await database.close();
          String pago = tiempo + " Abono $abono $resultado $idunico";
          await agregarHistorialPago(idprestamo, pago);
          await agregarMovimientoPrestamo(idprestamo, "Abonado a interes $abono ");
          await agregarResumenDia("abono", "Abono a $nombre",  abono.toString(), "0", "0",interescapital, idprestamo);
          //print("saldo interes: $saldointeres");
        } else {
          double abonointeres = interes;
          double saldointeres = interes-abonointeres;
          double abonocapital = abono - abonointeres;
          saldo = saldo-abonointeres;
          double saldocapital = saldo - abonocapital;
          Database database = await opendb();
          int count = await database.rawUpdate('UPDATE prestamos SET alarma = ?, interes = ?, capital =?, ultimopago =? WHERE id = ?', ["no", saldointeres, saldocapital,fechaactual, idprestamo]);
          await database.close();
          String pago = tiempo + " Abono $abono $resultado $idunico";
          await agregarHistorialPago(idprestamo, pago);
          await agregarMovimientoPrestamo(idprestamo, "Abonado a interes: $abonointeres capital: $abonocapital saldo: $saldocapital");
          await agregarResumenDia("abono", "Abono a $nombre",  abono.toString(), "0","0", interescapital,idprestamo);
          //print("saldos: interes: $abonointeres capital. $abonocapital");
        }
      }

      Map elemento = await verEstadoPrestamo(idprestamo);
      listaPrestamos.removeAt(_index);
      listaPrestamos.insert(_index, elemento);
      estadoPrestamo.addAll(elemento);

      setState(() {

      });

      //para actualizar la mora
      String ava = estadoPrestamo['ava'];
      String diasmoracobrados = estadoPrestamo['diasmoracobrado'];
      List datacobrados = diasmoracobrados.split("/");
      int diascobradoatraso = int.parse(datacobrados[0]);
      int diascobradovencido = int.parse(datacobrados[1]);
      int diassepaso = estadoPrestamo['diassepaso'];
      String nuevodiasmoracobrados = "$diascobradoatraso/$diascobradovencido";
      if(ava=="atrasado"){
        nuevodiasmoracobrados = "$diassepaso/$diascobradovencido";
      }else if(ava=="vencido"){
        nuevodiasmoracobrados = "$diascobradoatraso/$diassepaso";
      }else if(ava=="adelantado"){
        nuevodiasmoracobrados = "0/$diascobradovencido";
      }
      Database database = await opendb();
      int count = await database.rawUpdate('UPDATE prestamos SET diasmoracobrado = ? WHERE id = ?', [nuevodiasmoracobrados, idprestamo]);
      await database.close();

      Map item = estadoPrestamo;
      String estado = item['estado'];
      double cuotaspagas = double.parse(item['cuotaspagas'].toString());
      double cuotaspendientes = double.parse(item['cuotaspendientes'].toString());
      String plazo = item['plazo'].toString();

      datopago.addAll({
        "abono": dejarDosDecimales(abono),
        "saldo": dejarDosDecimales(resultado),
        "estado": estado,
        "movimiento": tipopago,
        "cuotaspagas": dejarDosDecimales(cuotaspagas),
        "cuotaspendientes": dejarDosDecimales(cuotaspendientes),
        "plazo": plazo,
        "fecha": fecha,
        "tiempo": tiempo,
        "idpago": idunico,
      });

      if(_checkimprimir) {
        Ticket ticket = await recibo(datopago);
        imprimirRecibo(ticket,context,idprestamo,nombre);
      }

      cancelarpago = new Map();
      cancelarpago = {
        "capital":capital,
        "interes":interes,
        "ultimopago":prestamo[0]['ultimopago'].toString(),
        "alarma": prestamo[0]['alarma'].toString(),
        "pagos": prestamo[0]['pagos'].toString(),
        "abono":abono,
        "porcentaje":interescapital,
      };


      bool _wasButtonClicked;

      flush = Flushbar<bool>(
        title: "Pago exitoso",
        message: "El pago se realizo exitosamente",
        icon: Icon(Icons.check_circle, color: Colors.blue,),
        duration: Duration(seconds: 10),
        mainButton: FlatButton(
          onPressed: () {
            //flush.dismiss(true); // result = true
            cancelarPago();
          },
          child: Text("CANCELAR PAGO", style: TextStyle(color: Colors.amber),),
        ),) // <bool> is the type of the result passed to dismiss() and collected by show().then((result){})
        ..show(context).then((result) {
          setState(() { // setState() is optional here
            _wasButtonClicked = result;
          });
        });

    }else{
      Flushbar(message: "No se encontro prestamo",duration: Duration(seconds: 5),backgroundColor: Colors.orange,)..show(context);
    }

  }

  void cancelarPago()async{

    String alarma = cancelarpago['alarma'];
    String capital = cancelarpago['capital'].toString();
    String interes = cancelarpago['interes'].toString();
    String ultimopago = cancelarpago['ultimopago'];
    String abono = cancelarpago['abono'].toString();
    String pagos = cancelarpago['pagos'].toString();
    String porcentaje = cancelarpago['porcentaje'].toString();

    //print("datos llego: $cancelarpago");

    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE prestamos SET alarma = ?, interes = ?, capital =?, ultimopago =?, pagos =? WHERE id = ?', [alarma, interes, capital,ultimopago,pagos, idprestamo]);
    await database.close();
    String movimiento = "Cancelo pago: ${fechaActual()} abono: $abono";
    await agregarMovimientoPrestamo(idprestamo, movimiento);
    await agregarResumenDia("pagocancelado", "Caneclado a $nombre",  abono, "0", "0",porcentaje, idprestamo);

    Map elemento = await verEstadoPrestamo(idprestamo);
    listaPrestamos.removeAt(_index);
    listaPrestamos.insert(_index, elemento);
    estadoPrestamo.addAll(elemento);
    flush.dismiss(true); //cerrar el flushbar

  }

  void pagarmora()async{

    String estadoprint = await PrintBluetoothThermal.estadoConexion;
    if(estadoprint=="false"){
      conectarImpresora();
      _connected = false;
      return;
    }
    Map datopago = new Map();
    Map item = estadoPrestamo;

    String abona = txtabonomora.text.trim();
    if(abona.length<=0){
      Flushbar(message: "Falta el abono ",backgroundColor: Colores.naranja,duration: Duration(seconds: 3),)..show(context);
      return;
    }
    double abono = double.parse(abona);
    double saldomora = double.parse(mapmora['mora']);
    double resultado = saldomora - abono;
    if(resultado>=0){

      Database database = await opendb();
      int count = await database.rawUpdate('UPDATE prestamos SET mora = ? WHERE id = ?', [resultado, idprestamo]);
      await database.close();

      String tiempo = fechaActual() + " " + horaActual();
      String idunico = idUnico();

      String movimiento = "Abono a mora $abono saldo $resultado";
      await agregarMovimientoPrestamo(idprestamo, movimiento);
      String pago = tiempo + " Abono_mora $abono $resultado $idunico";
      await agregarHistorialPago(idprestamo, pago);
      await agregarResumenDia("mora", "Abono mora a $nombre",  abono.toString(), "0", "0","0", idprestamo);

      mapmora = {
        "mora": dejarDosDecimales(resultado),
        "interesdia": mapmora['interesdia'],
        "interesatraso": mapmora['interesatraso'],
        "interesvencido": mapmora['interesvencido'],
        "diasmora": mapmora['diasmora'],
      };
      print("mora $mapmora");

      String estado = item['estado'];
      double cuotaspagas = item['cuotaspagas'];
      double cuotaspendientes = item['cuotaspendientes'];
      int plazo = item['plazo'];
      String fecha = item['fecha'];

      datopago.addAll({
        "abono": dejarDosDecimales(abono),
        "saldo": dejarDosDecimales(resultado),
        "estado": estado,
        "movimiento": "Abono_mora",
        "cuotaspagas": dejarDosDecimales(cuotaspagas),
        "cuotaspendientes": dejarDosDecimales(cuotaspendientes),
        "plazo": plazo.toString(),
        "fecha": fecha,
        "tiempo": tiempo,
        "idpago": idunico,
      });

      if(_checkimprimirmora) {
        Ticket ticket = await recibo(datopago);
        imprimirRecibo(ticket,context,idprestamo,nombre);
      }
      await this.ActualizarMora();

      bool _wasButtonClicked;
      flush = Flushbar<bool>(
        title: "Pago exitoso",
        message: "El pago se realizo exitosamente",
        icon: Icon(Icons.check, color: Colors.blue,),
        duration: Duration(seconds: 5),
        mainButton: FlatButton(
          onPressed: () {
            flush.dismiss(true); // result = true
            //cancelarPago();
          },
          child: Text("OK", style: TextStyle(color: Colors.blue),),
        ),) // <bool> is the type of the result passed to dismiss() and collected by show().then((result){})
        ..show(context).then((result) {
          setState(() { // setState() is optional here
            _wasButtonClicked = result;
          });
        });

    }else{
      Flushbar(message: "El abono es mayor que el saldo de mora ",backgroundColor: Colores.naranja,duration: Duration(seconds: 3),)..show(context);
    }
  }

  void conectarImpresora()async{
    Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
  }

  Future<Ticket> recibo(Map datopago) async {

    String empresa = nombreempresa;
    String telefono = telefonoempresa;
    String moneda = simbolomoneda;
    String movimiento = datopago['movimiento'];

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    //el logo debe ser de 350 ancho por 86 alto
    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    if(existelogo) {
      //final ByteData data = await rootBundle.load(pathlogo);
      final bytes = file.readAsBytesSync();
      //final Uint8List bytes = data.buffer.asUint8List();
      final image = Imag.decodeImage(bytes);
      ticket.image(image, align: PosAlign.center);
    }else {
      ticket.text('$empresa', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ));
    }

    //ticket.text('$telefono', styles: PosStyles(align: PosAlign.center));
    ticket.feed(1);

    ticket.text('Prestamo $idPrestamoFinal',styles: PosStyles(bold: true));
    ticket.text('Sr(a) $nombre',styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('C.C.  $cedula');
    ticket.feed(1);

    String saldo = datopago['saldo'].toString();
    String abono = datopago['abono'].toString();
    abono = dejarSinDecimalSiTerminaEnCeros(abono);

    if(movimiento!="Abono_mora") {
      ticket.text('ABONO: $moneda$abono', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
        codeTable: 'CP1252',
      ));
      ticket.feed(1);
      ticket.text("SALDO:       $moneda$saldo", styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }else {
      ticket.text('ABONO MORA: $moneda$abono', styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
      ticket.feed(1);
      ticket.text("SALDO MORA: $moneda$saldo", styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }

    double mora = double.parse(mapmora['mora']);
    if(mora>0){
      ticket.text("INTERES MORA: $moneda$mora",styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }

    ticket.feed(1);

    ticket.text("${estadoPrestamo['estado']}",styles: PosStyles(bold: true,align: PosAlign.center));
    ticket.feed(1);

    ticket.text("Cuotas pendientes: ${dejarDosDecimales(estadoPrestamo['cuotaspendientes'])} de ${estadoPrestamo['plazo']}");
    ticket.text("Cuotas pagas:      ${dejarDosDecimales(estadoPrestamo['cuotaspagas'])} de ${estadoPrestamo['plazo']}");
    ticket.text("Fecha Prestado:    ${estadoPrestamo['fecha']}");

    ticket.feed(1);

    String letras = Strings.letrasrecibo.substring(0,94);

    ticket.text('${letras}', styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252'));
    ticket.feed(1);
    ticket.text('${datopago['tiempo']}', styles: PosStyles(align: PosAlign.center));

    ticket.feed(1);

    ticket.text('CONSERVAR ESTE RECIBO DE PAGO', styles: PosStyles(align: PosAlign.center));
    ticket.text('ID ${datopago['idpago']}', styles: PosStyles(align: PosAlign.center,bold: true));

    ticket.feed(3);

    /*ticket.text('Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    ticket.text('Special 1: Bogotá ññ', styles: PosStyles(codeTable: PosCodeTable.westEur));
    ticket.text('Special 2: blåbærgrød', styles: PosStyles(codeTable: PosCodeTable.westEur));

    ticket.text('Bold text', styles: PosStyles(bold: true));
    ticket.text('Reverse text', styles: PosStyles(reverse: true));
    ticket.text('Underlined text', styles: PosStyles(underline: true), linesAfter: 1);
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

    // Print image
    final ByteData data = await rootBundle.load('assets/logop.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final image = Imag.decodeImage(bytes);
    ticket.image(image);
    // Print image using alternative commands
    // ticket.imageRaster(image);
    // ticket.imageRaster(image, imageFn: PosImageFn.graphics);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    ticket.barcode(Barcode.upcA(barData)); */

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // ticket.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    //ticket.feed(2);

    //ticket.cut();
    return ticket;
  }

  Future<List<String>> vercalificacion() async {
    Database database = await opendb();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece =? AND capital=='0'", [key]);
    await database.close();
    List<String> lista = new List();
    String estrella = "★";
    String estrellas = "";
    int puntos = 0;
    int prestamos = list.length;
    int puntosprestamo = 5;
    if (prestamos > 0) {
      await Future.forEach(list, (item) async {
        String id = item['id'].toString();
        double capital = double.parse(item['capital'].toString());
        if(capital==0) {
          int plazo = int.parse(item['plazo'].toString());
          String modalidad = item['modalidad'].toString();
          if(modalidad=="Semanal"){
            plazo = plazo * 7;
          }else if(modalidad=="Quincenal"){
            plazo = plazo * 15;
          }else if(modalidad=="Mensual"){
            plazo = plazo * 30;
          }
          String fecha = item['fecha'].toString();
          String ultimopago = item['ultimopago'].toString();
          int diaspagando = await diasCorridosDosFechas(fecha, ultimopago);
          if(diaspagando>plazo){
            int diasdemas = diaspagando-plazo;
            if(diasdemas>puntosprestamo){
              puntos = puntos+1;
            }else{
              puntos = puntos+4;
            }
          }else{
            puntos = puntos+puntosprestamo;
          }
        }
      });

      double estrellasdouble = puntos/prestamos;
      int estrellasint = estrellasdouble.toInt();
      for(int i = 0; i<estrellasint;i++){
        estrellas = estrellas+estrella;
      }

      lista.add(dejarUnDecimales(estrellasdouble));
      lista.add(estrellas);
    }else{
      lista.add("");
      lista.add("");
    }

    return lista;
  }

  observacion()async{

    return showDialog(
      context: context,
      builder: (BuildContext context) {

        final txtobservacion = TextEditingController();
        String msj = "";
        Color color = Colors.blueGrey;

        return AlertDialog(
          content: StatefulBuilder(  // You need this, notice the parameters below:
            builder: (BuildContext context, StateSetter setState) {
              return Column(  // Then, the content of your dialog.
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(msj,style: TextStyle(color: color),),
                  ),
                  Container(
                    child: TextField(
                      controller: txtobservacion,
                      decoration: InputDecoration(
                          labelText: "Observacion"
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FlatButton(
                          onPressed: (){
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                          child: Text("Cancelar"),
                        ),
                      ),
                      SizedBox(width: 20,),
                      Expanded(
                        child: FlatButton(
                          onPressed: () async {
                            String observacion = txtobservacion.text.trim();
                            if(observacion.trim().length<=0){
                              setState(() {
                                msj = "Escriba algo para guardar";
                                color = Colors.orange;
                              });
                              return;
                            }
                            await agregarMovimientoPrestamo(idprestamo, primeraLetraMayuzcula(observacion));
                            setState(() {
                              msj = "Guardado exitoso";
                              color = Colors.green;
                            });
                          },
                          child: Text("Guardar",style: TextStyle(color: Colors.green),),
                        ),
                      ),
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  setAlerta()async{

    return showDialog(
      context: context,
      builder: (BuildContext context) {

        final txtobservacion = TextEditingController();
        String msj = "";
        Color color = Colors.blueGrey;

        return AlertDialog(
          content: StatefulBuilder(  // You need this, notice the parameters below:
            builder: (BuildContext context, StateSetter setState) {
              return Column(  // Then, the content of your dialog.
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(msj,style: TextStyle(color: color),),
                  ),
                  Container(
                    child: TextField(
                      controller: txtobservacion,
                      decoration: InputDecoration(
                          labelText: "Alerta"
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FlatButton(
                          onPressed: (){
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                          child: Text("Cancelar"),
                        ),
                      ),
                      SizedBox(width: 20,),
                      Expanded(
                        child: FlatButton(
                          onPressed: () async {
                            String alerta = txtobservacion.text.trim();
                            if(alerta.trim().length<=0){
                              setState(() {
                                msj = "Escriba algo para guardar, aparece en los movimientos del resumen del dia";
                                color = Colors.orange;
                              });
                              return;
                            }
                            await agregarResumenDia("ALERTA", "$alerta para $nombre", "0", "0", "0", "0", "0");
                            setState(() {
                              msj = "Guardado exitoso";
                              color = Colors.green;
                            });
                          },
                          child: Text("Guardar",style: TextStyle(color: Colors.green),),
                        ),
                      ),
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<Null> _alarma(BuildContext context) async {

    DateTime selectedDate = DateTime.now();
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020, 1),
        lastDate: DateTime(2101),
      cancelText: "CANCELAR",
      confirmText: "GUARDAR",
      helpText: "Selecione alarma",
    );
    if(picked==null)return;
    String fecha = picked.toString().substring(0,10);

    List<String> fec = fecha.toString().split("-");
    String anio = fec[0];
    String mes = fec[1];
    String dia = fec[2];
    String alarma = "$dia/$mes/$anio";
    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE prestamos SET alarma = ? WHERE id = ?', [alarma,idprestamo]);
    await database.close();

  }

  borrarAlarma()async{
    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE prestamos SET alarma = ? WHERE id = ?', ["no",idprestamo]);
    await database.close();
    Flushbar(message: "Alarma borrada",duration: Duration(seconds: 2),).show(context);
    print("Alarma quitada");
  }

}

class Historialpagos extends StatefulWidget {
  String idPrestamo;
  Historialpagos(this.idPrestamo);
  @override
  _HistorialpagosState createState() => _HistorialpagosState();
}

class _HistorialpagosState extends State<Historialpagos> {

  String idPrestamoFinal = "";
  String idprestamo;
  String key;
  String nombre;
  String cedula;
  List<Pagos> listapagos = Pagos.getPagos();
  Map estadoPrestamo;

  ActualizarPagos()async{
    List<Pagos> pagos = await getPagos();
    estadoPrestamo = await verEstadoPrestamo(idprestamo);
    key = estadoPrestamo['key'];

    List result = key.split("-");
    String idpres = result[0];
    idPrestamoFinal = idprestamo+idpres.toUpperCase();

    setState(() {
      listapagos = pagos;
    });

    nombre = await getDatoCliente(key, "nombre");
    cedula = await getDatoCliente(key, "cedula");
  }

  @override
  void initState() {
    idprestamo = widget.idPrestamo;
    this.ActualizarPagos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.circular(10),
            border: Border.all(width: 1, color: Colors.black12,),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                sortColumnIndex: 0,
                columns: [
                  DataColumn(
                    label: Text("Fecha",
                      style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                    tooltip: "Fecha ",
                  ),
                  DataColumn(
                    label: Text(
                      "Abono", style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text(
                      "Saldo", style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text("Movimiento",
                      style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text(
                      "Id", style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text("Imprimir",
                      style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                  DataColumn(
                    label: Text("Compartir", style: TextStyle(fontWeight: FontWeight.bold),),
                    numeric: false,
                  ),
                ],
                rows: listapagos == null ? Pagos.getPagos()
                    : listapagos.map((user) =>
                    DataRow(cells: [
                      DataCell(
                        Text(user.fecha),
                        onTap: () {
                          print('Selected ${user.fecha}');
                        },
                      ),
                      DataCell(
                        Text(user.abono),
                        onTap: () {
                          print('Selected ${user.abono}');
                        },
                      ),
                      DataCell(
                        Text(user.saldo),
                        onTap: () {
                          print('Selected ${user.saldo}');
                        },
                      ),
                      DataCell(
                        Text(user.movimiento),
                        onTap: () {
                          print('Selected ${user.movimiento}');
                        },
                      ),
                      DataCell(
                        Text(user.id),
                        onTap: () {
                          print('Selected ${user.id}');
                        },
                      ),
                      DataCell(
                        Icon(Icons.print),
                        onTap: () async{
                          Ticket ticket = await recibo(user);
                          imprimirRecibo(ticket,context,idprestamo,nombre);
                        },
                      ),
                      DataCell(
                        Icon(Icons.share),
                        onTap: () {
                          compratirRecibo(user);
                        },
                      ),
                    ]),
                )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Pagos>> getPagos() async {
    Database database = await opendb();
    List<Pagos> listapagos = new List();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
    await database.close();

    Map item = list[0];
    String pagos = item['pagos'].toString();

    if (pagos.length > 0) {

      List<String> itemspagos = pagos.split("-");

      await Future.forEach(itemspagos, (itempago) {
        List<String> pago = itempago.split(" ");
        try {
          String fecha = pago[0];
          String hora = pago[1];
          String movimiento = pago[2];
          String abono = pago[3];
          String saldo = pago[4];
          String id = pago[5];

          listapagos.add(Pagos(fecha: fecha,
              hora: hora,
              movimiento: movimiento,
              abono: abono,
              saldo: saldo,
              id: id));

        }catch(e){

        }
      });

    }else{
      listapagos = Pagos.getPagos();
    }

    return listapagos;

  }

  Future<Ticket> recibo(Pagos datopago) async {

    String empresa = nombreempresa;
    String telefono = telefonoempresa;
    String moneda = simbolomoneda;
    String movimiento = datopago.movimiento;
    Map mapmora = await verMora(idprestamo);

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    if(existelogo) {
      //final ByteData data = await rootBundle.load(pathlogo);
      final bytes = file.readAsBytesSync();
      //final Uint8List bytes = data.buffer.asUint8List();
      final image = Imag.decodeImage(bytes);
      ticket.image(image, align: PosAlign.center);
    }else {
      ticket.text('$empresa', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ));
    }

    //ticket.text('$telefono', styles: PosStyles(align: PosAlign.center));
    ticket.feed(1);

    ticket.text('Prestamo $idPrestamoFinal',styles: PosStyles(bold: true));
    ticket.text('Sr(a) $nombre',styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('C.C.  $cedula');
    ticket.feed(1);

    String saldo = datopago.saldo.toString();
    String abono = datopago.abono.toString();
    abono = dejarSinDecimalSiTerminaEnCeros(abono);

    if(movimiento!="Abono_mora") {
      ticket.text('ABONO: $moneda$abono', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
        codeTable: 'CP1252',
      ));
      ticket.feed(1);
      ticket.text("SALDO:       $moneda$saldo", styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }else {
      ticket.text('ABONO MORA: $moneda$abono', styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
      ticket.feed(1);
      ticket.text("SALDO MORA: $moneda$saldo", styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }

    double mora = double.parse(mapmora['mora']);
    if(mora>0){
      ticket.text("INTERES MORA: $moneda$mora",styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252',));
    }

    ticket.feed(1);

    ticket.text("${estadoPrestamo['estado']}",styles: PosStyles(bold: true,align: PosAlign.center));
    ticket.feed(1);

    ticket.text("Cuotas pendientes: ${dejarDosDecimales(estadoPrestamo['cuotaspendientes'])} de ${estadoPrestamo['plazo']}");
    ticket.text("Cuotas pagas:      ${dejarDosDecimales(estadoPrestamo['cuotaspagas'])} de ${estadoPrestamo['plazo']}");
    ticket.text("Fecha Prestado:    ${estadoPrestamo['fecha']}");

    ticket.feed(1);

    String letras = Strings.letrasrecibo.substring(0,94);

    ticket.text('${letras}', styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252'));
    ticket.feed(1);
    ticket.text('${datopago.fecha} ${datopago.hora}', styles: PosStyles(align: PosAlign.center));

    ticket.feed(1);

    ticket.text('CONSERVAR ESTE RECIBO DE PAGO', styles: PosStyles(align: PosAlign.center));
    ticket.text('ID ${datopago.id}', styles: PosStyles(align: PosAlign.center,bold: true));

    ticket.feed(3);

    return ticket;
  }

  void compratirRecibo(Pagos datopago)async{

    File imghtml = await generarpdf(datopago);
    String id = datopago.id;

    List<int> bytes = await imghtml.readAsBytes();
    await Share.file('Recibo pdf', 'Recibo_pago_$id.pdf', bytes, 'application/pdf');
    await imghtml.delete();
    await agregarResumenDia("compartido", "compartio recibo a $nombre",  "0", "0", "0","0", idprestamo);
    await agregarMovimientoPrestamo(idprestamo, "Compartio recibo ${datopago.id} a $nombre");

  }

  Future<File> generarpdf(Pagos datopago)async{

    String empresa = nombreempresa;
    String telefono = telefonoempresa;
    String moneda = simbolomoneda;
    String movimiento = datopago.movimiento;
    String abono = datopago.abono;
    String saldo = datopago.saldo;
    String estado = estadoPrestamo['estado'];
    String cuotaspendientes = estadoPrestamo['cuotaspendientes'].toString();
    cuotaspendientes = dejarDosDecimales(double.parse(cuotaspendientes));
    String cuotaspagas = estadoPrestamo['cuotaspagas'].toString();
    cuotaspagas = dejarDosDecimales(double.parse(cuotaspagas));
    String fechaprestado = estadoPrestamo['fecha'];
    String plazo = estadoPrestamo['plazo'].toString();
    String tiempo = "${datopago.fecha} ${datopago.hora}";
    String idpago = datopago.id;
    Map mapmora = await verMora(idprestamo);
    double mora = double.parse(mapmora['mora']);

    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    var htmlContent;
    if(existelogo){
      if(movimiento=="Abono_mora") {
        htmlContent =
        """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="max-width: 500px; border-radius: 5px; border: 1px solid #a1a1a1; padding: 20px; margin: auto;">
        <div style="text-align: center;">
            <img src="file://$pathlogo" alt="web-img">
            <p style="font-weight: bold; font-size: 12px; color: #919995;">Tel: $telefono</p>
        </div>
        <br><br>
        <div style="text-align: left;">
            <p style=" color: #26a168;">Prestamo: $idPrestamoFinal </p>
            <p style=" color: #26a168;">Sr(a): $nombre </p>
            <p style=" color: #1fa164; font-size: 12px;">C.C: $cedula </p>
        </div>
        <div style="margin-top: 20px; padding: 10px; text-align: center; color: #656768;">
            <h1 style="font-weight: bold; ">Abono mora: $moneda$abono</h1>
            <h5 style="font-weight: bold; ">Saldo mora: $moneda$saldo</h5>
            <p style="text-align: center; font-weight: bold; font-size: 18px; ">$estado</p>
        </div>
        <div style="padding: 20px; color: #656768; border: 1px solid #b2b9b573; border-radius: 5px;">
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pendientes</p>
                <p style="width: 50%; text-align: right;">$cuotaspendientes de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pagas</p>
                <p style="width: 50%; text-align: right;">$cuotaspagas de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Fecha de prestado</p>
                <p style="width: 50%; text-align: right;">$fechaprestado</p>
            </div>
        </div>
        <br><br>
        <div>
            <p style="text-align: center; font-size: 12px; color: #666;">${Strings
            .letrasrecibo}</p>
            <br>
            <p style="text-align: center; font-size: 12px; color: #87898a;">$tiempo</p>
            <h4 style="text-align: center; font-size: 10px; color: #989999;">CONSERVAR ESTE RECIBO DE PAGO</h4>
            <P style="text-align: center; font-weight: bold; color: #b4b6b8;">ID $idpago</P>
        </div>
    </div>

    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
    </style>
</body>

</html>
    """;
      }else{
        htmlContent =
        """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="max-width: 500px; border-radius: 5px; border: 1px solid #a1a1a1; padding: 20px; margin: auto;">
        <div style="text-align: center;">
            <img src="file://$pathlogo" alt="web-img">
            <p style="font-weight: bold; font-size: 12px; color: #919995;">Tel: $telefono</p>
        </div>
        <br><br>
        <div style="text-align: left;">
            <p style=" color: #26a168;">Prestamo: $idPrestamoFinal </p>
            <p style=" color: #26a168;">Sr(a): $nombre </p>
            <p style=" color: #1fa164; font-size: 12px;">C.C: $cedula </p>
        </div>
        <div style="margin-top: 20px; padding: 10px; text-align: center; color: #656768;">
            <h1 style="font-weight: bold; ">Abono: $moneda$abono</h1>
            <h5 style="font-weight: bold; ">Saldo: $moneda$saldo</h5>
            <h5 style="font-weight: bold; ">Mora: $moneda$mora</h5>
            <p style="text-align: center; font-weight: bold; font-size: 18px; ">$estado</p>
        </div>
        <div style="padding: 20px; color: #656768; border: 1px solid #b2b9b573; border-radius: 5px;">
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pendientes</p>
                <p style="width: 50%; text-align: right;">$cuotaspendientes de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pagas</p>
                <p style="width: 50%; text-align: right;">$cuotaspagas de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Fecha de prestado</p>
                <p style="width: 50%; text-align: right;">$fechaprestado</p>
            </div>
        </div>
        <br><br>
        <div>
            <p style="text-align: center; font-size: 12px; color: #666;">${Strings.letrasrecibo}</p>
            <br>
            <p style="text-align: center; font-size: 12px; color: #87898a;">$tiempo</p>
            <h4 style="text-align: center; font-size: 10px; color: #989999;">CONSERVAR ESTE RECIBO DE PAGO</h4>
            <P style="text-align: center; font-weight: bold; color: #b4b6b8;">ID $idpago</P>
        </div>
    </div>

    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
    </style>
</body>

</html>
    """;
      }
    }else{
      if(movimiento=="Abono_mora") {
        htmlContent =
        """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="max-width: 500px; border-radius: 5px; border: 1px solid #a1a1a1; padding: 20px; margin: auto;">
        <div style="text-align: center;">
            <p style="font-weight: bold; font-size: 40px; color: #4A6C6F;">$empresa</p>
            <p style="font-weight: bold; font-size: 12px; color: #919995;">Tel: $telefono</p>
        </div>
        <br><br>
        <div style="text-align: left;">
            <p style=" color: #26a168;">Prestamo: $idPrestamoFinal </p>
            <p style=" color: #26a168;">Sr(a): $nombre </p>
            <p style=" color: #1fa164; font-size: 12px;">C.C: $cedula </p>
        </div>
        <div style="margin-top: 20px; padding: 10px; text-align: center; color: #656768;">
            <h1 style="font-weight: bold; ">Abono mora: $moneda$abono</h1>
            <h5 style="font-weight: bold; ">Saldo mora: $moneda$saldo</h5>
            <p style="text-align: center; font-weight: bold; font-size: 18px; ">$estado</p>
        </div>
        <div style="padding: 20px; color: #656768; border: 1px solid #b2b9b573; border-radius: 5px;">
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pendientes</p>
                <p style="width: 50%; text-align: right;">$cuotaspendientes de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pagas</p>
                <p style="width: 50%; text-align: right;">$cuotaspagas de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Fecha de prestado</p>
                <p style="width: 50%; text-align: right;">$fechaprestado</p>
            </div>
        </div>
        <br><br>
        <div>
            <p style="text-align: center; font-size: 12px; color: #666;">${Strings
            .letrasrecibo}</p>
            <br>
            <p style="text-align: center; font-size: 12px; color: #87898a;">$tiempo</p>
            <h4 style="text-align: center; font-size: 10px; color: #989999;">CONSERVAR ESTE RECIBO DE PAGO</h4>
            <P style="text-align: center; font-weight: bold; color: #b4b6b8;">ID $idpago</P>
        </div>
    </div>

    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
    </style>
</body>

</html>
    """;
      }else{
        htmlContent =
        """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="max-width: 500px; border-radius: 5px; border: 1px solid #a1a1a1; padding: 20px; margin: auto;">
        <div style="text-align: center;">
            <p style="font-weight: bold; font-size: 40px; color: #4A6C6F;">$empresa</p>
            <p style="font-weight: bold; font-size: 12px; color: #919995;">Tel: $telefono</p>
        </div>
        <br><br>
        <div style="text-align: left;">
            <p style=" color: #26a168;">Prestamo: $idPrestamoFinal </p>
            <p style=" color: #26a168;">Sr(a): $nombre </p>
            <p style=" color: #1fa164; font-size: 12px;">C.C: $cedula </p>
        </div>
        <div style="margin-top: 20px; padding: 10px; text-align: center; color: #656768;">
            <h1 style="font-weight: bold; ">Abono: $moneda$abono</h1>
            <h5 style="font-weight: bold; ">Saldo: $moneda$saldo</h5>
            <h5 style="font-weight: bold; ">Mora: $moneda$mora</h5>
            <p style="text-align: center; font-weight: bold; font-size: 18px; ">$estado</p>
        </div>
        <div style="padding: 20px; color: #656768; border: 1px solid #b2b9b573; border-radius: 5px;">
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pendientes</p>
                <p style="width: 50%; text-align: right;">$cuotaspendientes de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Cuotas pagas</p>
                <p style="width: 50%; text-align: right;">$cuotaspagas de $plazo</p>
            </div>
            <div style="display:flex;">
                <p style="width: 50%; text-align: left;">Fecha de prestado</p>
                <p style="width: 50%; text-align: right;">$fechaprestado</p>
            </div>
        </div>
        <br><br>
        <div>
            <p style="text-align: center; font-size: 12px; color: #666;">${Strings.letrasrecibo}</p>
            <br>
            <p style="text-align: center; font-size: 12px; color: #87898a;">$tiempo</p>
            <h4 style="text-align: center; font-size: 10px; color: #989999;">CONSERVAR ESTE RECIBO DE PAGO</h4>
            <P style="text-align: center; font-weight: bold; color: #b4b6b8;">ID $idpago</P>
        </div>
    </div>

    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
    </style>
</body>

</html>
    """;
      }
    }

    Directory dir = await getExternalStorageDirectory();
    String pathdirectorio = dir.path;
    var targetFileName = "recibo";

    File generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent, pathdirectorio, targetFileName);

    return generatedPdfFile;
  }

}

class Pagos{
  String fecha;
  String movimiento;
  String abono;
  String saldo;
  String hora;
  String id;

  Pagos({this.fecha, this.movimiento, this.abono, this.saldo, this.hora, this.id});

  static List<Pagos> getPagos() {
    return <Pagos>[
      //Pagos(fecha:"12/05/2020",movimiento:"abono",abono:"40000",saldo:"200000",hora:"11:30",id:"sidifhwsh4"),
    ];
  }
}

class movimientosprestamo extends StatefulWidget {
  String idPrestamo;
  movimientosprestamo(this.idPrestamo);
  @override
  _movimientosprestamoState createState() => _movimientosprestamoState();
}

class _movimientosprestamoState extends State<movimientosprestamo> {
  
  String idprestamo = null;
  String movimientos = "";

  ActualizarMovimientos()async{
    String movim = await getMovimientos();
    setState(() {
      movimientos = movim;
    });
  }
  
  @override
  void initState() {
    idprestamo = widget.idPrestamo;
    ActualizarMovimientos();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Text("$movimientos",style: TextStyle(fontSize: 9),),
        ),
      ),
    );
  }

  Future<String> getMovimientos()async{
    Database database = await opendb();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
    await database.close();
    String enter = "\n";
    String movimi = "";
    Map item = list[0];
    String movimient = item['movimientos'].toString();

    if (movimient.length > 0) {

      List<String> itemspagos = movimient.split("-");

      await Future.forEach(itemspagos, (itemmovimiento) {
        movimi = movimi+ itemmovimiento+enter;
      });
    }else{
      movimi = "Sin movimientos";
    }

    return movimi;
  }
}

//conectar impresora
class ConectarImpresora extends StatefulWidget {
  @override
  _ConectarImpresoraState createState() => _ConectarImpresoraState();
}

class _ConectarImpresoraState extends State<ConectarImpresora> {

  List items = new List();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initPlatformState());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conectar impresora'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("$msj",style: TextStyle(fontWeight: FontWeight.bold,color: Colores.primario),),
            OutlineButton(
              onPressed: (){
                this.initPlatformState();
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
                      this._connect(lista);
                    },
                    title: Text('${items[index]}'),
                  );
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RaisedButton.icon(
                  onPressed: null,
                  label: Text(_connected ? 'Desconectar' : 'Conectar'),
                  icon: Icon(_connected?Icons.bluetooth_audio:Icons.bluetooth_connected),
                ),
                RaisedButton.icon(
                  onPressed: _connected ? _tesPrint : null,
                  label: Text('Prueba'),
                  icon: Icon(Icons.print,),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {

    List lista = new List();
    try {
     lista = await PrintBluetoothThermal.getBluetooths;
    } catch(ex) {
      print("error: $ex");
    }
    setState(() {
      items = lista;
    });
  }

  void _connect(List lista) async {

    String name = lista[0];
    String mac = lista[1];

    String result = await PrintBluetoothThermal.conectar(mac);
    if(result=="true"){
      _connected = true;
      msj = "Concetado";
    }else{
      msj = "Fallo conexion bluetooth";
    }

    setState(() {

    });

  }

  void _disconnect() {

  }

  show(String mensaje){
    Flushbar(message: mensaje,).show(context);
  }

  void _tesPrint() async {

    //print("Imprimiendo prueba");

    String text = '\n';

    await PrintBluetoothThermal.writeBytes(text.codeUnits);

  }

}

void imprimirRecibo(Ticket ticket,BuildContext context,String idprestamo,String nombre)async{

  String estadoprint = await PrintBluetoothThermal.estadoConexion;
  print("estado print $estadoprint");
  if(estadoprint=="false"){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
    _connected = false;
  }else{
    List<int> list = ticket.bytes;
    //Uint8List bytes = Uint8List.fromList(list);
    //String string = String.fromCharCodes(bytes);
    //String string = String.fromCharCodes(list);
    //String text = "\n";
    _connected = true;
    String estado = await PrintBluetoothThermal.writeBytes(list);
  }
}


//registro clientes
class RegistroClientes extends StatefulWidget {
  String cedula;
  RegistroClientes(this.cedula);

  @override
  _RegistroClientesState createState() => _RegistroClientesState();
}

class _RegistroClientesState extends State<RegistroClientes>{

  bool _isexistCliente = false;
  bool _isvisiblecliente = false;
  bool _isvisibleprestamo = false;
  bool _isvisibleregistrar = false;
  bool imprimircompartir = false;
  bool visiblefinal = false;
  bool _visiblefecha = false;
  bool _visibleconsecutivo = true;
  bool _isprestamos = false;
  bool _enabledcouta = true;
  List<datoPrestamo> _itemsPrestamos;
  String key = Uuid().v1();
  String radioItem = '';
  int item = null;

  bool checksabado = false;
  bool checkdomingo = false;
  bool checkinteresconsecutivo = false;
  String prestamo = "Nuevo prestamo";
  String lplazo = "Plazo";
  double total = 0;
  int plazodiasF = 0;
  double interesF = 0;
  String nombre = "";
  Map datoprestamo = null;

  final _txtcedula = TextEditingController();
  final _txtnombre = TextEditingController();
  final _txtdireccion = TextEditingController();
  final _txttelefono = TextEditingController();

  final _txtcapital = TextEditingController();
  final _txtinteres = TextEditingController();
  final _txtvalorextra = TextEditingController();
  final _txtplazo = TextEditingController();
  final _txtcuota = TextEditingController();

  @override
  void initState() {
    super.initState();
    _txtcedula.text = widget.cedula;
  }

  @override
  void dispose() {
    _txtcedula.dispose();
    _txtnombre.dispose();
    _txtdireccion.dispose();
    _txttelefono.dispose();
    _txtcapital.dispose();
    _txtinteres.dispose();
    _txtvalorextra.dispose();
    _txtplazo.dispose();
    _txtcuota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro clientes"),
      ),
      body: Container(
        color: Colores.grisclaro,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: screenWidth(context) / 1.5,
                        padding: EdgeInsets.only(
                            left: 20, top: 10, right: 20, bottom: 0),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Cedula",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: _txtcedula,
                          onChanged: (text) {
                            if (text.length == 0) {
                              setState(() {
                                _isvisiblecliente = false;
                                _isvisibleprestamo = false;
                                _isvisibleregistrar = false;
                                visiblefinal = false;
                                imprimircompartir = false;
                                _isprestamos = false;
                              });
                            }
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: OutlineButton(
                          onPressed: () {
                            validarcedula();
                          },
                          child: Text("Validar"),
                        ),
                      )
                    ],
                  ),
                ),
                Visibility(
                  visible: _isvisiblecliente,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
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
                            controller: _txtnombre,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Direccion",
                              icon: Icon(Icons.home),
                            ),
                            controller: _txtdireccion,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Telefono",
                              icon: Icon(Icons.phone),
                            ),
                            controller: _txttelefono,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(),
                Visibility(
                  visible: _isprestamos,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _itemsPrestamos == null ? 0 : _itemsPrestamos.length,
                      itemBuilder: (context, index) {
                        if (_itemsPrestamos == null) {
                          return CircularProgressIndicator();
                        } else {
                          final item = _itemsPrestamos[index];
                          return _itemPrestamo(item);
                        }
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: _isvisibleprestamo,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          prestamo + " " + radioItem + " $total",
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Capital",
                              icon: Icon(Icons.monetization_on),
                            ),
                            controller: _txtcapital,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              calcularcuota();
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "% interes mensual",
                              icon: Icon(Icons.data_usage),
                            ),
                            controller: _txtinteres,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              calcularcuota();
                            },
                          ),
                        ),
                        Divider(
                          height: 10,
                          color: Colors.white,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:  radioItem == "Diario"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Diario'),
                                    value: 'Diario',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        lplazo = "Cuantos dias de plazo";
                                        _visiblefecha = false;
                                        _enabledcouta = true;
                                        _visibleconsecutivo = true;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 140,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:  radioItem == "Semanal"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Semanal'),
                                    value: 'Semanal',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        item = 2;
                                        lplazo = "Cuantas semanas de plazo";
                                        _visiblefecha = false;
                                        _enabledcouta = true;
                                        _visibleconsecutivo = true;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 160,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:  radioItem == "Quincenal"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Quincenal'),
                                    value: 'Quincenal',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        item = 3;
                                        lplazo = "Cuantas quincenas de plazo";
                                        _visiblefecha = false;
                                        _enabledcouta = true;
                                        _visibleconsecutivo = true;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 170,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:  radioItem == "Mensual"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Mensual'),
                                    value: 'Mensual',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        lplazo = "Cuantos meses de plazo";
                                        _visiblefecha = false;
                                        _enabledcouta = true;
                                        _visibleconsecutivo = true;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 150,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color:  radioItem == "Fijo"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Dia fijo'),
                                    value: 'Fijo',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        lplazo = "Total de dias";
                                        _txtvalorextra.text = fechaActual();
                                        _visiblefecha = true;
                                        _enabledcouta = false;
                                        _visibleconsecutivo = false;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 180,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: radioItem == "Personalizado"
                                        ? Colors.teal[200]
                                        : Colors.teal[50],
                                  ),
                                  child: RadioListTile(
                                    groupValue: radioItem,
                                    title: Text('Personalizado'),
                                    value: 'Personalizado',
                                    onChanged: (val) {
                                      setState(() {
                                        radioItem = val;
                                        lplazo = "Total de cuotas";
                                        _txtvalorextra.text = "";
                                        _visiblefecha = true;
                                        _enabledcouta = false;
                                        _visibleconsecutivo = false;
                                        calcularcuota();
                                      });
                                    },
                                  ),
                                  width: 200,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _visiblefecha,
                          child: Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: radioItem=="Personalizado"?"Dias para una cota":"Fecha de pago",
                                icon: Icon(Icons.calendar_today),
                              ),
                              controller: _txtvalorextra,
                              keyboardType: TextInputType.number,
                              onChanged: (num) {
                                calcularcuota();
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _visibleconsecutivo,
                          child: Container(
                            child: InkWell(
                              onTap: () {},
                              child: Container(
                                width: double.infinity,
                                child: new CheckboxListTile(
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  title:
                                  new Text("Interes consecutivo $radioItem"),
                                  value: checkinteresconsecutivo,
                                  onChanged: (bool value) {
                                    setState(() {
                                      checkinteresconsecutivo = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: lplazo,
                              icon: Icon(Icons.confirmation_number),
                            ),
                            controller: _txtplazo,
                            keyboardType: TextInputType.number,
                            onChanged: (num) {
                              calcularcuota();
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Cuotas de",
                              icon: Icon(Icons.blur_circular),
                            ),
                            controller: _txtcuota,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              calcularinteres();
                            },
                            enabled: _enabledcouta,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  width: 180,
                                  child: new CheckboxListTile(
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                    title: new Text("No cobrar sabados"),
                                    value: checksabado,
                                    onChanged: (bool value) {
                                      setState(() {
                                        checksabado = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  width: 180,
                                  child: new CheckboxListTile(
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                    title: new Text("No cobrar domingos"),
                                    value: checkdomingo,
                                    onChanged: (bool value) {
                                      setState(() {
                                        checkdomingo = value;
                                      });
                                    },
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
                SizedBox(height: 10,),
                Visibility(
                  visible: visiblefinal,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: <Widget>[
                        Visibility(
                          visible: _isvisibleregistrar,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            child: RaisedButton.icon(
                              label: Text("Registrar"),
                              icon:  Icon(Icons.save),
                              color: Colors.green,
                              textColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              onPressed: () {
                                registrar();
                              },
                              onLongPress: ()async{
                                Ticket ticket = await recibo(datoprestamo);
                                imprimirRecibo(ticket,context,"0",_txtnombre.text);
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: imprimircompartir,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: <Widget>[
                                Text("$total a $nombre",style: TextStyle(fontSize: 12),),
                                SizedBox(height: 10,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                        child: RaisedButton.icon(
                                          label: Text("Imprimir"),
                                          icon:  Icon(Icons.print),
                                          onPressed: () async{
                                            Ticket ticket = await recibo(datoprestamo);
                                            imprimirRecibo(ticket,context,"0",_txtnombre.text);
                                          },
                                          color: _connected?Colors.blue:Colors.blueGrey,
                                          textColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                        )
                                    ),
                                    Flexible(
                                        child: RaisedButton.icon(
                                          label: Text("Compartir"),
                                          icon:  Icon(Icons.share),
                                          onPressed: () {
                                            compratirRecibo();
                                          },
                                          color: Colors.blue,
                                          textColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                        )
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
                SizedBox(height: 10,),
              ],
            ),
          )),
    );
  }

  void calcularcuota() async {
    total = 0;
    interesF = 0;
    plazodiasF = 0;
    String modalidad = radioItem;
    double capital = 0;
    if (_txtcapital.text.trim().length > 0) {
      capital = double.parse(_txtcapital.text);
    }
    double interes = 0;
    if (_txtinteres.text.trim().length > 0) {
      interes = double.parse(_txtinteres.text);
    }
    int dias = 0;
    int plazo = 0;
    int diascuota = 1;
    String fecha = fechaActual();
    if (_txtplazo.text.trim().length > 0) {
      dias = int.parse(_txtplazo.text);
      plazo = int.parse(_txtplazo.text);
    }
    if(radioItem=='Fijo') {
      if (_txtvalorextra.text.trim().length > 0) {
        fecha = _txtvalorextra.text.trim();
      }
    }else if(radioItem=='Personalizado'){
      if (_txtvalorextra.text.trim().length > 0) {
        diascuota = int.parse(_txtvalorextra.text.trim());
      }
    }else if(radioItem=='Diario'){
      diascuota = 1;
    }else if(radioItem=='Semanal'){
      diascuota = 7;
    }else if(radioItem=='Quincenal'){
      diascuota = 15;
    }else if(radioItem=='Mensual'){
      diascuota = 30;
    }
    int diasmes = 30;
    if (modalidad == "Semanal") {
      plazo = plazo * 7;
      diasmes = 28;
    } else if (modalidad == "Quincenal") {
      plazo = plazo * 15;
    } else if (modalidad == "Mensual") {
      plazo = plazo * 30;
    } else if (modalidad == "Personalizado") {
      plazo = plazo * diascuota;
    }else if (modalidad == "Fijo") {
      int dias = await diasCorridos(fecha);
      int diaspositvo = (dias < 0) ? dias * -1 : 0; //combierte a positivo
      plazo = diaspositvo;
    }
    double interesmensual = capital * interes / 100;
    double interesdiario = interesmensual / diasmes;
    double newinteres = interesdiario * plazo;
    total = capital + newinteres;
    interesF = newinteres;
    plazodiasF = plazo;
    double cuota = total / dias;
    //print("==> modalidad: $modalidad total: $total cuota: $cuota plazodias: $plazo newinteres $newinteres");

    setState(() {
      if (modalidad == "Fijo") {
        _txtplazo.text = "$plazo";
        _txtcuota.text = "${dejarDosDecimales(total)}";
      } else {
        _txtcuota.text = "${dejarDosDecimales(cuota)}";
      }
    });
    //return dejarDosDecimales(cuota);
  }

  void calcularinteres() async {

    String modalidad = radioItem;
    double capital = 0;
    int dias = 0;
    int plazo = 0;
    double cuota = 0;
    String fecha = fechaActual();
    int diascuota = 1;
    if (_txtcapital.text.trim().length > 0) {
      capital = double.parse(_txtcapital.text);
    }
    if (_txtplazo.text.trim().length > 0) {
      dias = int.parse(_txtplazo.text);
      plazo = int.parse(_txtplazo.text);
    }
    if (_txtcuota.text.trim().length > 0) {
      cuota = double.parse(_txtcuota.text);
    }
    if (_txtvalorextra.text.trim().length > 0) {
      fecha = _txtvalorextra.text.trim();
    }
    if (_txtvalorextra.text.trim().length > 0) {
      diascuota = int.parse(_txtvalorextra.text.trim());
    }
    total = plazo * cuota;
    double interes = total - capital;
    interesF = interes;
    double porcentaje = (interes * 100) / capital;

    int plazodias = 30;
    if (modalidad == "Diario") {
      plazodias = plazo;
    } else if (modalidad == "Semanal") {
      plazodias = plazo * 7 + 2;
    } else if (modalidad == "Quincenal") {
      plazodias = plazo * 15;
    }else if (modalidad == "Personalizado") {
      plazodias = plazo * 15;
    }
    if (plazodias < 30) {
      double interesdia = interes / plazodias;
      double interes30dias = (interesdia * plazodias) + (interesdia * (30 - plazodias));
      porcentaje = (interes30dias * 100) / capital;
      //print("int2=> interes $interes por dias $plazodias interesdia $interesdia interesfinal $inteteresfinal capital: $capital");
    }if(plazodias>30){
      double interesdia = porcentaje / plazodias;
      double interesmes = interesdia*30;
      porcentaje = interesmes;
      //print("interes mes $interesmes interesdia $interesdia interes $interes");
    }

    //print(" interes=> modalidad: $modalidad total: $total cuota: $cuota plazo: $plazo interes: $interes porcentaje: $porcentaje plazodias $plazodias");

    setState(() {
      _txtinteres.text = dejarDosDecimales(porcentaje);
    });
  }

  Widget _itemPrestamo(datoPrestamo item) {
    //print("llego: ${item.modalidad}");

    String id = item.id;
    Color color = item.color;
    String estado = item.estado;
    String modalidad = item.modalidad;
    String saldo = item.saldo;
    String letras = item.cuota;

    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.circular(10),
        border: Border.all(
          width: 1,
          color: Colors.black12,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              "Prestamo $estado",
              style: TextStyle(color: Colors.white),
            ),
          ),
          Text("Modalidad: $modalidad"),
          Text("Saldo: $saldo"),
          Text(letras),
        ],
      ),
    );
  }

  Future<List<datoPrestamo>> leerPrestamos() async {
    Database database = await opendb();
    _itemsPrestamos = new List();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece =? ORDER BY id DESC", [key]);
    if (list.length > 0) {
      Future.forEach(list, (item) async {
        String id = item['id'].toString();
        double saldo = double.parse(await verSaldo(id));
        String cuota = item['cuota'].toString();
        String modalidad = item['modalidad'].toString();
        String ultimopago = item['ultimopago'].toString();
        String letras = "Cuota de $cuota";
        Color color = Colors.blue;
        String estado = "Activo";
        if (saldo == 0) {
          estado = "Pagado";
          color = Colors.blueGrey;
          letras = "Finalizo";
        }
        datoPrestamo value = new datoPrestamo(
            id, estado, modalidad, saldo.toString(), letras, color);
        _itemsPrestamos.add(value);
        setState(() {
          _isprestamos = true;
        });
      });
    }
  }

  validarcedula() async {
    key = Uuid().v1();
    String cedula = _txtcedula.text.trim();
    _isexistCliente = false; //no existe cliente validado
    item = 0; //quitar color radius
    _itemsPrestamos = null; //quitar lista de prestamos
    _isprestamos = false; //caja de prestamos invisible
    radioItem = ''; //lista de prestamos
    imprimircompartir = false; //botones imprimir compartir
    _txtnombre.clear();
    _txtdireccion.clear();
    _txttelefono.clear();
    _txtcapital.clear();
    _txtinteres.clear();
    _txtplazo.clear();
    _txtcuota.clear();
    total = 0;
    prestamo = "Nuevo prestamo";
    lplazo = "Plazo";

    if (cedula.length == 0) {
      return Flushbar(
        message: "Escriba una cedula",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(this.context);
    }
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM clientes WHERE cedula=?', [cedula]);
    //list.forEach((row) => print(row));
    if (list.length > 0) {
      _isexistCliente = true;
      key = list[0]['key'];
      _txtnombre.text = list[0]['nombre'];
      _txtdireccion.text = list[0]['direccion'];
      _txttelefono.text = list[0]['telefono'];
      nombre = list[0]['nombre'];
    }
    setState(() {
      _isvisiblecliente = true;
      _isvisibleprestamo = true;
      _isvisibleregistrar = true;
      visiblefinal = true;
    });
    database.close();
    leerPrestamos();
  }

  registrar() async {

    String cedula = _txtcedula.text.trim();
    String nombre = _txtnombre.text.trim().toUpperCase();
    String direccion = _txtdireccion.text.trim();
    String telefono = _txttelefono.text.trim();

    if (cedula.length == 0) {
      return Flushbar(
        message: "Verifique la cedula de registrar",
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      )..show(context);
    }
    if (nombre.length == 0) {
      return Flushbar(
        message: "El campo nombre es obliagtorio",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    }

    Database database = await opendb();
    if (_isexistCliente) {
      int id = await database.rawUpdate(
          'UPDATE clientes SET nombre = ?, direccion = ?, telefono = ? WHERE key = ?', [nombre, direccion, telefono, key]);
      print('actualizado: $id nombre: $nombre');
      database.close();
      registrarPrestamo();
      //return Flushbar(message: "Cliente actualizado exitoso",backgroundColor: Colors.blue,duration: Duration(seconds: 1),)..show(context);
    } else {
      int id;
      await database.transaction((txn) async {
        id = await txn.rawInsert('INSERT INTO clientes(key,nombre,cedula,direccion,telefono,posicion,grupo,cupo) VALUES(?,?,?,?,?,?,?,?)',
            [key, nombre, cedula, direccion, telefono, "0", "Principal","no"]);
        print('registrado: $id nombre: $nombre');
      });
      await database.close();
      await agregarResumenDia("nuevocliente", "Nuevo cliente $nombre",  "0", "0", "0","0", id.toString());
      registrarPrestamo();
      return Flushbar(
        message: "Cliente registrado exitoso",
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      )..show(context);
    }
  }

  registrarPrestamo() async {

    String fecha = fechaActual();
    String capital = _txtcapital.text.trim();
    if (capital.length == 0) {
      print("sin capital $capital");
      return;
    }

    String porcentaje = _txtinteres.text.trim();
    String mora = "0";
    String porcentajemora = "5/10";
    String diasmoracobrado = "0/0";
    String diasmora = "3/1";
    String modalidad = radioItem;
    String diascuota;
    if(modalidad=='Diario'){
      diascuota = "1";
    }else if(modalidad=='Semanal'){
      diascuota = "7";
    }else if(modalidad=='Quincenal'){
      diascuota = "15";
    }else if(modalidad=='Mensual'){
      diascuota = "30";
    }else if(modalidad=='Fijo'){
      diascuota = "1";
    }else if(modalidad=='Personalizado'){
      diascuota = _txtvalorextra.text.trim();
    }
    String interesconsecutivo = "no";
    if (checkinteresconsecutivo) interesconsecutivo = "si";
    String plazo = _txtplazo.text.trim();
    String cuota = _txtcuota.text.trim();
    String alarma = "0";
    String descontardias = "0";
    String diasnocobra = "";
    String sabad = "A";
    String doming = "A";
    if (checksabado) {
      sabad = "S";
    }
    if (checkdomingo) {
      doming = "D";
    }
    diasnocobra = "$sabad/$doming";

    String pagos = "";
    String movimientos = "creado prestamo $fecha ${horaActual()} capital: $capital interes: $interesF %: $porcentaje";

    if (porcentaje.length == 0) {
      return Flushbar(
        message: "Prestamo no creado falto el interes",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    } else if (modalidad.length == 0) {
      return Flushbar(
        message: "Prestamo no creado falto la modalidad",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    } else if (plazo.length == 0) {
      return Flushbar(
        message: "Prestamo no creado falto el plazo",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    } else if (cuota.length == 0) {
      return Flushbar(
        message: "Prestamo no creado falto el cuota",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    }else if (diascuota.length == 0) {
      return Flushbar(
        message: "Prestamo no creado falto el dias para la cuota",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      )..show(context);
    }

    _txtcapital.clear();
    _txtinteres.clear();
    _txtplazo.clear();
    _txtcuota.clear();
    checkinteresconsecutivo = false;
    checksabado = false;
    checkdomingo = false;

    Map item = await getCaja();
    String interescapital = item['interescapital'];
    String interesatraso = item['interesatraso'];
    String interesvencido = item['interesvencido'];
    String diasatraso = item['diasatraso'];
    String diasvencido = item['diasvencido'];
    porcentajemora = "$interesatraso/$interesvencido";
    diasmora = "$diasatraso/$diasvencido";

    int id;
    Database database = await opendb();

    await database.transaction((txn) async {
      id = await txn.rawInsert(
          'INSERT INTO prestamos(pertenece,fecha,capital,interes,porcentajecapital,diasinterescobrado,mora,porcentajemora,diasmoracobrado,diasmora,modalidad,diascuota,interesconsecutivo,plazo,cuota,alarma,descontardias,diasnocobra,ultimopago,pagos,movimientos) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
          [key, fecha, capital, interesF, porcentaje, plazodiasF, mora, porcentajemora, diasmoracobrado, diasmora, modalidad, diascuota, interesconsecutivo, plazo, cuota, alarma, descontardias, diasnocobra, fecha, pagos, movimientos]);
      print('insertado prestamo: $id ');
    });

    await database.close();

    //print("=====> Interes: $interesF capital $capital");

    datoprestamo = new Map();
    datoprestamo = {
      "total":"$total",
      "cuota": "$cuota",
      "modalidad":"$modalidad",
      "plazo":"$plazodiasF",
    };

    setState(() {
      prestamo = "Nuevo prestamo";
      lplazo = "Plazo";
      //total = 0;
      radioItem = '';
      checkdomingo = false;
      checksabado = false;
      _isvisiblecliente = false; //caja de cliente invisible
      _isvisibleprestamo = false; //caja de prestamos invisible
      _isprestamos = false; //lista de prestamos invisible
      _isvisibleregistrar = false; //boton registrar
      imprimircompartir = true; //visible imprimir compartir
    });

    //print("capital $capital interes $interesF");

    await agregarResumenDia("prestamo", "Prestamo a ${_txtnombre.text.toString()}", total.toString(), capital, interesF.toString(), porcentaje, id.toString());

    return Flushbar(
      message: "Prestamo creado exitoso",
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    )..show(context);
  }

  Future<Ticket> recibo(Map datoprestamo) async {

    String empresa = nombreempresa;
    String nombre = _txtnombre.text;
    String cedula = _txtcedula.text;

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    if(existelogo) {
      //final ByteData data = await rootBundle.load(pathlogo);
      final bytes = file.readAsBytesSync();
      //final Uint8List bytes = data.buffer.asUint8List();
      final image = Imag.decodeImage(bytes);
      ticket.image(image, align: PosAlign.center);
    }else {
      ticket.text('$empresa', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ));
    }

    //ticket.text('$telefono', styles: PosStyles(align: PosAlign.center));
    ticket.feed(1);

    ticket.text('${Strings.letrascontrato}', styles: PosStyles(align: PosAlign.left,codeTable: 'CP1252'));
    ticket.feed(1);

    ticket.text('Nuevo prestamo a:', styles: PosStyles(align: PosAlign.left));
    ticket.text('Nomb: $nombre',styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('C.c:  $cedula');
    ticket.feed(1);

    ticket.text('TOTAL:     $simbolomoneda${datoprestamo['total']}', styles: PosStyles(align: PosAlign.left));
    ticket.text('MODALIDAD: ${datoprestamo['modalidad']}', styles: PosStyles(align: PosAlign.left));
    ticket.text('PLAZO:     ${datoprestamo['plazo']}', styles: PosStyles(align: PosAlign.left));
    ticket.text('CUOTAS DE: $simbolomoneda${datoprestamo['cuota']}', styles: PosStyles(align: PosAlign.left));

    ticket.feed(1);

    ticket.text('Fir:___________________________', styles: PosStyles(align: PosAlign.left),linesAfter: 1);
    ticket.text('C.c:___________________________ ', styles: PosStyles(align: PosAlign.left),linesAfter: 1);
    ticket.text('Tel:___________________________ ', styles: PosStyles(align: PosAlign.left),linesAfter: 1);

    ticket.text("${fechaActual()} ${horaActual()}",styles: PosStyles(bold: true,align: PosAlign.center));
    ticket.feed(1);

    ticket.text('CONSERVAR ESTE RECIBO ', styles: PosStyles(align: PosAlign.center));
    ticket.text('No se acepta reclamaciones sin este recibo', styles: PosStyles(align: PosAlign.center));

    ticket.feed(3);

    return ticket;
  }

  void compratirRecibo()async{

    print("compartiendo recibos");
    File imghtml = await generarpdf(datoprestamo);

    List<int> bytes = await imghtml.readAsBytes();
    await Share.file('Recibo pdf', 'Nuevo_Prestamo.pdf', bytes, 'application/pdf');
    await imghtml.delete();
    await agregarResumenDia("impresion", "Impresion contrato a $nombre",  "0", "0", "0","0", "0");

  }

  Future<File> generarpdf(Map datoprestamo)async{

    String empresa = nombreempresa;
    String telefono = telefonoempresa;
    String moneda = simbolomoneda;
    String total = datoprestamo['total'];
    String cuota = datoprestamo['cuota'];
    String modalidad = datoprestamo['modalidad'];
    String plazo = datoprestamo['plazo'];
    String nombre = _txtnombre.text;
    String cedula = _txtcedula.text;

    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    var htmlContent;
    if(existelogo){
      htmlContent =
      """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="text-align: center; padding: 20px;">
        <img src="file://$pathlogo" alt="web-img">
        <p style="color: #2b74af;">$telefono</p>
    </div>
    <div style="padding: 20px;">
        <h3 style="color: #2baf6d;">Sr(a) $nombre</h3>
        <h5 style="color: #2baf6d;">C.c $cedula</h5>
    </div>

    <div style="padding: 10px; margin: 20px; border: 1px solid #c7c8c9; border-radius: 5px;">
        <h5 style="color: #2b74af;">Terminos del contrato</h5>
        <p style="font-size: 12px;">${Strings.letrascontrato}</p>
    </div>

    <div style="padding: 20px;">
        <table id="customers" style="border-radius: 5px; border-collapse: collapse; overflow: hidden;">
            <tr>
                <th>Tipo</th>
                <th>Valor</th>
            </tr>
            <tr>
                <td>Total prestado</td>
                <td>$total</td>
            </tr>
            <tr>
                <td>Cuotas de</td>
                <td>$cuota</td>
            </tr>
            <tr>
                <td>Modalidad</td>
                <td>$modalidad</td>
            </tr>
            <tr>
                <td>Plazo</td>
                <td>$plazo</td>
            </tr>
            <tr>
                <td>Fecha</td>
                <td>${fechaActual()}</td>
            </tr>
        </table>
    </div>
    <br><br><br>
    <div style="padding: 20px; text-align: center;">
        <p>______________________________________</p>
        <p style="color: #a9aaac;">Firma y c.c</p>
    </div>

    <div style="padding: 20px; text-align: center;">
        <p style="font-size: 9px; color:#b2b3b4">Por favor guardar este comprobante</p>
        <p style="color: #2b74af;">$empresa</p>
    </div>


    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
        
        #customers {
            font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
            border-collapse: collapse;
            width: 100%;
        }
        
        #customers td,
        #customers th {
            border: 1px solid #ddd;
            padding: 8px;
        }
        
        #customers tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        
        #customers tr:hover {
            background-color: #ddd;
        }
        
        #customers th {
            padding-top: 12px;
            padding-bottom: 12px;
            text-align: left;
            background-color: rgb(58, 177, 117);
            color: white;
        }
    </style>

</body>

</html>
    """;
    }else{
      htmlContent =
      """
    <!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recibo</title>
</head>

<body>

    <div style="text-align: center; padding: 20px;">
        <p style="font-weight: bold; font-size: 40px; color: #4A6C6F;">$empresa</p>
        <p style="color: #2b74af;">$telefono</p>
    </div>
    <div style="padding: 20px;">
        <h3 style="color: #2baf6d;">Sr(a) $nombre</h3>
        <h5 style="color: #2baf6d;">C.c $cedula</h5>
    </div>

    <div style="padding: 10px; margin: 20px; border: 1px solid #c7c8c9; border-radius: 5px;">
        <h5 style="color: #2b74af;">Terminos del contrato</h5>
        <p style="font-size: 12px;">${Strings.letrascontrato}</p>
    </div>

    <div style="padding: 20px;">
        <table id="customers" style="border-radius: 5px; border-collapse: collapse; overflow: hidden;">
            <tr>
                <th>Tipo</th>
                <th>Valor</th>
            </tr>
            <tr>
                <td>Total prestado</td>
                <td>$total</td>
            </tr>
            <tr>
                <td>Cuotas de</td>
                <td>$cuota</td>
            </tr>
            <tr>
                <td>Modalidad</td>
                <td>$modalidad</td>
            </tr>
            <tr>
                <td>Plazo</td>
                <td>$plazo</td>
            </tr>
            <tr>
                <td>Fecha</td>
                <td>${fechaActual()}</td>
            </tr>
        </table>
    </div>
    <br><br><br>
    <div style="padding: 20px; text-align: center;">
        <p>______________________________________</p>
        <p style="color: #a9aaac;">Firma y c.c</p>
    </div>

    <div style="padding: 20px; text-align: center;">
        <p style="font-size: 9px; color:#b2b3b4">Por favor guardar este comprobante</p>
        <p style="color: #2b74af;">$empresa</p>
    </div>


    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: sans-serif;
            max-width: 700px;
        }
        
        p {
            margin: 0 0 0 0;
            padding: 0;
        }
        
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            margin: 0 0 2px 0;
            padding: 0;
        }
        
        form {
            margin: 0;
            padding: 0;
        }
        
        #customers {
            font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
            border-collapse: collapse;
            width: 100%;
        }
        
        #customers td,
        #customers th {
            border: 1px solid #ddd;
            padding: 8px;
        }
        
        #customers tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        
        #customers tr:hover {
            background-color: #ddd;
        }
        
        #customers th {
            padding-top: 12px;
            padding-bottom: 12px;
            text-align: left;
            background-color: rgb(58, 177, 117);
            color: white;
        }
    </style>

</body>

</html>
    """;

    }

    Directory dir = await getExternalStorageDirectory();
    String pathdirectorio = dir.path;
    var targetFileName = "recibo";

    File generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent, pathdirectorio, targetFileName);

    return generatedPdfFile;
  }

}

class datoPrestamo {
  String id;
  String estado;
  String modalidad;
  String saldo;
  String cuota;
  Color color;

  datoPrestamo(
      this.id, this.estado, this.modalidad, this.saldo, this.cuota, this.color);
}

//editar clientes
class EditarPrestamo extends StatefulWidget {
  final String keyCliente;
  final String idprestamo;
  EditarPrestamo(this.keyCliente,this.idprestamo);
  @override
  _EditarPrestamoState createState() => _EditarPrestamoState();
}

class _EditarPrestamoState extends State<EditarPrestamo> {

  String idprestamo = null;
  String key = null;
  String radioItem = '';
  String lcuota = "Cuotas de";
  String lplazo = "Plazo";
  bool interesconsecutivo = false;
  //String letrasvalorextra = "Cuantos dias es una cuota";
  bool visiblevalorextra = false;

  bool visibleeditarcliente = false;
  bool visibleeditarprestamo = false;
  bool visiblepagos = false;
  bool visibleeditarmora = false;
  bool visibleconsecutivo = false;
  bool checksabado = false;
  bool checkdomingo = false;

  Map cliente = null;
  Map prestamo = null;
  List<Pagos> pagos = null;
  List<Pagos> selectedPagos = [];
  bool sort = true;

  final txtcedula = TextEditingController();
  final txtnombre = TextEditingController();
  final txttelefono = TextEditingController();
  final txtdireccion = TextEditingController();
  final txtgrupo = TextEditingController();

  final txtcapital = TextEditingController();
  final txtinteres = TextEditingController();
  final txtcuota = TextEditingController();
  final txtvalorextra = TextEditingController();
  final txtplazo = TextEditingController();
  final txtfechaprestado = TextEditingController();
  final txtporcentajecapital = TextEditingController();
  final txtinteresconsecutivo = TextEditingController();
  final txtdiasinterescobrado = TextEditingController();
  final txtdiasnocobra = TextEditingController();
  final txtdescontardias = TextEditingController();
  final txtpagos = TextEditingController();
  final txtmovimientos = TextEditingController();

  final txtmora = TextEditingController();
  final txtporcentajeatraso = TextEditingController();
  final txtporcentajevencido = TextEditingController();
  final txtcuotasaplicaratraso = TextEditingController();
  final txtcuotasaplicarvencido = TextEditingController();
  final txtdiascobradoatraso = TextEditingController();
  final txtdiascobradovencido = TextEditingController();

  cargardatos()async{
    await this.cargardatosCliente();
    await this.cargardatosPrestamo();
    await this.getPagos();
  }

  @override
  void initState() {
    idprestamo = widget.idprestamo;
    key = widget.keyCliente;
    this.cargardatos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(0),
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: <Widget>[
                    Text("Puede editar toda la informacion del cliente quedara un registro de las modificaciones",style: TextStyle(fontSize: 12),),
                    Text(cliente==null?"":"id cliente: ${cliente['key']}",style: TextStyle(color: Colors.blue),),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: (){
                        setState(() {
                          visibleeditarcliente = !visibleeditarcliente;
                        });
                      },
                      title: Text("Datos del cliente"),
                      trailing: visibleeditarcliente?Icon(Icons.remove_circle,color: Colores.moradooscuro,):Icon(Icons.arrow_drop_down_circle,color: Colores.amarillo,),
                      leading: Icon(Icons.person),
                    ),
                    Visibility(
                      visible: visibleeditarcliente,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Cedula",
                                icon: Icon(Icons.credit_card),
                              ),
                              controller: txtcedula,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Nombre",
                                icon: Icon(Icons.person_outline),
                              ),
                              controller: txtnombre,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Direccion",
                                icon: Icon(Icons.home),
                              ),
                              controller: txtdireccion,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Telefono",
                                icon: Icon(Icons.phone),
                              ),
                              controller: txttelefono,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Grupo",
                                icon: Icon(Icons.group_work),
                              ),
                              controller: txtgrupo,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: <Widget>[
                                RaisedButton(
                                  onPressed: (){
                                    guardarCliente();
                                  },
                                  child: Text("Guardar"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: (){
                        setState(() {
                          visibleeditarprestamo = !visibleeditarprestamo;
                        });
                      },
                      title: Text("Datos del prestamo"),
                      trailing: visibleeditarprestamo?Icon(Icons.remove_circle,color: Colores.moradooscuro,):Icon(Icons.arrow_drop_down_circle,color: Colores.amarillo,),
                      leading: Icon(Icons.monetization_on),
                    ),
                    Visibility(
                      visible: visibleeditarprestamo,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Fecha de prestado",
                                icon: Icon(Icons.calendar_today),
                              ),
                              controller: txtfechaprestado,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Capital",
                                icon: Icon(Icons.monetization_on),
                              ),
                              controller: txtcapital,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Interes",
                                icon: Icon(Icons.pie_chart),
                              ),
                              controller: txtinteres,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "% interes mensual",
                                icon: Icon(Icons.data_usage),
                              ),
                              controller: txtporcentajecapital,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Dias interes cobrados",
                                icon: Icon(Icons.featured_play_list),
                              ),
                              controller: txtdiasinterescobrado,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Descontar dias",
                                icon: Icon(Icons.developer_board),
                              ),
                              controller: txtdescontardias,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Divider(
                            height: 10,
                            color: Colors.white,
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color:  radioItem == "Diario"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Diario'),
                                      value: 'Diario',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Cuantos dias de plazo";
                                          visiblevalorextra = false;
                                          visibleconsecutivo = true;
                                        });
                                      },
                                    ),
                                    width: 140,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color:  radioItem == "Semanal"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Semanal'),
                                      value: 'Semanal',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Cuantas semanas de plazo";
                                          visiblevalorextra = false;
                                          visibleconsecutivo = true;
                                        });
                                      },
                                    ),
                                    width: 160,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color:  radioItem == "Quincenal"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Quincenal'),
                                      value: 'Quincenal',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Cuantas quincenas de plazo";
                                          visiblevalorextra = false;
                                          visibleconsecutivo = true;
                                        });
                                      },
                                    ),
                                    width: 170,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color:  radioItem == "Mensual"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Mensual'),
                                      value: 'Mensual',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Cuantos meses de plazo";
                                          visiblevalorextra = false;
                                          visibleconsecutivo = true;
                                        });
                                      },
                                    ),
                                    width: 150,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color:  radioItem == "Fijo"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Dia fijo'),
                                      value: 'Fijo',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Total de dias";
                                          txtvalorextra.text = "0";
                                          visiblevalorextra = true;
                                          visibleconsecutivo = false;
                                        });
                                      },
                                    ),
                                    width: 180,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: radioItem == "Personalizado"
                                          ? Colors.teal[200]
                                          : Colors.teal[50],
                                    ),
                                    child: RadioListTile(
                                      groupValue: radioItem,
                                      title: Text('Personalizado'),
                                      value: 'Personalizado',
                                      onChanged: (val) {
                                        setState(() {
                                          radioItem = val;
                                          lplazo = "Total de cuotas";
                                          txtvalorextra.text = "0";
                                          visiblevalorextra = true;
                                          visibleconsecutivo = true;
                                        });
                                      },
                                    ),
                                    width: 200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: visiblevalorextra,
                            child: Container(
                              padding: EdgeInsets.only(),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: radioItem=="Personalizado"?"Dias para una cota":"Dias de plazo",
                                  icon: Icon(Icons.developer_board),
                                ),
                                controller: txtvalorextra,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: visibleconsecutivo,
                            child: Container(
                              child: InkWell(
                                onTap: () {},
                                child: Container(
                                  width: double.infinity,
                                  child: new CheckboxListTile(
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                    title:
                                    new Text("Interes consecutivo $radioItem"),
                                    value: interesconsecutivo,
                                    onChanged: (bool value) {
                                      setState(() {
                                        interesconsecutivo = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: lplazo,
                                icon: Icon(Icons.confirmation_number),
                              ),
                              controller: txtplazo,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Cuotas de",
                                icon: Icon(Icons.blur_circular),
                              ),
                              controller: txtcuota,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    width: 180,
                                    child: new CheckboxListTile(
                                      controlAffinity:
                                      ListTileControlAffinity.leading,
                                      title: new Text("No cobrar sabados"),
                                      value: checksabado,
                                      onChanged: (bool value) {
                                        setState(() {
                                          checksabado = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    width: 180,
                                    child: new CheckboxListTile(
                                      controlAffinity:
                                      ListTileControlAffinity.leading,
                                      title: new Text("No cobrar domingos"),
                                      value: checkdomingo,
                                      onChanged: (bool value) {
                                        setState(() {
                                          checkdomingo = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                RaisedButton(
                                  onPressed: (){
                                    guardarEdicion();
                                  },
                                  child: Text("Guardar"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: (){
                        setState(() {
                          visiblepagos = !visiblepagos;
                        });
                      },
                      title: Text("Historial de pagos"),
                      trailing: visiblepagos?Icon(Icons.remove_circle,color: Colores.moradooscuro,):Icon(Icons.arrow_drop_down_circle,color: Colores.amarillo,),
                      leading: Icon(Icons.assignment),
                    ),
                    Visibility(
                      visible: visiblepagos,
                      child: Column(
                        children: <Widget>[
                          //Container(child: Text("Aqui va la tabla de pagos")),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: <Widget>[
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: pagos==null?Container():SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      sortAscending: sort,
                                      sortColumnIndex: 0,
                                      columns: [
                                        DataColumn(
                                            label: Text("Fecha"),
                                            numeric: false,
                                            tooltip: "Fecha del balance",
                                            onSort: (columnIndex, ascending) {
                                              setState(() {
                                                sort = !sort;
                                              });
                                              onSortColum(columnIndex, ascending);
                                            }),
                                        DataColumn(
                                          label: Text(
                                            "Abono", style: TextStyle(fontWeight: FontWeight.bold),),
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Text(
                                            "Saldo", style: TextStyle(fontWeight: FontWeight.bold),),
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Text("Movimiento",
                                            style: TextStyle(fontWeight: FontWeight.bold),),
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Text(
                                            "Id", style: TextStyle(fontWeight: FontWeight.bold),),
                                          numeric: false,
                                        ),
                                      ],
                                      rows: pagos == null
                                          ? Pagos.getPagos()
                                          : pagos.map(
                                            (user) => DataRow(
                                            selected: selectedPagos.contains(user),
                                            onSelectChanged: (b) {
                                              print("Onselect");
                                              onSelectedRow(b, user);
                                            },
                                            cells: [
                                              DataCell(
                                                Text(user.fecha),
                                                onTap: () {
                                                  print('Selected ${user.fecha}');
                                                },
                                              ),
                                              DataCell(
                                                Text(user.abono),
                                                onTap: () {
                                                  print('Selected ${user.abono}');
                                                },
                                              ),
                                              DataCell(
                                                Text(user.saldo),
                                                onTap: () {
                                                  print('Selected ${user.saldo}');
                                                },
                                              ),
                                              DataCell(
                                                Text(user.movimiento),
                                                onTap: () {
                                                  print('Selected ${user.movimiento}');
                                                },
                                              ),
                                              DataCell(
                                                Text(user.id),
                                                onTap: () {
                                                  print('Selected ${user.id}');
                                                },
                                              ),
                                            ]),
                                      )
                                          .toList(),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.only(left: 20, bottom: 20),
                                      child: OutlineButton(
                                        child: Text('SELECT ${selectedPagos.length}'),
                                        onPressed: () {},
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 20, bottom: 20),
                                      child: OutlineButton(
                                        child: Text('BORRAR ${selectedPagos.length}', style: TextStyle(color: selectedPagos.isEmpty ? null : Colors.red),),
                                        onPressed: selectedPagos.isEmpty ? null : () {deleteSelected();},
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      onTap: (){
                        setState(() {
                          visibleeditarmora = !visibleeditarmora;
                        });
                      },
                      title: Text("Datos de la mora"),
                      trailing: visibleeditarmora?Icon(Icons.remove_circle,color: Colores.moradooscuro,):Icon(Icons.arrow_drop_down_circle,color: Colores.amarillo,),
                      leading: Icon(Icons.attach_money),
                    ),
                    Visibility(
                      visible: visibleeditarmora,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              controller: txtmora,
                              decoration: InputDecoration(
                                  labelText: "Mora "
                              ),
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtporcentajeatraso,
                                    decoration: InputDecoration(
                                        labelText: "Porcentaje atraso "
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtporcentajevencido,
                                    decoration: InputDecoration(
                                        labelText: "Porcentaje vencido "
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtcuotasaplicaratraso,
                                    decoration: InputDecoration(
                                        labelText: "Cuotas atraso aplicar"
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtcuotasaplicarvencido,
                                    decoration: InputDecoration(
                                        labelText: "Cuotas vencido aplicar "
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtdiascobradoatraso,
                                    decoration: InputDecoration(
                                        labelText: "Dias atraso cobrados"
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  child: TextField(
                                    controller: txtdiascobradovencido,
                                    decoration: InputDecoration(
                                        labelText: "Dias vencido cobrados"
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                RaisedButton(
                                  onPressed: (){
                                    guardarMora();
                                  },
                                  child: Text("Guardar"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlineButton(
                onPressed: (){
                  this.modalEliminarPrestamo();
                },
                child: Text("ELIMINAR ESTE PRESTAMO",style: TextStyle(color: Colors.red),),
                color: Colors.red,
                splashColor: Colors.red,
                highlightedBorderColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Pagos>> getPagos() async {
    Database database = await opendb();
    List<Pagos> listapagos = new List();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
    await database.close();

    Map item = list[0];
    String lpagos = item['pagos'].toString();

    if (lpagos.length > 0) {

      List<String> itemspagos = lpagos.split("-");

      await Future.forEach(itemspagos, (itempago) {
        List<String> pago = itempago.split(" ");
        try {
          String fecha = pago[0];
          String hora = pago[1];
          String movimiento = pago[2];
          String abono = pago[3];
          String saldo = pago[4];
          String id = pago[5];

          listapagos.add(Pagos(fecha: fecha,
              hora: hora,
              movimiento: movimiento,
              abono: abono,
              saldo: saldo,
              id: id));

        }catch(e){

        }
      });

    }else{
      listapagos = Pagos.getPagos();
    }

    setState(() {
      pagos = listapagos;
    });

    return listapagos;

  }

  deleteSelected() async {

    double abonoborro = 0;
    double moraborro = 0;
    if (selectedPagos.isNotEmpty) {
      List<Pagos> temp = [];
      temp.addAll(selectedPagos);
      for (Pagos pago in temp) {
        pagos.remove(pago);
        selectedPagos.remove(pago);
        String movimient = pago.movimiento;
        if(movimient=="Abono_mora"){
          moraborro = moraborro + double.parse(pago.abono);
        }else{
          abonoborro = abonoborro + double.parse(pago.abono);
        }
        String movimiento = "pago_borrado: ${pago.fecha} ${pago.movimiento}: ${pago.abono} saldo: ${pago.saldo} id: ${pago.id}";
        await agregarMovimientoPrestamo(idprestamo, movimiento);
        await agregarMovimientoPrestamo(idprestamo, "abono borro $abonoborro moraborro $moraborro");
        await agregarResumenDia("pagoborrado",movimiento, "0",  "0", "0", "0", "0");
      }
      print("abono borro $abonoborro moraborro $moraborro");

      //actualizar saldos
      Database database = await opendb();
      List<Map> prestamo = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
      Map item = prestamo[0];
      //print("item: $item");
      //double cuota = double.parse(item['cuota'].toString());
      //int plazo = int.parse(item['plazo'].toString());
      //double totalprestado = cuota * plazo;
      double capital = double.parse(item['capital'].toString());
      double interes = double.parse(item['interes'].toString());
      double mora = double.parse(item['mora'].toString());
      double capitalFinal = capital+abonoborro;
      double moraFinal = mora+moraborro;
      print(" capital: $capital interes: $interes mora: $mora");
      int count = await database.rawUpdate('UPDATE prestamos SET capital =?, mora=? WHERE id = ?', [capitalFinal, moraFinal, idprestamo]);
      await database.close();
    }

    String lpagos = "";
    for (Pagos pago in pagos) {
      String fecha = pago.fecha;
      String hora = pago.hora;
      String abono = pago.abono;
      String saldo = pago.saldo;
      String movim = pago.movimiento;
      String id = pago.id;
      lpagos = lpagos + "$fecha $hora $movim $abono $saldo $id"+"-";
    }
    //actualiza los pagos
    Database database = await opendb();
    await database.rawUpdate('UPDATE prestamos SET pagos=? WHERE id=?',[lpagos,idprestamo]);
    await database.close();
    //print("pagos $lpagos");

    setState(() {

    });
  }

  onSelectedRow(bool selected, Pagos pago) async {
    setState(() {
      if (selected) {
        selectedPagos.add(pago);
      } else {
        selectedPagos.remove(pago);
      }
    });
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (ascending) {
        pagos.sort((a, b) => a.fecha.compareTo(b.fecha));
      } else {
        pagos.sort((a, b) => b.fecha.compareTo(a.fecha));
      }
    }
  }

  cargardatosCliente()async{

    Database database = await opendb();
    List<Map> client = await database.rawQuery("SELECT * FROM clientes WHERE key =?", [key]);
    await database.close();
    if(client.length>0){
      cliente = client[0];
      Map item = cliente;
      String id = item['id'].toString();
      String nombre = item['nombre'].toString();
      String cedula = item['cedula'].toString();
      String direccion = item['direccion'].toString();
      String telefono = item['telefono'].toString();
      String posicion = item['posicion'].toString();
      String grupo = item['grupo'].toString();
      String cupo = item['cupo'].toString();

      txtcedula.text = cedula;
      txtnombre.text = nombre;
      txtdireccion.text = direccion;
      txttelefono.text = telefono;
      txtgrupo.text = grupo;

      setState(() {

      });

    }
  }

  cargardatosPrestamo()async{
    Database database = await opendb();
    List<Map> list = await database.rawQuery("SELECT * FROM prestamos WHERE id =?", [idprestamo]);
    await database.close();
    if (list.length > 0) {
      prestamo = list[0];
      Map item = prestamo;
      String id = item['id'].toString();
      String fecha = item['fecha'].toString();
      String capital = item['capital'].toString();
      String interes = item['interes'].toString();
      String porcentajecapital = item['porcentajecapital'].toString();
      String modalidad = item['modalidad'].toString();
      String interesConsecutivo = item['interesconsecutivo'].toString();
      String diasinterescobrado = item['diasinterescobrado'].toString();
      String plazo = item['plazo'].toString();
      String cuota = item['cuota'].toString();
      String alarma = item['alarma'].toString();
      String descontardias = item['descontardias'].toString();
      String diasnocobra = item['diasnocobra'].toString();
      String ultimopago = item['ultimopago'].toString();
      String diascuota = item['diascuota'].toString();
      String pagos = item['pagos'].toString();
      String movimientos = item['movimientos'].toString();
      String mora = item['mora'].toString();
      String porcentajemora = item['porcentajemora'].toString();
      String diasmora = item['diasmora'];
      String diasmoracobrado = item['diasmoracobrado'].toString();

      if(modalidad!="Fijo"){
        visibleconsecutivo = true;
        visiblevalorextra = false;
        if(interesConsecutivo=="si"){
          interesconsecutivo = true;
        }else{
          interesconsecutivo = false;
        }
      }else {
        visibleconsecutivo = false;
        visiblevalorextra = true;
      }

      List<String> dia = diasnocobra.split("/");
      String sabado = dia[0];
      String domingo = dia[1];
      if(sabado=="S"){
        checksabado = true;
      }else{
        checksabado = false;
      }
      if(domingo=="D"){
        checkdomingo = true;
      }else{
        checkdomingo = false;
      }

      txtfechaprestado.text = fecha;
      txtcapital.text = capital;
      txtinteres.text = interes;
      txtporcentajecapital.text = porcentajecapital;
      txtdiasinterescobrado.text = diasinterescobrado;
      txtdescontardias.text = descontardias;
      radioItem = modalidad;
      txtvalorextra.text = diascuota;
      txtvalorextra.text = diascuota;
      txtplazo.text = plazo;
      txtcuota.text = cuota;

      //mora
      List pormora = porcentajemora.split("/");
      String interesmora = pormora[0];
      String interesvencido = pormora[1];
      List aplimora = diasmora.split("/");
      String poratraso = aplimora[0];
      String porvencido = aplimora[1];
      List cobradomora = diasmoracobrado.split("/");
      String cobradoatraso = cobradomora[0];
      String cobradovencido = cobradomora[1];

      txtmora.text = mora;
      txtporcentajeatraso.text = interesmora;
      txtporcentajevencido.text = interesvencido;
      txtcuotasaplicaratraso.text = poratraso;
      txtcuotasaplicarvencido.text = porvencido;
      txtdiascobradoatraso.text = cobradoatraso;
      txtdiascobradovencido.text = cobradovencido;

      setState(() {

      });

    }
  }

  guardarCliente()async{

    String cedula = txtcedula.text;
    String nombre = txtnombre.text.toUpperCase();
    String direccion = txtdireccion.text;
    String telefono = txttelefono.text.trim();
    String grupo = txtgrupo.text.trim();
    String cupo = "-1";
    if(cedula.trim().length==0){
      return Flushbar(message: "Falta la cedula",backgroundColor: Colors.orange, duration: Duration(seconds: 3),)..show(context);
    }else if(nombre.trim().length==0){
      return Flushbar(message: "Falta el nombre",backgroundColor: Colors.orange, duration: Duration(seconds: 3),)..show(context);
    }
    if(direccion.trim().length==0)direccion = "";
    if(telefono.trim().length==0)telefono = "";

    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE clientes SET cedula = ?, nombre =?, direccion =?, telefono=?, grupo=? WHERE key = ?', [cedula,nombre,direccion,telefono,grupo,key]);
    await database.close();

    await agregarResumenDia("clienteeditado", "edito datos del cliente", "0", "0", "0", "0", "0");

    Flushbar(message: "Cliente editado exitoso",backgroundColor: Colors.blue,duration: Duration(seconds: 2),).show(context);
  }

  guardarEdicion()async{

    String capital = txtcapital.text;
    String interes = txtinteres.text;
    String modalidad = radioItem;
    String plazo = txtplazo.text.trim();
    String diascuota = txtvalorextra.text;
    String cuota = txtcuota.text;
    String fecha = txtfechaprestado.text;
    String porcentajecapital = txtporcentajecapital.text;
    String interesConsecutivo = txtinteresconsecutivo.text;
    String diasinterescobrado = txtdiasinterescobrado.text;
    String diasnocobra = "A/A";
    String descontardias = txtdescontardias.text;
    //String pagos = txtpagos.text;
    //String movimientos = txtmovimientos.text;
    if(capital.trim().length==0)capital="0";
    if(interes.trim().length==0)interes="0";
    if(plazo.trim().length==0)plazo="0";
    if(diascuota.trim().length==0)diascuota="0";
    if(cuota.trim().length==0)cuota="0";
    if(fecha.trim().length==0)fecha=fechaActual();
    if(porcentajecapital.trim().length==0)porcentajecapital="0";
    if(diasinterescobrado.trim().length==0)diasinterescobrado="0";
    if(descontardias.trim().length==0)descontardias="0";

    if(interesconsecutivo){
      interesConsecutivo = "si";
    }else{
      interesConsecutivo = "no";
    }

    String sabado = "A";
    String domingo = "A";
    if(checksabado){
      sabado = "S";
    }
    if(checkdomingo){
      domingo = "D";
    }
    diasnocobra = sabado+"/"+domingo;

    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE prestamos SET capital = ?, interes =?, modalidad =?, plazo =?, diascuota =?, cuota =?, fecha =?, porcentajecapital =?, interesconsecutivo =?,diasinterescobrado =?, diasnocobra=?, descontardias =? WHERE id = ?', [capital,interes,modalidad,plazo,diascuota,
      cuota,fecha,porcentajecapital,interesConsecutivo,diasinterescobrado,diasnocobra,descontardias,idprestamo]);
    await database.close();

    await agregarResumenDia("clienteeditado", "edito el prestamo capital: $capital interes: $interes", "0", "0", "0", "0", idprestamo);
    await agregarMovimientoPrestamo(idprestamo, "edito el prestamo capital: $capital interes: $interes");

    Flushbar(message: "Prestamo editado exitoso",backgroundColor: Colors.blue,duration: Duration(seconds: 2),).show(context);
  }

  guardarMora()async{

    if(txtmora.text.trim().length==0)txtmora.text = "0";
    if(txtporcentajeatraso.text.trim().length==0)txtporcentajeatraso.text = "0";
    if(txtporcentajevencido.text.trim().length==0)txtporcentajevencido.text = "0";
    if(txtdiascobradoatraso.text.trim().length==0)txtdiascobradoatraso.text = "0";
    if(txtdiascobradovencido.text.trim().length==0)txtdiascobradovencido.text = "0";
    if(txtcuotasaplicaratraso.text.trim().length==0)txtcuotasaplicaratraso.text = "0";
    if(txtcuotasaplicarvencido.text.trim().length==0)txtcuotasaplicarvencido.text = "0";

    String mora = txtmora.text;
    String porcentajeinteres = txtporcentajeatraso.text+"/"+txtporcentajevencido.text;
    String diasmoracobrado = txtdiascobradoatraso.text+"/"+txtdiascobradovencido.text;
    String diasmora = txtcuotasaplicaratraso.text+"/"+txtcuotasaplicarvencido.text;

    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE prestamos SET mora =?, porcentajemora =?, diasmoracobrado=?,diasmora=? WHERE id = ?', [mora,porcentajeinteres,diasmoracobrado,diasmora,idprestamo]);
    await database.close();

    await agregarResumenDia("clienteeditado", "edito la mora: $mora ", "0", "0", "0", "0", idprestamo);
    await agregarMovimientoPrestamo(idprestamo, "edito la mora: $mora (% $porcentajeinteres) (aplica:$diasmora) (cobrado:$diasmoracobrado) ");

    Flushbar(message: "Mora editado exitoso",backgroundColor: Colors.blue,duration: Duration(seconds: 2),).show(context);
  }

  modalEliminarPrestamo()async{
    var baseDialog = BaseAlertDialog(
      title: Text("ELIMINAR PRESTAMO",style: TextStyle(color: Colors.red),),
      content: Text("Se eliminara el prestamo $idprestamo de ${txtnombre.text}",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("ELIMINAR",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        this.eliminarprestamo();
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);
  }

  eliminarprestamo()async{

    Database database = await opendb();
    int count = await database.rawDelete('DELETE FROM prestamos WHERE id = ?', [idprestamo]);
    await database.close();
    print("elimino. $count");
    if(count==1){
      await agregarResumenDia("borroprestamo", "Se borro el prestamo de ${txtnombre.text}", "0", "${txtcapital.text}", "${txtinteres.text}", "0", "0");
      Flushbar(message: "Prestamo eliminado",duration: Duration(seconds: 4),backgroundColor: Colors.red,).show(context);
    }

  }

}

//ordenar y mover clientes
class Ordenar extends StatefulWidget {
  @override
  _OrdenarState createState() => _OrdenarState();
}

class _OrdenarState extends State<Ordenar> {

  List<Map> listaGrupos = new List();
  String grupoSeleccionado = "";
  List<Map> listaClientes = new List();
  int totalclientes = 0;
  String msj = "";

  @override
  void initState() {
    this.getListaGrupos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              SizedBox(height: 10,),
              Text("$msj"),
              Container(
                height: 70,
                width: double.infinity,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: listaGrupos==null?0:listaGrupos.length,
                    itemBuilder: (context, index) {
                      if(listaGrupos==null){
                        return CircularProgressIndicator();
                      }else{
                        Map item = listaGrupos[index];
                        return InkWell(
                          onTap: (){
                            grupoSeleccionado = item['grupo'];
                            getClientesGrupo(true);
                          },
                          child: Container(
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1,color: item['grupo']==grupoSeleccionado?Colors.blueAccent:Colors.black),
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                            ),
                            child: Text("${item['grupo']}",style: TextStyle(color: item['grupo']==grupoSeleccionado?Colors.blueAccent:Colors.black,fontWeight: FontWeight.bold),),
                          ),
                        );
                      }
                    }),
              ),
              Visibility(
                visible: grupoSeleccionado.length>0?true:false,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      OutlineButton(
                        onPressed: (){
                          getClientesGrupo(true);
                        },
                        child: Text("Con prestamo"),
                      ),
                      OutlineButton(
                        onPressed: (){
                          getClientesGrupo(false);
                        },
                        child: Text("Sin prestamo"),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: screenHeight(context)-80,
                child: ReorderableListView(
                  scrollDirection: Axis.vertical,
                  children: listaClientes == null
                      ?  CircularProgressIndicator()
                      : List.generate(listaClientes == null ? 0 : listaClientes.length, (index) {
                        Map item = listaClientes[index];
                        return Container(
                          key: Key('$index'),
                          height: 60,
                          child: ListTile(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>Mover(item['id'],item['nombre'])));
                            },
                            title: Text("${item['nombre']}"),
                            subtitle: Text("${item['direccion']}",style: TextStyle(fontSize: 12),),
                            trailing: Icon(Icons.dehaze),
                          ),
                        );
                      }),
                  onReorder: (int start, int current) {
                    //print("star $start current $current");
                    // arrastrando de arriba a abajo
                    if (start < current) {
                      int end = current - 1;
                      Map startItem = listaClientes[start];
                      int i = 0;
                      int local = start;
                      do {
                        listaClientes[local] = listaClientes[++local];
                        i++;
                      } while (i < end - start);
                      listaClientes[end] = startItem;
                    }
                    // arrastrando de abajo hacia arriba
                    else if (start > current) {
                      Map startItem = listaClientes[start];
                      for (int i = start; i > current; i--) {
                        listaClientes[i] = listaClientes[i - 1];
                      }
                      listaClientes[current] = startItem;
                    }
                    setState(() {
                      /*lista.forEach((element) {
              print("orden: ${element.nombre}");
            });*/
                    });
                    ordenarClientes(listaClientes);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4.0,
        icon: const Icon(Icons.mode_edit),
        label: const Text('Renombrar grupos'),
        onPressed: () {
          if(listaGrupos.length>0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RenombrarGrupos()));
          }else{
            Flushbar(message: "No hay clientes",duration: Duration(seconds: 3),).show(context);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            //IconButton(icon: Icon(Icons.menu), onPressed: () {},),
            //IconButton(icon: Icon(Icons.search), onPressed: () {},),
          ],
        ),
      ),
    );
  }

  getListaGrupos()async{

    listaGrupos = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();
    List<Map> lista = new List();
    int total = 0;
    int recorrido = 0;
    String grupova = "";
    if(clientes.length>0){

      //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
      // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
      await Future.forEach(clientes, (cliente){

        String key = cliente['key'].toString();
        String grupo = cliente['grupo'].toString();
        String nombre = cliente['nombre'].toString();
        String direccion = cliente['direccion'].toString();

        if(grupova!=grupo&&total>0){
          lista.add({"grupo": grupova, "total": total});
          grupova = grupo;
          total = 1;
        }else{
          total++;
          grupova = grupo;
        }
        recorrido++;
        if(clientes.length==recorrido){
          lista.add({"grupo": grupova, "total": total});
        }

      });

    }else{

    }

    setState(() {
      listaGrupos = lista;
    });
  }

  getClientesGrupo(bool conprestamo)async{

    //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
    // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
    listaClientes = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes WHERE grupo=? ORDER BY posicion ASC",[grupoSeleccionado]);
    await database.close();

    totalclientes = 0;
    String fechaactual = fechaActual();
    List<Map> lista = new List();
    await Future.forEach(clientes, (cliente) async {

      String id = cliente['id'].toString();
      String key = cliente['key'];
      String nombre = cliente['nombre'];
      String direccion = cliente['direccion'];

      Database database = await opendb();
      List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=? AND capital>'0' ",[key]);
      await database.close();

      int totalprestamos = prestamos.length;

      if(conprestamo) {
        if(totalprestamos>0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "key": key,
          });
          totalclientes++;
        }
      }else{
        if(totalprestamos<=0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "key": key,
          });
          totalclientes++;
        }
      }

      setState(() {
        msj = "$nombre";
      });

    });

    setState(() {
      listaClientes = lista;
      msj = conprestamo? "Con prestamo $totalclientes clientes ($grupoSeleccionado)":"Sin prestamo $totalclientes clientes ($grupoSeleccionado)";
    });

  }

}

class Mover extends StatefulWidget {
  String idcliente;
  String nombre;
  Mover(this.idcliente,this.nombre);
  @override
  _MoverState createState() => _MoverState();
}

class _MoverState extends State<Mover> {

  String idcliente = "";
  String nombre;
  List<Map> listaGrupos;
  List<Map> listaClientes;
  String grupoSeleccionado = "";
  Map clienteSeleccionado;
  bool aclientes = false;
  bool cargando = false;
  bool termino = false;

  @override
  void initState() {
    idcliente = widget.idcliente;
    nombre = widget.nombre;
    getListaGrupos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text("Mover $nombre al grupo"),
              Container(
                height: 50,
                width: double.infinity,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: listaGrupos==null?0:listaGrupos.length,
                    itemBuilder: (context, index) {
                      if(listaGrupos==null){
                        return CircularProgressIndicator();
                      }else{
                        Map item = listaGrupos[index];
                        return InkWell(
                          onTap: (){
                            grupoSeleccionado = item['grupo'];
                            getClientesGrupo(true);
                          },
                          child: Center(
                              child: Container(
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(40)),
                                      color: Colors.black12
                                  ),
                                  child: Text("${item['grupo']}",style: TextStyle(color: item['grupo']==grupoSeleccionado?Colors.blueAccent:Colors.black,fontWeight: FontWeight.bold),))),
                        );
                      }
                    }),
              ),
              SizedBox(
                height: 30,
              ),
              Visibility(
                visible: cargando,
                child: SizedBox(
                  child: CircularProgressIndicator(strokeWidth: 1,),
                ),
              ),
              Visibility(
                visible: aclientes,
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Text("Mover despues del cliente"),
                      Container(
                        height: screenHeight(context)/2,
                        width: double.infinity,
                        child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: listaClientes==null?0:listaClientes.length,
                            itemBuilder: (context, index) {
                              if(listaClientes==null){
                                return CircularProgressIndicator();
                              }else{
                                Map item = listaClientes[index];
                                return InkWell(
                                  onTap: (){
                                    clienteSeleccionado = item;
                                    setState(() {
                                      termino = true;
                                    });
                                  },
                                  child: Center(
                                      child: Container(
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.circular(40)),
                                              color: item==clienteSeleccionado?Colors.lightBlueAccent:Colors.black12
                                          ),
                                          child: Text("${item['nombre']}",style: TextStyle(color: Colors.black),)
                                      )
                                  ),
                                );
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40,),
              Visibility(
                visible: termino,
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      termino?Text("Mover $nombre al grupo $grupoSeleccionado despues de ${clienteSeleccionado['nombre']}",style: TextStyle(color: Colors.blue),):SizedBox(),
                      SizedBox(height: 10,),
                      OutlineButton(
                        onPressed: (){
                          moverCliente();
                        },
                        child: Text("Mover"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  getListaGrupos()async{

    listaGrupos = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();
    List<Map> lista = new List();
    int total = 0;
    int recorrido = 0;
    String grupova = "";
    if(clientes.length>0){

      //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
      // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
      await Future.forEach(clientes, (cliente){

        String key = cliente['key'].toString();
        String grupo = cliente['grupo'].toString();
        String nombre = cliente['nombre'].toString();
        String direccion = cliente['direccion'].toString();

        if(grupova!=grupo&&total>0){
          lista.add({"grupo":grupova});
          grupova = grupo;
          total = 1;
        }else{
          total++;
          grupova = grupo;
        }
        recorrido++;
        if(clientes.length==recorrido){
          lista.add({"grupo":grupova});
        }

      });

    }else{

    }

    setState(() {
      listaGrupos = lista;
    });
  }

  getClientesGrupo(bool conprestamo)async{

    //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
    // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
    setState(() {
      cargando = true;
      aclientes = false;
    });
    listaClientes = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes WHERE grupo=? ORDER BY posicion ASC",[grupoSeleccionado]);
    await database.close();

    String fechaactual = fechaActual();
    List<Map> lista = new List();
    await Future.forEach(clientes, (cliente) async {

      String id = cliente['id'].toString();
      String key = cliente['key'].toString();
      String nombre = cliente['nombre'];
      String direccion = cliente['direccion'];
      String posicion = cliente['posicion'].toString();

      Database database = await opendb();
      List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=? AND capital>'0' ",[key]);
      await database.close();

      int totalprestamos = prestamos.length;

      if(conprestamo) {
        if(totalprestamos>0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "posicion": posicion,
          });
        }
      }else{
        if(totalprestamos<=0){
          lista.add({
            "id":id,
            "nombre": nombre,
            "direccion": direccion,
            "posicion": posicion,
          });
        }
      }

    });

    setState(() {
      listaClientes = lista;
      cargando = false;
      aclientes = true;
    });

  }

  moverCliente()async{

    String id = clienteSeleccionado['id'];
    String posicion = clienteSeleccionado['posicion'].toString();
    String grupo = grupoSeleccionado;

    Database database = await opendb();
    int count = await database.rawUpdate('UPDATE clientes SET grupo = ?, posicion=? WHERE id = ?', [grupo,"$posicion.1",idcliente]);
    await database.close();

    //print("movido id$id grupo $grupo posicion $posicion.1");
    setState(() {
      aclientes=false;
      termino=false;
    });

    Flushbar(
      message: "Movido a $grupoSeleccionado despues de ${clienteSeleccionado['nombre']}",
      duration: Duration(seconds: 3),
      //showProgressIndicator: true,
      onStatusChanged: (state) {
        //print("click ${state.index} $state");
        if(state.index==1)Navigator.pop(context);
      },
    ).show(context);

  }

}

class RenombrarGrupos extends StatefulWidget {
  @override
  _RenombrarGruposState createState() => _RenombrarGruposState();
}

class _RenombrarGruposState extends State<RenombrarGrupos> {

  List<Map> listaGrupos;
  String grupoSeleccionado = "";
  String totalclientes = "0";
  String msj = "";
  final txtnuevogrupo = TextEditingController();

  @override
  void initState() {
    this.getListaGrupos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Renombrar grupos"),),
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            child: Column(
              children: [
                Container(
                  height: 70,
                  width: double.infinity,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: listaGrupos==null?0:listaGrupos.length,
                      itemBuilder: (context, index) {
                        if(listaGrupos==null){
                          return CircularProgressIndicator();
                        }else{
                          Map item = listaGrupos[index];
                          return InkWell(
                            onTap: (){
                              setState(() {
                                grupoSeleccionado = item['grupo'];
                                totalclientes = item['total'].toString();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(15),
                              margin: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(width: 1,color: item['grupo']==grupoSeleccionado?Colors.blueAccent:Colors.black),
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Text("${item['grupo']}",style: TextStyle(color: item['grupo']==grupoSeleccionado?Colors.blueAccent:Colors.black,fontWeight: FontWeight.bold),),
                            ),
                          );
                        }
                      }),
                ),
                Visibility(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cambiar nombre para el grupo $grupoSeleccionado $totalclientes clientes"),
                        TextField(
                          controller: txtnuevogrupo,
                          decoration: InputDecoration(
                            labelText: "Nuevo nombre para $grupoSeleccionado",
                          ),
                        ),
                        Text("$msj"),
                        RaisedButton(
                          onPressed: (){
                            this.cambiarNombreGrupo();
                          },
                          child: Text("Cambiar"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  getListaGrupos()async{

    listaGrupos = new List();
    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();
    List<Map> lista = new List();
    int total = 0;
    int recorrido = 0;
    String grupova = "";
    if(clientes.length>0){

      //id: 39, key: 4a5f3670-c972-11ea-94e5-11d56ded882c, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria,
      // telefono: 3124648717, posicion: 7, oculto: , grupo: Centro, cupo: no
      await Future.forEach(clientes, (cliente){

        String key = cliente['key'].toString();
        String grupo = cliente['grupo'].toString();
        String nombre = cliente['nombre'].toString();
        String direccion = cliente['direccion'].toString();

        if(grupova!=grupo&&total>0){
          lista.add({"grupo": grupova, "total": total});
          grupova = grupo;
          total = 1;
        }else{
          total++;
          grupova = grupo;
        }
        recorrido++;
        if(clientes.length==recorrido){
          lista.add({"grupo": grupova, "total": total});
        }

      });

    }else{

    }

    setState(() {
      listaGrupos = lista;
    });
  }

  cambiarNombreGrupo()async{

    String grupocambiar = grupoSeleccionado;
    String nuevogrupo = txtnuevogrupo.text;
    if(grupoSeleccionado.length==0){
      Flushbar(message: "Seleccione un grupo para cambiar",duration: Duration(seconds: 3),).show(context);
      return;
    }
    if(nuevogrupo.length<=0){
      Flushbar(message: "Escriba el nombre del nuevo grupo",duration: Duration(seconds: 3),backgroundColor: Colors.orange,).show(context);
      return;
    }

    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes WHERE grupo=?",[grupocambiar]);
    await database.close();

    //print("clientes grupo $grupocambiar Clientes: ${clientes.length}");

    await Future.forEach(clientes, (cliente) async {

      String id = cliente['id'].toString();
      String nombre = cliente['nombre'].toString();
      Database database = await opendb();
      int count = await database.rawUpdate('UPDATE clientes SET grupo=? WHERE id = ?', [nuevogrupo,id]);
      await database.close();

      setState(() {
        msj = "$nombre cambiado a $nuevogrupo";
      });

    });

    setState(() {
      txtnuevogrupo.text = "";
      grupoSeleccionado = "";
      msj = "Cambio exitoso";
    });

    this.getListaGrupos();

  }

}

//imprimir resumen dia
class ImprimirResumen extends StatefulWidget {

  Map resumen;
  ImprimirResumen(this.resumen);

  @override
  _ImprimirResumenState createState() => _ImprimirResumenState();
}

class _ImprimirResumenState extends State<ImprimirResumen> {

  Map resumendia;

  @override
  void initState() {
    resumendia = widget.resumen;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Imprimir resumen dia"),),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Imprimir el resumen del dia"),
            SizedBox(
              height: 20,
            ),
            OutlineButton(
              onPressed: ()async{
                Ticket ticket = await resumen();
                //imprimirRecibo(ticket,context);
              },
              onLongPress: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
              },
              child: Text("Imprimir resumen"),
            ),
          ],
        ),
      ),
    );
  }

  void conectarImpresora()async{
    Navigator.push(context, MaterialPageRoute(builder: (context)=>ConectarImpresora()));
  }

  Future<Ticket> resumen() async {

    String rutaActiva = await getLocal("ruta");
    String empresa = nombreempresa;
    String telefono = telefonoempresa;
    String moneda = simbolomoneda;
    String fecha = fechaActual();
    String hora = horaActual();
    String resumen = resumendia['movimientos'];
    String movimientos = "";

    //la informacion del mapa resumendia
    /*
    "cobrado": dejarDosDecimales(cobrado),
      "capital" : dejarDosDecimales(capital),
      "interes" : dejarDosDecimales(interes),
      "prestado" : prestado,
      "totalprestamos" : totalprestamos,
      "mora" : dejarDosDecimales(mora),
      "movimientoscaja" : movimientoscaja,
      "gastos" : gastos,
      "numerogastos" : numerogastos,
      "pagosrealizados" : pagosrealizados,
      "clientesnuevos" : clientesnuevos,
      "impresiones" : impresiones,
      "compartidos" : compartidos,
      "clienteseditados" : clienteseditados,
      "pagoscancelados" : pagoscancelados,
      "abonoborrado" : abonoborradoeldiapago,
      "abonoborrototal" : abonoborradototal,
      "abonoborrados" : abonoborrados,
      "movimientos": movimientos,
     */

    String enter = "\n";
    List movimient = resumen.split("*");
    movimient.removeAt(0); //elimina un asterisco que no tiene nada
    await Future.forEach(movimient, (movi) {
      //print("movi $movi");
      List movimien = movi.split(" ");
      String tipo = movimien[0];
      if(tipo=="abono"||tipo=="ALERTA"||tipo=="pagocancelado"){
        if(movi.length>63){
          String movim = movi.substring(0,63);
          movimientos = movimientos +enter+ "*" + movim;
        }else {
          movimientos = movimientos +enter+ "*" + movi;
        }
      }
    });

    CapabilityProfile profile = await CapabilityProfile.load();
    final Ticket ticket = Ticket(PaperSize.mm58, profile);

    Directory ruta = await getExternalStorageDirectory();
    String pathlogo = ruta.path+"/logo.png";
    File file = new File(pathlogo);
    bool existelogo = await file.exists();

    if(existelogo) {
      /*//final ByteData data = await rootBundle.load(pathlogo);
      final data = file.readAsBytesSync();
      //final Uint8List bytes = data.buffer.asUint8List();
      final image = Imag.decodeImage(data);
      ticket.image(image, align: PosAlign.center);*/
    }else {
      ticket.text('$empresa', styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ));
    }

    //ticket.text('$telefono', styles: PosStyles(align: PosAlign.center));
    ticket.feed(1);

    ticket.text('RESUMEN DIA $fecha $hora',styles: PosStyles(codeTable: 'CP1252'));
    ticket.text('$rutaActiva');
    ticket.feed(2);

    ticket.row([
      PosColumn(
        text: 'Cobrado',
        width: 3,
        styles: PosStyles(align: PosAlign.left, underline: true),
      ),
      PosColumn(
        text: '',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: '$moneda ${resumendia['cobrado']}',
        width: 3,
        styles: PosStyles(align: PosAlign.right, underline: true),
      ),
    ]);
    ticket.row([
      PosColumn(
        text: 'Prestado',
        width: 3,
        styles: PosStyles(align: PosAlign.left, underline: true),
      ),
      PosColumn(
        text: '',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: '$moneda ${resumendia['prestado']}',
        width: 3,
        styles: PosStyles(align: PosAlign.right, underline: true),
      ),
    ]);
    ticket.row([
      PosColumn(
        text: 'Gastos',
        width: 3,
        styles: PosStyles(align: PosAlign.left, underline: true),
      ),
      PosColumn(
        text: '',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: '$moneda ${resumendia['gastos']}',
        width: 3,
        styles: PosStyles(align: PosAlign.right, underline: true),
      ),
    ]);
    ticket.row([
      PosColumn(
        text: 'Mora',
        width: 3,
        styles: PosStyles(align: PosAlign.left, underline: true),
      ),
      PosColumn(
        text: '',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: '$moneda ${resumendia['mora']}',
        width: 3,
        styles: PosStyles(align: PosAlign.right, underline: true),
      ),
    ]);

    ticket.feed(1);

    ticket.text('Movimientos', styles: PosStyles(align: PosAlign.center,codeTable: 'CP1252'));
    ticket.text('$movimientos', styles: PosStyles(align: PosAlign.left));

    ticket.feed(1);

    ticket.text('CONSERVAR ESTE RESUMEN', styles: PosStyles(align: PosAlign.center));
    ticket.text('$fecha $hora', styles: PosStyles(align: PosAlign.center,bold: true));

    ticket.feed(3);

    /*ticket.text('Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    ticket.text('Special 1: Bogotá ññ', styles: PosStyles(codeTable: PosCodeTable.westEur));
    ticket.text('Special 2: blåbærgrød', styles: PosStyles(codeTable: PosCodeTable.westEur));

    ticket.text('Bold text', styles: PosStyles(bold: true));
    ticket.text('Reverse text', styles: PosStyles(reverse: true));
    ticket.text('Underlined text', styles: PosStyles(underline: true), linesAfter: 1);
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

    // Print image
    final ByteData data = await rootBundle.load('assets/logop.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final image = Imag.decodeImage(bytes);
    ticket.image(image);
    // Print image using alternative commands
    // ticket.imageRaster(image);
    // ticket.imageRaster(image, imageFn: PosImageFn.graphics);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    ticket.barcode(Barcode.upcA(barData)); */

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    // ticket.text(
    //   'hello ! 中文字 # world @ éphémère &',
    //   styles: PosStyles(codeTable: PosCodeTable.westEur),
    //   containsChinese: true,
    // );

    //ticket.feed(2);

    //ticket.cut();
    return ticket;
  }
}








