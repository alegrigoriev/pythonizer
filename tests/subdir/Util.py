#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 ./subdir/Util.pm" v1.027 run by JO2742 on Thu Feb 23 22:12:52 2023
# Part of issue_s211
import builtins, perllib
from Exporter import import_

builtins.__PACKAGE__ = "subdir.Util"
Exporter.import_("Exporter", *"import".split())
perllib.init_package("subdir.Util")


def escape(*_args):
    return _args[0]


subdir.Util.escape = escape

builtins.__PACKAGE__ = "subdir.Util"
subdir.Util.import_ = import_
subdir.Util.EXPORT_OK_a = "escape".split()
