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
    home: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("https://img.freepik.com/free-photo/gray-painted-background_53876-94041.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        TodoList(),
      ],
    ),
    theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
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
          title: Text('Add Note',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),),
          content: TextField(
            controller: _list,
            decoration: InputDecoration(hintText: 'Enter Note'),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.pink[200]!),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_list.text.isNotEmpty) {
                  addList(_list.text);
                  Navigator.pop(context);
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green[400]!),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),

              ),
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
        title: Text(
          'To-do List',
          style: TextStyle(
            color: Colors.black, // Change text color here
            fontWeight: FontWeight.bold, // Change font weight here
            fontSize: 26, // Change font size here
            // You can add more TextStyle properties as needed
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink[100],
      ),
      body: db.todoList.isEmpty
          ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.network(
                  'https://static.wixstatic.com/media/c177c1_32f3193b310e4d088accb3367d098727~mv2.gif', width: 200, height: 200),
              // Customize the size as needed
              Text('No to-do lists available.',
                  style: TextStyle(fontSize: 25, color: Colors.black))
            ],
          )
      ) // Image displayed when there is no item in the list
          : Padding(
        padding: const EdgeInsets.all(14.0),
        child: ListView.builder(
          itemCount: db.todoList.length,
          itemBuilder: (context, index) {
            final item = db.todoList[index];
            return Card(
              elevation: 3, // Adjust the elevation as needed for your design
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Adjust margin as needed
              child: ListTile(
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
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteList(index);
                  },
                ),
              ),
            );


          },
        ),
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