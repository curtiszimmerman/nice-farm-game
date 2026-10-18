#!/usr/bin/env python3
"""Gracefully restart this project's native game on the current X11 desktop.

Sends the normal window-close request so the running game can save, then starts
the project-local launcher. Logs and runtime data remain inside this project.
"""
import argparse
import ctypes as c
from ctypes.util import find_library
from pathlib import Path
import subprocess
import time


class MessageData(c.Union):
    _fields_ = [("bytes", c.c_char * 20), ("shorts", c.c_short * 10), ("longs", c.c_long * 5)]


class ClientMessage(c.Structure):
    _fields_ = [("type", c.c_int), ("serial", c.c_ulong), ("send_event", c.c_int),
                ("display", c.c_void_p), ("window", c.c_ulong), ("message_type", c.c_ulong),
                ("format", c.c_int), ("data", MessageData)]


class Event(c.Union):
    _fields_ = [("client", ClientMessage), ("padding", c.c_long * 24)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    library = find_library("X11")
    if not library:
        parser.exit(1, "X11 client library is unavailable. No game was closed.\n")
    x = c.CDLL(library)
    x.XOpenDisplay.argtypes, x.XOpenDisplay.restype = [c.c_char_p], c.c_void_p
    x.XDefaultRootWindow.argtypes, x.XDefaultRootWindow.restype = [c.c_void_p], c.c_ulong
    x.XInternAtom.argtypes, x.XInternAtom.restype = [c.c_void_p, c.c_char_p, c.c_int], c.c_ulong
    x.XGetWindowProperty.argtypes = [c.c_void_p, c.c_ulong, c.c_ulong, c.c_long, c.c_long, c.c_int, c.c_ulong,
                                    c.POINTER(c.c_ulong), c.POINTER(c.c_int), c.POINTER(c.c_ulong),
                                    c.POINTER(c.c_ulong), c.POINTER(c.POINTER(c.c_ubyte))]
    x.XFetchName.argtypes = [c.c_void_p, c.c_ulong, c.POINTER(c.c_void_p)]
    x.XFree.argtypes = [c.c_void_p]
    x.XSendEvent.argtypes = [c.c_void_p, c.c_ulong, c.c_int, c.c_long, c.POINTER(Event)]
    x.XFlush.argtypes = [c.c_void_p]
    x.XCloseDisplay.argtypes = [c.c_void_p]
    display = x.XOpenDisplay(None)
    if not display:
        parser.exit(1, "Cannot connect to the host X11 display. No game was closed.\n")
    root = x.XDefaultRootWindow(display)
    clients_atom = x.XInternAtom(display, b"_NET_CLIENT_LIST", 0)

    def windows():
        actual, fmt, count, remaining = c.c_ulong(), c.c_int(), c.c_ulong(), c.c_ulong()
        data = c.POINTER(c.c_ubyte)()
        x.XGetWindowProperty(display, root, clients_atom, 0, 4096, 0, 0,
                             c.byref(actual), c.byref(fmt), c.byref(count), c.byref(remaining), c.byref(data))
        result = list(c.cast(data, c.POINTER(c.c_ulong))[:count.value]) if data and fmt.value == 32 else []
        if data:
            x.XFree(data)
        return result

    targets = []
    for window in windows():
        name = c.c_void_p()
        if x.XFetchName(display, window, c.byref(name)) and name:
            title = c.string_at(name).decode("utf-8", "replace")
            x.XFree(name)
            if title.startswith("Somewhere, the Sun Still Rises"):
                targets.append(window)
    protocols = x.XInternAtom(display, b"WM_PROTOCOLS", 0)
    close = x.XInternAtom(display, b"WM_DELETE_WINDOW", 0)
    for window in targets:
        event = Event()
        event.client = ClientMessage(33, 0, 1, display, window, protocols, 32, MessageData())
        event.client.data.longs[0] = close
        x.XSendEvent(display, window, 0, 0, c.byref(event))
    x.XFlush(display)
    deadline = time.monotonic() + 5
    while set(targets).intersection(windows()):
        if time.monotonic() >= deadline:
            x.XCloseDisplay(display)
            parser.exit(1, "The existing game has not closed; leaving it running without forcing a restart.\n")
        time.sleep(.1)
    x.XCloseDisplay(display)
    project = Path(__file__).resolve().parent.parent
    log_path = project / "internal/runtime/relaunch.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("ab") as log:
        process = subprocess.Popen(["bash", str(project / "scripts/play.sh")], cwd=project,
                                   stdout=log, stderr=log, start_new_session=True)
    print(f"Native game launched (PID {process.pid}). Closed {len(targets)} previous game window(s) gracefully.")
    print(f"Log: {log_path}")


if __name__ == "__main__":
    main()
