import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:prestagroons/ResumenDia.dart';
import 'package:sqflite/sqflite.dart';

import 'meTodo.dart';

class MenuBalances extends StatefulWidget {
  @override
  _MenuBalancesState createState() => _MenuBalancesState();
}

class _MenuBalancesState extends State<MenuBalances> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>Balances()));
                    },
                    child: Material(
                      elevation: 20,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.show_chart,color: Colores.secundario,),
                            Text("Balances mes",style: TextStyle(color: Colores.primario),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>ComparacionMeses()));
                    },
                    child: Material(
                      elevation: 20,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.multiline_chart,color: Colores.secundario,),
                            Text("Comprarar meses",style: TextStyle(color: Colores.primario),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: (){
                      String fecha = fechaActual();
                      List list = fecha.split("/");
                      String mes = list[1];
                      String anio = list[2];
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>LiquidacionesMesaMes(mes,anio)));
                    },
                    child: Material(
                      elevation: 20,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.multiline_chart,color: Colores.secundario,),
                            Text("Liquidaciones",style: TextStyle(color: Colores.primario),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child:InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnalizesBalancesMes()));
                    },
                    child:  Material(
                      elevation: 20,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.grain,color: Colores.secundario,),
                            Text("Analizes",style: TextStyle(color: Colores.primario),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Balances extends StatefulWidget {
  @override
  _BalancesState createState() => _BalancesState();
}

class _BalancesState extends State<Balances> {

  Color colorLetras = Colores.secundario;
  Color colorFondo = Colores.primario;
  Color colorFondoDos = Colores.tercero;
  bool isShowingMainData = true;
  int touchedIndex;
  Color colorgraficauno = Color(0xff7b2cbf);

  String mesSeleccionado = "";
  String anioSeleccionado = "";
  String mesSeleccionadoLetras = "";
  double promediodinero = 0;
  String enlacalle = "0";
  List<Map> listaMeses = null;
  double gastos =0,prestamos=0,cobro=0,ganancia = 0;
  double pagos=0,dineroCalle=0,mora=0,clientesNuevos=0,prestamosRealizados=0,caja=0,impresiones=0,compartidos=0,clienteseditados=0;
  int balancesrecogidosmes = 0;
  List<FlSpot> listaCobro = [FlSpot(1, 0),];
  List<FlSpot> listaPrestado = [FlSpot(1, 0),];
  List<FlSpot> listaGanancia = [FlSpot(1, 0),];

  List<Map> balancesMes = null;

  List<BarChartGroupData> lista12meses;

  @override
  void initState() {
    this.leerbalancesTodos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: colorFondo,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 40,left: 10,right: 10,bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 20,),
                    Text("Balance calle",style: TextStyle(color: Color(0xff72719b)),),
                    Text("$dineroCalle",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold,color: Colors.white),),
                    SizedBox(height: 10,),
                    Container(
                      height: 100,
                      padding: EdgeInsets.only(top: 30,),
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: listaMeses == null ? 0 : listaMeses.length,
                          itemBuilder: (context,index){
                            if (listaMeses == null) {
                              return CircularProgressIndicator();
                            } else {
                              final item = listaMeses[index];
                              return InkWell(
                                onTap: (){
                                  mesSeleccionado = item['mes'].toString();
                                  anioSeleccionado = item['anio'].toString();
                                  mesSeleccionadoLetras = getMesEnLetras(item['mes'].toString());
                                  cargarDatosMes();
                                },
                                child: SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: mesSeleccionado==item['mes']&&anioSeleccionado==item['anio']?Colores.secundario:Colors.white),
                                      borderRadius: BorderRadius.all(Radius.circular(50)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(" ${item['mesletras']} ${item['anio']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                                  ),
                                ),
                              );
                            }
                          }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20),),
                  color: colorFondo,
                ),
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Text("Balances del mes",style: TextStyle(color: Colors.white),),
                    SizedBox(height: 20,),
                    graficaMesPrincipal(),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Cobro",style: TextStyle(color: colorLetras)),
                        Text("$cobro",style: TextStyle(color: Color(0xff0466c8))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Prestamos",style: TextStyle(color: colorLetras)),
                        Text("$prestamos",style: TextStyle(color: Color(0xff9e0059))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Gastos",style: TextStyle(color: colorLetras),),
                        Text("$gastos",style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Ganancia",style: TextStyle(color: colorLetras)),
                        Text("$ganancia",style: TextStyle(color: Color(0xff41ead4))),
                      ],
                    ),
                    SizedBox(height: 20,),
                    Material(
                      elevation: 20,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                          gradient: LinearGradient(
                            colors: [
                              Colores.tercero,
                              Colores.primario,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Text("Totales del mes $mesSeleccionadoLetras",style: TextStyle(color: colorLetras)),
                            SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Cobrado",style: TextStyle(color: colorLetras)),
                                Text("${cobro}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Gastos",style: TextStyle(color: colorLetras)),
                                Text("${gastos}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Prestado",style: TextStyle(color: colorLetras)),
                                Text("${prestamos}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Ganancia",style: TextStyle(color: colorLetras)),
                                Text("${ganancia}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Pagos",style: TextStyle(color: colorLetras)),
                                Text("${pagos}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Mora cobrado",style: TextStyle(color: colorLetras)),
                                Text("${mora}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Clientes nuevos",style: TextStyle(color: colorLetras)),
                                Text("${clientesNuevos}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Prestamos realizados",style: TextStyle(color: colorLetras)),
                                Text("${prestamosRealizados}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Recibos imprimidos",style: TextStyle(color: colorLetras)),
                                Text("${impresiones}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Recibos compartidos",style: TextStyle(color: colorLetras)),
                                Text("${compartidos}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Clientes editados",style: TextStyle(color: colorLetras)),
                                Text("${clienteseditados}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Numero de balances del mes",style: TextStyle(color: colorLetras)),
                                Text("${balancesrecogidosmes}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                    ),
                    Material(
                      elevation: 20,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                          gradient: LinearGradient(
                            colors: [
                              Colores.tercero,
                              Colores.primario,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Text("Tus promedios diario",style: TextStyle(color: colorLetras,fontWeight: FontWeight.bold)),
                            Text("Promedio del mes $mesSeleccionadoLetras",style: TextStyle(color: colorLetras)),
                            SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio cobro",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(cobro/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio gastos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(gastos/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio prestamos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(prestamosRealizados/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio ganancia",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(ganancia/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio pagos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(pagos/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio dinero calle",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(dineroCalle/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio cobro mora",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(mora/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio clientes nuevos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(clientesNuevos/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio prestado",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(prestamos/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio caja",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(caja/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio recibos imprimidos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(impresiones/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio recibos compartidos",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(compartidos/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Promedio clientes editados",style: TextStyle(color: colorLetras)),
                                Text("${dejarDosDecimales(clienteseditados/balancesrecogidosmes)}",style: TextStyle(color: colorLetras)),
                              ],
                            ),
                            Divider(height: 1,color: colorLetras,),
                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              balancesMes==null?Container():Padding(
                padding: EdgeInsets.all(10),
                child: Material(
                  elevation: 20,
                  color: colorFondo,
                  child: Container(
                    color: colorFondo,
                    child: Column(
                      children: <Widget>[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              sortColumnIndex: 0,
                              columns: [
                                DataColumn(
                                  label: Text("Dia", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Resumen caja", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Resumen dia", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Cobrado", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Prestamos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Gastos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Ganancia", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Dinero calle", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Clientes nuevos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Nuevos prestamos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Pagos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Mora", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Caja", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Clientes editados", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Impresiones", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                                DataColumn(
                                  label: Text("Compartidos", style: TextStyle(fontWeight: FontWeight.bold,color: Colores.grisclaro),),
                                  numeric: false,
                                ),
                              ],
                              rows: balancesMes == null ? null: balancesMes.map((balance) =>
                                  DataRow(cells: [
                                    DataCell(
                                      Text(balance['dia'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                        Icon(Icons.assignment,color: colorLetras,),
                                        onTap: (){
                                          String dia = balance['dia'].toString();
                                          String mes = balance['mes'].toString();
                                          String anio = balance['anio'].toString();
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>MovimientosCaja("$dia/$mes/$anio")));
                                        }
                                    ),
                                    DataCell(
                                        Icon(Icons.assignment,color: colorLetras,),
                                        onTap: (){
                                          String dia = balance['dia'].toString();
                                          String mes = balance['mes'].toString();
                                          String anio = balance['anio'].toString();
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>MovimientosDia("$dia/$mes/$anio")));
                                        }
                                    ),
                                    DataCell(
                                      Text(balance['cobrado'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['valorprestado'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['gastos'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['ganancia'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['dinerocalle'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['clientesnuevos'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['numeroprestamos'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['pagos'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['mora'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(dejarDosDecimales(double.parse(balance['caja'].toString())),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['editados'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['impresiones'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                    DataCell(
                                      Text(balance['compartidos'].toString(),style: TextStyle(color: colorLetras),),
                                    ),
                                  ]),
                              ).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 30,width: double.infinity,)
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

  Future<Map> leerbalancesTodos()async{

    String fecha = fechaActual();
    List valor = fecha.split("/");
    mesSeleccionado = valor[1];
    anioSeleccionado = valor[2];
    mesSeleccionadoLetras = getMesEnLetras(mesSeleccionado);


    Database database = await opendb();
    List<Map> list = await database.rawQuery("SELECT * FROM balances ORDER BY anio DESC, mes DESC, dia ASC");
    await database.close();

    listaMeses = new List();

    String mesya = "";
    await Future.forEach(list, (balance) {

      String id = balance['id'].toString();
      String day = balance['dia'].toString();
      String mes = balance['mes'].toString();
      String anio = balance['anio'].toString();
      if(int.parse(mes)<10)mes = "0"+mes; //para ponerle el 0 al mes si es menor de 10

      if(mes!=mesya){
        listaMeses.add({"id":id,"mes":mes,"mesletras":getMesEnLetras(mes),"anio":anio});
        mesya = mes;
      }

    });

    await cargarDatosMes();
  }

  Widget graficaMesPrincipal(){
    return Material(
      elevation: 20,
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(0)),
            gradient: LinearGradient(
              colors: [
                Colores.tercero,
                Colores.primario,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(
                    height: 37,
                  ),
                  Text(
                    'Movimientos $anioSeleccionado',
                    style: TextStyle(
                      color: Color(0xff827daa),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text("Mes $mesSeleccionadoLetras", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center,),
                  const SizedBox(
                    height: 37,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                      child: LineChart(graficames(),
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
      ),
    );
  }

  LineChartData graficames() {
    print("promedio dinero $promediodinero");
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
      maxX: 30, //promedio maximo ancho
      maxY: promediodinero, //promedio maximo alto
      minY: 0, //minimo izquierdo
      lineBarsData: datosdelmes(),
    );
  }

  List<LineChartBarData> datosdelmes() {

    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: listaCobro,
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
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: listaGanancia,
      isCurved: true,
      colors: [
        const Color(0xff41ead4),
      ],
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(show: false, colors: [
        const Color(0x00aa4cfc),
      ]),
    );
    final LineChartBarData lineChartBarData3 = LineChartBarData(
      spots: listaPrestado,
      isCurved: true,
      colors: const [
        Color(0xff9e0059),
      ],
      barWidth: 2,
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
      lineChartBarData2,
      lineChartBarData3,
    ];
  }

  void cargarDatosMes()async{

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE mes = $mesSeleccionado and anio = $anioSeleccionado ORDER BY dia');
    await database.close();


    if(list.length>0) {
      balancesrecogidosmes = list.length;
      balancesMes = new List();
      balancesMes = list;
      gastos = 0;
      prestamos = 0;
      cobro = 0;
      ganancia = 0;
      listaCobro = new List();
      listaPrestado = new List();
      listaGanancia = new List();

      pagos = 0;
      mora = 0;
      caja = 0;
      clientesNuevos = 0;
      prestamosRealizados = 0;
      impresiones = 0;
      compartidos = 0;
      clienteseditados = 0;
      promediodinero = 0;

      await Future.forEach(list, (balance) {
        //print("balance $balance");
        //dia: 3, mes: 7, anio: 2020, cobrado: 450000, capital: 400000, interes: 50000, ganancia: 55000, dinerocalle: 20500000,
        // clientesnuevos: 2, numeroprestamos: 3, valorprestado: 300000, pagos: 12, mora: 5000, impresiones: 10, compartidos: 2,
        // editados: 2, gastos: 35000, caja: 120000, movimientoscaja: movimientos de la caja, movimientosdia: movimientos del dia

        double dia = double.parse(balance['dia'].toString());
        double cobrado = double.parse(balance['cobrado'].toString());
        double prestamo = double.parse(balance['valorprestado'].toString());
        double gananc = double.parse(balance['ganancia'].toString());
        double gasto = double.parse(balance['gastos'].toString());
        double dinerocalle = double.parse(balance['dinerocalle'].toString());
        int pagosdia = int.parse(balance['pagos'].toString());
        double moradia = double.parse(balance['mora'].toString());
        double clientesnuevo = double.parse(
            balance['clientesnuevos'].toString());
        double caj = double.parse(balance['caja'].toString());
        int numerprestamos = int.parse(balance['numeroprestamos'].toString());
        int impresionesdia = int.parse(balance['impresiones'].toString());
        int compartidosdia = int.parse(balance['compartidos'].toString());
        int editadosdia = int.parse(balance['editados'].toString());

        dineroCalle = dinerocalle;
        gastos = gastos + gasto;
        prestamos = prestamos + prestamo;
        cobro = cobro + cobrado;
        ganancia = ganancia + gananc;

        pagos = pagos + pagosdia;
        mora = mora + moradia;
        caja = caja + caj;
        clientesNuevos = clientesNuevos + clientesnuevo;
        prestamosRealizados = prestamosRealizados + numerprestamos;
        impresiones = impresiones + impresionesdia;
        compartidos = compartidos + compartidosdia;
        clienteseditados = clienteseditados + editadosdia;

        if (promediodinero < cobrado) promediodinero = cobrado;
        if (promediodinero < prestamo) promediodinero = prestamo;


        listaCobro.add(new FlSpot(dia, cobrado));
        listaPrestado.add(new FlSpot(dia, prestamo));
        listaGanancia.add(new FlSpot(dia, gananc));
      });
    }
    
    ganancia = double.parse(dejarDosDecimales(ganancia));

    setState(() {});

  }

}

class MovimientosCaja extends StatefulWidget {
  String fechabuscar;
  MovimientosCaja(this.fechabuscar);

  @override
  _MovimientosCajaState createState() => _MovimientosCajaState();
}

class _MovimientosCajaState extends State<MovimientosCaja> {
  String fechaBuscar = "";
  String movimientos = "";

  @override
  void initState() {
    fechaBuscar = widget.fechabuscar;
    this.movimientoscaja();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xff001845),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                //color: Colores.azul,
                alignment: Alignment.topLeft,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Movimientos",style: TextStyle(color: Colors.white),),
                    Text("$movimientos",style: TextStyle(color: Colors.white,fontSize: 9),),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> movimientoscaja()async{

    List valor = fechaBuscar.split("/");
    String dia = valor[0].toString();
    String mes = valor[1].toString();
    String anio = valor[2].toString();

    String enter = "\n";

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE dia = $dia and mes = $mes and anio = $anio');
    await database.close();
    print("list $list");
    if(list.length>0) {
      String movimientoscaja = list[0]['movimientoscaja'].toString();

      List movimient = movimientoscaja.split("*");
      movimient.removeAt(0); //elimina un asterisco que no tiene nada
      await Future.forEach(movimient, (movi) {
        movimientos = movimientos+"*"+movi;
      });
    }
    setState(() {

    });
  }
}

class MovimientosDia extends StatefulWidget {
  String fechabuscar;
  MovimientosDia(this.fechabuscar);

  @override
  _MovimientosDiaState createState() => _MovimientosDiaState();
}

class _MovimientosDiaState extends State<MovimientosDia> {

  String fechaBuscar = "";
  String movimientos = "";

  @override
  void initState() {
    fechaBuscar = widget.fechabuscar;
    this.movimientosdia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xff03045e),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                //color: Colores.azul,
                alignment: Alignment.topLeft,
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Movimientos",style: TextStyle(color: Colors.white),),
                    Text("$movimientos",style: TextStyle(color: Colors.white,fontSize: 9),),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> movimientosdia()async{

    List valor = fechaBuscar.split("/");
    String dia = valor[0].toString();
    String mes = valor[1].toString();
    String anio = valor[2].toString();

    String enter = "\n";

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE dia = $dia and mes = $mes and anio = $anio');
    await database.close();

    if(list.length>0) {
      String movimientosdia = list[0]['movimientosdia'].toString();

      List movimient = movimientosdia.split("*");
      movimient.removeAt(0); //elimina un asterisco que no tiene nada
      await Future.forEach(movimient, (movi) {
        movimientos = movimientos+"*"+movi;
      });
    }
    setState(() {

    });
  }
}

class LiquidacionesMesaMes extends StatefulWidget {
  String mes;
  String anio;
  LiquidacionesMesaMes(this.mes,this.anio);

  @override
  _LiquidacionesMesaMesState createState() => _LiquidacionesMesaMesState();
}

class _LiquidacionesMesaMesState extends State<LiquidacionesMesaMes> {

  List<Map> listaMeses = null;
  String mesSeleccionado = "";
  String anioSeleccionado = "";
  String mesSeleccionadoLetras = "";
  List<Map> listaLiquidacionesMes = null;

  @override
  void initState() {
    mesSeleccionado = "${int.parse(widget.mes)}";
    anioSeleccionado = "${int.parse(widget.anio)}";
    mesSeleccionadoLetras = getMesEnLetras(mesSeleccionado);
    this.leerMeses();
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
                height: 100,
                padding: EdgeInsets.only(top: 30,),
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: listaMeses == null ? 0 : listaMeses.length,
                    itemBuilder: (context,index){
                      if (listaMeses == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaMeses[index];
                        return InkWell(
                          onTap: (){
                            mesSeleccionado = item['mes'].toString();
                            anioSeleccionado = item['anio'].toString();
                            mesSeleccionadoLetras = getMesEnLetras(item['mes'].toString());
                            cargarDatosMes();
                          },
                          child: SizedBox(
                            width: 140,
                            height: 50,
                            child: Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(color: mesSeleccionado==item['mes']&&anioSeleccionado==item['anio']?Colors.lightBlueAccent:Colors.indigo),
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                              alignment: Alignment.center,
                              child: Text(" ${item['mesletras']} ${item['anio']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.indigo),),
                            ),
                          ),
                        );
                      }
                    }),
              ),
              SizedBox(height: 20,),
              Container(
                padding: EdgeInsets.only(top: 30,),
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: listaLiquidacionesMes == null ? 0 : listaLiquidacionesMes.length,
                    itemBuilder: (context,index){
                      if (listaLiquidacionesMes == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaLiquidacionesMes[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            border: Border.all(color:Colors.black12,width: 1),
                          ),
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(5),
                          child: ListTile(
                            onTap: (){
                              String fecha = item['fecha'].toString();
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>MovimientosDia(fecha)));
                            },
                            title: Text("Dia ${item['dia']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.indigo),),
                            subtitle: Text("${item['liquidaciones']}",style: TextStyle(fontSize: 12),),
                            trailing: Text("${item['totalliquidaciones']} Veces",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.indigo),),
                          ),
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

  void leerMeses()async{
    listaMeses = new List();
    List<Map> lista = new List();
    Database database = await opendb();
    List<Map> balances = await database.rawQuery("SELECT * FROM balances ORDER BY anio DESC ,mes DESC, dia ASC");
    await database.close();

    String mesya = "";

    await Future.forEach(balances, (balance){
      String mes = balance['mes'].toString();
      String anio = balance['anio'].toString();
      if(mesya!=mes){
        lista.add({"mes":mes,"mesletras":getMesEnLetras(mes),"anio":anio});
        mesya = mes;
      }

    });

    listaMeses = lista;
    cargarDatosMes();
  }

  void cargarDatosMes()async{

    listaLiquidacionesMes = new List();
    List<Map> lista = new List();
    Database database = await opendb();
    List<Map> balances = await database.rawQuery("SELECT * FROM balances WHERE mes=$mesSeleccionado AND anio=$anioSeleccionado ORDER BY dia DESC");
    await database.close();

    await Future.forEach(balances, (balance){
      String dia = balance['dia'].toString();
      String mes = balance['mes'].toString();
      String anio = balance['anio'].toString();
      String liquidaciones = balance['liquidaciones'].toString();
      List item = liquidaciones.split("*");

      if(liquidaciones.length>0){
        lista.add({"fecha":"$dia/$mes/$anio","dia":dia,"totalliquidaciones":"${item.length}","liquidaciones":liquidaciones});
      }


    });

    setState(() {
      listaLiquidacionesMes = lista;
    });


  }

}

class ComparacionMeses extends StatefulWidget {
  @override
  _ComparacionMesesState createState() => _ComparacionMesesState();
}

class _ComparacionMesesState extends State<ComparacionMeses> {

  Color colorFondo = Colores.primario;
  int touchedIndex;
  List<Map> listaMeses;
  List<Map> listaopciones;
  String opcionSeleccionada = "cobro";

  String mesUnoSeleccionado = "0";
  String anioUnoSeleccionado;
  String mesDosSeleccionado = "0";
  String anioDosSeleccionado;

  double promediodinero = 10;
  List<FlSpot> listadatomesuno = [FlSpot(1, 0)];
  List<FlSpot> listadatomesdos = [FlSpot(1, 0)];

  String porcentajesubio = "";
  String totalesmesunovsmesdos = "";
  String promediomesuno = "";
  String promediomesdos = "";

  @override
  void initState() {
    this.getListaOpcion();
    this.cargarMeses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: colorFondo,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                color: colorFondo,
                height: 300,
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 100,
                      padding: EdgeInsets.only(top: 30,),
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: listaMeses == null ? 0 : listaMeses.length,
                          itemBuilder: (context,index){
                            if (listaMeses == null) {
                              return CircularProgressIndicator();
                            } else {
                              final item = listaMeses[index];
                              return InkWell(
                                onTap: (){
                                  mesUnoSeleccionado = item['mes'].toString();
                                  anioUnoSeleccionado = item['anio'].toString();
                                  actualizarComparacion();
                                },
                                child: SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: mesUnoSeleccionado==item['mes']&&anioUnoSeleccionado==item['anio']?Color(0xffff006e):Colors.white),
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(" ${item['mesletras']} ${item['anio']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                                  ),
                                ),
                              );
                            }
                          }),
                    ),
                    Container(
                      height: 100,
                      padding: EdgeInsets.only(top: 30,),
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: listaMeses == null ? 0 : listaMeses.length,
                          itemBuilder: (context,index){
                            if (listaMeses == null) {
                              return CircularProgressIndicator();
                            } else {
                              final item = listaMeses[index];
                              return InkWell(
                                onTap: (){
                                  mesDosSeleccionado = item['mes'].toString();
                                  anioDosSeleccionado = item['anio'].toString();
                                  actualizarComparacion();
                                },
                                child: SizedBox(
                                  width: 140,
                                  height: 50,
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: mesDosSeleccionado==item['mes']&&anioDosSeleccionado==item['anio']?Color(0xff2ec4b6):Colors.white),
                                      borderRadius: BorderRadius.all(Radius.circular(50)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(" ${item['mesletras']} ${item['anio']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                                  ),
                                ),
                              );
                            }
                          }),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                      children: <Widget>[
                        Container(
                          child: Text("Seleccione dos meses para compararlos",style: TextStyle(color: Colors.white),),
                        ),
                      ],
                      )
                    ),
                  ],
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: graficaMes(),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Text("$totalesmesunovsmesdos",style: TextStyle(color: Colors.white,fontSize: 12),),
                    Text("$porcentajesubio",style: TextStyle(color: Colors.white,fontSize: 12),),
                    Text("$promediomesuno",style: TextStyle(color: Colors.white,fontSize: 12),),
                    Text("$promediomesdos",style: TextStyle(color: Colors.white,fontSize: 12),),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void cargarMeses()async{

    //dia: 3, mes: 7, anio: 2020, cobrado: 450000, capital: 400000, interes: 50000, ganancia: 55000, dinerocalle: 20500000,
    // clientesnuevos: 2, numeroprestamos: 3, valorprestado: 300000, pagos: 12, mora: 5000, impresiones: 10, compartidos: 2,
    // editados: 2, gastos: 35000, caja: 120000, movimientoscaja: movimientos de la caja, movimientosdia: movimientos del dia

    Database database = await opendb();
    List<Map> lista = await database.rawQuery('SELECT * FROM balances ORDER BY anio DESC, mes DESC, dia ASC');
    await database.close();

    if(lista.length>0) {
      listaMeses = new List();
      String agrego = "";
      await Future.forEach(lista, (balance) {
        String mes = balance['mes'].toString();
        String anio = balance['anio'].toString();
        String mesLetras = getMesEnLetras(mes);
        if (mes != agrego) {
          listaMeses.add({"mes": mes, "anio": anio, "mesletras": mesLetras});
          agrego = mes;
        }
      });

      int items = lista.length;
      mesUnoSeleccionado = lista[0]['mes'].toString();
      anioUnoSeleccionado = lista[0]['anio'].toString();
      mesDosSeleccionado = lista[items-1]['mes'].toString();
      anioDosSeleccionado = lista[items-1]['anio'].toString();

      actualizarComparacion();
    }


  }

  void actualizarComparacion() async{

    Database database = await opendb();
    List<Map> listUno = await database.rawQuery('SELECT * FROM balances WHERE mes = $mesUnoSeleccionado and anio = $anioUnoSeleccionado ORDER BY dia ASC');
    List<Map> listDos = await database.rawQuery('SELECT * FROM balances WHERE mes = $mesDosSeleccionado and anio = $anioDosSeleccionado ORDER BY dia ASC');
    await database.close();

    listadatomesuno = new List();
    listadatomesdos = new List();
    promediodinero = 0;

    double totaluno = 0;
    double totaldos = 0;

    await Future.forEach(listUno, (balance) {

      double dia = double.parse(balance['dia'].toString());
      double cobrado = double.parse(balance['cobrado'].toString());
      double prestamo = double.parse(balance['valorprestado'].toString());
      double gananc = double.parse(balance['ganancia'].toString());
      double gasto = double.parse(balance['gastos'].toString());
      double dinerocalle = double.parse(balance['dinerocalle'].toString());
      int pagosdia = int.parse(balance['pagos'].toString());
      double moradia = double.parse(balance['mora'].toString());
      double clientesnuevo = double.parse(balance['clientesnuevos'].toString());
      double caj = double.parse(balance['caja'].toString());
      int numerprestamos = int.parse(balance['numeroprestamos'].toString());
      int impresionesdia = int.parse(balance['impresiones'].toString());
      int compartidosdia = int.parse(balance['compartidos'].toString());
      int editadosdia = int.parse(balance['editados'].toString());

      if(opcionSeleccionada=="cobro"){
        double valor = cobrado;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="gastos"){
        double valor = gasto;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="prestamos"){
        double valor = prestamo;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="ganancia"){
        double valor = gananc;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="pagos"){
        double valor = pagosdia.toDouble();
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="mora"){
        double valor = moradia;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="dinerocalle"){
        double valor = dinerocalle;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="clientesnuevos"){
        double valor = clientesnuevo;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="numeroprestamos"){
        double valor = numerprestamos.toDouble();
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="caja"){
        double valor = caj;
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="impresiones"){
        double valor = impresionesdia.toDouble();
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="compartidos"){
        double valor = compartidosdia.toDouble();
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="editados"){
        double valor = editadosdia.toDouble();
        totaluno = totaluno+valor;
        listadatomesuno.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }

    });

    await Future.forEach(listDos, (balance) {

      double dia = double.parse(balance['dia'].toString());
      double cobrado = double.parse(balance['cobrado'].toString());
      double prestamo = double.parse(balance['valorprestado'].toString());
      double gananc = double.parse(balance['ganancia'].toString());
      double gasto = double.parse(balance['gastos'].toString());
      double dinerocalle = double.parse(balance['dinerocalle'].toString());
      int pagosdia = int.parse(balance['pagos'].toString());
      double moradia = double.parse(balance['mora'].toString());
      double clientesnuevo = double.parse(balance['clientesnuevos'].toString());
      double caj = double.parse(balance['caja'].toString());
      int numerprestamos = int.parse(balance['numeroprestamos'].toString());
      int impresionesdia = int.parse(balance['impresiones'].toString());
      int compartidosdia = int.parse(balance['compartidos'].toString());
      int editadosdia = int.parse(balance['editados'].toString());

      if(opcionSeleccionada=="cobro"){
        double valor = cobrado;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="gastos"){
        double valor = gasto;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="prestamos"){
        double valor = prestamo;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="ganancia"){
        double valor = gananc;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="pagos"){
        double valor = pagosdia.toDouble();
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="mora"){
        double valor = moradia;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="dinerocalle"){
        double valor = dinerocalle;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="clientesnuevos"){
        double valor = clientesnuevo;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="numeroprestamos"){
        double valor = numerprestamos.toDouble();
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="caja"){
        double valor = caj;
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="impresiones"){
        double valor = impresionesdia.toDouble();
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="compartidos"){
        double valor = compartidosdia.toDouble();
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }else if(opcionSeleccionada=="editados"){
        double valor = editadosdia.toDouble();
        totaldos = totaldos+valor;
        listadatomesdos.add(FlSpot(dia,valor));
        if(promediodinero<valor)promediodinero=valor;
      }

    });

    //print("totaluno $totaluno totaldos $totaldos");
    int balancesuno = listUno.length;
    int balancesdos = listDos.length;
    double promediouno = totaluno/balancesuno;
    double promediodos = totaldos/balancesdos;

    totalesmesunovsmesdos = "${getMesEnLetras(mesUnoSeleccionado)} $anioUnoSeleccionado $totaluno vs ${getMesEnLetras(mesDosSeleccionado)} $anioDosSeleccionado $totaldos";
    promediomesuno = "Promedio ${dejarDosDecimales(promediouno)} de ${getMesEnLetras(mesUnoSeleccionado)} $anioUnoSeleccionado ($balancesuno balances)";
    promediomesdos = "Promedio ${dejarDosDecimales(promediodos)} de ${getMesEnLetras(mesDosSeleccionado)} $anioDosSeleccionado ($balancesdos balances)";

    double sobro = totaluno-totaldos;
    double unoporcientoes = 100/totaldos;
    double porcentaje = unoporcientoes*sobro;
    String letras = "subio";
    //print("totaluno $totaluno totaldos $totaldos sobro $sobro totalunociento $unoporcientoes");

    if(porcentaje<0){
      letras = "bajo";
    }

    porcentajesubio = "${getMesEnLetras(mesUnoSeleccionado)} $anioUnoSeleccionado $letras ${dejarDosDecimales(porcentaje)}% con respecto a ${getMesEnLetras(mesDosSeleccionado)} $anioDosSeleccionado";


    setState(() {});
  }

  Widget graficaMes(){
    return Material(
      elevation: 20,
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(0)),
            gradient: LinearGradient(
              colors: [Colores.tercero, Colores.primario,],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(
                    height: 37,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text("${getMesEnLetras(mesUnoSeleccionado)} $anioUnoSeleccionado vs ${getMesEnLetras(mesDosSeleccionado)} $anioDosSeleccionado", style: TextStyle(color: Color(0xffffff3f), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center,),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 40,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: listaopciones == null ? 0 : listaopciones.length,
                        itemBuilder: (context,index){
                          if (listaopciones == null) {
                            return CircularProgressIndicator();
                          } else {
                            final item = listaopciones[index];
                            return InkWell(
                              onTap: (){
                                opcionSeleccionada = item['name'];
                                actualizarComparacion();
                              },
                              child: SizedBox(
                                width: 80,
                                height: 20,
                                child: Container(
                                  margin: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: opcionSeleccionada==item['name']?Color(0xffffff3f):Colors.white),
                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(" ${item['letras']}",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 10),),
                                ),
                              ),
                            );
                          }
                        }),
                  ),
                  const SizedBox(
                    height: 37,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 0),
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
      ),
    );
  }

  LineChartData grafica() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white,
        ),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(show: false,),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: const TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.bold, fontSize: 7,),
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
              case 10:
                return '10';
              case 100:
                return '100';
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
              color: Color(0xffd9d9d9),
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
      maxX: 30, //promedio maximo ancho
      maxY: promediodinero, //promedio maximo alto
      minY: 0, //minimo izquierdo
      lineBarsData: datosdelmes(),
    );
  }

  List<LineChartBarData> datosdelmes() {

    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: listadatomesuno,
      isCurved: true,
      colors: [
        const Color(0xffff006e),
      ],
      barWidth: 4, //grosor de la linea
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: listadatomesdos,
      isCurved: true,
      colors: [
        const Color(0xff2ec4b6),
      ],
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(show: false, colors: [
        const Color(0x00ffffff),
      ]),
    );
    return [
      lineChartBarData1,
      lineChartBarData2,
    ];
  }

  void getListaOpcion(){
    listaopciones = new List();
    listaopciones.add({"name":"cobro","letras":"Cobro"});
    listaopciones.add({"name":"gastos","letras":"Gastos"});
    listaopciones.add({"name":"prestamos","letras":"Prestamos"});
    listaopciones.add({"name":"ganancia","letras":"Ganancia"});
    listaopciones.add({"name":"pagos","letras":"Pagos"});
    listaopciones.add({"name":"mora","letras":"Mora"});
    listaopciones.add({"name":"dinerocalle","letras":"Dinero calle"});
    listaopciones.add({"name":"clientesnuevos","letras":"Clientes new"});
    listaopciones.add({"name":"numeroprestamos","letras":"# prestamos"});
    listaopciones.add({"name":"caja","letras":"Caja"});
    listaopciones.add({"name":"impresiones","letras":"Impresiones"});
    listaopciones.add({"name":"compartidos","letras":"Compartidos"});
    listaopciones.add({"name":"editados","letras":"Editados"});
  }

  //otra grafica
  Widget graficaGananciaMes(){
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color:  Color(0xfffef9ef),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text('Ganancia', style: TextStyle(color: Color(0xff3d348b), fontSize: 24, fontWeight: FontWeight.bold),),
                  const SizedBox(
                    height: 4,
                  ),
                  Text('Grafica ultimos 12 meses', style: TextStyle(color: Color(0xff3d348b), fontSize: 18, fontWeight: FontWeight.bold),),
                  const SizedBox(
                    height: 38,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: BarChart(
                        mainBarData(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Color(0xff3d348b),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String weekDay;
              switch (group.x.toInt()) {
                case 0:
                  weekDay = 'otro';
                  break;
                case 1:
                  weekDay = 'Enero';
                  break;
                case 2:
                  weekDay = 'Febrero';
                  break;
                case 3:
                  weekDay = 'Marzo';
                  break;
                case 4:
                  weekDay = 'Abril';
                  break;
                case 5:
                  weekDay = 'Mayo';
                  break;
                case 6:
                  weekDay = 'Junio';
                  break;
                case 7:
                  weekDay = 'Julio';
                  break;
                case 8:
                  weekDay = 'Agosto';
                  break;
                case 9:
                  weekDay = 'Septiembre';
                  break;
                case 10:
                  weekDay = 'Octubre';
                  break;
                case 11:
                  weekDay = 'Noviembre';
                  break;
                case 12:
                  weekDay = 'Diciembre';
                  break;
              }
              return BarTooltipItem(weekDay + '\n' + (rod.y - 1).toString(), TextStyle(color: Color(0xffd81159)));
            }),
        touchCallback: (barTouchResponse) {
          setState(() {
            if (barTouchResponse.spot != null &&
                barTouchResponse.touchInput is! FlPanEnd &&
                barTouchResponse.touchInput is! FlLongPressEnd) {
              touchedIndex = barTouchResponse.spot.touchedBarGroupIndex;
            } else {
              touchedIndex = -1;
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(color: Color(0xff3d348b), fontWeight: FontWeight.bold, fontSize: 14),
          margin: 16,
          getTitles: (double value) {
            switch (value.toInt()) {
              case 0:
                return 'M';
              case 1:
                return 'T';
              case 2:
                return 'W';
              case 3:
                return 'T';
              case 4:
                return 'F';
              case 5:
                return 'S';
              case 6:
                return 'S';
              default:
                return '';
            }
          },
        ),
        leftTitles: SideTitles(
          showTitles: false,
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
    );
  }

  BarChartGroupData makeGroupData(int x, double y, {bool isTouched = false, Color barColor = const Color(0xff3d348b), double width = 22, List<int> showTooltips = const [],}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: isTouched ? y + 1 : y,
          color: isTouched ? Color(0xffd81159) : barColor,
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            y: 20,
            color: Color(0xffa8dadc),
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(12, (i) {
    switch (i) {
      case 0:
        return makeGroupData(12, 5, isTouched: i == touchedIndex);
      case 1:
        return makeGroupData(1, 6.5, isTouched: i == touchedIndex);
      case 2:
        return makeGroupData(2, 5, isTouched: i == touchedIndex);
      case 3:
        return makeGroupData(3, 7.5, isTouched: i == touchedIndex);
      case 4:
        return makeGroupData(4, 9, isTouched: i == touchedIndex);
      case 5:
        return makeGroupData(5, 11.5, isTouched: i == touchedIndex);
      case 6:
        return makeGroupData(6, 6.5, isTouched: i == touchedIndex);
      case 7:
        return makeGroupData(7, 6.5, isTouched: i == touchedIndex);
      case 8:
        return makeGroupData(8, 6.5, isTouched: i == touchedIndex);
      case 9:
        return makeGroupData(9, 6.5, isTouched: i == touchedIndex);
      case 10:
        return makeGroupData(10, 6.5, isTouched: i == touchedIndex);
      case 11:
        return makeGroupData(11, 6.5, isTouched: i == touchedIndex);
      default:
        return null;
    }
  });

}

class AnalizesBalancesMes extends StatefulWidget {
  @override
  _AnalizesBalancesMesState createState() => _AnalizesBalancesMesState();
}

class _AnalizesBalancesMesState extends State<AnalizesBalancesMes> {

  List<Map> listaMeses = new List();
  Map datosMes = {"cajadia1":"0","cajadiaultimo":"0","cajadebeterminar":"0","calledia1":"0","callediaultimo":"0","calledebeterminar":"0","prestadomes":"0","gastomes":"0","cobradomes":"0"};
  String mesSeleccionado = "";
  String anioSeleccionado = "";
  String mesSeleccionadoLetras = "";

  String datosinteres = "";
  String movimientoscajatodos = "";
  String movimientosdiatodos = "";

  bool visiblecaja = false;
  bool visibletodo = true;

  @override
  void initState() {
    this.leerMesesTodos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Container(
                height: 100,
                padding: EdgeInsets.only(top: 30,),
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: listaMeses == null ? 0 : listaMeses.length,
                    itemBuilder: (context,index){
                      if (listaMeses == null) {
                        return CircularProgressIndicator();
                      } else {
                        final item = listaMeses[index];
                        return InkWell(
                          onTap: (){
                            mesSeleccionado = item['mes'].toString();
                            anioSeleccionado = item['anio'].toString();
                            mesSeleccionadoLetras = getMesEnLetras(item['mes'].toString());
                            this.analizarMes();
                          },
                          child: SizedBox(
                            width: 140,
                            height: 50,
                            child: Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: Border.all(color: mesSeleccionado==item['mes']&&anioSeleccionado==item['anio']?Colores.secundario:Colores.primario),
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                              alignment: Alignment.center,
                              child: Text(" ${item['mesletras']} ${item['anio']}",style: TextStyle(fontWeight: FontWeight.bold,color: mesSeleccionado==item['mes']&&anioSeleccionado==item['anio']?Colores.secundario:Colores.primario),),
                            ),
                          ),
                        );
                      }
                    }),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Material(
                      elevation: 10,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text("Analizes $mesSeleccionadoLetras $anioSeleccionado",style: TextStyle(fontSize: 20),),
                            SizedBox(height: 30,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Caja empezo mes"),
                                Text("${datosMes['cajadia1']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Caja finalizo mes"),
                                Text("${datosMes['cajadiaultimo']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Caja debe finalizar mes"),
                                Text("${datosMes['cajadebeterminar']}"),
                              ],
                            ),
                            Divider(),
                            SizedBox(height: 20,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Calle inicio mes"),
                                Text("${datosMes['calledia1']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Calle finalizo mes"),
                                Text("${datosMes['callediaultimo']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Calle debe finalizar mes"),
                                Text("${datosMes['calledebeterminar']}"),
                              ],
                            ),
                            Divider(),
                            SizedBox(height: 20,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Cobrado en el mes"),
                                Text("${datosMes['cobradomes']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Prestado en el mes"),
                                Text("${datosMes['prestadomes']}"),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Gastos en el mes"),
                                Text("${datosMes['gastomes']}"),
                              ],
                            ),
                            Divider(),
                            SizedBox(height: 20,),
                            Text("Datos de interes del mes"),
                            Text("$datosinteres",style: TextStyle(fontSize: 10),),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40,),
                    Material(
                      elevation: 10,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FlatButton(
                                  onPressed: (){
                                    setState(() {
                                      visiblecaja = false;
                                      visibletodo = true;
                                    });
                                  },
                                  child: Text("Movimientos todo"),
                                ),
                                FlatButton(
                                  onPressed: (){
                                    setState(() {
                                      visiblecaja = true;
                                      visibletodo = false;
                                    });
                                  },
                                  child: Text("Movimientos caja"),
                                ),
                              ],
                            ),
                            Divider(),
                            Visibility(
                              visible: visibletodo,
                              child: Container(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  children: [
                                    Text("Movimientos del mes",style: TextStyle(color: Colores.secundario),),
                                    Text("$movimientosdiatodos",style: TextStyle(fontSize: 10),),
                                  ],
                                ),
                              ),
                            ),
                            Visibility(
                              visible: visiblecaja,
                              child: Container(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  children: [
                                    Text("Movimientos caja del mes",style: TextStyle(color: Colores.secundario),),
                                    Text("$movimientoscajatodos",style: TextStyle(fontSize: 10),),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40,),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Como se sacaraon los datos?",style: TextStyle(fontSize: 15),),
                          Text("-Se analizo cuanto empezo el dia uno y termino en balances el mes, en caja y calle (no se cuenta el cobrado, prestado y gastos del dia uno)",style: TextStyle(fontSize: 10),),
                          Text("-A la caja se le suma el cobrado en el mes, se resta gastos del mes, menos prestamos del mes ese resultado debe ser en caja sin editarla",style: TextStyle(fontSize: 10),),
                          Text("-Al dinero en la calle se le suma el prestado en el mes incluyendo interes y se le resta el cobrado en el mes, ese resultado debe ser sin editar clientes",style: TextStyle(fontSize: 10),),
                        ],
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map> leerMesesTodos()async{

    String fecha = fechaActual();
    List valor = fecha.split("/");
    mesSeleccionado = valor[1];
    anioSeleccionado = valor[2];
    mesSeleccionadoLetras = getMesEnLetras(mesSeleccionado);


    Database database = await opendb();
    List<Map> list = await database.rawQuery("SELECT * FROM balances ORDER BY anio DESC, mes DESC, dia ASC");
    await database.close();

    listaMeses = new List();

    String mesya = "";
    await Future.forEach(list, (balance) {

      String id = balance['id'].toString();
      String day = balance['dia'].toString();
      String mes = balance['mes'].toString();
      String anio = balance['anio'].toString();
      if(int.parse(mes)<10)mes = "0"+mes; //para ponerle el 0 al mes si es menor de 10

      if(mes!=mesya){
        listaMeses.add({"id":id,"mes":mes,"mesletras":getMesEnLetras(mes),"anio":anio});
        mesya = mes;
      }

    });

    this.analizarMes();
  }

  Future<void> analizarMes()async{

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE mes = $mesSeleccionado and anio = $anioSeleccionado ORDER BY dia');
    await database.close();

    int balancesmes = list.length;
    int recorrido = 0;

    double cajadia1 = 0, cajadiaultimo = 0;
    double calledia1 = 0, callediaultimo = 0;
    double prestadomes = 0;
    double cobromes = 0;
    double gastomes = 0;


    await list.forEach((balance) async {
      //id: 515, dia: 1, mes: 7, anio: 2020, cobrado: 1046000, capital: 0, interes: 0, ganancia: 0, dinerocalle: 50559060, clientesnuevos: 0,
      // numeroprestamos: 0, valorprestado: 50000, pagos: 29, mora: 0, impresiones: 0, compartidos: 0, editados: 0, gastos: 0, caja: 5158166.6466666,
      // movimientoscaja: *movimientos de la caja, movimientosdia: *movimientos del dia, liquidaciones:

      recorrido++;
      double caja = double.parse(balance['caja'].toString());
      double dinerocalle = double.parse(balance['dinerocalle'].toString());
      double valorprestado = double.parse(balance['valorprestado'].toString());
      double cobro = double.parse(balance['cobrado'].toString());
      double gastos = double.parse(balance['gastos'].toString());

      if(recorrido==1){
        cajadia1 = caja;
        calledia1 = dinerocalle;
      }else{
        prestadomes = prestadomes+valorprestado;
        cobromes = cobromes+cobro;
        gastomes = gastomes+gastos;
      }

      if(recorrido==balancesmes){
        cajadiaultimo = caja;
        callediaultimo = dinerocalle;
      }

    });

    //print("prestadomes $prestadomes gastosmes $gastomes cobromes $cobromes");

    double resultadocaja = cajadia1+cobromes-prestadomes-gastomes;
    double resultadocalle = calledia1+prestadomes-cobromes;

    datosMes = {"cajadia1":cajadia1,"cajadiaultimo":cajadiaultimo,"cajadebeterminar":resultadocaja,"calledia1":calledia1,"callediaultimo":callediaultimo,"calledebeterminar":resultadocalle,"prestadomes":prestadomes,"gastomes":gastomes,"cobradomes":cobromes};

    //print("calidad=> [$mesSeleccionadoLetras] cajadebehaber : $resultadocaja (hay $cajadiaultimo) calledebe haber $resultadocalle (hay $callediaultimo)");

    await analizarDatosMes();

    setState(() {

    });
  }

  Future<void> analizarDatosMes()async{

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances WHERE mes = $mesSeleccionado and anio = $anioSeleccionado ORDER BY dia');
    await database.close();

    datosinteres = "";
    movimientoscajatodos = "";
    movimientosdiatodos = "";
    String enter = "\n";

    await list.forEach((balance) async{

      String movimientosdia = balance['movimientosdia'];
      String movimientoscaja = balance['movimientoscaja'];

      String dia = balance['dia'].toString();

      movimientosdiatodos = movimientosdiatodos+enter+dia+enter+movimientosdia+enter;
      movimientoscajatodos = movimientoscajatodos+enter+dia+enter+movimientoscaja+enter;

      List movimient = movimientosdia.split("*");
      movimient.removeAt(0); //elimina un asterisco que no tiene nada
      await Future.forEach(movimient, (movi) {
        List datosdia = movi.split(" ");
        String movimiento = datosdia[0];
        if(movimiento=="clienteeditado"){
          String fecha = datosdia[1];
          String hora = datosdia[2];
          datosinteres = datosinteres + enter +"*$movimiento fecha $fecha hora $hora";
        }
        if(movimiento=="pagoborrado"){
          String fecha = datosdia[1];
          String hora = datosdia[2];
          datosinteres = datosinteres + enter +"*$movimiento fecha $fecha hora $hora";
        }
        //print("movi $movi");

      });

    });

  }

}




//ejemplo de graficas
class LineChartSample1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  bool isShowingMainData;

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.23,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          gradient: LinearGradient(
            colors: const [
              Color(0xff2c274c),
              Color(0xff46426c),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  height: 37,
                ),
                const Text(
                  'Movimientos 2020',
                  style: TextStyle(
                    color: Color(0xff827daa),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text('Cobro mensual', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center,),
                const SizedBox(
                  height: 37,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 6.0),
                    child: LineChart(
                      isShowingMainData ? sampleData1() : sampleData2(),
                      swapAnimationDuration: const Duration(milliseconds: 250),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.white.withOpacity(isShowingMainData ? 1.0 : 0.5),
              ),
              onPressed: () {
                setState(() {
                  isShowingMainData = !isShowingMainData;
                });
              },
            )
          ],
        ),
      ),
    );
  }

  LineChartData sampleData1() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: const TextStyle(color: Color(0xff72719b),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          margin: 10,
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'SEPT';
              case 7:
                return 'OCT';
              case 12:
                return 'DEC';
            }
            return '';
          },
        ),
        leftTitles: SideTitles(showTitles: true,
          textStyle: const TextStyle(color: Color(0xff75729e), fontWeight: FontWeight.bold, fontSize: 14,),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '1m';
              case 2:
                return '2m';
              case 3:
                return '3m';
              case 4:
                return '5m';
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
            width: 4,
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
      minX: 0,
      maxX: 14,
      maxY: 4,
      minY: 0,
      lineBarsData: linesBarData1(),
    );
  }

  List<LineChartBarData> linesBarData1() {
    final LineChartBarData lineChartBarData1 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 1.5),
        FlSpot(5, 1.4),
        FlSpot(7, 3.4),
        FlSpot(10, 2),
        FlSpot(12, 2.2),
        FlSpot(13, 1.8),
      ],
      isCurved: true,
      colors: [
        const Color(0xff4af699),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
    final LineChartBarData lineChartBarData2 = LineChartBarData(
      spots: [
        FlSpot(1, 1),
        FlSpot(3, 2.8),
        FlSpot(7, 1.2),
        FlSpot(10, 2.8),
        FlSpot(12, 2.6),
        FlSpot(13, 3.9),
      ],
      isCurved: true,
      colors: [
        const Color(0xffaa4cfc),
      ],
      barWidth: 8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(show: false, colors: [
        const Color(0x00aa4cfc),
      ]),
    );
    final LineChartBarData lineChartBarData3 = LineChartBarData(
      spots: [
        FlSpot(1, 2.8),
        FlSpot(3, 1.9),
        FlSpot(6, 3),
        FlSpot(10, 1.3),
        FlSpot(13, 2.5),
      ],
      isCurved: true,
      colors: const [
        Color(0xff27b6fc),
      ],
      barWidth: 8,
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
      lineChartBarData2,
      lineChartBarData3,
    ];
  }

  LineChartData sampleData2() {
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: false,
      ),
      gridData: FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: const TextStyle(
            color: Color(0xff72719b),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          margin: 10,
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'SEPT';
              case 7:
                return 'OCT';
              case 12:
                return 'DEC';
            }
            return '';
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          textStyle: const TextStyle(color: Color(0xff75729e), fontWeight: FontWeight.bold, fontSize: 14,),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '1m';
              case 2:
                return '2m';
              case 3:
                return '3m';
              case 4:
                return '5m';
              case 5:
                return '6m';
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
              width: 4,
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
          )),
      minX: 0,
      maxX: 14,
      maxY: 6,
      minY: 0,
      lineBarsData: linesBarData2(),
    );
  }

  List<LineChartBarData> linesBarData2() {
    return [
      LineChartBarData(
        spots: [
          FlSpot(1, 1),
          FlSpot(3, 4),
          FlSpot(5, 1.8),
          FlSpot(7, 5),
          FlSpot(10, 2),
          FlSpot(12, 2.2),
          FlSpot(13, 1.8),
        ],
        isCurved: true,
        curveSmoothness: 0,
        colors: const [
          Color(0x444af699),
        ],
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: false,
        ),
      ),
      LineChartBarData(
        spots: [
          FlSpot(1, 1),
          FlSpot(3, 2.8),
          FlSpot(7, 1.2),
          FlSpot(10, 2.8),
          FlSpot(12, 2.6),
          FlSpot(13, 3.9),
        ],
        isCurved: true,
        colors: const [
          Color(0x99aa4cfc),
        ],
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(show: true, colors: [
          const Color(0x33aa4cfc),
        ]),
      ),
      LineChartBarData(
        spots: [
          FlSpot(1, 3.8),
          FlSpot(3, 1.9),
          FlSpot(6, 5),
          FlSpot(10, 3.3),
          FlSpot(13, 4.5),
        ],
        isCurved: true,
        curveSmoothness: 0,
        colors: const [
          Color(0x4427b6fc),
        ],
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: false,
        ),
      ),
    ];
  }
}

class BarChartSample2 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => BarChartSample2State();
}

class BarChartSample2State extends State<BarChartSample2> {
  final Color leftBarColor = const Color(0xff53fdd7);
  final Color rightBarColor = const Color(0xffff5182);
  final double width = 7;

  List<BarChartGroupData> rawBarGroups;
  List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex;

  @override
  void initState() {
    super.initState();
    final barGroup1 = makeGroupData(0, 5, 12);
    final barGroup2 = makeGroupData(1, 16, 12);
    final barGroup3 = makeGroupData(2, 18, 5);
    final barGroup4 = makeGroupData(3, 20, 16);
    final barGroup5 = makeGroupData(4, 17, 6);
    final barGroup6 = makeGroupData(5, 19, 1.5);
    final barGroup7 = makeGroupData(6, 10, 1.5);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  makeTransactionsIcon(),
                  const SizedBox(
                    width: 38,
                  ),
                  const Text(
                    'Transactions',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Text(
                    'state',
                    style: TextStyle(color: Color(0xff77839a), fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(
                height: 38,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: BarChart(
                    BarChartData(
                      maxY: 20,
                      barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.grey,
                            getTooltipItem: (_a, _b, _c, _d) => null,
                          ),
                          touchCallback: (response) {
                            if (response.spot == null) {
                              setState(() {
                                touchedGroupIndex = -1;
                                showingBarGroups = List.of(rawBarGroups);
                              });
                              return;
                            }

                            touchedGroupIndex = response.spot.touchedBarGroupIndex;

                            setState(() {
                              if (response.touchInput is FlLongPressEnd ||
                                  response.touchInput is FlPanEnd) {
                                touchedGroupIndex = -1;
                                showingBarGroups = List.of(rawBarGroups);
                              } else {
                                showingBarGroups = List.of(rawBarGroups);
                                if (touchedGroupIndex != -1) {
                                  double sum = 0;
                                  for (BarChartRodData rod
                                  in showingBarGroups[touchedGroupIndex].barRods) {
                                    sum += rod.y;
                                  }
                                  final avg =
                                      sum / showingBarGroups[touchedGroupIndex].barRods.length;

                                  showingBarGroups[touchedGroupIndex] =
                                      showingBarGroups[touchedGroupIndex].copyWith(
                                        barRods: showingBarGroups[touchedGroupIndex].barRods.map((rod) {
                                          return rod.copyWith(y: avg);
                                        }).toList(),
                                      );
                                }
                              }
                            });
                          }),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: SideTitles(
                          showTitles: true,
                          textStyle: TextStyle(
                              color: const Color(0xff7589a2),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          margin: 20,
                          getTitles: (double value) {
                            switch (value.toInt()) {
                              case 0:
                                return 'Mn';
                              case 1:
                                return 'Te';
                              case 2:
                                return 'Wd';
                              case 3:
                                return 'Tu';
                              case 4:
                                return 'Fr';
                              case 5:
                                return 'St';
                              case 6:
                                return 'Sn';
                              default:
                                return '';
                            }
                          },
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          textStyle: TextStyle(
                              color: const Color(0xff7589a2),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          margin: 32,
                          reservedSize: 14,
                          getTitles: (value) {
                            if (value == 0) {
                              return '1K';
                            } else if (value == 10) {
                              return '5K';
                            } else if (value == 19) {
                              return '10K';
                            } else {
                              return '';
                            }
                          },
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: showingBarGroups,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(barsSpace: 4, x: x, barRods: [
      BarChartRodData(
        y: y1,
        color: leftBarColor,
        width: width,
      ),
      BarChartRodData(
        y: y2,
        color: rightBarColor,
        width: width,
      ),
    ]);
  }

  Widget makeTransactionsIcon() {
    const double width = 4.5;
    const double space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}

class ScatterChartSample2 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScatterChartSample2State();
}

class _ScatterChartSample2State extends State {
  int touchedIndex;

  Color greyColor = Colors.grey;

  List<int> selectedSpots = [];

  int lastPanStartOnIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        color: const Color(0xff222222),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: [
              ScatterSpot(
                4,
                4,
                color: selectedSpots.contains(0) ? Colors.green : greyColor,
              ),
              ScatterSpot(
                2,
                5,
                color: selectedSpots.contains(1) ? Colors.yellow : greyColor,
                radius: 12,
              ),
              ScatterSpot(
                4,
                5,
                color: selectedSpots.contains(2) ? Colors.purpleAccent : greyColor,
                radius: 8,
              ),
              ScatterSpot(
                8,
                6,
                color: selectedSpots.contains(3) ? Colors.orange : greyColor,
                radius: 20,
              ),
              ScatterSpot(
                5,
                7,
                color: selectedSpots.contains(4) ? Colors.brown : greyColor,
                radius: 14,
              ),
              ScatterSpot(
                7,
                2,
                color: selectedSpots.contains(5) ? Colors.lightGreenAccent : greyColor,
                radius: 18,
              ),
              ScatterSpot(
                3,
                2,
                color: selectedSpots.contains(6) ? Colors.red : greyColor,
                radius: 36,
              ),
              ScatterSpot(
                2,
                8,
                color: selectedSpots.contains(7) ? Colors.tealAccent : greyColor,
                radius: 22,
              ),
            ],
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 10,
            borderData: FlBorderData(
              show: false,
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              checkToShowHorizontalLine: (value) => true,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1)),
              drawVerticalLine: true,
              checkToShowVerticalLine: (value) => true,
              getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1)),
            ),
            titlesData: FlTitlesData(
              show: false,
            ),
            showingTooltipIndicators: selectedSpots,
            scatterTouchData: ScatterTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchTooltipData: ScatterTouchTooltipData(
                tooltipBgColor: Colors.black,
              ),
              touchCallback: (ScatterTouchResponse touchResponse) {
                if (touchResponse.touchInput is FlPanStart) {
                  lastPanStartOnIndex = touchResponse.touchedSpotIndex;
                } else if (touchResponse.touchInput is FlPanEnd) {
                  final FlPanEnd flPanEnd = touchResponse.touchInput;

                  if (flPanEnd.velocity.pixelsPerSecond <= const Offset(4, 4)) {
                    // Tap happened
                    setState(() {
                      if (selectedSpots.contains(lastPanStartOnIndex)) {
                        selectedSpots.remove(lastPanStartOnIndex);
                      } else {
                        selectedSpots.add(lastPanStartOnIndex);
                      }
                    });
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BarChartSample1 extends StatefulWidget {
  final List<Color> availableColors = [
    Colors.purpleAccent,
    Colors.yellow,
    Colors.lightBlue,
    Colors.orange,
    Colors.pink,
    Colors.redAccent,
  ];

  @override
  State<StatefulWidget> createState() => BarChartSample1State();
}

class BarChartSample1State extends State<BarChartSample1> {
  final Color barBackgroundColor = const Color(0xff72d8bf);
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex;

  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: const Color(0xff81e5cd),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text(
                    'Mingguan',
                    style: TextStyle(
                        color: const Color(0xff0f4a3c), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Grafik konsumsi kalori',
                    style: TextStyle(
                        color: const Color(0xff379982), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 38,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: BarChart(
                        isPlaying ? randomData() : mainBarData(),
                        swapAnimationDuration: animDuration,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xff0f4a3c),
                  ),
                  onPressed: () {
                    setState(() {
                      isPlaying = !isPlaying;
                      if (isPlaying) {
                        refreshState();
                      }
                    });
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(
      int x,
      double y, {
        bool isTouched = false,
        Color barColor = Colors.white,
        double width = 22,
        List<int> showTooltips = const [],
      }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          y: isTouched ? y + 1 : y,
          color: isTouched ? Colors.yellow : barColor,
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            y: 20,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
    switch (i) {
      case 0:
        return makeGroupData(0, 5, isTouched: i == touchedIndex);
      case 1:
        return makeGroupData(1, 6.5, isTouched: i == touchedIndex);
      case 2:
        return makeGroupData(2, 5, isTouched: i == touchedIndex);
      case 3:
        return makeGroupData(3, 7.5, isTouched: i == touchedIndex);
      case 4:
        return makeGroupData(4, 9, isTouched: i == touchedIndex);
      case 5:
        return makeGroupData(5, 11.5, isTouched: i == touchedIndex);
      case 6:
        return makeGroupData(6, 6.5, isTouched: i == touchedIndex);
      default:
        return null;
    }
  });

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String weekDay;
              switch (group.x.toInt()) {
                case 0:
                  weekDay = 'Monday';
                  break;
                case 1:
                  weekDay = 'Tuesday';
                  break;
                case 2:
                  weekDay = 'Wednesday';
                  break;
                case 3:
                  weekDay = 'Thursday';
                  break;
                case 4:
                  weekDay = 'Friday';
                  break;
                case 5:
                  weekDay = 'Saturday';
                  break;
                case 6:
                  weekDay = 'Sunday';
                  break;
              }
              return BarTooltipItem(
                  weekDay + '\n' + (rod.y - 1).toString(), TextStyle(color: Colors.yellow));
            }),
        touchCallback: (barTouchResponse) {
          setState(() {
            if (barTouchResponse.spot != null &&
                barTouchResponse.touchInput is! FlPanEnd &&
                barTouchResponse.touchInput is! FlLongPressEnd) {
              touchedIndex = barTouchResponse.spot.touchedBarGroupIndex;
            } else {
              touchedIndex = -1;
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          margin: 16,
          getTitles: (double value) {
            switch (value.toInt()) {
              case 0:
                return 'M';
              case 1:
                return 'T';
              case 2:
                return 'W';
              case 3:
                return 'T';
              case 4:
                return 'F';
              case 5:
                return 'S';
              case 6:
                return 'S';
              default:
                return '';
            }
          },
        ),
        leftTitles: SideTitles(
          showTitles: false,
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
    );
  }

  BarChartData randomData() {
    return BarChartData(
      barTouchData: BarTouchData(
        enabled: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          margin: 16,
          getTitles: (double value) {
            switch (value.toInt()) {
              case 0:
                return 'M';
              case 1:
                return 'T';
              case 2:
                return 'W';
              case 3:
                return 'T';
              case 4:
                return 'F';
              case 5:
                return 'S';
              case 6:
                return 'S';
              default:
                return '';
            }
          },
        ),
        leftTitles: SideTitles(
          showTitles: false,
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: List.generate(7, (i) {
        switch (i) {
          case 0:
            return makeGroupData(0, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 1:
            return makeGroupData(1, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 2:
            return makeGroupData(2, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 3:
            return makeGroupData(3, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 4:
            return makeGroupData(4, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 5:
            return makeGroupData(5, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          case 6:
            return makeGroupData(6, Random().nextInt(15).toDouble() + 6,
                barColor: widget.availableColors[Random().nextInt(widget.availableColors.length)]);
          default:
            return null;
        }
      }),
    );
  }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(animDuration + const Duration(milliseconds: 50));
    if (isPlaying) {
      refreshState();
    }
  }
}


