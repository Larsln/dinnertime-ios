import SwiftUI

/// The colors of the Dinnertime look; each one has a light and a dark value in the brand asset catalog.
///
/// The accent is the asset `AccentColor`, which the system also uses as the tint of every control.
extension ShapeStyle where Self == Color {
    /// Everything tappable, shopping tiles and primary buttons.
    static var accent: Color { Color("AccentColor") }
    /// Background of every screen.
    static var paper: Color { Color("Paper") }
    /// Cards and list rows.
    static var surface: Color { Color("Surface") }
    /// Wells: fields the app draws itself, checked tiles, cooked meals.
    static var sunken: Color { Color("Sunken") }
    /// Hairlines and the borders of cards.
    static var line: Color { Color("Line") }
    /// Text.
    static var ink: Color { Color("Ink") }
    /// Secondary text.
    static var inkMuted: Color { Color("InkMuted") }
    /// Text and icons on the accent.
    static var onAccent: Color { Color("OnAccent") }
    /// Accent-colored text on light surfaces: labels, warnings, scaled amounts.
    static var accentDeep: Color { Color("AccentDeep") }
    /// Selected rows, hint cards and cover placeholders.
    static var accentSoft: Color { Color("AccentSoft") }
    /// Marks for "done" and "active".
    static var herb: Color { Color("Herb") }
    /// Background of positive hints.
    static var herbSoft: Color { Color("HerbSoft") }
    /// Text on a checked shopping tile.
    static var doneInk: Color { Color("DoneInk") }
    /// Check marks and the heading of what is done: green in light appearance, neutral in dark.
    static var doneMark: Color { Color("DoneMark") }
}
