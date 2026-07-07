abstract final class Responsive {
  static const sidebarBreakpoint = 1200.0;
  static const compactWidthBreakpoint = 900.0;
  static const scrollLayoutHeightBreakpoint = 820.0;

  static bool showSidebar(double width) => width >= sidebarBreakpoint;

  static bool isCompactWidth(double width) => width < compactWidthBreakpoint;

  static bool useStackedTopNav(double width) => width < 1100;

  static bool useScrollLayout(double width, double height) {
    return height < scrollLayoutHeightBreakpoint || !showSidebar(width);
  }

  /// Fler kolumner på smal yta = färre rader och mindre risk att innehåll kapas.
  static int actionColumns(double width, int itemCount) {
    if (itemCount == 0) return 4;

    var columns = (width / 108).floor().clamp(3, 6);

    while (columns < 6 && (itemCount / columns).ceil() > 2) {
      columns++;
    }

    return columns;
  }

  static double actionTileHeight(double width, {required bool compact}) {
    if (compact) return 118;
    return width < compactWidthBreakpoint ? 124 : 132;
  }
}
