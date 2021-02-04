#!/bin/bash 

 str2str -in ntrip://@caster.centipede.fr:2101/LIENSS -out tcpsvr://localhost:2102 &>/dev/null &   # get RTCM stream 
#  curl -sS --max-time 21 http://localhost:2102 | gpsdecode -j |  jq --seq -s -r .[] >RTCM3 &&         # capture and decode
  curl -sS --max-time 21 http://localhost:2102 | gpsdecode -j |  jq -R 'fromjson?' >RTCM3 &&  #resolve problem with bad json format but not display all values...


    TYPE=STR
    #mountpoint
    #IDENTIFIER= #commune ou $MP
    FORMAT=$(jq -s -r '[(.[] |.class)] | unique | @csv' < RTCM3)  #get classe (RTCM3,....)
    FORMATD=$(jq -s -r '[(.[] |.type)] | unique | @csv' < RTCM3)  #get list of 
    CARRIER=1 #$(jq -s -r '[(.[] |.type)] | unique' < RTCM3 | jq -r 'if .[] == 1002 then 1 elif .[] == 1004 then 2 else empty end') #get L1, L1-L2, dgps

    GPS_MES="contains([1001]) or contains([1002]) or contains([1003]) or contains([1004]) or contains([1071]) or contains([1072]) or contains([1073]) or contains([1074]) or contains([1075]) or contains([1076]) or contains([1077])"
    GLO_MES="contains([1009]) or contains([1010]) or contains([1011]) or contains([1012]) or contains([1081]) or contains([1082]) or contains([1083]) or contains([1084]) or contains([1085]) or contains([1086]) or contains([1087])"
    GAL_MES="contains([1091]) or contains([1092]) or contains([1093]) or contains([1094]) or contains([1095]) or contains([1096]) or contains([1097])"
    SBS_MES="contains([1101]) or contains([1102]) or contains([1103]) or contains([1104]) or contains([1105]) or contains([1106]) or contains([1107])"
    QZS_MES="contains([1111]) or contains([1112]) or contains([1113]) or contains([1114]) or contains([1115]) or contains([1116]) or contains([1117])"
    BDS_MES="contains([1121]) or contains([1122]) or contains([1123]) or contains([1124]) or contains([1125]) or contains([1126]) or contains([1127])"

    GPS=$(jq -s -r '[(.[] |.type)] | unique | '"$GPS_MES"' | if . == true then "GPS" else empty end' < RTCM3)
    GLO=$(jq -s -r '[(.[] |.type)] | unique | '"$GLO_MES"' | if . == true then "GLO+" else empty end' < RTCM3)
    GAL=$(jq -s -r '[(.[] |.type)] | unique | '"$GAL_MES"' | if . == true then "GAL+" else empty end' < RTCM3)
    SBS=$(jq -s -r '[(.[] |.type)] | unique | '"$SBS_MES"' | if . == true then "SBS+" else empty end' < RTCM3)
    QZS=$(jq -s -r '[(.[] |.type)] | unique | '"$QZS_MES"' | if . == true then "QZS+" else empty end' < RTCM3)
    BDS=$(jq -s -r '[(.[] |.type)] | unique | '"$BDS_MES"' | if . == true then "BDS+" else empty end' < RTCM3)

    RECV=$(jq -r 'select(.type == 1230)' < RTCM3)

    NAVSYS="$GLO""$GAL""$SBS""$QZS""$BDS""$GPS" #display nav system
    NETW=EUREF
    COUNTRY=FRA
    ECEF=$(jq -r 'select(.type == 1006) | [.x,.y,.z] | @sh' < RTCM3) #get Lat long alt (ECEF)
    LAT=$(python ecef2lat.py $ECEF) # transfom lat ECEF > WGS84
    LON=$(python ecef2lon.py $ECEF) # transfom lat ECEF > WGS84
    ALT=$(python ecef2alt.py $ECEF) # transfom lat ECEF > WGS84
    NMEA=0
    SOLUT=0
    GENER=sNTRIP
    COMP=none
    AUTH=N
    FEE=N
    #https://docs.emlid.com/reach/common/reachview/base-mode/ GPS+GLO+GAL+BDS+SBS
    BIT=101
    MISC=CENTIPEDE
    echo "----------  "$i "UP"
    echo $TYPE";"$i";"$i";"$FORMAT";"$FORMATD";"$CARRIER";"$NAVSYS";"$NETW";"$COUNTRY";"$LAT";"$LON";"$ALT";"$NMEA";"$SOLUT";"$GENER";"$COMP";"$AUTH";"$FEE";"$BIT";"$MISC";"$RECV

kill -9 $(ps aux | grep -e str2str| awk '{ print $2 }') 
      echo "______________________________________________________________________"
