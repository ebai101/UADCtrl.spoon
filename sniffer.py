#!/usr/bin/env python

from scapy.all import *
from threading import Thread
from pprint import pprint
import socket
import time
import json


class Sniffer(Thread):
    def __init__(self, filter=True):
        super().__init__()
        self.stop_sniffer = Event()
        self.filter = filter

    def uad_prn(self, pkt):
        if (pkt.haslayer(Raw) and pkt.haslayer(TCP)) and (
            pkt[TCP].sport == 4710 or pkt[TCP].dport == 4710
        ):
            try:
                data = pkt[Raw].load.decode().replace("\u0000", "")
            except:
                pass
            else:
                filter_strings = [
                    "/ClockLocked",
                    "/MeterPulse",
                    "/ping",
                    "/UndoRedo",
                    "/UndoRecording",
                ]
                if not filter or not any(filter in data for filter in filter_strings):
                    try:
                        data_json = json.loads(data)
                        print(
                            f'{time.asctime(time.localtime(pkt.time))} {"SEND" if pkt[TCP].dport == 4710 else "RECV"}'
                        )
                        pprint(data_json)
                    except:
                        print(
                            f'{time.asctime(time.localtime(pkt.time))} {"SEND" if pkt[TCP].dport == 4710 else "RECV"} {data}'
                        )

    def run(self):
        sniff(iface="lo0", prn=self.uad_prn, stop_filter=self.should_stop_sniffer)

    def join(self, timeout=None):
        self.stop_sniffer.set()
        super().join(timeout)

    def should_stop_sniffer(self, packet):
        return self.stop_sniffer.is_set()


if __name__ == "__main__":
    sniffer = Sniffer(filter=True)
    sniffer.start()

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", 4710))

    try:
        while True:
            message = input()
            s.send(f"{message}\0".encode("utf-8"))
    except KeyboardInterrupt:
        s.close()
        sniffer.join(2.0)
        if sniffer.is_alive():
            sniffer.socket.close()
