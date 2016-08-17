# String.tcl --
#   This file implements the string defination for the highlevel CAPI of IxNetwork device.
#
# Copyright (c) Ixia technologies, Inc.

# Version 1.1
# Change
#   Version 1.1

proc after {args} \
    {
	    set retCode ""

	    set argc    [llength $args]

	    set duration  [lindex $args 0]  
	    if {[stringIsInteger $duration] && $argc == 1 && $duration > 0} {
		    ixSleep $duration
		    set retCode ""
	    } else {
		    catch {eval originalAfter $args} retCode
	    }

	    set retCode [stringSubstitute $retCode originalAfter after]

	    return $retCode
    }