#!/usr/bin/env python3
# Generated by "pythonizer -aM ../Time/tm.pm" v1.026 run by SNOOPYJC on Sat Feb 11 12:45:45 2023
__author__ = """Joe Cool"""
__email__ = "snoopyjc@gmail.com"
__version__ = "1.026"
import builtins, perllib
from Class.Struct import struct_

builtins.__PACKAGE__ = "Time.tm"
Class.Struct.import_("Class.Struct", *"struct".split())
perllib.init_package("Time.tm")
_d = ""
builtins.__PACKAGE__ = "Time.tm"
# SKIPPED: use strict;

Time.tm.VERSION_v = "1.00"

struct_(
    "Time::tm",
    perllib.flatten(
        map(
            lambda _d: [_d, "$"],
            perllib.make_list("sec min hour mday mon year wday yday isdst".split()),
        )
    ),
)
