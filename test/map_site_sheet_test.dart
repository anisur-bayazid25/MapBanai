import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/ui/common/map_chrome.dart';

void main() {
  for (final size in [const Size(360, 780), const Size(780, 360)]) {
    for (final height in [140.0, 230.0, 460.0]) {
      testWidgets('site panel fits $height content on $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: Stack(children: [
          MapSiteSheet(
              child: SizedBox(height: height, child: const Text('Actions'))),
        ]))));
        await tester.pumpAndSettle();
        final sheet = tester.widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet));
        final expected = ((height + 28) / size.height).clamp(.18, .86);
        expect(sheet.controller!.size, closeTo(expected, .002));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
