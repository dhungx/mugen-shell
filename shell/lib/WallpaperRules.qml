pragma Singleton
import QtQuick

QtObject {
    readonly property var pauseWhenValues: ["never", "fullscreen"]
    readonly property var fitValues: ["fill", "fit", "stretch"]
    readonly property var transitionValues: ["wave", "fade", "wipe", "grow", "random", "none"]
    readonly property var slideshowMinuteValues: [1, 5, 10, 15, 30, 60]
    readonly property var slideshowOrderValues: ["shuffle", "inOrder"]
    readonly property var ignoredAppIds: ["", "org.quickshell"]

    readonly property var defaults: ({
        pauseWhen: "fullscreen",
        pauseApps: [],
        speed: 1,
        sound: false,
        volume: 50,
        fit: "fill",
        brightness: 0,
        saturation: 0,
        transition: "wave",
        transitionSeconds: 1.3,
        slideshow: false,
        slideshowMinutes: 15,
        slideshowOrder: "shuffle"
    })

    // jq's round goes away from zero on halves; Math.round goes toward +Infinity.
    function roundHalfAway(n) {
        const r = Math.sign(n) * Math.round(Math.abs(n))
        return r === 0 ? 0 : r
    }

    function enumOf(v, allowed, fallback) {
        return typeof v === "string" && allowed.indexOf(v) >= 0 ? v : fallback
    }

    function boolOf(v, fallback) {
        return typeof v === "boolean" ? v : fallback
    }

    function speedOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.speed
        return Math.min(2, Math.max(0.25, roundHalfAway(v * 4) / 4))
    }

    function volumeOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.volume
        return Math.min(100, Math.max(0, roundHalfAway(v)))
    }

    function brightnessOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.brightness
        return Math.min(50, Math.max(-50, roundHalfAway(v)))
    }

    function saturationOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.saturation
        return Math.min(100, Math.max(-100, roundHalfAway(v)))
    }

    function transitionSecondsOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.transitionSeconds
        return Math.min(3, Math.max(0.3, roundHalfAway(v * 10) / 10))
    }

    function slideshowMinutesOf(v) {
        if (typeof v !== "number" || !isFinite(v))
            return defaults.slideshowMinutes
        const minutes = roundHalfAway(v)
        return slideshowMinuteValues.indexOf(minutes) >= 0 ? minutes : defaults.slideshowMinutes
    }

    function pauseAppsOf(v) {
        if (!Array.isArray(v))
            return []
        const out = []
        for (const item of v) {
            if (typeof item !== "string")
                continue
            const id = item.trim()
            if (ignoredAppIds.indexOf(id) < 0 && out.indexOf(id) < 0)
                out.push(id)
        }
        return out
    }

    function openAppIds(toplevels) {
        const out = []
        for (let i = 0; i < toplevels.length; i++) {
            const id = toplevels[i].appId
            if (typeof id === "string" && ignoredAppIds.indexOf(id) < 0 && out.indexOf(id) < 0)
                out.push(id)
        }
        return out.sort()
    }

    function pauseAppRowIds(openIds, knownSaved) {
        const out = []
        for (const id of openIds.concat(knownSaved)) {
            if (out.indexOf(id) < 0)
                out.push(id)
        }
        return out.sort()
    }

    function wantPause(toplevels, pauseWhen, pauseApps) {
        for (let i = 0; i < toplevels.length; i++) {
            const t = toplevels[i]
            const fullscreen = t.fullscreen
            const appId = t.appId
            if ((pauseWhen === "fullscreen" && fullscreen === true) || pauseApps.indexOf(appId) >= 0)
                return true
        }
        return false
    }

    function pauseAction(want, mpvPaused, holding) {
        if (want)
            return mpvPaused ? "" : "pause"
        if (!holding)
            return ""
        return mpvPaused ? "resume" : "release"
    }

    function mpvProperties(s) {
        return [
            ["speed", s.speed],
            ["volume", s.volume],
            ["aid", s.sound ? "auto" : "no"],
            ["panscan", s.fit === "fill" ? 1 : 0],
            ["keepaspect", s.fit !== "stretch"],
            ["brightness", s.brightness],
            ["saturation", s.saturation]
        ]
    }

    function nextInOrder(list, current) {
        const i = list.indexOf(current)
        if (i < 0)
            return list.length > 0 ? list[0] : ""
        for (let step = 1; step < list.length; step++) {
            const candidate = list[(i + step) % list.length]
            if (candidate !== current)
                return candidate
        }
        return ""
    }

    function nextShuffled(list, current, bag, rand) {
        let pool = bag.filter(p => list.indexOf(p) >= 0 && p !== current)
        if (pool.length === 0)
            pool = list.filter(p => p !== current)
        if (pool.length === 0)
            return { path: "", bag: [] }
        const path = pool[Math.min(pool.length - 1, Math.floor(rand() * pool.length))]
        return { path: path, bag: pool.filter(p => p !== path) }
    }

    function speedLabel(speed) {
        return (Math.round(speed * 100) / 100) + "×"
    }
}
