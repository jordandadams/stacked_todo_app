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