#!/usr/bin/perl -w

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
use warnings;
use IO::Select;
use threads;

require "./misc.pl";
require "./irc.pl";
require "./telegram.pl";

# Process configuration data
my $config_data = get_config('config.json');

# Get IRC configuration
my $irc_server = $config_data->{irc}{server};
my $irc_password = $config_data->{irc}{password} if $config_data->{irc}{password} ne "";
my $irc_port = $config_data->{irc}{port};
my $irc_nick = $config_data->{irc}{nickname};
my $irc_nick_pass = $config_data->{irc}{nick_pass} if $config_data->{irc}{nick_pass} ne "";
my $irc_user = $config_data->{irc}{user_name};
my $irc_name = $config_data->{irc}{real_name};
my $irc_channel = $config_data->{irc}{channel};
my $irc_modes = $config_data->{irc}{modes};

# Get Telegram configuration
my $tg_group_id = $config_data->{telegram}{group_id};
my $tg_bot_token = $config_data->{telegram}{bot_token};
my $tg_base_url = $config_data->{telegram}{base_url};
my $tg_url = "https://$tg_base_url/";

# Main loop
while (1) {

	# Create IRC connection
	my $irc_connection = create_irc_connection($irc_server, $irc_password, $irc_port, $irc_nick, $irc_nick_pass, $irc_user, $irc_name, $irc_channel, $irc_modes);
	die "Unable to connect to IRC server $irc_server:$irc_port" if (!$irc_connection);

	# Selects for user input
	my $user_input = IO::Select -> new();
	$user_input -> add(\*STDIN);

	# Select for IRC incoming messages
	my $irc_messages = IO::Select -> new($irc_connection);

	# Thread for telegram incoming messages
	$SIG{ALRM} = sub {
		alarm(5);
		my $get_tg_messages = eval {
			for (tg_get_messages($tg_url, $tg_bot_token, $tg_group_id)) {
					my %messages = %$_;
					while ( my ($nickname, $message) = each %messages ) {
							# TODO: Pretty nicknames
							irc_send_message($irc_connection, $irc_channel, "<".$nickname."> ".$message);
					}
			}
		};
	};

	# Start TG messages thread
	alarm(5);

	# Selects loop
	while (1) {

		# Handles IRC server messages
		if ($irc_messages -> can_read(.5)) {
			my $irc_raw_message = <$irc_connection>;
			my $irc_message = process_irc_message($irc_connection, $irc_raw_message);
			if ($irc_message)
			{
				tg_send_message($tg_url, $tg_bot_token, $tg_group_id, $irc_message);
			}
		}

		# TODO: Handles user input (Unix only)
		#elsif ($user_input -> can_read(.5)) {
		#
		#	}

		# TODO: On disconnect, break this loop and reconnect
		# Also destroy $tg_messages thread
		# --

	}

}

alarm(0);
exit;
