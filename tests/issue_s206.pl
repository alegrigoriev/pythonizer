# issue s206 - string range in definition generates bad code and arrays with other elements in [...] arrayrefs generate bad code
# from CGI.pl
use Carp::Assert;

%EXPORT_TAGS = (
	':html2' => [ 'h1' .. 'h6', qw/
		p br hr ol ul li dl dt dd menu code var strong em
		tt u i b blockquote pre img a address cite samp dfn html head
		base body Link nextid title meta kbd start_html end_html
		input Select option comment charset escapeHTML
	/ ],
	':html3' => [ qw/
		div table caption th td TR Tr sup Sub strike applet Param nobr
		embed basefont style span layer ilayer font frameset frame script small big Area Map
	/ ],
	':html4' => [ qw/
		abbr acronym bdo col colgroup del fieldset iframe
		ins label legend noframes noscript object optgroup Q
		thead tbody tfoot
	/ ],
	':form'     => [ qw/
		textfield textarea filefield password_field hidden checkbox checkbox_group
		submit reset defaults radio_group popup_menu button autoEscape
		scrolling_list image_button start_form end_form
		start_multipart_form end_multipart_form isindex tmpFileName uploadInfo URL_ENCODED MULTIPART
	/ ],
	':cgi' => [ qw/
		param multi_param upload path_info path_translated request_uri url self_url script_name
		cookie Dump raw_cookie request_method query_string Accept user_agent remote_host content_type
		remote_addr referer server_name server_software server_port server_protocol virtual_port
		virtual_host remote_ident auth_type http append save_parameters restore_parameters param_fetch
		remote_user user_name header redirect import_names put Delete Delete_all url_param cgi_error env_query_string
	/ ],
	':netscape' => [qw/blink fontsize center/],
	':ssl'      => [qw/https/],
	':cgi-lib'  => [qw/ReadParse PrintHeader HtmlTop HtmlBot SplitParam Vars/],
	':push'     => [qw/multipart_init multipart_start multipart_end multipart_final/],

	# bulk export/import
	':html'     => [qw/:html2 :html3 :html4 :netscape/],
	':standard' => [qw/:html2 :html3 :html4 :form :cgi :ssl/],
	':all'      => [qw/:html2 :html3 :html4 :netscape :form :cgi :ssl :push/]
);

assert(join(' ', @{$EXPORT_TAGS{':html2'}}) eq 'h1 h2 h3 h4 h5 h6 p br hr ol ul li dl dt dd menu code var strong em tt u i b blockquote pre img a address cite samp dfn html head base body Link nextid title meta kbd start_html end_html input Select option comment charset escapeHTML');

# Check other array refs with multiple arrays in them

my @arr1 = (1,2,3);
my @arr2 = (4,5);
my $aref1 = [@arr1, @arr2];
assert(scalar(@$aref1) == 5);
assert(join('', @$aref1) eq '12345');
my $aref2 = [@arr1, 4, 5];
assert(join('', @$aref2) eq '12345');
my $aref3 = [qw/1 2 3/, qw/4 5/];
assert(join('', @$aref3) eq '12345');
my $aref4 = [1,2,3,@arr2];
assert(join('', @$aref4) eq '12345');

print "$0 - test passed!\n";
