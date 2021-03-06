#!/usr/bin/perl
#
# --- BEGIN COPYRIGHT BLOCK ---
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright (C) 2007 Red Hat, Inc.
# All rights reserved.
# --- END COPYRIGHT BLOCK ---
#
#
#
#

# wizard - 
#  Fedora Certificate System - Registration Authority System configuration wizard


# This script is run as a 'mod_perl' CGI. Configure mod_perl by adding
# the following to /etc/httpd/conf.d/perl.conf
#
# PerlModule ModPerl::Registry
# PerlModule Apache::compat
# PerlModule PKI::RA::Wizard
# PerlSetEnv PKI_DOCROOT /u/sparkins/t/cs_tip/certsystem/prj/common/ui
# <Location /wizard>
#    SetHandler perl-script
#    PerlHandler PKI::RA::Wizard
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
use PKI::RA::GlobalVar;
use PKI::RA::WelcomePanel;
use PKI::RA::SecurityDomainPanel;
use PKI::RA::DisplayCertChainPanel;
use PKI::RA::SubsystemTypePanel;
use PKI::RA::CAInfoPanel;
use PKI::RA::DisplayCertChain2Panel;
use PKI::RA::AdminAuthPanel;
use PKI::RA::AgentAuthPanel;
use PKI::RA::DatabasePanel;
use PKI::RA::ModulePanel;
use PKI::RA::SizePanel;
use PKI::RA::NamePanel;
use PKI::RA::ConfigHSMLoginPanel;
use PKI::RA::CertRequestPanel;
use PKI::RA::AdminPanel;
use PKI::RA::ImportAdminCertPanel;
use PKI::RA::DonePanel;
use PKI::RA::Config;

use PKI::RA::Common qw(yes no r);

package PKI::RA::Wizard;
$PKI::RA::Wizard::VERSION = '1.00';

# read configuration file
my $flavor = "pki";
$flavor =~ s/\n//g;

my $pkiroot = $ENV{PKI_ROOT};

my $config = PKI::RA::Config->new();
$config->load_file("$pkiroot/conf/CS.cfg");
# read password cache file
my $pwdconf = PKI::RA::Config->new();
$pwdconf->load_file("$pkiroot/conf/pwcache.conf");
# SELinux disallows performing a "chmod" on this file
if( $^O ne "linux" ) {
    system( "chmod 00660 $pkiroot/conf/pwcache.conf" );
}

# create cfg debug log
my $logfile = $config->get("service.instanceDir") .  "/logs/debug";
system( "touch $logfile" );
system( "chmod 00640 $logfile" );
open( DEBUG, ">>" . $logfile ) ||
warn( "Could not open '" . $logfile . "':  $!" );

# apache server

our $debug;

my $HTTP_OK = 0;

my $STATUS_OK = 0; # Apache 2 needs this to be zero
my $STATUS_ERROR = 2;
my $STATUS_REDIRECT = 3;

&debug_log("RA wizard: starting up");
  
my $docroot = $ENV{PKI_DOCROOT};

if (! $docroot) {
    &debug_log("RA wizard: ERROR: PKI_DOCROOT is null");
    return 0;
}

our $parser = new Template::Velocity($docroot);
our $symbol;
our @certtags;

makepanels();

&debug_log("RA wizard: start up complete");

1;

sub debug_log
{
  my ($msg) = @_;
  my $date = `date`;
  chomp($date);
  if( -w $logfile ) {
      print DEBUG "$date - $msg\n";
  }
}

  # initializes entries in parser's global symbol table for panels
sub makepanels
{
    #REAL PANELS BELOW
    my $welcome = new  PKI::RA::WelcomePanel();
    my $securitydomain = new PKI::RA::SecurityDomainPanel();
    my $displaycertchain = new PKI::RA::DisplayCertChainPanel();
    my $subsystem = new PKI::RA::SubsystemTypePanel();
    my $cainfopanel = new PKI::RA::CAInfoPanel();
#    my $displaycertchain2 = new PKI::RA::DisplayCertChain2Panel();
    my $databasepanel = new  PKI::RA::DatabasePanel();
    my $modulepanel = new PKI::RA::ModulePanel();
    my $confighsmloginpanel = new PKI::RA::ConfigHSMLoginPanel();
    my $sizepanel   = new PKI::RA::SizePanel();
    my $namepanel   = new  PKI::RA::NamePanel();
    my $certrequestpanel = new  PKI::RA::CertRequestPanel();
    my $adminpanel = new PKI::RA::AdminPanel();
    my $importadmincertpanel = new  PKI::RA::ImportAdminCertPanel();
    my $donepanel = new PKI::RA::DonePanel();

    $symbol{panels}  = [ 
        $welcome,           # com.netscape.cms.servlet.csadmin.WelcomePanel
        $securitydomain,    # com.netscape.cms.servlet.csadmin.SecurityDomainPanel
        $displaycertchain,  # com.netscape.cms.servlet.csadmin.DisplayCertChainPanel
        $subsystem,         # com.netscape.cms.servlet.csadmin.CreateSubsystemPanel
        $cainfopanel,       # com.netscape.cms.servlet.csadmin.CAInfoPanel
#        $displaycertchain2,  # com.netscape.cms.servlet.csadmin.DisplayCertChain2Panel
        $databasepanel,     # com.netscape.cms.servlet.csadmin.DatabasePanel
        $modulepanel,       # com.netscape.cms.servlet.csadmin.ModulePanel
        $confighsmloginpanel,        # com.netscape.cms.servlet.csadmin.ConfigHSMLoginPanel
        $sizepanel,         # com.netscape.cms.servlet.csadmin.SizePanel
        $namepanel,         # com.netscape.cms.servlet.csadmin.NamePanel
        $certrequestpanel,  # com.netscape.cms.servlet.csadmin.CertRequestPanel
        $adminpanel,        # com.netscape.cms.servlet.csadmin.AdminPanel
        $importadmincertpanel,  # com.netscape.cms.servlet.csadmin.ImportAdminCertPanel
        $donepanel,         # com.netscape.cms.servlet.csadmin.DonePanel</param-value>
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
            &debug_log("RA wizard: update returns status '" . 
			$status . "'");
            if ($status == $STATUS_REDIRECT) {
              return $STATUS_REDIRECT;
            }
           
	}

        &debug_log("RA wizard: about to find out about sub panel");
        if ($status eq "1") {
          if ($currentpanel->{hasSubPanel} && &{$currentpanel->{hasSubPanel}}($q)) {
              &debug_log("RA wizard: has sub panel");
              $panelnum = $panelnum + 2;
	  } elsif ($currentpanel->{isSubPanel} && &{$currentpanel->{isSubPanel}}($q)) {
              &debug_log("RA wizard: is sub panel");
              $panelnum = $panelnum - 1;
          } else {
              &debug_log("RA wizard: no sub panel and is not subpanel");
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
        &debug_log("RA wizard: update : apply button pressed");
        $currentpanel = $symbol{panels}[$panelnum];
        # validate variables for panel
        if ($currentpanel->{validate}) {
            $currentpanel->{validate}($q);
        }
        # execute current panel
        if ($currentpanel->{update}) {
            my $status = $currentpanel->{update}($q);
            &debug_log("RA wizard: update returns status '" . 
			$status . "'");
            if ($status == $STATUS_REDIRECT) {
              return $STATUS_REDIRECT;
            }
           
	}
    }

    &debug_log("RA wizard: after looking into about sub panel");

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

    $symbol{panel} = "ra/admin/console/config/".$currentpanel->{vmfile};

    #wizard.vm:
    $symbol{name}    = "Registration Authority";
    $symbol{title}   = $currentpanel->{getName}();
    if ($panelnum == 0) {
      $symbol{firstpanel} = "1";
    } else {
      $symbol{firstpanel} = "0";
    }
    if ($panelnum == 13) {
      $symbol{lastpanel}  = "1";
    } else {
      $symbol{lastpanel}  = "0";
    }
    $symbol{p}        = $panelnum;
    $symbol{subpanelno}        = $panelnum+1;
    $symbol{productversion}    =  $::config->get("preop.product.version");
    $symbol{csstate}        = "1";

#    $symbol{urls}        = [ "cert1", "cert2" ];  #createsubsystem
#    $symbol{urls_size}   = 2;
#    $symbol{instanceId}  = "ra";
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

    &debug_log("RA wizard: in handler");

    my $q = new CGI;

    # check cookie
    my $cookie = $q->cookie('pin');
    my $pin = $::config->get("preop.pin");
    if ($cookie ne $pin) {
         print $q->redirect("login");
         return;
    }

    # output http parameters
    &debug_log("RA wizard: uri='" . $ENV{REQUEST_URI} . "'");
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
          $pn =~ /directoryManagerPwd/i  ||
          $pn =~ /bindpassword/i         ||
          $pn =~ /bindpwd/i              ||
          $pn =~ /passwd/i               ||
          $pn =~ /password/i             ||
          $pn =~ /pin/i                  ||
          $pn =~ /pwd/i                  ||
          $pn =~ /pwdagain/i             ||
          $pn =~ /uPasswd/i ) {
        &debug_log("RA wizard: http parameter name='" . $pn . "' value='(sensitive)'");
      } else {
        &debug_log("RA wizard: http parameter name='" . $pn . "' value='" . $q->param($pn) . "'");
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

    &debug_log("RA wizard: before argparsing");
    if ($#ARGV == -1) {
     $Data::Dumper::Maxdepth = 7;
        $startfile = "ra/admin/console/config/wizard.vm";
    }

    &debug_log("RA wizard: setting up test objects");

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
    &debug_log("RA wizard: found $numtags certtags");

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
    &debug_log("RA wizard: executing file $startfile");
    foreach $q (sort keys %symbol) {
        &debug_log("RA wizard:/config/wizard?p=9&SecToken=NSS%20Generic%20Crypto%20Services sym{$q}=".$symbol{$q});
    }

    my $result;
    if ($q->param('xml') && $q->param('xml') eq "true") {
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

    $r->send_http_header('text/html');
    print "$result\n";

    return $HTTP_OK;
}

sub escape_xml
{
  my ($v) = @_;
  $v =~ s/\"/&quot;/g;
  $v =~ s/\'/&apos;/g;
  $v =~ s/\&/&amp;/g;
  $v =~ s/</&lt;/g;
  $v =~ s/>/&gt;/g;
  return $v;
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
    } elsif (ref($v) eq "PKI::RA::CertInfo") {
              my $certinfo = $v;
              $result .= "<certinfo>";
              $result .= "<dn>" . $certinfo->get_dn() ."</dn>";
              $result .= "<tag>" . $certinfo->get_cert_tag() . "</tag>";
              $result .= "<friendly>" . $certinfo->get_user_friendly_name() .
                             "</friendly>";
              $result .= "</certinfo>";
    } elsif (ref($v) eq "PKI::RA::ReqCertInfo") {
              my $reqcertinfo = $v;
              $result .= "<reqcertinfo>";
              $result .= "<name>" . $reqcertinfo->get_user_friendly_name() ."</name>";
              $result .= "<req>" . $reqcertinfo->get_request() ."</req>";
              $result .= "<cert>" . $reqcertinfo->get_cert() ."</cert>";
              $result .= "<certpp>" . &escape_xml($reqcertinfo->get_cert_pp()) ."</certpp>";
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
            $result .= &escape_xml($v);
    }
  return $result;
}

1;
