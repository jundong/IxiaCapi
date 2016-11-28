#############################################################################################################################
# Script Name     :   Device.tcl
# Last Mod        :
# Function Des    :   Main script
# Related Script  :   Need Accton_SystemAcceptance_Lib.tcl and Accton_SystemAcceptance_config.ini.
# Scriptor        :   Ji Li & Jeffrey Li & Ning Zhang & Jingbo
# 修改记录        :   Judo Xu 2016.10.8
#                     1. 修改函数constructor的参数host_ip为ip，保持各个测试仪器类的参数统一
#                     2. 函数Link增加参数chassisIp，保持各个测试仪器类的参数统一
#                     3. 继承基类CTestInstrument
###########################################################################################################################

package require Itcl

package require cmdline
package require registry

#package require Smartbits
#package require IxTclOrigin 1.0

#引入基类
#package require TestInstrument 1.0

package provide Ixia 1.0

::itcl::class CTestInstrument {
	constructor { ip Lablename args } {
	}
}
	
::itcl::class CIxiaNet {
	public variable _tcl_server "localhost/8009"
    public variable _host "0.0.0.0"
    public variable _user ixUser
    public variable _portList ""
    public variable _portHandleList ""
    public variable _port ""

    #IXIA过程返回变量                                                         
    public common  gIxia_OK      1
    public common  gIxia_ERR     0
    public common  gInvalidCode  0xffffffff                                   

	#IXIA过程返回变量，代表端口模式
	public common  gIxia_COPPER 0                                             
    public common  gIxia_FIBER 1 

    #继承父类 
    inherit CTestInstrument
    #构造函数
    #constructor {ip args}
    constructor {ip {Lablename user} args} { CTestInstrument::constructor $ip $Lablename $args } {
        set _host $ip
        set user ""
        get_params $args
        if {$user != ""} {
            set _user $user
        }
		Login
        Link
    }

    #析构函数
    destructor {
        foreach po $_port {
            Log "Delete object $po ..."
            catch {::itcl::delete object $po}
        }
        Release $_portList
        UnLink
    }
    
    public method Link { args }
    public method UnLink { args }
    public method ReLink { args }
    public method GetPort { args }
    public method Release { args }
    public method Reserve { args }
    
    private method get_params { args }
    
    
    #处理并记录error错误
    method error {Str} {
		puts "Error - Log: $Str"
	    #CTestException::Error $Str -origin Ixia
    } 
    
    #输出调试信息
    method Log {Str { Level info } }  {
		puts "$Level - Log: $Str"
	    #CTestLog::Log $Level $Str origin Ixia
    }
}

###########################################################################################
#@@Proc
#Name: ::CIxiaNet::Link
#Desc: Link to chassis
#Args: N/A
#Ret:  1 - OK
#      0 - connect failed
###########################################################################################
::itcl::body CIxiaNet::Link {} {    
	set rt $::CIxiaNet::gIxia_OK
	Log "Link to chassis $_host"
 
	if { [ catch {
		set root [ixNet getRoot]
		if { [ llength [ixNet getList $root/availableHardware chassis] ] == 0 } {
			set chas [ixNet add $root/availableHardware chassis]
			ixNet setA $chas -hostname $_host
			ixNet commit
			ixNet exec connectToChassis $_host
		}
	} err ] } {
		Log "Failed to Link chassis $_host: $err"
		set rt $::CIxiaNet::gIxia_ERR
	}
	return $rt
}

###########################################################################################
#@@Proc
#Name: ::CIxiaNet::UnLink
#Desc: Disconnect from chassis, and release all ports
#Args: N/A
#Ret:  1 - OK
#      0 - disconnect from chassis failed
###########################################################################################
::itcl::body CIxiaNet::UnLink {} {
    Log "Disconnect from chassis $_host ..."
    
	set rt $::CIxiaNet::gIxia_OK
	if { [ catch {
        ixNet exec releaseAllPorts
        } err ] } {
		Log "Unable to disconnect from chassis !"
		set rt $::CIxiaNet::gIxia_ERR
	}
    
	return $rt
}

###########################################################################################
#@@Proc
#Name: ::CIxiaNet::ReLink
#Desc: relink to chassis
#Args: N/A
#Ret:  1 - OK
#      0 - failed
###########################################################################################
::itcl::body CIxiaNet::ReLink {} {
    Log "ReLink chassis $_host ..."
    set rt [UnLink]
    set rt [Link]
    return $rt
}
    
    
###########################################################################################
#@@Proc
#Name: ::CIxiaNet::GetPort
#Desc: Constructor a port object
#Args: 
#	port - The format is: chassis/slot/port/media - 1.1.1.1/1/1/c
#   obj_name - Port object name which will be created
#Ret:  1 - OK
#      0 - failed
###########################################################################################
::itcl::body CIxiaNet::GetPort {port objName} {
    Log "Constructor port: $port with name: $objName"
    
	set retVal $::CIxiaNet::gIxia_OK
	#删除端口类型
	regexp {(\d.*)} $port total match
	set ixia_port_cfg [split $match "/"]
	set ixia_port [lrange $ixia_port_cfg 0 2]
	set ixia_media [lindex $ixia_port_cfg 3]
    set port [list $ixia_port_cfg]

    #CIxiaNetPortETH ::$objName $port
    if {[catch {
        CIxiaNetPortETH ::$objName $this $port $objName
        set objName [ GetObject $objName ]
        lappend _port $objName
        lappend _portList $ixia_port
        lappend _portHandleList [ $objName cget -handle ]
    } err]} {
		Log "Failed to GetPort: $err"
        set retVal $::CIxiaNet::gIxia_ERR
    }

	return $retVal
}


###########################################################################################
#@@Proc
#Name: ::CIxiaNet::Reserve
#Desc: Take owner ship
#Args: port list
#Ret:  1 - OK
#      0 - Fail
###########################################################################################
::itcl::body CIxiaNet::Reserve {portList } {
    Log "Take OwnerShip of $portList..."
    
    set retVal $::CIxiaNet::gIxia_OK
    foreach port $_portList {
        set index [lsearch $_portList $port]
        if { $index >= 0 } {
            set handle [lindex $_portHandleList $index]
            if { [catch {
                if { ![ixNet getA $handle -isConnected] } {
                    ixNet exec connectPort $handle 
                }
            } err]} {
                Log "Failed to Reserve port: $port - $err"
                set retVal $::CIxiaNet::gIxia_ERR
            }
        }
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: ::CIxiaNet::Release
#Desc: Clear owner ship
#Args: port list
#Ret:  1 - OK
#      0 - Fail
###########################################################################################
::itcl::body CIxiaNet::Release {portList} {
    Log "Clear OwnerShip of $portList..."
    
    set retVal $::CIxiaNet::gIxia_OK
    foreach port $_portList {
        set index [lsearch $_portList $port]
        if { $index >= 0 } {
            set handle [lindex $_portHandleList $index]
            if { [catch {
                if { [ixNet getA $handle -isConnected] } {
                    ixNet exec releasePort $handle 
                }
            } err]} {
                Log "Failed to Release port: $port - $err"
                set retVal $::CIxiaNet::gIxia_ERR
            }
        }
    }
    
    return $retVal
}

###########################################################################################
#@@Proc
#Name: get_params
#Desc: get params from args
#Args: form as -x 1 -y 2
###########################################################################################
::itcl::body CIxiaNet::get_params {args} {
        set argList ""
        set args [string tolower [lindex $args 0]]
        set tmp [split $args \-]
        set tmp_len [llength $tmp]
        for {set i 0 } {$i < $tmp_len} {incr i} {
            set tmp_list [lindex $tmp $i]
            if {[llength $tmp_list] == 2} {
                upvar [lindex $tmp_list 0] [lindex $tmp_list 0]
                append argList " [lindex $tmp_list 0].arg"
            }
        }
        set result [cmdline::getopt args $argList opt val]
        while {$result > 0} {
                set $opt $val
                set result [cmdline::getopt args $argList opt val]
        }
        if {$result < 0} {
                error "Invaild value:$args"
        }
}