import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prestagroons/main.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'meTodo.dart';
import 'package:http/http.dart' as http;

class MenuTienda extends StatefulWidget {
  @override
  _MenuTiendaState createState() => _MenuTiendaState();
}

class _MenuTiendaState extends State<MenuTienda> with SingleTickerProviderStateMixin{

  TabController _tabController;
  List<Map> listaTienda = new List();
  Map datosLicencia = {"dias":"0","licencia":"Gratis","usd":"0"};
  int rutashay = 0;
  String msj = "";

  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      //print("click ${_tabController.index}");
    });
    this.getDatosLicencia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Tienda"),
        bottom: TabBar(
          unselectedLabelColor: Colors.white,
          labelColor: Colors.amber,
          tabs: [
            new Tab(icon: new Icon(Icons.shopping_cart)),
            new Tab(icon: new Icon(Icons.payment),),
          ],
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,),
        bottomOpacity: 1,
      ),
      body: TabBarView(
        children: [
          new Container(
            color: Colores.primario,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(msj,style: TextStyle(color: Colors.white),),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Mi saldo", style: TextStyle(color: Colors.amber, fontSize: 15),),
                              Text("${datosLicencia['usd']} USD", style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Plan actual", style: TextStyle(color: Colors.amber, fontSize: 15),),
                              Text("${datosLicencia['licencia']}", style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Dias restantes", style: TextStyle(color: Colors.amber, fontSize: 15),),
                              Text("${datosLicencia['dias']}", style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                       scrollDirection: Axis.vertical,
                       shrinkWrap: true,
                       physics: NeverScrollableScrollPhysics(),
                       itemCount: listaTienda == null ? 0 : listaTienda.length,
                       itemBuilder: (context,index){
                         if (listaTienda == null) {
                           return CircularProgressIndicator();
                         } else {
                           final item = listaTienda[index];
                           String id = item['id'];
                           String oferta = item['oferta'];
                           String valorruta = item['valorruta'];
                           String totalnormal = item['totalnormal'];
                           String total = item['total'];
                           String dias = item['dias'];
                           String msj = item['msj'];
                           String caracteristicas = item['caracteristicas'];
                           String licencia = item['licencia'].toString();
                           String sisupera = item['sisupera'].toString();
                           String descuento = item['descuento'].toString();
                           String descuentoporcentaje = item['descuentoporcentaje'].toString();
                           return Padding(
                             padding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 50),
                             child: Material(
                               elevation: 20,
                               color: Colors.transparent,
                               child: Container(
                                 width: double.infinity,
                                 padding: EdgeInsets.all(20),
                                 decoration: BoxDecoration(
                                     borderRadius: BorderRadius.all(Radius.circular(5)),
                                     gradient: LinearGradient(
                                       colors: oferta=="si"?[
                                         Color(0xff85182a),
                                         Color(0xffe01e37),
                                       ]:[
                                         Colores.tercero,
                                         Colores.primario,
                                       ],
                                       begin: Alignment.bottomCenter,
                                       end: Alignment.topCenter,
                                     )
                                 ),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     SizedBox(height: 20,),
                                     oferta=="si"?Shimmer.fromColors(
                                       child: Text("Oferta", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),), baseColor: Color(0xff8338ec),
                                       highlightColor: Color(0xffffffff),
                                     ):SizedBox(),
                                     oferta=="si"?Shimmer.fromColors(child: Text("PLAN $licencia", style: TextStyle(
                                         color: Colors.white,
                                         fontSize: 20,
                                         fontWeight: FontWeight.bold),), baseColor: Colores.primario, highlightColor: Colors.amber):SizedBox(),
                                     oferta=="no"?Shimmer.fromColors(child: Text("PLAN $licencia", style: TextStyle(
                                         color: Colors.white,
                                         fontSize: 20,
                                         fontWeight: FontWeight.bold),), baseColor: Colors.amber, highlightColor: Colors.white):SizedBox(),
                                     Text("Compra de $dias dias ($rutashay rutas)", style: TextStyle(color: Colors.white),),
                                     Text("$valorruta usd por ruta", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),),
                                     oferta=="si"?Text("Si supera $sisupera rutas descuento del $descuentoporcentaje % ", style: TextStyle(color: Colors.white),):SizedBox(),
                                     SizedBox(height: 20,),
                                     Text("$msj", style: TextStyle(color: Colors.white),),
                                     SizedBox(height: 40,),
                                     oferta=="si"?Container(
                                       padding: EdgeInsets.all(10),
                                       decoration: BoxDecoration(
                                         borderRadius: BorderRadius.all(Radius.circular(5)),
                                         border: Border.all(color: Colors.black12,width: 3),
                                       ),
                                       child: Text("Antes $totalnormal USD ahora $total USD", style: TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),),
                                     ):SizedBox(),
                                     SizedBox(height: 10,),
                                     Shimmer.fromColors(
                                       child: InkWell(
                                         onTap: () {
                                           this.setComprar(id,item);
                                         },
                                         child: Container(
                                           decoration: BoxDecoration(
                                             borderRadius: BorderRadius.all(Radius.circular(5)),
                                             border: Border.all(color: Colors.amber, width: 3),
                                           ),
                                           child: Padding(
                                             padding: const EdgeInsets.all(8.0),
                                             child: Text("COMPRAR $total USD x $dias DIAS",
                                               style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                                           ),
                                         ),
                                       ),
                                       baseColor: Colors.amber,
                                       highlightColor: Colors.white,
                                     ),
                                     SizedBox(height: 20,),
                                     Text("$caracteristicas", style: TextStyle(color: Colors.white,fontSize: 10),),
                                   ],
                                 ),
                               ),
                             ),
                           );
                         }
                       })
                  ],
                ),
              ),
            ),
          ),
          new Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Text("Proximamente nuevo sistema de pagos por Google play"),
                  SizedBox(
                    height: 30,
                  ),
                  RaisedButton(
                    onPressed: (){
                      _launchURL();
                    },
                    child: Text("Agregar por Paypal"),
                  )
                ],
              ),
            ),
          ),
        ],
        controller: _tabController,
      ),
    );
  }

  void getDatosLicencia()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");

    String url = baseurl + 'verlicencia.php';

    setState(() {
      msj = "Buscando licencia";
    });

    var data = { "iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    //print("respuesta server: ${response.body} idruta $idruta");
    List result = jsonDecode(response.body);
    Map item = result[0];
    print("respuesta server: ${item}");

    licenciaGlobal = item['licencia'];
    String dias = item['diaspagos'].toString();
    String fecha = item['fechapago'];
    String usd = item['usd'].toString();
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

    datosLicencia = {"dias": "$diasrestantes","licencia": plan,"usd": usd};

    this.getDatosTienda();

  }

  void getDatosTienda()async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String urlruta = baseurl + 'leerrutas.php';

    setState(() {
      msj = "Leyendo cantidad de rutas";
    });

    var data = {"iduser": iduser, "token": token};
    var responserutas = await http.post(urlruta, body: json.encode(data));

    List rutas = jsonDecode(responserutas.body);

    //print("rutas: ${rutas.length}");
    rutashay = rutas.length;

    setState(() {
      msj = "Buscando planes";
    });

    String url = baseurl + 'planes.php';
    //var data = { "iduser": iduser, "token": token};
    var response = await http.post(url, body: json.encode(data));

    print("respuesta server: ${response.body}");
    List result = jsonDecode(response.body);
    Map item = result[0];
    //print("respuesta server: ${item}");

    await Future.forEach(result, (item) {

      //print("item: $item");
      String id = item['id'].toString();
      String licencia = item['licencia'];
      int dias = int.parse(item['dias']);
      double valorruta = double.parse(item['valorruta']);
      String promosion = item['promosion'];
      double descuentoporcentaje = double.parse(item['descuento']);
      int sisupera = int.parse(item['sisupera']);
      String mensaje = item['msj'];
      String caracteristicas = item['caracteristicas'];
      String disponible = item['disponible'];

      double valor = rutashay*valorruta;
      double descuento = 0;
      double total = valor;
      if(dias>30){
        double meses = dias/30;
        total = meses*valor;
        valor = total;
      }
      if(sisupera<=rutashay){
        descuento = valor*descuentoporcentaje/100;
        total = valor-descuento;
        //print("descuento $descuento total $total");
      }

      if(licencia=="2"){
        licencia = "PLATA";
      }else if(licencia=="3"){
        licencia = "BRONCE";
      }else if(licencia=="4"){
        licencia = "ORO";
      }

      if(disponible=="si") {
        listaTienda.add({
          "id": id,
          "valorruta": valorruta.toString(),
          "totalnormal": dejarDosDecimales(valor),
          "total": dejarDosDecimales(total),
          "oferta": promosion,
          "sisupera": sisupera.toString(),
          "descuento": "$descuento USD",
          "descuentoporcentaje": "$descuentoporcentaje",
          "dias": "$dias",
          "licencia": licencia,
          "msj": mensaje,
          "caracteristicas": caracteristicas,
        });
      }

    });

    setState(() {
      msj = "Rutas registradas $rutashay";
    });

  }

  void setComprar(String id,Map item)async{

    String token = await getLocal("token");
    String iduser = await getLocal("iduser");
    String idplan = id;
    String url = baseurl + 'comprar.php';

    Navigator.push(context, MaterialPageRoute(builder: (context)=>pantallaGracias(false,"Su compra esta en proceso, validando...")));

    var data = {"iduser": iduser, "token": token, "idplan": idplan};
    var response = await http.post(url, body: json.encode(data));

    print("llego: ${response.body}");
    List lista = jsonDecode(response.body);
    Map item = lista[0];
    String code = item['code'];
    String msj = item['msj'];

    if(code=="10"){
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context)=>pantallaGracias(true,msj)));
    }

  }

  Widget pantallaGracias(bool exitoso,String msj){

    return Scaffold(
      body: Container(
        color: Colores.primario,
        child: Center(
          child: Container(
            color: Colores.primario,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Text(exitoso?"EXITOSO":"GRACIAS",style: TextStyle(fontSize: 50,color: Colores.secundario),)),
                Text(msj,style: TextStyle(fontSize: 12,color: Colores.secundario),),
                exitoso?SizedBox():SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 1,),
                ),
                exitoso?FlatButton(
                  onPressed: (){
                    Navigator.pop(context);
                    this.getDatosLicencia();
                  },
                  child: Text("Volver a la tienda",style: TextStyle(color: Colors.white),),
                ):SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _launchURL() async {
    const url = 'https://www.paypal.me/prestacop';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}
