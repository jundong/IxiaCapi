#=========================================================================
# 版本号：1.0
#   
# 文件名：IxiaCapi.tcl
# 
# 文件描述：IxiaCapi库初始化文件，当用户输入 "package require IxiaCapi" 调用此文件
# 
# 作者：李霄石(Shawn Li)
#
# 创建时间: 2008.03.25
#
# 修改记录： 
#   
# 版权所有：Ixia
#====================================================================================
# Change made by Eric on v2.0
#        1.fix the multiversion loading package problem
#        2.add ixNetwork TrafficEngine
#        3.add ixNetwork Profile
#        4.add ixNetwork Stream
#        5.add ixNetwork HeaderCreator
#        6.add ixNetwork PacketBuilder
# Change made by Cathy on v2.7
#        1.add ixNetwork TestAnalysis in TestStatistics
#        2.add ixNetwork Filter
#        3.remove ixOS package
# Change made by Cathy on v3.5 2015.12.25 
# Change made by Cathy on v3.6 2016.03.22 
# Change made by Cathy on v3.7 2016.05.06 

package require Itcl
package req ip
namespace import itcl::*

proc GetEnvTcl { product } {
   
   set productKey     "HKEY_LOCAL_MACHINE\\SOFTWARE\\Ixia Communications\\$product"
   set versionKey     [ registry keys $productKey ]
   set latestKey      [ lindex $versionKey end ]

    if { $latestKey == "Multiversion" } {
        set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
        if { $latestKey == "InstallInfo" } {
            set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 3 ] ]
        }
    } elseif { $latestKey == "InstallInfo" } {
        set latestKey   [ lindex $versionKey [ expr [ llength $versionKey ] - 2 ] ]
    }
   set installInfo    [ append productKey \\ $latestKey \\ InstallInfo ]            
   return             [ registry get $installInfo  HOMEDIR ]

}

set portlist [list]
set trafficlist [list]
set portnamelist [list]
set trafficnamelist [list]
set tportlist [list]
set remote_server "localhost"
set remote_serverPort "8009"
proc loadconfig { filename } {
    global portlist
    global trafficlist
    global portnamelist
    global trafficnamelist
    global tportlist
    puts "Loadconfig $filename"
    ixNet exec loadConfig [ixNet readFrom $filename]
    set root [ixNet getRoot]
    set portlist [ixNet getL $root vport]
    foreach portobj $portlist {
        lappend portnamelist [ixNet getA $portobj -name]
    }
    
    set trafficlist [ixNet getL [ixNet getL $root traffic] trafficItem]
    foreach trafficItemobj $trafficlist {
	    lappend trafficnamelist [ixNet getA $trafficItemobj -name]
		set itemlist [lindex [ixNet getL $trafficItemobj highLevelStream] 0]
		lappend tportlist [ixNet getA $itemlist -txPortName]
        # set itemlist [ixNet getL $trafficItemobj highLevelStream]
        # foreach trafficobj $itemlist {
            # lappend trafficnamelist [ixNet getA $trafficobj -name]
            # lappend tportlist [ixNet getA $trafficobj -txPortName]
        # }
    }
}

proc Login { { location "localhost/8009"} { force 0 } { filename null } } {
	global ixN_tcl_v
	global loginInfo
    
    global portlist
    global trafficlist
    global portnamelist
    global trafficnamelist
    global tportlist
    
	global remote_server
	global remote_serverPort
	
	set loginInfo $location
    puts "Login...$location"	
	if { $location == "" } {
		set port "localhost/8009"
	} else {
		set port $location
	}

	set portInfo [ split $port "/" ]
	set remote_server	 [ lindex $portInfo 0 ]
	if { [ regexp {\d+\.\d+\.\d+\.\d+} $remote_server ] || ( $remote_server == "localhost" ) } {
		set portInfo [ lreplace $portInfo 0 0 ]
	} else {
		set remote_server localhost
	}
	if { [ llength $portInfo ] == 0 } {
		set portInfo 8009
	}
    
    set flag 0
	foreach port $portInfo {
		ixNet disconnect
		ixNet connect $remote_server -version $ixN_tcl_v -port $port
		set root [ ixNet getRoot]
		if { $force } {
			puts "Login successfully on port $port."
			#return	
			set remote_serverPort $port
            set flag 1            
		} else {
			if { [ llength [ ixNet getL $root vport ] ] > 0 } {
				puts "The connecting optional port $port is ocuppied, try next port..."
				continue
			} else {
				puts "Login successfully on port $port."
				#return
				set remote_serverPort $port
                set flag 1
			}
		}
        
        if { $flag == 1 } {
            if { $filename != "null" } {
                loadconfig $filename
				after 15000
                
                #foreach pname $portnamelist pobj $portlist {
                #    Port $pname NULL NULL $pobj
                #}
                #
                #foreach tname $trafficnamelist tobj $trafficlist tport $portnamelist {
                #    Traffic $tname $tport $tobj
                #}
				
				return
                
            } else {
                return
            }
        }
	}
	puts "Login failed on all port $portInfo."
	return
}

proc GetAllPortObj {} {

	set portObj [list]
	set objList [ find objects ]
	foreach obj $objList {
		if { [ $obj isa Port ] } {
			lappend portObj [ $obj cget -handle ]
		}
	}
	return $portObj
}

set ixN_tcl_v "6.0"
puts "connect to ixNetwork Tcl Server version $ixN_tcl_v"
set ctype "ixNetwork"
if { $::tcl_platform(platform) == "windows" } {
	puts "windows platform..."
	package require registry	
	
	if { $ctype != "ixNetwork" } {
        catch {	
        puts "load package IxTclHal..."	
            source [ GetEnvTcl IxOS ]/TclScripts/bin/ixiawish.tcl
            package require IxTclHal
            source [file join $currDir afterchange.tcl]
        }
    }
    puts "load package IxTclNetwork..."
    if { [ catch {
	  lappend auto_path  "[ GetEnvTcl IxNetwork ]/TclScripts/lib/IxTclNetwork"
	} err ] } {
	  puts "Failed to invoke IxNetwork environment...$err"
	}

    package require IxTclNetwork
}



set gOffline 0

namespace eval IxiaCapi {
   namespace export *
   
} ;# end of namespace eval ixia


#modified by shawn 2009.3.18
#comments:添加Host类和Router/Rip类tcl文件
#-----------------------------------------
set currDir [file dirname [info script]]
 #source [file join $currDir Ixia_CRouter.tcl]
 #source [file join $currDir Ixia_CRipRouter.tcl]
# source [file join $currDir Ixia_CBgpRouter.tcl]
 #source [file join $currDir Ixia_COspfRouter.tcl]
# source [file join $currDir Ixia_CIsisRouter.tcl]
# source [file join $currDir Ixia_COspfV3Router.tcl]

source [file join $currDir config.tcl]
source [file join $currDir Logger.tcl]
source [file join $currDir String.tcl]
source [file join $currDir Regexer.tcl]
source [file join $currDir IxNetLib.tcl]
source [file join $currDir IxNetTestDevice.tcl]
source [file join $currDir IxNetTestPort.tcl]
source [file join $currDir IxNetHost.tcl]
source [file join $currDir IxNetTestPortMgr.tcl]
source [file join $currDir IxNetTrafficMgr.tcl]
source [file join $currDir IxNetProfile.tcl]
source [file join $currDir IxNetStream.tcl]
source [file join $currDir IxNetHeaderCreator.tcl]
source [file join $currDir IxNetPacketBuilder.tcl]
source [file join $currDir IxNetTrafficEngine.tcl]
source [file join $currDir IxNetTestStatistic.tcl]
source [file join $currDir IxNetFilter.tcl]
source [file join $currDir Ixia_NetTester.tcl]
source [file join $currDir Ixia_NetObj.tcl]
source [file join $currDir Ixia_NetPort.tcl]
source [file join $currDir Ixia_NetFlow.tcl]
source [file join $currDir Ixia_NetTraffic.tcl]
source [file join $currDir Ixia_NetDhcp.tcl]
source [file join $currDir Ixia_NetPPPoX.tcl]
source [file join $currDir Ixia_NetCapture.tcl]
source [file join $currDir Ixia_NetCaptureFilter.tcl]
source [file join $currDir Ixia_NetDeviceGroup.tcl]
source [file join $currDir Ixia_convert.tcl]
source [file join $currDir IxNetDHCP.tcl]
source [file join $currDir IxNetPPPoE.tcl]
source [file join $currDir IxNet802Dot1x.tcl]
source [file join $currDir IxNetIPv6SLAAC.tcl]
source [file join $currDir Ixia_NetIgmp.tcl]
source [file join $currDir IxNetMld.tcl]
source [file join $currDir IxNetIGMP.tcl]
source [file join $currDir IxNetIGMPOPPPOE.tcl]
source [file join $currDir IxNetIGMPODHCP.tcl]
source [file join $currDir Ixia_NetBgp.tcl]
source [file join $currDir IxNetBGP.tcl]
source [file join $currDir Ixia_NetOspf.tcl]
source [file join $currDir Ixia_NetIsis.tcl]
source [file join $currDir IxNetISIS.tcl]
source [file join $currDir IxNetOSPF.tcl]
source [file join $currDir Ixia_NetLdp.tcl]
source [file join $currDir IxNetLDP.tcl]

source [file join $currDir CIxia.tcl]
source [file join $currDir CIxiaPortETH.tcl]

set errNumber(1)    "Bad argument value or out of range..."
set errNumber(2)    "Madatory argument missed..."
set errNumber(3)    "Unsupported parameter..."
set errNumber(4)    "Confilct argument..."

#namespace import ::IxiaCapi::*
namespace import ::IxiaCapi::Regexer::*
namespace import ::IxiaCapi::Logger::*
namespace import ::IxiaCapi::Lib::*

set ixCapiVersion 3.7
package provide IxiaCAPI $ixCapiVersion
namespace import IxiaCapi::*
