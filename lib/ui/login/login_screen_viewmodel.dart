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