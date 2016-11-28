lappend auto_path {C:\Ixia\Workspace\IxiaCapi}
package require IxiaCAPI
set chassis 172.16.174.134
#set password 603546
CIxiaNet ixia $chassis h3c
ixia Link
ixia UnLink
ixia ReLink

set portObjName h3cPort
ixia GetPort $chassis/1/1/NULL $portObjName
ixia Release [list $chassis 1 1]
ixia Reserve [list $chassis 1 1]




lappend auto_path {C:\Ixia\Workspace\IxiaCapi}
package require IxiaCAPI
IxDebugOn
set chassis 172.16.174.134
CIxiaNet ixia $chassis h3c
ixia Link
set portObjName h3cPort
set portEthObj $portObjName
ixia GetPort $chassis/1/1/NULL $portObjName
#CIxiaNetPortETH method verify
#$portEthObj Reset
#$portEthObj Run
#$portEthObj Stop
#$portEthObj SetTrig 10 "10 11 12 13" "&&" 20 "20 21 22 23"
#$portEthObj SetPortSpeedDuplex 1 100 full
#$portEthObj SetCustomPkt {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
#$portEthObj SetTxSpeed 88 Uti
#$portEthObj SetTxMode 3 111 222 333 444
$portEthObj CreateCustomStream -FrameLen 111 -Utilization 33 -TxMode 1 -BurstCount 112 -ProHeader {ff ff ff ff ff ff 00 00 00 00 00 01 08 00 45 00}
$portEthObj Stop

package require IxiaNet
Login
::itcl::delete class Port
::itcl::delete class Host 
source {D:\ixia-IxN-H3C\lib\Ixia_NetPort.tcl}
Port port1 NULL NULL ::ixNet::OBJ-/vport:1
port1 config -auto_neg 1 -duplex full -speed 100M




