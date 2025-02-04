import 'package:flutter/material.dart';
import 'detail_page.dart';
import 'add_entity_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List entities = [];
  String? token;
  bool isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loginAndFetchData();
  }

  Future<void> loginAndFetchData() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginResponse = await http.post(
        Uri.parse('http://192.168.1.88/api/index.php'),
        body: json.encode({
          'action': 'login',
          'username': 'admin',
          'password': 'password'
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (loginResponse.statusCode == 200) {
        final data = json.decode(loginResponse.body);
        token = data['token'];

        if (token != null) {
          fetchEntities();
        } else {
          setState(() {
            _errorMessage = 'Erreur : Token non récupéré.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
          'Erreur de connexion : ${loginResponse.statusCode} ${loginResponse.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion : $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEntities() async {
    if (token == null) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.88/api/index.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          entities = json.decode(response.body);
        });
      } else {
        setState(() {
          _errorMessage =
          'Erreur récupération : ${response.statusCode} ${response.body} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la récupération : $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Entités'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loginAndFetchData,
              child: Text('Réessayer'),
            ),
          ],
        ),
      )
          : entities.isEmpty
          ? Center(child: Text('Aucune entité trouvée.'))
          : ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final entity = entities[index];
          return ListTile(
            title: Text(entity['nom']),
            subtitle: Text(entity['description']),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(entity: entity),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur : Token non disponible.')),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEntityPage(token: token!)),
          );

          if (result == true) {
            fetchEntities();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Ajouter une entité',
      ),
    );
  }
}
