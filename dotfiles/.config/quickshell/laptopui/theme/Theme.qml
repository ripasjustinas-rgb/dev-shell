pragma Singleton

import QtQuick

QtObject {
    // Permanent "high rice" palette, adapted from NerdMini_shell. Qt colors
    // use #AARRGGBB, so alpha is kept at the beginning of translucent tokens.
    property color background: "#d6151218"
    property color surface: "#d9221e24"
    property color elevated: "#ed2c292e"
    property color surfaceHover: "#e64a454e"
    property color border: "#66968e98"
    readonly property color glassBorder: "#30ffffff"
    readonly property color glassHighlight: "#55ffffff"
    property color overlay: "#dc100d12"
    property color text: "#e8e0e8"
    property color muted: "#ccc4cf"
    property color accent: "#dabaf9"
    property color accentText: "#3e2459"
    property color secondary: "#d0c1da"
    property color glow: "#80553b71"
    property color danger: "#ffb4ab"
    property color warningColor: "#f3b7be"
    property color success: "#b8f2c8"
    readonly property int panelHeight: 48
    readonly property int panelContentHeight: 36
    readonly property int spacing: 8
    readonly property int radius: 14
    readonly property int radiusLarge: 22
    readonly property int animationFast: 150
    readonly property int animationNormal: 220
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
