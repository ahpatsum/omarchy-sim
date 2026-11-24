import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons as Commons

Ui.Panel {
  id: root
  moduleName: "tamdintdesign.sim"
  ipcTarget: moduleName
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  property var status: ({})
  readonly property string helper: Qt.resolvedUrl("status.py").toString().replace(/^file:\/\//, "")
  readonly property var allowedStates: ["disabled", "enabled", "registered", "connected", "locked", "failed", "searching", "idle", "home", "roaming", "denied", "sim-pin", "sim-puk", "none"]

  function translateState(value) {
    return allowedStates.indexOf(value) >= 0 ? translations.t("state." + value) : translations.t("empty")
  }

  function refresh() {
    if (runner.running) return
    runner.command = ["/usr/bin/python", decodeURIComponent(helper)]
    runner.running = true
  }

  onOpenedChanged: if (opened) refresh()
  Commons.Translations { id: translations; directory: Qt.resolvedUrl("i18n") }

  Process {
    id: runner
    stdout: StdioCollector { id: result; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0 && result.text.length > 0 && result.text.length <= 4096) {
        try {
          const parsed = JSON.parse(result.text)
          if (["missing", "no-modem", "status-error", "service"].indexOf(parsed.mode) >= 0) {
            root.status = parsed
            return
          }
        } catch (error) {}
      }
      root.status = ({ "mode": "status-error" })
    }
  }

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "SIM"
    fixedWidth: Commons.Style.space(36)
    active: root.opened
    onPressed: function(mouseButton) { if (mouseButton === Qt.LeftButton) root.toggle() }
  }

  Ui.KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Commons.Style.space(335))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Commons.Style.space(390))

    content: FocusScope {
      implicitHeight: rows.implicitHeight
      Keys.onEscapePressed: root.close()
      Keys.onPressed: event => {
        if (event.key === Qt.Key_R) {
          root.refresh()
          event.accepted = true
        }
      }
      ColumnLayout {
        id: rows
        width: parent.width
        spacing: Commons.Style.space(12)

        Text {
          textFormat: Text.PlainText
          text: translations.t("title")
          color: root.barForeground
          font.family: Commons.Style.font.family
          font.pixelSize: Commons.Style.font.title
          font.bold: true
        }

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: runner.running ? translations.t("running")
                : root.status.mode ? translations.t(root.status.mode) : ""
          wrapMode: Text.WordWrap
          color: root.barForeground
          opacity: 0.72
          font.family: Commons.Style.font.family
          font.pixelSize: Commons.Style.font.body
        }

        Ui.PanelSeparator { Layout.fillWidth: true }

        GridLayout {
          columns: 2
          columnSpacing: Commons.Style.space(14)
          rowSpacing: Commons.Style.space(8)
          Layout.fillWidth: true
          Repeater {
            model: [
              [translations.t("modem"), root.status.model || translations.t("empty")],
              [translations.t("sim"), translations.t(["present", "unknown", "unconfirmed"].indexOf(root.status.sim) >= 0 ? root.status.sim : "unknown")],
              [translations.t("operator"), root.status.operator || translations.t("empty")],
              [translations.t("radio"), root.translateState(root.status.state)],
              [translations.t("network"), root.translateState(root.status.network)],
              [translations.t("lock"), root.translateState(root.status.lock)]
            ]
            delegate: RowLayout {
              required property var modelData
              Layout.fillWidth: true
              Layout.columnSpan: 2
              spacing: Commons.Style.space(10)

              Text {
                textFormat: Text.PlainText
                text: modelData[0]
                color: root.barForeground
                opacity: 0.72
                font.family: Commons.Style.font.family
                font.pixelSize: Commons.Style.font.body
              }

              Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: modelData[1]
                color: root.barForeground
                horizontalAlignment: Text.AlignRight
                font.family: Commons.Style.font.family
                font.pixelSize: Commons.Style.font.body
                elide: Text.ElideRight
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Commons.Style.space(8)
          Ui.Button {
            text: translations.t("refresh")
            enabled: !runner.running
            onClicked: root.refresh()
          }
        }
      }
    }
  }
}
