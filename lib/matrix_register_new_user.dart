
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> registerUser() async {
  var username = "test";
  var password = "test";
  var serverLocation = "http://localhost:8008"; // your synapse server ip or domain name
  var sharedSecret = "125364342esfgasdagfasda"; // get from homeserver.yaml => equal: registration_shared_secret

   var account = await create_account(username, password, serverLocation, sharedSecret);
   print(account);
   return account.user_id;
}

class UserMatrix {
  final String user_id;
  final String home_server;
  final String access_token;
  final String device_id;

  UserMatrix({
    required this.user_id,
    required this.home_server,
    required this.access_token,
    required this.device_id,
  });

  factory UserMatrix.fromJson(Map<String, dynamic> json) {
    return UserMatrix(
      user_id: json['user_id'] as String,
      home_server: json['home_server'] as String,
      access_token: json['access_token'] as String,
      device_id: json['device_id'] as String,
    );
  }
}

Future<UserMatrix> create_account(userName, password, serverLocation, sharedSecret,
    {bool admin = false}) async {

  final nonce = await _get_nonce(serverLocation);

  var bytes = utf8.encode(sharedSecret);
  final hmac = Hmac(sha1, bytes);
  final mac = hmac
      .convert(utf8.encode(nonce +
      '\x00' +
      userName +
      '\x00' +
      password +
      '\x00' +
      'notadmin'))
      .toString();

  Map<String, dynamic> jsonData = {
    'nonce': nonce,
    'username': userName,
    'password': password,
    'mac': mac,
  };

  http.Response response = await http.post(
      Uri.parse(serverLocation + '/_synapse/admin/v1/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(jsonData));
  if (response.statusCode == 200) {
     return UserMatrix.fromJson(jsonDecode(response.body));
  }else{
    return null!;
  }
}

Future<String> _get_nonce(String server_location) async {
  String url = server_location + "/_synapse/admin/v1/register";
  final response = await http.get(Uri.parse(url));

  var responseData = json.decode(response.body);
  return responseData["nonce"] as String;
}

