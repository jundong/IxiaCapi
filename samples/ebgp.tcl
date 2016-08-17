lappend auto_path {C:\Ixia\Workspace\IxiaCapi}
package req IxiaCAPI
IxDebugOn
TestDevice device1 
device1 Connect -ipaddr 172.16.174.134
device1 CreateTestPort -loc {1/1} -name port1 -type ETH
device1 CreateTestPort -loc {3/1} -name port2 -type ETH
set port1 ::IxiaCapi::TestDevice::port1
set port2 ::IxiaCapi::TestDevice::port2
$port2 CreateHost \
 -HostName hostname2 -Ipv6Addr 2002:db8:0101:0100::1 -Ipv6Mask 64 -Ipv6SutAddr 2002:db8:0101:0100::2 -MacAddr 00:20:15:01:10:02 -FlagPing enable
$port1 CreateSubInt -SubIntName port1Vlan1
    port1Vlan1 ConfigPort -VlanId 66
    port1Vlan1 CreateAccessHost -HostName port1Host -Ipv4Addr 66.0.0.2  \
        -Ipv4Mask 24 -Ipv4SutAddr 66.0.0.1 \
        -MacAddr 00-00-00-00-00-66 -FlagPing enable
#EBGP
$port1 CreateAccessHost -HostName hostname1 -Ipv4Addr 88.0.0.2 -Ipv4Mask 24 -Ipv4SutAddr 88.0.0.1 -MacAddr 00-00-00-00-00-88 -FlagPing enable
$port1 CreateRouter -RouterName bgpRouter1 -RouterType BgpV4Router -routerid 88.0.0.2
bgpRouter1 ConfigRouter -PeerType EBGP -TesterIp 88.0.0.2 -PrefixLen 24  -TesterAS 89  -SutIp 88.0.0.1 -SutAs 88
bgpRouter1 CreateRouteBlock -BlockName block1 -AddressFamily ipv4 -FirstRoute 55.0.0.0 -PrefixLen 24 \
        -RouteNum 10 -Modifier 1 \
        -ORIGIN EGP -NEXTHOP 88.0.0.2 -Active enable -MED 1 \
        -AS_PATH {{2 89}}


#IBGP
$port2 CreateRouter -RouterName bgpRouter2 -RouterType BgpV4Router -routerid 88.0.0.2
 bgpRouter2 ConfigRouter -PeerType IBGP -TesterIp 88.0.0.2 -PrefixLen 24 \
        -TesterAS 88  -SutIp 88.0.0.1 -SutAs 88 -HoldTimer 90 -KeepaliveTimer 30
bgpRouter2 CreateRouteBlock -BlockName block2 -AddressFamily ipv4 -FirstRoute 55.0.0.0 -PrefixLen 24 \
        -RouteNum 10 -Modifier 1 \
        -ORIGIN igp -NEXTHOP 88.0.0.2 -Active enable -MED 1

bgpRouter2 CreateRouteBlock -BlockName block3 -AddressFamily ipv4 \
        -FirstRoute {10.12.52.1 10.13.24.5 20.1.1.3} \
        -PrefixLen 24 -Active enable \
        -ORIGIN 1 -NEXTHOP 66.0.0.2 -MED 1  -ORIGINATOR_ID 192.85.3.1 \
        -CLUSTER_LIST 192.86.1.1 -COMMUNITIES 1:1 -LabelMode FIXED






#stream check
package req IxiaCAPI
IxDebugOn
set ::gOffline 0
TestDevice device1 
device1 Connect -ipaddr 192.168.200.180
device1 CreateTestPort -loc {1/7} -name port1 -type ETH
device1 CreateTestPort -loc {1/8} -name port2 -type ETH

set port1 ::IxiaCapi::TestDevice::port1
set port2 ::IxiaCapi::TestDevice::port2


set frameLen 1000
set dstMac1 "00:03:03:03:00:03"
set dstMac2 "00:03:03:03:00:04"
set dstMac3 "00:03:03:03:00:05"
set srcMac "00:03:03:03:00:01"
set port1Ip "2000::1"
set port2Ip "2002:db8:0101:0100::1"

$port1 CreateTraffic -TrafficName p1Traf1 
p1Traf1 CreateProfile -Name profile1 -Type Constant -TrafficLoad 90 -TrafficLoadUnit percent 
p1Traf1 CreateStream -StreamName p1Str1 -ProfileName profile1  \
               -framelen       $frameLen  \
               -EthDst         $dstMac1 \
               -EthSrc         $srcMac \
                -L2             Ethernet \
        -L3             IPv4 \
        -IpSrcAddr      $port1Ip \
        -IpDstAddr      $port2Ip  \
        -IpProtocol     4   \
        -qosmode "dscp"  \
       -qosvalue  63

$port1 DestroyTraffic
$port1 CreateTraffic -TrafficName port1Traffic
port1Traffic CreateProfile -Name profile1 -Type Constant -TrafficLoad 90 -TrafficLoadUnit percent
set frameLen 256
set dut1Mac "00:d0:d0:c0:10:42"
set port1Mac "00:20:10:01:10:01"
set port1Ip "2000::1"
set port2Ip "2002:db8:0101:0100::1"
set port1Mask 64
set port2Mask 64

port1Traffic CreateStream -StreamName port1Stream1 -ProfileName profile1 \
        -framelen       $frameLen \
        -EthDst         $dut1Mac \
        -EthSrc         $port1Mac \
        -L2             Ethernet \
        -L3             IPv6 \
        -Ipv6SrcAddr      $port1Ip \
        -Ipv6SrcMask      $port1Mask \
        -Ipv6DstAddr      $port2Ip \
        -Ipv6DstMask      $port2Mask
set port1Ip 192.168.3.22
set port2Ip 192.168.7.33
port1Traffic CreateStream -StreamName port1Stream2 -ProfileName profile1 \
        -framelen       $frameLen \
        -EthDst         $dut1Mac \
        -EthSrc         $port1Mac \
        -L2             Ethernet \
        -L3             IPv4 \
        -IpSrcAddr      $port1Ip \
        -IpDstAddr      $port2Ip 


 p1Traf1 CreateStream -StreamName p1Str2 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac2 \
               -EthSrc         $srcMac 

  p1Traf1 CreateStream -StreamName p1Str3 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac3 \
               -EthSrc         $srcMac 
 $port1 CreateStaEngine -StaEngineName port1Stat -StaType Statistics 
$port20 CreateStaEngine -StaEngineName port20Stat -StaType Statistics 
 $port30 CreateStaEngine -StaEngineName port30Stat -StaType Statistics         
 $port1 StartTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 
        after 30000 
  $port1 StopTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 
    set port1Tx 0 
        set port20Rx 0 
        set port30Rx 0 
        port1Stat GetPortStats -TxFrames port1Tx
port1Stat GetStreamStats -StreamName p1Str1  -RxFrames rxframes2
port1Stat GetStreamStats -StreamName p1Str1  -TxFrames txframes2
        port20Stat GetPortStats -RxSignature port20Rx
        port30Stat GetPortStats -RxSignature port30Rx
        
        ############################################################## 
           p1Traf1 DestroyStream
        after 3000 
    p1Traf1 CreateStream -StreamName p1Str1 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac1 \
               -EthSrc         $srcMac 
        after 60000000 
        p1Traf1 CreateStream -StreamName p1Str2 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac2 \
               -EthSrc         $srcMac 
        p1Traf1 CreateStream -StreamName p1Str3 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac3 \
               -EthSrc         $srcMac 

        $port1 StartTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 
        after 30000 
        $port1 StopTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 

    set port1Tx 0 
        set port20Rx 0 
        set port30Rx 0 
        port1Stat GetPortStats -TxFrames port1Tx
        port20Stat GetPortStats -RxSignature port20Rx
        port30Stat GetPortStats -RxSignature port30Rx
        puts "发送情况：\ 
                    端口1发送帧统计值port1Tx: $port1Tx \ 
                    端口2接收标记帧统浦祊ort20Rx: $port20Rx \ 
                                端口3接收标记帧统计值port30Rx: $port30Rx"

set vid 100
p1Traf1 DestroyStream 
        after 3000 
 p1Traf1 CreateStream -StreamName p1Str1 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac1 \
               -EthSrc         $srcMac  \
                           -Vlanid         $vid 
        p1Traf1 CreateStream -StreamName p1Str2 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac2 \
               -EthSrc         $srcMac  \
                           -Vlanid         $vid 
        p1Traf1 CreateStream -StreamName p1Str3 -ProfileName profile1 \
               -framelen       $frameLen \
                           -EthDst         $dstMac3 \
               -EthSrc         $srcMac  \
                           -Vlanid         $vid 
        MZtePut -c "仪表端口$port1发送数据流，发送时间为30秒" 
        $port1 StartTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 
        after 30000 
        $port1 StopTraffic -StreamNameList  {p1Str1 p1Str2 p1Str3} 
        MZtePut -c "获取数据流统计结果，并进行结果判断" 
    set port1Tx 0 
        set port20Rx 0 
        set port30Rx 0 
        port1Stat GetPortStats -TxFrames port1Tx
        port20Stat GetPortStats -RxSignature port20Rx
        port30Stat GetPortStats -RxSignature port30Rx

port1Traffic CreateStream -StreamName port1Stream3 -ProfileName profile1 \
    -framelen       256 \
    -EthDst         00:00:00:00:00:01 \
    -EthSrc         00:00:00:00:00:10 \
    -L2   Ethernet_Vlan_Mpls     \
    -VlanId 1982 \
    -VlanUserPriority 2 \
    -MplsBottomOfStack 1 \
    -Mplslabel 100 \
    -Mplsexp 0 \
    -Mplsttl 255 \
    -L3 IPv4 \
    -IpSrcAddr 8.8.8.81 \
    -IpSrcMask 255.255.255.0 \
    -IpSrcAddrMode decrement \
    -IpSrcAddrCount 20  \
    -IpSrcAddrStep 0.0.0.1 \
    -IpDstAddr 10.10.10.10 \
    -IpDstMask 255.255.255.0 \
    -IpDstAddrMode increment \
    -IpDstAddrCount 30  \
    -IpDstAddrStep 0.0.1.0 
port1Traffic CreateStream -StreamName port1Stream4 -ProfileName profile1 \
    -framelen       128 \
    -EthDst         00:00:00:00:00:05 \
    -EthSrc         00:00:00:00:00:50 \
    -L2   Ethernet_Vlan     \
    -VlanId 1982 \
    -VlanUserPriority 2 \
    -L3   IPv6 \
    -Ipv6SrcAddress 2000::4 \
    -Ipv6SrcAddressMode increment \
    -Ipv6SrcAddressCount 100 \
    -Ipv6SrcAddressStep ::2 \
    -Ipv6DstAddress 2000::3 \
    -Ipv6DstAddressMode decrement \
    -Ipv6DstAddressCount 100 \
    -Ipv6DstAddressStep ::4





after 3000
::IxiaCapi::TestDevice::port1 CreateAccessHost -HostName hostname2 -HostNum 5  -Ipv4Addr 90.1.1.2 -Ipv4Mask 24 -Ipv4SutAddr 90.1.1.1 -MacAddr 00-00-00-00-00-01 -FlagPing enable -UpperLayer "ipv4"
port1 CreateTraffic -TrafficName port1traffic
port1traffic CreateProfile -Name profile1 -Type Constant -TrafficLoad 10 -TrafficLoadUnit percent
port1traffic CreateStream -StreamName port1Stream1 -ProfileName profile1 -framelen 128 -EthDst 00:01:01:01:00:01 -EthSrc 00:00:00:00:00:01 -L2 Ethernet -L3 IPv4 -IpSrcAddr 90.1.1.2 -IpDstAddr 90.1.1.1

#pppoe test case
IxDebugOn
set ::gOffline 0
TestDevice device1 
device1 Connect -ipaddr 192.168.1.212
device1 CreateTestPort -loc {2/3} -name port1 -type ETH
device1 CreateTestPort -loc {2/4} -name port2 -type ETH
::IxiaCapi::TestDevice::port2 CreateSubInt -SubIntName vlanInt2        
vlanInt2 ConfigPort -VlanId 150
vlanInt2 CreateAccessHost -HostName Host2 -UpperLayer IPv6 -Ipv6Addr 2014::1 -Ipv6Mask 64   
vlanInt2 CreateRouter  -RouterName pppoev6client1 -RouterType PPPoEv6Client -HostName Host2
pppoev6client1 ConfigRouter -FlagStartOnAble True -Username


IxDebugOn
set ::gOffline 0
TestDevice device1 
device1 Connect -ipaddr 192.168.1.212
device1 CreateTestPort -loc {2/7} -name port1 -type ETH
device1 CreateTestPort -loc {2/8} -name port2 -type ETH
::IxiaCapi::TestDevice::port1 CreateAccessHost -HostName Host2 -UpperLayer IPv6 -Ipv6Addr 2014::1 -Ipv6Mask 64   -MacAddr 00-00-00-00-00-01  
::IxiaCapi::TestDevice::port2 CreateAccessHost -HostName Host3 -UpperLayer IPv4 -Ipv4Addr 192.168.10.22 -MacAddr 00-00-00-00-00-01
::IxiaCapi::TestDevice::port2 CreateRouter  -RouterName pppoev4client1 -RouterType PPPoEv4Client -HostName Host3
::IxiaCapi::TestDevice::port1 CreateRouter  -RouterName pppoev6client1 -RouterType PPPoEv6Client -HostName Host2
pppoev6client1 ConfigRouter -FlagStartOnAble True -Username

::IxiaCapi::TestDevice::port1 CreateAccessHost -HostName Host3 -UpperLayer IPv6 -Ipv6Addr 2013::1 -Ipv6Mask 64
::IxiaCapi::TestDevice::port1 CreateRouter  -RouterName Router1 -RouterType IPv6SLAAC -HostName Host3

Router1 ConfigRouter -DuplicateAddrDetection false -DADTransmitCount 11 \
    -DADRetransmitDelay 1111 -RouterSolicitationRetries 12 -RouterSolicitationRetransmitDelay 1112 \
    -Active enable

$port1 CreateAccessHost -HostName Host1 -UpperLayer ipv6  -Ipv6Addr 2000::2 -Ipv6Mask 64 -Ipv6SutAddr 2000::1   -Ipv6LinkLocalAddr fe80::2 -MacAddr 00:00:01:00:00:02

$port1 CreateRouter -RouterName rtr2 -RouterType Dhcpv6Client -HostName Host1
                rtr2 ConfigRouter -ClientLocalMac 00:00:01:00:00:02 -VlanId1 10 -Count 20
                rtr2 Enable
