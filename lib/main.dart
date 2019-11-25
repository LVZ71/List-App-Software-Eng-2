import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

//TODO link new account text to registration page by an onpressed
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class LoggedInPage extends StatefulWidget {
  LoggedInPage({Key key, this.username, this.token}) : super(key: key);

  final String username;
  final String token;

  @override
  _LoggedInPage createState() => _LoggedInPage();
}

class ItemList {
  List<Item> items;
  ItemList({
    this.items,
  });
  factory ItemList.fromJson(List<dynamic> parsedJson) {
    List<Item> items = new List<Item>();
    print(items.runtimeType);
    items = parsedJson.map((i) => Item.fromJson(i)).toList();
    return new ItemList(items: items);
  }
}

class Item {
  int id;
  String text;
  bool completed;
  String created_at;
  int user_id;

  Item({this.id, this.text, this.completed, this.created_at, this.user_id});
  factory Item.fromJson(Map<String, dynamic> parsedJson) {
    return new Item(
        id: parsedJson['id'],
        text: parsedJson['text'],
        completed: parsedJson['completed'],
        created_at: parsedJson['created_at'],
        user_id: parsedJson['user_id']);
  }
}

class _LoggedInPage extends State<LoggedInPage> {
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  var addingController = TextEditingController();
  var editingController = TextEditingController();
  bool _visibility = false;
  bool _visibilityforedit = false;
  bool pressed = false;
  String _secret = " ";
  String todotext = "";
  int _length = 0;
  ItemList _items;
  String _test = "add";
  String tosavetodotext = "";
  int _idofcurrenttilelist = null;

  Future<void> addTodo(String todotext, String token) async {
    final response = await http.post(
        "https://sleepy-hamlet-97922.herokuapp.com/todo_items?text=$todotext",
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"});

    if (response.statusCode == 201) {
      String textFromServer = response.body;
      print("this was posted: " + textFromServer);
      final jsonResponse = json.decode(textFromServer);

      Item todoposted = Item.fromJson(jsonResponse);
      print(jsonResponse);
      setState(() {
        _items.items.add(todoposted);
        _length = _items.items.length;
        _visibility = false;
        addingController.text = "";
      });
    }
  }

  Future<void> editTodo(int idd, String textoupdate, String token) async {
    final response = await http.patch(
        "https://sleepy-hamlet-97922.herokuapp.com/todo_items/${idd.toString()}?text=$textoupdate",
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"});
    if (response.statusCode == 200) {
      setState(() {
        _items.items.firstWhere((itm) => itm.id == idd, orElse: null).text =
            textoupdate;
        _visibilityforedit = false;
      });
    }
  }

  Future<void> deleteTodo(int id, String token) async {
    final response = await http.delete(
        "https://sleepy-hamlet-97922.herokuapp.com/todo_items/${id.toString()}",
        headers: {HttpHeaders.authorizationHeader: "bearer $token"});
    if (response.statusCode == 200) {
      var obj = _items.items.firstWhere((i) => i.id == id, orElse: null);
      setState(() {
        _items.items.removeAt(_items.items.indexOf(obj));
        _length = _items.items.length;
        _visibilityforedit = false;
      });
    }
  }

  Future<void> _onCheckButtonPressed(int id, bool check, String token) async {
    print("token" + token);
    bool boolean = !check;
    String boolean2 = boolean.toString();
    String id2 = id.toString();
    print(id2 + " and " + boolean2);
    final response = await http.patch(
        "https://sleepy-hamlet-97922.herokuapp.com/todo_items/$id2?completed=$boolean2",
        headers: {HttpHeaders.authorizationHeader: "Bearer $token"});

    if (response.statusCode == 200) {
      print("It went through");
    } else {
      print("error");
    }
  }

  Future<void> setList(String token) async {
    final response = await http.get(
      "https://sleepy-hamlet-97922.herokuapp.com/todo_items",
      headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
    );
    if (response.statusCode == 200) {
      String textFromServer = response.body;
      print("response boyd" + textFromServer);
      final jsonResponse = json.decode(textFromServer);
      print(jsonResponse);
      ItemList itemlist = ItemList.fromJson(jsonResponse);

      setState(() {
        _items = itemlist;
        _length = _items.items.length;
      });
    } else if (response.statusCode == 400) {
      print("Bad request");
    } else {
      print("Error");
    }
  }

  Future<void> getSecret(String token) async {
    final response = await http.get(
      "https://sleepy-hamlet-97922.herokuapp.com/secret",
      headers: {HttpHeaders.authorizationHeader: "Bearer $token"},
    );
    if (response.statusCode == 401) {
      setState(() {
        _secret = "A valid token must be passed";
      });
    } else if (response.statusCode == 200) {
      String textFromServer = response.body;
      Map<String, dynamic> data = json.decode(textFromServer);
      print(data);
      String word = data["message"];
      setState(() {
        _secret = word;
      });
    } else {
      setState(() {
        _secret = "Error";
      });
    }
  }

  void setStringValues() {
    todotext = addingController.text;
  }

  void _pushedAdd() {
    setState(() {
      _visibility = true;
    });
  }
  ////////Widget _

  Widget _buildrow(Item i) {
    bool checked = i.completed;
    return ListTile(
        key: ValueKey(i.id),
        title: Text(
          i.text != null ? i.text : "this was null",
          style: _biggerFont,
        ),
        trailing: IconButton(
            icon: checked
                ? Icon(Icons.check_box)
                : Icon(Icons.check_box_outline_blank),
            color: checked ? Colors.green : null,
            onPressed: () {
              _onCheckButtonPressed(i.id, i.completed, widget.token);
              setState(() {
                if (i.completed) {
                  i.completed = false;
                } else {
                  i.completed = true;
                }
              });
            }),
        onLongPress: () {
          setState(() {
            _visibilityforedit = true;
            editingController.text =
                (i.text != null ? i.text : "this was null");
            _idofcurrenttilelist = i.id;
          });
        });
  }

  @override
  void initState() {
    setList(widget.token).then((value) {
      print('Async done');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //var str = await getSecret(widget.token);
    return Scaffold(
        appBar: AppBar(
          title: Text("Secret"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _pushedAdd,
            ),
          ],
        ),
        body: Stack(children: <Widget>[
          new ListView.builder(
              itemCount: _length,
              itemBuilder: (BuildContext _context, int index) {
                return _buildrow(_items.items[index]);
              }),
          Visibility(
            visible: _visibility,
            child: Center(
              child: Container(
                  width: 380,
                  height: ScreenUtil.getInstance().setHeight(500),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 15.0),
                            blurRadius: 15.0),
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0.0, -10.0),
                          blurRadius: 10.0,
                        ),
                      ]),
                  child: Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Add",
                              style: TextStyle(
                                fontSize: ScreenUtil.getInstance().setSp(45),
                                fontFamily: "Poppings-Bold",
                                letterSpacing: .6,
                              )),
                          SizedBox(
                            height: ScreenUtil.getInstance().setHeight(30),
                          ),
                          TextField(
                            controller: addingController,
                            decoration: InputDecoration(
                                hintText: "new to-do",
                                hintStyle: TextStyle(
                                    color: Colors.grey, fontSize: 12.0)),
                          ),
                          SizedBox(
                            height: ScreenUtil.getInstance().setHeight(30),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10.0),
                            ),
                            onTap: () {
                              setStringValues();
                              addTodo(todotext, widget.token);
                            },
                            child: Container(
                              width: ScreenUtil.getInstance().setWidth(280),
                              padding: EdgeInsets.all(15.0),
                              child: Center(
                                child: Text(
                                  "Enter",
                                  style: TextStyle(
                                    fontFamily: "Rubik-Medium",
                                    fontSize: 15.0,
                                    color: Colors.white,
                                    inherit: false,
                                  ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                            ),
                          )
                        ],
                      ))),
            ),
          ),
          Visibility(
            visible: _visibilityforedit,
            child: Center(
              child: Container(
                  width: 380,
                  height: ScreenUtil.getInstance().setHeight(500),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 15.0),
                            blurRadius: 15.0),
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0.0, -10.0),
                          blurRadius: 10.0,
                        ),
                      ]),
                  child: Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("Editing",
                              style: TextStyle(
                                fontSize: ScreenUtil.getInstance().setSp(45),
                                fontFamily: "Poppings-Bold",
                                letterSpacing: .6,
                              )),
                          SizedBox(
                            height: ScreenUtil.getInstance().setHeight(30),
                          ),
                          TextField(
                            controller: editingController,
                            decoration: InputDecoration(
                                semanticCounterText: "This is in here",
                                hintStyle: TextStyle(
                                    color: Colors.grey, fontSize: 12.0)),
                          ),
                          SizedBox(
                            height: ScreenUtil.getInstance().setHeight(30),
                          ),
                          Row(
                            children: <Widget>[
                              InkWell(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                                onTap: () {
                                  //TODO delete function
                                  deleteTodo(
                                      _idofcurrenttilelist, widget.token);
                                },
                                child: Container(
                                  width: ScreenUtil.getInstance().setWidth(180),
                                  padding: EdgeInsets.all(15.0),
                                  child: Center(
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(
                                        fontFamily: "Rubik-Medium",
                                        fontSize: 15.0,
                                        color: Colors.white,
                                        inherit: false,
                                      ),
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: ScreenUtil.getInstance().setWidth(270),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                                onTap: () {
                                  //TODO edit function
                                  tosavetodotext = editingController.text;
                                  //editTodo(tosavetodotext, widget.token);
                                  editTodo(_idofcurrenttilelist, tosavetodotext,
                                      widget.token);
                                },
                                child: Container(
                                  width: ScreenUtil.getInstance().setWidth(180),
                                  padding: EdgeInsets.all(15.0),
                                  child: Center(
                                    child: Text(
                                      "Save",
                                      style: TextStyle(
                                        fontFamily: "Rubik-Medium",
                                        fontSize: 15.0,
                                        color: Colors.white,
                                        inherit: false,
                                      ),
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10.0),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ))),
            ),
          )
        ]));
  }
}

class RegistrationPage extends StatefulWidget {
  RegistrationPage({Key key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  String username = "";
  String password = "";

  void setStringValues() {
    username = usernameController.text;
    password = passwordController.text;
  }

  Future<void> registration(String username, String password) async {
    var response = await http.post(
        "https://sleepy-hamlet-97922.herokuapp.com/api/register?username=${username}&password=${password}");
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil.getInstance()..init(context);
    ScreenUtil.instance =
        ScreenUtil(width: 750, height: 1334, allowFontScaling: true);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("RegistationPage"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 380,
              height: ScreenUtil.getInstance().setHeight(500),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0.0, 15.0),
                        blurRadius: 15.0),
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, -10.0),
                      blurRadius: 10.0,
                    ),
                  ]),
              child: Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Login",
                          style: TextStyle(
                            fontSize: ScreenUtil.getInstance().setSp(45),
                            fontFamily: "Poppings-Bold",
                            letterSpacing: .6,
                          )),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Text("Username",
                          style: TextStyle(
                            fontFamily: "Poppins-Medium",
                            fontSize: ScreenUtil.getInstance().setSp(26),
                          )),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                            hintText: "username",
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 12.0)),
                      ),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Text("Password",
                          style: TextStyle(
                            fontFamily: "Poppins-Medium",
                            fontSize: ScreenUtil.getInstance().setSp(26),
                          )),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                            hintText: "password",
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 12.0)),
                      ),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text("New Account",
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: "Poppins-Medium",
                                fontSize: ScreenUtil.getInstance().setSp(28),
                              ))
                        ],
                      ),
                    ],
                  )),
            ),
            SizedBox(
              height: ScreenUtil.getInstance().setHeight(30),
            ),
            InkWell(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
              onTap: () {
                setStringValues();
                registration(username, password);
              },
              child: Container(
                width: ScreenUtil.getInstance().setWidth(380),
                padding: EdgeInsets.all(15.0),
                child: Center(
                  child: Text(
                    "Registration",
                    style: TextStyle(
                      fontFamily: "Rubik-Medium",
                      fontSize: 15.0,
                      color: Colors.white,
                      inherit: false,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  String username = "";
  String password = "";

  void setStringValues() {
    username = usernameController.text;
    password = passwordController.text;
  }

  Future<String> login(
      String username, String password, BuildContext context) async {
    var response = await http.get(
        "https://sleepy-hamlet-97922.herokuapp.com/api/login?username=${username}&password=${password}");
    if (response.statusCode == 200) {
      String textFromServer = response.body;
      Map<String, dynamic> data = json.decode(textFromServer);
      String token = data["token"];
      return Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoggedInPage(
                    username: username,
                    token: token,
                  )));
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil.getInstance()..init(context);
    ScreenUtil.instance =
        ScreenUtil(width: 750, height: 1334, allowFontScaling: true);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 380,
              height: ScreenUtil.getInstance().setHeight(500),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0.0, 15.0),
                        blurRadius: 15.0),
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, -10.0),
                      blurRadius: 10.0,
                    ),
                  ]),
              child: Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Login",
                          style: TextStyle(
                            fontSize: ScreenUtil.getInstance().setSp(45),
                            fontFamily: "Poppings-Bold",
                            letterSpacing: .6,
                          )),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Text("Username",
                          style: TextStyle(
                            fontFamily: "Poppins-Medium",
                            fontSize: ScreenUtil.getInstance().setSp(26),
                          )),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                            hintText: "username",
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 12.0)),
                      ),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Text("Password",
                          style: TextStyle(
                            fontFamily: "Poppins-Medium",
                            fontSize: ScreenUtil.getInstance().setSp(26),
                          )),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                            hintText: "password",
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 12.0)),
                      ),
                      SizedBox(
                        height: ScreenUtil.getInstance().setHeight(30),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text("New Account",
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: "Poppins-Medium",
                                fontSize: ScreenUtil.getInstance().setSp(28),
                              ))
                        ],
                      ),
                    ],
                  )),
            ),
            SizedBox(
              height: ScreenUtil.getInstance().setHeight(30),
            ),
            InkWell(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
              onTap: () {
                setStringValues();
                login(username, password, context);
              },
              child: Container(
                width: ScreenUtil.getInstance().setWidth(380),
                padding: EdgeInsets.all(15.0),
                child: Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: "Rubik-Medium",
                      fontSize: 15.0,
                      color: Colors.white,
                      inherit: false,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
