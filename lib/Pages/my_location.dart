// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// class MyLocation extends StatefulWidget {
//   const MyLocation({super.key});
//
//   @override
//   State<MyLocation> createState() => _MyLocationState();
// }
//
// class _MyLocationState extends State<MyLocation> {
//
//   final Color myColor = Color.fromRGBO(128,178,247, 1);
//
//   String coordinates="No Location found";
//   String address='No Address found';
//   bool scanning=false;
//
//   checkPermission()async{
//
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled=await Geolocator.isLocationServiceEnabled();
//
//     print(serviceEnabled);
//
//     if (!serviceEnabled){
//       await Geolocator.openLocationSettings();
//       return ;
//     }
//
//
//     permission=await Geolocator.checkPermission();
//
//     print(permission);
//
//     if (permission==LocationPermission.denied){
//
//       permission=await Geolocator.requestPermission();
//
//       if (permission==LocationPermission.denied){
//         Fluttertoast.showToast(msg: 'Request Denied !');
//         return ;
//       }
//
//     }
//
//     if(permission==LocationPermission.deniedForever){
//       Fluttertoast.showToast(msg: 'Denied Forever !');
//       return ;
//     }
//
//     getLocation();
//
//   }
//
//   getLocation()async{
//
//     setState(() {scanning=true;});
//
//     try{
//
//       Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//
//       coordinates='Latitude : ${position.latitude} \nLongitude : ${position.longitude}';
//
//       List<Placemark> result  = await placemarkFromCoordinates(position.latitude, position.longitude);
//
//       if (result.isNotEmpty){
//         address='${result[0].name}, ${result[0].locality} ${result[0].administrativeArea}';
//       }
//
//
//     }catch(e){
//       Fluttertoast.showToast(msg:"${e.toString()}");
//     }
//
//     setState(() {scanning=false;});
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           SizedBox(height: 100,),
//           Image.asset('images/l2.png'),
//
//           SizedBox(height: 20,),
//           Text('Current Coordinates',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700,color: Colors.grey),),
//           SizedBox(height: 20,),
//
//           scanning?
//           SpinKitThreeBounce(color: myColor,size: 20,):
//           Text('${coordinates}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black),),
//
//           SizedBox(height: 20,),
//           Text('Current Address',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700,color: Colors.grey),),
//           SizedBox(height: 20,),
//
//           scanning?
//           SpinKitThreeBounce(color: myColor,size: 20,):
//           Text('${address}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black),),
//
//           Spacer(),
//           Center(
//             child: ElevatedButton.icon(
//               onPressed: (){checkPermission();},
//               icon: Icon(Icons.location_pin,color: Colors.white,),
//               label: Text('Current Location',style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),
//
//             ),
//           ),
//
//           Spacer(),
//         ],
//       ),
//     );
//   }
// }