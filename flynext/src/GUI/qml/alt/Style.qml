pragma Singleton
import QtQml 2.0

QtObject
{
    readonly property int margin: 8
    readonly property int roundRadius: 6

    readonly property int inset: 20
    readonly property int strutSize: 50

    readonly property string frameColor: "#2275D3"
    readonly property string minorFrameColor: "#CEBEBE"

    readonly property string backgroundColor: "#3F3F3F"
    readonly property string themeColor: "#2275D3"
    readonly property string destructiveActionColor: "#c62703"
    readonly property string panelBackground: "#333333"

    readonly property string activeColor: Qt.lighter(themeColor)
    readonly property string inverseActiveColor: "#2f2f2f"

    readonly property string inactiveThemeColor: "#9f9f9f"
    readonly property string disabledThemeColor: disabledTextColor
    readonly property string disabledMinorFrameColor: "#755775"

    readonly property string baseTextColor: "#CEBEBE"
    readonly property string themeContrastTextColor: "#e5dcdc"
    readonly property string themeContrastLinkColor: "#ECE2D0"

    readonly property int baseFontPixelSize: 12
    readonly property int subHeadingFontPixelSize: 14
    readonly property int headingFontPixelSize: 18

    readonly property string disabledTextColor: "#6f6f6f"

    readonly property double panelOpacity: 0.8

    readonly property int menuItemHeight: baseFontPixelSize + (margin * 2)
}

