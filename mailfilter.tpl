MAXSPAMSCORE="3" 
logfile "$HOME/mailfilter.log"
 
# set default Maildir
MAILDIR="$HOME/Maildir"
 
# check if we're called from a .qmail-EXT instead of .qmail
import EXT
if ( $EXT )
{
  # does a vmailmgr user named $EXT exist?
  # if yes, deliver mail to his Maildir instead
  CHECKMAILDIR = `dumpvuser $EXT | grep '^Directory' | awk '{ print $2 }'`
  if ( $CHECKMAILDIR )
  {
    MAILDIR="$HOME/$CHECKMAILDIR"
  }
}
 
# check folder structure

# test for junk directory.
# If all three exist, use "Junk"

JUNKDIR=""
# Outlook style
`test -d "$MAILDIR/.Junk-E-Mail"`
if( $RETURNCODE == 0 )
{
  JUNKDIR=".Junk-E-Mail"
}
else 
{
  # Gmail style
  `test -d "$MAILDIR/.Spam"`
  if( $RETURNCODE == 0 )
  {
    JUNKDIR=".Spam"
  }
  else
  {

    # Thunderbird + all open source/ de-facto standard style
    `test -d "$MAILDIR/.Junk"`
    if( $RETURNCODE == 0 )
    {
      JUNKDIR=".Junk"
    }
  }
}

# if no directory of the above exist, create a "Junk" directory and use that.
if( $JUNKDIR = "" )
{
  `maildirmake "$MAILDIR/.Junk"`
  JUNKDIR=".Junk"
}

`test -d "$MAILDIR/.Junk.als Spam lernen"`
if( $RETURNCODE == 1 )
{
  `maildirmake "$MAILDIR/.Junk.als Spam lernen"`
}
`test -d "$MAILDIR/.Junk.kein Spam"`
if( $RETURNCODE == 1 )
{
  `maildirmake "$MAILDIR/.Junk.kein Spam"`
}
 
# show the mail to SpamAssassin
xfilter "/usr/bin/spamc"
 
# now show the mail to DSPAM
xfilter "/package/host/localhost/dspam/bin/dspam --mode=teft --deliver=innocent,spam --stdout"
 
# if whitelisted by DSPAM just deliver
if ( /^X-DSPAM-Result: Whitelisted/)
{
  to "$MAILDIR"
}
 
# process SPAM
if ( /^X-Spam-Level: \*{$MAXSPAMSCORE,}$/ || /^X-DSPAM-Result: Spam/)
{
  MAILDIR="$MAILDIR/$JUNKDIR"
  # mark as read
  cc "$MAILDIR";
  `find "$MAILDIR/new/" -mindepth 1 -maxdepth 1 -type f -printf '%f\0' | xargs -0 -I {} mv "$MAILDIR/new/{}" "$MAILDIR/cur/{}:2,S"`
  exit
}
 
# and finally, deliver everything that survived our filtering
to "$MAILDIR"
