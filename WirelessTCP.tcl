Mac/802_11 set bandwidth [lindex $argv 0]
set error_rate [lindex $argv 1]
set packet_size [lindex $argv 2]

# Define options
set opt(chan)           Channel/WirelessChannel  ;# channel type
set opt(prop)           Propagation/TwoRayGround ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy          ;# network interface type
set opt(mac)            Mac/802_11               ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue  ;# interface queue type
set opt(ll)             LL                       ;# link layer type
set opt(ant)            Antenna/OmniAntenna      ;# antenna model
set opt(ifqlen)         50                       ;# max packet in ifq
set opt(nn)             9                        ;# number of mobilenodes
set opt(rp)             AODV                     ;# routig protocol(Ad hoc On-Demand Distance Vector Routing)
set opt(x)              700                      ;# x coordinate of topology
set opt(y)              200                      ;# y coordinate of topology
set opt(finish)         100                      ;# time to stop simulation


# Create the simulator object
set ns [new Simulator]


# Set up tracing
set tracefd  [open "out_trace.tr" w]
$ns trace-all $tracefd
$ns eventtrace-all

set namtrace [open "trace.nam" w]
$ns namtrace-all-wireless $namtrace $opt(x) $opt(y)


# Define the finish procedure
proc finish {} {
    global ns namtrace tracefd opt
    $ns flush-trace
    # exec nam trace.nam &
    close $namtrace
    close $tracefd
    exit 0
}


# Create  and define the topography object and layout
set topo [new Topography]
$topo load_flatgrid $opt(x) $opt(y)


# Create an instance of General Operations Director, which keeps track of nodes and 
# node-to-node reachability. The parameter is the total number of nodes in the simulation.
create-god $opt(nn)


# General node configuration
set chan1 [new $opt(chan)]

$ns node-config -adhocRouting $opt(rp) \
                -llType $opt(ll) \
                -macType $opt(mac) \
                -ifqType $opt(ifq) \
                -ifqLen $opt(ifqlen) \
                -antType $opt(ant) \
                -propType $opt(prop) \
                -phyType $opt(netif) \
                -IncomingErrProc UniformErr \
                -OutgoingErrProc UniformErr \
		        -channelType Channel/WirelessChannel \
                -topoInstance $topo \
                -agentTrace ON \
                -routerTrace OFF \
                -macTrace ON \
                -movementTrace OFF 


proc UniformErr {} {
    global error_rate
    set err [new ErrorModel]
    $err unit packet
    $err set rate_ $error_rate
    $err ranvar [new RandomVariable/Uniform]
    return $err
}


# Create nodes as a node array $node()
for {set i 0} {$i < $opt(nn)} {incr i} {
    set node($i) [$ns node]
}

# Set node positions

#A
$node(0) set X_ 200.0
$node(0) set Y_ 400.0
$node(0) set Z_ 0.0

#B
$node(1) set X_ 100.0
$node(1) set Y_ 200.0
$node(1) set Z_ 0.0

#D
$node(2) set X_ 200.0
$node(2) set Y_ 0.0
$node(2) set Z_ 0.0

#C
$node(3) set X_ 400.0
$node(3) set Y_ 300.0
$node(3) set Z_ 0.0

#E
$node(4) set X_ 400.0
$node(4) set Y_ 100.0
$node(4) set Z_ 0.0

#G
$node(5) set X_ 600.0
$node(5) set Y_ 300.0
$node(5) set Z_ 0.0

#F
$node(6) set X_ 600.0
$node(6) set Y_ 100.0
$node(6) set Z_ 0.0

#H
$node(7) set X_ 800.0
$node(7) set Y_ 300.0
$node(7) set Z_ 0.0

#L
$node(8) set X_ 800.0
$node(8) set Y_ 100.0
$node(8) set Z_ 0.0



# setup TCP connection, using FTP traffic
set sink1 [new Agent/TCPSink]
set sink2 [new Agent/TCPSink]
set src1 [new Agent/TCP]
set src2 [new Agent/TCP]

$ns attach-agent $node(7) $sink1
$ns attach-agent $node(8) $sink2
$ns attach-agent $node(0) $src1
$ns attach-agent $node(2) $src2

$ns connect $src1 $sink1
# $ns connect $src1 $sink2 //for 4 connections
# $ns connect $src2 $sink1
$ns connect $src2 $sink2

set ftp1 [new Application/FTP]
set ftp2 [new Application/FTP]


$ftp1 attach-agent $src1
$sink1 set packetSize_ $packet_size
$ftp1 set rate_ 200kb
$ftp1 set interval_ 0.01

$ftp2 attach-agent $src2
$sink2 set packetSize_ $packet_size
$ftp2 set rate_ 200kb
$ftp2 set interval_ 0.01


$ns at 0 "$ftp1 start"
$ns at 0 "$ftp2 start"
$ns at $opt(finish) "$ftp1 stop"
$ns at $opt(finish) "$ftp2 stop"

for {set i 0} {$i < $opt(nn)} {incr i} {
    $ns initial_node_pos $node($i) 50
    $ns at 100.0 "$node($i) reset";
}

$ns at $opt(finish) "finish"
$ns run