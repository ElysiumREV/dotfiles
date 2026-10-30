.pragma library

function widthForScreen(screen, preferredWidth, horizontalMargin) {
    const width = Number(screen ? screen.width : NaN);
    if (!Number.isFinite(width) || width <= 0)
        return Math.max(1, preferredWidth - horizontalMargin);
    return Math.max(1, Math.min(preferredWidth, width - horizontalMargin));
}

function heightForScreen(screen, preferredHeight, topMargin, bottomMargin) {
    const height = Number(screen ? screen.height : NaN);
    if (!Number.isFinite(height) || height <= 0)
        return preferredHeight;
    return Math.max(1, Math.min(preferredHeight, height - topMargin - bottomMargin));
}
