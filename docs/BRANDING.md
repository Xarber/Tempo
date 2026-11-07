# Branding

Tempo is the working name explicitly supplied by the user. No trademark clearance or global uniqueness claim is made. Tagline: Make time for what matters. Parent initiative: OpenRecode.

Accent #6269F5, highlight #858BFF, adaptive system text/surface colors. Native system font with rounded timer numerals. Light/dark appearance follows macOS. Restrained motion: timer rendering uses no continuous ornamental animation.

assets/branding/tempo.svg is the editable original vector master. Stable groups: background, track, primary-symbol, highlight; reusable accent gradient. Open timer ring symbolizes making room for intentional time. No Session assets are used. scripts/generate-icon.swift reproduces the same geometry as editable SVG into a complete macOS iconset. Run `swift scripts/generate-icon.swift` then `iconutil -c icns build/Tempo.iconset -o build/Tempo.icns`. The packaging script includes an existing ICNS. Dedicated dark/tinted variants and raster visual QA remain open.
