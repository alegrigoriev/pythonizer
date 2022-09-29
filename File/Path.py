#!/usr/bin/env python3
# Generated by "pythonizer -aM -v3 -d5 Path.pm" v0.971 run by JO2742 on Thu Apr 14 15:50:18 2022
"""Implementation of perl File::Path package"""
__author__ = """Joe Cool"""
__email__ = "snoopyjc@gmail.com"
__version__ = "0.993"
import builtins, perllib, os, re

_str = lambda s: "" if s is None else str(s)
_locals_stack = []


class LoopControl_ROOT_DIR(Exception):
    pass


perllib.init_package("File.Path")


def _slash_lc(*_args):
    _args = list(_args)

    # fix up slashes and case on MSWin32 so that we can determine that
    # c:\path\to\dir is underneath C:/Path/To
    path = _args.pop(0) if _args else None
    path = path.translate(str.maketrans("\\", "/"))
    return path.lower()


File.Path._slash_lc = _slash_lc


def _is_subdir(*_args):
    [dir_, test] = perllib.list_of_n(_args, 2)

    [dv, dd] = perllib.list_of_n(perllib.splitpath(_str(dir_), 1), 2)
    [tv, td] = perllib.list_of_n(perllib.splitpath(_str(test), 1), 2)

    # not on same volume
    if dv != tv:
        return 0

    d = perllib.Array(perllib.splitdir(dd))
    t = perllib.Array(perllib.splitdir(td))

    # @t can't be a subdir if it's shorter than @d
    if len(t) < len(d):
        return 0

    return "/".join(d) == "/".join(map(_str, (perllib.splice(t, 0, +len(d)))))


File.Path._is_subdir = _is_subdir


def __is_arg(*_args):
    [arg] = perllib.list_of_n(_args, 1)

    # If client code blessed an array ref to HASH, this will not work
    # properly. We could have done $arg->isa() wrapped in eval, but
    # that would be expensive. This implementation should suffice.
    # We could have also used Scalar::Util:blessed, but we choose not
    # to add this dependency
    return perllib.refs(arg) == "HASH"


File.Path.__is_arg = __is_arg


def _error(*_args):
    _args = list(_args)
    arg = _args.pop(0) if _args else None
    message = _args.pop(0) if _args else None
    object_ = _args.pop(0) if _args else None

    if arg.get("error"):
        if object_ is None:
            object_ = ""

        if perllib.OS_ERROR:
            message += f": {perllib.OS_ERROR}"

        arg["error"].append({object_: message})
    else:
        perllib.carp(
            f"{message} for {object_}: {perllib.OS_ERROR}"
            if object_ is not None
            else f"{message}: {perllib.OS_ERROR}"
        )


File.Path._error = _error


def _rmtree(*_args):
    _args = list(_args)

    fh_inode = 0
    cur_inode = 0
    nperm = None
    fh_dev = 0
    narg = ""
    d_v = None
    _d = ""
    root_fh = None
    cur_dev = 0
    data = _args.pop(0) if _args else None
    paths = _args.pop(0) if _args else None

    count = 0
    curdir = perllib.curdir()
    updir = perllib.updir()

    files = perllib.Array()
    root = None
    # ROOT_DIR
    for root in paths:
        try:

            # since we chdir into each directory, it may not be obvious
            # to figure out where we are if we generate a message about
            # a file name. We therefore construct a semi-canonical
            # filename, anchored from the directory being unlinked (as
            # opposed to being truly canonical, anchored from the root (/).

            canon = os.path.join(data.get("prefix"), root) if data.get("prefix") else root

            (ldev, lino, perm) = perllib.Array(
                [perllib.get_element((_ := perllib.lstat(root)), _i) for _i in [0, 1, 2]]
            )
            if ldev is None:
                continue

            if perllib.is_dir(_):
                if File.Path._IS_VMS():
                    root = VMS.Filespec.vmspath(VMS.Filespec.pathify(root))

                if not perllib.chdir(_str(root)):

                    # see if we can escalate privileges to get in
                    # (e.g. funny protection mask such as -w- instead of rwx)
                    # This uses fchmod to avoid traversing outside of the proper
                    # location (CVE-2017-6512)
                    root_fh = None
                    if root_fh := perllib.open_(_str(root), "r"):
                        try:
                            _locals_stack.append(perllib.EVAL_ERROR)
                            [fh_dev, fh_inode] = perllib.list_of_n(
                                [
                                    perllib.get_element((_ := perllib.stat(root_fh)), _i)
                                    for _i in [0, 1]
                                ],
                                2,
                            )
                            perm &= int("7777", 8)
                            nperm = perm | int("700", 8)
                            perllib.EVAL_ERROR = ""
                            _eval_result421 = None
                            try:
                                _eval_result421 = perllib.chmod(perllib.int_(nperm), root_fh)
                                perllib.EVAL_ERROR = ""
                            except Exception as _e:
                                perllib.EVAL_ERROR = perllib.exc(_e)

                            if not (
                                data.get("safe")
                                or perllib.num(nperm) == perm
                                or not perllib.is_dir(_)
                                or _str(fh_dev) != _str(ldev)
                                or _str(fh_inode) != _str(lino)
                                or _eval_result421
                            ):
                                _error(data, "cannot make child directory read-write-exec", canon)
                                continue

                            perllib.close(root_fh)

                        finally:
                            perllib.EVAL_ERROR = _locals_stack.pop()

                    if not perllib.chdir(_str(root)):
                        _error(data, "cannot chdir to child", canon)
                        continue

                (cur_dev, cur_inode, perm) = perllib.Array(
                    [perllib.get_element((_ := perllib.stat(curdir)), _i) for _i in [0, 1, 2]]
                )
                if cur_dev is None:
                    _do_435 = True
                    while _do_435:
                        _error(data, "cannot stat current working directory", canon)
                        raise LoopControl_ROOT_DIR("continue")
                        _do_435 = False

                if File.Path._NEED_STAT_CHECK():
                    if not (_str(ldev) == _str(cur_dev) and _str(lino) == _str(cur_inode)):
                        perllib.croak(
                            f"directory {canon} changed before chdir, expected dev={ldev} ino={lino}, actual dev={cur_dev} ino={cur_inode}, aborting."
                        )

                perm &= int("7777", 8)  # don't forget setuid, setgid, sticky bits
                nperm = perm | int("700", 8)

                # notabene: 0700 is for making readable in the first place,
                # it's also intended to change it to writable in case we have
                # to recurse in which case we are better than rm -rf for
                # subtrees with strange permissions

                if not (
                    data.get("safe")
                    or perllib.num(nperm) == perm
                    or perllib.chmod(perllib.int_(nperm), curdir)
                ):
                    _error(data, "cannot make directory read+writeable", canon)
                    nperm = perm

                d_v = None
                if 5.034 < 5.006:
                    d_v = gensym()

                if not (d_v := perllib.opendir(curdir)):
                    _error(data, "cannot opendir", canon)
                    files = perllib.Array()
                else:
                    if not False is not None or False:
                        # Blindly untaint dir names if taint mode is active
                        def _f476(*_args):
                            _d = _args[0]
                            _m = re.search(re.compile(r"\A(.*)\Z", re.S), _str(_d))
                            return _m.group(1)

                        files = perllib.Array(list(map(_f476, perllib.readdirs(d_v))))
                    else:
                        files = perllib.Array(perllib.readdirs(d_v))

                    perllib.closedir(d_v)

                if File.Path._IS_VMS():

                    # Deleting large numbers of files from VMS Files-11
                    # filesystems is faster if done in reverse ASCIIbetical order.
                    # include '.' to '.;' from blead patch #31775
                    def _f489(*_args):
                        _d = _args[0]
                        return ".;" if _str(_d) == "." else _d

                    files = perllib.Array(list(map(_f489, (files)[::-1])))

                files = perllib.Array(
                    list(filter(lambda _d: _str(_d) != updir and _str(_d) != curdir, files))
                )

                if files:

                    # remove the contained files before the directory itself
                    narg = perllib.Hash(data.copy())
                    perllib.assign_hash(
                        narg,
                        "device inode cwd prefix depth".split(),
                        (cur_dev, cur_inode, updir, canon, perllib.num(data.get("depth")) + 1),
                    )
                    count += _rmtree(narg, files)

                # restore directory permissions of required now (in case the rmdir
                # below fails), while we are still in the directory and may do so
                # without a race via '.'

                if perllib.num(nperm) != perm and not perllib.chmod(perm, curdir):
                    _error(data, "cannot reset chmod", canon)

                # don't leave the client code in an unexpected directory

                if not (perllib.chdir(_str(data.get("cwd")))):
                    perllib.croak(
                        f"cannot chdir to {data.get('cwd','')} from {canon}: {perllib.OS_ERROR}, aborting."
                    )

                # ensure that a chdir upwards didn't take us somewhere other
                # than we expected (see CVE-2002-0435)

                [cur_dev, cur_inode] = perllib.list_of_n(
                    [perllib.get_element((_ := perllib.stat(curdir)), _i) for _i in [0, 1]], 2
                )
                if cur_dev is None:
                    perllib.croak(
                        f"cannot stat prior working directory {data.get('cwd','')}: {perllib.OS_ERROR}, aborting."
                    )

                if File.Path._NEED_STAT_CHECK():
                    if not (
                        _str(data.get("device")) == _str(cur_dev)
                        and _str(data.get("inode")) == _str(cur_inode)
                    ):
                        perllib.croak(
                            f"previous directory {data.get('cwd','')} "
                            + f"changed before entering {canon}, "
                            + f"expected dev={ldev} ino={lino}, "
                            + f"actual dev={cur_dev} ino={cur_inode}, aborting."
                        )

                if data.get("depth") or not data.get("keep_root"):
                    if data.get("safe") and (
                        not VMS.Filespec.candelete(root)
                        if File.Path._IS_VMS()
                        else not perllib.is_writable(root)
                    ):
                        if data.get("verbose"):
                            perllib.perl_print(f"skipped {root}")

                        continue

                    if File.Path._FORCE_WRITABLE() and not perllib.chmod(
                        perm | int("700", 8), root
                    ):
                        _error(data, "cannot make directory writeable", canon)

                    if data.get("verbose"):
                        perllib.perl_print(f"rmdir {root}")

                    if perllib.rmdir(_str(root)):
                        if data.get("result"):
                            data["result"].append(root)

                        count += 1
                    else:
                        _error(data, "cannot remove directory", canon)
                        if File.Path._FORCE_WRITABLE() and not perllib.chmod(
                            perm, (VMS.Filespec.fileify(root) if File.Path._IS_VMS() else root)
                        ):
                            _error(
                                data,
                                perllib.format_("cannot restore permissions to 0%o", perm),
                                canon,
                            )
            else:
                # not a directory
                if (
                    File.Path._IS_VMS()
                    and not os.path.isabs(_str(root))
                    and (not (_m := re.search(r"(?<!\^)[\]>]+", _str(root))))
                ):  # not already in VMS syntax
                    root = VMS.Filespec.vmsify(f"./{root}")

                if data.get("safe") and (
                    not VMS.Filespec.candelete(root)
                    if File.Path._IS_VMS()
                    else not (perllib.is_link(root) or perllib.is_writable(root))
                ):
                    if data.get("verbose"):
                        perllib.perl_print(f"skipped {root}")

                    continue

                nperm = perm & int("7777", 8) | int("600", 8)
                if (
                    File.Path._FORCE_WRITABLE()
                    and perllib.num(nperm) != perm
                    and not perllib.chmod(perllib.int_(nperm), root)
                ):
                    _error(data, "cannot make file writeable", canon)

                if data.get("verbose"):
                    perllib.perl_print(f"unlink {canon}")

                # delete all versions under VMS

                while True:
                    if os.unlink(root):
                        if data.get("result"):
                            data["result"].append(root)
                    else:
                        _error(data, "cannot unlink file", canon)
                        if not (File.Path._FORCE_WRITABLE() and perllib.chmod(perm, root)):
                            _error(
                                data,
                                perllib.format_("cannot restore permissions to 0%o", perm),
                                canon,
                            )

                        break

                    count += 1
                    if not (File.Path._IS_VMS() and (_ := perllib.lstat(root))):
                        break
        except LoopControl_ROOT_DIR as _l:
            if _l.args[0] == "break":
                break

            continue

    return count


File.Path._rmtree = _rmtree


def rmtree(*_args):
    _args = list(_args)

    args_permitted = perllib.Hash()
    safe = None
    bad_args = perllib.Array()
    verbose = None
    old_style = not (_args and __is_arg(_args[-1]))

    arg = ""
    data = perllib.Hash()
    paths = None

    if old_style:
        verbose = safe = None
        [paths, verbose, safe] = perllib.list_of_n(_args, 3)
        data["verbose"] = verbose
        data["safe"] = safe if safe is not None else 0

        if paths is not None and len(_str(paths)):
            if not perllib.isa(paths, "ARRAY"):
                paths = perllib.Array([paths])
        else:
            perllib.carp("No root path(s) specified\n")
            return 0
    else:
        args_permitted = perllib.Hash(
            perllib.list_to_hash(
                perllib.flatten(
                    map(lambda _d: [_d, 1], ("error keep_root result safe verbose".split()))
                )
            )
        )
        bad_args = perllib.Array()
        arg = _args.pop() if _args else None
        for k in sorted(list(arg.keys())):
            if not args_permitted.get(k):
                bad_args.append(k)
            else:
                data[k] = arg.get(k)

        if bad_args:
            perllib.carp(
                f"Unrecognized option(s) passed to remove_tree(): {perllib.LIST_SEPARATOR.join(map(_str,bad_args))}"
            )

        if "error" in data:
            data["error"] = perllib.Array()

        if "result" in data:
            data["result"] = perllib.Array()

        # Wouldn't it make sense to do some validation on @_ before assigning
        # to $paths here?
        # In the $old_style case we guarantee that each path is both defined
        # and non-empty.  We don't check that here, which means we have to
        # check it later in the first condition in this line:
        #     if ( $ortho_root_length && _is_subdir( $ortho_root, $ortho_cwd ) ) {
        # Granted, that would be a change in behavior for the two
        # non-old-style interfaces.

        paths = _args

    data["prefix"] = ""
    data["depth"] = 0

    clean_path = perllib.Array()
    if not perllib.set_element(data, "cwd", os.getcwd()):
        _do_328 = True
        while _do_328:
            _error(data, "cannot fetch initial working directory")
            return 0
            _do_328 = False

    for _d in data["cwd"]:
        _m = re.search(re.compile(r"\A(.*)$", re.S), _str(_d))
        _d = _m.group(1)
    # untaint

    for p in paths:

        # need to fixup case and map \ to / on Windows
        ortho_root = _slash_lc(p) if File.Path._IS_MSWIN32() else p
        ortho_cwd = _slash_lc(data.get("cwd")) if File.Path._IS_MSWIN32() else data.get("cwd")
        ortho_root_length = len(ortho_root)
        if File.Path._IS_VMS():  # don't compare '.' with ']'
            ortho_root_length -= 1

        if ortho_root_length and _is_subdir(ortho_root, ortho_cwd):
            try:
                _locals_stack.append(perllib.OS_ERROR)
                perllib.OS_ERROR = 0
                _error(data, f"cannot remove path when cwd is {data.get('cwd','')}", p)
                continue

            finally:
                perllib.OS_ERROR = _locals_stack.pop()

        if File.Path._IS_MACOS():
            if not ((re.search(r":", _str(p)))):
                p = f":{p}"

            if not ((re.search(r":\Z", _str(p)))):
                p = _str(p) + ":"
        elif File.Path._IS_MSWIN32():
            p = re.sub(r"[/\\]\Z", r"", _str(p), count=1)
        else:
            p = re.sub(r"/\Z", r"", _str(p), count=1)

        clean_path.append(p)

    perllib.assign_hash(
        data,
        "device inode".split(),
        perllib.Array(
            [perllib.get_element((_ := perllib.lstat(data.get("cwd"))), _i) for _i in [0, 1]]
        ),
    )
    if not bool(data):
        _do_361 = True
        while _do_361:
            _error(data, "cannot stat initial working directory", data.get("cwd"))
            return 0
            _do_361 = False

    return _rmtree(data, clean_path)


File.Path.rmtree = rmtree


def remove_tree(*_args):
    _args = list(_args)
    if not (_args and __is_arg(_args[-1])):
        _args.append(perllib.Hash())

    return rmtree(*_args)


File.Path.remove_tree = remove_tree


def _mkpath(*_args):
    _args = list(_args)

    e = ""
    save_bang = 0
    e1 = ""
    unknown_perl_special_varE = ""
    data = _args.pop(0) if _args else None
    paths = _args.pop(0) if _args else None

    created = perllib.Array()
    for path in paths:
        if not (path is not None and len(_str(path))):
            continue

        if File.Path._IS_OS2() and (
            re.search(re.compile(r"^\w:\Z", re.S), _str(path))
        ):  # feature of CRT
            path = _str(path) + "/"

        # Logic wants Unix paths, so go with the flow.

        if File.Path._IS_VMS():
            if _str(path) == "/":
                continue

            path = VMS.Filespec.unixify(path)

        if perllib.is_dir(path):
            continue

        parent = perllib.dirname(_str(path))
        # Coverage note:  It's not clear how we would test the condition:
        # '-d $parent or $path eq $parent'
        if not (perllib.is_dir(parent) or _str(path) == parent):
            created.extend(perllib.make_list(_mkpath(data, [parent])))

        if data.get("verbose"):
            perllib.perl_print(f"mkdir {path}")

        if perllib.mkdir(_str(path), perllib.int_(data.get("mode"))):
            created.append(path)
            if "owner" in data:

                # NB: $data->{group} guaranteed to be set during initialisation
                if not File.Path.chown(data.get("owner"), data.get("group"), path):
                    _error(
                        data,
                        f"Cannot change ownership of {path} to {data.get('owner','')}:{data.get('group','')}",
                    )

            if "chmod" in data:
                # Coverage note:  It's not clear how we would trigger the next
                # 'if' block.  Failure of 'chmod' might first result in a
                # system error: "Permission denied".
                if not perllib.chmod(perllib.int_(data.get("chmod")), path):
                    _error(data, f"Cannot change permissions of {path} to {data.get('chmod','')}")
        else:
            save_bang = perllib.OS_ERROR

            # From 'perldoc perlvar': $EXTENDED_OS_ERROR ($^E) is documented
            # as:
            # Error information specific to the current operating system. At the
            # moment, this differs from "$!" under only VMS, OS/2, and Win32
            # (and for MacPerl). On all other platforms, $^E is always just the
            # same as $!.

            [e, e1] = (save_bang, unknown_perl_special_varE)
            if e != _str(e1):
                e += f"; {e1}"

            # allow for another process to have created it meanwhile

            if not perllib.is_dir(path):
                perllib.OS_ERROR = save_bang
                if data.get("error"):
                    data["error"].append({path: e})
                else:
                    perllib.croak(f"mkdir {path}: {e}")

    return created


File.Path._mkpath = _mkpath


def mkpath(*_args):
    _args = list(_args)

    win32_implausible_args = perllib.Array()
    gid = None
    args_permitted = perllib.Hash()
    uid = None
    verbose = None
    arg = perllib.Hash()
    not_on_win32_args = perllib.Hash()
    mode = None
    bad_args = perllib.Array()
    old_style = not (_args and __is_arg(_args[-1]))

    data = perllib.Hash()
    paths = None

    if old_style:
        verbose = mode = None
        [paths, verbose, mode] = perllib.list_of_n(_args, 3)
        if not perllib.isa(paths, "ARRAY"):
            paths = perllib.Array([paths])

        data["verbose"] = verbose
        data["mode"] = mode if mode is not None else int("777", 8)
    else:
        args_permitted = perllib.Hash(
            perllib.list_to_hash(
                perllib.flatten(
                    map(
                        lambda _d: [_d, 1],
                        ("chmod error group mask mode owner uid user verbose".split()),
                    )
                )
            )
        )
        not_on_win32_args = perllib.Hash(
            perllib.list_to_hash(
                perllib.flatten(map(lambda _d: [_d, 1], ("group owner uid user".split())))
            )
        )
        bad_args = perllib.Array()
        win32_implausible_args = perllib.Array()
        arg = _args.pop() if _args else None
        for k in sorted(list(arg.keys())):
            if not args_permitted.get(k):
                bad_args.append(k)
            elif not_on_win32_args.get(k) and File.Path._IS_MSWIN32():
                win32_implausible_args.append(k)
            else:
                data[k] = arg.get(k)

        if bad_args:
            perllib.carp(
                f"Unrecognized option(s) passed to mkpath() or make_path(): {perllib.LIST_SEPARATOR.join(map(_str,bad_args))}"
            )

        if win32_implausible_args:
            perllib.carp(
                f"Option(s) implausible on Win32 passed to mkpath() or make_path(): {perllib.LIST_SEPARATOR.join(map(_str,win32_implausible_args))}"
            )

        if "mask" in data:
            data["mode"] = data.pop("mask", None)

        if not ("mode" in data):
            data["mode"] = int("777", 8)

        if "error" in data:
            data["error"] = perllib.Array()

        if not win32_implausible_args:
            if "user" in data:
                data["owner"] = data.pop("user", None)

            if "uid" in data:
                data["owner"] = data.pop("uid", None)

            if "owner" in data and (re.search(r"\D", _str(data.get("owner")))):
                uid = (File.Path.getpwnam(data.get("owner")))[2]
                if uid is not None:
                    data["owner"] = uid
                else:
                    _error(
                        data,
                        f"unable to map {data.get('owner','')} to a uid, ownership not changed",
                    )
                    data.pop("owner", None)

            if "group" in data and (re.search(r"\D", _str(data.get("group")))):
                gid = (File.Path.getgrnam(data.get("group")))[2]
                if gid is not None:
                    data["group"] = gid
                else:
                    _error(
                        data,
                        f"unable to map {data.get('group','')} to a gid, group ownership not changed",
                    )
                    data.pop("group", None)

            if "owner" in data and not "group" in data:
                data["group"] = -1  # chown will leave group unchanged

            if "group" in data and not "owner" in data:
                data["owner"] = -1  # chown will leave owner unchanged

        paths = _args

    return _mkpath(data, paths)


File.Path.mkpath = mkpath


def make_path(*_args):
    _args = list(_args)
    if not (_args and __is_arg(_args[-1])):
        _args.append(perllib.Hash())

    return mkpath(*_args)


File.Path.make_path = make_path


def _croak(*_args):
    pass  # SKIPPED:     require Carp;
    return perllib.croak(*_args)


File.Path._croak = _croak


def _carp(*_args):
    pass  # SKIPPED:     require Carp;
    return perllib.carp(*_args)


File.Path._carp = _carp
builtins.__PACKAGE__ = "File.Path"

# SKIPPED: use 5.005_04;
# SKIPPED: use strict;

# SKIPPED: use Cwd 'getcwd';
# SKIPPED: use File::Basename ();
# SKIPPED: use File::Spec     ();

for _ in range(1):  # BEGIN:
    if 5.034 < 5.006:

        # can't say 'opendir my $dh, $dirname'
        # need to initialise $dh
        try:
            from Symbol import ungensym, qualify_to_ref, qualify, gensym

            perllib.EVAL_ERROR = ""
        except Exception as _e:
            perllib.EVAL_ERROR = perllib.exc(_e)

# SKIPPED: use Exporter ();
# SKIPPED: use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

File.Path.VERSION_v = "2.18"
_eval_result22 = None
try:
    _eval_result22 = File.Path.VERSION_v
    perllib.EVAL_ERROR = ""
except Exception as _e:
    perllib.EVAL_ERROR = perllib.exc(_e)

File.Path.VERSION_v = _eval_result22
File.Path.ISA_a = "Exporter".split()
File.Path.EXPORT_a = "mkpath rmtree".split()
File.Path.EXPORT_OK_a = "make_path remove_tree".split()

for _ in range(1):  # BEGIN:
    for _d in "VMS MacOS MSWin32 os2".split():
        pass  # SKIPPED:     no strict 'refs';

        def _f30(*_args):
            return 1

        def _f30a(*_args):
            return 0

        File.Path.__dict__[f"_IS_{(_d).upper()}"] = (
            _f30 if perllib.os_name() == _str(_d) else _f30a
        )

    # These OSes complain if you want to remove a file that you have no
    # write permission to:

    def _f37(*_args):
        return 1

    def _f37a(*_args):
        return 0

    File.Path._FORCE_WRITABLE = (
        _f37
        if (
            len(
                list(
                    filter(
                        lambda _d: perllib.os_name() == _str(_d),
                        "amigaos dos epoc MSWin32 MacOS os2".split(),
                    )
                )
            )
        )
        else _f37a
    )

    # Unix-like systems need to stat each directory in order to detect
    # race condition. MS-Windows is immune to this particular attack.
    def _f41(*_args):
        return 1

    def _f41a(*_args):
        return 0

    File.Path._NEED_STAT_CHECK = _f41 if not (File.Path._IS_MSWIN32()) else _f41a
