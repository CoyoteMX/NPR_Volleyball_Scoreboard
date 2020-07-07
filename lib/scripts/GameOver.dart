import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'scoreboard.dart';

class GameOver extends StatefulWidget {

  Team _team1;
  Team _team2;
  Team _winner;
  Map<String, int> setsWinner;
  int numberOfSets;

  GameOver(this._team1, this._team2, this._winner, this.setsWinner, this.numberOfSets);

  @override
  State createState() => GameOverState();
}

class GameOverState extends State<GameOver>{

  Route _animatedRoute(Widget wid) {
    return PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => wid,
        transitionsBuilder: (context, animation, secondaryAnimation, child){

          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }
    );
  }

  Color primaryColor = Color(0xFF679267);

  @override
  Widget build(BuildContext context) {
    Team _team1 = widget._team1;
    Team _team2 = widget._team2;
    Map<String, int> setsWinner = widget.setsWinner;
    int numberOfSets = widget.numberOfSets;
    Team _winner = widget._winner;

    GlobalKey _globalKey = new GlobalKey();

    Future<Uint8List> _capturePng() async{
      try {
        RenderRepaintBoundary boundary = _globalKey.currentContext.findRenderObject();
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        var pngBytes = byteData.buffer.asUint8List();
        var bs64 = base64Encode(pngBytes);
        await Share.file('Marcador', 'marcador.png', pngBytes, 'image/png');
        return pngBytes;
      }catch(e){
        print(e);
      }
    }

    Widget setBoard(int set){
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text("Set $set", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: setsWinner[set.toString()] == 1 ? _team1.color : Colors.transparent,
            ),
            child: Text(
              _team1.score[set.toString()].toString(),
              style: TextStyle(
                fontSize: 15,
                color: setsWinner[set.toString()] == 1 ? _team1.color.computeLuminance() > 0.5 ? Colors.black: Colors.white : Colors.black,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: setsWinner[set.toString()] == 2 ? _team2.color : Colors.transparent,
            ),
            child: Text(
              _team2.score[set.toString()].toString(),
              style: TextStyle(
                fontSize: 15,
                color: setsWinner[set.toString()] == 2 ? _team2.color.computeLuminance() > 0.5 ? Colors.black: Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    return new WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.share,
              ),
              onPressed: (){
                _capturePng();
              },
            ),
          ],
        ),
        body: Material(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                child: Text(
                  "Ganador: " + _winner.name,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                  padding: EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(
                      color: _winner.color,
                      blurRadius: 10,
                      offset: Offset(0, 0),
                    )],
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  height: 130,
                  child: RepaintBoundary(
                    key: _globalKey,
                    child:  Container(
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(_team1.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(_team2.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          setBoard(1),
                          setBoard(2),
                          setBoard(3),
                          numberOfSets == 3 ? Container() : setBoard(4),
                          numberOfSets == 3 ? Container() : setBoard(5),
                        ],
                      ),
                    ),
                  ),
                ),
              Container(
                height: 80,
                width: 80,
                child: FlatButton(
                  shape: CircleBorder(),
                  child: Center(
                    child: Icon(
                      Icons.replay,
                      size: 50,
                    ),
                  ),
                  onPressed: (){
                    Navigator.of(context).push(_animatedRoute(ScoreBoard()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}