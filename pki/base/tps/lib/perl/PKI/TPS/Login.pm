#!/usr/bin/pkiperl
#
# --- BEGIN COPYRIGHT BLOCK ---
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation;
# version 2.1 of the License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA  02110-1301  USA 
# 
# Copyright (C) 2007 Red Hat, Inc.
# All rights reserved.
# --- END COPYRIGHT BLOCK ---
#

# wizard - 
#  Fedora Certificate System - Token Processing System configuration wizard


# This script is run as a 'mod_perl' CGI. Configure mod_perl by adding
# the following to /etc/httpd/conf.d/perl.conf
#
# PerlModule ModPerl::Registry
# PerlModule Apache::compat
# PerlModule RHCS::TPS::Wizard
# PerlSetEnv RHCS_DOCROOT /u/sparkins/t/cs_tip/certsystem/prj/common/ui
# <Location /wizard>
#    SetHandler perl-script
#    PerlHandler RHCS::TPS::Wizard
#    Order deny,allow
#    Allow from all
# </Location>


# Note: The Velocity parser is not very helpful when it comes to
# errors right now. Here are some common errors, and what they mean:
#
# ERROR:
#    [Mon Apr 03 13:57:33 2006] [error] [client 172.16.24.26] 
#    Can't use string ("0") as an ARRAY ref while "strict refs" 
#    in use at /usr/lib/perl5/site_perl/5.8.5/Template/Velocity.pm
#    line 423.\n, referer: http://chico/wizard?p=2
# MEANING
#    This probably means that your *.vm file refers to an array
#    variable in a foreach statement that is not defined
#    Check your foreach array variables.

use warnings;
use ModPerl::Registry;
use Template::Velocity;
use Getopt::Std;
use Data::Dumper;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use APR::Const    -compile => qw(:error SUCCESS);
use PKI::TPS::GlobalVar;
use PKI::TPS::WelcomePanel;
use PKI::TPS::SecurityDomainPanel;
use PKI::TPS::DisplayCertChainPanel;
use PKI::TPS::SubsystemTypePanel;
use PKI::TPS::CAInfoPanel;
use PKI::TPS::TKSInfoPanel;
use PKI::TPS::DRMInfoPanel;
use PKI::TPS::DisplayCertChain2Panel;
use PKI::TPS::AdminAuthPanel;
use PKI::TPS::AgentAuthPanel;
use PKI::TPS::AuthDBPanel;
use PKI::TPS::DatabasePanel;
use PKI::TPS::ModulePanel;
use PKI::TPS::SizePanel;
use PKI::TPS::NamePanel;
use PKI::TPS::ConfigHSMLoginPanel;
use PKI::TPS::CertRequestPanel;
use PKI::TPS::AdminPanel;
use PKI::TPS::ImportAdminCertPanel;
use PKI::TPS::LoginPanel;
use PKI::TPS::DonePanel;
use PKI::TPS::Config;

use PKI::TPS::Common qw(yes no r);

package PKI::TPS::Login;
$PKI::TPS::Login::VERSION = '1.00';

# read configuration file
my $flavor = `pkiflavor`;
$flavor =~ s/\n//g;

my $pkiroot = $ENV{PKI_ROOT};

my $config = PKI::TPS::Config->new();
$config->load_file("$pkiroot/conf/CS.cfg");
# read password cache file
my $pwdconf = PKI::TPS::Config->new();
$pwdconf->load_file("$pkiroot/conf/pwcache.conf");
if( -e "$pkiroot/conf/pwcache.conf" ) {
    system( "chmod 00660 $pkiroot/conf/pwcache.conf" );
}

# create cfg debug log
open(DEBUG, ">>" . $config->get("service.instanceDir") . 
                "/logs/debug");

# apache server

our $debug;

my $STATUS_OK = 1;
my $STATUS_ERROR = 2;
my $STATUS_REDIRECT = 3;

&debug_log("TPS wizard: starting up");
  
my $docroot = $ENV{PKI_DOCROOT};

if (! $docroot) {
    &debug_log("TPS wizard: ERROR: PKI_DOCROOT is null");
    return 0;
}

our $parser = new Template::Velocity($docroot);
our $symbol;
our @certtags;

makepanels();

&debug_log("TPS wizard: start up complete");

1;

sub debug_log
{
  my ($msg) = @_;
  my $date = `date`;
  chomp($date);
  print DEBUG "$date - $msg\n";
}

  # initializes entries in parser's global symbol table for panels
sub makepanels
{
    #REAL PANELS BELOW
    my $login = new  PKI::TPS::LoginPanel();

    $symbol{panels}  = [ 
        $login,           # com.netscape.cms.servlet.csadmin.WelcomePanel
    ];
};

sub render_panel
{
    my ($panelnum, $q) = @_;

    $symbol{errorString} = "";

    my $currentpanel;

    if ($q->param('op') && $q->param('op') eq "next") {
        $currentpanel = $symbol{panels}[$panelnum];
        # validate variables for panel
        if ($currentpanel->{validate}) {
            $currentpanel->{validate}($q);
        }
        # execute current panel
        my $status = "0";

        if ($currentpanel->{update}) {
            $status = $currentpanel->{update}($q);
            &debug_log("TPS wizard: update returns status '" . 
			$status . "'");
            if ($status == $STATUS_REDIRECT) {
              return $STATUS_REDIRECT;
            }
           
	}

        &debug_log("TPS wizard: about to find out about sub panel");
        if ($status eq "1") {
          if ($currentpanel->{hasSubPanel} && &{$currentpanel->{hasSubPanel}}($q)) {
              &debug_log("TPS wizard: has sub panel");
              $panelnum = $panelnum + 2;
	  } elsif ($currentpanel->{isSubPanel} && &{$currentpanel->{isSubPanel}}($q)) {
              &debug_log("TPS wizard: is sub panel");
              $panelnum = $panelnum - 1;
          } else {
              &debug_log("TPS wizard: no sub panel and is not subpanel");
              $panelnum = $panelnum + 1;
          }
        }
    } elsif ($q->param('op') && $q->param('op') eq "back") {
            $panelnum = $panelnum - 1;
            #check if this a subpanel, if so, go back to it's parent.
            #only handles one-deep at this point
            my $panel = $symbol{panels}[$panelnum];
            if (&{$panel->{isSubPanel}}($q)) {
                $panelnum = $panelnum - 1;
	    }
    } elsif ($q->param('op') && $q->param('op') eq "apply") {
        &debug_log("TPS wizard: update : apply button pressed");
        $currentpanel = $symbol{panels}[$panelnum];
        # validate variables for panel
        if ($currentpanel->{validate}) {
            $currentpanel->{validate}($q);
        }
        # execute current panel
        if ($currentpanel->{update}) {
            my $status = $currentpanel->{update}($q);
            &debug_log("TPS wizard: update returns status '" . 
			$status . "'");
            if ($status == $STATUS_REDIRECT) {
              return $STATUS_REDIRECT;
            }
           
	}
    }

    &debug_log("TPS wizard: after looking into about sub panel");

    # advance to next panel
    $currentpanel = $symbol{panels}[$panelnum];

    # initialize symbol table values
    $symbol{showApplyButton} = "false";

    # fill in variables for new panel
    if ($currentpanel->{panelvars}) {
        $Data::Dumper::Indent = 1;
        # The '&debug_log("q=".Dumper($q));' call must be commented out to fix
        # Bugzilla Bug #249923:  Incorrect file permissions on
        #                        various files and/or directories 
        # &debug_log("q=".Dumper($q));
        $currentpanel->{panelvars}($q);
    }

    $symbol{panel} = "tps/admin/console/config/".$currentpanel->{vmfile};

    #wizard.vm:
    $symbol{name}    = "Token Processing System";
    $symbol{title}   = $currentpanel->{getName}();
    if ($panelnum == 0) {
      $symbol{firstpanel} = "1";
    } else {
      $symbol{firstpanel} = "0";
    }
    if ($panelnum == 17) {
      $symbol{lastpanel}  = "1";
    } else {
      $symbol{lastpanel}  = "0";
    }
    $symbol{p}        = $panelnum;
    $symbol{subpanelno}        = $panelnum+1;
    $symbol{csstate}        = "1";

#    $symbol{urls}        = [ "cert1", "cert2" ];  #createsubsystem
#    $symbol{urls_size}   = 2;
#    $symbol{instanceId}  = "tps";
#    $symbol{errorString}  = "";

    #modulepanel
#    $symbol{certs}   = [ ];
#    $symbol{reqscerts}   = [ ];
    $symbol{ppcerts}   = [ ];

    return $STATUS_OK;
}



sub dbg {
    my $msg = shift;
    $::symbol{dbg} .= "$msg\n";
}

sub handler {
    my $r = shift;

    *::symbol = \%symbol;
    *::s = \$s;
    *::config = \$config;
    *::pwdconf = \$pwdconf;

    &debug_log("TPS wizard: in handler");
    if ($#ARGV == -1) {
        $r->send_http_header('text/html');
    }

    my $q = new CGI;

    # check cookie
    my $pin = $q->param('__pin');
    if (defined($pin)) {
         my $cookie = $q->cookie(
                -name=>'__pin',
                -value=> $pin,
                -expires=>'+1y',
                -path=>'/');
         print $q->redirect(-location => "wizard", -cookie => $cookie);
         return;
    }

    # output http parameters
    &debug_log("TPS wizard: uri='" . $ENV{REQUEST_URI} . "'");
    my @pnames = $q->param();
    foreach $pn (@pnames) {
      # added this facility so that password can be hidden,
      # all sensitive parameters should be prefixed with 
      # __ (double underscores); however, in the event that
      # a security parameter slips through, we perform multiple
      # additional checks to insure that it is NOT displayed
      if( $pn =~ /^__/                   ||
          $pn =~ /password$/             ||
          $pn =~ /passwd$/               ||
          $pn =~ /pwd$/                  ||
          $pn =~ /admin_password_again/i ||
          $pn =~ /bindpassword/i         ||
          $pn =~ /bindpwd/i              ||
          $pn =~ /passwd/i               ||
          $pn =~ /password/i             ||
          $pn =~ /pin/i                  ||
          $pn =~ /pwd/i                  ||
          $pn =~ /pwdagain/i             ||
          $pn =~ /uPasswd/i ) {
        &debug_log("TPS wizard: http parameter name='" . $pn . "' value='(sensitive)'");
      } else {
        &debug_log("TPS wizard: http parameter name='" . $pn . "' value='" . $q->param($pn) . "'");
      }
    }

    my $panelnum = $q->param('p');
    if (!defined($panelnum) || $panelnum eq "") {
      # Apache fails to pick up the p parameter after 
      # redirecting from the security domain. This is 
      # a quick hack to solve the issue.
      if ($ENV{'QUERY_STRING'} ne "") {
        $ENV{'QUERY_STRING'} =~ /p=([0-9]+)&/;
        $panelnum = $1;
      }
    }

    use subs qw(debug);
    *debug = \&Template::Velocity::Executor::debug;

    $::symbol{dbg} = "";

    &debug_log("TPS wizard: before argparsing");
    if ($#ARGV == -1) {
     $Data::Dumper::Maxdepth = 7;
        $startfile = "tps/admin/console/config/login.vm";
    }

    &debug_log("TPS wizard: setting up test objects");

    #initialize from config file
    my $certlist = $::config->get("preop.cert.list");
    if ($certlist eq "") {
       $certlist = "sslserver,subsystem"; 
    }
    @certtags = split(/,/, $certlist);
    $numtags =  @certtags;
    if ($numtags eq 0) {
         @certtags = ("sslserver", "subsystem");
    }
    &debug_log("TPS wizard: found $numtags certtags");

    if (! $panelnum) {
        $panelnum = 0;
    }

    my $status = render_panel($panelnum, $q);
    if ($status == 3) {
        $r->header_out(Location => $symbol{redirect});
        $r->status(301);
        $r->send_http_header();
        return;
    }

    use Data::Dumper;
    &debug_log("TPS wizard: executing file $startfile");
    foreach $q (sort keys %symbol) {
        &debug_log("TPS wizard:/config/wizard?p=9&SecToken=NSS%20Generic%20Crypto%20Services sym{$q}=".$symbol{$q});
    }

    my $result;
    if ($q->param("xml") eq "true") {
        $r->send_http_header('text/xml');
        $result = "<xml>";
        foreach $s (sort keys %symbol) {
          if ($s =~ /^__/) {
              next;
          }
          $result .= "<" . $s . ">"; 
          my $v = $symbol{$s};
          $result .= &get_xml($s, $v);
          $result .= "</" . $s . ">"; 
        }
        $result .= "</xml>";
    } else {
      $result = $parser->execute_file($startfile);
      if (!defined $result) {
          die("Couldn't execute template file: $docroot/$startfile");
      }
    }

    print "$result\n";
    return $STATUS_OK;
}

sub get_xml 
{
    my ($s, $v) = @_;

    my $result;
    if (ref($v) eq "HASH") {
      foreach my $xkey (keys %$v) {
              $result .= "<" . $xkey . ">";
              $result .= &get_xml($xkey, $v{$xkey});
          #    $result .= "-" . ref($xkey);
              $result .= "</" . $xkey . ">";
            }
    } elsif (ref($v) eq "PKI::TPS::CertInfo") {
              my $certinfo = $v;
              $result .= "<certinfo>";
              $result .= "<dn>" . $certinfo->get_dn() ."</dn>";
              $result .= "<tag>" . $certinfo->get_cert_tag() . "</tag>";
              $result .= "<friendly>" . $certinfo->get_user_friendly_name() .
                             "</friendly>";
              $result .= "</certinfo>";
    } elsif (ref($v) eq "PKI::TPS::ReqCertInfo") {
              my $reqcertinfo = $v;
              $result .= "<reqcertinfo>";
              $result .= "<name>" . $reqcertinfo->get_user_friendly_name() ."</name>";
              $result .= "<req>" . $reqcertinfo->get_request() ."</req>";
              $result .= "<cert>" . $reqcertinfo->get_cert() ."</cert>";
              $result .= "<certpp>" . $reqcertinfo->get_cert_pp() ."</certpp>";
              $result .= "<tag>" . $reqcertinfo->get_cert_tag() ."</tag>";
              $result .= "<dn>" . $reqcertinfo->get_cert_tag() ."</dn>";
              $result .= "</reqcertinfo>";
    } elsif (ref($v) eq "ARRAY") {
            my $pos = 0;
            foreach my $item (@$v) {
              $result .= "<element>";
              $result .= &get_xml("p" . $pos, $item);
          #    $result .= "-" . ref($item);
              $result .= "</element>";
              $pos++;
            }
    } else {
            $result .= $v;
    }
  return $result;
}

1;
