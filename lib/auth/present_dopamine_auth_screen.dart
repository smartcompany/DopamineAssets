import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import 'dopamine_auth_config.dart';
import 'dopamine_user.dart';

Future<void> presentDopamineAuthScreen(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => AuthScreen<DopamineUser>(
        config: dopamineAuthConfig(),
      ),
    ),
  );
}
