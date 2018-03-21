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
use IO::Socket;
#use IRC::Toolkit::Colors;

# Prefix in case nick is in use
my $nick_prefix = "_"; # TODO: Maybe put in config

# Connects to IRC and returns a socket
sub create_irc_connection
{

	my ($irc_server, $irc_password, $irc_port, $irc_nick, $irc_nick_pass, $irc_user, $irc_name, $irc_channel, $irc_modes) = @_;

	# Create IRC connection
	my $irc_connection = IO::Socket::INET -> new(PeerAddr => $irc_server, PeerPort => $irc_port, Proto => "tcp");

	# Check IRC connection
	return 0 unless ($irc_connection);

	# Return connection
	return $irc_connection if (irc_connect($irc_connection, $irc_password, $irc_nick, $irc_nick_pass, $irc_user, $irc_name, $irc_channel, $irc_modes));

	# Return false
	return 0;

}

# IRC initial handshake
sub irc_connect
{
	my ($irc_connection, $irc_password, $irc_nick, $irc_nick_pass, $irc_user, $irc_name, $irc_channel, $irc_modes) = @_;

	irc_raw_message($irc_connection, "PASS $irc_password") if defined($irc_password);
	irc_raw_message($irc_connection, "NICK $irc_nick");
	irc_raw_message($irc_connection, "USER $irc_user 8 * :$irc_name");

	my $nickname = $irc_nick;

	while (my $irc_message = <$irc_connection>)
	{

		chop $irc_message;

		# Array of current IRC message
		my @message_split = split(/ /, $irc_message);
		my $irc_command = $message_split[1];

		# Initial ping/pong (for some servers)
		irc_raw_message($irc_connection, "PONG $1") if ($irc_message =~ /^PING(.*)$/i);

		# OK (004)
		if ($irc_command eq "004")
		{

			# User mode
			irc_raw_message($irc_connection, "MODE $nickname $irc_modes");

			# Try to identify to registered nickname, releasing it first
			if (defined($irc_nick_pass))
			{
				irc_raw_message($irc_connection, "PRIVMSG NickServ :release $irc_nick $irc_nick_pass");
				irc_raw_message($irc_connection, "PRIVMSG NickServ :ghost $irc_nick $irc_nick_pass");
				irc_raw_message($irc_connection, "NICK $irc_nick");
				irc_raw_message($irc_connection, "PRIVMSG NickServ :identify $irc_nick_pass");
			}

			# Join channel
			irc_raw_message($irc_connection, "JOIN $irc_channel");

			return 1;
		}

		# Nick in use (433)
		elsif ($irc_command eq "433")
		{
			# Retry with prefix
			$nickname = $nickname."".$nick_prefix;
			irc_raw_message($irc_connection, "NICK $nickname");
		}

	}

}

# Sends a message to a specific target
sub irc_send_message
{
	my ($connection, $target, $message) = @_;
	my @lines = split('\n', $message);
	foreach my $msg (@lines) {
		irc_raw_message($connection, "PRIVMSG ".$target." :".$msg);
	}
}

# Sends a raw message to an IRC server
sub irc_raw_message
{
	my ($connection, $message) = @_;

	# Send raw message
	print $connection "$message\r\n";
}

# Process IRC messages
sub process_irc_message
{
	my ($irc_connection, $message) = @_;

	# Ping
	if ($message =~ /^PING(.*)$/i)
	{
		# Pong reply
		irc_raw_message($irc_connection, "PONG $1");
		return 0;
	}
	else
	{

		# Split current message
		my @message_split = split(/ /, $message);
		my $irc_command = $message_split[1];
		my $irc_target = $message_split[2];
		my $irc_message = join(" ", @message_split[ 3 .. $#message_split ]); ($irc_message) =~ s/.//;
		my ($irc_sender) = $message_split[0] =~ /\:(.*)\!/;

		# Rejoin channel if kicked
		if ($irc_command eq "KICK")
		{
			irc_raw_message($irc_connection, "JOIN $irc_target");
			return 0;
		}
		elsif ($irc_command eq "PRIVMSG")
		{
			print("<IRC> ".$irc_target." ".$irc_sender.": ".$irc_message);

			# Return channel message
			# TODO: Validate nickname instead of checking for channel
			if ($irc_target =~ /^#(.*)$/i)
			{
				return "<".$irc_sender."> ".$irc_message;
			}
			return 0;
		}
		else {
			return 0;
		}
	}

}

1;
