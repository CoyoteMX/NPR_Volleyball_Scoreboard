import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'GameOver.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';


class ScoreBoard extends StatefulWidget{
  @override
  State createState() => ScoreBoardState();
}

class ScoreBoardState extends State<ScoreBoard> {

  Team _team1 = Team(1, Alignment.centerLeft, Colors.amberAccent, "Local", <String,int> {'1': 0, '2': 0, '3': 0, '4':0, '5':0}, <String,int> {'1': 2, '2': 2, '3': 2, '4':2, '5':2}, 0);
  Team _team2 = Team(2, Alignment.centerRight, Colors.blueAccent, "Visitante", <String,int> {'1': 0, '2': 0, '3': 0, '4':0, '5':0}, <String,int> {'1': 2, '2': 2, '3': 2, '4':2, '5':2}, 0);

  Map<String, int> setsWinner = <String, int>{'1': 0, '2': 0, '3': 0, '4':0, '5':0};
  Map<String, int> actions = {};
  /*
  action 1 = point of team 1
  action 2 = team 2 point
  action 3 = team 1 clock
  action 4 = team 2 clock
  action 5 = invert teams align
  action 6 = set change
  */

  Map <String, int> possessionChange = {};

  int actionNumber = 0;


  int currentSet = 1;
  int setMaximum = 25;
  int lastPointTeam = 1;

  Color primaryColor = Color(0xFF679267);

  int popperCount = 0;
  bool _3sets = false;
  bool lastSetTo15 = false;

  bool isGameOver = false;
  int numberOfSets = 5;

  String matchNumber;
  String mirrorMatchNumber = "";
  bool online = false;
  bool mirrorMode = false;

  Team winner;

  int a;
  int r;
  int g;
  int b;

  bool portrait = true;


  DatabaseReference root = FirebaseDatabase.instance.reference().root();

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



  void gameOver(Team _winner, bool lessSets){
    setState(() {
      isGameOver = true;
      winner = _winner;
      if(_team2.score[currentSet.toString()] > _team1.score[currentSet.toString()]) {
        setsWinner[currentSet.toString()] = _winner._number;
        if(online){
          root.child(matchNumber).child("SetsWinner").child(currentSet.toString()).set(setsWinner[currentSet.toString()].toString());
        }
      }
      if(lessSets){
        ++_winner._setsWon;
        if(online){
          root.child(matchNumber).child("Team"+_winner._number.toString()).child("SetsWon").set(_winner._setsWon.toString());
        }
      }

    });
    Navigator.of(context).push(_animatedRoute(GameOver(_team1, _team2, winner, setsWinner, numberOfSets)));
  }

  void setOver(Team _winner){
    setState(() {
      ++actionNumber;
      actions[actionNumber.toString()] = 6;
      setsWinner[currentSet.toString()] = _winner._number;
      if(online){
        root.child(matchNumber).child("SetsWinner").child(currentSet.toString()).set(setsWinner[currentSet.toString()].toString());
      }
      ++currentSet;
      lastPointTeam = currentSet%2 == 0 ? 2: 1;
      setMaximum = lastSetTo15 ? currentSet == numberOfSets ? 15 : 25 : 25;
      ++_winner._setsWon;
      if(online){
        root.child(matchNumber).child("CurrentSet").set(currentSet.toString());
        root.child(matchNumber).child("Team"+_winner._number.toString()).child("SetsWon").set(_winner._setsWon.toString());
        root.child(matchNumber).child("LastPointTeam").set(lastPointTeam.toString());
      }
      if(numberOfSets == 3){
        if(_winner._setsWon == 2){
          winner = _winner;
          gameOver(_team1._score[currentSet.toString()] == setMaximum ? _team1 : _team2, false);
          if(online){
            root.child(matchNumber).child("GameOver").set("2");
          }
        }
      }else{
        if(_winner._setsWon==3){
          winner = _winner;
          gameOver(_team1._score[currentSet.toString()] == setMaximum ? _team1 : _team2, false);
          if(online){
            root.child(matchNumber).child("GameOver").set("2");
          }
        }
      }
    });
  }

  void createMatch(){
    root.child(matchNumber).set({
      'Exists': '1',
      'CurrentSet': currentSet.toString(),
      "LastPointTeam": lastPointTeam.toString(),
      'NumberOfSets': numberOfSets.toString(),
      'LastSetTo15': lastSetTo15 ? '1' : '2',
    });
    setsWinner.forEach((key, value) {
      root.child(matchNumber).child("SetsWinner").child(key).set(value.toString());
    });

    root.child(matchNumber).child("Team1").set({
      'Number': _team1.number.toString(),
      'Align': _team1._align == Alignment.centerLeft ? '1' : '2',
      'Name': _team1.name.toString(),
      'SetsWon': _team1._setsWon.toString(),
    });
    root.child(matchNumber).child("Team1").child("Color").set({
      'R': _team1._color.red.toString(),
      'G': _team1._color.green.toString(),
      'B': _team1._color.blue.toString(),
      'A': _team1._color.alpha.toString(),
    });
    _team1._remainingTimesOut.forEach((key, value) {
      root.child(matchNumber).child("Team1").child("RemainingTimesOut").child(key).set(value.toString());
    });
    _team1.score.forEach((key, value) {
      root.child(matchNumber).child("Team1").child("Score").child(key).set(value.toString());
    });


    root.child(matchNumber).child("Team2").set({
      'Number': _team2.number.toString(),
      'Align': _team2._align == Alignment.centerLeft ? '1' : '2',
      'Name': _team2.name.toString(),
      'SetsWon': _team2._setsWon.toString(),
    });
    root.child(matchNumber).child("Team2").child("Color").set({
      'R': _team2._color.red.toString(),
      'G': _team2._color.green.toString(),
      'B': _team2._color.blue.toString(),
      'A': _team2._color.alpha.toString(),
    });
    _team2._remainingTimesOut.forEach((key, value) {
      root.child(matchNumber).child("Team2").child("RemainingTimesOut").child(key).set(value.toString());
    });
    _team2.score.forEach((key, value) {
      root.child(matchNumber).child("Team2").child("Score").child(key).set(value.toString());
    });
  }

  void fetchTeams (){

    setState(() {
      int r;
      int g;
      int b;
      int a;
      print("Fetching");

      root.child(mirrorMatchNumber).child("CurrentSet").once().then((value) => {currentSet = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("LastPointTeam").once().then((value) => {lastPointTeam = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("LastSetTo15").once().then((value) => {lastSetTo15 = value.value.toString() == '1' ? true: false});
      root.child(mirrorMatchNumber).child("NumberOfSets").once().then((value) => {numberOfSets = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("SetsWinner").child("1").once().then((value) => {setsWinner["1"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("SetsWinner").child("2").once().then((value) => {setsWinner["2"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("SetsWinner").child("3").once().then((value) => {setsWinner["3"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("SetsWinner").child("4").once().then((value) => {setsWinner["4"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("SetsWinner").child("5").once().then((value) => {setsWinner["5"] = int.parse(value.value.toString())});

      root.child(mirrorMatchNumber).child("Team1").child("Align").once().then((value) => {_team1._align = value.value.toString() == '1' ? Alignment.centerLeft : Alignment.centerRight});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("A").once().then((value) => {a = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("R").once().then((value) => {r = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("G").once().then((value) => {g = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("B").once().then((value) => {b = int.parse(value.value.toString())});
      _team1._color = Color.fromARGB(a, r, g, b);
      root.child(mirrorMatchNumber).child("Team1").child("Name").once().then((value) => {_team1._name = value.value.toString()});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("1").once().then((value) => {_team1._remainingTimesOut["1"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("2").once().then((value) => {_team1._remainingTimesOut["2"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("3").once().then((value) => {_team1._remainingTimesOut["3"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("4").once().then((value) => {_team1._remainingTimesOut["4"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("5").once().then((value) => {_team1._remainingTimesOut["5"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("1").once().then((value) => {_team1._score["1"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("2").once().then((value) => {_team1._score["2"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("3").once().then((value) => {_team1._score["3"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("4").once().then((value) => {_team1._score["4"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("5").once().then((value) => {_team1._score["5"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team1").child("SetsWon").once().then((value) => {_team1._setsWon = int.parse(value.value.toString())});

      root.child(mirrorMatchNumber).child("Team2").child("Align").once().then((value) => {_team2._align = value.value.toString() == '1' ? Alignment.centerLeft : Alignment.centerRight});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("A").once().then((value) => {a = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("R").once().then((value) => {r = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("G").once().then((value) => {g = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("B").once().then((value) => {b = int.parse(value.value.toString())});
      _team2._color = Color.fromARGB(a, r, g, b);
      root.child(mirrorMatchNumber).child("Team2").child("Name").once().then((value) => {_team2._name = value.value.toString()});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("1").once().then((value) => {_team2._remainingTimesOut["1"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("2").once().then((value) => {_team2._remainingTimesOut["2"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("3").once().then((value) => {_team2._remainingTimesOut["3"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("4").once().then((value) => {_team2._remainingTimesOut["4"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("5").once().then((value) => {_team2._remainingTimesOut["5"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("1").once().then((value) => {_team2._score["1"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("2").once().then((value) => {_team2._score["2"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("3").once().then((value) => {_team2._score["3"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("4").once().then((value) => {_team2._score["4"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("5").once().then((value) => {_team2._score["5"] = int.parse(value.value.toString())});
      root.child(mirrorMatchNumber).child("Team2").child("SetsWon").once().then((value) => {_team2._setsWon = int.parse(value.value.toString())});
    });
  }

  void resetVariables() {
    setState(() {
      _team1 = Team(1, Alignment.centerLeft, Colors.amberAccent, "Local", <String,int> {'1': 0, '2': 0, '3': 0, '4':0, '5':0}, <String,int> {'1': 2, '2': 2, '3': 2, '4':2, '5':2}, 0);
      _team2 = Team(2, Alignment.centerRight, Colors.blueAccent, "Visitante", <String,int> {'1': 0, '2': 0, '3': 0, '4':0, '5':0}, <String,int> {'1': 2, '2': 2, '3': 2, '4':2, '5':2}, 0);

      setsWinner = <String, int>{'1': 0, '2': 0, '3': 0, '4':0, '5':0};
      actions = {};


      possessionChange = {};

      actionNumber = 0;


      currentSet = 1;
      setMaximum = 25;
      lastPointTeam = 1;

      primaryColor = Color(0xFF679267);

      popperCount = 0;
      _3sets = false;
      lastSetTo15 = false;

      isGameOver = false;
      numberOfSets = 5;

      matchNumber;
      mirrorMatchNumber = "";
      online = false;
      mirrorMode = false;
    });
  }

  Widget TeamEditor(Team _team, bool portrait) {

    return Container(
      height: portrait ? 70 : 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: _team._color,
          blurRadius: 5,
          offset: Offset(0, 2),
        )],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FlatButton(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: portrait ? 20: 5),
            child: Text(
              _team._name,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
          onPressed: (){
            if(!mirrorMode){
              showDialog(
                context: context,
                barrierDismissible: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: portrait ? 180 : 50),
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                    title: Text(
                      "Editar equipo",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    content: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            maxLength: 9,
                            decoration: InputDecoration(
                              hintText: _team._name,
                            ),
                            onChanged: (val){
                              setState(() {
                                if(val != ""){
                                  _team._name = val;
                                  if(online){
                                    root.child(matchNumber).child("Team"+_team._number.toString()).child("Name").set(val.toString());
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        Container (
                          margin: EdgeInsets.only(left: 20),
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: _team._color,
                            shape: BoxShape.circle,
                          ),
                          child: FlatButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onPressed: (){
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)
                                  ),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: _team._color,
                                      onColorChanged: (color){
                                        setState(() {
                                          _team._color = color;
                                          if(online){
                                            root.child(matchNumber).child("Team"+_team._number.toString()).child("Color").set({
                                              'R': color.red.toString(),
                                              'G': color.green.toString(),
                                              'B': color.blue.toString(),
                                              'A': color.alpha.toString(),
                                            });
                                          }
                                        });
                                      },
                                      showLabel: false,
                                      pickerAreaBorderRadius: BorderRadius.circular(20),
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text("Hecho"),
                                      onPressed: (){
                                        setState(() {
                                          _team._color = _team._color;
                                          popperCount = 0;
                                          Navigator.of(context).popUntil((route){
                                            return popperCount++ == 2;
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("Hecho"),
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }


  Widget Board(Team _team, bool portrait) {
    return Container(
      width: 140,
      margin: EdgeInsets.symmetric(vertical: portrait ? 20 : 10, horizontal: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          TeamEditor(_team, portrait),
          Container(
            margin: EdgeInsets.symmetric(vertical: portrait ? 20 : 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _team._color,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlatButton(
                onPressed: (){
                  if(!mirrorMode){
                    setState(() {
                      ++_team._score[currentSet.toString()];
                      if(online){
                        root.child(matchNumber).child("Team" + _team._number.toString()).child("Score").child(currentSet.toString()).set(_team._score[currentSet.toString()].toString());
                      }
                      if(_team._score[currentSet.toString()] < setMaximum){
                        ++actionNumber;
                        actions[actionNumber.toString()] = _team._number;
                        if(lastPointTeam != _team._number){
                          possessionChange[currentSet.toString() + _team._score[currentSet.toString()].toString() + "-"+ _team._number.toString()] = _team._number;
                        }
                        lastPointTeam = _team._number;
                        if(online){
                          root.child(matchNumber).child("LastPointTeam").set(lastPointTeam.toString());
                        }
                      }
                      if(isGameOver == false){
                        if(_team1._score[currentSet.toString()] == (setMaximum-1) && _team2._score[currentSet.toString()] == (setMaximum-1)){
                          ++setMaximum;
                        }

                        if(_team1._score[currentSet.toString()] == setMaximum || _team2._score[currentSet.toString()] == setMaximum){
                          if(currentSet == numberOfSets){
                            if(online){
                              root.child(matchNumber).child("GameOver").set('1');
                            }
                            gameOver(_team1._score[currentSet.toString()] == setMaximum ? _team1 : _team2, true);
                          }else{
                            setOver(_team1._score[currentSet.toString()] == setMaximum ? _team1 : _team2);
                          }
                        }
                      }
                    });
                  }
                },
                child:
                Container(
                  width: 150,
                  margin: EdgeInsets.symmetric(vertical: portrait ? 30 : 5),
                  child: Center(
                    child: Text(
                      _team._score[currentSet.toString()].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _team._color.computeLuminance() > 0.5 ? Colors.black: Colors.white,
                        fontSize: portrait ? 60 : 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: _team._align,
            child: Row(
              mainAxisAlignment: _team._align == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: <Widget>[
                _team._align == Alignment.centerLeft ? Container() :
                Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _team._remainingTimesOut[currentSet.toString()] == 2 ? _team._color : Colors.grey,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _team._remainingTimesOut[currentSet.toString()] >= 1 ? _team._color : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: _team._color,
                  ),
                  child: IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    iconSize: 30,
                    icon: Icon(
                      Icons.timer,
                      color: _team._color.computeLuminance() > 0.5 ? Colors.black: Colors.white,
                    ),
                    onPressed: (){
                      if(!mirrorMode){
                        if(_team._remainingTimesOut[currentSet.toString()]> 0){
                          setState(() {
                            ++actionNumber;
                            actions[actionNumber.toString()] = _team._number+2;
                            --_team._remainingTimesOut[currentSet.toString()];
                            if(online){
                              root.child(matchNumber).child("Team" + _team._number.toString()).child("RemainingTimesOut").child(currentSet.toString()).set(_team._remainingTimesOut[currentSet.toString()].toString());
                            }
                          });


                          Timer _timer;
                          int _seconds = 30;
                          int x = 0;


                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context){

                                return StatefulBuilder(
                                  builder: (BuildContext context,setState){
                                    if(x<1){
                                      _timer = Timer.periodic(
                                          Duration(seconds: 1),
                                              (timer){
                                            setState(() {
                                              if(_seconds>0){
                                                --_seconds;
                                              }else {
                                                _timer.cancel();
                                              }
                                            });
                                          });
                                      ++x;
                                    }
                                    if(!_timer.isActive){
                                      Navigator.of(context).pop();
                                    }
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      title: Text(
                                        "Tiempo muerto",
                                        style: TextStyle(
                                          fontSize: 25,
                                        ),
                                      ),
                                      content: Container(
                                        child: Text(
                                          _seconds >= 10 ? "00:$_seconds" : "00:0$_seconds",
                                          style: TextStyle(
                                            fontSize: 50,
                                          ),
                                        ),
                                      ),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(
                                            "Saltar",
                                            style: TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          onPressed: (){
                                            _timer.cancel();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                          );

                        }
                      }
                    },
                  ),
                ),
                _team._align == Alignment.centerRight ? Container() :
                Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _team._remainingTimesOut[currentSet.toString()] == 2 ? _team._color : Colors.grey,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _team._remainingTimesOut[currentSet.toString()] >= 1 ? _team._color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          lastPointTeam == _team._number ? Align(
            alignment: _team._align,
            child:  Container(
              margin: EdgeInsets.only(top: 10),
              height: 50,
              width: 50,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _team._color,
              ),
              child: SvgPicture.asset(
                "assets/icons/ball-volleyball.svg",
                width: 35,
                height: 35,
                color: _team._color.computeLuminance() > 0.5 ? Colors.black: Colors.white,
              ),
            ) ,
          ): Container(
            margin: EdgeInsets.only(top: 10),
            height: 50,
            width: 50,
          ),

        ],
      ),
    );
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
            color: setsWinner[set.toString()] == 1 ? _team1._color : Colors.transparent,
          ),
          child: Text(
            _team1._score[set.toString()].toString(),
            style: TextStyle(
              fontSize: 15,
              color: setsWinner[set.toString()] == 1 ? _team1._color.computeLuminance() > 0.5 ? Colors.black: Colors.white : Colors.black,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: setsWinner[set.toString()] == 2 ? _team2._color : Colors.transparent,
          ),
          child: Text(
            _team2._score[set.toString()].toString(),
            style: TextStyle(
              fontSize: 15,
              color: setsWinner[set.toString()] == 2 ? _team2._color.computeLuminance() > 0.5 ? Colors.black: Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }




  void undo(){
    if(actionNumber > 0){
      setState(() {
        switch (actions[actionNumber.toString()]){
          case 1: {
            if(possessionChange[currentSet.toString() + _team1._score[currentSet.toString()].toString() + "-1"] != null){
              lastPointTeam = 2;
              possessionChange.remove(currentSet.toString() + _team1._score[currentSet.toString() + "-1"].toString());
            }
            --_team1._score[currentSet.toString()];
            if(online){
              root.child(matchNumber).child("Team1").child("Score").child(currentSet.toString()).set(_team1._score[currentSet.toString()].toString());
              root.child(matchNumber).child("LastPointTeam").set(lastPointTeam.toString());
            }
          }
          break;
          case 2: {
            if(possessionChange[currentSet.toString() + _team2._score[currentSet.toString()].toString() + "-2"] != null){
              lastPointTeam = 1;
              possessionChange.remove(currentSet.toString() + _team2._score[currentSet.toString() + "-2"].toString());
            }
            --_team2._score[currentSet.toString()];
            if(online){
              root.child(matchNumber).child("Team2").child("Score").child(currentSet.toString()).set(_team2._score[currentSet.toString()].toString());
              root.child(matchNumber).child("LastPointTeam").set(lastPointTeam.toString());
            }
          }
          break;
          case 3: {
            ++_team1._remainingTimesOut[currentSet.toString()];
            if(online){
              root.child(matchNumber).child("Team1").child("RemainingTimesOut").child(currentSet.toString()).set(_team1._remainingTimesOut[currentSet.toString()].toString());
            }
          }
          break;
          case 4: {
            ++_team2._remainingTimesOut[currentSet.toString()];
            if(online){
              root.child(matchNumber).child("Team2").child("RemainingTimesOut").child(currentSet.toString()).set(_team2._remainingTimesOut[currentSet.toString()].toString());
            }
          }
          break;
          case 5: {
            if(_team1._align == Alignment.centerLeft){
              _team1._align = Alignment.centerRight;
              _team2._align = Alignment.centerLeft;
            }else if (_team1._align == Alignment.centerRight) {
              _team2._align = Alignment.centerRight;
              _team1._align = Alignment.centerLeft;
            }
            if(online){
              root.child(matchNumber).child("Team1").child("Align").set(_team1._align == Alignment.centerLeft ? '1' : '2');
              root.child(matchNumber).child("Team2").child("Align").set(_team2._align == Alignment.centerLeft ? '1' : '2');
            }
          }
          break;
          case 6: {
            --currentSet;
            lastPointTeam = setsWinner[currentSet.toString()];
            setsWinner[currentSet.toString()] == 1 ? --_team1._score[currentSet.toString()] : --_team2._score[currentSet.toString()];
            setsWinner[currentSet.toString()] == 1 ? --_team1._setsWon : --_team2._setsWon;
            setMaximum = setsWinner[currentSet.toString()] == 1 ? _team1.score[currentSet.toString()]+1 : _team2._score[currentSet.toString()]+1;
            setsWinner.remove(currentSet.toString());
            if(online){
              root.child(matchNumber).child("SetsWinner").child(currentSet.toString()).remove();
              root.child(matchNumber).child("CurrentSet").child(currentSet.toString()).set(currentSet.toString());
              root.child(matchNumber).child("Team1").child("Score").child(currentSet.toString()).set(_team1._score[currentSet.toString()].toString());
              root.child(matchNumber).child("Team2").child("Score").child(currentSet.toString()).set(_team2._score[currentSet.toString()].toString());
              root.child(matchNumber).child("Team1").child("SetsWon").set(_team1._setsWon.toString());
              root.child(matchNumber).child("Team2").child("SetsWon").set(_team2._setsWon.toString());
              root.child(matchNumber).child("LastPointTeam").set(lastPointTeam.toString());
            }
          }
          break;
          default: {
            print("Invalid");
          }
          break;
        }
        actions.remove(actionNumber.toString());
        --actionNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

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

    if(mirrorMode){
      root.child(mirrorMatchNumber).child("CurrentSet").onValue.listen((event) {setState(() {currentSet = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("LastPointTeam").onValue.listen((event) {setState(() {lastPointTeam = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("LastSetTo15").onValue.listen((event) {setState(() {lastSetTo15 = event.snapshot.value.toString() == '1' ? true: false;});});
      root.child(mirrorMatchNumber).child("NumberOfSets").onValue.listen((event) {setState((){numberOfSets = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("SetsWinner").child("1").onValue.listen((event) {setState(() {setsWinner["1"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("SetsWinner").child("2").onValue.listen((event) {setState(() {setsWinner["2"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("SetsWinner").child("3").onValue.listen((event) {setState(() {setsWinner["3"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("SetsWinner").child("4").onValue.listen((event) {setState(() {setsWinner["4"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("SetsWinner").child("5").onValue.listen((event) {setState(() {setsWinner["5"] = int.parse(event.snapshot.value);});});

      root.child(mirrorMatchNumber).child("Team1").child("Align").onValue.listen((event) {setState(() {_team1._align = event.snapshot.value.toString() == '1' ? Alignment.centerLeft : Alignment.centerRight;});});

      root.child(mirrorMatchNumber).child("Team1").child("Color").child("A").onValue.listen((event) {setState(() {a = int.parse(event.snapshot.value); _team1._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("R").onValue.listen((event) {setState(() {r = int.parse(event.snapshot.value); _team1._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("G").onValue.listen((event) {setState(() {g = int.parse(event.snapshot.value); _team1._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team1").child("Color").child("B").onValue.listen((event) {setState(() {b = int.parse(event.snapshot.value); _team1._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team1").child("Name").onValue.listen((event) {setState(() {_team1._name = event.snapshot.value.toString();});});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("1").onValue.listen((event) {setState(() {_team1._remainingTimesOut["1"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("2").onValue.listen((event) {setState(() {_team1._remainingTimesOut["2"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("3").onValue.listen((event) {setState(() {_team1._remainingTimesOut["3"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("4").onValue.listen((event) {setState(() {_team1._remainingTimesOut["4"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("RemainingTimesOut").child("5").onValue.listen((event) {setState(() {_team1._remainingTimesOut["5"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("1").onValue.listen((event) {setState(() {_team1._score["1"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("2").onValue.listen((event) {setState(() {_team1._score["2"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("3").onValue.listen((event) {setState(() {_team1._score["3"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("4").onValue.listen((event) {setState(() {_team1._score["4"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("Score").child("5").onValue.listen((event) {setState(() {_team1._score["5"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team1").child("SetsWon").onValue.listen((event) {setState(() {_team1._setsWon = int.parse(event.snapshot.value);});});

      root.child(mirrorMatchNumber).child("Team2").child("Align").onValue.listen((event) {setState(() {_team2._align = event.snapshot.value.toString() == '1' ? Alignment.centerLeft : Alignment.centerRight;});});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("A").onValue.listen((event) {setState(() {a = int.parse(event.snapshot.value); _team2._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("R").onValue.listen((event) {setState(() {r = int.parse(event.snapshot.value); _team2._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("G").onValue.listen((event) {setState(() {g = int.parse(event.snapshot.value); _team2._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team2").child("Color").child("B").onValue.listen((event) {setState(() {b = int.parse(event.snapshot.value); _team2._color = Color.fromARGB(a, r, g, b);});});
      root.child(mirrorMatchNumber).child("Team2").child("Name").onValue.listen((event) {setState(() {_team2._name = event.snapshot.value.toString();});});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("1").onValue.listen((event) {setState(() {_team2._remainingTimesOut["1"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("2").onValue.listen((event) {setState(() {_team2._remainingTimesOut["2"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("3").onValue.listen((event) {setState(() {_team2._remainingTimesOut["3"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("4").onValue.listen((event) {setState(() {_team2._remainingTimesOut["4"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("RemainingTimesOut").child("5").onValue.listen((event) {setState(() {_team2._remainingTimesOut["5"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("1").onValue.listen((event) {setState(() {_team2._score["1"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("2").onValue.listen((event) {setState(() {_team2._score["2"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("3").onValue.listen((event) {setState(() {_team2._score["3"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("4").onValue.listen((event) {setState(() {_team2._score["4"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("Score").child("5").onValue.listen((event) {setState(() {_team2._score["5"] = int.parse(event.snapshot.value);});});
      root.child(mirrorMatchNumber).child("Team2").child("SetsWon").onValue.listen((event) {setState(() {_team2._setsWon = int.parse(event.snapshot.value);});});
      if(isGameOver){
        root.child(mirrorMatchNumber).child("GameOver").onValue.listen((event) {if(event.snapshot.value == "1"){gameOver(_team1._score[currentSet.toString()] > _team2._score[currentSet.toString()] ? _team1 : _team2, true);}else if(event.snapshot.value == "2"){gameOver(_team1._score[currentSet.toString()] > _team2._score[currentSet.toString()] ? _team1 : _team2, false);}});
      }
    }



   return new WillPopScope(
     onWillPop: () async => false,
     child: Material(
       color: Colors.white,
       child: Scaffold(
         backgroundColor: Colors.white,
         resizeToAvoidBottomInset: false,
         appBar: AppBar(
           automaticallyImplyLeading: false,
           backgroundColor: primaryColor,
           elevation: 0,
           title: Row(
             children: <Widget>[
               Container(
                 margin: EdgeInsets.all(10),
                 child: Text(
                   "Marcador",
                   style: TextStyle(
                     fontWeight: FontWeight.bold,
                     fontSize: 25,
                   ),
                 ),
               ),
               Expanded(
                 child: Container(
                   alignment: Alignment.centerRight,
                   margin: EdgeInsets.all(10),
                   child: IconButton(
                     icon: Icon(
                       Icons.share,
                       color: primaryColor.computeLuminance() > 0.5 ? Colors.black: Colors.white,
                     ),
                     onPressed: (){
                       _capturePng();
                     },
                   ),
                 ),
               ),
               Container(
                 child: Align(
                   alignment: Alignment.centerRight,
                   child: IconButton(
                     icon: Icon(Icons.more_horiz),
                     onPressed: (){
                       showModalBottomSheet(
                           isScrollControlled: true,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                           ),
                           context: context,
                           builder: (BuildContext context){
                             return StatefulBuilder(
                               builder: (context, setSt){
                                 return Container(
                                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom+15),
                                   height: portrait ? 400 : 300,
                                   child: ListView(
                                     children: <Widget>[
                                       mirrorMode ? Container() : Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: <Widget>[
                                           Container(
                                             margin: EdgeInsets.only(top: 10, left: 25),
                                             child: Text(
                                               "Partido a 3 sets",
                                               style: TextStyle(
                                                 fontSize: 17,
                                               ),
                                             ),
                                           ),
                                           Container(
                                             margin: EdgeInsets.only(top: 10, right: 25),
                                             child: Switch(
                                               value: _3sets,
                                               onChanged: (val){
                                                 setSt(() {
                                                   _3sets = val;
                                                   numberOfSets = _3sets ? 3 : 5;
                                                 });
                                                 setState(() {
                                                   _3sets = val;
                                                   numberOfSets = _3sets ? 3 : 5;
                                                   if(lastSetTo15 && currentSet == numberOfSets){
                                                     setMaximum = 15;
                                                   }
                                                 });
                                                 if(online){
                                                   root.child(matchNumber).child("NumberOfSets").set(numberOfSets.toString());
                                                 }
                                               },
                                             ),
                                           ),
                                         ],
                                       ),
                                       mirrorMode ? Container() : Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: <Widget>[
                                           Container(
                                             margin: EdgeInsets.only(top: 7.5, left: 25),
                                             child: Text(
                                               "Último set a 15 puntos",
                                               style: TextStyle(
                                                 fontSize: 17,
                                               ),
                                             ),
                                           ),
                                           Container(
                                             margin: EdgeInsets.only(top: 7.5, right: 25),
                                             child: Switch(
                                               value: lastSetTo15,
                                               onChanged: (val){
                                                 setSt(() {
                                                   lastSetTo15 = val;
                                                 });
                                                 setState(() {
                                                   lastSetTo15 = val;
                                                   if(currentSet == numberOfSets){
                                                     setMaximum = 15;
                                                   }
                                                 });
                                                 if(online){
                                                   root.child(matchNumber).child("LastSetTo15").set(lastSetTo15 ? '1' : '2');
                                                 }
                                               },
                                             ),
                                           ),
                                         ],
                                       ),
                                       mirrorMode ? Container() : Align(
                                         alignment: Alignment.centerLeft,
                                         child:  Container(
                                           margin: EdgeInsets.only(top: 30, left: 25),
                                           child: Text(
                                             "Compartir partido",
                                             style: TextStyle(
                                               fontSize: 17,
                                             ),
                                           ),
                                         ),
                                       ),
                                       mirrorMode ? Container() : Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: <Widget>[
                                           Container(
                                             margin: EdgeInsets.only(top: 10, left: 25),
                                             width: 225,
                                             child: TextFormField(
                                               enabled: !online,
                                               maxLength: 6,
                                               keyboardType: TextInputType.number,
                                               decoration: InputDecoration(
                                                 hintText: online ? matchNumber : "Ingresa un PIN",
                                               ),
                                               onChanged: (val){
                                                 setState(() {
                                                   matchNumber = val;
                                                 });
                                               },
                                             ),
                                           ),
                                           Container(
                                             margin: EdgeInsets.only(top: 10),
                                             child: Container(
                                               margin: EdgeInsets.all(10),
                                               decoration: BoxDecoration(
                                                 color: Colors.white,
                                                 shape: BoxShape.circle,
                                                 boxShadow: [BoxShadow(
                                                   color: Colors.grey.withOpacity(0.5),
                                                   blurRadius: 5,
                                                   offset: Offset(0, 0),
                                                 )],
                                               ),
                                               child: ClipRRect(
                                                 borderRadius: BorderRadius.circular(50),
                                                 child: FlatButton(
                                                   shape: CircleBorder(),
                                                   child: Icon(
                                                     online ? Icons.cancel : Icons.check,
                                                     color: Colors.black,
                                                   ),
                                                   onPressed: (){
                                                     setState(() {
                                                       setSt((){
                                                         online = !online;
                                                       });
                                                       if(online){
                                                         createMatch();
                                                       }else{
                                                         root.child(matchNumber).remove();
                                                       }
                                                     });
                                                   },
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ],
                                       ),
                                       online ? Container() : Align(
                                         alignment: Alignment.centerLeft,
                                         child: Container(
                                           margin: EdgeInsets.only(top: mirrorMode ? 30 : 10, left: 20),
                                           child: Text(
                                             "Modo Espejo",
                                             style: TextStyle(
                                               fontSize: 17,
                                             ),
                                           ),
                                         ),
                                       ),
                                       online ? Container() : Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: <Widget>[
                                           Container(
                                             margin: EdgeInsets.only(top: 10, left: 20),
                                             width: 225,
                                             child: TextFormField(
                                               enabled: !mirrorMode,
                                               maxLength: 6,
                                               keyboardType: TextInputType.number,
                                               decoration: InputDecoration(
                                                 hintText: mirrorMode ? mirrorMatchNumber : "PIN del partido",
                                               ),
                                               onChanged: (val){
                                                 setState(() {
                                                   setSt((){
                                                     mirrorMatchNumber = val;
                                                   });
                                                 });
                                                 print(mirrorMatchNumber);
                                               },
                                             ),
                                           ),
                                           Container(
                                             margin: EdgeInsets.only(top: 10),
                                             child: Container(
                                               margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                                               decoration: BoxDecoration(
                                                 color: Colors.white,
                                                 shape: BoxShape.circle,
                                                 boxShadow: [BoxShadow(
                                                   color: Colors.grey.withOpacity(0.5),
                                                   blurRadius: 5,
                                                   offset: Offset(0, 0),
                                                 )],
                                               ),
                                               child: ClipRRect(
                                                 borderRadius: BorderRadius.circular(50),
                                                 child: FlatButton(
                                                   shape: CircleBorder(),
                                                   child: Icon(
                                                     mirrorMode ? Icons.cancel : Icons.check,
                                                     color: Colors.black,
                                                   ),
                                                   onPressed: (){
                                                     setState(() {
                                                       setSt((){
                                                         if(!mirrorMode){
                                                           root.child(mirrorMatchNumber).child("Exists").once().then((value) => {setState((){setSt((){mirrorMode = value.value == "1" ? true : false;});})}).then((value) {
                                                             if(!mirrorMode){
                                                               Fluttertoast.showToast(
                                                                 msg: "¿Ingresaste el código correcto?",
                                                                 backgroundColor: Colors.grey.withOpacity(0.7),
                                                               );
                                                             }else {
                                                               fetchTeams();
                                                             }
                                                           });
                                                         }else{
                                                           mirrorMode = false;
                                                           resetVariables();
                                                         }
                                                       });
                                                     });
                                                   },
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ],
                                       ),
                                     ],
                                   ),
                                 );
                               },
                             );
                           }
                       );
                     },
                   ),
                 ),
               ),
             ],
           ),
         ),
         body: OrientationBuilder(
           builder: (_, orientation){
             portrait = orientation == Orientation.portrait ? true : false;
             return Material(
               color: Colors.white,
               child: SingleChildScrollView(
                 child: Column(
                   children: <Widget>[
                     Stack(
                       alignment: Alignment.topCenter,
                       children: <Widget>[

                         AnimatedContainer(
                           alignment: _team1._align,
                           duration: Duration(milliseconds: 400),
                           child: Board(_team1, portrait),
                         ),
                         AnimatedContainer(
                           alignment: _team2._align,
                           duration: Duration(milliseconds: 400),
                           child: Board(_team2, portrait),
                         ),
                         Column(
                           children: <Widget>[
                             Container(
                               height: portrait ? 280 : 30,
                             ),
                             mirrorMode ? Container(
                               height: 50,
                             ) : Container(
                               child: FlatButton(
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(15),
                                 ),
                                 onPressed: (){
                                   setState(() {
                                     ++actionNumber;
                                     actions[actionNumber.toString()] = 5;
                                     if(_team1._align == Alignment.centerLeft){
                                       _team1._align = Alignment.centerRight;
                                       _team2._align = Alignment.centerLeft;
                                     }else if (_team1._align == Alignment.centerRight) {
                                       _team2._align = Alignment.centerRight;
                                       _team1._align = Alignment.centerLeft;
                                     }
                                     if(online){
                                       root.child(matchNumber).child("Team1").child("Align").set(_team1._align == Alignment.centerLeft ? '1' : '2');
                                       root.child(matchNumber).child("Team2").child("Align").set(_team2._align == Alignment.centerLeft ? '1' : '2');
                                     }
                                   });
                                 },
                                 child: Container(
                                   height: 50,
                                   width: 50,
                                   child: Icon(
                                     Icons.swap_horiz,
                                     size: 40,
                                   ),
                                 ),
                               ),
                             ),
                             mirrorMode ? Container(
                               height: 50,
                             ) : Container(
                               margin: EdgeInsets.only(top: 10),
                               child: FlatButton(
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(15),
                                 ),
                                 onPressed: () => undo(),
                                 child: Container(
                                   height: 50,
                                   width: 50,
                                   child: Icon(
                                     Icons.undo,
                                     size: 40,
                                   ),
                                 ),
                               ),
                             ),
                             RepaintBoundary(
                               key: _globalKey,
                               child: Container(
                                 margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                                 height: 100,
                                 color: Colors.white,
                                 width: portrait ? double.infinity : 340,
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                   children: <Widget>[
                                     Column(
                                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                       children: <Widget>[
                                         Text(" ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                         Text(_team1._name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                         Text(_team2._name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                           ],
                         ),
                       ],
                     ),

                   ],
                 ),
               ),
             );
           },
         ),
       ),
     ),
   );
  }
}


class Team {
  int _number;
  Alignment _align;
  Color _color;
  String _name;
  Map <String, int> _score;
  Map <String, int> _remainingTimesOut;
  int _setsWon;

  int get number{
    return _number;
  }
  Alignment get align{
    return _align;
  }
  Color get color{
    return _color;
  }

  String get name{
    return _name;
  }

  Map <String, int> get score{
    return _score;
  }

  Map <String, int>  get remainingTimesOut{
    return _remainingTimesOut;
  }

  int get setsWon{
    return _setsWon;
  }

  Team(this._number, this._align, this._color, this._name, this._score, this._remainingTimesOut, this._setsWon);
}