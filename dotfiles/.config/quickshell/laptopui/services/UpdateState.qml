pragma Singleton

import QtQuick

QtObject {
    property int revision: 0

    function refresh() {
        revision += 1
    }
}
