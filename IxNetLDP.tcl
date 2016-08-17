namespace eval IxiaCapi {
    
    class LdpRouter {
        inherit ProtocolConvertObject
        #public variable newargs
        #public variable argslist
        public variable objName
        public variable className
		public variable groupName
        constructor { Port { hostname null } } {
            set tag "body LdpRouter::ctor [info script]"
Deputs "----- TAG: $tag -----"
            set className LdpSession
			if { $hostname != "null" } {
			    set inttype [$hostname cget -topStack]
			    set intfhandle [ $hostname cget -topHandle]
				puts $intfhandle
Deputs "-----intfhandle: $intfhandle -----"
                LdpSession ${this}_c  $Port $intfhandle $inttype
			} else {
			    LdpSession ${this}_c  $Port 
			}
            
            
            set objName ${this}_c
            
            set argslist(-active)                         -active

            set argslist(-testerip)                -ipv4_addr
           
            set argslist(-prefixlen)       -ipv4_prefix_len
            set argslist(-sutip)              -ipv4_gw
            #set argslist(-submask)    -unsolicited_report_interval
            set argslist(-testerrouterid)         -router_id
            #set argslist(-insertlengtherrors)           -insert_length_errors
           
			#set argslist(-grouppoolname)                    -group_name
            #set argslist(-groupcnt)                         -group_num  
            #set argslist(-srcstartip)                       -source_ip
            #set argslist(-filtermode)                       -filter_mode
            #set argslist(-startip)                          -group_ip 
            			
        
        }
        
        method ConfigRouter { args } {
            set tag "body LdpRouter::ConfigRouter [info script]"
Deputs "----- TAG: $tag -----"
            eval ProtocolConvertObject::convert $args
            eval $objName config $newargs
        
        }
        
        method Enable {} {
            set tag "body LdpRouter::Enable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName config -active enabled
            
        }
        method Disable {} {
            set tag "body LdpRouter::Disable [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName config -active disabled
        }
        method CreateGroupPool { args } {
            set tag "body LdpRouter::CreateGroupPool [info script]"
Deputs "----- TAG: $tag -----"
            
            eval ConfigGroupPool $args
        }
        method ConfigGroupPool { args } {
            set tag "body LdpRouter::ConfigGroupPool [info script]"
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
				set groupName $gName
			}
            eval $gName config $newargs
			
			eval $objName join_group -group $groupName 
        }
        method DeleteGroupPool { args } {
            set tag "body LdpRouter::DeleteGroupPool [info script]"
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
        method SendReport { args } {
            foreach { key value } $args {
                set key [string tolower $key]
                switch -exact -- $key {
                    -grouppoollist {
                        set grouppoolname $value
                    }
                }
            }
			
            if {[ info exists grouppoolname ]} {
                eval $objName join_group $grouppoolname
			} else {
			    eval $objName join_group
			}
            
        }
        method SendLeave {} {
            set tag "body LdpRouter::SendLeave [info script]"
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
                eval $objName leave_group $grouppoolname
			} else {
			    eval $objName leave_group
			}

           
        }
        method ResendReport {} {
            set tag "body LdpRoutert::ResendReport [info script]"
Deputs "----- TAG: $tag -----"
            SendReport
        }
        method GetRouterStats {} {
            set tag "body LdpRouter::GetRouterStats [info script]"
Deputs "----- TAG: $tag -----"
            eval $objName get_host_stats
        }
        destructor {}
        
    
    }
}