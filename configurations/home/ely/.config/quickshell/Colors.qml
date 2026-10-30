pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	property alias md3: jsonAdapter.md3
	property alias base16: jsonAdapter.base16
	property alias palette: jsonAdapter.palette

	FileView {
		id: colorsFile
		path: Quickshell.env("HOME") + "/.local/state/quickshell/generated/colors.json"
		watchChanges: true
		onFileChanged: reloadTimer.restart()

		JsonAdapter {
			id: jsonAdapter

			readonly property Md3 md3: Md3 {}
			readonly property Base16 base16: Base16 {}
			readonly property Palette palette: Palette {}
		}
	}

	Timer {
		id: reloadTimer
		interval: 150
		repeat: false
		onTriggered: colorsFile.reload()
	}

	component Md3: JsonObject {
		// Dark Material 3 fallback colors; Matugen values override these when present.
		property string background: "#141218"
		property string error: "#F2B8B5"
		property string error_container: "#93000A"
		property string inverse_on_surface: "#313033"
		property string inverse_primary: "#6750A4"
		property string inverse_surface: "#E6E0E9"
		property string on_background: "#E6E0E9"
		property string on_error: "#601410"
		property string on_error_container: "#F2B8B5"
		property string on_primary: "#381E72"
		property string on_primary_container: "#EADDFF"
		property string on_primary_fixed: "#21005D"
		property string on_primary_fixed_variant: "#4F378B"
		property string on_secondary: "#332D41"
		property string on_secondary_container: "#E8DEF8"
		property string on_secondary_fixed: "#1D192B"
		property string on_secondary_fixed_variant: "#4A4458"
		property string on_surface: "#E6E0E9"
		property string on_surface_variant: "#CAC4D0"
		property string on_tertiary: "#492532"
		property string on_tertiary_container: "#FFD8E4"
		property string on_tertiary_fixed: "#31111D"
		property string on_tertiary_fixed_variant: "#633B48"
		property string outline: "#938F99"
		property string outline_variant: "#49454F"
		property string primary: "#D0BCFF"
		property string primary_container: "#4F378B"
		property string primary_fixed: "#EADDFF"
		property string primary_fixed_dim: "#D0BCFF"
		property string scrim: "#000000"
		property string secondary: "#CCC2DC"
		property string secondary_container: "#4A4458"
		property string secondary_fixed: "#E8DEF8"
		property string secondary_fixed_dim: "#CCC2DC"
		property string shadow: "#000000"
		property string surface: "#141218"
		property string surface_bright: "#3B383E"
		property string surface_container: "#211F26"
		property string surface_container_high: "#2B2930"
		property string surface_container_highest: "#36343B"
		property string surface_container_low: "#1D1B20"
		property string surface_container_lowest: "#0F0D13"
		property string surface_dim: "#141218"
		property string surface_tint: "#D0BCFF"
		property string surface_variant: "#49454F"
		property string tertiary: "#EFB8C8"
		property string tertiary_container: "#633B48"
		property string tertiary_fixed: "#FFD8E4"
		property string tertiary_fixed_dim: "#EFB8C8"
	}

	component Palette: JsonObject {
		property string error0: "transparent"
		property string error5: "transparent"
		property string error10: "transparent"
		property string error15: "transparent"
		property string error20: "transparent"
		property string error25: "transparent"
		property string error30: "transparent"
		property string error35: "transparent"
		property string error40: "transparent"
		property string error50: "transparent"
		property string error60: "transparent"
		property string error70: "transparent"
		property string error80: "transparent"
		property string error90: "transparent"
		property string error95: "transparent"
		property string error98: "transparent"
		property string error99: "transparent"
		property string error100: "transparent"

		property string neutral0: "transparent"
		property string neutral5: "transparent"
		property string neutral10: "transparent"
		property string neutral15: "transparent"
		property string neutral20: "transparent"
		property string neutral25: "transparent"
		property string neutral30: "transparent"
		property string neutral35: "transparent"
		property string neutral40: "transparent"
		property string neutral50: "transparent"
		property string neutral60: "transparent"
		property string neutral70: "transparent"
		property string neutral80: "transparent"
		property string neutral90: "transparent"
		property string neutral95: "transparent"
		property string neutral98: "transparent"
		property string neutral99: "transparent"
		property string neutral100: "transparent"

		property string neutral_variant0: "transparent"
		property string neutral_variant5: "transparent"
		property string neutral_variant10: "transparent"
		property string neutral_variant15: "transparent"
		property string neutral_variant20: "transparent"
		property string neutral_variant25: "transparent"
		property string neutral_variant30: "transparent"
		property string neutral_variant35: "transparent"
		property string neutral_variant40: "transparent"
		property string neutral_variant50: "transparent"
		property string neutral_variant60: "transparent"
		property string neutral_variant70: "transparent"
		property string neutral_variant80: "transparent"
		property string neutral_variant90: "transparent"
		property string neutral_variant95: "transparent"
		property string neutral_variant98: "transparent"
		property string neutral_variant99: "transparent"
		property string neutral_variant100: "transparent"

		property string primary0: "transparent"
		property string primary5: "transparent"
		property string primary10: "transparent"
		property string primary15: "transparent"
		property string primary20: "transparent"
		property string primary25: "transparent"
		property string primary30: "transparent"
		property string primary35: "transparent"
		property string primary40: "transparent"
		property string primary50: "transparent"
		property string primary60: "transparent"
		property string primary70: "transparent"
		property string primary80: "transparent"
		property string primary90: "transparent"
		property string primary95: "transparent"
		property string primary98: "transparent"
		property string primary99: "transparent"
		property string primary100: "transparent"

		property string secondary0: "transparent"
		property string secondary5: "transparent"
		property string secondary10: "transparent"
		property string secondary15: "transparent"
		property string secondary20: "transparent"
		property string secondary25: "transparent"
		property string secondary30: "transparent"
		property string secondary35: "transparent"
		property string secondary40: "transparent"
		property string secondary50: "transparent"
		property string secondary60: "transparent"
		property string secondary70: "transparent"
		property string secondary80: "transparent"
		property string secondary90: "transparent"
		property string secondary95: "transparent"
		property string secondary98: "transparent"
		property string secondary99: "transparent"
		property string secondary100: "transparent"

		property string tertiary0: "transparent"
		property string tertiary5: "transparent"
		property string tertiary10: "transparent"
		property string tertiary15: "transparent"
		property string tertiary20: "transparent"
		property string tertiary25: "transparent"
		property string tertiary30: "transparent"
		property string tertiary35: "transparent"
		property string tertiary40: "transparent"
		property string tertiary50: "transparent"
		property string tertiary60: "transparent"
		property string tertiary70: "transparent"
		property string tertiary80: "transparent"
		property string tertiary90: "transparent"
		property string tertiary95: "transparent"
		property string tertiary98: "transparent"
		property string tertiary99: "transparent"
		property string tertiary100: "transparent"
	}

	component Base16: JsonObject {
		property string base00: "transparent"
		property string base01: "transparent"
		property string base02: "transparent"
		property string base03: "transparent"
		property string base04: "transparent"
		property string base05: "transparent"
		property string base06: "transparent"
		property string base07: "transparent"
		property string base08: "transparent"
		property string base09: "transparent"
		property string base0a: "transparent"
		property string base0b: "transparent"
		property string base0c: "transparent"
		property string base0d: "transparent"
		property string base0e: "transparent"
		property string base0f: "transparent"
	}
}
