#!/usr/bin/env python3
import requests
import sys

TV_IP = "192.168.1.1"  # change it to your smartscreen ip
CONTROL_URL = f"http://{TV_IP}:49153/rcr_control" # change it to your smartscreen port
SERVICE_TYPE = "urn:schemas-upnp-org:service:RenderingControl:1"

def send_upnp_request(action, params_xml):
    soap_body = f"""<?xml version="1.0"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                  SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
 <SOAP-ENV:Body>
  <m:{action} xmlns:m="{SERVICE_TYPE}">
   <InstanceID>0</InstanceID>
   {params_xml}
  </m:{action}>
 </SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""

    headers = {
        "Content-Type": "text/xml; charset=\"utf-8\"",
        "SOAPACTION": f"\"{SERVICE_TYPE}#{action}\""
    }

    resp = requests.post(CONTROL_URL, headers=headers, data=soap_body)
    if resp.status_code == 200:
        print(f"{action} successful.")
    else:
        print(f"{action} failed with status code {resp.status_code}")
        print("Response:", resp.text)

def set_volume(volume_level):
    # volume_level: int from 0 to 100
    volume_xml = f"<Channel>Master</Channel><DesiredVolume>{volume_level}</DesiredVolume>"
    send_upnp_request("SetVolume", volume_xml)

def set_mute(mute_on):
    # mute_on: to mute
    mute_xml = f"<Channel>Master</Channel><DesiredMute>{mute_on}</DesiredMute>"
    send_upnp_request("SetMute", mute_xml)

def print_usage():
    print("Usage:")
    print("  python3 tv_volume.py up <0-100>    # رفع الصوت إلى القيمة المحددة")
    print("  python3 tv_volume.py down <0-100>  # خفض الصوت إلى القيمة المحددة")
    print("  python3 tv_volume.py mute           # كتم الصوت")
    print("  python3 tv_volume.py unmute         # فك كتم الصوت")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    cmd = sys.argv[1].lower()

    if cmd == "up":
        if len(sys.argv) != 3 or not sys.argv[2].isdigit():
            print("Please specify volume level (0-100).")
            sys.exit(1)
        vol = int(sys.argv[2])
        if not (0 <= vol <= 100):
            print("Volume level must be between 0 and 100.")
            sys.exit(1)
        set_volume(vol)

    elif cmd == "down":
        if len(sys.argv) != 3 or not sys.argv[2].isdigit():
            print("Please specify volume level (0-100).")
            sys.exit(1)
        vol = int(sys.argv[2])
        if not (0 <= vol <= 100):
            print("Volume level must be between 0 and 100.")
            sys.exit(1)
        set_volume(vol)

    elif cmd == "mute":
        set_mute(1)

    elif cmd == "unmute":
        set_mute(0)

    else:
        print_usage()
        sys.exit(1)
