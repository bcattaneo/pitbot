# pitbot

IRC <-> Telegram relay bot written in perl

Requirements:
------
* perl
* Modules:
  * IO::Socket::SSL
  * LWP::Protocol::https
  * LWP::Simple

Installation
------

Install perl (example)
```
sudo apt-get install perl
```

Install perl modules
```
sudo cpan IO::Socket::SSL LWP::Protocol::https LWP::Simple
```

Modify `config.json` file accordingly

Execute `pitbot.pl` (example)
```
chmod +x pitbot.pl
./pitbot.pl
```

TODO
------
* teknik uploads instead of local file storage (optional)
* Pretty IRC nicknames (maybe using IRC::Toolkit::Colors)
* Logs?
* Check other 'TODO's in source