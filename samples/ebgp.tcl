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