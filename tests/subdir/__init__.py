#!/usr/bin/env python3
# Generated by "pythonizer -v0 subdir.pm" v1.024 run by JO2742 on Sun Feb  5 10:18:28 2023
# part of issue s211
import builtins, perllib, sys, types

sys.path[0:0] = ["."]
from subdir.Util import escape
from subdir.subsubdir.utils import myutil

perllib.init_package("subdir", is_class=True)


def identity(*_args):
    _args = list(_args)
    self = _args.pop(0) if _args else None
    return perllib.num(myutil(escape(_args[0]))) - 1


subdir.identity = identity


def new(*_args):
    _args = list(_args)
    return perllib.bless(perllib.Hash(), (_args.pop(0) if _args else None))


subdir.new = types.MethodType(new, subdir)
builtins.__PACKAGE__ = "subdir"

subdir.escape = escape
subdir.myutil = myutil
