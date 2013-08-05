# Usage Instructions
# ~~~~~~~~~~~~~~~~~~
#  Usage: [n]awk -f ass.awk fname.trc   (But read the Portability Section !!)
#
#  Configuring Ass:
#   
#   By default, 'ass' attempts to dump as much information as possible and
#  assumes that the output is to be printed to screen. This means that 'ass'
#  runs in its slowest mode. Ass can be changed/speeded up by amending the
#  following variables in the BEGIN section :
#
#   interactive...........1 = show indication of processing [default]
#                         0 = don't show anything (faster)
#   verbose...............1 = prints additional info        [default]
#                         0 = don't show info (faster)
#   eventdetail...........1 = prints additional event info for selected events 
#                             [default] 
#                         0 = don't do the above (faster)
#   skipbranch............1 = Skip 'branch of' state objects cause by SQL*NET
#                             loopback sessions etc (default)
#                         0 = don't skip 'branch of' transactions
#   seqinfo...............1 = Output sequence number for WAITING processes
#			  0 = Do not dump seq# information.
#
# Portability
# ~~~~~~~~~~~
#  1) This uses the nawk extension of functions. Some variants of awk accept
#     this (eg HP-UX v10) and others do not. Use nawk if awk fails !!
#
#      Alpha OSF/1    nawk         IBM RS/6000   awk
#      Sun Solaris    nawk         HPUX          awk (v10)  ??? (v9)
#      Sun SunOS      nawk         Sequent       nawk
#
#  2) The Alpha version of awk can only handle 99 fields and will return 
#     a message like 'awk: Line ..... cannot have more than 99 fields'.
#     The w/a: Either change the identified line or use a different platform.
#
# Known Restrictions
# ~~~~~~~~~~~~~~~~~~
#  o The script assumes a certain structure to the System State. This means
#    that this cannot be used on systemstates produced by MVS or VM.
#    [To make it work the first two or three words need to be stripped from]
#    [each line in the systemstate trace file.                             ]
#
#  o This has been developed to work with Oracle7. It *may* work with Oracle
#    version 6 but this has not been tested.
#
#  o The code currently does not recognise processes that are CONVERTING locks.
#    Eg, I have an SX lock and I am requesting the higher SSX mode. 
#    This will result in the process as waiting for a lock when it owns it. Note
#    that if any other process has the resource locked then both are listed
#    as holding the resource but a SELF-DEADLOCK is not flagged.
#
#  o It looks like there may be a bug with listing processes that are 
#    blocking others because they have a buffer s.o. that others are waiting
#    on.
#
# Coding Notes
# ~~~~~~~~~~~~ 
#  o There's an obscure usage of building the blkres word list. It seems
#    that you cannot just say : blkres[a,b] = blkres[a,b] " " newval
#    You have to use a temporary variable ('tb' in our case) to achieve this.
#  o Sequent doesn't seem to like logical operators being used with regular
#    expressions. Hence the 'wait event' section had to be re-written to use
#    $0 ~ /a/ || $0 ~ /b/. Just try the following test :
#
#       NR == 1 && /a/ || /b/ { print }
#
# History
# ~~~~~~~
#  kquinn.uk	v1.0.0	04/96	Created
#  kquinn.uk	v1.0.1	04/96	Minor changes to run with nawk on OSF1 and AIX
#                               Blocking Section's output changed slightly
#  kquinn.uk    v1.0.2  04/96   Dumps object names for library objects 
#                               Now sequent-nawk aware                        
#                               First public release
#  kquinn.uk    v1.0.3  06/96   File I/O wait events now output file, block etc
#  kquinn.uk    v1.0.4  07/96   Parallel Query Dequeue Reason codes now output
#  kquinn.uk    v1.0.5  08/96   Added QC to QS code
#                               Added code to skip 'branch of' state objects
#  kquinn.uk    v1.0.5  03/97   Output Oracle command based on 'oct:' code.
#				(Note that only the PARENT session's command
#				 code is output).
#				Strip carriage returns (^M)
#  kquinn.uk    v1.0.6  10/97   Indicate dead processes
#  kquinn.uk    v1.0.7  09/98   Print some more wait information for certain
# 				wait events and handle waits on the sequence
#				enqueue.
#  kquinn.uk    v1.0.8  12/98   Minor changes
#				Changed to accomodate new systemstate format
#				so that we identify the start of a systemstate
#				correctly once more.
#				Added seq# processing for waiting processes.
#				Dumped more info for DFS lock acquisition
#  kquinn.uk    v1.0.9  03/00   Cater for change in 8i enqueue dump
#                               Dump who waits for who according to the 8i
#                               wait "blocking sess" information
#
# Current Enhancement Requests Oustanding
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  o Pick out error code in PQO Queue Ref's
#  o Test concatenating all array elements so that we affectively use singular
#    arrays. This may speed the processing depending upon how the implementation
#    of awk uses multi-dimensional arrays.
#
##############################################################################
# Any failure cases or suggested improvements then please Email KQUINN.UK    #
# with the details and the system state file (if relevant).                  #
##############################################################################

# Function : add_resource
# ~~~~~~~~~~~~~~~~~~~~~~~
function add_resource (pblkres, newpid) {
 if (index(pblkres, newpid))
   return pblkres;
 else
   return pblkres " " newpid;
}
# Function : sameseq
# ~~~~~~~~~~~~~~~~~~
function sameseq(ev1, ev2, seq1, seq2) {
 #printf("sameseq: Comparing :\n");
 #printf("Ev=(%s) seq=(%s)\n", ev1, seq1);
 #printf("against Ev=(%s) seq=(%s)\n", ev2, seq2);
 if (!seq1) return 0;
 if (seq1 != seq2) return 0;
 if (ev1 != ev2) return 0;

 if (ev1 ~ "'rdbms ipc message'" ||
     ev1 ~ "'smon timer'"	  ||
     ev1 ~ "'pmon timer'")
   return 0;
 return 1;
}
# Function : min
# ~~~~~~~~~~~~~~
function min(one, two) {
 return (one<two?one:two);
}
# Function: procevent
# ~~~~~~~~~~~~~~~~~~~
function procevent (str) {
 if (!eventdetail) return str;  
 realev = str;
 sub("^.* for ", "", str);
 sub("holding ", "", str);
 sub("acquiring ", "", str);
 #printf("DBG> String = '%s'\n", str);
 if (str == "'db file sequential read'"||str == "'db file scattered read'"   ||
     str == "'db file parallel write'" ||str == "'db file sequential write'" ||
     str == "'buffer busy waits'" || str == "'free buffer waits'" ||
     str == "'buffer deadlock'" || str == "'parallel query qref latch'")
  {
   getline; sub("",""); gsub("="," ");
   realev = realev " (" $2 $4 $6 ")";
  }
 else if (str == "'pipe get'")
  {
   getline; sub("","");
   realev = realev " (" $2 ")"; 
  }
 else if (str == "'parallel query dequeue wait'")
  {
   getline; sub("","");
   gsub("="," ");
   realev = realev " (" $2 $4 $6 ")";
   print_pqo = 1;
  }
 else if (str == "'enqueue'" || "'DFS lock acquisition'")
  {
   getline; sub("",""); gsub("="," ");
   # For now let's not do anything too clever !
   if (substr($2, 1, 4) == "5351")	# SQ - sequence
     realev = realev " (SQ(sequence) id=" $4 ")";
   else if (substr($2, 1, 4) == "5356")  # SV - sequence
     realev = realev " (SV(sequence) id=" $4 ")";
   ############################################
   ### The following tends to crowd the output.
   ############################################
   #else
   # realev = realev " (" $2 $4 $6 ")";
  }

 return realev;
}

# Function: pq_details
# ~~~~~~~~~~~~~~~~~~~~
function pq_details(rversion)
{
 split(rversion, _ver, ".");
 printf("\nAdditional Note:\n~~~~~~~~~~~~~~~~\n");
 printf(" A 'parallel query dequeue' wait event has been encountered. The\n");
 printf("arguments to this wait event are described below :\n\n");

 if (_ver[2] < 2)
  {
   printf(" Parameter 1 - Process Queue to Dequeue\n"); 
  }
 else
  {
#  Reasons can be seen in the fixed table X$KXFPSDS.
   printf(" Parameter 1 - Reason for Dequeue. One of (Based upon 7.2.x) :\n");
   printf("  0x01 - QC waiting for reply from Slaves for Parallel Recovery\n");
   printf("  0x02 - Slave Dequeueing for Parallel Recovery\n");
   printf("  0x03 - Waiting for the Join Group Message from new KXFP client\n");
   printf("  0x04 - QC dequeueing from Slaves after starting a Server Group\n");
   printf("  0x05 - Dequeueing a credit only\n");
   printf("  0x06 - Dequeueing to free up a NULL buffer\n");
   printf("  0x07 - Dequeueing to get the credit so that we can enqueue\n");
   printf("  0x08 - Testing for dequeue\n");
   printf("  0x09 - Slave is waiting to dequeue a message fragment from QC\n");
   printf("  0x0a - QC waiting for Slaves to parse SQL and return OK\n"); 
   printf("  0x0b - QC waiting to dequeue (execution reply) msg from slave\n");
   printf("  0x0c - QC waiting to dequeue (execution) msg from slave\n");
   printf("  0x0d - We are dequeueing a message (range partitioned)\n");
   printf("  0x0e - We are dequeueing samples (consumer) from the QC\n"); 
   printf("  0x0f - We are dequeueing a message (ordered)\n");
   printf("  0x10 - Range TQ producer and are waiting to dequeue\n");
   printf("  0x11 - Consumer waiting to dequeue prior to closing TQ\n");
  }

 printf(" Parameter 2 - Sleep Time/Sender Id\n");
 printf("   Time to sleep in 1/100ths of a second\n");
 printf("   If sleeptime greater than 0x10000000, the lower sixteen bits\n");
 printf("   indicate the slave number on the remote instance indicated by\n");
 printf("   the higher sixteen bits of the first 32 bits.\n");

 printf(" Parameter 3 - Number of passes through the dequeueing code\n\n");
 printf(" (This information assumes the trace file has a version number in the header)\n");
 return 0;
}

# Function: pq_qc2slave
# ~~~~~~~~~~~~~~~~~~~~~
#
# Note: If the following line is added in then the awk script causes awk to
#       CORE dump under HP and AIX. The line is designed to make variables have
#       local scope but unfortunately it cannot be used here.
#function pq_qc2slave(state_no       ,_tmp,_temp,_qcarr,_i,_j,_k,_qc,_slaveid)
function pq_qc2slave(state_no)
{
 if (!(_qc = split(qclist[state_no], _qcarr, " ")))
   return;

 printf("\nQuery Co-Ordinator to Query Slave Mapping\n");
 printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

## TODO: Add a Receiving/Sending message at end of line to denote what we are
##       up to.
#  o Make use of PS enqueues  (PS-instance-slave) (Output them in QC dump ?)
 for (_i=1; _i<=_qc; _i++)
  {
   printf("QC=%5s  [Count=%s]\n", _qcarr[_i], qc_cnt[state_no, _qcarr[_i]]-1);
   for (_j=0; _j<pqenq_cnt[state_no, _qcarr[_i]]; _j++)
    {
     split(pqenq[_qcarr[_i], _j], _pqtmp, "-");    
     printf("%10s Communicates with Slave %d (hex) on instance %d (%s)\n",  " ",
       _pqtmp[3], _pqtmp[2], pqenq[_qcarr[_i], _j]);
    }

  printf("%5s %8s %3s %8s %11s %11s %5s %7s %8s %4s\n", 
        "Slave", "Info", "Msg", "State", "From", "To", 
		"Type", "Status", "Mode","Err"); 
   for (_j=qc_cnt[state_no, _qcarr[_i]]-1; _j>0; _j--)
    {
     _temp = qc[state_no, _qcarr[_i], _j];
     _slaveid = slave[state_no, _temp]; 
     #printf("DBG: Slaveid = slave[sstate=%d, qref=%s]\n", state_no, _temp);
     _printed = 0;

     for (_k=0; _k<2; _k++)
      {
       _msg = pqdetail[state_no, _slaveid, _k];
       if (!_msg) continue; 
       
       split(_msg, _tmp, " ");

       printf("%5s %8s %3d %8s %11s %11s %5s %7s %8s %4s\n", 
	  _printed?" ":_slaveid, pqenq[_slaveid, 0], _k, _tmp[1], 
	  slave[state_no,_tmp[2]]?slave[state_no, _tmp[2]]:_tmp[2],
	  slave[state_no,_tmp[3]]?slave[state_no, _tmp[3]]:_tmp[3],
         _tmp[4], _tmp[5], _tmp[6], _tmp[7]);
     #printf("DBG: From = slave[sstate=%d, qref=%s]\n", state_no, _tmp[2]);
     #printf("DBG: To   = slave[sstate=%d, qref=%s]\n", state_no, _tmp[3]);
       _printed = 1;
      }
    }
  }

 printf("%*s------------------------\n", 25, " "); 
 printf("STATUS Key:\n");
 printf("  DEQ = buffer has been dequeued\n");         
 printf("  EML = buffer on emergency message list\n"); 
 printf("  ENQ = buffer has been enqueued\n");
 printf("  FLST= buffer is on SGA freelist\n");
 printf("  FRE = buffer is free (unused)\n");
 printf("  GEB = buffer has been gotten for enqueuing\n");
 printf("  GDB = dequeued buffer has been gotten \n");
 printf("  INV = buffer is invalid (non-existent)\n");
 printf("  QUE = buffer on queue message list\n");
 printf("  RCV = buffer has been received \n"); 
 printf("  NOFL= not on freelist (just removed)\n");

 printf("%*s------------------------\n", 30, " "); 
#                    KXFPMTYINV  0 - Invalid message (new buffer).         [INV]
#                    KXFPMTYNUL  1 - Null message, used to send credit.    [NUL]
#                    KXFPMTYJOI  2 - Join group, from QC to slaves.        [JOI]
#                    KXFPMTYERR  3 - Exiting group from slave to QC.       [ERR]
#                    KXFPMTYRQS  4 - Request for statistics, QC to slaves. [RQS]
#                    KXFPMTYSTA  5 - Statistics update, slaves to QC.      [STA]
#                    KXFPMTYDTA  6 - User data, stuff kxfp doesn't look at.[DTA]
#                    KXFPMTYJVR  7 - Slave to QC, ack and version number.
#          KXFPHSTRE :  0x01 - Stream mode, return credit immediately.    [STRE]
#          KXFPHDIAL :  0x02 - Dialog mode, expect a reply message.       [DIAL]
#          KXFPHNPNG :  0x04 - No pings, error if next message pings.     [NPNG]
#          KXFPMHPRI :  0x08 - Priority (JOIn|ERRor|EXIt) message.         [PRI]
#          KXFPMHSTP :  0x10 - Stream ping message. @@                     [STP]
#          KXFPMHNDS :  0x20 - Non-default sized buffer.                   [NDS]
#          KXFPMHCLR :  0x40 - Sent from a clear qref.                     [CLR]
#          KXFPMHNID :  0x80 - No implicit dequeue.                        [NID]
}

##############################################################################
#                   S T A R T   O F   P R O C E S S I N G                    #
#                                                                            #
# BEGIN Section: Can amend 'interactive', 'verbose' and 'eventdetail'.       #
##############################################################################
BEGIN		{ version="1.0.9"; lwidth=79; interactive=1; verbose=1;
		  eventdetail=1; skipbranch=1; seqinfo=1;
 tx1="Above is a list of all the processes. If they are waiting for a resource";
 tx2="then it will be given in square brackets. Below is a summary of the";
 tx3="waited upon resources, together with the holder of that resource.";
 tx4="Notes:\n\t~~~~~";
 tx5=" o A process id of '???' implies that the holder was not found in the";
 tx6="   systemstate."; 
 br1="WARNING: The following is a list of process id's that have state";
 br2="         objects that are NOT owned by the parent state object and as"
 br3="         such have been SKIPPED during processing. (These are typically";
 br4="         SQL*Net loopback sessions).";

 cmdtab[1]="Create Table"; cmdtab[2]="Insert";cmdtab[3]="Select";
 cmdtab[4]="Create Cluster";cmdtab[5]="Alter Cluster";cmdtab[6]="Update";
 cmdtab[7]="Delete";cmdtab[8]="drop Cluster";cmdtab[9]="Create Index";
 cmdtab[10]="Drop Index";cmdtab[11]="Alter Index";cmdtab[12]="Drop Table";
 cmdtab[13]="Create Sequence";cmdtab[14]="Alter Sequence";
 cmdtab[17]="Grant";cmdtab[18]="Revoke"; cmdtab[40]="Alter Tablespace";
 cmdtab[42]="Alter Session";cmdtab[44]="Commit";cmdtab[45]="Rollback";
 cmdtab[47]="PL/SQL Execute";
 cmdtab[62]="Analyze Table"; cmdtab[63]="Analyze Index";
 cmdtab[67]="Alter Profile"; cmdtab[85]="Truncate Table";
}

# Start of trace file
# ~~~~~~~~~~~~~~~~~~~
# Oracle7 Server Release 7.1.6.2.0 
# Oracle8 Enterprise Edition Release 8.0.5.0.0
/^Oracle7 Server Release 7\./	{ rdbms_ver = $4; next }
/^Oracle8 .* .* Release 8\./	{ rdbms_ver = $5; next }
/^Oracle8i /			{ rdbms_ver = $(NF-2); a8ienabled=1; next }

# Start of Systemstate
# ~~~~~~~~~~~~~~~~~~~~
/^SYSTEM STATE/		{ printf("\nStarting Systemstate %d\n", ++sstate);
			  lcount=1; insystate=1; inbranch=0; next }

# Skipped Lines
# ~~~~~~~~~~~~~
insystate!=1			{ next }
                                # Used for PQO--flds 1 and two are good enuf
				# Do NOT skip additional processing (ie no next)
# v1.0.9 - We need to save session state objects
/^ *SO:/			{ myso=$2; 
  			          getline; sub("","");; sotype=$1 " " $2; }

/PROCESS STATE/			{ insystate=0; next }
/SHUTDOWN: waiting for logins to complete/	{ next }

# Code to skip 'branch of' state objects which are caused by silly things 
# such as SQLNET loopback sessions 
skipbranch && inbranch > 0	{ tmp = $0;
				  sub(branchstr, "", tmp);
				  if (tmp !~ "^ ")
				    inbranch = 0;
				}
				    
/^  *branch of *$/		{ if (skipbranch)
				   {
				    sub("branch of.*", ""); branchstr="^" $0;
				    inbranch=length(branchstr); 
				    branchlst[sstate]=branchlst[sstate] " " pid;
         			    next 
				   }
				}

# Strip Carriage returns
//				{ sub("",""); }

# Start of New Process
# ~~~~~~~~~~~~~~~~~~~~ 
/PROCESS [0-9]*:/		{ pid=$2; inbranch=0;
				  # Need to use pidarray to avoid "holes"
				  # in processes causing us problems.
				  pidarray[sstate, ++pidcnt[sstate]] = pid;
				  handle=""; inpq = 0; 
				  # v1.0.9 - keep max pid for use with a8iblk[]
				  tmp = pid; sub(":", "", tmp);
				  numpid = tmp+0; # coerce
				  if (numpid > maxpid) maxpid = numpid;
				  if (!interactive) next;
				  if (++lcount > lwidth) lcount=1;
				  printf("%s", lcount==1? "\n.":".");
				  next }
# Oracle Command
# ~~~~~~~~~~~~~~
# oct: 3, prv: 0, user: 221/MRCHTMH
/^ *oct: .*, prv:/		{ tmp=$2; sub(",", "",tmp);
				  # Only output the parent session's command.
				  if (!oct[sstate, pid]) oct[sstate, pid]=tmp;
				  next }

# Capture Seq
# ~~~~~~~~~~~
# last wait for 'db file sequential read' seq=39279 wait_time=4

/waiting for .*seq=.*wait_time/ { if (seqinfo)
				   seq[sstate, pid] = $(NF-1); 
## v1.0.9 - See if we have the new 8i "blocking sess" token and store this
##          for later use as well.
#
# waiting for 'enqueue' blocking sess=0x800618a4 seq=173 wait_time=0
#             name|mode=54580006, id1=10021, id2=a

                                  if ($0 ~ "blocking sess=")
				   {
				    tmp = $(NF-2);
				    sub("sess=0x", "", tmp);
				    a8iblk[sstate, numpid] = tmp;
				   }
				}

## v1.0.9 - To make use of a8iblk array we need to capture the session state
##          object.

# Capture Session S.O. (for use with 8i)
# ~~~~~~~~~~~~~~~~~~~~
# SO: 800620e4, type: 3, owner: 80053418, flag: INIT/-/-/0x00
# (session) trans: 801382dc, creator: 80053418, flag: (41) USR/- BSY/-/-/-/-/-

/^ *.session. trans/		{ tmp = myso; sub(",", "", tmp);
 			          a8isess[sstate, tmp] = numpid; }

# Wait Event Information
# ~~~~~~~~~~~~~~~~~~~~~~
#  Gather the current wait event information for a simple overview of the
# 'Waiter' information summarised at the end.
#
$0 ~ "last wait for .*'"   ||
$0 ~ "acquiring .*'"	|| 
$0 ~ "waiting for .*'" ||
$0 ~ "holding .*'"       	{ sub("' .*$", "'");  # Just keep event name
				  sub("^ *","");
				  wait_event[sstate, pid] = procevent($0);
			       	  next }

# Spot Dead Processes
# ~~~~~~~~~~~~~~~~~~~
# (process) Oracle pid=6, calls cur/top: 22060e34/22060e34, flag: (3) DEAD
/(process).*flag:.*DEAD/	{ isdead[sstate,pid]=1; }

# RESOURCE: Latch
# ~~~~~~~~~~~~~~~
# Example:
#   waiting for  80108e04 shared pool level=7 state=free
#      wtr=80108e04, next waiter 0
#   holding     80108eec library cache pin level=6 state=busy
#
/waiting for *[a-f0-9]* /	{ waitres[sstate, pid] = "Latch " $3; 	
				  if (verbose && !objname[sstate, "Latch " $3])
				   {
				    tmp = $3;
				    sub("^ *waiting for *[a-f0-9]* ","");
				    sub(" level.*$","");
				    objname[sstate, "Latch " tmp] = $0;
				   }
				  next }
/holding *[a-f0-9]* /		{ tb = blkres[sstate, "Latch " $2];
				  tb = add_resource(tb,pid);
				  blkres[sstate, "Latch " $2] = tb;
				  if (verbose && !objname[sstate, "Latch " $3])
				   {
				    tmp = $3;
				    sub("^ *waiting for *[a-f0-9]* ","");
				    sub(" level.*$","");
				    objname[sstate, "Latch " tmp] = $0;
				   }
				  next }
/acquiring *[a-f0-9]* /		{ tb = blkres[sstate, "Latch " $2];
                                  tb = add_resource(tb,pid);
				  blkres[sstate, "Latch " $2] = tb;
				  if (verbose && !objname[sstate, "Latch " $3])
				   {
				    tmp = $3;
				    sub("^ *waiting for *[a-f0-9]* ","");
				    sub(" level.*$","");
				    objname[sstate, "Latch " tmp] = $0;
				   }
                                  next }

# RESOURCE: Enqueue
# ~~~~~~~~~~~~~~~~~
# Example:
#  (enqueue) TX-00030007-00004170
#  lv: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
#  res:c07c3e90, mode: X, prv: c07c3e98, sess: c1825fc8, proc: c180d338
#
/\(enqueue\) <no resource>/	{ next }   # Skip this

/\(enqueue\)/			{ tmp = $2;
				  getline; getline; sub("","");
## v1.0.9 - Under 8i we now print a space following the "res:" token above
##          which means that we can no longer rely on word position so let's
##          just search for the fact that the line CONTAINS "mode:" or 
##          "req:". 
				  if ($0 ~ "mode:")
				   {
				    tb = blkres[sstate, "Enqueue " tmp];
				    tb = add_resource(tb , pid);
				    blkres[sstate, "Enqueue " tmp] = tb;
				    if (substr(tmp,1,2)=="PS")
				     {
				      tb = pqenq_cnt[sstate, pid]++;
				      tmp1 = tmp;
				      gsub("-0*","-0", tmp1);
				      pqenq[pid, tb] = tmp1;
				     }
				   }

				  if ($0 ~ "req:")
				    waitres[sstate, pid] = "Enqueue " tmp;
                                  sub(", prv.*$", "");
				  mode[sstate, pid, tmp] = $NF; 
				  next }

# RESOURCE: Row Cache Enqueue
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Example:
#  row cache enqueue: count=1 session=c1825fc8 object=c146e960, request=S
#  row cache parent object: address=c146e960 type=9(dc_tables)
#
/row cache enqueue:.*mode/	{ tb = blkres[sstate, "Rcache " $6];
				  tb = add_resource(tb, pid);
				  blkres[sstate, "Rcache " $6] = tb;
				  if (verbose && !objname[sstate, "Rcache " $6])
				   {
				    mode[sstate, pid, $6] = $7;
				    tmp = $6; getline; sub("","");
				    objname[sstate, "Rcache " tmp] = $6;
				    sub(".*type=.", "",
					objname[sstate, "Rcache " tmp]);
				   }
				  next }

/row cache enqueue:/		{ waitres[sstate, pid] = "Rcache " $6;
				  if (verbose && !objname[sstate, "Rcache " $6])
				   {
				    mode[sstate, pid, $6] = $7;
				    tmp = $6;
				    getline; sub("","");
				    objname[sstate, "Rcache " tmp] = $6;
				    sub(".*type=.", "",
					objname[sstate, "Rcache " tmp]);
				   }
				  next }

# RESOURCE: Library Object Pin/Lock
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Example:
#  LIBRARY OBJECT PIN: pin=c0f3aa90 handle=c15bcac0 mode=S lock=c0f3b840
#  LIBRARY OBJECT LOCK: lock=c0f3b840 handle=c15bcac0 mode=N
#
/LIBRARY OBJECT .*mode/		{ tb = blkres[sstate, $3 " " $5];
				  tb = add_resource(tb, pid);
			          blkres[sstate, $3 " " $5] = tb;
				  mode[sstate, pid, $5] = $6; next }

/LIBRARY OBJECT .*request/	{ waitres[sstate, pid] = $3 " " $5;
				  mode[sstate, pid, $5] = $6; next }

# RESOURCE: Cache Buffer
# ~~~~~~~~~~~~~~~~~~~~~~
# Example:
#   (buffer) (CR) PR: 37290 FLG:    0
#   kcbbfbp    : [BH: befd8, LINK: 7836c] (WAITING)
#   BH #1067 (0xbefd8) dba: 5041865 class 1 ba: a03800
#     hash: [7f2d8,b47d0],  lru: [16380,b1b50]
#     use:  [78eb4,78eb4], wait: [79cf4,78664]
#     st: READING, md: EXCL, rsop: 0
#     cr:[[scn: 0.00000000],[xid: 00.00.00],[uba: 00.00.00], sfl: 0]
#     flags: only_sequential_access
#     L:[0.0.0] H:[0.0.0] R:[0.0.0]
#     Using State Objects
#
/^    kcbbfbp/		{ blmode = $7;
			  getline; sub("","");
			  dba = $5; 
			  if ( blmode == "(WAITING)" || blmode == "EXCLUSIVE" )
			    waitres[sstate, pid] = "Buffer " dba;
			  else
			   {
			    tb = blkres[sstate, "Buffer " dba];
			    tb = add_resource(tb, pid);
			    blkres[sstate, "Buffer " dba] = tb;
			   }
			  mode[sstate, pid, dba] = blmode; 
			  next }

# RESOURCE: Lock Element Dump
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Example:
#   LOCK CONTEXT DUMP (address: 0x90ceab20):
#   op: 2 nmd: EXCLUSIVE  dba: 0x5400004f cls: DATA       cvt: 0 cln: 1
#      LOCK ELEMENT DUMP (number: 14048, address: 0x91212498):
#      mod: NULL       rls:0x00 acq:03 inv:0 lch:0x921a366c,0x921a366c
#      lcp: 0x90ceab20 lnk: 0x90ceab30,0x90ceab30

#
# Complete: Always assumes waiting AND just identifies one resource !!
#
/LOCK CONTEXT DUMP/	{ getline; sub("",""); isnull = 0; 
			  if ($4 == "NULL") isnull = 1; 
			  wantmode = $4;
			  getline; sub("","");
			  tmp = "Elem " $5; 
			  if (!isnull)
			    waitres[sstate, pid] = tmp;
			  else
			    blkres[sstate, tmp] = pid;
			  if (!verbose) next;
			  getline; sub("","");
			  mode[sstate, pid, tmp] = $2;
		  	  getline; getline; getline; getline;getline;getline;
			  sub("","");
			  tb = objname[sstate, tmp] " ";
			  tb = tb $2;
			  objname[sstate, tmp] = tb;
			  next }
				  
##
## Verbose Processing
##
verbose != 1		{ next }

# Handle to Object Mapping (Verbose mode)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Example:
#     LIBRARY OBJECT HANDLE: handle=40e25e08
#     name=TEST.CRSMESSAGELOG
#     hash=e2deff52 timestamp=11-22-1995 17:53:55
#     namespace=TABL/PRCD flags=TIM/SML/[02000000]

/LIBRARY OBJECT HANDLE:/	{ # next; # Just skip for now
				  handle=$4; getline; sub("","");
				  if (objname[sstate, handle]) next;
				  # Skip child cursors for now.
				  if ($0 ~ "namespace=") next;
				  sub("^ *name=","");
				  if (!$0) getline; sub("","");
				  txt = $0;
				  while ($0 !~ "namespace") getline; 
				  sub("",""); type=$1;
				  sub("namespace=","",type);
				  objname[sstate, handle] = type ":" txt;
				  next }

# PQO QC <-> QS Code (verbose)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  o A QC can be identified within a systemstate by any of the following
#    methods :
#      - Look for 'flags' being set to ISQC when dumped as part of the Process
#        Queue state object dump (not the Message Buffer state object dump).
#      - Look for PS enqueues being held in EXCLUSIVE mode. 
#        (Null is used for the query slaves).
#        We can then pick up the 'proc:' address of the enqeueue s.o. and link

#      - Check to see whether the Process Queue state object hangs under the
#        Session state object (QC) rather than the process state object (Slave).
#
# Notes:
#  o One QC can have TWO Process Queue state objects with flag ISQC if the QC
#    manipulates two query slave sets (producer/consumer).
#
# Here we maintain the following variables :
#  o qclist  - This is a space delimited list of processes that are recognised
#              as QC's. The queue descriptor is also used to differentiate 
#              seperate slave sets for the same QC pid.
#  
#  o qcid    - The pid of the last QC processed.
#  
#  o qc_cnt  - Count of Opposite Qrefs we have seen for a particular QC. This
#              is indexed by [sstate, qcid]. (This is one HIGHER than the actual
#              count found).
#
#
# TODO: Complete descriptions !!
#

#Queue Reference--kxfpqr: 0x67d4244, ser: 23040, seq: 31066, error: 0
/Queue Reference--kxfpqr/	{ # printf("DBG slave[%d, qref=%s] saved\n",
				  # 	sstate, $3);
				  slave[sstate, $3] = pid; 	
				  qreferr[sstate, $3] = $9; next }

# We need to skip processing if we are dealing with a QC that we have ALREADY
# seen (Eg a QC with 2 slave sets). 
# (We have to check for this in two phases because of Sequent 'feature'
/flags: ISQC/			{ if (sotype ~ "Process Queue")
				   {
				    inpq=1;
				    if (qc_cnt[sstate,  pid]) next;
				    qclist[sstate]=qclist[sstate] " " pid; 
				    qcid = pid; ++qc_cnt[sstate, qcid]; next;
				   } 
				}

#opp qref: 0x67dd950, process: 0x7046ae4, bufs: {0x0, 0x65ff6f8}
# (We have to check for this in two phases because of Sequent 'feature'
/opp qref:.*process:/           { if (inpq==1)
				   {
				    qc[sstate, qcid, qc_cnt[sstate, qcid]++]=$3;
				    next;
				    }
				}

#client 1, detached proc: 0x726899c, QC qref 0x67dd950, flags: -none-
/client.*QC qref 0x0/		{ next; }                       # Skip QC qref's
/client.*QC qref/		{ qref=$8; slave[sstate, $8] = pid; next }
#state: 00000, flags: SMEM OPEN COPE, nulls 0, hint 0x0
/state.*hint/			{ pqostate=$2; next }
#ser: 23040, seq: 1, flags: DIAL CLR, status: FRE, err: 0
/^ *ser:.*seq:.*flags:.*err:/	{ gsub(" ","_");
				  split($0, tmparr, ",");
				  sub("^.*:_", "", tmparr[3]);
				  sub("^.*:_", "", tmparr[4]);
				  sub("^.*:_", "", tmparr[5]);
				  pqomode=tmparr[3]; pqostatus=tmparr[4];
				  pqoerr=tmparr[5];  next }

/Message Buffer--/		{ pqotype = $5; pqobufnum = $7; next }
/to qref.*from qref/		{ tmp=sprintf("%5s %10s %10s %5s %7s %7s %4s",
				  pqostate, $6, $3, pqotype, pqostatus,pqomode,
				  pqoerr);
				  pqdetail[sstate,pid,pqobufnum] = tmp; next}
#       "QC", "Slave", "Msg", "State", "From", "To", "Type", "Status", "Err"); 
				
# END Processing
# ~~~~~~~~~~~~~~
#  Ok - Let's put all the pieces together and you never know.....It just may
# make sense !!
#
END	{ printf("\nAss.Awk Version %s - Processing %s\n", version, FILENAME);
	  for (i=1; i<=sstate; i++)
	   {
	    printf("\nSystem State %d\n~~~~~~~~~~~~~~~~\n", i);
	    blocking = "";
	    blkcnt = 0; objcnt = 0;
	    for (j=1; j<=pidcnt[i]; j++)
	     {
	      pid = pidarray[i,j];
	      tmp = waitres[i, pid];
	      tmp1 = "";
	      if (tmp) tmp1 = "["tmp"]";
	      printf("%-4s%-35s%s%s %s\n", pid, wait_event[i,pid],tmp1,
			isdead[i, pid]?" [DEAD]":"",seq[i, pid]);
	      if (seqinfo && i > 1 && 
		  sameseq(wait_event[i,pid], wait_event[i-1,pid],
			seq[i, pid], seq[i-1, pid]) )
		{
		#printf("DBG: Process %s seq (%s)\n", pid, seq[i, pid]);
		seq_stuck = seq_stuck?min(seq_stuck, j):j;
		}

	      if (oct[i,pid] && oct[i,pid]!=0)
	       {
                if (cmdtab[oct[i,pid]]) printf("     Cmd: %s\n", 
		   cmdtab[oct[i,pid]]);
   		else
		  printf("     Cmd: Unknown(%s)\n", oct[i,pid]);
	       }
#
# Verbose: Need to describe wait_event details as well !!
#

              sub(" ", "_", tmp);
	      if (!index(blocking, tmp) && waitres[i,pid])
	       {
	      	blocking = blocking " " tmp;
		blklist[++blkcnt] = waitres[i,pid];
		if (verbose)
		 {
		  objid[++objcnt] = waitres[i, pid];
		 } # end verbose
	       }
	     } # end j
#
# Summary of the blocking resources
#
	    if (blkcnt)
	     {
	      printf("Blockers\n~~~~~~~~\n\n\t%s\n\t%s\n\t%s\n", tx1, tx2, tx3);
	      printf("\t%s\n\t%s\n\t%s\n\n", tx4, tx5, tx6);
	      printf("%28s %6s %s\n", "Resource", "Holder", "State");
	     }
	    else
	     printf("\nNO BLOCKING PROCESSES FOUND\n");
			
	    for (k=1; k<=blkcnt; k++)
	     {
	      pidlist = blkres[i, blklist[k]];
#	      Someone must be waiting for the resource if we got this far. 
	      if (!pidlist) pidlist = "???"; 
	      numpids = split(pidlist, tpid, " ");
	      for (z=1; z<=numpids; z++)
	       {
	        printf("%28s %6s ", blklist[k], tpid[z]);
	        # -- Handle self deadlocks !!
	        if (waitres[i, tpid[z]])
	         {
# What if blker is multiple blockers ? Need to handle this case as well
# (and tidy code up [use functions?]). Currently just lists it in the following
# format :
#  Enqueue TM-000008EC-00000000              7:   7: is waiting for 7: 13:
#
		  blker = blkres[i, waitres[i, tpid[z]]];
		  # D>on't know holder so let's print the resource
		  if (!sub("^ ", "", blker)) blker = waitres[i, tpid[z]];
		  if (tpid[z] == blker)
		    printf("Self-Deadlock\n");
		  else
	            printf("%s is waiting for %s\n", tpid[z], blker);
	         }
	        else if (wait_event[i, tpid[z]])
		  printf("%s\n", wait_event[i, tpid[z]]); 
		else
	  	  printf("Blocker\n");
	       } # end z
	     } # end k

	    # v1.0.9 - Let's print what the 8i wait info believes are the
	    #          blockers.
	    if (a8ienabled)
             {
	      printf("\nBlockers According to 8i Wait Info:");
	      printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	      for (i8=1; i8<=maxpid; i8++)
               {
	        # If I am now waiting or I am a non-existent pid then skip
		if (a8iblk[i,i8] == "" || a8iblk[i,i8] == "0")
		  continue;

		printf("Process %4d blocked by process %4d\n", i8,
                  a8isess[i, a8iblk[i,i8]]);
			
               } # end i8
             }

            pq_qc2slave(i);
	    if (!verbose || !blkcnt) continue;

	    printf("\nObject Names\n~~~~~~~~~~~~\n");
	    for (y=1; y<=objcnt; y++)
	     {
	      tmp = objid[y];
	      sub("^PIN: ","", tmp); 
	      sub("^LOCK: ","", tmp); 
              #printf("DBG: objname[%d, %s] = '%s'\n", i, tmp, objname[i,tmp]);
	      printf("%12s\t%-30s\n", objid[y], substr(objname[i, tmp],1,50));
	     } # End y
	   # Print out skipped branches
           if (branchlst[sstate])
             printf("\n%s\n%s\n%s\n%s\n%s\n", br1,br2,br3,br4, branchlst[i]);
	   } # end i

	  # Highlight processes that seem to be stuck
	  # Note that we do not care if it is stuck across ALL iterations
	  # of the systemstate dump - just across any TWO adjacent 
	  # systemstates. This is because the user may have dumped the 
	  # systemstate before the problem started, or killed the process.
	  #
	  # TODO: Remember that we may actually have a different OS process
	  #       But unlikely to have the same seq# anyway
	  #       Also, the wait_event string may actually comprise of more
	  #       than just the wait event string itself. In some cases it
	  #       also includes the p1,p2,p3 info as well.
	  if (seq_stuck)
	   {
	    printf("\nList of Processes That May Be Stuck");
	    printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	    for (i=2; i<=sstate; i++)
	     {
	      for (j=seq_stuck; j<=pidcnt[i]; j++)
	       {
		pid = pidarray[i,j];
		#printf("DBG: wait_event[%d,%s] = (%s)\n", i, pid, 
			#wait_event[i,pid]);
		#printf("KDBG: seq[%d, %s] = %s\n", i, pid, seq[i, pid]);
                if (sameseq(wait_event[i,pid], wait_event[i-1,pid],
                         seq[i, pid], seq[i-1, pid]) )
		 {
		  printf("%s %s %s\n", pid, wait_event[i,pid], seq[i,pid]);
		  ## Stop duplicate printouts
		  seq[i,pid] = "";
		 }

               } # end for j
	     } # end for i
	   } # end seq_stuck

	 if (print_pqo) pq_details(rdbms_ver);

	 printf("\n\n%d Lines Processed.\n", NR);

	} # end END

