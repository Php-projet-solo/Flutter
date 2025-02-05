import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
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
  bool isLoadingMore = false;
  String? _errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 30;
  final ScrollController _scrollController = ScrollController();

  final String apiUrl = 'http://192.168.43.19/api/index.php';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loginAndFetchData();
  }

  Future<void> loginAndFetchData() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginResponse = await http.post(
        Uri.parse(apiUrl),
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
          setState(() => _errorMessage = 'Erreur : Token non récupéré.');
        }
      } else {
        setState(() => _errorMessage =
        'Erreur de connexion : ${loginResponse.statusCode} ${loginResponse.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur de connexion : $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEntities({bool loadMore = false}) async {
    if (token == null || isLoadingMore) return;

    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl?action=getEntities&page=$currentPage&limit=$itemsPerPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List newData = json.decode(response.body);

        setState(() {
          if (loadMore) {
            entities.addAll(newData);
            currentPage++;
          } else {
            entities = newData;
          }
        });
      } else {
        setState(() => _errorMessage =
        'Erreur récupération : ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de la récupération : $e');
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      fetchEntities(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Liste des Entités')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : entities.isEmpty
          ? Center(child: Text('Aucune entité trouvée.'))
          : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntity,
        child: Icon(Icons.add),
        tooltip: 'Ajouter une entité',
      ),
    );
  }

  Widget _buildListView() {
    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: entities.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == entities.length) {
            return Center(child: CircularProgressIndicator());
          }

          final entity = entities[index];
          return ListTile(
            title: Text(entity['nom']),
            subtitle: Text(HtmlUnescape().convert(entity['description'])),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(entity: entity),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: loginAndFetchData,
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _addNewEntity() async {
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
  }
}