import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  // Register the adapter
  Hive.registerAdapter(TodoItemAdapter());

  // Initialize Hive
  await Hive.initFlutter();
  var box = await Hive.openBox('database');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TodoList(),
    theme: ThemeData(scaffoldBackgroundColor: Colors.redAccent),
  ));
}

class TodoItem {
  late String title;
  late bool isCompleted;

  TodoItem(this.title, this.isCompleted);
}

class TodoItemAdapter extends TypeAdapter<TodoItem> {
  @override
  final int typeId = 0; // Unique identifier for the adapter

  @override
  TodoItem read(BinaryReader reader) {
    return TodoItem(
      reader.readString(),
      reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.isCompleted);
  }
}

class TodoDB {
  List todoList = [];
  final box = Hive.box('database');

  void loadList() {
    todoList = box.get('todolist', defaultValue: []);
  }

  void updateList() {
    box.put('todolist', todoList);
  }
}

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  var box = Hive.box('database');
  TodoDB db = TodoDB();

  void addList(String title) {
    setState(() {
      db.todoList.add(TodoItem(title, false));
    });
    db.updateList();
  }

  void deleteList(int index) {
    setState(() {
      db.todoList.removeAt(index);
    });
    db.updateList();
  }

  void isComplete(int index) {
    setState(() {
      db.todoList[index].isCompleted = !db.todoList[index].isCompleted;
    });
    db.updateList();
  }

  void _listDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _list = TextEditingController();
        return AlertDialog(
          title: Text('Add Item'),
          content: TextField(
            controller: _list,
            decoration: InputDecoration(hintText: 'Enter a list'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_list.text.isNotEmpty) {
                  addList(_list.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    db.loadList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        centerTitle: true,
      ),
      body: db.todoList.isEmpty
          ? Center(child: Text('No todos available'))
          : ListView.builder(
        itemCount: db.todoList.length,
        itemBuilder: (context, index) {
          final item = db.todoList[index];
          return ListTile(
            leading: Checkbox(
              value: item.isCompleted,
              onChanged: (bool? value) {
                setState(() {
                  isComplete(index);
                });
              },
            ),
            title: Text(
              item.title,
              style: TextStyle(
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                deleteList(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}