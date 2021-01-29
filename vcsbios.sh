#!/usr/bin/env bash
#==============================================================================
#   ______ _______ _______  ______  _____       _______ _     _ _____ _______
#  |_____/ |______    |    |_____/ |     |      |_____|  \___/    |   |______
#  |    \_ |______    |    |    \_ |_____|      |     | _/   \_ __|__ ______|
#                                                                           
#==============================================================================
#     Program: vcschroot.sh
#      Author: retroaxis.tv
#         Ver: 20210128
# Description: This script creates demonstrates 
#              How to retrieve the BIOS Password on an AtariVCS
#              from a Linux OS.  Requires the correctly installed
#              package from your distribution with the efivar command
#
#==============================================================================
#
EFIKEY=`efivar -l | grep SystemSupervisorPW`
efivar -p -n $EFIKEY
