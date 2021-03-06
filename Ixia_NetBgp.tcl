
# Copyright (c) Ixia technologies 2010-2011, Inc.

# Release Version 1.3
#===============================================================================
# Change made
# Version 1.0 
#       1. Create
# Version 1.1.4.34
#		2. Add Vpn for BGP Vpn
# Version 1.2.4.53
#		3. Add capability in reborn
# Version 1.3.4.54
#		4. Add learned filter in reborn

class BgpSession {
    inherit RouterEmulationObject
       
    constructor { port } {

		set tag "body BgpSession::ctor [info script]"
Deputs "----- TAG: $tag -----"
		set portObj [ GetObject $port ]
		Deputs "portObj: $portObj"
		set handle ""
		# reborn
	}

	method reborn { { ip_version ipv4 } } {
		global errNumber
		
		set tag "body BgpSession::reborn [info script]"
Deputs "----- TAG: $tag -----"

		if { [ catch {
			set hPort   [ $portObj cget -handle ]
		} ] } {
			error "$errNumber(1) Port Object in BgpSession ctor"
		}		
		
		ixNet setA $hPort/protocols/bgp -enabled True
			
		#-- add bgp protocol
		set handle [ ixNet add $hPort/protocols/bgp neighborRange ]
		if { $ip_version == "ipv6" } {
			ixNet setM $handle \
				-dutIpAddress 0:0:0:0:0:0:0:0 \
				-localIpAddress 0:0:0:0:0:0:0:0
		} 
		ixNet commit
		set handle [ ixNet remapIds $handle ]
		ixNet setA $handle \
			-name $this \
			-enabled True
		ixNet commit
		array set routeBlock [ list ]
		
		#-- add interface
		set interface [ ixNet getL $hPort interface ]
		if { [ llength $interface ] == 0 } {
			set interface [ ixNet add $hPort interface ]
			if { $ip_version == "ipv6" } {
			   ixNet add $interface ipv6
		    } else {
			   ixNet add $interface ipv4
			} 
		
			ixNet commit
			set interface [ ixNet remapIds $interface ]
Deputs "interface:$interface"			
			ixNet setM $interface \
				-enabled True
			ixNet commit
		} else {
			set interface [ lindex $interface end ]
		}
		ixNet setA $handle \
			-interfaceType "Protocol Interface" \
			-interfaces [ lindex $interface end ]
		ixNet commit
		
		#-- set capability
		ixNet setM $handle \
			-ipV4Mpls true \
			-ipV4MplsVpn true \
			-ipV4Multicast true \
			-ipV4Unicast true \
			-ipV6Mpls true \
			-ipV6MplsVpn true \
			-ipV6Multicast true \
			-ipV6Unicast true
			
		ixNet setM $handle/learnedFilter/capabilities \
			-ipV4Mpls true \
			-ipV4MplsVpn true \
			-ipV4Multicast true \
			-ipV4MulticastMplsVpn true \
			-ipV4MulticastVpn true \
			-ipV4Unicast true \
			-ipV6Mpls true \
			-ipV6MplsVpn true \
			-ipV6Multicast true \
			-ipV6MulticastMplsVpn true \
			-ipV6MulticastVpn true \
			-ipV6Unicast true \
			-vpls true

		ixNet commit
		
		set protocol bgp
	}
    method config { args } {}
	method enable {} {}
	method disable {} {}
	method get_status {} {}
	method get_stats {} {}
	method set_route { args } {}
	method advertise_route { args } {}
	method withdraw_route { args } {}
	method wait_session_up { args } {}
	
	public variable routeBlock 
    public variable bgpType
}

body BgpSession::config { args } {
    global errorInfo
    global errNumber
    set tag "body BgpSession::config [info script]"
Deputs "----- TAG: $tag -----"
	
	set ip_version ipv4
	set loopback_ipv4_gw 1.1.1.1

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -afi {
            	set afi $value
            }
            -sub_afi {
            	set sub_afi $value
            }
            -as {
            	set as $value
            }
            -dut_ip {
            	set dut_ip $value
            }
            -dut_as {
            	set dut_as $value
            }
            -enable_pack_routes {
            	set enable_pack_routes $value
            }
            -max_routes_per_update {
            	set max_routes_per_update $value
            }
            -enable_refresh_routes {
            	set enable_refresh_routes $value
            }
            -hold_time_interval {
            	set hold_time_interval $value
            }
			-update_Interval {
            	set update_Interval $value
            }
            -ip_version {
            	set ip_version $value
            }
			-ipv4_addr {
				set ipv4_addr $value
			}
			-ipv4_gw {
				set ipv4_gw $value
			}
			-type {
			    if { $value == "IBGP" } {
				    set value "internal"
				}
				if { $value == "EBGP" } {
				    set value "external"
				}
				set type $value
                set bgpType $value
			}
			-bgp_id -
			-router_id {
				set bgp_id $value
			}
			-ipv6_addr {
				set ipv6_addr $value
			}
			-loopback_ipv4_addr {
				set loopback_ipv4_addr $value
			}
			-loopback_ipv4_gw {
				set loopback_ipv4_gw $value
			}
		}
    }
	
	if { $handle == "" } {
		reborn $ip_version
	}
	
	if { [ info exists ipv4_addr ] } {
Deputs "ipv4: [ixNet getL $interface ipv4]"	
Deputs "interface:$interface"
		ixNet setA $interface/ipv4 -ip $ipv4_addr
	}
	if { [ info exists ipv4_gw ] } {
		ixNet setA $interface/ipv4 -gateway $ipv4_gw		
	}
	ixNet commit
	if { [ info exists loopback_ipv4_addr ] } {
		
	}
	if { [ info exists type ] } {
		ixNet setA $handle -type $type
	}
    if { [ info exists afi ] } {
Deputs "not implemented parameter: afi"
    }
    if { [ info exists sub_afi ] } {
Deputs "not implemented parameter: safi"
    }
    if { [ info exists as ] } {
    	ixNet setA $handle -localAsNumber $as
    }
    if { [ info exists dut_ip ] } {
Deputs "dut_ip:$dut_ip"	
    	ixNet setA $handle -dutIpAddress $dut_ip
		ixNet commit
		ixNet setA $interface/ipv4 -gateway $dut_ip
		ixNet commit

    }
    if { [ info exists dut_as ] } {
    }
    if { [ info exists enable_pack_routes ] } {
    }
    if { [ info exists Max_routes_per_update ] } {
    }
    if { [ info exists enable_refresh_routes ] } {
    }
    if { [ info exists hold_time_interval ] } {
	    ixNet setA $handle  -holdTimer $hold_time_interval
    }
	if { [ info exists update_Interval ] } {
	    ixNet setA $handle  -updateInterval $update_Interval
    }
	if { [ info exists bgp_id ] } {
		ixNet setA $handle -bgpId $bgp_id
	}
	if { [ info exists ipv6_addr ] } {
		ixNet setA $handle -localIpAddress $ipv6_addr
	}
	if { [ info exists loopback_ipv4_addr ] } {
		Host $this.loopback $portObj
		$this.loopback config \
			-ipv4_addr $loopback_ipv4_addr \
			-unconnected 1 \
			-ipv4_prefix_len 32 \
			-ipv4_gw $loopback_ipv4_gw
		set loopbackInt [ $this.loopback cget -handle ] 
Deputs "loopback int:$loopbackInt"
		set viaInt [ lindex $interface end ]
Deputs "via interface:$viaInt"
		ixNet setA $loopbackInt/unconnected \
			-connectedVia $viaInt
		ixNet commit
		lappend interface $loopbackInt

		ixNet setA $handle \
			-interfaceType "Protocol Interface" \
			-interfaces [ lindex $interface end ]
		ixNet commit

	}
	
	
	ixNet commit
    return [GetStandardReturnHeader]	
	
}

body BgpSession::set_route { args } {

    global errorInfo
    global errNumber
    set tag "body BgpSession::set_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
	
		foreach rb $route_block {
			set num 		[ $rb cget -num ]
			set step 		[ $rb cget -step ]
			set prefix_len 	[ $rb cget -prefix_len ]
			set start 		[ $rb cget -start ]
			set type 		[ $rb cget -type ] 
            set origin 		[ $rb cget -origin ]
            set nexthop 	[ $rb cget -nexthop ]
            set med 		[ $rb cget -med ]
            set local_pref 	      [ $rb cget -local_pref ]
            set cluster_list      [ $rb cget -cluster_list ]
            set flag_atomic_agg   [ $rb cget -flag_atomic_agg ]
            set agg_as 		      [ $rb cget -agg_as ]
            set agg_ip 		      [ $rb cget -agg_ip ]
            set originator_id 	  [ $rb cget -originator_id ]
            set communities 	  [ $rb cget -communities ]
            set flag_label 		  [ $rb cget -flag_label ]
            set label_mode 		  [ $rb cget -label_mode ]
            set user_label 		  [ $rb cget -user_label ]
			set as_path           [ $rb cget -as_path ]
    
			
			set hRouteBlock [ ixNet add $handle routeRange ]
			ixNet commit
			set hRouteBlock [ ixNet remapIds $hRouteBlock ]
			set routeBlock($rb,handle) $hRouteBlock
			lappend routeBlock(obj) $rb
			
			ixNet setM $hRouteBlock \
				-numRoutes $num \
				-ipType $type \
				-networkAddress $start \
				-fromPrefix $prefix_len \
				-iterationStep $step 
			ixNet commit
            
            if { $origin != "" } {
                ixNet setM $hRouteBlock \
                    -enableOrigin True \
                    -originProtocol $origin
                    
            }
            
            if { $nexthop != "" } {
                ixNet setM $hRouteBlock \
                    -enableNextHop True \
					-nextHopSetMode setManually \
                    -nextHopIpType ipv4 \
                    -nextHopIpAddress $nexthop
                    
            }
            
            if { $med != "" } {
                ixNet setM $hRouteBlock \
                    -enableMed True \
                    -med $med
                    
            }
			
			if { $as_path != "" } {
			   set aspathCmd ""
			    foreach asPathEle $as_path {
				    set astype [lindex $asPathEle 0 ]
					switch $astype {
					    1 { set as_type "asSet"}
						2 { set as_type "asSequence"}
						3 { set as_type "asConfedSequence"}
						4 { set as_type "asConfedSet"}
                    }
					set newEle [lreplace $asPathEle 0 0]
					
					lappend aspathCmd [list true $as_type $newEle]
                    					
				}
				
				
                ixNet setM $hRouteBlock/asSegment \
                    -asSegments $aspathCmd
                    
            }
            
            if { $local_pref != "" } {
                ixNet setM $hRouteBlock \
                    -enableLocalPref True \
                    -localPref $local_pref
                    
            }
            
            if { $cluster_list != "" } {
                ixNet setM $hRouteBlock \
                    -enableCluster True 
                if { [IsIPv4Address $cluster_list] } { 
                    set hexnum [IP2Hex $cluster_list] 	
                    set decnum [Hex2Int $hexnum]					
                ixNet setMultiAttrs $hRouteBlock/cluster \
                    -val $decnum
                }					
            }
            
            if { $flag_atomic_agg != "" } {
                ixNet setM $hRouteBlock \
                    -enableAtomicAttribute True 
                if { $agg_as != "" } {
                    ixNet setM $hRouteBlock \
                        -aggregatorAsNum  $agg_as
                } 
                if { $agg_ip != "" } {
                    ixNet setM $hRouteBlock \
                        -aggregatorIpAddress  $agg_ip
                }                
                    
            }
            
            if { $originator_id != "" } {
                ixNet setM $hRouteBlock \
                    -enableOriginatorId True \
                    -originatorId $originator_id
                    
            }
            
            if { $communities != "" } {
                ixNet setM $hRouteBlock \
                    -enableCommunity True 
                ixNet setMultiAttrs $hRouteBlock/community \
                     -val $communities
                    
            }
            
            if { $bgpType == "internal" } {
               ixNet setM $hRouteBlock \
                  -asPathSetMode noInclude
            }
            
            ixNet commit
			
			$rb configure -handle $hRouteBlock
			$rb configure -portObj $portObj
			$rb configure -hPort $hPort
			$rb configure -protocol "bgp"
			$rb enable
		}
	}
	
    return [GetStandardReturnHeader]
	

}

body BgpSession::advertise_route { args } {
    global errorInfo
    global errNumber
    set tag "body BgpSession::advertise_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
		ixNet setA $routeBlock($route_block,handle) \
			-enabled True
	} else {
		foreach hRouteBlock $routeBlock(obj) {
Deputs "hRouteBlock : $hRouteBlock"		
			ixNet setA $routeBlock($hRouteBlock,handle) -enabled True
		}
	}
	ixNet commit
	return [GetStandardReturnHeader]

}

body BgpSession::withdraw_route { args } {
    global errorInfo
    global errNumber
    set tag "body BgpSession::withdraw_route [info script]"
Deputs "----- TAG: $tag -----"

#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
		ixNet setA $routeBlock($route_block,handle) \
			-enabled False
	} else {
		foreach hRouteBlock $routeBlock(obj) {
			ixNet setA $routeBlock($hRouteBlock,handle) -enabled False
		}
	}
	ixNet commit
	return [GetStandardReturnHeader]

}

body BgpSession::get_stats {} {

    set tag "body BgpSession::get_stats [info script]"
Deputs "----- TAG: $tag -----"


    set root [ixNet getRoot]
	set view {::ixNet::OBJ-/statistics/view:"BGP Aggregated Statistics"}
    # set view  [ ixNet getF $root/statistics view -caption "Port Statistics" ]
Deputs "view:$view"
    set captionList             [ ixNet getA $view/page -columnCaptions ]
Deputs "caption list:$captionList"
	set port_name				[ lsearch -exact $captionList {Stat Name} ]
    set session_conf          [ lsearch -exact $captionList {Sess. Configured} ]
    set session_succ          [ lsearch -exact $captionList {Sess. Up} ]

	
    set ret [ GetStandardReturnHeader ]
	
    set stats [ ixNet getA $view/page -rowValues ]
Deputs "stats:$stats"

    set connectionInfo [ ixNet getA $hPort -connectionInfo ]
Deputs "connectionInfo :$connectionInfo"
    regexp -nocase {chassis=\"([0-9\.]+)\" card=\"([0-9\.]+)\" port=\"([0-9\.]+)\"} $connectionInfo match chassis card port
Deputs "chas:$chassis card:$card port$port"

    foreach row $stats {
        
        eval {set row} $row
Deputs "row:$row"
Deputs "portname:[ lindex $row $port_name ]"
		if { [ string length $card ] == 1 } {
			set card "0$card"
		}
		if { [ string length $port ] == 1 } {
			set port "0$port"
		}
		if { "${chassis}/Card${card}/Port${port}" != [ lindex $row $port_name ] } {
			continue
		}

        set statsItem   "session_conf"
        set statsVal    [ lindex $row $session_conf ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
          
              
        set statsItem   "session_succ"
        set statsVal    [ lindex $row $session_succ ]
Deputs "stats val:$statsVal"
        set ret $ret[ GetStandardReturnBody $statsItem $statsVal ]
			  

Deputs "ret:$ret"

    }
        
    return $ret

	
}

body BgpSession::wait_session_up { args } {
    set tag "body BgpSession::wait_session_up [info script]"
Deputs "----- TAG: $tag -----"

	set timeout 300

    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -timeout {
				set trans [ TimeTrans $value ]
                if { [ string is integer $trans ] } {
                    set timeout $trans
                } else {
                    error "$errNumber(1) key:$key value:$value"
                }
            }

        }
    }
	
	set startClick [ clock seconds ]
	
	while { 1 } {
		set click [ clock seconds ]
		if { [ expr $click - $startClick ] >= $timeout } {
			return [ GetErrorReturnHeader "timeout" ]
		}
		
		set stats [ get_stats ]
		set initStats [ GetStatsFromReturn $stats session_conf ]
		set succStats [ GetStatsFromReturn $stats session_succ ]
		
		if { $succStats == $initStats && $initStats > 0 } {
			break	
		}
		
		after 3000
	}
	
	return [GetStandardReturnHeader]

}

class Vpn {
    inherit RouterEmulationObject
       
	public variable bgpObj
	public variable hBgp
	
    constructor { bgp } {

		set tag "body Vpn::ctor [info script]"
Deputs "----- TAG: $tag -----"

		set bgpObj $bgp
		set hBgp [ $bgp cget -handle ]
		
		set portObj [ $bgp cget -portObj ]
		set hPort	[ $bgp cget -hPort ]
		set handle ""
		reborn
	}

	method reborn {} {
		global errNumber
		
		set tag "body Vpn::reborn [info script]"
Deputs "----- TAG: $tag -----"

		if { [ catch {
			set hBgp   [ $bgpObj cget -handle ]
		} ] } {
			error "$errNumber(1) BGP Object in Vpn ctor"
		}		
		
			
		#-- add l3Site
		set handle [ ixNet add $hBgp l3Site ]
		ixNet commit
		
		set handle [ ixNet remapIds $handle ]
		ixNet setA $handle \
			-name $this \
			-enabled True
		ixNet commit
		array set routeBlock [ list ]
				
		set protocol vpn
	}
    method config { args } {}
	method set_route { args } {}
}

body Vpn::config { args } {
    global errorInfo
    global errNumber
    set tag "body Vpn::config [info script]"
Deputs "----- TAG: $tag -----"

	if { $handle == "" } {
		reborn 
	}
	
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
            -rt {
            	set rt $value
            }
			-rd {
				set rd $value
			}
			-rd_as {
				set rd_as $value
			}
			-rd_ip {
				set rd_ip $value
			}
			-rt_type {
				set rt_type $value
			}
			-rt_ip {
				set rt_ip $value
			}
			-as_path {
				set as_path $value
			}
			-as_path_type {
				set as_path_type $value
			}
			-local_pref {
				set local_pref $value
			}
			-next_hop {
				set next_hop $value
			}
			-route_block {
				set route_block $value
			}
		}
    }

	if { [ info exists rt ] } {
		set rtSplit [ split $rt ":" ]
		set asNumber		[ lindex $rtSplit 0 ]
		set assignedNumber	[ lindex $rtSplit 1 ]
		
		if { [ IsIPv4Address $asNumber ] } {
			set rtList "\{ ip 0 $asNumber $assignedNumber \}"
		} else {
			set rtList "\{ as $asNumber 0.0.0.0 $assignedNumber \}"
		}
Deputs "rtList:$rtList"				

		ixNet setA $handle/target -targetList $rtList 	
		ixNet setA $handle/importTarget -importTargetList $rtList
	}

	
	set_route -route_block $route_block -rd $rd
	
	ixNet commit
    return [GetStandardReturnHeader]	
	
}

body Vpn::set_route { args } {

    global errorInfo
    global errNumber
    set tag "body Vpn::config [info script]"
Deputs "----- TAG: $tag -----"

	set rdType as
	set asNumber 100
	set assignedNumber 1
	set ipNumber 0.0.0.0
	
#param collection
Deputs "Args:$args "
    foreach { key value } $args {
        set key [string tolower $key]
        switch -exact -- $key {
			-rd {
				set rd $value
			}
            -route_block {
            	set route_block $value
            }
        }
    }
	
	if { [ info exists route_block ] } {
	
	
		if { [ info exists rd ] } {
			set rdSplit [ split $rd ":" ]
			set asIpNumber		[ lindex $rdSplit 0 ]
			set assignedNumber	[ lindex $rdSplit 1 ]
			if { [ IsIPv4Address $asIpNumber ] } {
				set rdType ip
				set ipNumber $asIpNumber
			} else {
				set rdType as
				set asNumber $asIpNumber
			}
		}
		
		foreach rb $route_block {
			set num 		[ $rb cget -num ]
			set step 		[ $rb cget -step ]
			set prefix_len 	[ $rb cget -prefix_len ]
			set start 		[ $rb cget -start ]
			set type 		[ $rb cget -type ] 
			
			set hRouteBlock [ ixNet add $handle vpnRouteRange ]
			ixNet commit
			set hRouteBlock [ ixNet remapIds $hRouteBlock ]
			set routeBlock($rb,handle) $hRouteBlock
			lappend routeBlock(obj) $rb
			
			ixNet setM $hRouteBlock \
				-enabled True \
				-numRoutes $num \
				-ipType $type \
				-networkAddress $start \
				-fromPrefix $prefix_len \
				-iterationStep $step \
				-distinguisherType $rdType \
				-distinguisherAsNumber $asNumber \
				-distinguisherAssignedNumber $assignedNumber \
				-distinguisherIpAddress $ipNumber
			ixNet commit
Deputs "rb:$rb"
Deputs "handle:$hRouteBlock"
			$rb configure -handle $hRouteBlock
			$rb configure -portObj $portObj
			$rb configure -hPort $hPort
			$rb configure -protocol "bgp"
			$rb enable
		}
	}
	
    return [GetStandardReturnHeader]
	

}

# =======================
# Neighbor Range
# =======================
# Child Lists:
	# bgp4VpnBgpAdVplsRange (kLegacyUnknown : getList)
	# interfaceLearnedInfo (kLegacyUnknown : getList)
	# l2Site (kLegacyUnknown : getList)
	# l3Site (kLegacyUnknown : getList)
	# learnedFilter (kLegacyUnknown : getList)
	# learnedInformation (kLegacyUnknown : getList)
	# mplsRouteRange (kLegacyUnknown : getList)
	# opaqueRouteRange (kLegacyUnknown : getList)
	# routeImportOptions (kLegacyUnknown : getList)
	# routeRange (kLegacyUnknown : getList)
	# userDefinedAfiSafi (kLegacyUnknown : getList)
# Attributes:
	# -asNumMode (readOnly=False, type=(kEnumValue)=fixed,increment, deprecated)
	# -authentication (readOnly=False, type=(kEnumValue)=md5,null)
	# -bfdModeOfOperation (readOnly=False, type=(kEnumValue)=multiHop,singleHop)
	# -bgpId (readOnly=False, type=(kIP))
	# -dutIpAddress (readOnly=False, type=(kIP))
	# -enable4ByteAsNum (readOnly=False, type=(kBool))
	# -enableActAsRestarted (readOnly=False, type=(kBool))
	# -enableBfdRegistration (readOnly=False, type=(kBool))
	# -enableBgpId (readOnly=False, type=(kBool))
	# -enabled (readOnly=False, type=(kBool))
	# -enableDiscardIxiaGeneratedRoutes (readOnly=False, type=(kBool))
	# -enableGracefulRestart (readOnly=False, type=(kBool))
	# -enableLinkFlap (readOnly=False, type=(kBool))
	# -enableNextHop (readOnly=False, type=(kBool))
	# -enableOptionalParameters (readOnly=False, type=(kBool))
	# -enableSendIxiaSignatureWithRoutes (readOnly=False, type=(kBool))
	# -enableStaggeredStart (readOnly=False, type=(kBool))
	# -holdTimer (readOnly=False, type=(kInteger))
	# -interfaces (readOnly=False, type=(kObjref)=null,/vport/interface,/vport/protocolStack/atm/dhcpEndpoint/range,/vport/protocolStack/atm/ip/l2tpEndpoint/range,/vport/protocolStack/atm/ipEndpoint/range,/vport/protocolStack/atm/pppoxEndpoint/range,/vport/protocolStack/ethernet/dhcpEndpoint/range,/vport/protocolStack/ethernet/ip/l2tpEndpoint/range,/vport/protocolStack/ethernet/ipEndpoint/range,/vport/protocolStack/ethernet/pppoxEndpoint/range,/vport/protocolStack/ethernetEndpoint/range)
	# -interfaceStartIndex (readOnly=False, type=(kInteger))
	# -interfaceType (readOnly=False, type=(kString))
	# -ipV4Mdt (readOnly=False, type=(kBool))
	# -ipV4Mpls (readOnly=False, type=(kBool))
	# -ipV4MplsVpn (readOnly=False, type=(kBool))
	# -ipV4Multicast (readOnly=False, type=(kBool))
	# -ipV4MulticastVpn (readOnly=False, type=(kBool))
	# -ipV4Unicast (readOnly=False, type=(kBool))
	# -ipV6Mpls (readOnly=False, type=(kBool))
	# -ipV6MplsVpn (readOnly=False, type=(kBool))
	# -ipV6Multicast (readOnly=False, type=(kBool))
	# -ipV6MulticastVpn (readOnly=False, type=(kBool))
	# -ipV6Unicast (readOnly=False, type=(kBool))
	# -isAsbr (readOnly=False, type=(kBool))
	# -isInterfaceLearnedInfoAvailable (readOnly=True, type=(kBool))
	# -isLearnedInfoRefreshed (readOnly=True, type=(kBool))
	# -linkFlapDownTime (readOnly=False, type=(kInteger))
	# -linkFlapUpTime (readOnly=False, type=(kInteger))
	# -localAsNumber (readOnly=False, type=(kString))
	# -localIpAddress (readOnly=False, type=(kIP))
	# -md5Key (readOnly=False, type=(kString))
	# -nextHop (readOnly=False, type=(kIPv4))
	# -numUpdatesPerIteration (readOnly=False, type=(kInteger))
	# -rangeCount (readOnly=False, type=(kInteger))
	# -remoteAsNumber (readOnly=False, type=(kInteger64), deprecated)
	# -restartTime (readOnly=False, type=(kInteger))
	# -staggeredStartPeriod (readOnly=False, type=(kInteger))
	# -staleTime (readOnly=False, type=(kInteger))
	# -tcpWindowSize (readOnly=False, type=(kInteger))
	# -trafficGroupId (readOnly=False, type=(kObjref)=null,/traffic/trafficGroup)
	# -ttlValue (readOnly=False, type=(kInteger))
	# -type (readOnly=False, type=(kEnumValue)=external,internal)
	# -updateInterval (readOnly=False, type=(kInteger))
	# -vpls (readOnly=False, type=(kBool))
# Execs:
	# getInterfaceAccessorIfaceList((kObjref)=/vport/protocols/bgp/neighborRange)
	# getInterfaceLearnedInfo((kObjref)=/vport/protocols/bgp/neighborRange)
	# refreshLearnedInfo((kObjref)=/vport/protocols/bgp/neighborRange)

# ====================
# Route Range
# ====================
# Child Lists:
	# asSegment (kLegacyUnknown : getList)
	# cluster (kLegacyUnknown : getList)
	# community (kLegacyUnknown : getList)
	# extendedCommunity (kLegacyUnknown : getList)
	# flapping (kLegacyUnknown : getList)
# Attributes:
	# -aggregatorAsNum (readOnly=False, type=(kInteger64))
	# -aggregatorIpAddress (readOnly=False, type=(kIP))
	# -asPathSetMode (readOnly=False, type=(kEnumValue)=includeAsSeq,includeAsSeqConf,includeAsSet,includeAsSetConf,noInclude,prependAs)
	# -enableAggregator (readOnly=False, type=(kBool))
	# -enableAggregatorIdIncrementMode (readOnly=False, type=(kBool))
	# -enableAsPath (readOnly=False, type=(kBool))
	# -enableAtomicAttribute (readOnly=False, type=(kBool))
	# -enableCluster (readOnly=False, type=(kBool))
	# -enableCommunity (readOnly=False, type=(kBool))
	# -enabled (readOnly=False, type=(kBool))
	# -enableGenerateUniqueRoutes (readOnly=False, type=(kBool))
	# -enableIncludeLoopback (readOnly=False, type=(kBool))
	# -enableIncludeMulticast (readOnly=False, type=(kBool))
	# -enableLocalPref (readOnly=False, type=(kBool))
	# -enableMed (readOnly=False, type=(kBool))
	# -enableNextHop (readOnly=False, type=(kBool))
	# -enableOrigin (readOnly=False, type=(kBool))
	# -enableOriginatorId (readOnly=False, type=(kBool))
	# -enableProperSafi (readOnly=False, type=(kBool))
	# -enableTraditionalNlriUpdate (readOnly=False, type=(kBool))
	# -endOfRib (readOnly=False, type=(kBool))
	# -fromPacking (readOnly=False, type=(kInteger))
	# -fromPrefix (readOnly=False, type=(kInteger))
	# -ipType (readOnly=False, type=(kEnumValue)=ipAny,ipv4,ipv6)
	# -iterationStep (readOnly=False, type=(kInteger))
	# -localPref (readOnly=False, type=(kInteger))
	# -med (readOnly=False, type=(kInteger64))
	# -networkAddress (readOnly=False, type=(kIP))
	# -nextHopIpAddress (readOnly=False, type=(kIP))
	# -nextHopIpType (readOnly=False, type=(kEnumValue)=ipAny,ipv4,ipv6)
	# -nextHopMode (readOnly=False, type=(kEnumValue)=fixed,incrementPerPrefix,nextHopIncrement)
	# -nextHopSetMode (readOnly=False, type=(kEnumValue)=sameAsLocalIp,setManually)
	# -numRoutes (readOnly=False, type=(kInteger))
	# -originatorId (readOnly=False, type=(kIP))
	# -originProtocol (readOnly=False, type=(kEnumValue)=egp,igp,incomplete)
	# -thruPacking (readOnly=False, type=(kInteger))
	# -thruPrefix (readOnly=False, type=(kInteger))
# Execs:
	# reAdvertiseRoutes((kObjref)=/vport/protocols/bgp/neighborRange/routeRange)

# ====================
# L3 VPN
# ====================
# (bin) 12 % ixNet help $port/protocols/bgp/neighborRange/l3Site
# Child Lists:
	# importTarget (kRequired : getList)
	# learnedRoute (kManaged : getList)
	# multicast (kRequired : getList)
	# multicastReceiverSite (kList : add, remove, getList)
	# multicastSenderSite (kList : add, remove, getList)
	# opaqueValueElement (kList : add, remove, getList)
	# target (kRequired : getList)
	# umhImportTarget (kRequired : getList)
	# umhSelectionRouteRange (kList : add, remove, getList)
	# umhTarget (kRequired : getList)
	# vpnRouteRange (kList : add, remove, getList)
# Attributes:
	# -enabled (readOnly=False, type=kBool)
	# -exposeEachVrfAsTrafficEndpoint (readOnly=False, type=kBool)
	# -includePmsiTunnelAttribute (readOnly=False, type=kBool)
	# -isLearnedInfoRefreshed (readOnly=True, type=kBool)
	# -mplsAssignedUpstreamLabel (readOnly=False, type=kInteger)
	# -multicastGroupAddressStep (readOnly=False, type=kIP)
	# -rsvpP2mpId (readOnly=False, type=kIP)
	# -rsvpTunnelId (readOnly=False, type=kInteger)
	# -sameRtAsL3SiteRt (readOnly=False, type=kBool)
	# -sameTargetListAsL3SiteTargetList (readOnly=False, type=kBool)
	# -trafficGroupId (readOnly=False, type=kObjref=null,/traffic/trafficGroup)
	# -tunnelType (readOnly=False, type=kEnumValue=tunnelTypePimGreRosenDraft,tunnelTypeRsvpP2mp,tunnelTypeMldpP2mp)
	# -useUpstreamAssignedLabel (readOnly=False, type=kBool)
	# -vrfCount (readOnly=False, type=kInteger64)
# Execs:
	# refreshLearnedInfo (kObjref=/vport/protocols/bgp/neighborRan
	
	# ixNet help $bgp/learnedFilter/capabilities
# Attributes:
	# -adVpls (readOnly=False, type=kBool)
	# -evpn (readOnly=False, type=kBool)
	# -fetchDetailedIpV4UnicastInfo (readOnly=False, type=kBool)
	# -fetchDetailedIpV6UnicastInfo (readOnly=False, type=kBool)
	# -ipV4Mpls (readOnly=False, type=kBool)
	# -ipV4MplsVpn (readOnly=False, type=kBool)
	# -ipV4Multicast (readOnly=False, type=kBool)
	# -ipV4MulticastMplsVpn (readOnly=False, type=kBool)
	# -ipV4MulticastVpn (readOnly=False, type=kBool)
	# -ipV4Unicast (readOnly=False, type=kBool)
	# -ipV6Mpls (readOnly=False, type=kBool)
	# -ipV6MplsVpn (readOnly=False, type=kBool)
	# -ipV6Multicast (readOnly=False, type=kBool)
	# -ipV6MulticastMplsVpn (readOnly=False, type=kBool)
	# -ipV6MulticastVpn (readOnly=False, type=kBool)
	# -ipV6Unicast (readOnly=False, type=kBool)
	# -vpls (readOnly=False, type=kBool)

