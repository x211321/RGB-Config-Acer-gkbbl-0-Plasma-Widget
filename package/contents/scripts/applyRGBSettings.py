import os
import sys

# Available RGB Modes
RGB_MODE_STATIC   = 0
RGB_MODE_BREATH   = 1
RGB_MODE_NEON     = 2
RGB_MODE_WAVE     = 3
RGB_MODE_SHIFTING = 4
RGB_MODE_ZOOM     = 5

# Payload sizes
RGB_PAYLOAD_SIZE         = 16
RGB_STATIC_PAYLOAD_SIZE  = 4

# RGB kernel devices
RGB_DEVICE        = "/dev/acer-gkbbl-0"
RGB_DEVICE_STATIC = "/dev/acer-gkbbl-static-0"


####################
# applySettings
#-------------------
def applySettings():

    # Default values
    mode       = 0
    brightness = 100
    speed      = 3
    direction  = 1
    tempColors = "red,green,blue,yellow"
    colors     = []

    # Get command-line arguments
    for i in range(1, len(sys.argv), 2):
        if sys.argv[i] == "--check":
            # Check RGB device available
            if not os.path.exists(RGB_DEVICE):
                print("1")
                return 

            # Check if static device available
            if not os.path.exists(RGB_DEVICE_STATIC):
                print("2")
                return

        if sys.argv[i] == "-m":
            mode       = int(sys.argv[i+1])
        if sys.argv[i] == "-b":
            brightness = int(sys.argv[i+1])
        if sys.argv[i] == "-s":
            speed      = int(sys.argv[i+1])
        if sys.argv[i] == "-d":
            direction  = int(sys.argv[i+1])
        if sys.argv[i] == "-c":
            tempColors = sys.argv[i+1]


    tempColors = tempColors.split(",")

    for color in tempColors:
        colors.append(tuple(int(color[i:i+2], 16) for i in (0, 2, 4)))


    # Check RGB device available
    if not os.path.exists(RGB_DEVICE):
        print("1")
        return 

    if mode == RGB_MODE_STATIC:
        # Check if static device available
        if not os.path.exists(RGB_DEVICE_STATIC):
            print("2")
            return 

        # Write RGB Settings for each zone to static device
        for zone, color in enumerate(colors):

            # Set zone coloring
            pload = [0] * RGB_STATIC_PAYLOAD_SIZE

            pload[0] = 1 << zone
            pload[1] = color[0]
            pload[2] = color[1]
            pload[3] = color[2]

            # Write to Static device
            writePayload(RGB_DEVICE_STATIC, pload)

        # Activate Static mode
        pload = [0] * RGB_PAYLOAD_SIZE
        pload[2] = brightness
        pload[9] = 1

        # Write to RGB device
        writePayload(RGB_DEVICE, pload)
    else:
        # Dynamic RGB mode
        pload = [0] * RGB_PAYLOAD_SIZE
        pload[0] = mode
        pload[1] = speed
        pload[2] = brightness
        pload[3] = 8 if mode == RGB_MODE_WAVE else 0
        pload[4] = 1 if direction else 2
        pload[5] = colors[0][0]
        pload[6] = colors[0][1]
        pload[7] = colors[0][2]
        pload[9] = 1

        # Write to RGB device
        writePayload(RGB_DEVICE, pload)



####################
# writePayload
#-------------------
# Write given payload to kernel device
# - arg device: string - path to kernel device
# - arg pload: bytearray - payload
def writePayload(device, pload):
    with open(device, "wb") as d:
        d.write(bytes(pload))



# Main entry point
if __name__ == "__main__":
    applySettings()
