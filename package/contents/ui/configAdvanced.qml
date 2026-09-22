import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_allowSearch: allowSearchCheckBox.checked
    property alias cfg_firstArtist: firstArtistCheckBox.checked
    property alias cfg_baseUrlLrcLib: baseUrlLrcLibTextField.text
    property alias cfg_baseUrlLrcApi: baseUrlLrcApiTextField.text
    property alias cfg_baseUrlNetease: baseUrlNeteaseTextField.text
    // property alias cfg_baseUrlJellyfin: baseUrlJellyfinTextField.text
    // property alias cfg_baseUrlPlex: baseUrlPlexTextField.text
    property string cfg_providerPriorities
    property alias cfg_maxAttempts: maxAttemptsSpinBox.value
    property alias cfg_applications: applicationsTextField.text
    property bool updatingProviderModel: false

    ListModel {
        id: providerModel
    }

    function loadProviderModel() {
        const knownProviders = ['LRCLIB', 'LrcApi', 'Netease'];
        const configuredProviders = cfg_providerPriorities
            .split(',')
            .map(name => name.trim())
            .filter(name => knownProviders.includes(name));

        updatingProviderModel = true;
        providerModel.clear();

        for (const name of configuredProviders) {
            if (!new Array(providerModel.count).fill().some((_, index) => providerModel.get(index).name === name)) {
                providerModel.append({ name, selected: true });
            }
        }

        for (const name of knownProviders) {
            if (!configuredProviders.includes(name)) providerModel.append({ name, selected: false });
        }

        updatingProviderModel = false;
    }

    function updateProviderPriorities() {
        if (updatingProviderModel) return;

        const providers = [];
        for (let index = 0; index < providerModel.count; index++) {
            const provider = providerModel.get(index);
            if (provider.selected) providers.push(provider.name);
        }
        updatingProviderModel = true;
        cfg_providerPriorities = providers.join(',');
        updatingProviderModel = false;
    }

    onCfg_providerPrioritiesChanged: {
        if (!updatingProviderModel) loadProviderModel();
    }

    Component.onCompleted: loadProviderModel()

    Kirigami.FormLayout {
        QQC2.TextField {
            id: baseUrlLrcLibTextField
            Kirigami.FormData.label: i18n("LRCLIB Base URL: ")
            placeholderText: "https://lrclib.net"
        }

        QQC2.TextField {
            id: baseUrlLrcApiTextField
            Kirigami.FormData.label: i18n("LrcApi Base URL: ")
            placeholderText: "https://api.lrc.cx"
        }

        QQC2.TextField {
            id: baseUrlNeteaseTextField
            Kirigami.FormData.label: i18n("NetEase Base URL: ")
            placeholderText: "https://music.163.com"
        }

        // QQC2.TextField {
        //     id: baseUrlJellyfinTextField
        //     Kirigami.FormData.label: i18n("Jellyfin Base URL: ")
        // }

        // QQC2.TextField {
        //     id: baseUrlPlexTextField
        //     Kirigami.FormData.label: i18n("Plex Base URL: ")
        // }

        RowLayout {
            Kirigami.FormData.label: i18n("Lyric providers")

            QQC2.Button {
                id: providerButton
                Layout.fillWidth: true
                text: root.cfg_providerPriorities
                    ? root.cfg_providerPriorities.split(',').join(', ')
                    : i18n("No providers enabled")
                icon.name: "arrow-down"
                onClicked: providerPopup.open()

                Binding {
                    target: providerButton.contentItem
                    property: "horizontalAlignment"
                    value: Text.AlignLeft
                    when: providerButton.contentItem
                }
            }

            QQC2.Popup {
                id: providerPopup
                parent: providerButton
                x: 0
                y: providerButton.height
                width: Math.max(providerButton.width, contentItem.implicitWidth + leftPadding + rightPadding)
                padding: Kirigami.Units.smallSpacing
                closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("Providers are tried from top to bottom.")
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: providerModel

                        delegate: RowLayout {
                            required property int index
                            required property string name
                            required property bool selected

                            QQC2.CheckBox {
                                Layout.fillWidth: true
                                text: name
                                checked: selected
                                onToggled: {
                                    providerModel.setProperty(index, 'selected', checked);
                                    root.updateProviderPriorities();
                                }
                            }

                            QQC2.ToolButton {
                                enabled: index > 0
                                icon.name: "go-up"
                                text: i18n("Move up")
                                display: QQC2.AbstractButton.IconOnly
                                onClicked: {
                                    providerModel.move(index, index - 1, 1);
                                    root.updateProviderPriorities();
                                }
                                QQC2.ToolTip.text: text
                                QQC2.ToolTip.visible: hovered
                            }

                            QQC2.ToolButton {
                                enabled: index < providerModel.count - 1
                                icon.name: "go-down"
                                text: i18n("Move down")
                                display: QQC2.AbstractButton.IconOnly
                                onClicked: {
                                    providerModel.move(index, index + 1, 1);
                                    root.updateProviderPriorities();
                                }
                                QQC2.ToolTip.text: text
                                QQC2.ToolTip.visible: hovered
                            }
                        }
                    }
                }
            }
        }

        QQC2.SpinBox {
            id: maxAttemptsSpinBox
            Kirigami.FormData.label: i18n("Max attempts: ")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Search fallback (inaccurate): ")

            QQC2.CheckBox {
                id: allowSearchCheckBox
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Allows for lyrics based on a search query rather than exact matches")
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("First artist only: ")

            QQC2.CheckBox {
                id: firstArtistCheckBox
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Ignores featured artists while searching for lyrics")
            }
        }

        // also hopefully temporary, i dont like the , seperation
        RowLayout {
            Kirigami.FormData.label: i18n("Applications: ")

            QQC2.TextField {
                id: applicationsTextField
            }

            Kirigami.ContextualHelpButton {
                toolTipText: i18n("Only shows lyrics for media playing from these applications (seperated by ',')")
            }
        }
    }
}
