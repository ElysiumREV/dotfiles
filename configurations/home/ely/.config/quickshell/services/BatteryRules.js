.pragma library

function iconName(level, charging) {
    if (charging)
        return "battery_charging_full"
    if (level <= 5)
        return "battery_0_bar"
    if (level <= 20)
        return "battery_1_bar"
    if (level <= 35)
        return "battery_2_bar"
    if (level <= 50)
        return "battery_3_bar"
    if (level <= 65)
        return "battery_4_bar"
    if (level <= 80)
        return "battery_5_bar"
    if (level <= 95)
        return "battery_6_bar"
    return "battery_full"
}

function isLow(level, pluggedIn) {
    return level <= 25 && !pluggedIn
}

function isCritical(level, pluggedIn) {
    return level <= 20 && !pluggedIn
}
