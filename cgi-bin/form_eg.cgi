#!/usr/bin/perl -I.

use CGI::UploadEngine;
use Template;
require "upload_cfg.pl";
require "upload_html.pl";

# Create an upload object
my $upload = CGI::UploadEngine->new({ db => 'files', user => 'files', pass => 'tmie' });

# Set the view template
my $tmpl = 'upload/form_eg.tt2';

# Set the template variables
my $vars = { action_url  => $root_url . 'cgi-bin/handler_eg.cgi',
	     file_upload => $upload->upload_prepare({ file_path => '/tmp' }) };

# Process the template
my $result;
my $template = Template->new({ INCLUDE_PATH => $tmpl_incl });
   $template->process( $tmpl, $vars, \$result );

# Print the page
header();
print $result;
footer();

exit;

