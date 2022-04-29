Mac/802_11 set bandwidth [lindex $argv 0]
set error_rate [lindex $argv 1]

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

set opt(x)              800                      ;# x coordinate of topology
set opt(y)              800                      ;# y coordinate of topology
set opt(finish)         100                      ;# time to stop simulation

set opt(spacing)        200
# Create the simulator object
set ns [new Simulator]


# Set up tracing
set tracefd  [open "trace.tr" w]
$ns trace-all $tracefd
$ns eventtrace-all

set namtrace [open "trace.nam" w]
$ns namtrace-all-wireless $namtrace $opt(x) $opt(y)


# Define the finish procedure
proc finish {} {
    global ns namtrace tracefd opt
    $ns flush-trace
    exec nam trace.nam &
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
    # $err drop-target [new Agent/Null]
    return $err
}


# proc UniformErr {} {
# 	global error_rate
# 	set error_model [new ErrorModel]
# 	$error_model unit pkt
# 	$error_model set rate_ $error_rate
# 	$error_model ranvar [new RandomVariable/Uniform]
# 	return $error_model
# }



# Create nodes as a node array $node()
for {set i 0} {$i < $opt(nn)} {incr i} {
    set node($i) [$ns node]
    # $node($i) random-motion 0
    $node($i) color black
}

# Set node positions

#A
$node(0) set X_ 200.0
$node(0) set Y_ 400.0
$node(0) set Z_ 0.0

#B
$node(1) set X_ 0.0
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



# setup UDP connection, using CBR traffic
set sink1 [new Agent/Null]
set sink2 [new Agent/Null]
set src1 [new Agent/UDP]
set src2 [new Agent/UDP]

# set null1 [new Agent/Null]
# set null2 [new Agent/Null]

$ns attach-agent $node(7) $sink1
$ns attach-agent $node(8) $sink2
$ns attach-agent $node(0) $src1
$ns attach-agent $node(2) $src2
# $ns attach-agent $node(0) $null1
# $ns attach-agent $node(2) $null2

$ns connect $src1 $sink1
$ns connect $src1 $sink2
$ns connect $src2 $sink1
$ns connect $src2 $sink2

set cbr1 [new Application/Traffic/CBR]
set cbr2 [new Application/Traffic/CBR]

$cbr1 set packetSize_ 100
$cbr1 set interval_ 0.01
$cbr1 set rate_ 100Kb
$cbr1 attach-agent $src1

$ns at 0.1 "$cbr1 start"
$ns at 20.0 "$cbr1 stop"

$cbr2 set packetSize_ 100
$cbr2 set interval_ 0.01
$cbr2 set rate_ 100Kb
$cbr2 attach-agent $src2

$ns at 0.1 "$cbr2 start"
$ns at 20.0 "$cbr2 stop"

for {set i 0} {$i < $opt(nn)} {incr i} {
    $ns initial_node_pos $node($i) 50
    $ns at 20.0 "$node($i) reset";
}

$ns at 20.0 "finish"
$ns at 20.1 "$ns halt"

# puts "Starting simulation...."

$ns run