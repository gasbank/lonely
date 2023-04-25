import 'package:flutter/material.dart';

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          color: Colors.black12,
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                width: 100,
                height: 100,
                top: selected ? 0.0 : 100.0,
                left: selected ? 0.0 : 100.0,
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selected = !selected;
                    });
                  },
                  child: Container(
                    color: Colors.blue,
                    child: Center(child: Image.network('https://storage.googleapis.com/dartlang-pub--pub-images/flame/1.7.3/gen/190x190/logo.webp')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
