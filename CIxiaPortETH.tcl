##############################################################
# Script Name	 :   CIxiaNetPortETH.tcl
# Class Name	 :   CIxiaNetPortETH
# Description    :   Port Class, support port traffic operations.
# Related Script :   
# Created By     :   Judo Xu 
#############################################################

#############################################################
# Modify History:
#############################################################
# 1.Create	2016.09.28    	jxu@ixiacom.com
#
#############################################################

package require Itcl
package require cmdline

#引入基类
#package require TestInstrument 1.0

package provide IxiaPort 1.0

::itcl::class CTestInstrumentPort {
	constructor { obj port portObj } {
	}
}

set ::CIxiaNet::gIxia_OK true
set ::CIxiaNet::gIxia_ERR false

#@@All Proc
#Ret: ::CIxiaNet::gIxia_OK - if no error(s)
#     ferr - if error(s) occured
#Usage: CRouteTesterPort port1 {1 2 1}
::itcl::class CIxiaNetPortETH {
    public variable _chassis ""
    public variable _card ""
    public variable _port ""
    public variable _media ""
    public variable _streamid ""
    public variable _uti ""
    public variable _mode ""
    public variable _portObj ""
    public variable _handle ""
    public variable portList ""
    public variable _capture ""

    #继承父类 
    inherit CTestInstrumentPort
    
    #构造函数
    constructor { obj port portObj } { CTestInstrumentPort::constructor $obj $port $portObj } {
        Log "Constructor port $port, object name: $portObj..."
        set port [lindex $port 0]
        set _chassis [lindex $port 0]
        set _card [lindex $port 1]
        set _port [lindex $port 2]
        set portList [ list [ list $_chassis $_card $_port ] ]
        
        set _media [lindex $port 3]
        if { [ string tolower $_media ] == "c" } {
            set _media copper
        } elseif { [ string tolower $_media ] == "f" } {
            set _media fiber
        }
        
        Port $portObj $_chassis/$_card/$_port $_media
		set _portObj [ GetObject $portObj ]
        set _handle [ $_portObj cget -handle ]
        
        Capture ${_portObj}_capture $_portObj
        set _capture [ GetObject ${_portObj}_capture ]
        
        Reset
    }
    
    #析构函数
    destructor {}
    
    #Traffic APIs
    public method Reset { args }
    public method Run { args }
    public method Stop { args }
    public method SetTrig {args }
    public method SetPortSpeedDuplex { args }
    public method SetTxSpeed { args }
    public method SetTxMode { args }
    public method SetCustomPkt { args }
    public method SetVFD1 { args }
    public method SetVFD2 { args }
    public method SetEthIIPkt { args }
    public method SetArpPkt { args }
    public method CreateCustomStream { args }
    public method CreateIPStream { args }
    public method CreateTCPStream { args }
    public method CreateUDPStream { args }
    public method SetCustomVFD { args }
    public method CaptureClear { args }
    public method StartCapture { args }
    public method StopCapture { args }
    public method ReturnCaptureCount { args }
    public method ReturnCapturePkt { args }
    public method GetPortInfo { args }
	public method GetPortStatus {}
    public method GetTypeName {}
    public method GetPortCableType {}
    public method GetPortStreams {} {}
    public method Clear { args }
	public method CreateIPv6Stream { args }
	public method CreateIPv6TCPStream { args }
	public method CreateIPv6UDPStream { args }
	public method DeleteAllStream {}
	public method DeleteStream { args } 
	public method SetErrorPacket { args }
	public method SetFlowCtrlMode { args }
	public method SetMultiModifier { args }
	public method SetPortAddress { args } 
	public method SetPortIPv6Address { args }
	public method SetTxPacketSize { args }
    
    #处理并记录error错误
    method error {Str} {
        puts "Log: $Str"
    	#CTestException::Error $Str -origin Ixia
    } 
    
    #输出调试信息
    method Log {Str { Level info } }  {
        puts "Log: $Level --- $Str"
    	#CTestLog::Log $Level $Str origin Ixia
    }
} ;# End of Class

###########################################################################################
#@@Proc
#Name: Reset
#Desc: Reset current Port
#Args: args
#Usage: port1 Reset
###########################################################################################
::itcl::body CIxiaNetPortETH::Reset { args } {
	Log "Reset port $_chassis $_card $_port..."
    set retVal $::CIxiaNet::gIxia_OK
  
    if { ![ GetValueFromReturn [ $_portObj reset ] Status ] } {
        Log "Failed to reset port: $_chassis/$_card/$_port"
        set retVal $::CIxiaNet::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: Run
#Desc: Begin to send packects/stream
#Args: args
#Usage: port1 Run
###########################################################################################
::itcl::body CIxiaNetPortETH::Run { args } {
	Log "Start transmit at $_chassis $_card $_port..."
    set retVal $::CIxiaNet::gIxia_OK
  
    if { ![ GetValueFromReturn [ $_portObj start_traffic ]  Status ] } {
        Log "Failed to start traffic on port: $_chassis/$_card/$_port"
        set retVal $::CIxiaNet::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: Stop
#Desc: Stop to send packects/stream
#Args: args
#Usage: port1 Stop
###########################################################################################
::itcl::body CIxiaNetPortETH::Stop { args } {
	Log "Stop transmit at $_chassis $_card $_port..."
    set retVal $::CIxiaNet::gIxia_OK
    if { ![ GetValueFromReturn [ $_portObj stop_traffic ]  Status ] } {
        Log "Failed to stop traffic on port: $_chassis/$_card/$_port"
        set retVal $::CIxiaNet::gIxia_ERR 
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTrig
#Desc: Set filter conditions
#Args:  
#	offset1:       offset of packect
#   pattern1:       trigger pattern
#	trigMode:      support && and ||
#   offset2:       offset of packet
#   pattern2:       trigger pattern
#Usage: port1 SetTrig 12 {00 10}
###########################################################################################
::itcl::body CIxiaNetPortETH::SetTrig {offset1 pattern1 {TrigMode ""} {offset2 ""} {pattern2 ""}} {
    set trigmode $TrigMode
    Log "Set trigger ($offset1 $pattern1 $trigmode $offset2 $pattern2) at $_chassis $_card $_port..."
    set retVal $::CIxiaNet::gIxia_OK

    #将十进制数转换为十六进制数
    if {[regsub -nocase -all {0x} $pattern1 "" pattern1] == 0} {
        set m_pattern1 ""
        foreach ele $pattern1 {
            lappend m_pattern1 [format %02x $ele]
        }
        set pattern1 $m_pattern1
    }

    if {[regsub -nocase -all {0x} $pattern2 "" pattern2] == 0 && [string length $pattern2] > 0} {
        set m_pattern2 ""
        foreach ele $pattern2 {
            lappend m_pattern2 [format %02x $ele]
        }
        set pattern2 $m_pattern2
    }
    #end
    
    switch -- $trigmode {
        ""      {
                set TriggerMode pattern1
                }
        "||"    {
                set TriggerMode pattern1OrPattern2
                }
        "&&"    {
                set TriggerMode pattern1AndPattern2
                }
        default {
                error "Invaild trigmode: $trigmode"
                }
    }

    if { [catch {
        ixNet setM $_handle/capture -hardwareEnabled true -captureMode captureTriggerMode
        ixNet commit
        if { $TriggerMode == "pattern1" } {
            ixNet setM $_handle/capture/trigger \
                -captureTriggerPattern pattern1 \
                -captureTriggerEnable true \
                -captureTriggerExpressionString P1
				
				ixNet commit
		} else {
            if { $pattern1 != "" } {
                ixNet setM $_handle/capture/filterPallette \
                    -patternOffset1 $offset1 \
                    -patternMask1 $pattern1
            }
            if { $pattern2 != "" } {
                ixNet setM $_handle/capture/filterPallette \
                    -patternOffset2 $offset2 \
                    -patternMask2 $pattern2
                
                if { $TriggerMode == "pattern1OrPattern2" } {
                    ixNet setM $_handle/capture/trigger \
                        -captureTriggerPattern pattern1AndPattern2 \
                        -captureTriggerEnable true \
                        -captureTriggerExpressionString "P1\ or\ P2"
                    
                } elseif { $TriggerMode == "pattern1AndPattern2" } {
                    ixNet setM $_handle/capture/trigger \
                        -captureTriggerPattern pattern1AndPattern2 \
                        -captureTriggerEnable true \
                        -captureTriggerExpressionString "P1\ and\ P2"
                }
            }
        }
        ixNet commit
    } err] } {
        Log "Set trigger failed: $err"
        set retVal $::CIxiaNet::gIxia_ERR 
    }
   	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetPortSpeedDuplex
#Desc: set port speed and duplex 
#Args: 
#	autoneg: 0 - disable autoneg 
#			 1 - enable autoneg
#   speed  : speed - 0x0002(10M),0x0008(100M) 0x0040(1G)or all
#   duplex : duplex - FULL(0) or HALF(1) or ALL
#Usage: port1 SetPortSpeedDuplex 1 10 full
###########################################################################################
::itcl::body CIxiaNetPortETH::SetPortSpeedDuplex {AutoNeg {Speed -1} {Duplex -1}} {
	Log "Set port speed duplex at $_chassis $_card $_port..."
   	set retVal $::CIxiaNet::gIxia_OK
    
    set autoneg $AutoNeg
    set duplex [string tolower $Duplex]
    switch $duplex {
        full {set duplex full}
        half {set duplex half}
        1    {set duplex full}
        0    {set duplex half}
		all -
        -1   {
                set autoneg 1
                unset duplex
             }
        default { error "illegal duplex defined ($duplex)" }
    }
   	set speed [string toupper $Speed]
    switch $speed {
        0X0002 {set speed 10M}
        0X0008 {set speed 100M}
        0X0040 {set speed 1G}
        100M   {set speed 100M}
        10M    {set speed 10M}
        1000M  {set speed 1G}
        100    {set speed 100M}
        10     {set speed 10M}
        1000   {set speed 1G}
		all -
        -1     {
                unset speed
                set autoneg 1
               }
        default { error "illegal speed defined ($speed)" }
    }
   	
    if { [ info exists duplex ] } {
		if { [ info exists speed ] } {
			if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg -duplex $duplex -speed $speed ]  Status ] } {
				set retVal $::CIxiaNet::gIxia_ERR 
			}
		} else {
			if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg -duplex $duplex ]  Status ] } {
				set retVal $::CIxiaNet::gIxia_ERR 
			}
		}
    } else {		
		if { [ info exists speed ] } {
			if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg -speed $speed ]  Status ] } {
				set retVal $::CIxiaNet::gIxia_ERR 
			}
		} else {
			if { ![ GetValueFromReturn [ $_portObj config -auto_neg $autoneg ]  Status ] } {
				set retVal $::CIxiaNet::gIxia_ERR 
			}
		}
    }

   	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTxSpeed
#Desc: Set traffic mode and load
#Args:
#   Utilization : port utilization
#   Mode: traffic mode
#Usage: port1 SetTxSpeed
###########################################################################################
::itcl::body CIxiaNetPortETH::SetTxSpeed {Utilization {Mode "Uti"}} {

    set utilization $Utilization
    set _uti $Utilization
    set _mode $Mode

    Log "Set tx speed of {$_chassis $_card $_port}..."
    set retVal $::CIxiaNet::gIxia_OK
    regsub {[%]} $utilization {} utilization

    foreach streamObj [ GetPortStreams ] {
        if { $Mode == "Uti" } {
            $streamObj config -load_unit PERCENT -stream_load $utilization 
        } else {
            $streamObj config -load_unit FPS -stream_load $utilization 
        }
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: GetPortStreams
#Desc: Get all streams under current port
#Args: 
#Usage: port1 GetPortStreams
###########################################################################################
::itcl::body CIxiaNetPortETH::GetPortStreams {} {
    Log "Get all streams under current port"

	set streamObj [list]
	set objList [ find objects ]
	foreach obj $objList {
		if { [ $obj isa Traffic ] } {
			lappend streamObj [ GetObject $obj ]
		}
	}

    set txList [list ]
    foreach obj $streamObj {
        set traffic [ $obj cget -highLevelStream ]
        set txPort [ ixNet getA $traffic -txPortId ]
        if { $txPort == $_handle } {
            lappend txList $obj
        }
    }

    return $txList
}

###########################################################################################
#@@Proc
#Name: SetTxMode
#Desc: set port send mode
#Args: 
#	txmode: send mode
#		0 - CONTINUOUS_PACKET_MODE              
#		1 - SINGLE_BURST_MODE  attach 1 params: BurstCount
#		2 - MULTI_BURST_MODE   attach 4 params: BurstCount InterBurstGap InterBurstGapScale MultiburstCount
#		3 - CONTINUOUS_BURST_MODE   attach 3 params: BurstCount InterBurstGap InterBurstGapScale
#	BurstCount:  ever burst package count
#	MultiburstCount:    multiburst count
#	InterBurstGap:      interval of every 2 bursts
#	InterBurstGapScale: interval unit
#		0 - NanoSeconds            
#		1 - MICRO_SCALE   
#		2 - MILLI_SCALE   
#		3 - Seconds
#Usage: port1 SetTxMode 0
###########################################################################################
::itcl::body CIxiaNetPortETH::SetTxMode {TxMode {BurstCount 0} {InterBurstGap 0} {InterBurstGapScale 0} {MultiBurstCount 0}} {
    Log "Set tx mode on {$_chassis $_card $_port}..."
    set retVal $::CIxiaNet::gIxia_OK
    
    set txmode [ string tolower $TxMode ]
    switch $txmode {
        0 {set txmode continuous}
        1 {set txmode burst}
        2 {set txmode iteration}
        3 {set txmode custom}
        default { error "illegal txmode defined ($txmode)" }
    }
    set burstcount $BurstCount
    set interburstgap $InterBurstGap
    set interburstgapscale [ string tolower $InterBurstGapScale ]
    set multiburstcount $MultiBurstCount

    switch $interburstgapscale {
        0 {set interburstgapscale nanoseconds}
        1 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 ]
          }
        2 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 ]
          }
        3 {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 * 1000 ]
          }
        nanoseconds {set interburstgapscale nanoseconds}
        micro_scale {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 ]
          }
        milli_scale {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 ]
          }
        seconds {
            set interburstgapscale nanoseconds
            set interburstgap [ expr $interburstgap * 1000 * 1000 * 1000 ]
          }
        default { error "illegal interburstgap defined ($interburstgap)" }
    }
    
    foreach streamObj [ GetPortStreams ] {
        if { [catch {
            if { $txmode == "continuous" } {
                $streamObj config -tx_mode continuous
            } elseif { $txmode == "burst" } {
                $streamObj config -tx_mode burst -tx_num $burstcount 
            } elseif { $txmode == "iteration" } {
                $streamObj config -tx_mode iteration -tx_num $burstcount -iteration_count $multiburstcount -enable_burst_gap true -burst_gap $interburstgap -burst_gap_units $interburstgapscale
            } elseif { $txmode == "custom" } {
                $streamObj config -tx_mode custom -burst_packet_count $burstcount -enable_burst_gap true -burst_gap $interburstgap -burst_gap_units $interburstgapscale
            } } err]} {
            Log "Failed to set tx mode of {$_chassis $_card $_port}..."
            set retVal $::CIxiaNet::gIxia_ERR
        }
    }
   
    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetCustomPkt
#Desc: set packet value
#Args: 
#	myValue eg:ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00
#     	pkt_len default -1
#Usage: port1 SetCustomPkt {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
###########################################################################################
::itcl::body CIxiaNetPortETH::SetCustomPkt {{myValue 0} {pkt_len -1}} {
    Log "Set custom packet of {$_chassis $_card $_port}..."
    set retVal $::CIxiaNet::gIxia_OK
    Log "SetCustomPkt: $myValue $pkt_len"
    
    set Srcip "0.0.0.0"
    set Dstip "0.0.0.0"
    set Srcmac 0000-0000-0000
	set DstMac 0000-0000-0000
    set frameSizeType fixed
    
    set streamIndex [llength [GetPortStreams]]
    set trafficName $_portObj.traffic$streamIndex
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    set payload $myValue
    set myvalue $myValue
    
    if {[llength $pkt_len] == 1} {
        if [string match $pkt_len "-1"] {
            set pkt_len [llength $myvalue]
        }
        
        if { $pkt_len < 60 } {
            set pkt_len 60
        }
        
        set frameSize [expr $pkt_len + 4]
        set frameSizeType fixed
    } else {
        set frameSizeMIN [lindex $pkt_len 0]
        set frameSizeMAX [lindex $pkt_len 1]
        set frameSizeType random
    }
    
    if { $pkt_len > [llength $myvalue] } {
        set patch_value [string repeat "00 " [expr $pkt_len - [llength $myvalue]]]
        set myvalue [concat $myvalue $patch_value]
        Log "Payload value: $myvalue"
    }
    
    if { [llength $myvalue] >= 12} {
        set DstMac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
        set Srcmac "[lindex $myvalue 6][lindex $myvalue 7]-[lindex $myvalue 8][lindex $myvalue 9]-[lindex $myvalue 10][lindex $myvalue 11]"
    } elseif { [llength $myvalue] > 6 } { 
        set Dstmac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
    } else {
        set Srcmac "[lindex $myvalue 0][lindex $myvalue 1]-[lindex $myvalue 2][lindex $myvalue 3]-[lindex $myvalue 4][lindex $myvalue 5]"
    }
	set srcmac [HexToMac $Srcmac]
    set desmac [HexToMac $DstMac]
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x[lindex $myvalue 12][lindex $myvalue 13] -type_mod "fixed"
	
    if { [llength $myvalue] >= 12 } {
        if { [lindex $myvalue 12] == "81" && [lindex $myvalue 13] == "00"} {
			etherHdr config -type 0x8100 -type_mod "fixed"
			
            set vlanOpts  0x[lindex $myvalue 14][lindex $myvalue 15]
            set vlanID                 [expr $vlanOpts & 0x0FFF]
            # 3 bits Priority
            set userPriority           [expr [expr $vlanOpts >> 13] & 0x0007]
            set cfi                    [expr [expr $vlanOpts >> 12] & 0x0001]
            set payload [lrange $myvalue 18 end]
            
            SingleVlanHdr vlanHdr
            vlanHdr config \
                -id $vlanID \
                -pri $userPriority \
                -cfi $cfi 
				
		    set payload [lrange $myvalue 18 end]
            if { [lindex $myvalue 16] == "08" } {
                set Srcip "[lindex $myvalue 30].[lindex $myvalue 31].[lindex $myvalue 32].[lindex $myvalue 33]"                   
            }
        } else {
            set payload [lrange $myvalue 14 end]
            if { [lindex $myvalue 12] == "08" && [lindex $myvalue 13] == "00"} {
				etherHdr config -type 0x0800 -type_mod "fixed"
                set Srcip "[lindex $myvalue 26].[lindex $myvalue 27].[lindex $myvalue 28].[lindex $myvalue 29]"                   
            }
        }
    }
    
    if { $frameSizeType == "fixed" } {
        if { [info exists vlanHdr] } {
            $trafficName config -pdu "etherHdr vlanHdr" -frame_len_type $frameSizeType -frame_len $frameSize -payload $payload
        } else {
            $trafficName config -pdu "etherHdr" -frame_len_type $frameSizeType -frame_len $frameSize -payload $payload
        }
    } else {
        if { [info exists vlanHdr] } {
            $trafficName config -pdu "etherHdr vlanHdr" -frame_len_type $frameSizeType -min_frame_len $frameSizeMIN -max_frame_len $frameSizeMAX -payload $payload
        } else {
            $trafficName config -pdu "etherHdr" -frame_len_type $frameSizeType -min_frame_len $frameSizeMIN -max_frame_len $frameSizeMAX -payload $payload
        }
    }
    
	catch { ::itcl::delete object vlanHdr }
	catch { ::itcl::delete object etherHdr }
    # Added table interafce to enable arp response
    if { $Srcip != "0.0.0.0" && $Srcip != "00.00.00.00" } {
        SetPortAddress -macaddress $Srcmac -ipaddress $Srcip -netmask "255.255.255.0" -replyallarp 1
    }

    return $retVal
}

###########################################################################################
#@@Proc
#Name: SetEthIIPkt
#Desc: set packet value
#Args:
#   -PacketLen
#   -SrcMac
#   -DesMac
#   -DesIP
#   -SrcIP
#   -Tos
#   -TTL
#   -EncapType
#   -VlanID
#   -Priority
#   -Data
#   -Protocol
#     	
#Usage: port1 SetEthIIPkt -PacketLen 1000 -DesMac 7425-8a48-de05 -SrcMac 0000-0001-0001 -DesIP 2.2.2.2 -SrcIP 105.83.157.2
###########################################################################################
::itcl::body CIxiaNetPortETH::SetEthIIPkt { args } {
    set PacketLen 60
    set SrcMac "0.0.0.1"
    set DesMac "ffff.ffff.ffff"
    set DesIP "1.1.1.2"
    set SrcIP "1.1.1.1"
    set TTL 64
    set Tos 0
    set EncapType EET_II
    set VlanID 0
    set Priority 0
    set Data ""
    set Protocol 1

    set argList {PacketLen.arg SrcMac.arg DesMac.arg DesIP.arg SrcIP.arg Tos.arg TTL.arg \
                 EncapType.arg VlanID.arg Priority.arg Data.arg Protocol.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "SetEthIIPkt has illegal parameter! $val"
        return $::CIxiaNet::gIxia_ERR
    }

    # 参数检查
    set Match [MacValid $DesMac]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> DesMac is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    set Match [MacValid $SrcMac]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> SrcMac is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    set Match [IpValid $DesIP]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> DesIP is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    set Match [IpValid $SrcIP]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> SrcIP is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }

    if {$VlanID==0 && $Priority!=0} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> a vlan id is prefered if the priority is used"
        return $::CIxiaNet::gIxia_ERR    
    }
    
    set EncapList {EET_II EET_802_2 EET_802_3 EET_SNAP}
    if {[lsearch $EncapList $EncapType] == -1} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> Invalid encapsulation type is prefered! $EncapType" warning
        return $::CIxiaNet::gIxia_ERR
    }
    
    if {$PacketLen < 0} {
        Log "CIxiaNetPortETH::SetEthIIPkt >>> Invalid packet length is prefered! $PacketLen" warning
        return $::CIxiaNet::gIxia_ERR
    }
    
    switch $EncapType {
           EET_II {
           	set min_pktLen 34
           	set frame_name eth_frame_hdr
           	}
           EET_802_3 {
           	set min_pktLen 34
           	set frame_name 802.3_frame_hdr
           	}
           EET_802_2 {
           	set min_pktLen 37
           	set frame_name 802.2_frame_hdr
           	}
           EET_SNAP {
           	set min_pktLen 42
           	set frame_name snap_frame_hdr
           	}
    }
    
    set vlan_tag_hdr ""
    if {$VlanID!=0} {
        set min_pktLen [expr $min_pktLen + 4]
        set PacketLen [expr $PacketLen + 4]
        
        set vlan_tag_hdr [::packet::conpkt vlan_tag -pri $Priority -tag $VlanID]
    }
    set Data [regsub -all "0x" $Data ""]
    set ipv4_packet [::packet::conpkt ipv4_header -srcip $SrcIP -desip $DesIP -ttl $TTL -tos $Tos -pro $Protocol -data $Data]
    set eth_packet [::packet::conpkt $frame_name -deth $DesMac -seth $SrcMac -vlantag $vlan_tag_hdr -data $ipv4_packet]
    
    Log "Set packet of {$_chassis $_card $_port}:\n\t$eth_packet"
    
    if {[llength $eth_packet] > $PacketLen} {
        $this SetCustomPkt $eth_packet -1
    } else {
        $this SetCustomPkt $eth_packet $PacketLen
    }
    
    return $::CIxiaNet::gIxia_OK
}

::itcl::body CIxiaNetPortETH::SetArpPkt { args } {
    set PacketLen 60
    set ArpType 1
    set DesMac 0
    set SrcMac 0
    set ArpDesIP "0.0.0.0"
    set ArpSrcIP "0.0.0.0"
    set ArpSrcMac 0
    set ArpDesMac 0
    set EncapType EET_II
    set VlanID 0
    set Priority 0

    set argList {PacketLen.arg ArpType.arg DesMac.arg SrcMac.arg ArpDesMac.arg ArpSrcMac.arg ArpDesIP.arg ArpSrcIP.arg \
                 EncapType.arg VlanID.arg Priority.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "SetIPXPacket has illegal parameter! $val"
        return $::CIxiaNet::gIxia_ERR
    }
    
    # 如果不指定ArpSrcMac或者取0,则取ArpSrcMac等于SrcMac,如果两者只指定一个就同取一个值。如果两者都为0即都没有指定，
    #则取默认值0.0.1
    if {$ArpSrcMac == 0 && $SrcMac == 0} {  
        set ArpSrcMac 0.0.1 
        set SrcMac 0.0.1 
    } else {
        if {$ArpSrcMac == 0} {set ArpSrcMac $SrcMac }
        if {$SrcMac == 0} {set SrcMac $ArpSrcMac }
    }    
    
    # 如果不指定ArpDesMac或者取0,则取ArpDesMac等于DesMac,如果两者只指定一个就同取一个值。如果两者都为0即都没有指定，
    #则取默认值ffff.ffff.ffff
    if {$ArpDesMac == 0 && $DesMac == 0} {  
        set DesMac ffff.ffff.ffff 
        set ArpDesMac ffff.ffff.ffff 
    } else {
        if {$ArpDesMac == 0} {set ArpDesMac $DesMac }
        if {$DesMac == 0} {set DesMac $ArpDesMac }
    }
    #对于请求报文 ArpDesMac取0.0.0
    if {($ArpType == 1) } {
        set ArpDesMac 0.0.0 
    }
    # 参数检查
    set Match [MacValid $SrcMac]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetArpPkt >>> ArpSrcMac is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    set Match [MacValid $DesMac]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetArpPkt >>> DesMac is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    if {$ArpSrcMac != 0 } {
    set Match [MacValid $ArpSrcMac]
        if { $Match != 1} {
            Log "CIxiaNetPortETH::SetArpPkt >>> ArpSrcMac is invalid" warning
            return $::CIxiaNet::gIxia_ERR
        }
    }
    
    if {$ArpDesMac != 0 } {
    set Match [MacValid $ArpDesMac]
        if { $Match != 1} {
            Log "CIxiaNetPortETH::SetArpPkt >>> ArpDesMac is invalid" warning
            return $::CIxiaNet::gIxia_ERR
        }
    }
    
    set Match [IpValid $ArpSrcIP]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetArpPkt >>> ArpSrcIP is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }
    set Match [IpValid $ArpDesIP]
    if { $Match != 1} {
        Log "CIxiaNetPortETH::SetArpPkt >>> ArpDesIP is invalid" warning
        return $::CIxiaNet::gIxia_ERR
    }

    if {$VlanID==0 && $Priority!=0} {
        Log "CIxiaNetPortETH::SetArpPkt >>> a vlan id is prefered if the priority is used"
        return $::CIxiaNet::gIxia_ERR    
    }

    set EncapList {EET_II EET_802_2 EET_802_3 EET_SNAP}
    if {[lsearch $EncapList $EncapType] == -1} {
        Log "CIxiaNetPortETH::SetArpPkt >>> Invalid encapsulation type is prefered! $EncapType" warning
        return $::CIxiaNet::gIxia_ERR
    }

    if {$PacketLen < 0} {
        Log "CIxiaNetPortETH::SetArpPkt >>> Invalid packet length is prefered! $PacketLen" warning
        return $::CIxiaNet::gIxia_ERR
    }

    switch $EncapType {
           EET_II {set min_pktLen 42}
           EET_802_3 {set min_pktLen 42}
           EET_802_2 {set min_pktLen 45}
           EET_SNAP {set min_pktLen 50}
    }
    
    if {$PacketLen < $min_pktLen} {
        set PacketLen $min_pktLen
    }
    
    set arp_pkt [::packet::conpkt arp_pkt -deth $DesMac -seth $SrcMac -srcMac $ArpSrcMac -srcIp $ArpSrcIP \
                                          -desMac $ArpDesMac -desIp $ArpDesIP -oper $ArpType]
    Log "Set packet of {$_chassis $_card $_port}:\n\t$arp_pkt"
                                               
    return [$this SetCustomPkt $arp_pkt 60]
}

###########################################################################################
#@@Proc
#Name: CreateCustomStream
#Desc: set custom stream
#Args: 
#      FrameLen: frame length
#      Utilization: send utilization(percent)
#      TxMode: send mode,[0|1] 0 - continuous 1 - burst
#      BurstCount: burst package count
#      ProHeader: define packet value same as setcustompkt；
#Usage: port1 CreateCustomStream -FrameLen 64 -Utilization 10 -TxMode 0 -BurstCount 0 -ProHeader {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
#
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateCustomStream {args} {
	Log "Create custom stream..."
    set retVal $::CIxiaNet::gIxia_OK

    ##framelen utilization txmode burstcount protheader {portspeed 1000}
    set FrameLen 60
    set FrameRate 0
    set TxMode 0
    set BurstCount 0
    set ProHeader ""
    set Utilization 1
    if { $_uti != "" } {
        set Utilization $_uti
    }
    set argList {FrameLen.arg Utilization.arg FrameRate.arg TxMode.arg BurstCount.arg ProHeader.arg}

    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
        set result [cmdline::getopt args $argList opt val]
    }    
    if {$result<0} {
        puts "CreateCustomStream has illegal parameter! $val"
        return $::CIxiaNet::gIxia_ERR
    }
    
    if { $FrameRate != 0 } {
        set utilization $FrameRate
        set mode "PktPerSec"
    } else {
        set utilization $Utilization
        set mode "Uti"
        if { $_mode != "" } {
            set mode $_mode
        }
    }
    set txmode $TxMode
    set burstcount $BurstCount
    set protheader $ProHeader
    if { [llength $protheader] > $FrameLen } {
		set framelen [llength $protheader]
	} else {
		set framelen $FrameLen
	}
	
    set retVal1 [SetCustomPkt $protheader $framelen]
    if {[string match $retVal1 $::CIxiaNet::gIxia_ERR]} {	
        error "CreateCustomStream:SetCustomPkt failed."
        set retVal $::CIxiaNet::gIxia_ERR
    }
    set retVal2 [SetTxMode $txmode $burstcount]
    if {[string match $retVal2 $::CIxiaNet::gIxia_ERR]} {	
        error "CreateCustomStream:SetTxMode failed."
        set retVal $::CIxiaNet::gIxia_ERR
    }
    set retVal3 [SetTxSpeed $utilization $mode]
    if {[string match $retVal3 $::CIxiaNet::gIxia_ERR]} {	
        error "CreateCustomStream:SetTxSpeed failed."
        set retVal $::CIxiaNet::gIxia_ERR
    }
    return $retVal      
}

###########################################################################################
#@@Proc
#Name: CreateIPStream
#Desc: set IP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -desIP: destination ip default 0.0.0.0
#      -srcIP: source ip, default 0.0.0.0
#      -tos: tos default 0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#	   -signature: enable signature or not, 0(no) by default
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#
#Usage: _port1 CreateIPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateIPStream { args } {
	Log "Create IP stream..."
    set retVal $::CIxiaNet::gIxia_OK

    set framelen   64
    set framerate  0
    set txmode     0
    set burstcount 1
	set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000	
	set desip        0.0.0.0
	set srcip        0.0.0.0
    set tos        0
	set _portspeed  100
	set data 0
	set userPattern 0
	set signature 0 
	set ipmode 0 
	set ipbitsoffset1 0
	set ipbitsoffset2 0 
	set ipcount1 0 
    set ipcount2 0 
    set stepcount1 0 
    set stepcount2 0 

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         0
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set protocol   17
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum    100
    set utilization 100
    if { $_uti != "" } {
        set utilization $_uti
    }

    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
                append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val    
        puts "$opt: $val"
    }
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
		
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x0800 -type_mod "fixed"

    set vlan $vlanid
    set pri  $priority
    
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
    
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }
    
    Ipv4Hdr ipv4Hdr
	ipv4Hdr config -protocol_type $protocol \
		-tos $tos \
		-identification $id \
		-ttl $ttl \
		-flag $mayfrag \
		-fragment_offset 0 \
		-src $srcip \
		-dst $desip	
		
    if { $ipmode != 0} {
        if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
        if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
        switch $ipmode {
            ip_inc_src_ip  {
                ipv4Hdr config src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 
            }
            ip_inc_dst_ip  { 
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2
            }
            ip_dec_src_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode decr \
                    -src_mod $ipbitsoffset1 
            }
            ip_dec_dst_ip  {
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode decr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_inc_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_dec_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            default {
                error "Error: no such ipmode, please check your input!"
                set retVal $::CIxiaNet::gIxia_ERR
            }
        }
    }
    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv4Hdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr ipv4Hdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }  
    }
    
    catch { ::itcl::delete object etherHdr }
    
    catch { ::itcl::delete object vlanHdr }
    
    catch { ::itcl::delete object ipv4Hdr }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateTCPStream
#Desc: set TCP stream
#Args: args
#      -Name: the name of TCP stream
#	   -FrameLen: frame length
#      -Utilization: send utilization(percent), default 100
#      -TxMode: send mode,[0|1] 0 - continuous，1 - burst
#      -BurstCount: burst package count
#      -DesMac: destination MAC，default ffff-ffff-ffff
#      -SrcMac: source MAC，default 0-0-0
#      -DesIP: destination ip，default 0.0.0.0
#      -SrcIP: source ip, default 0.0.0.0
#      -Des_port: destionation _port, default 2000
#      -Src_port: source _port，default 2000
#      -Tos: tos，default 0
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#      -_portSpeed: _port speed，default 100
#Usage: _port1 CreateTCPStream -SrcMac 0010-01e9-0011 -DesMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateTCPStream { args } {
    Log "Create TCP stream..."
    set retVal $::CIxiaNet::gIxia_OK 
    
    set framelen        64
    set tos             0
    set txmode          0
    set framerate       0
    set utilization     100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set burstcount      1
    set srcport         2000
    set desport         2000     
    set desmac          ffff-ffff-ffff
    set srcmac          0000-0000-0000
    set desip           0.0.0.0
    set srcip           0.0.0.0
    set _portspeed      100    

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         1
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set pro        4
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum  100
    set seq        0
    set ack        0
    set tcpopt     ""
    set window     0
    set urgent     0  
    set data       0
    set userPattern 0
    set ipmode   0
    
    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
    lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
                append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val	
    }
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
    
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x0800 -type_mod "fixed"
    
    set vlan $vlanid
    set pri  $priority
    
    Ipv4Hdr ipv4Hdr
	ipv4Hdr config -protocol_type 6 \
		-tos $tos \
		-identification $id \
		-ttl $ttl \
		-flag $mayfrag \
		-fragment_offset 0 \
		-src $srcip \
		-dst $desip
                    	
    if { $ipmode != 0} {
        if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
        if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
        switch $ipmode {
            ip_inc_src_ip  {
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1
            }
            ip_inc_dst_ip  { 
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_dec_src_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode decr \
                    -src_mod $ipbitsoffset1 
            }
            ip_dec_dst_ip  {
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode decr \
                    -dst_mod $ipbitsoffset2
            }
            ip_inc_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_dec_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2
            }
            default {
                error "Error: no such ipmode, please check your input!"
                set retVal $::CIxiaNet::gIxia_ERR
            }
        }
    }
    
	TcpHdr tcpHdr
    tcpHdr config -src_port $srcport \
        -dst_port $desport \
        -seq_num $seq \
        -ack_num $ack \
        -window $window \
        -urgent_ptr $urgent 
		
    if {[llength $tcpopt] != 0} {
        if { $tcpopt > 63 } { 
            error "Error: tcpopt couldn't no more than 63."
            set retVal $::CIxiaNet::gIxia_ERR 
        } else {		
            set tcpFlag [expr $tcpopt % 2]
            for {set i 2} { $i <= 32} { incr i $i} {
                lappend tcpFlag [expr $tcpopt / $i % 2 ]
            }
        }
		
		tcpHdr config -fin_bit [lindex $tcpFlag 0] \
			-psh_bit [lindex $tcpFlag 3] \
			-rst_bit [lindex $tcpFlag 2] \
			-syn_bit [lindex $tcpFlag 1] \
			-urg_bit [lindex $tcpFlag 5] \
			-ack_bit [lindex $tcpFlag 4]		
    }
    
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
    
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }

    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv4Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr ipv4Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    }
    
    catch { ::itcl::delete object etherHdr }
    catch { ::itcl::delete object vlanHdr }
    catch { ::itcl::delete object ipv4Hdr }
    catch { ::itcl::delete object tcpHdr }
    
    return $retVal
}


###########################################################################################
#@@Proc
#Name: CreateUDPStream
#Desc: set UDP stream
#Args: args
#      -FrameLen: frame length
#      -Utilization: send utilization(percent), default 100
#      -TxMode: send mode,[0|1] 0 - continuous，1 - burst
#      -BurstCount: burst package count
#      -DesMac: destination MAC，default ffff-ffff-ffff
#      -SrcMac: source MAC，default 0-0-0
#      -DesIP: destination ip，default 0.0.0.0
#      -SrcIP: source ip, default 0.0.0.0
#      -Tos: tos，default 0
#	   -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	   -ipbitsoffset1: bitoffset,0 by default 
#	   -ipbitsoffset2: bitoffset,0 by default
#	   -ipcount1:  the count that the first ip stream will vary,0 by default 
#      -ipcount2:  the count that the second ip stream will vary,0 by default
#      -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	   -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#      -_portSpeed: _port speed，default 100
#Usage: _port1 CreateUDPStream -SrcMac 0010-01e9-0011 -DesMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateUDPStream { args } {
    Log "Create UDP stream..."
    set retVal $::CIxiaNet::gIxia_OK
    
    set framelen            64
    set tos                 0
    set txmode              0
    set framerate           0 
    set utilization         100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set burstcount          1
    set srcport             2000
    set desport             2000     
    set desmac              ffff-ffff-ffff
    set srcmac              0000-0000-0000
    set desip               0.0.0.0
    set srcip               0.0.0.0
    set _portspeed          100

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set type       "08 00"
    set ver        4
    set iphlen     5
    set dscp       0
    set tot        0
    set id         1
    set mayfrag    0
    set lastfrag   0
    set fragoffset 0
    set ttl        255        
    set pro        4
    set change     0
    set enable     true
    set value      {{00 }}
    set strframenum  100
    set data       0 
    set ipmode 0

    #get parameters
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val
    }
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
    # Added table interafce to enable arp response
    SetPortAddress -macaddress $srcmac -ipaddress $srcip -netmask "255.255.255.0" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
    
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x0800 -type_mod "fixed"
    
    set vlan $vlanid
    set pri  $priority
    
    UdpHdr udpHdr
    udpHdr config -src_port $srcport -dst_port $desport
    
    Ipv4Hdr ipv4Hdr
	ipv4Hdr config -protocol_type 17 \
		-tos $tos \
		-identification $id \
		-ttl $ttl \
		-flag $mayfrag \
		-fragment_offset 0 \
		-src $srcip	\
		-dst $desip
		
    if { $ipmode != 0} {
        if {$ipbitsoffset1 > 7} { set ipbitsoffset1 7 }
        if {$ipbitsoffset2 > 7} { set ipbitsoffset2 7 }
        switch $ipmode {
            ip_inc_src_ip  {
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 
            }
            ip_inc_dst_ip  { 
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_dec_src_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode decr \
                    -src_mod $ipbitsoffset1 
            }
            ip_dec_dst_ip  {
                ipv4Hdr config -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode decr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_inc_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            ip_dec_src_ip_and_dst_ip  { 
                ipv4Hdr config -src_num $ipcount1 \
                    -src_step "0.0.0.$stepcount1" \
                    -src_range_mode incr \
                    -src_mod $ipbitsoffset1 \
                    -dst_num $ipcount2 \
                    -dst_step "0.0.0.$stepcount2" \
                    -dst_range_mode incr \
                    -dst_mod $ipbitsoffset2 
            }
            default {
                error "Error: no such ipmode, please check your input!"
                set retVal $::CIxiaNet::gIxia_ERR
            }
        }
    }
    
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
    
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }

    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv4Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv4Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr ipv4Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }  
    }
    
    catch { ::itcl::delete object etherHdr }
    catch { ::itcl::delete object vlanHdr }
    catch { ::itcl::delete object ipv4Hdr }
    catch { ::itcl::delete object udpHdr }

    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateIPv6Stream
#Desc: set IPv6 stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 59 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLable: 0 by default
#
#Usage: _port1 CreateIPv6Stream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################

::itcl::body CIxiaNetPortETH::CreateIPv6Stream { args } {
	Log  "Create IPv6 stream..."
    set retVal $::CIxiaNet::gIxia_OK
    
    set framelen   128
    set framerate  0
    set utilization 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed  100
    set data 0
    set signature 0 

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    #set type       "86 DD"
    set ver        6
    set id         0    
    set protocol   41       
    set enable     true
    set value      {{00 }}
    set strframenum    100
    
    set nextheader  59
    set hoplimit   255
    set traffclass  0 
    set flowlabel   0 
    set change   0
    
    #get_params $args
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
    # Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipv6address  $srcip -prefixLen "64" -replyallarp 1
         
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
	
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x86dd -type_mod "fixed"
    
    set vlan $vlanid
    set pri  $priority           
    
    Ipv6Hdr ipv6Hdr
    ipv6Hdr config -src $srcip \
        -dst $desip \
        -flow_label $flowlabel \
        -hop_limit $hoplimit \
        -traffic_class $traffclass \
        -next_header $nextheader
    
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
    
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }	
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }

    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv6Hdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr ipv6Hdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        }   
    }
    
    catch { ::itcl::delete object etherHdr }
    catch { ::itcl::delete object vlanHdr }
    catch { ::itcl::delete object ipv6Hdr }
    
    return $retVal
}


###########################################################################################
#@@Proc
#Name: CreateIPv6TCPStream
#Desc: set IPv6 TCP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 59 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLable: 0 by default
#	  -ipmode: how to change the IP
#               0                          no change (default)
#               ip_inc_src_ip              source IP increment
#               ip_inc_dst_ip              destination IP increment
#               ip_dec_src_ip              source IP decrement
#               ip_dec_dst_ip              destination IP decrement
#               ip_inc_src_ip_and_dst_ip   both source and destination IP increment
#               ip_dec_src_ip_and_dst_ip   both source and destination IP decrement
#	  -ipcount1:  the count that the first ip stream will vary,0 by default 
#     -ipcount2:  the count that the second ip stream will vary,0 by default
#     -stepcount1: the step size that the first ip will vary, it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#	  -stepcount2: the step size that the second ip will vary,it should be the power of 2, eg. 1,2,4,8..., 0 by default means no change
#     -srcport: TCP source port , 2000 by default
#     -desport: TCP destination port, 2000 by default
#	  -tcpseq:  TCP sequenceNumber, 123456 by default
#     -tcpack:  TCP acknowledgementNumber, 234567 by default
#     -tcpopts: TCP Flag, 16 (push) by default 
#     -tcpwindow: TCP window, 4096 by default
#
#Usage: port1 CreateIPv6TCPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateIPv6TCPStream { args } {
	Log  "Create IPv6 TCP stream..."
         set retVal $::CIxiaNet::gIxia_OK

    set framelen   128
    set framerate  0
    set utilization 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed  100
    set data 0
    set signature 0 

    set name      ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set ver        6
    set id         1    
    set protocol   41       
    set enable     true
    set value      {{00 }}
    set strframenum    100
    
    set nextheader  6
    set hoplimit   255
    set traffclass  0 
    set flowlabel   0 
    set ipmode 0
    set ipcount1 1 
    set ipcount2 1 
    set stepcount1 1 
    set stepcount2 1 

    set change   0
    
    set srcport 2000
    set desport 2000 
    set tcpseq 123456
    set tcpack 234567
    set tcpopts 16 
    set tcpwindow 4096
    set tcpFlag ""
           
    #get_params $args
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
		lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }
   
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
	# Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipv6address  $srcip -prefixLen "64" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
	
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x86dd -type_mod "fixed"
    
    set vlan $vlanid
    set pri  $priority           
    
    Ipv6Hdr ipv6Hdr
    ipv6Hdr config -src $srcip \
        -dst $desip \
        -flow_label $flowlabel \
        -hop_limit $hoplimit \
        -traffic_class $traffclass \
        -next_header $nextheader
    
    switch $ipmode {
        0 {
        }
        ip_inc_src_ip  {
            ipv6Hdr config -src_num $ipcount1 \
                -src_step $stepcount1 \
                -src_mode incr 
        }
        ip_inc_dst_ip  { 
            ipv6Hdr config -dst_num $ipcount2 \
                -dst_step $stepcount2 \
                -dst_mode incr 
        }
        ip_dec_src_ip  { 
            ipv6Hdr config -src_num $ipcount1 \
                -src_step $stepcount1 \
                -src_mode decr 
        }
        ip_dec_dst_ip  {
            ipv6Hdr config -dst_num $ipcount2 \
                -dst_step $stepcount2 \
                -dst_mode decr 
        }
        ip_inc_src_ip_and_dst_ip  { 
            ipv6Hdr config -src_num $ipcount1 \
                -src_step $stepcount1 \
                -src_range_mode incr \
                -dst_num $ipcount2 \
                -dst_step $stepcount2 \
                -dst_mode incr 
        }
        ip_dec_src_ip_and_dst_ip  { 
            ipv6Hdr config -src_num $ipcount1 \
                -src_step $stepcount1 \
                -src_mode incr \
                -dst_num $ipcount2 \
                -dst_step $stepcount2 \
                -dst_mode incr 
        }
        default {
            error "Error: no such ipmode, please check your input!"
            set retVal $::CIxiaNet::gIxia_ERR
        }
    }

	TcpHdr tcpHdr
    tcpHdr config -src_port $srcport \
        -dst_port $desport \
        -seq_num $tcpseq \
        -ack_num $tcpack \
        -window $tcpwindow
		
	if {[llength $tcpopts] != 0} {
        if { $tcpopts > 63 } { 
            error "Error: tcpopts couldn't bigger than 63."
            set retVal $::CIxiaNet::gIxia_ERR 
        } else {		
            set tcpFlag [expr $tcpopts % 2]
            for {set i 2} { $i <= 32} { incr i $i} {
                lappend tcpFlag [expr $tcpopts / $i % 2 ]
            }
        }
		
		tcpHdr config -fin_bit [lindex $tcpFlag 0] \
			-psh_bit [lindex $tcpFlag 3] \
			-rst_bit [lindex $tcpFlag 2] \
			-syn_bit [lindex $tcpFlag 1] \
			-urg_bit [lindex $tcpFlag 5] \
			-ack_bit [lindex $tcpFlag 4]		
    }
	
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }

    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv6Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        } else {
            $trafficName config -pdu "etherHdr ipv6Hdr tcpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        }   
    }
    
    catch { ::itcl::delete object etherHdr }
    catch { ::itcl::delete object vlanHdr }
    catch { ::itcl::delete object ipv6Hdr }
    catch { ::itcl::delete object tcpHdr }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: CreateIPv6UDPStream
#Desc: set IPv6 UDP stream
#Args: 
#	   -name:    IP Stream name
#      -frameLen: frame length
#      -utilization: send utilization(percent), default 100
#      -txMode: send mode,[0|1] default 0 - continuous 1 - burst
#      -burstCount: burst package count
#      -desMac: destination MAC default ffff-ffff-ffff
#      -srcMac: source MAC default 0-0-0
#      -_portSpeed: _port speed default 100                   
#	   -data: content of frame, 0 by default means random
#             example: -data 0   ,  the data pattern will be random    
#                      -data abac,  use the "abac" as the data pattern
#     -VlanID: default 0
#     -Priority: the priority of vlan, 0 by default
#     -DesIP: the destination ipv6 address,the input format should be X:X::X:X
#     -SrcIP: the source ipv6 address, the input format should be X:X::X:X
#	  -nextHeader: the next header, 17 by default
#     -hopLimit: 255 by default
#     -traffClass: 0 by default
#     -flowLabel: 0 by default
#     -srcport: UDP source port , 2000 by default
#     -desport: UDP destination port, 2000 by default
#
#Usage: port1 CreateIPv6UDPStream -SMac 0010-01e9-0011 -DMac ffff-ffff-ffff
###########################################################################################
::itcl::body CIxiaNetPortETH::CreateIPv6UDPStream { args } {
    Log  "Create IPv6 udp stream..."
    set retVal $::CIxiaNet::gIxia_OK

    set framelen   128
    set framerate  0
    set utilization 100
    if { $_uti != "" } {
        set utilization $_uti
    }
    set txmode     0
    set burstcount 1
    set desmac       ffff-ffff-ffff
    set srcmac       0000-0000-0000
    set desip        ::
    set srcip        ::
    set portspeed   100
    set data        0
    set signature   0 
	set nextheader  17

    set name       ""
    set vlan       0
    set vlanid     0
    set pri        0
    set priority   0
    set cfi        0
    set ver        6
    set id         1    
    set protocol   41       
    set enable     true
    set value      {{00 }}
    set strframenum    100
    
    set hoplimit    255
    set traffclass  0 
    set flowlabel   0 
    set change   0
    
    set desport 2000
    set srcport  2000 
  
    #get_params $args
    set argList ""
    set temp ""
    for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
    }
    set tmp [split $temp \-]
    set tmp_len [llength $tmp]
    for {set i 0 } {$i < $tmp_len} {incr i} {
        set tmp_list [lindex $tmp $i]
        if {[llength $tmp_list] == 2} {
            append argList " [lindex $tmp_list 0].arg"
        }
    }
    while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
        set $opt $val        
    }
    if { [info exists smac] } {
		set srcmac $smac
	}
    if { [info exists dmac] } {
		set desmac $dmac
	}	
    # Added table interafce to enable arp response
    SetPortIPv6Address -macaddress $srcmac -ipv6address $srcip -prefixLen "64" -replyallarp 1
    
    #set srcmac [::ipaddress::format_mac_address $srcmac 6 ":"]
    #set desmac [::ipaddress::format_mac_address $desmac 6 ":"]
    set srcmac [HexToMac $srcmac]
    set desmac [HexToMac $desmac]
	
    EtherHdr etherHdr
    etherHdr config -dst $desmac -src $srcmac -type 0x86dd -type_mod "fixed"
    
    set vlan $vlanid
    set pri  $priority           
    
    Ipv6Hdr ipv6Hdr
    ipv6Hdr config -src $srcip \
        -dst $desip \
        -flow_label $flowlabel \
        -hop_limit $hoplimit \
        -traffic_class $traffclass \
        -next_header $nextheader
     
	UdpHdr udpHdr
    udpHdr config -src_port $srcport \
        -dst_port $desport  
		
    set frameRateType FPS
    if { $framerate != 0 } {
        set frameRateType FPS
    } else {
        set frameRateType PERCENT
        set framerate $utilization
    }
	
    set numBursts $burstcount        
    set numFrames $strframenum
    set burstMod continuous
    switch $txmode {
        0 {set burstMod continuous}
        1 {
            set burstMod burst
            set numBursts 1
            set numFrames $burstcount
        }
        2 {
            #stream config -dma advance
        }
        default {error "No such stream transmit mode, please check -strtransmode parameter."}
    }
    
    if {[llength $framelen] == 1} {
        set frameSizeType fixed
        set framesize [expr $framelen + 4]
    } else {
        set frameSizeType random
        set frameSizeMIN [lindex $framelen 0]
        set frameSizeMAX [lindex $framelen 1]
    }
    
    if {$data == 0} {
        set data "0000"
    }

    if {$name == ""} {
        set streamIndex [llength [GetPortStreams]]
        set trafficName $_portObj.traffic$streamIndex
    } else {
        set trafficName $name
    }
    Traffic $trafficName $_portObj NULL true
    set trafficName [ GetObject $trafficName ]
    
    if {[info exists vlanHdr]} {
        SingleVlanHdr vlanHdr
        vlanHdr config \
            -id $vlan \
            -pri $pri \
            -cfi $cfi
        
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 
        } else {
            $trafficName config -pdu "etherHdr vlanHdr ipv6Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        }   
    } else {
        if {$frameSizeType == "fixed"} {
            $trafficName config -pdu "etherHdr ipv6Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -frame_len $framesize \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        } else {
            $trafficName config -pdu "etherHdr ipv6Hdr udpHdr" \
                -frame_len_type $frameSizeType \
                -min_frame_len $frameSizeMIN \
                -max_frame_len $frameSizeMAX \
                -tx_mode $burstMod \
                -iteration_count $numBursts \
                -tx_num $numFrames \
                -payload_repeat false \
                -payload_type USERDEFINE \
                -payload $data \
				-load_unit $frameRateType \
				-stream_load $framerate 				
        }   
    }
    
    catch { ::itcl::delete object etherHdr }
    catch { ::itcl::delete object vlanHdr }
    catch { ::itcl::delete object ipv6Hdr }
    catch { ::itcl::delete object udpHdr }
     
    return $retVal
}


###########################################################################################
#@@Proc
#Name: SetErrorPacket
#Desc: set Error packet
#Args: 
#     -crc     : enable CRC error
#     -align   : enable align error
#     -dribble : enable dribble error
#     -jumbo   : enable jumbo error
#Usage: port1 SetErrorPacket -crc 1
###########################################################################################
::itcl::body CIxiaNetPortETH::SetErrorPacket {args} {
		Log   "set errors packet..."
		set retVal $::CIxiaNet::gIxia_OK
		
        #  Set the defaults
        set crc        0
        set align      0
        set dribble    0
		set jumbo      0

		#get_params $args
		set argList ""
		set temp ""
		for {set i 0} { $i < [llength $args]} {incr i} {
			lappend temp [ string tolower [lindex $args $i]]
		}
		set tmp [split $temp \-]
		set tmp_len [llength $tmp]
		for {set i 0 } {$i < $tmp_len} {incr i} {
			set tmp_list [lindex $tmp $i]
			if {[llength $tmp_list] == 2} {
				append argList " [lindex $tmp_list 0].arg"
			}
		}
		while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
			set $opt $val        
		}

        set traffic [lindex [GetPortStreams] end]
        $traffic config -enable_fcs_error_insertion false
        if {$crc == 1 || $dribble == 1 || $align == 1 || $jumbo ==1 } {
            $traffic config -enable_fcs_error_insertion true
        } 
        #if {$Jumbo == 1} {
        #    $traffic config -frame_len 9000			
        #}
		
        return $retVal
    }  

###########################################################################################
#@@Proc
#Name: SetFlowCtrlMode
#Desc: set the flow control mode on a port
#Args: 
#     1   enable
#     0   disable
#Usage: port1 SetFlowCtrlMode 1
###########################################################################################
::itcl::body CIxiaNetPortETH::SetFlowCtrlMode {args} {
    Log   "set flow control mode..."
    set retVal $::CIxiaNet::gIxia_OK
    
    # Enable flow control
    if { [llength $args] > 0} {
        set FlowCtrlMode [lindex $args 0]
    } else { 
        set FlowCtrlMode $args
    }
    
    $_portObj config -flow_control $FlowCtrlMode
    
    return $retVal
}
	
###########################################################################################
#@@Proc
#Name: DeleteAllStream
#Desc: To delete all streams of the target port
#Args: no
#Usage: port1 DeleteAllStream
###########################################################################################
::itcl::body CIxiaNetPortETH::DeleteAllStream {} {
    Log "Delete all streams of $_chassis $_card $_port..."
	set retVal $::CIxiaNet::gIxia_OK
    
    if { [catch {
        foreach streamObj [ GetPortStreams ] {
            ixNet exec deleteQuickFlowGroups [$streamObj cget -highLevelStream]
            ::itcl::delete object $streamObj
        }
		ixNet commit
    } err]} {
        Log "Failed to delete all streams on $_chassis $_card $_port: $err"
        set retVal $::CIxiaNet::gIxia_ERR
    }

    return $retVal 
}

###########################################################################################
#@@Proc
#Name: SetMultiModifier
#Desc: change multi-field value in the existing stream
#Args: 
#     -srcmac {mode step count}
# 	  -desmac {mode step count}
#	  -srcip  {mode step count}
#	  -desip  {mode step count}
#	  -srcport  {mode step count}
#	  -desport {mode step count}
#     mode: 
#     random incr decr list
#    
#Usage: port1 SetMultiModifier -srcmac {incr 1 16}
###########################################################################################
::itcl::body CIxiaNetPortETH::SetMultiModifier {args} {
    Log   "set multi-field value..."
    set retVal $::CIxiaNet::gIxia_OK
   
    set srcMac ""
    set desMac ""
    set srcIp "" 
    set desIp ""
    set srcPort ""
    set desPort ""
   
    set counterIndex 0
   
    set tableUdf 0
   
    set tmpList     [lrange $args 0 end]
    set idxxx      0
    set tmpllength [llength $tmpList]

    #  Set the defaults
    set Default    1

    while { $tmpllength > 0  } {
        set cmdx [string toupper [lindex $args $idxxx]]
        set argx [string toupper [lindex $args [expr $idxxx + 1]]]
   
        case $cmdx   {
            -SRCMAC      { set srcMac $argx}
            -DESMAC      {set desMac $argx }
            -SRCIP       {set srcIp $argx  }
            -DESIP       {set desIp $argx  }
            -SRCPORT     {set srcPort $argx}
            -DESPORT     {set desPort $argx}
            default   {
                set retVal $::CIxiaNet::gIxia_ERR
                error  "Error : cmd option $cmdx does not exist"
                return $retVal
            }
        }
        incr idxxx  +2
        incr tmpllength -2
    }
    
    set traffic [lindex [GetPortStreams] end]
    set hStream [ $traffic cget -highLevelStream ]
    #set EType [ list Fixed Random Incrementing Decrementing List ]
    set etherSrcMod ""
    if {$srcMac != ""} {
        set mac ""
        foreach stack [ ixNet getList $hStream stack ] {
            set srcStack [ GetField $stack sourceAddress ]
            if { $srcStack != "" } {
                set mac [ixNet getA $srcStack -startValue]
                break
            }
        }
        EtherHdr etherHdr 
        etherHdr config -src $mac -src_range_mode [lindex $srcMac 0] -src_step [lindex $srcMac 1] -src_num [lindex $srcMac 2] -modify 1
        $traffic config -pdu etherHdr
        catch { ::itcl::delete object etherHdr }
    }
   
    if {$desMac != ""} {
        set mac ""
        foreach stack [ ixNet getList $hStream stack ] {
            set dstStack [ GetField $stack destinationAddress ]
            if { $dstStack != "" } {
                set mac [ixNet getA $dstStack -startValue]
                break
            }
        }
        EtherHdr etherHdr 
        etherHdr config -dst $mac -dst_range_mode [lindex $desMac 0] -dst_step [lindex $desMac 1] -dst_num [lindex $desMac 2] -modify 1
        $traffic config -pdu etherHdr
        catch { ::itcl::delete object etherHdr }
    }
   
    if {$srcIp != ""} {
        set ip ""
        foreach stack [ ixNet getList $hStream stack ] {
            set srcStack [ GetField $stack srcIp ]
            if { $srcStack != "" } {
                set ip [ixNet getA $srcStack -startValue]
                break
            }
        }
        if { [ IsIPv4Address $value ] } {
            Ipv4Hdr ipv4Hdr
            ipv4Hdr config -src $ip -src_range_mode [lindex $srcIp 0] -src_step [lindex $srcIp 1] -src_num [lindex $srcIp 2] -modify 1
            $traffic config -pdu ipv4Hdr
            catch { ::itcl::delete object ipv4Hdr } 
        } else {
            Ipv6Hdr ipv6Hdr
            ipv6Hdr config -src $ip -src_range_mode [lindex $srcIp 0] -src_step [lindex $srcIp 1] -src_num [lindex $srcIp 2] -modify 1
            $traffic config -pdu ipv6Hdr
            catch { ::itcl::delete object ipv6Hdr } 
        }    
    }
                
    if {$desIp != ""} {
        set ip ""
        foreach stack [ ixNet getList $hStream stack ] {
            set dstStack [ GetField $stack dstIp ]
            if { $dstStack != "" } {
                set ip [ixNet getA $dstStack -startValue]
                break
            }
        }
        if { [ IsIPv4Address $value ] } {
            Ipv4Hdr ipv4Hdr
            ipv4Hdr config -dst $ip -dst_range_mode [lindex $desIp 0] -dst_step [lindex $desIp 1] -dst_num [lindex $desIp 2] -modify 1
            $traffic config -pdu ipv4Hdr
            catch { ::itcl::delete object ipv4Hdr }
        } else {
            Ipv6Hdr ipv6Hdr
            ipv6Hdr config -dst $ip -dst_range_mode [lindex $desIp 0] -dst_step [lindex $desIp 1] -dst_num [lindex $desIp 2] -modify 1
            $traffic config -pdu ipv6Hdr
            catch { ::itcl::delete object ipv6Hdr }
        }
    }    

    if {$srcPort != ""} {
        #Need to determine UDP or TCP
    }    

    if {$desPort != ""} {
        #Need to determine UDP or TCP
    }         
     
	return $retVal

}

###########################################################################################
#@@Proc
#Name: SetPortAddress
#Desc: Set IP address on the target port
#Args: 
#     MacAddress: the mac address of the port
#     IpAddress: the ip address of the port
#     NetMask: the netmask of the ip address
#     GateWay: the gateway of the port
#     ReplyAllArp: send a response to the arp request
#
#Usage: port1 SetPortAddress -macaddress 112233445566 -ipaddress 192.168.1.1 -netmask 255.255.255.0 -replyallarp 1
###########################################################################################
::itcl::body CIxiaNetPortETH::SetPortAddress {args} {
	Log "Set the IP address on $_chassis $_card $_port..."
	set retVal $::CIxiaNet::gIxia_OK

	set macaddress 0000-0000-1111
	set ipaddress 0.0.0.0 
	set netmask 255.255.255.0
	set gateway 0.0.0.0 
	set replyallarp 0 
	set vlan 0
	set flag 0 

    set prefixLen 24

    #Start to fetch param
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
		lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val	
		puts "$opt: $val"
	}
	
    #End of fetching param
    
    #Start to format the macaddress and IP netmask
    set macaddress [ HexToMac $macaddress ]
	
    for {set i 24} {$i > 0} {incr i -1} {
        if {$netmask == [ixNumber2Ipmask $i]} {
            set prefixLen $i
            break
        }
    }
	
    if {$gateway == "0.0.0.0"} {
        set numList [split $ipaddress "\."]
        set gateway [lindex $numList 0].[lindex $numList 1].[lindex $numList 2].1
    }

    if {$vlan} { 
        $_portObj config -mac_addr $macaddress -enable_arp $replyallarp -intf_ip $ipaddress -dut_ip $gateway -mask $prefixLen -inner_vlan_id $vlan
    } else {
        $_portObj config -mac_addr $macaddress -enable_arp $replyallarp -intf_ip $ipaddress -dut_ip $gateway -mask $prefixLen 
    }
    
	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetPortIPv6Address
#Desc: set IPv6 address on the target port
#Args: 
#     MacAddress: the mac address of the port
#     IpAddress: the ipv6 address of the port
#     PrefixLen: the prefix of the ipv6 address
#     GateWay: the gateway of the port
#     ReplyAllArp: send a response to the arp request
#
#Usage: port1 SetPortIPv6Address -macaddress 112233445566 -ipv6address 2001::1 -prefixLen 64 -replyallarp 1
###########################################################################################
::itcl::body CIxiaNetPortETH::SetPortIPv6Address {args} {

	Log "Set the IPv6 address on $_chassis $_card $_port..."
	set retVal $::CIxiaNet::gIxia_OK
	
	set macaddress 0000-0000-0000
	set ipv6address 0:0:0:0:0:0:0:1 
	set prefixlen 64
	set gateway 0:0:0:0:0:0:0:0 
	set replyallarp 0 
	set vlan 0 
	set flag 0 

    #Start to fetch param
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
		lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val	
		puts "$opt: $val"
	}
	
    #End of fetching param
    
    #Start to format the macaddress and IP netmask
    set macaddress [ HexToMac $macaddress ]
	
    if {$gateway == "0.0.0.0"} {
        set numList [split $ipaddress "\."]
        set gateway [lindex $numList 0].[lindex $numList 1].[lindex $numList 2].1
    }

    if {$vlan} { 
        $_portObj config -mac_addr $macaddress -enable_arp $replyallarp -ipv6_addr $ipv6address -ipv6_gw $gateway -ipv6_prefix_len $prefixlen -inner_vlan_id $vlan
    } else {
        $_portObj config -mac_addr $macaddress -enable_arp $replyallarp -ipv6_addr $ipv6address -ipv6_gw $gateway -ipv6_prefix_len $prefixlen
    }
    
	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetTxPacketSize
#Desc: set the Tx packet size of the target stream
#Args:  
#     frameSize:   0 means set the packet size to randomSize
#Usage: port1 SetTxPacketSize 1500
###########################################################################################
::itcl::body CIxiaNetPortETH::SetTxPacketSize { frameSize } {
    Log "Set the Tx packet size..."
    set retVal $::CIxiaNet::gIxia_OK
    
    set minSize 64
    set maxSize 1518
    set stepSize 1
    set randomSize 0 
     
    if {$frameSize > 0} {
        set frameSize $frameSize 
    } else {
        set randomSize 1  
    }

    set streamObj [lindex [GetPortStreams] end]
    if { $randomSize == 1 } {
        $streamObj config -frame_len_type random -min_frame_len $minSize -max_frame_len $maxSize -frame_len_step $stepSize
    } else {
        $streamObj config -frame_len_type fixed -frame_len $frameSize
    }
    return $retVal
}

###########################################################################################
#@@Proc
#Name: DeleteStream
#Desc: to disable a specific stream of the target port
#Args: -minindex: The first stream ID, start from 1. This could be a stream's name.
#	   -maxindex: If the "minindex" is a digital, then this function will disable streams from "minindex" to "maxindex". 
#                 If the "minindex" is a stream's name, then this option make no sense.
#	   
#Usage: port1 DeleteStream -minindex 1 -maxindex 10
#       port1 DeleteStream -minindex "stream_name"
###########################################################################################
::itcl::body CIxiaNetPortETH::DeleteStream {args} {
	Log "Disable the specific stream of $_chassis $_card $_port..."
	set retVal $::CIxiaNet::gIxia_OK
	
	set minindex 1
	set maxindex 1
	set test ""
	set flag ""

    #Get param	
	set argList ""
	set temp ""
	for {set i 0} { $i < [llength $args]} {incr i} {
        lappend temp [ string tolower [lindex $args $i]]
	}
	set tmp [split $temp \-]
	set tmp_len [llength $tmp]
	for {set i 0 } {$i < $tmp_len} {incr i} {
  	    set tmp_list [lindex $tmp $i]
  	    if {[llength $tmp_list] == 2} {
      	    append argList " [lindex $tmp_list 0].arg"
  	    }
 	}
	while {[set result [cmdline::getopt temp $argList opt val]] > 0} {
		set $opt $val
	}
	#end get param
	
    if { [ catch {
        if { [llength $minindex] != 0 } {
            # Stream ID
            if [string is digit $minindex] {
                foreach stream [lrange [GetPortStreams] [expr $minindex - 1] [expr $maxindex - 1]] {
                    ixNet exec deleteQuickFlowGroups [$stream cget -highLevelStream]
                    ::itcl::delete object $stream
                }
            } else {
                # Stream name 
                foreach stream [GetPortStreams] {
                    set name [[$stream cget -highLevelStream] cget -name]
                    if {$name == $minindex} {
                        ixNet exec deleteQuickFlowGroups [$stream cget -highLevelStream]
                        ::itcl::delete object $stream
                    }
                }
            }
        }
    } err ] } {
        Log "Failed to disable the specific stream of $_chassis $_card $_port..."
        set retVal $::CIxiaNet::gIxia_ERR
    }
	return $retVal
}

###########################################################################################
#@@Proc
#Name: SetCustomVFD
#Desc: set VFD
#Args:
#                       -Vfd1           VFD1 change state, default OffState; value:
#                                       OffState 
#                                       StaticState 
#                                       IncreState 
#                                       DecreState 
#                                       RandomState 
#                       -Vfd1cycle 	VFD1 cycle default no loop,continuous
#                       -Vfd1step	VFD1 change step,default 1
#                       -Vfd1offset     VFD1 offser,default 12, in bytes
#                       -Vfd1start      VFD1 start as {01} {01 0f 0d 13},default {00}
#                       -Vfd1len        VFD1 len [1~4], default 4
#                       -Vfd2           VFD2 change state, default OffState; value:
#                                       OffState 
#                                       StaticState 
#                                       IncreState 
#                                       DecreState 
#                                       RandomState 
#                       -Vfd2cycle 	VFD2 cycle default no loop,continuous
#                       -Vfd2step	VFD2 step,default 1
#                       -Vfd2offset     VFD2 offset,default 12, in bytes
#                       -Vfd2start      VFD2 start,as {01} {01 0f 0d 13},default {00}
#                       -Vfd2len        VFD2 len [1~4], default 4
## 从第208/8=26偏移处开始，变化6个字节的内容，起始值为E1 0 0 0 0 0 ，递增变化，循环10次
#Usage: port1 SetCustomVFD $::HVFD_1 $::HVFD_INCR 6 208 {E1 0 0 0 0 0} 10   
###########################################################################################
::itcl::body CIxiaNetPortETH::SetCustomVFD {Id Mode Range Offset Data DataCount {Step 1}} {
	puts "$Id $Mode $Range $Offset $Data $DataCount $Step"
	Log "Set custom VFD..."
	set retVal $::CIxiaNet::gIxia_OK
	if {[expr [llength $Data] % $Range ] != 0} { 
		error "The length of Data should be multiper of $Range."
		set retVal $::CIxiaNet::gIxia_ERR
		return $retVal
	}
						
	set stream [lindex [GetPortStreams] end]
	set highLevelStream [$stream cget -highLevelStream]
	set width [expr $Range * 8]
	if {$width > 32} {
		set width 32
	}
	set Data [string map {0x ""} $Data]
	#UDF1 config
	if { $Id == 1 } {
		set udfHandle [lindex [ixNet getL $highLevelStream udf] 0]
		set vfd1offset [expr $Offset / 8]
		ixNet setM $udfHandle -enabled true \
			-byteOffset $vfd1offset

		set vfd1start [HexToInt $Data]		
		set vfd1cycle $DataCount
		set vfd1step $Step
			
		switch $Mode {                
			1 { set vfd1 "RandomState" }
			2 { set vfd1 "IncreState" }
			3 { set vfd1 "DecreState" }
			4 { set vfd1 "List"}
			default { set vfd1 "OffState" }
		}
		
		if {$vfd1 != "OffState"} {
			switch $vfd1 {
			   "RandomState" {
					ixNet setA $udfHandle -type random
					ixNet commit 
					set random [lindex [ixNet getL $udfHandle random] end]					
					ixNet setM $random -width $width \
						-mask [string repeat X $Range]
					ixNet commit 
				}
				"StaticState" {
					ixNet setA $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]					
					ixNet setM $counter -startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width
					ixNet commit 
				}
				"IncreState" {
					ixNet setA $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]					
					ixNet setM $counter -direction increment \
						-startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width
					ixNet commit 
				}
				"DecreState" {
					ixNet setA $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]
					ixNet setM $counter -direction decrement \
						-startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width
					ixNet commit 
				}
				"List" {
					set valList [list ]
					for { set i 0} { $i < [llength $Data] } { incr i $Range} {
						lappend valList [HexToInt [lrange $Data [expr $i * $Range] [expr ($i + 1) * $Range - 1] ]]
					}		
					ixNet setA $udfHandle -type valueList
					ixNet commit
					set valueList [lindex [ixNet getL $udfHandle valueList] end]
					ixNet setM $valueList -width $width \
						-startValueList $valList
					ixNet commit 
				}
			}
		} elseif {$vfd1 == "OffState"} {
			ixNet setM $udfHandle -enabled false
			ixNet commit 
		}
	}

	#UDF2 config
	if { $Id == 2 } {
		set udfHandle [lindex [ixNet getL $highLevelStream udf] 1]
		set vfd1offset [expr $Offset / 8]
		ixNet setM $udfHandle -enabled true \
			-byteOffset $vfd1offset

		set vfd1start [HexToInt $Data]		
		set vfd1cycle $DataCount
		set vfd1step $Step
			
		switch $Mode {                
			1 { set vfd1 "RandomState" }
			2 { set vfd1 "IncreState" }
			3 { set vfd1 "DecreState" }
			4 { set vfd1 "List"}
			default { set vfd1 "OffState" }
		}
		
		if {$vfd1 != "OffState"} {
			switch $vfd1 {
			   "RandomState" {
					ixNet setA $udfHandle -type random
					ixNet commit 
					set random [lindex [ixNet getL $udfHandle random] end]					
					ixNet setM $random -width $width \
						-mask [string repeat X $Range]
					ixNet commit 
				}
				"StaticState" {
					ixNet setM $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]					
					ixNet setM $counter -startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width	
					ixNet commit 
				}
				"IncreState" {
					ixNet setA $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]					
					ixNet setM $counter -direction increment \
						-startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width
					ixNet commit 
				}
				"DecreState" {
					ixNet setA $udfHandle -type counter
					ixNet commit 
					set counter [lindex [ixNet getL $udfHandle counter] end]
					ixNet setM $counter -direction decrement \
						-startValue $vfd1start \
						-stepValue $vfd1step \
						-count $vfd1cycle \
						-width $width
					ixNet commit 
				}
				"List" {
					set valList [list ]
					for { set i 0} { $i < [llength $Data] } { incr i $Range} {
						lappend valList [HexToInt [lrange $Data [expr $i * $Range] [expr ($i + 1) * $Range - 1] ]]
					}			
					ixNet setM $udfHandle -type valueList
					ixNet commit
					set valueList [lindex [ixNet getL $udfHandle valueList] end]
					ixNet setM $valueList -width $width \
						-startValueList $valList
					ixNet commit 
				}
			}
		} elseif {$vfd1 == "OffState"} {
			ixNet setM $udfHandle -enabled false
			ixNet commit 
		}
	}

	#UDF3 config
	if { $Id == 3 && $Mode == 4 } {
		set udfHandle [lindex [ixNet getL $highLevelStream udf] 2]
		set vfd1offset [expr $Offset / 8]
		ixNet setM $udfHandle -enabled true \
			-byteOffset $vfd1offset

		set vfd1start [HexToInt $Data]		
		set vfd1cycle $DataCount
		set vfd1step $Step
		
		set valList [list ]
		for { set i 0} { $i < [llength $Data] } { incr i $Range} {
			lappend valList [HexToInt [lrange $Data [expr $i * $Range] [expr ($i + 1) * $Range - 1] ]]
		}
		ixNet setA $udfHandle -type valueList
		ixNet commit
		set valueList [lindex [ixNet getL $udfHandle valueList] end]
		ixNet setM $valueList \
			-width $width \
			-startValueList $valList
		ixNet commit 
	}
	
	ixNet commit 
	
    return $retVal
}

####################################################################
# 方法名称： SetVFD1
# 方法功能： 设置指定网卡发包的源MAC地址(使用VFD1)
# 入口参数：
#	    Offset 偏移，in byte,注意不要偏移位设置到报文的CHECKSUM的字节上。
#       DataList   需要设定的数据list，如果超过4个字节则取前面4个字节
#	    Mode   源MAC地址的变化形式，可取 
#                                     HVFD_RANDOM,
#                                     HVFD_INCR,
#                                     HVFD_DECR,
#                                     HVFD_SHUFFLE
#	    Count  源地址变化的循环周期
#
# 出口参数： 无
# 其他说明： 使用了VFD1资源
# 例   子:
#            SetVFD1 8 {1 1} $::HVFD_SHUFFLE 100
#            SetVFD1 12 {0x00 0x10 0xec 0xff 0x00 0x12} $::HVFD_INCR 100
####################################################################
::itcl::body CIxiaNetPortETH::SetVFD1 {Offset DataList {Mode 1} {Count 0}} {
    set Offset [expr 8*$Offset]
	if { ![info exists ::HVFD_1] } {
		set ::HVFD_1 1
	}
	$this SetCustomVFD $::HVFD_1 $Mode [llength $DataList] $Offset $DataList $Count 1
}

####################################################################
# 方法名称： SetVFD2
# 方法功能： 设置指定网卡发包的源MAC地址(使用VFD2)
# 入口参数：
#	    Offset 偏移，in byte,注意不要偏移位设置到报文的CHECKSUM的字节上。
#           DataList   需要设定的数据list，如果超过6个字节则取前面6个字节
#	    Mode   源MAC地址的变化形式，可取 
#                                     HVFD_RANDOM,
#                                     HVFD_INCR,
#                                     HVFD_DECR,
#                                     HVFD_SHUFFLE
#	    Count  源地址变化的循环周期
#
# 出口参数： 无
# 其他说明： 使用了VFD2资源
# 例   子:
#            SetVFD2 8 {1 1} $::HVFD_INCR 100
#            SetVFD2 12 {0x00 0x10 0xec 0xff 0x00 0x12} $::HVFD_INCR 100
####################################################################
::itcl::body CIxiaNetPortETH::SetVFD2 {Offset DataList {Mode 5}  {Count 0} } {
    set Offset [expr 8*$Offset]
	if { ![info exists ::HVFD_2] } {
		set ::HVFD_2 2	
	}
	$this SetCustomVFD $::HVFD_2 $Mode [llength $DataList] $Offset $DataList $Count 1
}

###########################################################################################
#@@Proc
#Name: CaptureClear
#Desc: Clear capture buffer, in face, Ixia doesn't need clear the buffer, because each
#      time begin start capture, the buffer will clear automatically.
###########################################################################################
::itcl::body CIxiaNetPortETH::CaptureClear {} {
	Log "Capture clear..."
    $_capture stop
    return $retVal
}

###########################################################################################
#@@Proc
#Name: StartCapture
#Desc: Start Port capture
#Args: mode: capture mode,1:capture trig,2:capture bad,0:capture all
#Usage: port1 StartCapture 
###########################################################################################
::itcl::body CIxiaNetPortETH::StartCapture {{CapMode 0}} {
	Log "Start capture on $_chassis $_card $_port..."
	set retVal $::CIxiaNet::gIxia_OK
    capture   setDefault
    switch $CapMode {
        0 {
            $_capture config -cap_mode all
        }
        2 {
            $_capture config -cap_mode trig
        }
        default {}
    }
    $_capture start
    return $retVal
}

###########################################################################################
#@@Proc
#Name: StopCapture
#Desc: Stop Port capture
#Args:
#Usage: port1 StopCapture 
###########################################################################################
::itcl::body CIxiaNetPortETH::StopCapture { } {
	Log "Stop capture on $_chassis $_card $_port..."
    set retVal $::CIxiaNet::gIxia_OK
    $_capture stop
    return $retVal
}

###########################################################################################
#@@Proc
#Name: ReturnCaptureCount
#Desc: Get capture buffer packet number. 
#Args:
#Ret:a list include 1.   ::CIxiaNet::gIxia_OK or ::CIxiaNet::gIxia_ERR, ::CIxiaNet::gIxia_OK means ok, ::CIxiaNet::gIxia_ERR means error.
#                   2.   the number of packet.
#Usage: port1 ReturnCaptureCount
###########################################################################################
::itcl::body CIxiaNetPortETH::ReturnCaptureCount { } {
	Log "Get capture count ..."
    return [ GetStatsFromReturn [$_capture get_count ] count ]
}

###########################################################################################
#@@Proc
#Name: ReturnCapturePkt
#Desc: Get detailed byte infomation of specific packet. 
#Args:
#	-index : the index of packet in buffer. default 0.
#       -offset: the bytes to be retrieved offset. default 0.
#       -len   : how many bytes to be retrieved.
#                                 default 0, means the whole packet, from the offset byte to end.
#Ret:a list include 1.   0 or 1, 0 means ok, 1 means error.
#                   2.   a list include the specific byte content of the packet.
#Usage: port1 ReturnCapturePkt
###########################################################################################
::itcl::body CIxiaNetPortETH::ReturnCapturePkt { {PktIndex 0} } {
	Log "Get capture packet..."
    set retVal $::CIxiaNet::gIxia_OK
    set packet [$_capture get_content -packet_index [expr $PktIndex + 1]
    
    return [ GetStatsFromReturn $packet Content ]
}

###########################################################################################
#@@Proc
#Name: GetPortInfo
#Desc: retrieve specific counter.
#Args:
#    -RcvPkt: received packets count
#    -TmtPkt: sent packets count
#    -RcvTrig: capture trigger packets count
#    -RcvTrigRate: capture trigger packets rate
#    -RcvByte: capture received packets bytes
#    -RcvByteRate: capture received packets rate
#    -RcvPktRate: received packets rate
#    -TmtPktRate: sent packects count
#    -CRC: received CRC errors packets count
#    -CRCRate: received CRC errors packets rate
#    -Collision: collision packets count
#    -CollisionRate: collision packets rate
#    -Align: alignment errors packets count
#    -AlignRate: alignment errors packets rate
#    -Oversize: oversize packets count
#    -OversizeRate: oversize packets rate
#    -Undersize: undersize packets count
#    -UndersizeRate: undersize packets rate
#Ret: success: eg: ::CIxiaNet::gIxia_OK {-RcvPkt 100} {-RcvPktRate 20}
#     fail:    ::CIxiaNet::gIxia_ERR {}
#Usage: port1 GetPortInfo -Undersize 1 -Oversize 1
###########################################################################################
::itcl::body CIxiaNetPortETH::GetPortInfo { args } {
    set retVal $::CIxiaNet::gIxia_OK

    set RcvPkt ""
    set TmtPkt ""
    set RcvTrig ""
	set RcvTrigRate ""
	set RcvByte ""
	set RcvByteRate ""
	set RcvPktRate ""
	set TmtPktRate ""
	set CRC ""
	set CRCRate ""
	set Align ""
	set AlignRate ""
	set Oversize ""
	set OversizeRate ""
	set Undersize ""
	set UndersizeRate ""
	
	set argList {RcvPkt.arg TmtPkt.arg RcvTrig.arg RcvTrigRate.arg RcvByte.arg RcvByteRate.arg RcvPktRate.arg TmtPktRate.arg \
                     CRC.arg CRCRate.arg Align.arg AlignRate.arg Oversize.arg OversizeRate.arg Undersize.arg UndersizeRate.arg}
        
    set result [cmdline::getopt args $argList opt val]
    while {$result>0} {
        set $opt $val
		puts "$opt: $val"
        set result [cmdline::getopt args $argList opt val]        
    }
    
    if {$result<0} {
        Log "GetPortInfo has illegal parameter! $val"
        return $$::CIxiaNet::gIxia_ERR
    }
    
    ixConnectToTclServer $_chassis
    ixConnectToChassis $_chassis
	chassis get $_chassis
	set chasId [ chassis cget -id ]
	port get $chasId $_card $_port
	set owner [ port cget -owner ]
	ixLogin $owner	
        
    if [stat get statAllStats $chasId $_card $_port] {
        error "Get all Event counters Error"
        set retVal $::CIxiaNet::gIxia_ERR
        return $retVal
    }
    
    if { $RcvPkt != "" } {
        upvar $RcvPkt m_RcvPktt
        set m_RcvPktt [stat cget -framesReceived]	
    }
    
    if { $TmtPkt != "" } {
        upvar $TmtPkt m_TmtPkt
        set m_TmtPkt [stat cget -framesSent]
    }
    
    if { $RcvTrig != "" } {
        upvar $RcvTrig m_RcvTrig
        set m_RcvTrig [stat cget -captureTrigger]
    }
    
    if { $RcvByte != "" } {
        upvar $RcvByte m_RcvByte
        set m_RcvByte [stat cget -bytesReceived]
    }
    
    if { $CRC != "" } {
        upvar $CRC m_CRC
        set m_CRC [stat cget -fcsErrors]
    }
    
    if { $Align != "" } {
        upvar $Align m_Align
        set m_Align [stat cget -alignmentErrors]
    }
    
    if { $Oversize != "" } {
        upvar $Oversize m_Oversize
        set m_Oversize [stat cget -oversize]
    }
                   
    if { $Undersize != "" } {
        upvar $Undersize m_Undersize
        set m_Undersize [stat cget -undersize]
    }
    
    if [stat getRate allStats $chasId $_card $_port] {
            error "Get all Rate counters Error"
            set retVal $::CIxiaNet::gIxia_ERR
        return $retVal
    }
    
    if { $RcvTrigRate != "" } {
        upvar $RcvTrigRate m_RcvTrigRate
        set m_RcvTrigRate [stat cget -captureTrigger]
    }
    
    if { $RcvByteRate != "" } {
        upvar $RcvByteRate m_RcvByteRate
        set m_RcvByteRate [stat cget -bytesReceived]
    }
    
    if { $RcvPktRate != "" } {
        upvar $RcvPktRate m_RcvPktRate
        set m_RcvPktRate [stat cget -framesReceived]
    }
    
    if { $TmtPktRate != "" } {
        upvar $TmtPktRate m_TmtPktRate
        set m_TmtPktRate [stat cget -framesSent]
    }
    
    if { $CRCRate != "" } {
        upvar $CRCRate m_CRCRate
        set m_CRCRate [stat cget -fcsErrors]
    }
    
    if { $AlignRate != "" } {
        upvar $AlignRate m_AlignRate
        set m_AlignRate [stat cget -alignmentErrors]
    }
    
    if { $OversizeRate != "" } {
        upvar $OversizeRate m_OversizeRate
        set m_OversizeRate [stat cget -oversize]
    }
    
    if { $UndersizeRate != "" } {
        upvar $UndersizeRate m_UndersizeRate
        set m_UndersizeRate [stat cget -undersize]
    }
    
    return $::CIxiaNet::gIxia_OK
}
###########################################################################################
#@@Proc
#Name: GetPortStatus
#Desc: retrieve specific port's status
#Args: No
#    
#Ret: success:  {up} {down}
#     fail:    ::CIxiaNet::gIxia_ERR {}
#
#Usage: port1 GetPortInfo 
###########################################################################################

::itcl::body CIxiaNetPortETH::GetPortStatus {  } {
	Log "Get port's status..."
	if {[ixNet getA $_handle -state] == "up"} {
        return up
    }

	return down
}

###########################################################################################
#@@Proc
#Name: GetTypeName
#Desc: retrieve specific port's speed
#Args: No
#    
#Ret: success:  the type of specific port,ie. GigabitEthernet
#     fail:    ::CIxiaNet::gIxia_ERR {}
#
#Usage: port1 GetTypeName
###########################################################################################
::itcl::body CIxiaNetPortETH::GetTypeName {  } {
    Log "Get port's speed..."
    if {[catch {
        set type [ixNet getL [lindex [ixNet getL $_handle l1Config] 0] [ixNet getA $_handle -type]]
        set portSpeed [ixNet getA $type -speed]
        } err]} {
        if {$type == "tenGigLan" || $type == "tenGigLanFcoe" || $type == "tenGigWan" || $type == "tenGigWanFcoe"} {
            set portSpeed "speed10g"
        } elseif {$type == "fortyGigLan" || $type == "fortyGigLanFcoe" } {
            set portSpeed "speed40g"
        } else {
            set portSpeed "speed1000"
        }
    }
	
    if {$portSpeed == "speed100fd" || $portSpeed == "speed100hd"} {
        set typeName "Ethernet"
    } elseif {$portSpeed == "speed10g"} {
        set typeName "Ten-GigabitEthernet"
    } elseif {$portSpeed == "speed40g"} {
        set typeName "FortyGigE"
    } elseif {$portSpeed == "speed100g"} {
        set typeName "HundredGigE"
    } else {
        set typeName "GigabitEthernet"
    }
    
	return $typeName
}

###########################################################################################
#@@Proc
#Name: GetPortCableType
#Desc: retrieve specific port's media type
#Args: No
#    
#Ret: success:  the media of specific port,ie. F C
#     fail:    ::CIxiaNet::gIxia_ERR {}
#
#Usage: port1 GetPortCableType
###########################################################################################
::itcl::body CIxiaNetPortETH::GetPortCableType {  } {
    Log "Get port cable type..."
	set type [ixNet getA $_handle -type]
	if { $type == "ethernet" } {
		set eth [ixNet getL [lindex [ixNet getL $_handle l1Config] 0] $type]
		if {[ixNet getA $eth -media] == "copper"} {
			set retVal C
		} elseif {[ixNet getA $eth -media] == "fiber"} {
			set retVal F
		}	
	} elseif { $type == "atm" } {
		set retVal UNKNOWN
	} elseif { $type == "pos" } {
		set retVal UNKNOWN
	} elseif { $type == "ethernetvm" } {
		set retVal UNKNOWN
	} else {
		set retVal F
	}
	
    return $retVal
}

###########################################################################################
#@@Proc
#Name: Clear
#Desc: Clear Counter
#Args:
#Usage: port1 Clear
###########################################################################################
::itcl::body CIxiaNetPortETH::Clear { args } {
	Log "Clear counter..."
    Tester::clear_traffic_stats
    return $retVal
}

