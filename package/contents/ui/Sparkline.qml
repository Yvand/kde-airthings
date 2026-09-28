import QtQuick

// Time-based line chart. X follows time, so gaps in the history stay visible;
// points further apart than maxGapMs are not connected.
Canvas {
    id: chart

    property var points: []             // [{ t: epoch ms, v: number }], sorted by t
    property real fromMs: 0
    property real toMs: 1
    property real maxGapMs: Infinity
    property color color: "steelblue"
    property real lineWidth: 1.5
    property bool showGuides: false
    property color guideColor: "transparent"

    // Value range drawn from bottom to top.
    readonly property var bounds: {
        let min = Infinity;
        let max = -Infinity;
        for (const p of points) {
            min = Math.min(min, p.v);
            max = Math.max(max, p.v);
        }
        if (min === Infinity) {
            return { min: 0, max: 1 };
        }
        return min === max ? { min: min - 1, max: max + 1 } : { min, max };
    }

    onPointsChanged: requestPaint()
    onFromMsChanged: requestPaint()
    onToMsChanged: requestPaint()
    onMaxGapMsChanged: requestPaint()
    onColorChanged: requestPaint()
    onLineWidthChanged: requestPaint()
    onShowGuidesChanged: requestPaint()
    onGuideColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (points.length < 2 || toMs <= fromMs) {
            return;
        }
        const inset = lineWidth;
        const x = t => (t - fromMs) / (toMs - fromMs) * width;
        const y = v => height - inset - (v - bounds.min) / (bounds.max - bounds.min) * (height - 2 * inset);

        if (showGuides) {
            ctx.strokeStyle = guideColor;
            ctx.lineWidth = 1;
            for (let i = 0; i <= 2; i++) {
                const guideY = inset + i * (height - 2 * inset) / 2;
                ctx.beginPath();
                ctx.moveTo(0, guideY);
                ctx.lineTo(width, guideY);
                ctx.stroke();
            }
        }

        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth;
        ctx.lineJoin = "round";
        ctx.beginPath();
        for (let i = 0; i < points.length; i++) {
            const p = points[i];
            if (i > 0 && p.t - points[i - 1].t <= maxGapMs) {
                ctx.lineTo(x(p.t), y(p.v));
            } else {
                ctx.moveTo(x(p.t), y(p.v));
            }
        }
        ctx.stroke();
    }
}
