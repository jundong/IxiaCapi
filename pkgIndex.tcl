#===================================================================================
# �汾�ţ�1.0
#   
# �ļ�����pkgIndex.tcl
# 
# �ļ��������������ļ�
# 
# ���ߣ��쿡��(Judo Xu)
#
# ����ʱ��: 2016.06.20
#
# �޸ļ�¼�� 
#   
# ��Ȩ���У�Ixia
#====================================================================================

if {$::tcl_platform(platform) != "unix"} {
    #���IxiaCapi���Ѿ����ع����򷵻�
    if {[lsearch [package names] IxiaCapi] != -1} {
        return
    }
} 
package ifneeded IxiaCAPI 3.7 [list source [file join $dir IxiaCapi.tcl]]

