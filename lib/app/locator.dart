import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';
import '../services/todos.service.dart';

final locator = GetIt.instance;

setupLocator() {
  locator.registerLazySingleton(() => TodosService());
  locator.registerLazySingleton(() => NavigationService());
}