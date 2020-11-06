import 'dart:io';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prestagroons/Ajustes.dart';
import 'package:prestagroons/Clientes.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';
import 'meTodo.dart';

class ResumenDia extends StatefulWidget {
  @override
  _ResumnenDiaState createState() => _ResumnenDiaState();
}

class _ResumnenDiaState extends State<ResumenDia> {

  final key = UniqueKey();
  Color colorLetras = Colors.black;
  Map resumen = new Map();
  String msjliquido = "";
  bool mostrarliquidaciones = false;
  String caja = "0";

  List<FlSpot> listapagosuno = [FlSpot(1, 0),];
  List<FlSpot> listapagosdos = [FlSpot(1, 0),];
  double promediodinero = 0;

  actualizarResumen()async{
    Map resu = await leerResumen();
    await cargarPagos();
    await estadoLiquidaciones();
    Map mapacaja = await getCaja();
    caja = mapacaja['caja'];
    setState(() {
      resumen = resu;
    });
  }

  @override
  void initState() {
    resumen = getResumenVacio();
    this.actualizarResumen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colores.grisclaro,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: FocusDetector(
            key: key,
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 40,left: 40,right: 40),
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Text("Resumen del dia",style: TextStyle(fontWeight: FontWeight.bold,color: Colores.azul),),
                      SizedBox(height: 30,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Cobrado",style: TextStyle(color: colorLetras,fontSize: 25),),
                          ),
                          Container(
                            child: Text("${resumen['cobrado']}",style: TextStyle(color: colorLetras,fontSize: 25,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Prestado",style: TextStyle(color: colorLetras,fontSize: 25),),
                          ),
                          Container(
                            child: Text("${resumen['prestado']}",style: TextStyle(color: colorLetras,fontSize: 25,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Gastos",style: TextStyle(color: colorLetras,fontSize: 25),),
                          ),
                          Container(
                            child: Text("${resumen['gastos']}",style: TextStyle(color: colorLetras,fontSize: 25,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: mostrarliquidaciones,
                  child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      color: Colors.red,
                      child: Text("$msjliquido",style: TextStyle(color: Colors.white),)
                  ),
                ),
                Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 20,),
                  child: Column(
                    children: <Widget>[
                      graficaPagos(),
                    ],
                  ),
                ),
                SizedBox(height: 10,),
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
                          Container(
                            child: Text("Caja",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            child: Text("${caja }",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Capital",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            child: Text("${resumen['capital']}",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Interes",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            child: Text("${resumen['interes']}",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Pagos realizados",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            child: Text("${resumen['pagosrealizados']}",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Mora",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                          Container(
                            child: Text("${resumen['mora']}",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Movimientos en caja",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['movimientoscaja']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Numero de gastos",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['numerogastos']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Prestamos realizados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['totalprestamos']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Clientes nuevos ingresados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['clientesnuevos']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Recibos imprimidos",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['impresiones']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Recibos compartidos",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['compartidos']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Clientes editados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['clienteseditados']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Pagos cancelados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['pagoscancelados']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Abonos borrado dia pago",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['abonoborrado']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Abonos borrados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['abonoborrados']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            child: Text("Total abonos borrados",style: TextStyle(color: colorLetras),),
                          ),
                          Container(
                            child: Text("${resumen['abonoborrototal']}",style: TextStyle(color: colorLetras),),
                          ),
                        ],
                      ),
                      Divider(height: 1,),
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
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>prestamosHoy()));
                        },
                        leading: Icon(Icons.perm_identity),
                        title: Text("Ver prestamos de hoy"),
                        trailing: Icon(Icons.arrow_right),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>gastos()));
                          }else{
                            Flushbar(title: "ADQUIERE UN PLAN",message: "No disponible sin plan",backgroundColor: Colors.deepPurpleAccent,duration: Duration(seconds: 5),).show(context);
                          }
                        },
                        leading: Icon(Icons.shopping_cart),
                        title: Text("Ver gastos de hoy"),
                        trailing: Icon(Icons.arrow_right),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  width: double.infinity,
                  color: Colores.azul,
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Movimientos",style: TextStyle(color: Colors.white),),
                      Text("${resumen['movimientos']}",style: TextStyle(color: Colors.white,fontSize: 9),),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          /*IconButton(
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>ImprimirResumen(resumen)));
                            },
                            icon: Icon(Icons.print,color: Colors.white,),
                          ),*/
                          OutlineButton.icon(
                            onPressed: (){
                              mensajeLiquidar();
                            },
                            onLongPress: ()async{
                              await borrarTabla("resumendia");
                            },
                            icon: Icon(Icons.done, color: Colors.white),
                            label: Text("Liquidar",style: TextStyle(color: Colors.white),),
                          ),
                          IconButton(
                            onPressed: (){
                              compartir();
                            },
                            icon: Icon(Icons.share,color: Colors.white,),
                          ),
                          OutlineButton.icon(
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>SubirCopia()));
                            },
                            icon: Icon(Icons.cloud_upload,color: Colors.white,),
                            label: Text("Subir copia",style: TextStyle(color: Colors.white),),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onFocusGained: ()async{
              await actualizarResumen();
            },
          ),
        ),
      ),
    );
  }

  Future<Map> leerResumen()async{
    Database database = await opendb();
    List<Map> resumendia = await database.rawQuery("SELECT * FROM resumendia");
    await database.close();
    Map resumen = new Map();
    double cobrado = 0;
    double capital = 0;
    double interes = 0;
    double prestado = 0;
    int totalprestamos = 0;
    double gastos = 0;
    int numerogastos = 0;
    double mora = 0;
    int movimientoscaja = 0;
    int pagosrealizados = 0;
    int clientesnuevos = 0;
    int impresiones = 0;
    int compartidos = 0;
    int clienteseditados = 0;
    int pagoscancelados = 0;
    double abonoborradoeldiapago = 0;
    double abonoborradototal = 0;
    int abonoborrados = 0;
    String movimientos = "";

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

        if(tipo=="abono"){
          cobrado = cobrado+valor;
          Map result = verCapitalInteres(valor, porcentaje);
          double capit = double.parse(result['capital']);
          double inter = double.parse(result['interes']);
          capital = capital+capit;
          interes = interes+inter;
          pagosrealizados++;
        }else if(tipo=="capital"){
          cobrado = cobrado+capitalL;
          capital = capital+capitalL;
          pagosrealizados++;
        }else if(tipo=="interes"){
          cobrado = cobrado+interesL;
          interes = interes+interesL;
          pagosrealizados++;
        }else if(tipo=="gasto"){
          gastos = gastos+valor;
          numerogastos++;
        }else if(tipo=="eliminogasto"){
          gastos = gastos-valor;
          numerogastos--;
        }else if(tipo=="mora"){
          mora = mora+valor;
          cobrado = cobrado + mora;
          interes = interes + mora;
        }else if(tipo=="impresion"){
          impresiones++;
        }else if(tipo=="compartido"){
          compartidos++;
        }else if(tipo=="nuevocliente"){
          clientesnuevos++;
        } else if(tipo=="clienteeditado"){
          clienteseditados++;
        }else if(tipo=="caja"){
          movimientoscaja++;
        }else if(tipo=="pagoborrado"){
          //print("movimiento $movimiento");
          List datapago = movimiento.split(" ");
          String fechapagoborrado = datapago[1];
          double abonoborro =  double.parse(datapago[3].toString());
          //print("fechapagoborrado $fechapagoborrado abonoborrado $abonoborro fechamovimiento $fecha");
          if(fechapagoborrado==fecha){
            abonoborradoeldiapago = abonoborradoeldiapago+abonoborro;
            cobrado = cobrado-abonoborro;
            pagosrealizados--;
          }
          abonoborradototal = abonoborradototal+abonoborro;
          abonoborrados++;
        }else if(tipo=="pagocancelado"){
          cobrado = cobrado-valor;
          pagosrealizados--;
          pagoscancelados++;
          Map ganancia = verCapitalInteres(valor,porcentaje);
          double capit = double.parse(ganancia['capital']);
          double inter = double.parse(ganancia['interes']);
          capital = capital-capit;
          interes = interes-inter;
        }else if(tipo=="prestamo"){
          double capi = capitalL;
          prestado = prestado+capi;
          totalprestamos++;
        }

        String enter = "\n";
        String movi = "*$tipo $fecha $hora $movimiento $valor $porcentaje";
        movimientos = movimientos+enter + movi;

      });

    }else{
      print("No hay resumendia");
      resumen = getResumenVacio();
    }

    resumen = {
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
    };

    return resumen;
  }

  estadoLiquidaciones()async{
    Map liquido = await getLiQuidacionesDiaAnterior();
    int liquidoveces = liquido['liquidaciones'];
    String fechaliquido = liquido['fecha'];
    if(liquidoveces>1){
      mostrarliquidaciones = true;
      msjliquido = "El dia anterior $fechaliquido liquido $liquidoveces veces";
    }
  }

  getResumenVacio(){
    Map resume = new Map();
    resume = {
      "cobrado": "0.0",
      "capital" : "0.0",
      "interes" : "0.0",
      "prestado" : "0",
      "totalprestamos" : "0.0",
      "mora" : 0,
      "movimientoscaja" : "0",
      "gastos" : "0",
      "numerogastos" : "0",
      "pagosrealizados" : "0",
      "clientesnuevos" : "0",
      "impresiones" : "0",
      "compartidos" : "0",
      "clienteseditados" : "0",
      "pagoscancelados" : "0",
      "movimientos" : "",
    };
    return resume;
  }

  Widget graficaPagos(){
    return AspectRatio(
      aspectRatio: 1.23,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: Colors.transparent,
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  height: 37,
                ),
                Text("Pagos ultimos 14 dias (roja nuevos)", style: TextStyle(color: Color(0xff0466c8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center,),
                const SizedBox(
                  height: 37,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 1),
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
            return 'dia ${value.toInt()}';
          },
        ),
        leftTitles: SideTitles(showTitles: true,
          textStyle: const TextStyle(color: Color(0xff75729e), fontWeight: FontWeight.bold, fontSize: 7,),
          getTitles: (value) {
          //return getTrasformarNumeroGrafica(value);
            /*switch (value.toInt()) {
              case 10:
                return '10';
              case 50:
                return '50';
              case 100:
                return '100';
              case 500:
                return '500';
              case 1000:
                return '1000';
              case 10000:
                return '10 mil';
            }
            return '';*/
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
      spots: listapagosuno,
      isCurved: true,
      colors: [
        const Color(0xffe71d36),
      ],
      barWidth: 3, //grosor de la linea
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: listapagosdos,
      isCurved: true,
      colors: [
        const Color(0xff0466c8),
      ],
      barWidth: 3, //grosor de la linea
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    return [
      lineChartBarData1,
      lineChartBarData2,
    ];
  }

  void cargarPagos()async{

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances ORDER BY id DESC');
    await database.close();

    int balances = list.length;

    if(balances<2){
      return;
    }else if(balances>14){
      balances = 14;
    }

    listapagosuno = new List();
    listapagosdos = new List();
    promediodinero = 0;
    int recorrido = 14;
    int partir = (balances/2).toInt();
    if(balances<14){
      recorrido = balances;
    }

    await Future.forEach(list, (balance){

      if(recorrido>0) {
        double pagos = double.parse(balance['pagos'].toString());
        if(recorrido>partir) {
          double position = (recorrido-partir).toDouble();
          listapagosuno.add(new FlSpot(position, pagos));
          if (promediodinero < pagos) promediodinero = pagos;
          recorrido--;
        }else{
          listapagosdos.add(new FlSpot(recorrido.toDouble(), pagos));
          if (promediodinero < pagos) promediodinero = pagos;
          recorrido--;
        }
      }

    });

    /*print("listauno ${listapagosuno.length}");
    print("listados ${listapagosdos.length}");
    print("partir $partir");*/

    setState(() {

    });

  }

  mensajeLiquidar()async{
    var baseDialog = BaseAlertDialog(
      title: Text("Liquidar?",style: TextStyle(color: Colors.white),),
      content: Text("Si liquida se limpiara el resumen del dia y se guardaran balances, todo el resumen se podra ver en balances-liquidaciones o movimientos.",style: TextStyle(color: Colors.white),),
      yes: Text("Liquidar",style: TextStyle(color: Colors.green),),
      no: Text("Cancelar"),
      fondoColor: Color.fromRGBO(65,66,136, 0.8),
      yesOnPressed: ()async {
        Navigator.pop(context);
        this.liquidar();
      },
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);
  }

  void liquidar()async{
    //agregar * a la caja y resumen en balances se divide por el *
    //opciones del map resumen
    //cobrado: 8000.00, capital: 6666.67, interes: 1333.33, prestado: 150000.0, totalprestamos: 2, mora: 0.00, movimientoscaja: 1,
    // gastos: 0.0, numerogastos: 0, pagosrealizados: 1, clientesnuevos: 0, impresiones: 0, compartidos: 1, clienteseditados: 3, pagoscancelados: 1, movimientos:

    String fecha = fechaActual();
    String hora = horaActual();
    List valor = fecha.split("/");
    int dia = int.parse(valor[0].toString());
    int mes = int.parse(valor[1].toString());
    int anio = int.parse(valor[2].toString());
    String cobrado = resumen['cobrado'].toString();
    String capital = resumen['capital'].toString();
    String interes = resumen['interes'].toString();
    String mora = resumen['mora'].toString();
    double ganancia = double.parse(interes)+double.parse(mora);
    double dinerocalle = await getTotalCalle();
    String clientesnuevos = resumen['clientesnuevos'].toString();
    String numeroprestamos = resumen['totalprestamos'].toString();
    String valorprestado = resumen['prestado'].toString();
    String pagos = resumen['pagosrealizados'].toString();
    String impresiones = resumen['impresiones'].toString();
    String compartidos = resumen['compartidos'].toString();
    String editados = resumen['clienteseditados'].toString();
    String gastos = resumen['gastos'].toString();
    String movimientoscaja = "";
    String movimientosdia = resumen['movimientos'].toString()+"=>Liquido $fecha $hora";
    String liquidaciones = "Liquido $fecha $hora";

    Map mapcaja = await getCaja();
    double cajatotal = double.parse(mapcaja['caja'].toString());
    double valorsumar = double.parse(mora)+double.parse(cobrado);
    double valorrestar = double.parse(gastos)+double.parse(valorprestado);
    double cajafinal = cajatotal+valorsumar-valorrestar;
    movimientoscaja = mapcaja['movimientos'].toString();

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE dia=? AND mes=? AND anio=?', [dia, mes, anio]);

    if (list.length > 0) {
      Map val = list[0];
      String id = val['id'].toString();
      double haycobrado = double.parse(val['cobrado'].toString());
      double haycapital = double.parse(val['capital'].toString());
      double hayinteres = double.parse(val['interes'].toString());
      double haymora = double.parse(val['mora'].toString());
      double hayganancia = double.parse(val['ganancia'].toString());
      int hayclientesnuevos = int.parse(val['clientesnuevos'].toString());
      int haynumeroprestamos = int.parse(val['numeroprestamos'].toString());
      double hayvalorprestado = double.parse(val['valorprestado'].toString());
      int haypagos = int.parse(val['pagos'].toString());
      int hayimpresiones = int.parse(val['impresiones'].toString());
      int haycompartidos = int.parse(val['compartidos'].toString());
      int hayeditados = int.parse(val['editados'].toString());
      double haygastos = double.parse(val['gastos'].toString());
      String haymovimientoscaja = val['movimientoscaja'].toString();
      String haymovimientosdia = val['movimientosdia'].toString();
      String hayliquidaciones = val['liquidaciones'].toString();

      double finalcobrado = haycobrado+double.parse(cobrado);
      double finalcapital = haycapital+double.parse(capital);
      double finalinteres = hayinteres+double.parse(interes);
      double finalmora = haymora+double.parse(mora);
      double finalganancia = hayganancia+ganancia;
      double finaldinerocalle = dinerocalle;
      int finalclientesnuevos = hayclientesnuevos+int.parse(clientesnuevos);
      int finalnumeroprestamos = haynumeroprestamos+int.parse(numeroprestamos);
      double finalvalorprestado = hayvalorprestado+double.parse(valorprestado);
      int finalpagos = haypagos+int.parse(pagos);
      int finalimpresiones = hayimpresiones+int.parse(impresiones);
      int finalcompartidos = haycompartidos+int.parse(compartidos);
      int finaleditados = hayeditados+int.parse(editados);
      double finalgastos = haygastos+double.parse(gastos);
      String finalmovimientoscaja = haymovimientoscaja+movimientoscaja;
      String finalmovimientosdia = haymovimientosdia+movimientosdia;
      String finalliquidaciones = hayliquidaciones+"*"+liquidaciones+"\n";

      int count = await database.rawUpdate('UPDATE balances SET cobrado=?,capital=?,interes=?,ganancia=?,dinerocalle=?,clientesnuevos=?,numeroprestamos=?,valorprestado=?,pagos=?,mora=?,impresiones=?,compartidos=?,editados=?,gastos=?,caja=?,movimientoscaja=?,movimientosdia=?,liquidaciones=? WHERE id = ?',
          [finalcobrado,finalcapital,finalinteres,finalganancia,finaldinerocalle,finalclientesnuevos,finalnumeroprestamos,finalvalorprestado,finalpagos,finalmora,finalimpresiones,finalcompartidos,finaleditados,finalgastos,cajafinal,finalmovimientoscaja,finalmovimientosdia,finalliquidaciones,id]);
      print("=> sumado balance $dia/$mes/$anio cob:$cobrado pag:$pagos a (cob$finalcobrado pags:$finalpagos)");
    } else {
      await database.transaction((txn) async {
        int id = await txn.rawInsert(
            'INSERT INTO balances(dia, mes, anio, cobrado,capital,interes,ganancia,dinerocalle,clientesnuevos,numeroprestamos,valorprestado,pagos,mora,impresiones,compartidos,editados,gastos,caja,movimientoscaja,movimientosdia,liquidaciones) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
            [dia, mes, anio, cobrado, capital, interes, ganancia, dinerocalle, clientesnuevos, numeroprestamos, valorprestado, pagos, mora, impresiones, compartidos, editados, gastos, cajafinal, movimientoscaja, movimientosdia,liquidaciones]);
        print("add balance cobrado:$cobrado ganancia:$ganancia");
      });
    }

    await database.close();

    await borrarTabla("resumendia");
    await setCajaLimpiarMovimientos(cajafinal);
    await setCaja("$cajafinal", "(Quedo=$cajafinal) Liquido $fecha $hora sumo (cobrado: $cobrado mora: $mora) resto: (gastos: $gastos prestado: $valorprestado)");
    Flushbar(message: "Liquidacion exitosa",duration: Duration(seconds: 3),backgroundColor: Colors.green,).show(context);
    await actualizarResumen();
  }

  compartir()async{

    //print("compartiendo recibos");
    File imghtml = await generarpdf();

    List<int> bytes = await imghtml.readAsBytes();
    await Share.file('Recibo pdf', 'ResumenDia.pdf', bytes, 'application/pdf');
    await imghtml.delete();
    await agregarResumenDia("impresion", "Compartio resumen dia",  "0", "0", "0","0", "0");
    //Flushbar(message: "Proximamente",duration: Duration(seconds: 5),).show(context);
  }

  Future<File> generarpdf()async{

    String empresa = await getLocal("nombreempresa");
    // <p style="font-weight: bold; font-size: 40px; color: #4A6C6F;">$empresa</p>
    String telefono = await getLocal("telefonoempresa");
    String ruta = await getLocal("ruta");
    String cobrado = resumen['cobrado'].toString();
    String capital = resumen['capital'].toString();
    String interes = resumen['interes'].toString();
    String prestado = resumen['prestado'].toString();
    String totalprestamos = resumen['totalprestamos'].toString();
    String mora = resumen['mora'].toString();
    String movimientoscaja = resumen['movimientoscaja'].toString();
    String gastos = resumen['gastos'].toString();
    String numerogastos = resumen['numerogastos'].toString();
    String pagosrealizados = resumen['pagosrealizados'].toString();
    String clientesnuevos = resumen['clientesnuevos'].toString();
    String impresiones = resumen['impresiones'].toString();
    String compartidos = resumen['compartidos'].toString();
    String clienteseditados = resumen['clienteseditados'].toString();
    String pagoscancelados = resumen['pagoscancelados'].toString();
    String movimientos = resumen['movimientos'];


    Directory direct = await getExternalStorageDirectory();
    String pathlogo = direct.path+"/logo.png";
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
        <title>Resumen</title>
    </head>
    
    <body>
    
        <div style="text-align: center; padding: 20px;">
            <img src="file://$pathlogo" alt="web-img">
            <p style="color: #2b74af;">$telefono</p>
        </div>
        <div style="padding: 20px;">
            <h3 style="color: #2baf6d;">Ruta $ruta</h3>
            <h5 style="color: #2baf6d;">Generado: ${fechaActual()} ${horaActual()}</h5>
        </div>
    
        <div style="padding: 20px;">
            <table id="customers" style="border-radius: 5px; border-collapse: collapse; overflow: hidden;">
                <tr>
                    <th>Tipo</th>
                    <th>Valor</th>
                </tr>
                <tr>
                    <td>Cobrado</td>
                    <td>${cobrado}</td>
                </tr>
                <tr>
                    <td>Prestado</td>
                    <td>${prestado}</td>
                </tr>
                <tr>
                    <td>Gastos</td>
                    <td>${gastos}</td>
                </tr>
                <tr>
                    <td>Capital cobrado</td>
                    <td>${capital}</td>
                </tr>
                <tr>
                    <td>Interes</td>
                    <td>${interes}</td>
                </tr>
                <tr>
                    <td>Pagos realizados</td>
                    <td>${pagosrealizados}</td>
                </tr>
                <tr>
                    <td>Mora</td>
                    <td>${mora}</td>
                </tr>
                <tr>
                    <td>Movimientos en caja</td>
                    <td>${movimientoscaja}</td>
                </tr>
                <tr>
                    <td>Numero de gastos</td>
                    <td>${numerogastos}</td>
                </tr>
                <tr>
                    <td>Prestamos realizados</td>
                    <td>${totalprestamos}</td>
                </tr>
                <tr>
                    <td>Clientes nuevos ingresados</td>
                    <td>${clientesnuevos}</td>
                </tr>
                <tr>
                    <td>Recibos imprimidos</td>
                    <td>${impresiones}</td>
                </tr>
                <tr>
                    <td>Recibos compartidos</td>
                    <td>${compartidos}</td>
                </tr>
                <tr>
                    <td>Clientes editados</td>
                    <td>${clienteseditados}</td>
                </tr>
                <tr>
                    <td>Pagos cancelados</td>
                    <td>${pagoscancelados}</td>
                </tr>
            </table>
        </div>
        <div style="padding: 10px; margin: 20px; border: 1px solid #c7c8c9; border-radius: 5px;">
            <h5 style="color: #2b74af;">Movimientos</h5>
            <p style="font-size: 12px;">${movimientos}</p>
        </div>
        <br><br><br>
        <div style="padding: 20px; text-align: center;">
            <P style="font-size: 8px;">Resumen generado por ${ruta}</P>
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
        <title>Resumen</title>
    </head>
    
    <body>
    
        <div style="text-align: center; padding: 20px;">
            <p style="font-weight: bold; font-size: 40px; color: #4A6C6F;">$empresa</p>
            <p style="color: #2b74af;">$telefono</p>
        </div>
        <div style="padding: 20px;">
            <h3 style="color: #2baf6d;">Ruta $ruta</h3>
            <h5 style="color: #2baf6d;">Generado: ${fechaActual()} ${horaActual()}</h5>
        </div>
    
        <div style="padding: 20px;">
            <table id="customers" style="border-radius: 5px; border-collapse: collapse; overflow: hidden;">
                <tr>
                    <th>Tipo</th>
                    <th>Valor</th>
                </tr>
                <tr>
                    <td>Cobrado</td>
                    <td>${cobrado}</td>
                </tr>
                <tr>
                    <td>Prestado</td>
                    <td>${prestado}</td>
                </tr>
                <tr>
                    <td>Gastos</td>
                    <td>${gastos}</td>
                </tr>
                <tr>
                    <td>Capital cobrado</td>
                    <td>${capital}</td>
                </tr>
                <tr>
                    <td>Interes</td>
                    <td>${interes}</td>
                </tr>
                <tr>
                    <td>Pagos realizados</td>
                    <td>${pagosrealizados}</td>
                </tr>
                <tr>
                    <td>Mora</td>
                    <td>${mora}</td>
                </tr>
                <tr>
                    <td>Movimientos en caja</td>
                    <td>${movimientoscaja}</td>
                </tr>
                <tr>
                    <td>Numero de gastos</td>
                    <td>${numerogastos}</td>
                </tr>
                <tr>
                    <td>Prestamos realizados</td>
                    <td>${totalprestamos}</td>
                </tr>
                <tr>
                    <td>Clientes nuevos ingresados</td>
                    <td>${clientesnuevos}</td>
                </tr>
                <tr>
                    <td>Recibos imprimidos</td>
                    <td>${impresiones}</td>
                </tr>
                <tr>
                    <td>Recibos compartidos</td>
                    <td>${compartidos}</td>
                </tr>
                <tr>
                    <td>Clientes editados</td>
                    <td>${clienteseditados}</td>
                </tr>
                <tr>
                    <td>Pagos cancelados</td>
                    <td>${pagoscancelados}</td>
                </tr>
            </table>
        </div>
        <div style="padding: 10px; margin: 20px; border: 1px solid #c7c8c9; border-radius: 5px;">
            <h5 style="color: #2b74af;">Movimientos</h5>
            <p style="font-size: 12px;">${movimientos}</p>
        </div>
        <br><br><br>
        <div style="padding: 20px; text-align: center;">
            <P style="font-size: 8px;">Resumen generado por ${ruta}</P>
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
    var targetFileName = "ResumenDia";

    File generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(htmlContent, pathdirectorio, targetFileName);

    return generatedPdfFile;
  }

}

class prestamosHoy extends StatefulWidget {
  @override
  _prestamosHoyState createState() => _prestamosHoyState();
}

class _prestamosHoyState extends State<prestamosHoy> {

  List<Map> prestamosHoy;

  @override
  void initState() {
    getPrestamosHoy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: prestamosHoy == null ? 0 : prestamosHoy.length,
            itemBuilder: (context,index) {
              if (prestamosHoy == null) {
                return CircularProgressIndicator();
              } else {
                final item = prestamosHoy[index];
                return ListTile(
                  onTap: (){
                    String key = item['key'].toString();
                    String nombre = item['nombre'];
                    print("key $key $nombre");
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>HacerPagos(key, nombre)));
                  },
                  title: Text(" ${item['nombre']} "),
                  subtitle: Text("${item['capital']} Plazo ${item['plazo']}"),
                  leading: Icon(Icons.check),
                  trailing: Text("${item['modalidad']}"),
                );
              }
            }),
      ),
    );
  }

  getPrestamosHoy()async{
    Database database = await opendb();
    List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE fecha =?", [fechaActual()]);
    await database.close();
    List<Map> list = new List();
    if(prestamos.length<=0){

    }else{
      await Future.forEach(prestamos, (prestamo) async {
        String key = prestamo['pertenece'].toString();
        String nombre = await getDatoCliente(key, "nombre");
        String capital = prestamo['capital'].toString();
        String plazo = prestamo['plazo'].toString();
        String modalidad = prestamo['modalidad'].toString();

        Map map = {
          "key": key,
          "nombre": nombre,
          "capital": capital,
          "plazo": plazo,
          "modalidad": modalidad,
        };

        list.add(map);
      });
      setState(() {
        prestamosHoy = list;
      });
    }
    print("prestamos hoy $prestamos");
  }
}



