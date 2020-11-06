import 'package:flutter/material.dart';
import 'package:prestagroons/php/meTodo.dart';
import 'package:prestagroons/php/Ajustes.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:focus_detector/focus_detector.dart';

var baseurl = getUrlServer();

class inicio extends StatelessWidget {
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
        body: SingleChildScrollView(
          child: Container(
            child: menu(),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 8.0,
          shape: CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _botonAcion(Icons.history, context, historial()),
              _botonAcion(Icons.insert_chart, context, balances()),
              Divider(),
              Divider(),
              _botonAcion(Icons.attach_money, context, gastos()),
              _botonAcion(Icons.settings, context, ajustes()),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => negocio()));
          },
          child: Icon(Icons.chrome_reader_mode),
        ),
      ),
    );
  }

  Widget _botonAcion(IconData icon, BuildContext context, funcion) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => funcion));
      },
      child: Container(
        padding: EdgeInsets.all(20),
        child: Icon(icon),
      ),
    );
  }
}

class menu extends StatefulWidget {
  @override
  _menuState createState() => _menuState();
}

class _menuState extends State<menu> with WidgetsBindingObserver {

  final _resumeDetectorKey = UniqueKey();
  String empresa = "";
  String ventas = '0.00';
  List<Map> items;

  Future<List<Map>> Recibir() async {
    var response = await ResumMes();
    String empre = await getLocal("empresa");
    setState(() {
      items = response;
      ventas = response[0]['vendido'];
      empresa = empre;
      //print("termino $items");
    });
  }

  @override
  void initState() {
    this.Recibir();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("estado: $state");
    if(state == AppLifecycleState.resumed){
      print("Usuario devuelta a nuestra aplicación");
    }else if(state == AppLifecycleState.inactive){
      print("la aplicación está inactiva");
    }else if(state == AppLifecycleState.paused){
      print("el usuario está a punto de salir de nuestra aplicación temporalmente");
    }else if(state == AppLifecycleState.detached){
      print("serparado");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: FocusDetector(
          key: _resumeDetectorKey,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            cabezera(),
            Divider(
              color: Colors.white,
              height: 10,
            ),
            centro(),
            OutlineButton(
              onPressed: (){
                this.Recibir();
              },
              child: Text("Actualizar"),
            ),
          ],
        ),
          onFocusGained: (){
            print("Foco widget volvio");
            empresaSeleciona();
          },
          onFocusLost: (){
            print("Foco widget salio");
          },
        )
      ),
    );
  }

  void empresaSeleciona() async{
    String idempresa = await getLocal("idempresa");
    if(idempresa=="_"||idempresa==""){
      Navigator.push(this.context, MaterialPageRoute(builder: (context) => descargarcopias()));
    }
  }

  Widget cabezera() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: Text(
              empresa,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.blueAccent),
            ),
          ),
          Divider(color: Colors.white,),
          Container(
            alignment: Alignment.center,
            child: Text(
              ventas,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold,color: Colors.blueGrey),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              "Ventas ultimo mes",
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget centro() {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: ListView.builder(
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
          ),
        ],
      ),
    );
  }

  Widget _buildItem(item) {
    IconData icon = Icons.add;
    String posit = item['posit'];
    //print("item: $item");
    String nombre = "nada";
    String valor = "0.00";
    if (posit == "0") {
      icon = Icons.attach_money;
      valor = item['caja'];
      nombre = "Caja";
    } else if (posit == "1") {
      icon = Icons.shopping_cart;
      valor = item['gastos'];
      nombre = "Gastos";
    } else if (posit == "2") {
      icon = Icons.add_shopping_cart;
      valor = item['comision'];
      nombre = "Comision";
    } else if (posit == "3") {
      icon = Icons.supervised_user_circle;
      valor = item['clientes'];
      nombre = "Clientes atendidos";
    }

    return InkWell(
      onTap: () {},
      child: ListTile(
        title: new Text(nombre,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        subtitle: new Text(
          '$nombre durante el ultimo mes',
          style: TextStyle(fontSize: 12),
        ),
        leading: new Icon(icon),
        trailing: Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            valor,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<List<Map>> ResumMes() async {

    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances');
    await database.close();

    List<Map> mlista = new List();
    double vendido = 0;
    double gastos = 0;
    double comision = 0;
    int clientes = 0;

    if (list.length > 0) {
      list.forEach((row) {
        int id = row['id'];
        String fecha = row['fecha'];
        String vendid = row['vendido'];
        String gasto = row['gastos'];
        String comisio = row['comision'];
        String caj = row['caja'];
        String cliente = row['clientes'];
        //print('linea: $row');

        List<String> fec = fecha.split("/"); //fecha.substring(3,5);
        String dia = fec[0];
        String mes = fec[1];
        String anio = fec[2];

        //print("mes $mes fechaactual: ${fechaActual()}");
        if (mes == mesActual()) {
          vendido = vendido + double.parse(vendid);
          gastos = gastos + double.parse(gasto);
          comision = comision + double.parse(comisio);
          clientes = clientes + int.parse(cliente);
        }
      });
      String caja = await cajaActual();
      for (int i = 0; i < 4; i++) {
        mlista.add({
          "posit": i.toString(),
          "caja": caja,
          "vendido": vendido.toString(),
          "gastos": gastos.toString(),
          "comision": comision.toString(),
          "clientes": clientes.toString(),
        });
      }
    }else{
      String caja = await cajaActual();
      for (int i = 0; i < 4; i++) {
        mlista.add({
          "posit": i.toString(),
          "caja": caja,
          "vendido": "0.00",
          "gastos": "0.00",
          "comision": "0.00",
          "clientes": "0.00",
        });
      }
    }

    return mlista;
  }

  Widget selector() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.0),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.all(15),
            width: 120.0,
            child: Text(
              "Enero",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.all(15),
            width: 120.0,
            child: Text(
              "Febrero",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.all(15),
            width: 120.0,
            child: Text(
              "Marzo",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.all(15),
            width: 120.0,
            child: Text(
              "Abril",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          InkWell(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.all(15),
              width: 120.0,
              child: Text(
                "Mayo",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class historial extends StatefulWidget {
  @override
  _historialState createState() => _historialState();
}

class _historialState extends State<historial> {

  List<Balance> users;
  List<Balance> selectedUsers;
  bool sort;

  Future<List<Balance>> Recibir() async {
    var response = await getBalances();
    setState(() {
      users = response;
    });
  }

  @override
  void initState() {
    sort = true;
    selectedUsers = [];
    users = Balance.getBalances();
    this.Recibir();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Historial"),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: tabla(),
              ),
            ),
            OutlineButton(
              onPressed: (){
                this.Recibir();
              },
              child: Text("Actualizar"),
            ),
          ],
        ));
  }

  SingleChildScrollView tabla() {
    return SingleChildScrollView(
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
            label: Text("Vendido"),
            numeric: false,
            tooltip: "Total vendido",
          ),
          DataColumn(
            label: Text("Gastos"),
            numeric: false,
            tooltip: "Total gastos",
          ),
          DataColumn(
            label: Text("Comision"),
            numeric: false,
            tooltip: "Comision pagada",
          ),
          DataColumn(
            label: Text("Caja"),
            numeric: false,
            tooltip: "Valor caja finalizo dia",
          ),
          DataColumn(
            label: Text("Clientes"),
            numeric: false,
            tooltip: "Clientes atendidos",
          ),
        ],
        rows: users == null ? Balance.getBalances() : users.map(
              (user) => DataRow(
              cells: [
                DataCell(
                  Text(user.fecha),
                  onTap: () {
                    print('Selected ${user.fecha}');
                  },
                ),
                DataCell(
                  Text(user.vendido),
                ),
                DataCell(
                  Text(user.gastos),
                ),
                DataCell(
                  Text(user.comision),
                ),
                DataCell(
                  Text(user.caja),
                ),
                DataCell(
                  Text(user.clientes),
                ),
              ]),
        )
            .toList(),
      ),
    );
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (ascending) {
        users.sort((a, b) => a.fecha.compareTo(b.fecha));
      } else {
        users.sort((a, b) => b.fecha.compareTo(a.fecha));
      }
    }
  }

  Future<List<Balance>> getBalances() async {
    Database database = await opendb();
    List<Map> list = await database.rawQuery('SELECT * FROM balances');
    await database.close();

    List<Balance> lista = new List();

    if (list.length > 0) {
      list.forEach((row) {
        int id = row['id'];
        String fecha = row['fecha'];
        String vendid = row['vendido'];
        String gasto = row['gastos'];
        String comisio = row['comision'];
        String caja = row['caja'];
        String cliente = row['clientes'];
        print('_getHistorialState getBalances(): $row');

        lista.add(Balance(fecha: fecha,vendido: vendid,gastos: gasto,comision: comisio,caja: caja,clientes: cliente));
      });
    }

    return lista;
  }
}

class Balance {
  String fecha;
  String vendido;
  String gastos;
  String comision;
  String caja;
  String clientes;

  Balance({this.fecha, this.vendido,this.gastos,this.comision,this.caja,this.clientes});

  static List<Balance> getBalances() {

    return <Balance>[
      Balance(fecha: fechaActual(), vendido: "0.00",gastos: "0.00",comision: "0.00",caja: "0.00",clientes: "0"),
    ];
  }
}

class balances extends StatefulWidget {
  @override
  _balancesState createState() => _balancesState();
}

class _balancesState extends State<balances> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Balances"),),
      body: Column(
        children: <Widget>[

        ],
      ),
    );
  }
}

class negocio extends StatefulWidget {
  @override
  _negocioState createState() => _negocioState();
}

class _negocioState extends State<negocio> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Negocio"),),
      body: Column(
        children: <Widget>[

        ],
      ),
    );
  }
}

class gastos extends StatefulWidget {
  @override
  _gastosState createState() => _gastosState();
}

class _gastosState extends State<gastos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gastos"),),
      body: Column(
        children: <Widget>[

        ],
      ),
    );
  }
}




//codigo wjemplo

leerDB() async{

  Database database = await opendb();
  List<Map> list = await database.rawQuery('SELECT * FROM scaner');
  await database.close();

  List<Balance> lista = new List();

  if (list.length > 0) {
    list.forEach((row) {
      int id = row['id'];
      String fecha = row['fecha'];
      String vendid = row['vendido'];
      String gasto = row['gastos'];
      String comisio = row['comision'];
      String caja = row['caja'];
      String cliente = row['clientes'];
      print(' leerGastos(): $row');

    });
  }

}

class listahorizontal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'Horizontal List';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(
          margin: EdgeInsets.symmetric(vertical: 20.0),
          height: 200.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Container(
                width: 160.0,
                color: Colors.red,
              ),
              Container(
                width: 160.0,
                color: Colors.blue,
              ),
              Container(
                width: 160.0,
                color: Colors.green,
              ),
              Container(
                width: 160.0,
                color: Colors.yellow,
              ),
              Container(
                width: 160.0,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class User {
  String firstName;
  String lastName;

  User({this.firstName, this.lastName});

  static List<User> getUsers() {
    return <User>[
      User(firstName: "Aaryan", lastName: "Shah"),
      User(firstName: "Ben", lastName: "John"),
      User(firstName: "Carrie", lastName: "Brown"),
      User(firstName: "Deep", lastName: "Sen"),
      User(firstName: "Emily", lastName: "Jane"),
    ];
  }
}
class DataTableDemo extends StatefulWidget {
  DataTableDemo() : super();

  final String title = "Data Table Flutter Demo";

  @override
  DataTableDemoState createState() => DataTableDemoState();
}

class DataTableDemoState extends State<DataTableDemo> {
  List<User> users;
  List<User> selectedUsers;
  bool sort;

  @override
  void initState() {
    sort = false;
    selectedUsers = [];
    users = User.getUsers();
    super.initState();
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (ascending) {
        users.sort((a, b) => a.firstName.compareTo(b.firstName));
      } else {
        users.sort((a, b) => b.firstName.compareTo(a.firstName));
      }
    }
  }

  onSelectedRow(bool selected, User user) async {
    setState(() {
      if (selected) {
        selectedUsers.add(user);
      } else {
        selectedUsers.remove(user);
      }
    });
  }

  deleteSelected() async {
    setState(() {
      if (selectedUsers.isNotEmpty) {
        List<User> temp = [];
        temp.addAll(selectedUsers);
        for (User user in temp) {
          users.remove(user);
          selectedUsers.remove(user);
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
              label: Text("FIRST NAME"),
              numeric: false,
              tooltip: "This is First Name",
              onSort: (columnIndex, ascending) {
                setState(() {
                  sort = !sort;
                });
                onSortColum(columnIndex, ascending);
              }),
          DataColumn(
            label: Text("LAST NAME"),
            numeric: false,
            tooltip: "This is Last Name",
          ),
        ],
        rows: users
            .map(
              (user) => DataRow(
              selected: selectedUsers.contains(user),
              onSelectChanged: (b) {
                print("Onselect");
                onSelectedRow(b, user);
              },
              cells: [
                DataCell(
                  Text(user.firstName),
                  onTap: () {
                    print('Selected ${user.firstName}');
                  },
                ),
                DataCell(
                  Text(user.lastName),
                ),
              ]),
        )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Expanded(
            child: dataBody(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(20.0),
                child: OutlineButton(
                  child: Text('SELECTED ${selectedUsers.length}'),
                  onPressed: () {},
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: OutlineButton(
                  child: Text('DELETE SELECTED'),
                  onPressed: selectedUsers.isEmpty
                      ? null
                      : () {
                    deleteSelected();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
