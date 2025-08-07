import requests
import json
import websocket

def scan_target(ip, port):
    actions = []
    http_base = f"http://{ip}:{port}"
    ws_base = f"ws://{ip}:{port}"

    try:
        response = requests.get(http_base + "/api/system/info", timeout=2)
        if response.status_code == 200:
            actions.append({
                'type': 'http',
                'name': 'Reboot TV',
                'path': '/api/system/reboot',
                'method': 'POST'
            })
            actions.append({
                'type': 'http',
                'name': 'Display Custom Message',
                'path': '/api/display/message',
                'method': 'POST'
            })
    except:
        pass

    try:
        ws = websocket.create_connection(ws_base + "/ws/control", timeout=2)
        ws.send(json.dumps({"command": "ping"}))
        response = ws.recv()
        if "pong" in response:
            actions.extend([
                {'type': 'ws', 'name': 'Volume Up', 'command': 'volume_up'},
                {'type': 'ws', 'name': 'Volume Down', 'command': 'volume_down'},
                {'type': 'ws', 'name': 'Mute Audio', 'command': 'mute'},
                {'type': 'ws', 'name': 'Change Source', 'command': 'source_hdmi1'}
            ])
        ws.close()
    except:
        pass

    if actions:
        return {'actions': actions}
    return None