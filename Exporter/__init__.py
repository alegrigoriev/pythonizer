#!/usr/bin/env python3
# Generated by "pythonizer -aM -d5 -v3 Exporter.pm" v1.027 run by SNOOPYJC on Wed Feb 22 14:03:51 2023
__author__ = """Joe Cool"""
__email__ = 'snoopyjc@gmail.com'
__version__ = '1.028'
import builtins,perllib,re
_bn = lambda s: '' if s is None else s
_pb = lambda b: 1 if b else ''
_str = lambda s: '' if s is None else str(s)
_locals_stack = []
class LoopControl(Exception):
    pass

import sys
perllib.init_package('Exporter')

# Default methods

def export_fail(*_args):
    _args = list(_args)
    self = (_args.pop(0) if _args else None)
    return _args

Exporter.export_fail = export_fail

# Unfortunately, caller(1)[3] "does not work" if the caller is aliased as
# *name = \&foo.  Thus the need to create a lot of identical subroutines
# Otherwise we could have aliased them to export().

def as_heavy(*_args):
    import Exporter.Heavy as _Exporter_Heavy
    # Unfortunately, this does not work if the caller is aliased as *name = \&foo
    # Thus the need to create a lot of identical subroutines
    c = (perllib.caller_s(1))[3]
    c = re.sub(r'.*::',r'',_str(c), count=1)
    return perllib.fetch_perl_global(f"Exporter::Heavy::heavy_{_bn(c)}")

Exporter.as_heavy = as_heavy

def require_version(*_args):
    __goto_sub__ = True
    return as_heavy()(*_args)

Exporter.require_version = require_version

def export_ok_tags(*_args):
    __goto_sub__ = True
    return as_heavy()(*_args)

Exporter.export_ok_tags = export_ok_tags

def export_tags(*_args):
    __goto_sub__ = True
    return as_heavy()(*_args)

Exporter.export_tags = export_tags

def export_to_level(*_args):
    __goto_sub__ = True
    return as_heavy()(*_args)

Exporter.export_to_level = export_to_level

def export(*_args):
    __goto_sub__ = True
    return as_heavy()(*_args)

Exporter.export = export

def import_(*_args):
    pass                        # SNOOPYJC: We have a built-in handler for Export in Pythonizer
# SNOOPYJC    _args = list(_args)
# SNOOPYJC    global _d
# SNOOPYJC    try:
# SNOOPYJC        _locals_stack.append(perllib.SIG_WARN_HANDLER)
# SNOOPYJC        pkg = (_args.pop(0) if _args else None)
# SNOOPYJC        callpkg = perllib.caller_s(perllib.int_(Exporter.ExportLevel_v))
# SNOOPYJC
# SNOOPYJC        if _str(pkg) == 'Exporter' and _args and _str(_args[0]) == 'import':
# SNOOPYJC            perllib.store_perl_global(_str(callpkg) + '::import', Exporter.import_, infer_suffix=True)
# SNOOPYJC            return 
# SNOOPYJC
# SNOOPYJC        # We *need* to treat @{"$pkg\::EXPORT_FAIL"} since Carp uses it :-(
# SNOOPYJC
# SNOOPYJC        exports = perllib.fetch_perl_global(f"{_bn(pkg)}::EXPORT"+'_a')
# SNOOPYJC        # But, avoid creating things if they don't exist, which saves a couple of
# SNOOPYJC        # hundred bytes per package processed.
# SNOOPYJC        fail = (_str(pkg) + '::')['EXPORT_FAIL'] and perllib.fetch_perl_global(f"{_bn(pkg)}::EXPORT_FAIL"+'_a')
# SNOOPYJC        if Exporter.Verbose_v or Exporter.Debug_v or fail and perllib.num(len(fail)) > 1:
# SNOOPYJC            return Exporter.export(pkg, callpkg, *_args)
# SNOOPYJC
# SNOOPYJC        export_cache = perllib.set_element(Exporter.Cache_h, pkg, Exporter.Cache_h.get(_str(pkg)) or perllib.Hash())
# SNOOPYJC        if (not (args:=_args)):
# SNOOPYJC            _args = exports
# SNOOPYJC
# SNOOPYJC
# SNOOPYJC        if args and not export_cache:
# SNOOPYJC            def _f46(_d):
# SNOOPYJC            for _i in range(len(exports)):
# SNOOPYJC                exports[_i] = _f46(exports[_i])
# SNOOPYJC
# SNOOPYJC            for _ in range(1):
# SNOOPYJC                _d = re.sub(r'^&',r'',_str(_d),count=1), perllib.set_element(export_cache, _d, 1)
# SNOOPYJC                return _d
# SNOOPYJC
# SNOOPYJC        heavy = None
# SNOOPYJC        # Try very hard not to use {} and hence have to  enter scope on the foreach
# SNOOPYJC        # We bomb out of the loop with last as soon as heavy is set.
# SNOOPYJC        if args or fail:
# SNOOPYJC            for _d in _args:
# SNOOPYJC                (heavy:=(_pb(re.search(r'\W',_str(_d)) or args and not _str(_d) in export_cache or fail and fail and _str(_d) == _str(fail[0])))) and perllib.raise_(LoopControl('break'))
# SNOOPYJC        else:
# SNOOPYJC            for _d in _args:
# SNOOPYJC                (heavy:=re.search(r'\W',_str(_d))) and perllib.raise_(LoopControl('break'))
# SNOOPYJC
# SNOOPYJC        if heavy:
# SNOOPYJC            return Exporter.export(pkg, callpkg, *(_args if args else perllib.Array()))
# SNOOPYJC
# SNOOPYJC        def _f61(*_args):
# SNOOPYJC            pass        #SKIPPED: require Carp; &Carp::carp} if not $SIG{__WARN__};
# SNOOPYJC            return perllib.carp()
# SNOOPYJC
# SNOOPYJC        if not perllib.SIG_WARN_HANDLER:
# SNOOPYJC            perllib.SIG_WARN_HANDLER = _f61
# SNOOPYJC        # shortcut for the common case of no type character
# SNOOPYJC
# SNOOPYJC        for _d in _args:
# SNOOPYJC            perllib.store_perl_global(f"{_bn(callpkg)}::{_bn(_d)}", perllib.fetch_perl_global(f"{_bn(pkg)}::{_bn(_d)}"), infer_suffix=True)
# SNOOPYJC
# SNOOPYJC    finally:
# SNOOPYJC        perllib.SIG_WARN_HANDLER = _locals_stack.pop()

Exporter.import_ = import_

Exporter.Cache_h = perllib.init_global('Exporter', 'Cache_h', perllib.Hash())
Exporter.Debug_v = perllib.init_global('Exporter', 'Debug_v', 0)
Exporter.ExportLevel_v = perllib.init_global('Exporter', 'ExportLevel_v', 0)
Exporter.Verbose_v = perllib.init_global('Exporter', 'Verbose_v', '')
_d = None

builtins.__PACKAGE__ = 'Exporter'

#SKIPPED: use strict;
#SKIPPED: no strict 'refs';

Exporter.Debug_v = 0
Exporter.ExportLevel_v = 0
Exporter.Verbose_v = Exporter.Verbose_v or 0
Exporter.VERSION_v = '5.77'
