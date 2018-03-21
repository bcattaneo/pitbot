#
# This file is part of pitbot.
#
# pitbot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pitbot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pitbot. If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use LWP::UserAgent qw( );
#use LWP::Simple;
use MIME::Base64;
use Data::Dumper;

my $offset = 0;
my $upload_base_url = "https://myhost.com/"; # TODO: Put in config, or don't store files locally

sub tg_get_messages
{
	my ($base_url, $bot_token, $group_id) = @_;
	my $method = "getUpdates";
	my $url = $base_url."bot".$bot_token."/".$method."?offset=".$offset;
	my $content = http_get($url);
	my $tg_json = decode_json($content);

	my @messages;

	# Process updates
	for my $updates (@{$tg_json->{result}})
	{
			# Only for our group messages
			if ($updates->{message}->{chat}->{id} == $group_id)
			{
				# Sender username
				my $message_from = $updates->{message}->{from}->{first_name};
				my $text_message = "";
				my $file_id;
				my $file_name;

				# Check if it's a reply
				if ($updates->{message}->{reply_to_message}) {
					$text_message = "[Reply to ".$updates->{message}->{reply_to_message}->{from}->{first_name}."] "
				}
				# Check if it's forwarded message
				elsif ($updates->{message}->{forward_from}) {
					$text_message = "[Forward from ".$updates->{message}->{forward_from}->{first_name}."] "
				}

				# Update types
				if ($updates->{message}->{text})
				{
					# Text message
					$text_message = $text_message.$updates->{message}->{text};
					push @messages, { $message_from => $text_message };
					print("<TG> ".$message_from.": ".$text_message);
				}
				elsif ($updates->{message}->{voice}->{file_id})
				{
					# Voice message
					$file_id = $updates->{message}->{voice}->{file_id};
					$file_name = $file_id.".oga";

					# TODO: Upload instead of storing files locally
					download_file(tg_get_file($base_url, $bot_token, $file_id), "voice/".$file_name);
					#tg_upload_file("voice/".$updates->{message}->{voice}->{file_id}.".oga");
					push @messages, { $message_from => $text_message.$upload_base_url."voice/".$file_name};
					print("<TG> ".$message_from.": ".$text_message.$upload_base_url."voice/".$file_name);
				}
				elsif ($updates->{message}->{photo}[2]->{file_id})
				{
					# Picture message
					$file_id = $updates->{message}->{photo}[2]->{file_id};
					$file_name = $file_id.".jpg";

					# TODO: Upload instead of storing files locally
					download_file(tg_get_file($base_url, $bot_token, $file_id), "photo/".$file_name);
					#tg_upload_file("photo/".$updates->{message}->{photo}[2]->{file_id}.".jpg");
					push @messages, { $message_from => $text_message.$upload_base_url."photo/".$file_name };
					print("<TG> ".$message_from.": ".$text_message.$upload_base_url."photo/".$file_name);
				}
				elsif ($updates->{message}->{document}->{file_id})
				{
					# Document message
					$file_id = $updates->{message}->{document}->{file_id};
					$file_name = $updates->{message}->{document}->{file_name};

					# TODO: Upload instead of storing files locally
					download_file(tg_get_file($base_url, $bot_token, $file_id), "document/".$file_name);
					#tg_upload_file("photo/".$updates->{message}->{photo}[2]->{file_id}.".jpg");
					push @messages, { $message_from => $text_message.$upload_base_url."document/".$file_name };
					print("<TG> ".$message_from.": ".$text_message.$upload_base_url."document/".$file_name);
				}
				elsif ($updates->{message}->{audio}->{file_id})
				{
					# Audio message
					$file_id = $updates->{message}->{audio}->{file_id};
					$file_name = $file_id.".mp3";

					# TODO: Upload instead of storing files locally
					download_file(tg_get_file($base_url, $bot_token, $file_id), "audio/".$file_name);
					#tg_upload_file("photo/".$updates->{message}->{photo}[2]->{file_id}.".jpg");
					push @messages, { $message_from => $text_message.$upload_base_url."audio/".$file_name };
					print("<TG> ".$message_from.": ".$text_message.$upload_base_url."audio/".$file_name);
				}
				else {
					# TODO: Add other update types (if there's any)
				}

				# Offset update
				$offset = $updates->{update_id} + 1;

			}
	}

	#print Dumper @messages;
	return @messages;

}

# Get file URL of file_id
sub tg_get_file
{
	my ($base_url, $bot_token, $file_id) = @_;
	my $method = "getFile";
	my $url = $base_url."bot".$bot_token."/".$method."?file_id=".$file_id;
	my $content = http_get($url);
	my $tg_json = decode_json($content);

	return $base_url."file/bot".$bot_token."/".$tg_json->{result}->{file_path};

}

# TODO: Fix/finish
sub tg_upload_file
{
	my ($base_url, $file_name) = @_;

	# base url : https://api.teknik.io/v1/

	my $method = "Upload";
	my $url = "https://api.teknik.io/v1/".$method;

	my $ua = LWP::UserAgent->new;
	my $response = $ua->post($url,
		Authorization => "Basic ".encode_base64('key'),
	  Content_Type => 'form-data',
	  Content => [
	     'file' => [ $file_name ],
	  ],
	);

	print Dumper $response;

}

# Send message to the telegram group
sub tg_send_message
{
	my ($base_url, $bot_token, $group_id, $message) = @_;
	my $method = "sendMessage";
	my $url = $base_url."bot".$bot_token."/".$method;
	my $ua = LWP::UserAgent->new();
	my $response = $ua -> post($url, [
	   chat_id => $group_id,
	   text => $message,
	]);
}

1;
