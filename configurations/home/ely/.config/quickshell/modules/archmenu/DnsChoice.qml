import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Layouts

// One DNS selector (title, combo, and the fields of "Custom…"), used for the
// default of all networks and for the exception of the connected network.
ColumnLayout {
    id: choice

    required property string title
    // Mode currently chosen: "default" (network only), "auto", a provider id or "custom".
    required property string currentMode
    property string currentIpv4: ""
    property string currentIpv6: ""
    // Offers "Use the default" as the first option (per-network selector).
    property bool offerDefault: false
    property string defaultLabel: ""
    // function(mode, ipv4Text, ipv6Text) -> "" or an error message
    required property var apply

    property bool editingCustom: false
    property string fieldError: ""

    readonly property var options: (offerDefault ? [{ mode: "default", label: "Use the default · " + defaultLabel }] : [])
        .concat([{ mode: "auto", label: "Automatic (from the network)" }])
        .concat(Services.DnsControl.providers.map(item => ({ mode: item.id, label: item.label + " · " + item.detail })))
        .concat([{ mode: "custom", label: "Custom…" }])
    readonly property int customIndex: options.length - 1
    readonly property int displayIndex: editingCustom ? customIndex
        : Math.max(0, options.findIndex(option => option.mode === currentMode))

    function startCustom() {
        editingCustom = true;
        fieldError = "";
        ipv4Field.text = currentMode === "custom" ? currentIpv4 : "";
        ipv6Field.text = currentMode === "custom" ? currentIpv6 : "";
        Qt.callLater(() => ipv4Field.forceActiveFocus());
    }

    function applyCustom() {
        fieldError = choice.apply("custom", ipv4Field.text, ipv6Field.text);
        if (fieldError === "")
            editingCustom = false;
    }

    function cancelCustom() {
        editingCustom = false;
        fieldError = "";
        combo.currentIndex = Qt.binding(() => choice.displayIndex);
    }

    Layout.fillWidth: true
    spacing: Config.Theme.spaceXs

    Text {
        Layout.fillWidth: true
        text: choice.title
        color: Config.Theme.colTextSec
        elide: Text.ElideRight
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSizeCaption
    }

    Widgets.ThemedComboBox {
        id: combo
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        popupAbove: false
        enabled: !Services.DnsControl.busy && Services.DnsControl.loaded
        model: choice.options.map(option => option.label)
        currentIndex: choice.displayIndex
        Accessible.name: choice.title
        onActivated: index => {
            if (index === choice.customIndex) {
                choice.startCustom();
                return;
            }
            choice.editingCustom = false;
            choice.fieldError = "";
            const mode = choice.options[index].mode;
            if (mode !== choice.currentMode)
                choice.fieldError = choice.apply(mode, "", "");
            combo.currentIndex = Qt.binding(() => choice.displayIndex);
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: choice.editingCustom
        spacing: Config.Theme.spaceXs

        Widgets.ThemedTextField {
            id: ipv4Field
            Layout.fillWidth: true
            placeholderText: "IPv4, e.g. 1.1.1.1, 1.0.0.1"
            horizontalTextPadding: 6
            font.pixelSize: Config.Theme.fontSizeCaption
            Accessible.name: choice.title + ": IPv4 servers"
            Keys.onReturnPressed: choice.applyCustom()
            Keys.onEscapePressed: event => { choice.cancelCustom(); event.accepted = true; }
        }

        Widgets.ThemedTextField {
            id: ipv6Field
            Layout.fillWidth: true
            placeholderText: "IPv6 (optional)"
            horizontalTextPadding: 6
            font.pixelSize: Config.Theme.fontSizeCaption
            Accessible.name: choice.title + ": IPv6 servers"
            Keys.onReturnPressed: choice.applyCustom()
            Keys.onEscapePressed: event => { choice.cancelCustom(); event.accepted = true; }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm

            Item { Layout.fillWidth: true }

            Widgets.LabelButton {
                text: "Cancel"
                labelFontSize: Config.Theme.fontSizeCaption
                cornerRadius: Config.Theme.radiusSmall
                outlineOnFocus: true
                idleTextColor: Config.Theme.colMuted
                hoverTextColor: Config.Theme.colFg
                hoverBackgroundColor: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                Accessible.name: "Cancel custom DNS"
                onClicked: choice.cancelCustom()
            }

            Widgets.LabelButton {
                text: "Apply"
                enabled: !Services.DnsControl.busy
                labelFontSize: Config.Theme.fontSizeCaption
                cornerRadius: Config.Theme.radiusSmall
                outlineOnFocus: true
                idleTextColor: Config.Theme.colHighlight
                hoverTextColor: Config.Theme.colHighlight
                hoverBackgroundColor: Config.Theme.alpha(Config.Theme.colHighlight, 0.14)
                Accessible.name: "Apply custom DNS"
                onClicked: choice.applyCustom()
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: choice.fieldError !== ""
        text: choice.fieldError
        color: Config.Theme.colRed
        wrapMode: Text.Wrap
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSizeCaption
    }
}
