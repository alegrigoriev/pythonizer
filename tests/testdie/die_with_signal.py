#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_with_signal.pl" v1.027 run by JO2742 on Thu Feb 23 22:13:26 2023
# part of issue_s292: die with a signal
import builtins, os, perllib

perllib.init_package("main")
builtins.__PACKAGE__ = "main"
perllib.kill("TERM", os.getpid())
