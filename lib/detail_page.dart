import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final Map entity;

  DetailPage({required this.entity});

  @override
  Widget build(BuildContext context) {
    String base64Image = entity['photo'];
    Uint8List bytes = base64Decode(base64Image);

    return Scaffold(
      appBar: AppBar(
        title: Text(entity['nom']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id: ${entity['id_competition']}'),
            Text('Nom: ${entity['nom']}'),
            Text('Description: ${entity['description']}'),
            Text('Date: ${entity['date']}'),
            Text('Prix: ${entity['prixentree']}€'),
            Text('Latitude: ${entity['latitude']}'),
            Text('Longitude: ${entity['longitude']}'),
            Text('Contact: ${entity['nompersonnecontacter']}'),
            Text('Email: ${entity['emailcontacter']}'),
            Text('Photo:'),
            Image.memory(bytes),
          ],
        ),
      ),
    );
  }
}