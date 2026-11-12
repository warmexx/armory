"""Generates the TOC test addons for Armory One for All (phase 0)."""
import os
import sys

ROOT = sys.argv[1]
IFACES = {"Mainline": "120105", "Forever": "16001", "Vanilla": "11509", "TBC": "20505"}
ALL = "120105, 16001, 11508, 11509, 20505, 20506"


def write(path, text):
    path = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def marker(label):
    return 'local _, ns = ...\nns.files = ns.files or {}\ntable.insert(ns.files, "%s")\n' % label


REPORT = r'''local addonName, ns = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version, build, _, interface = GetBuildInfo()
    local result = {
        build = version .. "." .. build,
        interface = interface,
        projectID = WOW_PROJECT_ID,
        tocUsed = GetMeta(addonName, "X-Ofa-Toc"),
        files = table.concat(ns.files or {}, ","),
        checkAddonVersion = GetCVar("checkAddonVersion"),
        hasCAddOnsDisable = (C_AddOns and C_AddOns.DisableAddOn) and true or false,
        constants = {
            MAINLINE = WOW_PROJECT_MAINLINE,
            CLASSIC = WOW_PROJECT_CLASSIC,
            BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC,
            CAMELOT = WOW_PROJECT_CAMELOT,
        },
    }
    local db = addonName .. "DB"
    _G[db] = _G[db] or {}
    _G[db][version] = result
    print("|cff33ff99" .. addonName .. "|r toc=" .. tostring(result.tocUsed)
        .. " project=" .. tostring(result.projectID) .. " files=" .. result.files)
end)
'''


def toc(name, interface, label, files, extra=""):
    return ("## Interface: %s\n## Title: %s\n## Notes: Armory One for All, TOC-test (fase 0)\n"
            "## SavedVariables: %sDB\n## X-Ofa-Toc: %s\n%s\n%s\n") % (
        interface, name, name, label, extra, "\n".join(files))


# 1. One base TOC with all interface numbers and per-file conditions.
name = "OfaTestCond"
files = ["files\\common.lua"]
write(name + "/files/common.lua", marker("common"))
for gt in ["mainline", "camelot", "forever", "standard", "classic", "vanilla", "tbc"]:
    write("%s/files/%s.lua" % (name, gt), marker(gt))
    files.append("files\\%s.lua [AllowLoadGameType %s]" % (gt, gt))
write(name + "/files/notcamelot.lua", marker("mainline-not-camelot"))
files.append("files\\notcamelot.lua [AllowLoadGameType mainline] [ExcludeLoadGameType camelot]")
for fam in ["Mainline", "Classic"]:
    write("%s/%s/family.lua" % (name, fam), marker("family=" + fam))
files.append("[Family]\\family.lua")
for game in ["Mainline", "Standard", "Camelot", "Forever", "Classic", "Vanilla", "TBC"]:
    write("%s/%s/game.lua" % (name, game), marker("game=" + game))
files.append("[Game]\\game.lua")
files.append("report.lua")
write(name + "/report.lua", REPORT)
write(name + "/%s.toc" % name, toc(name, ALL, "base", files))

# 2. A TOC per version plus a base TOC: which one does each client choose?
name = "OfaTestSuffix"
write(name + "/report.lua", REPORT)
for suffix, iface in IFACES.items():
    write("%s/%s_%s.toc" % (name, name, suffix), toc(name, iface, suffix, ["report.lua"]))
write("%s/%s.toc" % (name, name), toc(name, ALL, "base", ["report.lua"]))

# 3. Only Mainline and TBC TOCs, no base: must be invisible in Era (guild bank case).
name = "OfaTestNoToc"
write(name + "/report.lua", REPORT)
for suffix in ["Mainline", "TBC"]:
    write("%s/%s_%s.toc" % (name, name, suffix), toc(name, IFACES[suffix], suffix, ["report.lua"]))

# 4. Header AllowLoadGameType: can "load out of date" override it?
name = "OfaTestGameType"
write(name + "/report.lua", REPORT)
write("%s/%s.toc" % (name, name),
      toc(name, ALL, "base", ["report.lua"], "## AllowLoadGameType: mainline\n"))
