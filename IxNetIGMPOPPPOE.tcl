namespace eval IxiaCapi {
    
    class IGMPOPPPOEClient {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
		public variable pppoeObjName
        public variable className
		public variable groupName
        constructor { Port  } {
            set tag "body IGMPOPPPOEClient::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className IgmpHost
			PppoeHost ${this}_pppoe_c  $Port
			set groupName ""
						   
			set intfhandle [ ${this}_pppoe_c cget -handle]
			puts $intfhandle
Deputs "-----intfhandle: $intfhandle -----"
			IgmpHost ${this}_c  $Port $intfhandle "PPP"
			
            
            
            set objName ${this}_c 
			set pppoeObjName ${this}_pppoe_c
            set argslist(-count)                           -count			
            set argslist(-active)                          -enabled
            set argslist(-authenticationrole)              -authentication
            set argslist(-username)                        -user_name
            set argslist(-password)                        -password
            set argslist(-authenusername)                  -user_name
            set argslist(-authenpassword)                  -password
            set argslist(-flagenableipcp)                  -ipcp_encap
            
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
            set tag "body IGMPOPPPOEClient::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
			eval $pppoeObjName config $newargs
            eval $objName config $newargs
            #eval $objName join_group $newargs
        
        }
        
        method Enable {} {
            set tag "body IGMPOPPPOEClient::Enable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName start
            
        }
        method Disable {} {
            set tag "body IGMPOPPPOEClient::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName stop
        }
		method PPPoEOpen {} {
            set tag "body IGMPOPPPOEClient::PPPoEOpen [info script]"
Deputs "----- TAG: $tag -----"
             eval $pppoeObjName connect
			after 3000
        }
		method PPPoEClose {} {
            set tag "body IGMPOPPPOEClient::PPPoEClose [info script]"
Deputs "----- TAG: $tag -----"
            eval $pppoeObjName disconnect
			after 3000
        }
		method PPPoEAbort {} {
            set tag "body IGMPOPPPOEClient::PPPoEAbort [info script]"
Deputs "----- TAG: $tag -----"
            eval $pppoeObjName abort
			after 3000
        }
		method PPPoERetryFailedPeer {} {
            set tag "body IGMPOPPPOEClient::PPPoERetryFailedPeer [info script]"
Deputs "----- TAG: $tag -----"
            eval $pppoeObjName retry
			after 3000
        }
		method PPPoEGetHostState { args } {
            set tag "body IGMPOPPPOEClient::PPPoEGetHostState [info script]"
Deputs "----- TAG: $tag -----"
            eval $pppoeObjName get_per_session $args
			after 3000
        }
        
        method IgmpCreateGroupPool { args } {
            set tag "body IGMPOPPPOEClient::IgmpCreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        
        method ConfigGroupPool { args } {
            set tag "body IGMPOPPPOEClient::ConfigGroupPool [info script]"
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
            set tag "body IGMPOPPPOEClient::DeleteGroupPool [info script]"
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
            set tag "body IGMPOPPPOEClient::IgmpSendReport [info script]"
Deputs "----- TAG: $tag -----"
Deputs "args: $args"
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }
			
            Deputs "gouppoolname:$grouppoolname"
            if {[ info exists grouppoolname ]} {
                #eval $objName join_group -group $grouppoolname
				$objName join_group -group $grouppoolname
			} else {
			    eval $objName join_group
			}
        }
        method IgmpSendLeave { args} {
            set tag "body IGMPOPPPOEClient::IgmpSendLeave [info script]"
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
       
        method GetRouterStats {} {
            set tag "body IGMPOPPPOEClient::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_detailed_stats
        }
        method GetHostResults {} {
            set tag "body IGMPOPPPOEClient::GetHostResults [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
        destructor {}
        
      
    }
    
   
}