pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property string kairoDir: Quickshell.env("KAIRO_DIR")
    readonly property string qsDir: Quickshell.env("QS_DIR")
    readonly property string mainQml: Quickshell.env("MAIN_QML")

    readonly property string home: Quickshell.env("HOME")
    readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")

    readonly property string cacheDir: Quickshell.env("QS_CACHE_DIR") ? Quickshell.env("QS_CACHE_DIR") : ((Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")) + "/kairo")
    readonly property string stateDir: Quickshell.env("QS_STATE_DIR") ? Quickshell.env("QS_STATE_DIR") : ((Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/kairo")
    readonly property string runDir: Quickshell.env("QS_RUN_DIR") ? Quickshell.env("QS_RUN_DIR") : ((xdgRuntimeDir !== "" ? xdgRuntimeDir : "/tmp") + "/kairo")
    readonly property string logDir: Quickshell.env("QS_LOG_DIR") ? Quickshell.env("QS_LOG_DIR") : (runDir + "/logs")

    function getCacheDir(widgetName) {
        if (!widgetName || widgetName === "kairo" || cacheDir.endsWith("/" + widgetName)) {
            Quickshell.execDetached(["mkdir", "-p", cacheDir]);
            return cacheDir;
        }
        var envPath = Quickshell.env("QS_CACHE_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (cacheDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getStateDir(widgetName) {
        if (!widgetName || widgetName === "kairo" || stateDir.endsWith("/" + widgetName)) {
            Quickshell.execDetached(["mkdir", "-p", stateDir]);
            return stateDir;
        }
        var envPath = Quickshell.env("QS_STATE_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (stateDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getRunDir(widgetName) {
        if (!widgetName || widgetName === "kairo" || runDir.endsWith("/" + widgetName)) {
            Quickshell.execDetached(["mkdir", "-p", runDir]);
            return runDir;
        }
        var envPath = Quickshell.env("QS_RUN_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (runDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    function getLogDir(widgetName) {
        if (!widgetName || widgetName === "kairo" || logDir.endsWith("/" + widgetName)) {
            Quickshell.execDetached(["mkdir", "-p", logDir]);
            return logDir;
        }
        var envPath = Quickshell.env("QS_LOG_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (logDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
}
