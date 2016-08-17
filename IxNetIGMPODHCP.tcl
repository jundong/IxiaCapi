namespace eval IxiaCapi {
    
    class IGMPODHCPClient {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
		public variable dhcpObjName
        public variable className
		public variable groupName
        constructor { Port  } {
            set tag "body IGMPODHCPClient::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className IgmpHost
			DhcpHost ${this}_dhcp_c  $Port
			set groupName ""
						   
			set intfhandle [ ${this}_dhcp_c cget -handle]
			puts $intfhandle
Deputs "-----intfhandle: $intfhandle -----"
			IgmpHost ${this}_c  $Port $intfhandle "DHCP"
			
            
            
            set objName ${this}_c 
			set dhcpObjName ${this}_dhcp_c
			set argslist(-emulationmode)                  -ia_type         
            set argslist(-t1timer)                        -t1_timer
            set argslist(-t2timer)                        -t2_timer           
            set argslist(-duidtype)                       -duid_type
            set argslist(-duidenterpricenum)              -duid_enterprise
            set argslist(-duidstartvalue)                 -duid_start
            set argslist(-duidstepvalue)                  -duid_step       
            set argslist(-enablerelayagent)               -enable_relay_agent
            set argslist(-relayagentserverip)             -relay_server_ipv4_addr
            set argslist(-relayagentserveripstep)         -relay_server_ipv4_addr_step
			
            set argslist(-count)                           -count			            
            set argslist(-active)                          -enabled
			set argslist(-localmac)                        -mac_addr
			set argslist(-localmacmodifier)                -mac_addr_step
			set argslist(-vlanid1)                         -vlan_id
			set argslist(-vlanid2)                         -vlan_id2
			set argslist(-qinqlist)                        -qinqlist
			set argslist(-vlanpriority1)                   -outer_vlan_priority
            
            
            set argslist(-protocoltype)                  -version
            set argslist(-sendgrouprate)                -rate
            set argslist(-v1routerpresenttimeout)       -v1_router_present_timeout
            set argslist(-forcerobustjoin)              -force_robust_join
            set argslist(-unsolicitedreportinterval)    -unsolicited_report_interval
            set argslist(-insertchecksumerrors)         -insert_checksum_errors 
            set argslist(-insertlengtherrors)           -insert_length_errors
            set argslist(-ipv4dontfragment)             -ipv4_dont_fragment
            
            set argslist(-grouppoolname)                    -group_name
            set argslist(-groupcnt)                         -group_num  
            set argslist(-srcstartip)                       -source_ip
            set argslist(-filtermode)                       -filter_mode
            set argslist(-startip)                          -group_ip
			set argslist(-groupincrement)                   -group_step
            set argslist(-srcincrement)                     -source_step			
            
        }
        
        method ConfigRouter { args } {
            set tag "body IGMPODHCPClient::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
			eval $dhcpObjName config $newargs
            eval $objName config $newargs
            #eval $objName join_group $newargs
        
        }
        
        method Enable {} {
            set tag "body IGMPODHCPClient::Enable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start
			after 1000
            
        }
        method Disable {} {
            set tag "body IGMPODHCPClient::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
        
        method IgmpCreateGroupPool { args } {
            set tag "body IGMPODHCPClient::IgmpCreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        
        method ConfigGroupPool { args } {
            set tag "body IGMPODHCPClient::ConfigGroupPool [info script]"
Deputs "----- TAG: $tag -----"
           eval ProtocolConvertObject::convert $args
           foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoolname {
                        set gName $value
                    }
                }
            }
			if { [GetObject $gName ] == "" } {
			
				uplevel #0 "MulticastGroup $gName" 
				lappend groupName $gName
			}
			eval $gName config $newargs
			
			#eval $objName join_group -group $gName 

            
        }
		
		method DeleteGroupPool { args } {
            set tag "body IGMPODHCPClient::DeleteGroupPool [info script]"
Deputs "----- TAG: $tag -----"
			foreach { key value } $args {
				set key [string tolower $key]
				switch -exact -- $key {
					-grouppoollist {
						set grouppoolname $value
					}
				}
			}
			
			foreach poolname $grouppoolname {
			    set index [lsearch $groupName $poolname]
				if { $index >= 0} {
				   lreplace $groupName $index $index
				}
 			}
           
        }
        
        method IgmpSendReport { args } {
            set tag "body IGMPODHCPClient::IgmpSendReport [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }
			

            if {[ info exists grouppoolname ]} {
                #eval $objName join_group  -group $grouppoolname
				$objName join_group  -group $grouppoolname
			} else {
			    eval $objName join_group
			}
        }
        method IgmpSendLeave { args} {
            set tag "body IGMPODHCPClient::IgmpSendLeave [info script]"
Deputs "----- TAG: $tag -----"
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }

            if {[ info exists grouppoolname ]} {
                #eval $objName leave_group -group $grouppoolname
				$objName leave_group -group $grouppoolname
			} else {
			    eval $objName leave_group
			}
        }
		
		method DhcpBind {} {
            set tag "body IGMPODHCPClient::DhcpBind [info script]"
Deputs "----- TAG: $tag -----"
            eval $dhcpObjName request
			after 1000
        }
       
        method GetRouterStats {} {
            set tag "body IGMPODHCPClient::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body IGMPODHCPClient::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
		method DhcpGetHostState { args } {
            set tag "body DHCPv6Client::GetHostState [info script]"
Deputs "----- TAG: $tag -----"
            eval $dhcpObjName get_per_session $args
        }
        destructor {}
        
      
    }
    
   
}