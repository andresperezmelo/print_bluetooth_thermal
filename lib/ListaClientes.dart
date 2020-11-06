import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:prestagroons/Clientes.dart';
import 'package:prestagroons/meTodo.dart';
import 'package:sqflite/sqflite.dart';

class ListaClientes extends StatefulWidget {
  @override
  _ListaClientesState createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {

  List<Map> listaClientes = new List();
  String msj = "";

  @override
  void initState() {
    this.getClientes();
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
                  itemCount: listaClientes == null ? 0 : listaClientes.length,
                  itemBuilder: (context,index){
                    if (listaClientes.length == 0) {
                      return CircularProgressIndicator();
                    } else {
                      final item = listaClientes[index];
                      //print("diashoy $diahoy itemdia ${item['dia']}");
                      return ListTile(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>HacerPagos(item['key'],item['nombre'])));
                        },
                        title: Text("${item['nombre']} "),
                        subtitle: Text("${item['direccion']}"),
                        leading: Text("${item['prestamos']}"),
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

  void getClientes()async{

    Database database = await opendb();
    List<Map> clientes = await database.rawQuery("SELECT * FROM clientes ORDER BY grupo ASC");
    await database.close();

    //id: 39, key: b4b35650-ef9c-11ea-90fc-8371f1ce7f62, nombre: JAIRO RICHARD  SARMIENTO, cedula: 17338932, direccion: Floristeria centro, telefono: 3124648717, posicion: 7, grupo: Centro, cupo: no
    //print("clientes ${clientes[0]['grupo']}");
    int recorrido = 0;
    List<Map> lista = new List();

    await Future.forEach(clientes, (cliente) async {

      String id = cliente['id'].toString();
      String key = cliente['key'].toString();
      String nombre = cliente['nombre'].toString();
      String direccion = cliente['direccion'].toString();
      Database database = await opendb();
      List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=? AND capital>'0'",[key]);
      await database.close();
      int hayprestamos = prestamos.length;

      lista.add({"id":id,"key":key,"nombre":nombre,"direccion":direccion,"prestamos":hayprestamos.toString()});

      recorrido++;

      setState(() {
        msj = "Cliente: $recorrido $nombre";
      });

    });

    print("finalizo");

    setState(() {
      listaClientes = lista;
      msj = "Clientes $recorrido";
    });


  }

  dialogEliminar(Map item)async{

    var baseDialog = BaseAlertDialog(
      title: Text("ELIMINAR CLIENTE",style: TextStyle(color: Colors.red),),
      content: Text("Se eliminaran los prestamos y el cliente",style: TextStyle(color: Colors.white),),
      fondoColor: Color.fromRGBO(66, 73, 73, 0.9),
      yes: Text("ELIMINAR",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),),
      yesOnPressed: ()async {
        Navigator.pop(context);
        this.eliminarCliente(item);
      },
      no: Text("Cancelar"),
      noOnPressed: () {
        Navigator.pop(context);
      },
    );
    showDialog(context: context, builder: (BuildContext context) => baseDialog);

  }

  void eliminarCliente(Map item)async{

    String idcliente = item['id'].toString();
    String key = item['key'].toString();
    String nombre = item['nombre'];

    Database database = await opendb();
    List<Map> prestamos = await database.rawQuery("SELECT * FROM prestamos WHERE pertenece=?",[key]);
    await database.close();

    //print("id: $idcliente prestamos: ${prestamos.length}");

    await prestamos.forEach((element) async{

      String idprestamo = element['id'].toString();

      Database database = await opendb();
      int count = await database.rawDelete('DELETE FROM prestamos WHERE id = ?', [idprestamo]);
      await database.close();

      print("idprestamo $idprestamo elimino: $count");

    });

    Database database1 = await opendb();
    int count = await database1.rawDelete('DELETE FROM clientes WHERE id = ?', [idcliente]);
    await database1.close();

    //print("idcliente $idcliente elimino: $count");

    setState(() {
      listaClientes.remove(item);
    });

    Flushbar(message: "Cliente eliminado $nombre",duration: Duration(seconds: 4),backgroundColor: Colors.red,).show(context);

  }

}
