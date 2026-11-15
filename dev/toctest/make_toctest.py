"""Generates the TOC test addons for Armory One for All (phase 0)."""
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
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


# --- Phase 0b (2026-11-15): one Armory.toc for all versions? ---
ONE = "120105, 16001, 11509, 20506"


def xml(script):
    return ('<Ui xmlns="http://www.blizzard.com/wow/ui/">\n  <Script file="%s"/>\n</Ui>\n' % script)


# 5. The real layout: one base TOC, family and game lines by condition, in load order.
name = "OfaTestOne"
files = []
def add(line, path=None, label=None):
    if path:
        write("%s/%s" % (name, path), marker(label))
    files.append(line.replace('/', chr(92)))  # TOC paths use backslashes
add("files/first.lua", "files/first.lua", "first")
# A condition on an XML line; the XML loads a Lua file
for fam in ["mainline", "classic"]:
    write("%s/files/%s.xml" % (name, fam), xml("%s_xml.lua" % fam))
    write("%s/files/%s_xml.lua" % (name, fam), marker("xml-" + fam))
    add("files/%s.xml [AllowLoadGameType %s]" % (fam, fam))
# The family folder for a file every family has
for fam in ["Mainline", "Classic"]:
    write("%s/%s/family.lua" % (name, fam), marker("family=" + fam))
add("[Family]/family.lua")
# The game folder plus a condition: Retail and Forever have no folder and must skip the line
for game in ["Vanilla", "TBC"]:
    write("%s/%s/game.lua" % (name, game), marker("game=" + game))
add("[Game]/game.lua [AllowLoadGameType classic]")
# Only Forever, without the unknown types camelot and forever
add("files/onlyforever.lua [AllowLoadGameType mainline] [ExcludeLoadGameType standard]",
    "files/onlyforever.lua", "onlyforever")
# Only Retail
add("files/onlyretail.lua [AllowLoadGameType standard]", "files/onlyretail.lua", "onlyretail")
# Two game types in one condition
add("files/vanillatbc.lua [AllowLoadGameType vanilla, tbc]", "files/vanillatbc.lua", "vanilla+tbc")
add("files/retailtbc.lua [AllowLoadGameType standard, tbc]", "files/retailtbc.lua", "standard+tbc")
# Exclude alone
add("files/notvanilla.lua [ExcludeLoadGameType vanilla]", "files/notvanilla.lua", "not-vanilla")
# A missing file without a condition: silent or an error? (only Vanilla has it; see Logs\FrameXML.log)
write("%s/Vanilla/gameonly.lua" % name, marker("gameonly=Vanilla"))
add("[Game]/gameonly.lua")
add("files/last.lua", "files/last.lua", "last")
add("report.lua")
write(name + "/report.lua", REPORT)
write("%s/%s.toc" % (name, name), toc(name, ONE, "base", files))

# 6. The guild bank: one TOC, hidden in Era by a header with two game types
name = "OfaTestOneGB"
write(name + "/report.lua", REPORT)
write("%s/%s.toc" % (name, name),
      toc(name, ONE, "base", ["report.lua"], "## AllowLoadGameType: mainline, tbc\n"))

# 7. Fallback for Forever: a base TOC plus _Camelot. Which one does each client choose?
name = "OfaTestOneCamelot"
write(name + "/report.lua", REPORT)
write("%s/%s.toc" % (name, name), toc(name, ONE, "base", ["report.lua"]))
write("%s/%s_Camelot.toc" % (name, name), toc(name, "16001", "Camelot", ["report.lua"]))
