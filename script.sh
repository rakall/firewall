#!/bin/bash
clish -c 'set static-route 172.16.1.0/25 nexthop gateway address 172.16.0.1 priority 1 on'
#clish -c 'set hostname fwcheckpoint'
#clish -c 'config_system --config-string mgmt_admin_name=admin&mgmt_admin_passwd=Password1234&hostname=fwautomatizado&ftw_sic_key=Password1234&install_security_gw=true&gateway_daip=false&install_ppak=true&gateway_cluster_member=false&install_security_managment=false'
#clish -c 'config_system --config-string hostname=fwautomatizado&mgmt_admin_name=admin&mgmt_admin_passwd=Password1234&install_security_gw=true&ftw_sic_key=1234'
clish -c'config_system --config-string upload_info=true&download_info=true&hostname=fwautomatico&ftw_sic_key=Password1234&install_security_managment=false&install_security_gw=true&gateway_daip=false&install_ppak=true&gateway_cluster_member=false'