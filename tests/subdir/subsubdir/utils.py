#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 ./subdir/subsubdir/utils.pm" v1.026 run by JO2742 on Wed Feb 15 23:44:45 2023
# part of issue_s211 - check a subsubdir
import builtins, perllib

perllib.init_package("subdir.subsubdir.utils")


def myutil(*_args):
    return perllib.num(_args[0]) + 1


subdir.subsubdir.utils.myutil = myutil

builtins.__PACKAGE__ = "subdir.subsubdir.utils"

# SKIPPED: use Exporter 'import';

subdir.subsubdir.utils.EXPORT_OK_a = "myutil".split()
