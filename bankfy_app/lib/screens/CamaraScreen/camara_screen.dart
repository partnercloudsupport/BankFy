import 'package:bankfyapp/models/user.dart';
import 'package:bankfyapp/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:bankfyapp/services/auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:bankfyapp/utilities/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

class CamaraScreen extends StatefulWidget {
  @override
  _CamaraScreen createState() => new _CamaraScreen();
}

class _CamaraScreen extends State<CamaraScreen> {
  final AuthService _auth = AuthService();
  final textoMontoTotalImagen = TextEditingController();
  File _image;
  String _textImage = "Tomar foto o ingresar monto";
  double counter = 0.00;
  String dropdownValue = 'Comida';
  
  // Widget que define el componente del input del presupuesto inicial del periodo
  Widget _buildMontoTotalFacturaTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Monto total factura',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationWhiteStyle,
          height: 60.0,
          child: TextFormField(
            validator: (value) {
              if (value.isEmpty) {
                return 'Ingrese el monto total correspondiente a su factura';
              }
              else if (!isNumeric(value)) {
                return 'Ingrese un monto numérico';
              }
              return null;
            },
            controller: textoMontoTotalImagen,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'OpenSans'
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              errorStyle: TextStyle(
                fontSize: 10.0,
              ),
              prefixIcon: Icon(
                Icons.attach_money,
                color: Colors.black,
              ),
              hintText: 'Tome una foto de la factura',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _image = image;
    });

    double maximo = 0.00;

    FirebaseVisionImage receipt = FirebaseVisionImage.fromFile(_image);
    TextRecognizer getText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await getText.processImage(receipt);

    var lst = new List();

    for (TextBlock block in readText.blocks){
      for (TextLine line in block.lines){
        for (TextElement word in line.elements){
          if (word.text.contains(".")) {
            if (isNumeric(word.text)) {

              lst.add(double.parse(word.text));

              if (double.parse(word.text) > maximo) {
                maximo = double.parse(word.text);
                setState(() {
                  counter = maximo;
                  //_textImage = counter.toString();
                });
              }
            }
          }
        }
      }
    }

    for (var i = 0; i < lst.length; i++){
      if (lst[i] == maximo && (i+1)<lst.length){
        setState(() {
          counter = lst[i] - lst[i+1];
          textoMontoTotalImagen.text = counter.toString();
        });
      }
    }

    print(lst);

  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    void _showSettingsPanel() {
      showModalBottomSheet(context: context, builder: (context) { 
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
          child: FlatButton.icon(
            icon: Icon(Icons.person),
            label: Text('Salir'),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
              //Navigator.pop(context);
            },
          ), 
        );
      });
    }

    return StreamProvider<QuerySnapshot>.value(
      value: DatabaseService().gastos,
        child: Scaffold(
        backgroundColor: Colors.green[50],
        appBar: AppBar(
          title: Text(
            'Ingreso de gasto - OCR',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          backgroundColor: Color(0xFF149414),
          elevation: 0.0,
          actions: <Widget>[
            FlatButton.icon(
              icon: Icon(Icons.settings),
              padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
              label: Text(''),
              onPressed: () => _showSettingsPanel(),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Container(
              height: double.infinity,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 50.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    //Text("Total: " + _textImage),
                    _buildMontoTotalFacturaTF(),
                    // TextField(
                    //   obscureText: false,
                    //   textAlign: TextAlign.center,
                    //   decoration: InputDecoration(
                    //     border: OutlineInputBorder(),
                    //     labelText: _textImage,
                    //   ),
                    // ),
                    SizedBox(height: 30.0),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                        RaisedButton(
                          onPressed: getImage,
                          child: Text("Tomar Foto"),
                          color: Colors.green[500],
                        ),
                        Text("  "),
                        RaisedButton(
                          onPressed: getImage,
                          child: Text("Agregar"),
                          color: Colors.green[500],
                        ),
                      ],)
                    ),
                    DropdownButton<String>(
                      value: dropdownValue,
                      icon: Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(
                        color: Colors.green[900]
                      ),
                      underline: Container(
                        height: 2,
                        color: Colors.green[800],
                      ),
                      onChanged: (String newValue){
                        setState(() {
                          dropdownValue = newValue;
                        });
                      },
                      items: <String> ['Comida', 'Trabajo', 'Estudios', 'Otros']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                          );
                      })
                      .toList(),
                    ),
                    Align(
                      child: _image == null
                        ? new Text("")
                        : new Image.file(_image)
                    ),
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