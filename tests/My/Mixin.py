#!/usr/bin/env python3
# Generated by "pythonizer -v0 My/Mixin.pm" v1.030 run by joe on Wed Apr 19 09:52:36 2023
# Part of test_use_parent2.pl - generated by chatGPT
import builtins, perllib

perllib.init_package("My.Mixin")


def bar(*_args):
    return "bar"


My.Mixin.bar = bar

builtins.__PACKAGE__ = "My.Mixin"
