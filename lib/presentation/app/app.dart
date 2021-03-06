import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_bloc.dart';
import '../../application/page/page_bloc.dart';
import '../../application/theme/bloc/theme_bloc.dart';
import '../../infrastructure/core/urls.dart' as url;
import '../common/accent_button.dart';
import '../core/adaptive_dialog.dart';
import '../core/adaptive_scaffold.dart';
import '../core/constants.dart';
import '../core/extensions.dart';
import '../core/utils/custom_icons_icons.dart';
import '../core/utils/url_handler.dart';
import '../sign_in/sign_in_page.dart';
import 'components/app_page.dart';
import 'components/error_listener.dart';

@immutable
class _AppDesitination {
  final AdaptiveScaffoldDestination destination;
  final PageState page;

  const _AppDesitination({
    @required this.destination,
    @required this.page,
  });
}

class App extends StatefulWidget {
  const App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  List<_AppDesitination> get _destinations => const [
        _AppDesitination(
          destination: AdaptiveScaffoldDestination(
            title: 'Home',
            icon: Icons.home,
          ),
          page: PageState.home,
        ),
        // _AppDesitination(
        //   destination: AdaptiveScaffoldDestination(
        //     title: 'YouTube Videos',
        //     icon: CustomIcons.youtube,
        //   ),
        //   page: PageState.packages,
        // ),
        _AppDesitination(
          destination: AdaptiveScaffoldDestination(
            title: 'Blog Posts',
            icon: Icons.description,
          ),
          page: PageState.blog,
        ),
        // _AppDesitination(
        //   destination: AdaptiveScaffoldDestination(
        //     title: 'Courses',
        //     icon: Icons.school,
        //   ),
        //   page: PageState.packages,
        // ),
        _AppDesitination(
          destination: AdaptiveScaffoldDestination(
            title: 'Contact Us',
            icon: Icons.contact_phone,
          ),
          page: PageState.contact,
        ),
      ];

  void _onNavigation(
    int index,
  ) {
    BlocProvider.of<PageBloc>(context).add(
      PageEvent.update(_destinations[index].page),
    );
  }

  void _homePressed() {
    BlocProvider.of<PageBloc>(context).add(
      const PageEvent.update(PageState.home),
    );
  }

  int _getPageIndex(PageState page) {
    return _destinations.indexWhere((element) => element.page == page);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorListener(
      child: BlocBuilder<PageBloc, PageState>(
        builder: (context, pageState) {
          return AdaptiveScaffold(
            currentIndex: _getPageIndex(pageState),
            destinations: _destinations.map((e) => e.destination).toList(),
            onNavigationIndexChange: (index) {
              _onNavigation(index);
            },
            homePressed: _homePressed,
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: _SubscribeButton(),
              ),
              _BrightnessButton(),
              _MoreButton()
            ],
            body: const AppPage(),
          );
        },
      ),
    );
  }
}

class _BrightnessButton extends StatelessWidget {
  const _BrightnessButton({Key key}) : super(key: key);

  void _changeTheme(BuildContext context) {
    context.bloc<ThemeBloc>().add(const ThemeEvent.switchTheme());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return IconButton(
          icon: state.map(
            light: (_) => const Icon(Icons.brightness_2),
            dark: (_) => const Icon(Icons.wb_sunny),
          ),
          onPressed: () {
            _changeTheme(context);
          },
        );
      },
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    Key key,
  }) : super(key: key);

  static const Size _buttonSize = Size(168, 54);

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: context.mediaSize.width > kTabletBreakpoint,
      child: Center(
        child: SizedBox(
          width: _buttonSize.width,
          height: _buttonSize.height,
          child: AccentButton(
            label: 'Subscribe on YouTube',
            onPressed: () {
              launchURL(url.funWithYouTubeSubscribeUrl);
            },
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatefulWidget {
  const _MoreButton({
    Key key,
  }) : super(key: key);

  @override
  __MoreButtonState createState() => __MoreButtonState();
}

class __MoreButtonState extends State<_MoreButton> {
  bool isAuthenticated = false;

  void _signInPressed() {
    if (context.mediaSize.width >= kTabletBreakpoint) {
      showModal<SignInPage>(
        context: context,
        configuration: const FadeScaleTransitionConfiguration(),
        builder: (BuildContext context) {
          return const AdaptiveDialog(
            child: SignInPage(),
          );
        },
      );
    } else {
      ExtendedNavigator.of(context).push(
        MaterialPageRoute<SignInPage>(
          fullscreenDialog: true,
          builder: (_) => const SignInPage(),
        ),
      );
    }
  }

  void _signOutPressed() {
    BlocProvider.of<AuthBloc>(context).add(const AuthEvent.signOut());
  }

  void _select(_PopupMenuOptions menu) {
    if (isAuthenticated) {
      _signOutPressed();
    } else {
      _signInPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        isAuthenticated = state.map(
          initial: (_) => false,
          authenticated: (_) => true,
          unauthenticated: (_) => false,
        );
        return PopupMenuButton(
          offset: const Offset(0, 100),
          elevation: 3.2,
          initialValue: _choices[0],
          tooltip: 'Additional options',
          onSelected: _select,
          itemBuilder: (BuildContext context) {
            return _choices.map((_PopupMenuOptions choice) {
              return PopupMenuItem(
                value: choice,
                child: isAuthenticated
                    ? const _MenuOptionText(label: 'Sign Out')
                    : const _MenuOptionText(label: 'Sign In'),
              );
            }).toList();
          },
        );
      },
    );
  }
}

class _MenuOptionText extends StatelessWidget {
  const _MenuOptionText({Key key, this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(label),
    );
  }
}

class _PopupMenuOptions {
  const _PopupMenuOptions({this.title, this.icon});
  final String title;
  final IconData icon;
}

List<_PopupMenuOptions> _choices = const [
  _PopupMenuOptions(title: 'Auth', icon: Icons.lock),
];
