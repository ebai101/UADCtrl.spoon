#!/usr/bin/env python

import socket
import json
import sys

quant_factor = 54


def monitorLevelQuantized():
    s.send(b"get /devices/0/outputs/4/CRMonitorLevelTapered/value\0")
    monitorLevel = json.loads(recvall(s).decode().replace("\u0000", ""))["data"]
    print(monitorLevel * quant_factor)
    return round(monitorLevel * quant_factor) / quant_factor


def recvall(sock):
    data = bytearray()
    while True:
        packet = sock.recv(4096)
        if not packet:
            break
        data.extend(packet)
        if b"\x00" in data:
            break
    return data


if __name__ == "__main__":
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", 4710))

    try:
        command = sys.argv[1]
    except:
        print("need command")
        sys.exit(1)

    s.send(b"set /Sleep false\0")

    match command:
        case "up":
            mlq = monitorLevelQuantized()
            newMonitorLevel = mlq + (1 / quant_factor) if mlq < 1.0 else 1.0
            s.send(
                f"set /devices/0/outputs/4/CRMonitorLevelTapered/value {newMonitorLevel}\0".encode()
            )
            print("volume up")
            print(f"new volume is {newMonitorLevel}")
        case "down":
            mlq = monitorLevelQuantized()
            newMonitorLevel = mlq - (1 / quant_factor) if mlq > 0.0 else 0.0
            s.send(
                f"set /devices/0/outputs/4/CRMonitorLevelTapered/value {newMonitorLevel}\0".encode()
            )
            print("volume down")
            print(f"new volume is {newMonitorLevel}")
        case "mute":
            s.send(b"get /devices/0/outputs/4/Mute/value\0")
            mute = json.loads(recvall(s).decode().replace("\u0000", ""))["data"]
            mute = 1 if not mute else 0
            s.send(f"set /devices/0/outputs/4/Mute/value {mute}\0".encode())
            print("muted" if mute == 1 else "unmuted")
        case _:
            print("invalid command")

    s.close()
