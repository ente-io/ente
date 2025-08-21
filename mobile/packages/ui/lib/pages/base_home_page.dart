import 'package:flutter/material.dart';

abstract class BaseHomePage extends StatefulWidget {
  const BaseHomePage({super.key});
}

abstract class BaseHomePageState<T extends BaseHomePage> extends State<T> {}
