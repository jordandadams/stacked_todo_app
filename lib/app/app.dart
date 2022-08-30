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