// Importaciones
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TareasApp());
}

class TareasApp extends StatelessWidget {
  const TareasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tareas App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TareasHomePage(),
    );
  }
}

class Tarea {
  final String texto;
  final String fecha;

  Tarea({required this.texto, required this.fecha});

  Map<String, dynamic> toJson() => {'texto': texto, 'fecha': fecha};

  factory Tarea.fromJson(Map<String, dynamic> json) =>
      Tarea(texto: json['texto'], fecha: json['fecha']);
}

class TareasHomePage extends StatefulWidget {
  const TareasHomePage({super.key});

  @override
  State<TareasHomePage> createState() => _TareasHomePageState();
}

class _TareasHomePageState extends State<TareasHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();

  List<Tarea> _tareas = [];
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarTareas();
    _busquedaController.addListener(() {
      setState(() {
        _terminoBusqueda = _busquedaController.text.toLowerCase();
      });
    });
  }

  Future<void> _cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('tareas') ?? [];

    setState(() {
      _tareas = data.map((item) => Tarea.fromJson(json.decode(item))).toList();
    });
  }

  Future<void> _guardarTarea(String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final ahora = DateTime.now();
    final fechaFormateada =
        "${ahora.day}/${ahora.month}/${ahora.year} ${ahora.hour}:${ahora.minute}";

    final nuevaTarea = Tarea(texto: texto, fecha: fechaFormateada);

    setState(() {
      _tareas.add(nuevaTarea);
    });

    final data = _tareas.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList('tareas', data);
    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea guardada')),
    );
  }

  Future<void> _eliminarTarea(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tareas.removeAt(index);
    });
    final data = _tareas.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList('tareas', data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea eliminada')),
    );
  }

  Future<void> _editarTarea(int index) async {
    final tarea = _tareas[index];
    _controller.text = tarea.texto;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Tarea'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Texto de la tarea'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _controller.clear();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final ahora = DateTime.now();
                final nuevaFecha =
                    "${ahora.day}/${ahora.month}/${ahora.year} ${ahora.hour}:${ahora.minute}";

                setState(() {
                  _tareas[index] =
                      Tarea(texto: _controller.text, fecha: nuevaFecha);
                });

                final data =
                    _tareas.map((t) => json.encode(t.toJson())).toList();
                await prefs.setStringList('tareas', data);

                Navigator.of(context).pop();
                _controller.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarea editada')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tareasFiltradas = _tareas
        .where((t) => t.texto.toLowerCase().contains(_terminoBusqueda))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _guardarTarea(_controller.text);
                }
              },
              child: const Text('Guardar tarea'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _busquedaController,
              decoration: const InputDecoration(
                labelText: 'Buscar tarea',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tareasFiltradas.isEmpty
                  ? const Center(child: Text('No se encontraron tareas.'))
                  : ListView.builder(
                      itemCount: tareasFiltradas.length,
                      itemBuilder: (context, index) {
                        final tarea = tareasFiltradas[index];
                        final originalIndex = _tareas.indexOf(tarea);
                        return Card(
                          child: ListTile(
                            title: Text(tarea.texto),
                            subtitle: Text("Creada el ${tarea.fecha}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () {
                                    _editarTarea(originalIndex);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _eliminarTarea(originalIndex);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
