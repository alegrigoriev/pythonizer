#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_no_args.pl" v1.030 run by joe on Wed Apr 19 09:52:26 2023
# part of issue_s292: die w/o args
# If LIST was empty or made an empty string, and $@ is also empty, then the string "Died" is used
import builtins, perllib

perllib.init_package("main")
builtins.__PACKAGE__ = "main"
perllib.die()
