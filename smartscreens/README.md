# dark screen is a tool to control smart screens like TV based on common exploits

**PREPRATION**

* first you need to scan the network to know the smartscreen ip using the easy way 
[open] **zenmap** [and perform an] **intense scan plus tcp**

* second step is adding the ip and the port
[nano darkscreen.py] **and change the ip in line** [5] 
**now change the port in line** [6] example ["http://{TV_IP}:49153/rcr_control"] TO ["http://{TV_IP}:28008/rcr_control"]


# tool based on 

* upnp
* websocket

# you will put the upnp port and if not working try the websocket one

**usage**

* python3 darkscreen.py up 100
* python3 darkscreen.py down 0
* python3 darkscreen.py mute
* python3 darkscreen.py unmute


[this tool is still under test we are working on an easy CLI one with more options like controling the content on the screen]
