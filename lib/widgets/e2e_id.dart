import 'package:flutter/material.dart';

/// Wraps [child] in a [Semantics] node with a stable `identifier`, which
/// Flutter web serializes to the `flt-semantics-identifier` DOM attribute
/// when the semantics tree is enabled. Playwright / other DOM-based E2E
/// harnesses can then query widgets by this id without coordinate-based
/// selectors.
///
/// Adds no visual effect, no behavior change, and no overhead in release
/// builds where semantics are inactive.
Widget e2eId(String id, Widget child) {
  return Semantics(
    identifier: id,
    explicitChildNodes: true,
    child: child,
  );
}
