import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final Map entity;

  DetailPage({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entity['nom']),
      ),
      body: Padding(
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
            Text('Photo: ${entity['photo']}'),
          ],
        ),
      ),
    );
  }
}