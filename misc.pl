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
use LWP::Simple;
use LWP::UserAgent qw( );
use JSON qw( );

sub get_config
{
	my ($config_file) = @_;
	my $json_text = do {
	   open(my $json_fh, "<:encoding(UTF-8)", $config_file) or die("Can't open \$config_file\": $!\n");
	   local $/;
	   <$json_fh>
	};

	return decode_json($json_text);
}

sub decode_json
{
	my ($json_text) = @_;
	my $json = JSON->new;
	return $json->decode($json_text);
}

sub download_file
{
	my ($url, $file) = @_;
	getstore($url, $file);
}

sub http_get
{
	my ($url) = @_;

	my $ua = LWP::UserAgent->new();
	my $req = new HTTP::Request GET => $url;
	my $res = $ua->request($req);
	return $res->content;

}

1;
