pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// Local metadata only: Kairo has no remote release service.
Item {
    id: root
    readonly property string localVersion: packageVersion || stateVersion || "unknown"
    property string packageVersion: Quickshell.env("KAIRO_VERSION") || ""
    property string stateVersion: ""

    FileView {
        id: packageFile
        path: Caching.kairoDir + "/version.txt"
        onFileChanged: packageFile.reload()
        onLoadFailed: {
            if (!path.endsWith("/../version.txt")) path = Caching.kairoDir + "/../version.txt";
        }
        onLoaded: root.packageVersion = text().trim()
    }

    FileView {
        id: stateFile
        path: Caching.stateDir + "/version"
        onFileChanged: stateFile.reload()
        onLoaded: {
            for (let line of text().split("\n")) {
                if (line.startsWith("KAIRO_VERSION=")) {
                    root.stateVersion = line.substring(14).replace(/["']/g, "").trim();
                    break;
                }
            }
        }
    }
}
