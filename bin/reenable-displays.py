#!/usr/bin/env python3
# Script: reenable-displays.py
# Author: @alex-konkov
# Original source: https://github.com/jakehilborn/displayplacer/issues/137#issuecomment-1188372337
# Description: Uses private CoreGraphics APIs to force-enable macOS displays.

from ctypes import (CDLL, util, c_void_p, c_uint32, c_int, c_bool, POINTER, byref)

cg = CDLL(util.find_library('CoreGraphics'))

cg.CGBeginDisplayConfiguration.argtypes = [POINTER(c_void_p)]
cg.CGBeginDisplayConfiguration.restype = c_int
cg.CGCompleteDisplayConfiguration.argtypes = [c_void_p, c_int]
cg.CGCompleteDisplayConfiguration.restype = c_int
cg.CGCancelDisplayConfiguration.argtypes = [c_void_p]
cg.CGCancelDisplayConfiguration.restype = c_int
cg.CGSConfigureDisplayEnabled.argtypes = [c_void_p, c_uint32, c_bool]
cg.CGSConfigureDisplayEnabled.restype = c_int

def enable_display(display_id):
    config_ref = c_void_p()
    if cg.CGBeginDisplayConfiguration(byref(config_ref)) != 0:
        return
    if cg.CGSConfigureDisplayEnabled:
        if cg.CGSConfigureDisplayEnabled(config_ref, display_id, True) != 0:
            cg.CGCancelDisplayConfiguration(config_ref)
            return
    cg.CGCompleteDisplayConfiguration(config_ref, 0)

def reset_displays():
    for display_id in range(1, 11):
        enable_display(display_id)

if __name__ == "__main__":
    reset_displays()

