"""Plot 1024-bin FFT frames from the Arty Z7 UART."""
import argparse
import re
import struct
import zlib
from pathlib import Path
from threading import Event, Thread

import numpy as np

FFT_SIZE = 1024
SYNC = b"FFT1"
PACKET_HEADER = struct.Struct("<4sIH")
CRC_TRAILER = struct.Struct("<I")
HEADER = re.compile(rb"# FRAME (\d+)")
FOOTER = re.compile(rb"# END_FRAME (\d+) COUNT (\d+)")
WORD = re.compile(rb"[0-9A-Fa-f]{8}")


def read_frames(lines):
    """Yield complete frames with matching IDs and exactly 1024 words."""
    frame_id = None
    words = []
    for raw_line in lines:
        if not raw_line.endswith(b"\n"):
            # A serial timeout can return a partial line.
            if raw_line:
                frame_id = None
            continue
        line = raw_line.strip()
        header = HEADER.fullmatch(line)
        if header:
            frame_id = int(header[1])
            words = []
        elif frame_id is not None:
            footer = FOOTER.fullmatch(line)
            if footer:
                if int(footer[1]) == frame_id and int(footer[2]) == len(words) == FFT_SIZE:
                    yield frame_id, words
                frame_id = None
            elif WORD.fullmatch(line) and len(words) < FFT_SIZE:
                words.append(int(line, 16))
            else:
                frame_id = None


def read_binary_frames(chunks, check_crc=False):
    """Decode little-endian FFT1 packets from arbitrary serial chunks."""
    pending = bytearray()
    payload_end = PACKET_HEADER.size + 4 * FFT_SIZE
    packet_size = payload_end + (CRC_TRAILER.size if check_crc else 0)

    for chunk in chunks:
        pending.extend(chunk)
        while True:
            start = pending.find(SYNC)
            if start < 0:
                # Retain a possible split marker for the next serial read.
                del pending[:-(len(SYNC) - 1)]
                break
            del pending[:start]
            if len(pending) < PACKET_HEADER.size:
                break

            _, frame_id, bin_count = PACKET_HEADER.unpack_from(pending)
            if bin_count != FFT_SIZE:
                del pending[0]
                continue
            if len(pending) < packet_size:
                break

            if check_crc:
                expected_crc, = CRC_TRAILER.unpack_from(pending, payload_end)
                actual_crc = zlib.crc32(pending[len(SYNC):payload_end])
                if actual_crc != expected_crc:
                    del pending[0]
                    continue

            payload = bytes(pending[PACKET_HEADER.size:payload_end])
            del pending[:packet_size]
            yield frame_id, np.frombuffer(payload, dtype="<u4")


def magnitude_db(words):
    packed = np.asarray(words, dtype=np.uint32)
    real = (packed >> 16).astype(np.uint16).view(np.int16)
    imag = (packed & 0xFFFF).astype(np.uint16).view(np.int16)
    magnitude = np.hypot(real.astype(float), imag.astype(float)) / 32768.0
    return 20 * np.log10(np.maximum(magnitude, 1e-6))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default="COM6")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--sim", type=Path, help="Overlay the last complete frame in this simulation log")
    parser.add_argument("--crc", action="store_true", help="Require a CRC-32 trailer from firmware")
    args = parser.parse_args()

    import pyqtgraph as pg
    import serial
    from pyqtgraph.Qt import QtCore

    sim_frame = None
    if args.sim:
        try:
            with args.sim.open("rb") as log:
                for sim_frame in read_frames(log):
                    pass
        except OSError as exc:
            parser.error(str(exc))
        if sim_frame is None:
            parser.error("simulation log has no complete 1024-bin frames")

    app = pg.mkQApp("Arty Z7 Spectrum Analyzer")
    window = pg.PlotWidget(title=f"Waiting for FFT frames on {args.port}")
    window.setWindowTitle("Arty Z7 Spectrum Analyzer")
    window.resize(1000, 550)
    window.setLabel("bottom", "FFT bin")
    window.setLabel("left", "Magnitude (dB re 1.0)")
    window.showGrid(x=True, y=True, alpha=0.3)
    window.addLegend()
    bins = np.arange(FFT_SIZE)
    hardware = window.plot(pen=pg.mkPen("c", width=2), name="Hardware")
    if sim_frame:
        sim_id, words = sim_frame
        window.plot(bins, magnitude_db(words), pen=pg.mkPen("y"), name=f"Simulation frame {sim_id}")
    window.setXRange(0, FFT_SIZE - 1, padding=0)
    window.setYRange(-120, 5, padding=0)

    try:
        uart = serial.Serial(args.port, args.baud, timeout=0.25)
    except serial.SerialException as exc:
        parser.exit(1, f"Could not open {args.port}. Close the Vitis serial terminal.\n{exc}\n")

    class Signals(QtCore.QObject):
        frame = QtCore.Signal(object, object)
        error = QtCore.Signal(str)

    signals = Signals()
    stop = Event()

    def receive():
        try:
            with uart:
                for frame_id, words in read_binary_frames(serial_chunks(), check_crc=args.crc):
                    signals.frame.emit(frame_id, magnitude_db(words))
        except serial.SerialException as exc:
            signals.error.emit(str(exc))

    def serial_chunks():
        while not stop.is_set():
            yield uart.read(min(4096, max(1, uart.in_waiting)))

    def update(frame_id, db):
        hardware.setData(bins, db)
        peak = int(np.argmax(db))
        window.setTitle(f"Hardware frame {frame_id} | Peak bin {peak} ({db[peak]:.1f} dB)")

    signals.frame.connect(update, QtCore.Qt.ConnectionType.QueuedConnection)
    signals.error.connect(window.setTitle, QtCore.Qt.ConnectionType.QueuedConnection)
    reader = Thread(target=receive, daemon=True)
    window.show()
    reader.start()
    try:
        app.exec()
    finally:
        stop.set()
        reader.join()


if __name__ == "__main__":
    main()
