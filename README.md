# ddnsmouse
Dynamic DNS client for ipv6 Windows hosting (currently for dynv6.com) 


This is basically a fork from Chriv's "Dynephant", but more visible to the open public than just the fork.dy
ddnsmouse is a simple, open-source Dynamic DNS (DDNS) client for Windows. It was written because, at the time of it's creation, very few DDNS services had support for IPv6. More specifically, dynv6.com, a DDNS service, had support for IPv6, but no real Windows client.

It can be run either as an AutoIt3 script (requiring AutoIt3 to be installed), or a pre-compiled executable (requiring no runtime not already part of Windows). The dependency on IE for HTTPS creates some intrinsic limitations on reporting of errors (namely, that errors are known, but the cause is not automatically).

Currently there is only one exe which doesn't close automatically once you run it, but you can close it manually without the program stopping. 

* [Prerequisites](#prerequisites)
* [License](#license)
* [Usage](#usage)

##Prerequisites

* A relatively current version of Windows
* Internet Explorer 3 or higher installed

##License

ddnsmouse is licensed using the (extremely permissive) MIT license, as to the wishes of Chriv.
See the LICENSE.txt file.

The included icon is courtesy of https://pixabay.com/de/vectors/mouse-origami-papier-fold-kunst-4695476/
(link back not required by author if used)

##Usage

First, you need an account with dynv6.com, with at least one host (zone) and one record.

Once you have an account with dynv6.com, find your host name (record name) and
authentication token.

The command line arguments are:

    -host=<hostname> host name to update on DDNS service
    -token=<authentication_token> authentication token for host name to be updated
    -daemon=<seconds> number of seconds to wait between updates


-host and -token are required.
-Not changing -daemon results in an update attempt occuring every 10 minutes. Setting $daemon to less than 300 seconds (5 minutes) results in the default
of 1800 seconds (30 minutes) being used.
-host takes only the host name (leave off the dynv6.net part), not the FQDN.


The following example assumes your Fully Qualified Domain Name (FQDN)
for your host name is foobar.dynv6.net, and your authentication token
is randomtextforfoobarhere:

```
dynephant -host=foobar -token=randomtextforfoobarhere -6 -daemon=600
```
