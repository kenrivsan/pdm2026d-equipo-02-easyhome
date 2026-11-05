import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { home, search, accommodations, owner, settings }

final appNavigationProvider = NotifierProvider<AppNavigation, AppTab>(
  AppNavigation.new,
);

class AppNavigation extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}
