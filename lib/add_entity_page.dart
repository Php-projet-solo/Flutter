import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class AddEntityPage extends StatefulWidget {
  final String token;

  AddEntityPage({required this.token});

  @override
  _AddEntityPageState createState() => _AddEntityPageState();
}

class _AddEntityPageState extends State<AddEntityPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    "id_competition": 24,
    "nom": "",
    "description": "",
    "date": "",
    "prixentree": null,
    "latitude": null,
    "longitude": null,
    "nompersonnecontacter": null,
    "emailcontacter": null,
    "photo": "null",
  };

  File? _imageFile;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez activer la localisation')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission de localisation refusée')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission de localisation refusée définitivement')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _formData['latitude'] = position.latitude;
      _formData['longitude'] = position.longitude;
    });
  }

  Future<void> _selectDateTime() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDate = fullDateTime;
          _formData['date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(fullDateTime);
        });
      }
    }
  }

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    final image = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: camera),
      ),
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image);
        List<int> imageBytes = _imageFile!.readAsBytesSync();
        _formData['photo'] = base64Encode(imageBytes);
      });
    }
  }

  Future<void> addEntity() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : Token non disponible.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.88/api/index.php'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(_formData),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur HTTP ${response.statusCode}: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une Entité'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom'),
                onSaved: (value) => _formData['nom'] = value,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => _formData['description'] = value,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Prix d\'entrée (€)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _formData['prixentree'] = value != null && value.isNotEmpty ? double.tryParse(value) : null,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom du contact'),
                onSaved: (value) => _formData['nompersonnecontacter'] = value,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email du contact'),
                onSaved: (value) => _formData['emailcontacter'] = value,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? "Date sélectionnée : ${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate!)}"
                          : "Aucune date sélectionnée",
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDateTime,
                  ),
                ],
              ),
              SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _openCamera,
                icon: Icon(Icons.camera_alt),
                label: Text("Prendre une photo"),
              ),
              SizedBox(height: 20),

              _imageFile != null
                  ? Image.file(_imageFile!, height: 100)
                  : Text("Aucune image sélectionnée."),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Veuillez sélectionner une date.')),
                      );
                      return;
                    }

                    if (_imageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Veuillez prendre une photo.')),
                      );
                      return;
                    }

                    _formKey.currentState!.save();
                    addEntity();
                  }
                },
                child: Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    await _initializeControllerFuture;
    final image = await _controller.takePicture();
    Navigator.pop(context, image.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Prendre une photo")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? Stack(children: [
            CameraPreview(_controller),
            Positioned(bottom: 20, left: MediaQuery.of(context).size.width / 2 - 30,
                child: FloatingActionButton(onPressed: _takePicture, child: Icon(Icons.camera))),
          ])
              : Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
