#!/usr/bin/env python3
# Generated by "pythonizer -v0 testdie/die_array.pl" v1.029 run by JO2742 on Sun Mar 26 10:43:59 2023
# part of issue_s292: die with array
import builtins, perllib

perllib.init_package("main")
builtins.__PACKAGE__ = "main"
diearray = perllib.Array(["Die with", "array"])
perllib.die(*diearray)
