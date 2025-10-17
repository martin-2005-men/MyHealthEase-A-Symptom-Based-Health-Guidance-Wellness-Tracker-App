//Create the data
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Operations{

  final CollectionReference obj =
  FirebaseFirestore.instance.collection("USER");


  Future<void> create(String name,String age, String email,String password){
    return obj.add({
      "Name":name,
      "Age":age,
      "Email":email,
      "password":password,
    });
  }
//Stream<QuerySnapshot> dispaly{
  String userName="";
  Future<void> getCurrentUserName() async{
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance.collection("USER").doc(uid).get().then((snapshot){
      if(snapshot.exists) {
        userName = (snapshot.data() as Map<String, dynamic>)['Name'].toString();
      }
      else{
        print("USER DOES NOT EXISTS");
      }
    }).catchError((error){
      print("Error fetching user name:$error");
    });
}

}







