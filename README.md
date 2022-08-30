# Stacked Todo App Tutorial

Before starting this app, I advise everyone to head over to the page below to read/learn all about the Stacked architecture and how it works before you begin to code anything related to this Todo application.

[Flutter/App Setup Documentation](https://github.com/jordandadams/stacked_app_tutorial)

# Reason For This Tutorial:

The reason behind this tutorial is to get a full understanding of the Stacked architecture and how get_it is used for “getting” services within this app.

# Packages Used in This Tutorial:

1. **stacked** - Our state management solution.
2. **get_it** - Helps with dependency injection or services. To keep things simple, we will use this package for “getting” services within the app.
3. **hive** - Package that uses local storage of the device to store Todos within the application.
4. **hive_flutter** - Same as above package

Run the following command to install all the packages to your `pubspec.yaml` file easily.

```dart
flutter pub add get_it hive hive_flutter stacked
```

# Creating The Todo Model:

To keep things simple, a Todo will be a Dart class with just three properties:

1. `id` : Uniquely identifying string for each Todo
2. `completed` : Boolean value to indicate the status of the Todo
3. `content` : The actual text content of the Todo

Now, we need to create a folder following the folder structure of Stacked and the MVVM pattern. Inside the `lib` folder created a folder called `models` . Once done, create a file called `todo.dart` 

Now inside that file, paste the following code into the `lib/models/todo.dart` file:

```dart
class Todo {
  final String id; // string for each Todo
  bool completed; // Status of Todo
  String content; // content for each Todo

  Todo({required this.id, this.completed = false, this.content = ''});
}
```

Things to note here are the `id` property is required for each Todo. However, by default, we want the Todos to **NOT** be completed and make sure it has **empty** content.

# Create The TodoAdapter (for Hive)

Hive works well with primitive types (like bools, ints, strings, and so on), but to properly retrieve and save custom types (like our Todo model) from and to browser or device storage, Hive needs us to create adapters for our custom types.

Now, let’s create a file named `todo.adapter.dart` in the `lib/models` folder. The `todo.adapter.dart` should accompany the `todo.dart` file.

Now that is complete, paste the following code in the newly created `todo.adapter.dart` file:

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'todo.dart';

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 1;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      id: fields[0] as String,
      completed: fields[1] as bool,
      content: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.content);
  }
}
```

The above code is providing read and write methods for hive to retrieve and store a Todo. Feel free to head over to [pub.dev](http://pub.dev) to read more about the Hive package.

# Create The TodosService:

Create a new folder with the name `services` inside the `lib` folder. Inside this newly created `services` folder, create a new file with the name `todos.service.dart` .

Paste the following code into the newly created `lib/services/todos.services.dart` file.

```dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stacked/stacked.dart';
import '../models/todo.dart';

class TodosService with ReactiveServiceMixin {
  final _todos = ReactiveValue<List<Todo>>(
    Hive.box('todos').get('todos', defaultValue: []).cast<Todo>(),
  );
  final _random = Random();

  List<Todo> get todos => _todos.value;

  TodosService() {
    listenToReactiveValues([_todos]);
  }

  String _randomId() {
    return String.fromCharCodes(
      List.generate(10, (_) => _random.nextInt(33) + 80),
    );
  }

  void _saveToHive() => Hive.box('todos').put('todos', _todos.value);

  void newTodo() {
    _todos.value.insert(0, Todo(id: _randomId()));
    _saveToHive();
    notifyListeners();
  }

  bool removeTodo(String id) {
    final index = _todos.value.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos.value.removeAt(index);
      _saveToHive();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  bool toggleStatus(String id) {
    final index = _todos.value.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos.value[index].completed = !_todos.value[index].completed;
      _saveToHive();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  bool updateTodoContent(String id, String text) {
    final index = _todos.value.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos.value[index].content = text;
      _saveToHive();
      return true;
    } else {
      return false;
    }
  }
}
```

# Understanding Reactive Services in Stacked:

The TodosService class declaration comes with `ReactiveServiceMixin`. This is where Staked features start coming in.

With Stacked, services by default are not reactive. However, you need to make a service reactive if any other parts of the project code (other services or ViewModels) have to “react” to changes in the values of the service.

If a service is reactive, that is, has the `ReactiveServiceMixin` , it means that the service will have at least one `ReactiveValue` amoungst its properties. It also means that the service has to call `listenToReactiveValues` with a list of the reactive values in that service.

The idea behind reactivity is that when the reactive values change (either from user interaction or your backend server), the service can update listeners of that value that there are changes. In turn, these listeners can rebuild UIs just as if `setState` was called from within the widget.

# About The TodosService Class:

In our case, the TodosService class has only one private reactive `_todos` field. The `_todos` keeps a `ReactiveValue` of TodoList. This private reactive `_todos` is also given to the list of reactive values to listen to in the constructor (`listenToReactiveValues`).

This is where Hive comes in. With Hive, you store data as a key-value pair inside boxes. For our app, we are using a ‘todos’ box. Inside that box, we are using ‘todos’ key to retrieve stored `todos` .

```dart
Hive.box('todos').get('todos', defaultValue: []).cast<Todo>(),
```

The empty list (`[]` ) defaultValue is necessary. For the first time, the Todo App is run on a device that had never stored `todos` before, so the empty list will be returned instead.

Casting the retrieved value as a Todo object is also import (`.cast<Todo>()` ). If you omit that step, Flutter will throw errors.

The TodosService class also provides a `todos` getter for accessing the value of the private reactive TodoList (`_todos.value`).

```dart
List<Todo> get todos => _todos.value;
```

The TodosService class also provides methods for manipulating Todos and their properties (`removeTodo` , `toggleStatus` , and `updateTodoContent` ). Each of these methods takes the Todo’s `id` and uses the `id` to carry out the appropriate action.

Notice that all these methods call the private `_saveToHive()` method. The reason is whenever `todos` are updated, the updates are saved to our local storage with hive. So that if the app is closed an re-opened, the latest state of `todos` will be loaded back.

Also notice that these methods call `notifyListeners()`. It is part of the idea behind having only a getter for `todos` (and no setter). So that whenever there are updates (from these methods), we can call `notifyListeners()` (if need be) and do appropriate logic (like `_saveToHive` ).

`notifyListeners()` is the equivalent of `setState()` but this time not inside a StatefulWidget. It tells possible listeners (like the upcoming TodosScreenViewModel) that the `todos` getter has changed. in turn, the ViewModel will rebuild the UI of its view and render the new state of the `todos` .

It is worth pointing out that `updateTodoContent` doesn’t call `notifyListeners()` . We will point out the reason why when we build the UI of the TodosScreenView.

Notice the private `_randomId()` method that returns a random string of 10 characters. The `newTodo()` method uses `_randomId()` to set the `id` of a new Todo and inserts that new Todo at the beginning of the TodoList.

If you want new Todos to be added at the end of the list, use `_todos.value.add(Todo(id: _*randomId()));` instead of* `todos.value.insert(0, Todo(id: _randomId()));` in the `newTodo()` method.

The entire above pattern is using a service that introduces code structure and makes the code easier to read (compared to if everything was in a widget).

This service pattern becomes very useful if we were saving the `todos` to some external API and fetching them back on app load. However, that will be beyond the scope of simply introducing Stacked Architecture.

# Setup The Service Locator:

Create a new folder with the name `app` inside the `lib` folder. Inside this newly created `app` folder, create a new file with the name `locator.dart` .

Paste the following code into the newly created `lib/app/locator.dart` file:

```dart
import 'package:get_it/get_it.dart';
import '../services/todos.service.dart';

final locator = GetIt.instance;

setupLocator() {
  locator.registerLazySingleton(() => TodosService());
}
```

Here, out of convention, we named the `GetIt` instance `locator` . After all, that name reflects what it does. It locates services. Other developers might want to use `getIt` or some other descriptive name for this service locator.

We have a `setupLocator()` function that registers our TodosService with the locator. If we had other services, we would register them here in a similar way.

We need to call the `setupLocator()` function before the entire Flutter app launches. This way the services are available to any widgets that the Flutter app will need.

Delete the entire contents of the `lib/main.dart` file and paste the following code inside that file:

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/locator.dart';
import 'models/todo.adapter.dart';
import 'ui/views/todos_screen_view.dart'; // Read below about error

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  await Hive.openBox('todos');

  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TodosScreenView(), // Read below about error
      theme: ThemeData.dark(),
      title: 'Flutter Stacked Todos Tutorial'
    );
  }
}
```

`WidgetsFlutterBinding.ensureInitialized()` is the first statement in the same `main` method.

In simple terms, we use this statement because Flutter asks us to always include it as the first thing in the `main` method anytime we want to do some other stuff (like `Hive.initFlutter()` or `setupLocator()` before launching the Flutter app with `runApp()` .

Notice that we are initializing Hive, registering the TodoAdapter, and opening the ‘todos’ box in the `main` method. This is the last part of setting up Hive.

Also notice that we are now calling the `setupLocator()` function inside the `main` method and before the final `runApp` call to launch the Flutter app.

We used dark theme in our MaterialApp by setting the `theme` property to `ThemeData.dark()`. This dark theme is just for styling - you can remove it if you prefer the default light theme. You can also customize the app’s theme as you wish.

Our `lib/main.dart` file currently has errors. The error is that  the `TodosScreenView` widget does not exist yet and we need to set it as the `home` property of our MaterialApp.

If you are using a VS Code, you will see that the code about has error. The next section will cover how to fix these.

# Building The Todo App UI:

## Different Types of ViewModels:

We covered this in the main page linked at the top of the page for the full walkthrough of the Stacked Architecture, but I will share this information anyways.

in Stacked, think ViewModels first before their Views. This will help you gather the dependencies that the corresponding view needs before actually building the view.

Stacked comes with different ViewModel types. In Stacked, you have BaseViewModels, ReactiveViewModels, FutureViewModels, StreamViewModels, and MultipleFutureViewModels. Use each one based on your current need.

Use ReactiveViewModels if your View or its ViewModels will need to use reactive values from reactive services.

We will use the reactive ViewModel type for our TodosScreenViewModel. We are using a ReactiveViewModel because we will need the reactive `todos` getter in the TodosScreen.

## Create The TodosScreenViewModel:

Create a new folder with the name `ui` inside the `lib` folder. Inside this newly created `ui` folder, create another folder names `todos_screen`. Then inside the new `todos_screen` folder, create a new file with the name `todos_screen_viewmodel.dart` .

Paste the following code inside the newly created `lib/ui/todos_screen_viewmodel.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../app/locator.dart';
import '../../models/todo.dart';
import '../../services/todos.service.dart';

class TodosScreenViewModel extends ReactiveViewModel {
  final _firstTodoFocusNode = FocusNode();
  final _todosService = locator<TodosService>();
  late final toggleStatus = _todosService.toggleStatus;
  late final removeTodo = _todosService.removeTodo;
  late final updateTodoContent = _todosService.updateTodoContent;

  List<Todo> get todos => _todosService.todos;

  void newTodo() {
    _todosService.newTodo();
    _firstTodoFocusNode.requestFocus();
  }

  FocusNode? getFocusNode(String id) {
    final index = todos.indexWhere((todo) => todo.id == id);
    return index == 0 ? _firstTodoFocusNode : null;
  }

  @override
  List<ReactiveServiceMixin> get reactiveServices => [_todosService];
}
```

Notice how we have access to the `todosService` with the help of `locator` . We override the `reaciveServices` getter on ReactiveViewModels and provide the `_todosService` to this list.

That way, whenever `notfiyListeners()` is called inside TodosService, this TodosScreenViewModel will be notified and it will rebuild the UI as necessary.

From TodosScreenViewModel, we expose the `removeTodo` , `toggleStatus`, and `updateTodoContent` methods from the service to the TodosScreenView (which will be created later).

You might wonder why we need to do this. Why not just expose the service itself or rather access the service from the View or widget itself?

The point here is architectural rules and separation of concerns. Remember that the Stacked architecture states that Views should never access services.

Besides, we are doing this because we are keeping things simple. If the app grows bigger than this and we begin to add features to the views, you will realize that the TodosScreenViewModel will have to do other logic before or after making calls to the service’s methods. in that case, we won’t do such direct method exposure.

The is evident in the `newTodo()` method of TodosScreenViewModel. it calls the `_todosService.newTodo()` function to create a new empty Todo. Then it goes ahead and requests focus on the first or just-created Todo’s node (`_firstTodoFocusNode.requestFocus()`).

That way, the cursor will automatically focus on the text input field of the newly created empty Todo after it is created. You will see this in action when we create the TodosScreenView.

### Note on the `late` keyword

The `late` keyword attached to the directly exposed service methods is necessary.

`late` is a feature from Dart that says we are sure that these methods will be assigned later on (from the service) after the ViewModel has be instantiated.

If you remove the `late` keyword, Dart will complain with “The instance member ‘_todosService’ cant be access in an initializer.” This complaint is valid.

The complaint comes up because, when the TodosScreenViewModel has been instantiated, Dart is not sure if, at the time when it needs to instantiate those exposed methods (that had `late` in front of them), the '_todosService' has completed its initialization to be available for the methods.

Generally, instance members can't self initialize each other. The exception is either using the `late` keyword (as we did) or doing such initialization in the constructor.

Behind the scenes, the `late` keyword delays the initialization of the dependent instance members (in this case, the directly exposed methods) till the independent instance member (in this case, _todosService) has completed its initialization.

We didn't do these initializations in the constructor because it will make the code longer. And besides, it has the same effect as using `late`.

## Create The TodosScreenView:

Create a new file with name `todos_screen_view.dart` inside the `lib/ui/todos_screen` folder. In other words, the `todos_screen_view.dart` file should accompany its ViewModel file: `todos_screen_viewmodel.dart`.

Paste the following into the newly created `lib/ui/todos_screen/todos_screen_view.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'todos_screen_viewmodel.dart';

class TodosScreenView extends StatelessWidget {
  const TodosScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TodosScreenViewModel>.reactive(
      viewModelBuilder: () => TodosScreenViewModel(),
      builder: (context, model, _) => Scaffold(
        appBar: AppBar(title: const Text('Flutter Stacked Todos Tutorial')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            if (model.todos.isEmpty)
              Opacity(
                opacity: 0.5,
                child: Column(
                  children: const [
                    SizedBox(height: 64),
                    Icon(Icons.hourglass_empty, size: 48),
                    SizedBox(height: 16),
                    Text('No todos yet. Click + to add a new one.'),
                  ],
                ),
              ),
            ...model.todos.map((todo) {
              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    todo.completed ? Icons.task_alt : Icons.circle_outlined,
                  ),
                  onPressed: () => model.toggleStatus(todo.id),
                ),
                title: TextField(
                  controller: TextEditingController(text: todo.content),
                  decoration: null,
                  focusNode: model.getFocusNode(todo.id),
                  maxLines: null,
                  onChanged: (text) => model.updateTodoContent(todo.id, text),
                  style: TextStyle(
                    fontSize: 20,
                    decoration:
                        todo.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.horizontal_rule),
                  onPressed: () => model.removeTodo(todo.id),
                ),
              );
            }),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: model.newTodo,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

# About The TodosScreenView

The first line after the declaration of the `build` method is a return statement. This statement returns a `ViewModelBuilder` widget for the TodosScreenViewModel.

This is another aspect of Stacked architecture. It explains what we mean by Views being attached to ViewModels. In essence, we use ViewModelBuilders to render a View.

That way the View has access to the public properties and methods of its ViewModel. Also, calling `notifyListeners()` inside the ViewModel auto-updates the View's UI. Furthermore, most (if not all) UI logic that is not declarative should be moved to the ViewModel.

This explains why we shifted the logic of the first Todo's FocusNode to the TodosScreenViewModel.

The `body` of the TodosScreenView's Scaffold is a `ListView` for all the Todos gotten from `model.todos`.

However, the first member of the ListView is a conditional Opacity widget with 0.5 opacity. Its child is a Column for empty state with spacing, a teacup icon, and Text for children.

We used `ListTile` to display each Todo. It is a convenience widget that takes `leading`, `title`, and `trailing` widgets for the left, center, and right parts of the screen.

The `leading` widget on the ListTile is an IconButton whose icon is either an empty or checked circle depending on if the Todo is completed or not. The `onPressed` callback on the IconButton toggles the status of the Todo.

The `title` (center) widget on the ListTile is a TextField with no decoration. No decoration here means it has no backgrounds, borders, or underlines. The aim is to give the user the feeling that they can just read their Todo content, while at the same time, the ability to edit the content is in the same place.

The `[TextEditingController](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)` given to the TextField is used to set the text content on the field from the content of the Todo. Setting `maxLines` to null on the TextField is telling Flutter that text in the TextField can span across multiple lines.

The `onChanged` callback updates the text content of the attached Todo. This callback is called for every keystroke or edit of text. We are doing this to keep all Todos always in sync with the UI.

We didn't call `notifyListeners()` in this callback (`updateTodoContent`) in the TodosService to prevent the cursor from jumping (given that we are making the call for each keystroke).

If `notifyListeners()` was called in this callback, the UI would be rebuilt each time, and the cursor would keep jumping back to the start of the TextField after each keystroke.

# Run The Todo App:

As every other app works you can either type the following in the command line

```dart
flutter run
```

Or just click `Run` at the top, and run without debugging.

# (Optional) Adding Navigator:
So some of the things we did above was just a tidbit of what the Stacked Architecture has to offer. We originally created an app with only one screen that allows you to add todos, check them off and remove them. Now out goal will be to add navigation throughout different screens in our app.

You will need to configure Navigation or Routing in most if not all applications you’ll build with Flutter. Navigation is a necessity once you have more than one screen in the Flutter App.

Stacked lets you configure an `@StackedApp` decoration on an empty Dart class. This decoration can take routes and dependencies info as in the following snippet:

You will now need to add `build_runner` , `stacked_services` and `stacked_generator` packages to the Flutter `pubspec.yaml` file.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/21bad6b0-cbaf-45a8-852f-ea97edebf0e8/Untitled.png)

Once added we now need to create our routing files, but before we do that let’s create our startup/login view files before hand, so when we test the app we can actually have something to see.

I plan to develop this app a little further as this will be the boiler plate template for my SaveJar production app, so I will title these pages `login_screen_view.dart` and `login_screen_viewmodel.dart` however, for this tutorial it will just show a standard startup view.

If you read through the previous Stacked documentation regarding the Navigation setup, this will be very similar just with slight code changes since we will be using `get_it` .

Anyhow, make sure to continue to follow the architecture we already have setup by creating a new folder called `login` within the `lib/ui` folder structure.

Once you have the folder created along with the new view and view model, paste the following code in the files (please take note of the file name before pasting):

```dart
// login_screen_view.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'login_screen_viewmodel.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LoginScreenViewModel>.reactive(
      builder: (context, model, child) => Scaffold(
        floatingActionButton: FloatingActionButton(onPressed: model.doSomething, child: const Icon(Icons.arrow_forward),),
        body: const Center(
          child: Text('Start Up View, click the button to go to home view'),
        ),
      ),
      viewModelBuilder: () => LoginScreenViewModel(),
    );
  }
}
```

```dart
// login_screen_viewmodel.dart

import 'package:stacked/stacked.dart';
import 'package:stacked_todo/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_todo/app/app.locator.dart';

class LoginScreenViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  String title = '';

  void doSomething() {
    _navigationService.navigateTo(Routes.todosScreenView);
  }
}
```

Perfect, now that we have our view and view model created for the startup screen, we can now begin to create our Navigation.

We currently already have an `app` folder created inside the `lib` folder, so we will want to create a new file called `app.dart` inside the `lib/app` folder.

Once you have that file created, paste the following code inside that newly created `app.dart` file:

```dart
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_todo/ui/login/login_screen_view.dart';
import 'package:stacked_todo/ui/todos_screen/todos_screen_view.dart';

@StackedApp(
  routes: [
    MaterialRoute(page: LoginScreenView, initial: true),
    CustomRoute(page: TodosScreenView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
  ],
)
class App {
  // Serves no purpose yet
}
```

Some things to take notice here is how the initial page we are wanting to use when the app is launched. Notice how `MaterialRoute` is using the `LoginScreenView`  well this is what we use to identify the startup screen.

Directly under `MaterialRoute` you have `CustomRoute` this will hold all your pages you will want to navigation to. Notice we have `TodosScreenView` being passed here.

Okay, now that we have `app.dart` all setup, we can now head over to the `main.dart` page to make some changes to allow the `main.dart` page to load the correct startup page.

Currently we have just the `TodosScreenView` being passed in the `home:` parameter, so we need to change the `main.dart` page to the following code:

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_todo/app/app.router.dart';
import 'app/locator.dart';
import 'models/todo.adapter.dart';
import 'ui/todos_screen/todos_screen_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  await Hive.openBox('todos');

  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      title: 'Flutter Stacked Todos Tutorial',
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
    );
  }
}
```

Notice how we completely removed the `home:` parameter and decided to add `navigatorKey` and `onGenerateRoute` to which we then use both `StackedService` and `StackedRouter` to allow the pages to be displayed based on the `app.dart` file.

Now, head back over to your `app.dart` file and open the terminal. Make sure you are in the app directory before running this command. Inside the terminal, run the following command:

```dart
flutter pub run build_runner build
```

After running this you will notice two files were created. You should now see `app.locator.dart` and `app.router.dart` . These two files were generated from that command. So, anytime you have a new route, just simply run the build_runner command and it will generate it for you.

Now, go ahead and try to run the app.

Did it work?

If so great!

But if you’re like me and ran into a get_it error, I am about to save you hours of fixing, and no Google did not give me this answer unfortunately. 

Remember when we had to initialize our `TodosServie`? Well, we basically need to do the same for `NavigationService` located in our `login_screen_viewmodel.dart` file.

Open up the `locator.dart` file located under `lib/app/locator.dart` and you will notice the line

```dart
final locator = GetIt.instance;
```

Then directly under that you should see a method called `setupLocator` . Currently this method is only initializing the `TodosService` , so in order to get our app to work we must add the `NavigationService` .

Paste the following code into the `locator.dart` file:

```dart
import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';
import '../services/todos.service.dart';

final locator = GetIt.instance;

setupLocator() {
  locator.registerLazySingleton(() => TodosService());
  locator.registerLazySingleton(() => NavigationService());
}
```

Hooray! Now you can run the app.

# Source Code:

You can find the full source code along with this same documentation at the link below:
https://github.com/jordandadams/stacked_todo_app