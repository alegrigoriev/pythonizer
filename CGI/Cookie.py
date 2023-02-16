#!/usr/bin/env python3
# Generated by "pythonizer -a Cookie.pm" v1.025 run by SNOOPYJC on Fri Feb 10 14:16:14 2023
__author__ = """Joe Cool"""
__email__ = "snoopyjc@gmail.com"
__version__ = "1.025"
import builtins, os, perllib, re, types

_bn = lambda s: "" if s is None else s
_str = lambda s: "" if s is None else str(s)
_locals_stack = []
from perllib import Die


class FunctionReturn(Exception):
    pass


from CGI.Util import escape, rearrange, unescape

perllib.init_package("CGI.Cookie", is_class=True)


def samesite(*_args):  # SameSite
    _args = list(_args)
    global _legal_samesite

    samesite_v = ""
    self = _args.pop(0) if _args else None
    if _args:  # Normalize casing.
        samesite_v = perllib.ucfirst(_str(perllib.num(_args.pop(0) if _args else None)).lower())

    if samesite_v and _legal_samesite.get(samesite_v):
        self["samesite"] = samesite_v

    return self.get("samesite")


CGI.Cookie.samesite = samesite


def httponly(*_args):  # HttpOnly
    [self, httponly_v] = perllib.list_of_n(_args, 2)
    if httponly_v is not None:
        self["httponly"] = httponly_v

    return self.get("httponly")


CGI.Cookie.httponly = httponly


def path(*_args):
    [self, path_v] = perllib.list_of_n(_args, 2)
    if path_v is not None:
        self["path"] = path_v

    return self.get("path")


CGI.Cookie.path = path


def max_age(*_args):
    [self, max_age_v] = perllib.list_of_n(_args, 2)
    if max_age_v is not None:
        self["max-age"] = perllib.num(CGI.Util.expire_calc(max_age_v)) - perllib.time()

    return self.get("max-age")


CGI.Cookie.max_age = max_age


def expires(*_args):
    [self, expires_v] = perllib.list_of_n(_args, 2)
    if expires_v is not None:
        self["expires"] = CGI.Util.expires(expires_v, "cookie")

    return self.get("expires")


CGI.Cookie.expires = expires


def secure(*_args):
    [self, secure_v] = perllib.list_of_n(_args, 2)
    if secure_v is not None:
        self["secure"] = secure_v

    return self.get("secure")


CGI.Cookie.secure = secure


def domain(*_args):
    [self, domain_v] = perllib.list_of_n(_args, 2)
    if domain_v is not None:
        self["domain"] = _str(domain_v).lower()

    return self.get("domain")


CGI.Cookie.domain = domain


def value(*_args, wantarray=False):

    values_ = perllib.Array()
    [self, value_v] = perllib.list_of_n(_args, 2)
    if value_v is not None:
        values_ = perllib.Array(
            value_v
            if perllib.refs(value_v) == "ARRAY"
            else value_v
            if perllib.refs(value_v) == "HASH"
            else (value_v)
        )
        self["value"] = values_.copy()

    return self.get("value") if wantarray else self["value"][0]


CGI.Cookie.value = value

# accessors


def name(*_args):
    [self, name_v] = perllib.list_of_n(_args, 2)
    if name_v is not None:
        self["name"] = name_v

    return self.get("name")


CGI.Cookie.name = name


def bake(*_args):
    global MOD_PERL
    [self, r] = perllib.list_of_n(_args, 2)

    def _f162():
        return (
            (Apache2.RequestUtil.request(Apache2.RequestUtil))
            if MOD_PERL == 2
            else Apache.request()
        )

    if MOD_PERL:
        _eval_result166 = None
        try:
            _eval_result166 = _f162()
        except Exception:
            pass

        r = r or _eval_result166

    if r:
        return perllib.method_call(r.err_headers_out(), "add", "Set-Cookie", self.as_string())
    else:
        import CGI as _CGI

        return perllib.perl_print(CGI.header("-cookie", self), end="")


CGI.Cookie.bake = bake


def compare(*_args):
    [self, value_v] = perllib.list_of_n(_args, 2)
    return perllib.cmp(f"{_bn(self)}", value_v)


CGI.Cookie.compare = compare


def as_string(*_args):
    _args = list(_args)
    global _d
    try:
        _locals_stack.append(perllib.WARNING)
        self = _args.pop(0) if _args else None
        if not self.name():
            return ""

        perllib.WARNING = 0  # some things may be undefined, that's OK.

        name_v = escape(self.name())
        value_v = "&".join(
            map(
                _str,
                (
                    perllib.flatten(
                        map(lambda _d: escape(_d), perllib.make_list(self.value(wantarray=True)))
                    )
                ),
            )
        )
        cookie = perllib.Array([f"{_bn(name_v)}={value_v}"])

        if self.domain():
            cookie.extend(perllib.make_list("domain=" + _str(self.domain())))

        if self.path():
            cookie.extend(perllib.make_list("path=" + _str(self.path())))

        if self.expires():
            cookie.extend(perllib.make_list("expires=" + _str(self.expires())))

        if self.max_age():
            cookie.extend(perllib.make_list("max-age=" + _str(self.max_age())))

        if self.secure():
            cookie.append("secure")

        if self.httponly():
            cookie.append("HttpOnly")

        if self.samesite():
            cookie.extend(perllib.make_list("SameSite=" + _str(self.samesite())))

        return "; ".join(map(_str, cookie))

    finally:
        perllib.WARNING = _locals_stack.pop()


CGI.Cookie.as_string = as_string


def new(*_args):
    _args = list(_args)
    [class_, *params] = perllib.list_of_at_least_n(_args, 1)
    params = perllib.Array(params)
    class_ = perllib.ref_scalar(class_) or class_
    # Ignore mod_perl request object--compatibility with Apache::Cookie.
    _eval_result106 = None
    try:
        _eval_result106 = perllib.isa(params[0], "Apache::Request::Req") or perllib.isa(
            params[0], "Apache"
        )
    except Exception:
        pass

    if perllib.ref_scalar(params[0]) and _eval_result106:
        (_args.pop(0) if _args else None)

    [
        name_v,
        value_v,
        path_v,
        domain_v,
        secure_v,
        expires_v,
        max_age_v,
        httponly_v,
        samesite_v,
    ] = perllib.list_of_n(
        rearrange(
            perllib.Array(
                [
                    "NAME",
                    ["VALUE", "VALUES"],
                    "PATH",
                    "DOMAIN",
                    "SECURE",
                    "EXPIRES",
                    "MAX-AGE",
                    "HTTPONLY",
                    "SAMESITE",
                ]
            ),
            *params,
        ),
        9,
    )
    if not (name_v is not None and value_v is not None):
        return None

    self = perllib.Hash()
    self = perllib.bless(self, class_)
    self.name(name_v)
    self.value(value_v)
    path_v = path_v or "/"
    if path_v is not None:
        self.path(path_v)

    if domain_v is not None:
        self.domain(domain_v)

    if secure_v is not None:
        self.secure(secure_v)

    if expires_v is not None:
        self.expires(expires_v)

    if max_age_v is not None:
        self.max_age(max_age_v)

    if httponly_v is not None:
        self.httponly(httponly_v)

    if samesite_v is not None:
        self.samesite(samesite_v)

    return self


CGI.Cookie.new = types.MethodType(new, CGI.Cookie)


def parse(*_args, wantarray=False):
    global _d
    [self, raw_cookie] = perllib.list_of_n(_args, 2)
    if not raw_cookie:
        return perllib.Array() if wantarray else perllib.Hash()

    results = perllib.Hash()

    pairs = perllib.Array(perllib.split(r"[;,] ?", _str(raw_cookie)))
    for _i79, _d in enumerate(pairs):
        _d = re.sub(r"^\s+", r"", _str(_d), count=1)
        pairs[_i79] = _d
        _d = re.sub(r"\s+$", r"", _str(_d), count=1)
        pairs[_i79] = _d

        [key, value_v] = perllib.list_of_n(_str(_d).split("=", 2 - 1), 2)

        # Some foreign cookies are not in name=value format, so ignore
        # them.
        if value_v is None:
            continue

        values_ = perllib.Array()
        if _str(value_v) != "":
            values_ = perllib.Array(
                perllib.flatten(
                    map(
                        lambda _d: unescape(_d),
                        perllib.make_list(perllib.split(r"[&;]", _str(value_v) + "&dmy")),
                    )
                )
            )
            (values_.pop() if values_ else None)

        key = unescape(key)
        # A bug in Netscape can cause several cookies with same name to
        # appear.  The FIRST one in HTTP_COOKIE is the most recent version.
        results[_str(key)] = results[_str(key)] or self.new("-name", key, "-value", values_)

    return results if wantarray else results


CGI.Cookie.parse = parse


def get_raw_cookie(*_args):
    _args = list(_args)
    global MOD_PERL
    r = _args.pop(0) if _args else None

    def _f59():
        return (
            (Apache2.RequestUtil.request(Apache2.RequestUtil))
            if MOD_PERL == 2
            else Apache.request()
        )

    if MOD_PERL:
        _eval_result61 = None
        try:
            _eval_result61 = _f59()
        except Exception:
            pass

        r = r or _eval_result61

    if r:
        return r.headers_in().get("Cookie")

    if MOD_PERL and not "REQUEST_METHOD" in os.environ:
        raise Die(f"Run {_bn(r)}->subprocess_env; before calling fetch()")

    return os.environ.get("HTTP_COOKIE") or os.environ.get("COOKIE")


CGI.Cookie.get_raw_cookie = get_raw_cookie

# Fetch a list of cookies from the environment or the incoming headers and
# return as a hash. The cookie values are not unescaped or altered in any way.


def raw_fetch(*_args, wantarray=False):
    _args = list(_args)
    try:
        class_ = _args.pop(0) if _args else None
        if not (raw_cookie := get_raw_cookie(*_args)):
            return perllib.Array() if wantarray else None

        results = perllib.Hash()
        key = value_v = None

        pairs = perllib.Array(perllib.split(r"[;,] ?", _str(raw_cookie)))
        for _i47, pair_l in enumerate(pairs):
            pair_l = re.sub(
                re.compile(r"^\s+|\s+$"), r"", _str(pair_l), count=0
            )  # trim leading trailing whitespace
            pairs[_i47] = pair_l
            [key, value_v] = perllib.list_of_n(_str(pair_l).split("="), 2)

            value_v = value_v if value_v is not None else ""
            results[_str(key)] = value_v

        return results if wantarray else results
    except FunctionReturn as _r:
        return _r.args[0]


CGI.Cookie.raw_fetch = raw_fetch

# fetch a list of cookies from the environment and
# return as a hash.  the cookies are parsed as normal
# escaped URL data.


def fetch(*_args):
    _args = list(_args)
    try:
        class_ = _args.pop(0) if _args else None
        if not (raw_cookie := get_raw_cookie(*_args)):
            return

        return class_.parse(raw_cookie)
    except FunctionReturn as _r:
        return _r.args[0]


CGI.Cookie.fetch = fetch


def __gt__(self, other):  # extra overload '>'
    return compare(self, other, False) > 0


CGI.Cookie.__gt__ = __gt__


def __ge__(self, other):  # extra overload '>='
    return compare(self, other, False) >= 0


CGI.Cookie.__ge__ = __ge__


def __ne__(self, other):  # extra overload '!='
    return compare(self, other, False) != 0


CGI.Cookie.__ne__ = __ne__


def __eq__(self, other):  # extra overload '=='
    return compare(self, other, False) == 0


CGI.Cookie.__eq__ = __eq__


def __le__(self, other):  # extra overload '<='
    return compare(self, other, False) <= 0


CGI.Cookie.__le__ = __le__


def __lt__(self, other):  # extra overload '<'
    return compare(self, other, False) < 0


CGI.Cookie.__lt__ = __lt__


def __rcmp__(self, other):  # reversed overload 'cmp'
    return compare(self, other, True)


CGI.Cookie.__rcmp__ = __rcmp__


def __cmp__(self, other):  # use overload 'cmp'
    return compare(self, other, False)


CGI.Cookie.__cmp__ = __cmp__


def __str__(self):  # use overload '""'
    return _str(as_string(self, None, False))


CGI.Cookie.__str__ = __str__

MOD_PERL = 0
_d = ""
_legal_samesite = perllib.Hash()

builtins.__PACKAGE__ = "CGI.Cookie"

# SKIPPED: use strict;
perllib.WARNING = 1

CGI.Cookie.VERSION_v = "4.54"

CGI.Cookie.escape = escape
CGI.Cookie.rearrange = rearrange
CGI.Cookie.unescape = unescape
setattr(CGI.Cookie, '(""', as_string)
setattr(CGI.Cookie, "(cmp", compare)
PERLEX = 0
# Turn on special checking for ActiveState's PerlEx
if os.environ.get("GATEWAY_INTERFACE") is not None and (
    re.search(r"^CGI-PerlEx", _str(os.environ.get("GATEWAY_INTERFACE")))
):
    PERLEX += 1

# Turn on special checking for mod_perl
# PerlEx::DBI tries to fool DBI by setting MOD_PERL

MOD_PERL = 0
if "MOD_PERL" in os.environ and not PERLEX:
    if (
        "MOD_PERL_API_VERSION" in os.environ
        and perllib.num(os.environ.get("MOD_PERL_API_VERSION")) == 2
    ):
        MOD_PERL = 2
        import Apache2.RequestUtil as _Apache2_RequestUtil
        import APR.Table as _APR_Table
    else:
        MOD_PERL = 1
        import Apache as _Apache

_legal_samesite = perllib.Hash({"Strict": 1, "Lax": 1, "None": 1})
"""
=head1 NAME

CGI::Cookie - Interface to HTTP Cookies

=head1 SYNOPSIS

    use CGI qw/:standard/;
    use CGI::Cookie;

    # Create new cookies and send them
    $cookie1 = CGI::Cookie->new(-name=>'ID',-value=>123456);
    $cookie2 = CGI::Cookie->new(-name=>'preferences',
                               -value=>{ font => Helvetica,
                                         size => 12 } 
                               );
    print header(-cookie=>[$cookie1,$cookie2]);

    # fetch existing cookies
    %cookies = CGI::Cookie->fetch;
    $id = $cookies{'ID'}->value;

    # create cookies returned from an external source
    %cookies = CGI::Cookie->parse($ENV{COOKIE});

=head1 DESCRIPTION

CGI::Cookie is an interface to HTTP/1.1 cookies, a mechanism
that allows Web servers to store persistent information on
the browser's side of the connection.  Although CGI::Cookie is
intended to be used in conjunction with CGI.pm (and is in fact used by
it internally), you can use this module independently.

For full information on cookies see 

    https://tools.ietf.org/html/rfc6265

=head1 USING CGI::Cookie

CGI::Cookie is object oriented.  Each cookie object has a name and a
value.  The name is any scalar value.  The value is any scalar or
array value (associative arrays are also allowed).  Cookies also have
several optional attributes, including:

=over 4

=item B<1. expiration date>

The expiration date tells the browser how long to hang on to the
cookie.  If the cookie specifies an expiration date in the future, the
browser will store the cookie information in a disk file and return it
to the server every time the user reconnects (until the expiration
date is reached).  If the cookie species an expiration date in the
past, the browser will remove the cookie from the disk file.  If the
expiration date is not specified, the cookie will persist only until
the user quits the browser.

=item B<2. domain>

This is a partial or complete domain name for which the cookie is 
valid.  The browser will return the cookie to any host that matches
the partial domain name.  For example, if you specify a domain name
of ".capricorn.com", then the browser will return the cookie to
Web servers running on any of the machines "www.capricorn.com", 
"ftp.capricorn.com", "feckless.capricorn.com", etc.  Domain names
must contain at least two periods to prevent attempts to match
on top level domains like ".edu".  If no domain is specified, then
the browser will only return the cookie to servers on the host the
cookie originated from.

=item B<3. path>

If you provide a cookie path attribute, the browser will check it
against your script's URL before returning the cookie.  For example,
if you specify the path "/cgi-bin", then the cookie will be returned
to each of the scripts "/cgi-bin/tally.pl", "/cgi-bin/order.pl", and
"/cgi-bin/customer_service/complain.pl", but not to the script
"/cgi-private/site_admin.pl".  By default, the path is set to "/", so
that all scripts at your site will receive the cookie.

=item B<4. secure flag>

If the "secure" attribute is set, the cookie will only be sent to your
script if the CGI request is occurring on a secure channel, such as SSL.

=item B<5. httponly flag>

If the "httponly" attribute is set, the cookie will only be accessible
through HTTP Requests. This cookie will be inaccessible via JavaScript
(to prevent XSS attacks).

This feature is supported by nearly all modern browsers.

See these URLs for more information:

    http://msdn.microsoft.com/en-us/library/ms533046.aspx
    http://www.browserscope.org/?category=security&v=top

=item B<6. samesite flag>

Allowed settings are C<Strict>, C<Lax> and C<None>.

As of June 2016, support is limited to recent releases of Chrome and Opera.

L<https://tools.ietf.org/html/draft-west-first-party-cookies-07>

=back

=head2 Creating New Cookies

	my $c = CGI::Cookie->new(-name    =>  'foo',
                             -value   =>  'bar',
                             -expires =>  '+3M',
                           '-max-age' =>  '+3M',
                             -domain  =>  '.capricorn.com',
                             -path    =>  '/cgi-bin/database',
                             -secure  =>  1,
                             -samesite=>  "Lax"
	                    );

Create cookies from scratch with the B<new> method.  The B<-name> and
B<-value> parameters are required.  The name must be a scalar value.
The value can be a scalar, an array reference, or a hash reference.
(At some point in the future cookies will support one of the Perl
object serialization protocols for full generality).

B<-expires> accepts any of the relative or absolute date formats
recognized by CGI.pm, for example "+3M" for three months in the
future.  See CGI.pm's documentation for details.

B<-max-age> accepts the same data formats as B<< -expires >>, but sets a
relative value instead of an absolute like B<< -expires >>. This is intended to be
more secure since a clock could be changed to fake an absolute time. In
practice, as of 2011, C<< -max-age >> still does not enjoy the widespread support
that C<< -expires >> has. You can set both, and browsers that support
C<< -max-age >> should ignore the C<< Expires >> header. The drawback
to this approach is the bit of bandwidth for sending an extra header on each cookie.

B<-domain> points to a domain name or to a fully qualified host name.
If not specified, the cookie will be returned only to the Web server
that created it.

B<-path> points to a partial URL on the current server.  The cookie
will be returned to all URLs beginning with the specified path.  If
not specified, it defaults to '/', which returns the cookie to all
pages at your site.

B<-secure> if set to a true value instructs the browser to return the
cookie only when a cryptographic protocol is in use.

B<-httponly> if set to a true value, the cookie will not be accessible
via JavaScript.

B<-samesite> may be C<Lax>, C<Strict>, or C<None> and is an evolving part
of the standards for cookies. Please refer to current documentation
regarding it.

For compatibility with Apache::Cookie, you may optionally pass in
a mod_perl request object as the first argument to C<new()>. It will
simply be ignored:

  my $c = CGI::Cookie->new($r,
                          -name    =>  'foo',
                          -value   =>  ['bar','baz']);

=head2 Sending the Cookie to the Browser

The simplest way to send a cookie to the browser is by calling the bake()
method:

  $c->bake;

This will print the Set-Cookie HTTP header to STDOUT using CGI.pm. CGI.pm
will be loaded for this purpose if it is not already. Otherwise CGI.pm is not
required or used by this module.

Under mod_perl, pass in an Apache request object:

  $c->bake($r);

If you want to set the cookie yourself, Within a CGI script you can send
a cookie to the browser by creating one or more Set-Cookie: fields in the
HTTP header.  Here is a typical sequence:

  my $c = CGI::Cookie->new(-name    =>  'foo',
                          -value   =>  ['bar','baz'],
                          -expires =>  '+3M');

  print "Set-Cookie: $c\n";
  print "Content-Type: text/html\n\n";

To send more than one cookie, create several Set-Cookie: fields.

If you are using CGI.pm, you send cookies by providing a -cookie
argument to the header() method:

  print header(-cookie=>$c);

Mod_perl users can set cookies using the request object's header_out()
method:

  $r->err_headers_out->add('Set-Cookie' => $c);

Internally, Cookie overloads the "" operator to call its as_string()
method when incorporated into the HTTP header.  as_string() turns the
Cookie's internal representation into an RFC-compliant text
representation.  You may call as_string() yourself if you prefer:

  print "Set-Cookie: ",$c->as_string,"\n";

=head2 Recovering Previous Cookies

	%cookies = CGI::Cookie->fetch;

B<fetch> returns an associative array consisting of all cookies
returned by the browser.  The keys of the array are the cookie names.  You
can iterate through the cookies this way:

	%cookies = CGI::Cookie->fetch;
	for (keys %cookies) {
	   do_something($cookies{$_});
        }

In a scalar context, fetch() returns a hash reference, which may be more
efficient if you are manipulating multiple cookies.

CGI.pm uses the URL escaping methods to save and restore reserved characters
in its cookies.  If you are trying to retrieve a cookie set by a foreign server,
this escaping method may trip you up.  Use raw_fetch() instead, which has the
same semantics as fetch(), but performs no unescaping.

You may also retrieve cookies that were stored in some external
form using the parse() class method:

       $COOKIES = `cat /usr/tmp/Cookie_stash`;
       %cookies = CGI::Cookie->parse($COOKIES);

If you are in a mod_perl environment, you can save some overhead by
passing the request object to fetch() like this:

   CGI::Cookie->fetch($r);

If the value passed to parse() is undefined, an empty array will returned in list
context, and an empty hashref will be returned in scalar context.

=head2 Manipulating Cookies

Cookie objects have a series of accessor methods to get and set cookie
attributes.  Each accessor has a similar syntax.  Called without
arguments, the accessor returns the current value of the attribute.
Called with an argument, the accessor changes the attribute and
returns its new value.

=over 4

=item B<name()>

Get or set the cookie's name.  Example:

	$name = $c->name;
	$new_name = $c->name('fred');

=item B<value()>

Get or set the cookie's value.  Example:

	$value = $c->value;
	@new_value = $c->value(['a','b','c','d']);

B<value()> is context sensitive.  In a list context it will return
the current value of the cookie as an array.  In a scalar context it
will return the B<first> value of a multivalued cookie.

=item B<domain()>

Get or set the cookie's domain.

=item B<path()>

Get or set the cookie's path.

=item B<expires()>

Get or set the cookie's expiration time.

=item B<max_age()>

Get or set the cookie's max_age value.

=back


=head1 AUTHOR INFORMATION

The CGI.pm distribution is copyright 1995-2007, Lincoln D. Stein. It is
distributed under the Artistic License 2.0. It is currently
maintained by Lee Johnson with help from many contributors.

Address bug reports and comments to: https://github.com/leejo/CGI.pm/issues

The original bug tracker can be found at: https://rt.cpan.org/Public/Dist/Display.html?Queue=CGI.pm

When sending bug reports, please provide the version of CGI.pm, the version of
Perl, the name and version of your Web server, and the name and version of the
operating system you are using.  If the problem is even remotely browser
dependent, please provide information about the affected browsers as well.

=head1 BUGS

This section intentionally left blank.

=head1 SEE ALSO

L<CGI::Carp>, L<CGI>

L<RFC 2109|http://www.ietf.org/rfc/rfc2109.txt>, L<RFC 2695|http://www.ietf.org/rfc/rfc2965.txt>

=cut
"""
