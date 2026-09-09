import QtQuick
import qs.theme

Canvas {
    id: root

    property var samples: []
    property var secondarySamples: []
    property color lineColor: Theme.accent
    property color secondaryColor: Theme.secondary

    onSamplesChanged: requestPaint()
    onSecondarySamplesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onSecondaryColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const peak = samples.concat(secondarySamples).reduce((maximum, value) => Math.max(maximum, value), 1);
        line(ctx, peak, secondarySamples, secondaryColor);
        line(ctx, peak, samples, lineColor);
    }

    function line(ctx, peak, values, color) {
        if (values.length < 2)
            return ;

        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        for (let i = 0; i < values.length; ++i) {
            const x = i * width / Math.max(1, values.length - 1);
            const y = height - 2 - values[i] / peak * (height - 4);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.stroke();
    }

}
