import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_con_database_9624/screen/screen_Signin.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;
  late TextEditingController _statusController;

  final List<String> _myList = [];

  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();
    _statusController = TextEditingController();
  }

  void addTodoHandle(BuildContext context) {
    _texteditController.clear();
    _descriptionController.clear();
    _statusController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Note"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Status"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                CollectionReference tasks =
                    FirebaseFirestore.instance.collection("tasks");
                tasks.add({
                  'name': _texteditController.text,
                  'note': _descriptionController.text,
                  'status': _statusController.text,
                }).then((res) {
                  print("Task added: ${res.id}");
                }).catchError((onError) {
                  print("Failed to add new Task: $onError");
                });
                setState(() {
                  _myList.add(_texteditController.text);
                });
                _texteditController.clear();
                _descriptionController.clear();
                _statusController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void editTodoHandle(BuildContext context, DocumentSnapshot doc) {
    _texteditController.text = doc["name"];
    _descriptionController.text = doc["note"];
    _statusController.text = doc["status"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Note"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Status"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("tasks")
                    .doc(doc.id)
                    .update({
                  'name': _texteditController.text,
                  'note': _descriptionController.text,
                  'status': _statusController.text,
                }).then((res) {
                  print("Task updated: ${doc.id}");
                }).catchError((onError) {
                  print("Failed to update Task: $onError");
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteTodoHandle(String taskId) {
    FirebaseFirestore.instance.collection("tasks").doc(taskId).delete().then(
        (res) {
      print("Task deleted: $taskId");
    }).catchError((onError) {
      print("Failed to delete Task: $onError");
    });
  }

  // ฟังก์ชันสำหรับ handle logout
  void _logout() {
    // เมื่อล็อกเอาต์สำเร็จให้กลับไปที่หน้าจอเข้าสู่ระบบ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        automaticallyImplyLeading: false, // เอาลูกศรออก
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
                return const Center(child: Text("No data"));
              }
              return ListView.builder(
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data?.docs[index];
                  return ListTile(
                    title: Text(doc?["name"] ?? "No name"),
                    subtitle: Text(
                      'Note: ${doc?["note"] ?? "No note"}\nStatus: ${doc?["status"] ?? "No status"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            editTodoHandle(context, doc!);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteTodoHandle(doc!.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // ปุ่ม logout อยู่ที่มุมซ้ายล่างของจอ
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text( "Logout",
                style: TextStyle(color: Colors.black), // กำหนดให้ข้อความสีดำ
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // สีของปุ่ม
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
