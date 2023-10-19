import sys
import os
import argparse
import qrcode
import time
sys.path.append('lib')
from waveshare_epd import epd2in7_V2
from PIL import Image,ImageDraw,ImageFont

'''
    read a file, insert parameters and write the new file
'''
def populate_file(ssid, password, valid, inputpath, outputpath):
    strings = []
    with open(inputpath,"r") as f:
        strings = f.readlines()
        insert_params(ssid, password, valid, strings)

    with open(outputpath, "w") as f:
        f.writelines(strings)


'''
    Insert parameters into a list of strings
'''
def insert_params(ssid, password, valid, strings):
    for i, s in enumerate(strings):
        s = s.replace("{ssid}", ssid)
        s = s.replace("{password}", password)
        s = s.replace("{valid}", valid)
        strings[i] = s

    return strings

'''
    Update the content shown on the E-Ink display.
'''
def update_display(ssid, password, valid):
    img = qrcode.make(f'WIFI:S:{ssid};T:WPA;P:{password};;')

    # Initialize E-Ink display
    epd = epd2in7_V2.EPD()
    epd.init()
    epd.Clear()

    himg = Image.new('1', (epd.width, epd.height), 255)
    draw = ImageDraw.Draw(himg)


    img = img.resize((epd.width, epd.width))


    himg.paste(img, (0, 0))
    draw.text((0, epd.width), "Guest-access", fill = 0)
    draw.text((0, epd.width+30), "Valid until:", fill = 0)
    draw.text((0, epd.width+60), valid, fill=0)


    epd.display(epd.getbuffer(himg.transpose(Image.ROTATE_180)))

    epd.sleep()

    return img


def main():
    parser = argparse.ArgumentParser(description='Update QR-Code on the display given an SSID and password')
    parser.add_argument('ssid', metavar='s', type=str, help='SSID of the network')
    parser.add_argument('password', metavar='p', type=str, help='Password of the network')
    parser.add_argument('config', metavar='c', type=str, help='Path to directory of hostapd and html template')
    parser.add_argument('valid', metavar='v', type=str, help="Valid until")

    # Parse command line arguments passed from bash script
    args = parser.parse_args()
    ssid = args.ssid
    password = args.password
    configpath = args.config
    valid = args.valid

    # Generate Hostapd configuration
    hostapd_in = os.path.join(configpath, "hostapd.template.conf")
    hostapd_out = os.path.join(configpath, "hostapd.conf")
    populate_file(ssid, password, valid, hostapd_in, hostapd_out)

    # Generate HTML "website"
    html_in = os.path.join(configpath, "index.template.html")
    html_out = os.path.join(configpath, "index.html")
    populate_file(ssid, password, valid, html_in, html_out)

    # Generate image from QR-code for "website"
    img = update_display(ssid, password, valid)
    img_out = os.path.join(configpath, "qrcode.png")
    img.resize((512, 512)).save(img_out)

if __name__ == '__main__':
    main()