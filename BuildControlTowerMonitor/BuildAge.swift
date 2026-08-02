import Foundation

nonisolated extension Int {
    /// A compact, localized rendering of this value as an age in seconds, e.g.
    /// `40s`, `3m 20s`, `1h 5m`.
    ///
    /// The daemon reports every age as a plain second count, so the monitor owns
    /// all of the presentation. Two units are enough to be precise without the
    /// string growing wide enough to jostle the menu bar.
    var buildAgeDescription: String {
        Duration.seconds(self).formatted(
            .units(
                allowed: [.hours, .minutes, .seconds],
                width: .narrow,
                maximumUnitCount: 2
            )
        )
    }
}
