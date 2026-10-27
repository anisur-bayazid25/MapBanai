import 'package:flutter/material.dart';
import 'package:mapbanai/l10n/ui_text.dart';

/// The route owns its input controller until its closing animation unmounts.
class UserNameDialog extends StatefulWidget {
  final String initialName;
  final bool welcome;
  const UserNameDialog(
      {super.key, this.initialName = '', this.welcome = false});
  @override
  State<UserNameDialog> createState() => _UserNameDialogState();
}

class _UserNameDialogState extends State<UserNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(ui(context,
            widget.welcome ? 'Welcome to MapBanai' : 'My enumerator name')),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.welcome) ...[
                Text(
                    ui(context,
                        'Enter your name — it will be attached to every survey response, GPS log entry and export. You can change it later in the three-bar menu → My name.'),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
              ],
              TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 100,
                  decoration: InputDecoration(
                      labelText: ui(
                          context, widget.welcome ? 'User name' : 'Your name'),
                      helperText: widget.welcome
                          ? null
                          : ui(context, 'Attached to each new submission.'),
                      prefixIcon: const Icon(Icons.person_outline))),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ui(context, widget.welcome ? 'Skip' : 'Cancel'))),
          FilledButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context, _controller.text.trim());
              },
              child: Text(ui(context, 'Save'))),
        ],
      );
}
