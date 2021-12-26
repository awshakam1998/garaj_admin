import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:garaj_admin/parks_manager_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  String message='';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:  [
              const Text('Parks Manager',style:  TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.red),),
              const SizedBox(height: 20,),
              Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Enter the key to login!',style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600),),
                  ),
                ],
              ),
               Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    if(value=="admin123"){
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ParksManagerScreen()), (route) => false);
                    }else if(value.isEmpty){
                      setState(() {
                        message='';
                      });
                    }else{
                      setState(() {
                        message='Invalid Key!';
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    border:  OutlineInputBorder(),
                    label:  Text('Key'),
                  ),
                ),
              ),
              Row(
                children:  [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(message,style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: Colors.red),),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
