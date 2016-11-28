lappend auto_path {C:\Ixia\Workspace\IxiaCapi}
package require IxiaCAPI
Login
IxDebugOn
#Port @tester_to_dta1 172.16.174.134/1/1
#Port @tester_to_dta2 172.16.174.134/2/1

Port @tester_to_dta1 NULL NULL ::ixNet::OBJ-/vport:1
Port @tester_to_dta2 NULL NULL ::ixNet::OBJ-/vport:2
#Port @tester_to_dta3 NULL NULL ::ixNet::OBJ-/vport:3
#Port @tester_to_dta4 NULL NULL ::ixNet::OBJ-/vport:4

#@tester_to_dta1 config -dut_ip "30.30.30.1" -intf_ip "30.30.30.2"
#@tester_to_dta2 config -dut_ip "30.30.30.2" -intf_ip "30.30.30.1"
                         
Traffic @tester_to_dta1.traffic(1) @tester_to_dta1 NULL true
Ipv4Hdr @tester.pdu.ipv4(1)
@tester.pdu.ipv4(1) config @tester.pdu.ipv4(1) config -src "25.1.1.1" -dst "26.1.1.1"
  
VlanHdr @tester.pdu.vlan(1)
@tester.pdu.vlan(1) config -pri1 "1" -id1 "200"

EtherHdr @tester.pdu.eth(1)
@tester.pdu.eth(1) config -src "00:00:00:03:02:01" -dst "00:00:01:00:00:01"

#-pdu "@tester.pdu.eth(1) @tester.pdu.vlan(1) @tester.pdu.ipv4(1)"
@tester_to_dta1.traffic(1) config -pdu "@tester.pdu.eth(1) @tester.pdu.vlan(1) @tester.pdu.ipv4(1)"

@tester.pdu.ipv4(1) config @tester.pdu.ipv4(1) config -src "1.1.1.1" -dst "11.1.1.1" -modify 1
@tester_to_dta1.traffic(1) config -pdu "@tester.pdu.ipv4(1)"

@tester.pdu.eth(1) config -src "aa:bb:00:03:02:01" -dst "ee:ff:01:00:00:01" -modify 1
@tester_to_dta1.traffic(1) config -pdu "@tester.pdu.eth(1)"

@tester.pdu.vlan(1) config -pri1 "1" -id1 "440" -modify 1
@tester_to_dta1.traffic(1) config -pdu "@tester.pdu.vlan(1)"