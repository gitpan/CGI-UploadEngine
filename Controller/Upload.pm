package MBC::Controller::Upload;

use strict;
use warnings;
use Catalyst 'Session';
use base 'Catalyst::Controller';
use CGI::UploadEngine;
use Moose;
use namespace::autoclean;

# Sets the actions in this controller to be registered with no prefix
__PACKAGE__->config->{namespace} = '';

=head1 NAME

MBC::Controller::Upload - Upload Controller for MBC

=head1 DESCRIPTION

Working Core for CGI::UploadEngine

=head1 METHODS

=over 4

=item * upload

The Core controller for CGI::UE. Validates uploaded file and returns success token.

=back

=cut

sub upload : Local {
        my ( $self, $c ) = @_;

	my $token = $c->request->param('token');
	my $upload = CGI::UploadEngine->new();
	my $file_obj;
	eval{
		#validate upload attempt
		$file_obj  = $upload->upload_validate({ token => $token });
	
		#upload file to server
		my ( $file_name, $target, $file_size, $success );
		if ( my $file = $c->request->upload('auto_file') ) {
			$file_name = $file->filename;
			$target   = $file_obj->{file_path} . '/' . $file_name;
			if ( not $file->link_to($target) and not $file->copy_to($target) ) {
				 die("ERROR: Failed to copy '$file_name' to '$target': $!");
			}
			$file_size = $file->size; 
			#check if file matches paremeters	
			#check file size
			my $min_size=$file_obj->{min_size};
			my $max_size=$file_obj->{max_size};
			if($file_size<$min_size){
				die("ERROR: file size $file_size is smaller than min size $min_size");
			}
			if($file_size>$max_size){
				die("ERROR: file size $file_size is larger than max size $max_size");
			}

			#check file type
			$file_name =~ /.*(\..*)$/;
			my $type=$1;
			my $allowed_types=$file_obj->{allowed_types};
			my $disallowed_types=$file_obj->{disallowed_types};
			if(length($allowed_types)>1){
				if(not $allowed_types =~ /$type/){
					die("ERROR: file type $type not allowed. Allowed types are: $allowed_types");
				}
			}elsif(length($disallowed_types)>1){
				if($disallowed_types =~ /$type/){
					die("ERROR: file type $type is forbidden. Forbidden types are: $disallowed_types");
				}
			}
			$success  = $upload->upload_success({ token => $token, file_name => $file_name, file_size => $file_size}); 
			$c->stash->{'success'} = '"' . $success . '"';
			$c->stash->{template} = 'upload.tt2';
			$c->response->header('Content-Type' => 'text/html');
		}else{
			die("ERROR: request upload failed");
		}
	};
	if($@){
		#check to see if exception is one of mine, and remove the exception origin 
		# from the end of the string as it will mess up the JSON
		if($@ =~ /(ERROR:.*)at \/.*/){
			#exception is mine, handle it
			$c->stash->{'success'} = '"' . $1 . '"';
			$c->stash->{template} = 'upload.tt2';
			$c->response->header('Content-Type' => 'text/html');
			warn($@);		
		}else{
			#rethrow exception that's not mine
			die($@);
		}
	}
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHORS

    Roger A Hall  C<< <rogerhall@cpan.org> >>
    Michael A Bauer  C<< <mbkodos@cpan.org> >>
    Kyle D Bolton  C<< <kdbolton@ualr.edu> >>
    Aleksandra A Markovets  C<< <aamarkovets@ualr.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2010, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights pre-served.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
