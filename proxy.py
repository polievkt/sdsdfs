"""1. proxy USB codes 2. alter next key with """
from copy import deepcopy
import socket
import keyboard as kbd

#TODO:
#keyboard hotplug
#autodetect darwin keyboards - no win key

USB_CODES = {
    'a':4,
    'b':5,
    'c':6,
    'd':7,
    'e':8,
    'f':9,
    'g':10,
    'h':11,
    'i':12,
    'j':13,
    'k':14,
    'l':15,
    'm':16,
    'n':17,
    'o':18,
    'p':19,
    'q':20,
    'r':21,
    's':22,
    't':23,
    'u':24,
    'v':25,
    'w':26,
    'x':27,
    'y':28,
    'z':29,
    '1':30,
    '!':30,
    '2':31,
    '@':31,
    '3':32,
    '#':32,
    '4':33,
    '$':33,
    '5':34,
    '%':34,
    '6':35,
    '^':35,
    '7':36,
    '&':36,
    '8':37,
    '*':37,
    '9':38,
    '(':38,
    '0':39,
    ')':39,
    'enter':40,
    'esc':41,
    'delete':76,
    'space':44,
    'tab':43,
    '-':45,
    '_':45,
    '=':46,
    '+':46,
    '[':47,
    '{':47,
    ']':48,
    '}':48,
    '\\':49,
    '|':49,
    ';':51,
    ':':51,
    '"':52,
    '\'':52,
    '`':53,
    '~':53,
    ',':54,
    '<':54,
    '>':55,
    '.':55,
    '/':56,
    '?':56,
    'caps lock':57,
    'f1':58,
    'f2':59,
    'f3':60,
    'f4':61,
    'f5':62,
    'f6':63,
    'f7':64,
    'f8':65,
    'f9':66,
    'f10':67,
    'f11':68,
    'f12':69,
    'f13':58,
    'f14':59,
    'f15':60,
    'f16':61,
    'f17':62,
    'f18':63,
    'f19':64,
    'f20':65,
    'f21':66,
    'f22':67,
    'f23':68,
    'f24':69,
    'insert':73,
    'find':74,
    'home':74,
    'end':77,
    'select':77,
    'page up':75,
    'page down':78,
    'right':79,
    'left':80,
    'down':81,
    'up':82,
    'ctrl':224,
    'shift':225,
    'alt':226,
    'win':227,
    'windows':227,
    'backspace':42
}

def eval_mod_byte():
    """first byte should represent modifiers state"""
    ctrl = "1" if kbd.is_pressed('ctrl') else "0"
    alt = "1" if kbd.is_pressed('alt') else "0"
    shift = "1" if kbd.is_pressed('shift') else "0"
    #HACK: for darwin keyboards...
    #win = "0"
    win = "1" if kbd.is_pressed('win') else "0"
    return bytes([int("0000"+win+alt+shift+ctrl, 2)])

def keys2bytes(keys):
    """return bytes ready to be transferred to usb device. keys should be decimal"""
    assert len(keys) < 7
    return eval_mod_byte()+bytes([0])+bytes(keys)+bytes([0 for x in range(0, 6-len(keys))])

class KbdInput():
    def __init__(self, dev):
        # open device
        self.dev = open(dev, 'wb')
        self.pressed_keys = []
        self.magic_key_single = "r"
        self.magic_key_aoe = "t"
        self.magic_key_burst = "g"
        self.ai_key_single = None
        self.ai_key_aoe = None
        self.ai_key_burst = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.dev.close()
    
    def usrinput(self, _):
        keys = [e.name for e in kbd._pressed_events.values()]
        if not keys == self.pressed_keys:
            self.pressed_keys = keys
            self.push(self.pressed_keys)
    
    def alter_keys(self, keys):
        newkeys = deepcopy(keys)
        if self.ai_key_single and self.magic_key_single in keys:
            print("Replacing {} with {}".format(newkeys[newkeys.index(self.magic_key_single)], self.ai_key_single))
            newkeys[newkeys.index(self.magic_key_single)] = self.ai_key_single
        if self.ai_key_aoe and self.magic_key_aoe in keys:
            print("Replacing {} with {}".format(newkeys[newkeys.index(self.magic_key_aoe)] , self.ai_key_aoe))
            newkeys[newkeys.index(self.magic_key_aoe)] = self.ai_key_aoe
        if self.ai_key_burst and self.magic_key_burst in keys:
            print("Replacing {} with {}".format(newkeys[newkeys.index(self.magic_key_burst)] , self.ai_key_burst))
            newkeys[newkeys.index(self.magic_key_burst)] = self.ai_key_burst
        return newkeys

    def push(self, keys):
        assert len(keys) < 7
        keys2send = self.alter_keys(keys)
        result = keys2bytes([USB_CODES.get(k, 0) for k in keys2send])
        self.dev.write(result)
        self.dev.flush()

if __name__ == "__main__":
    with KbdInput("/dev/hidg0") as myinput:
        kbd.hook(myinput.usrinput)
        SRV = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        SRV.bind(('', 5000))
        print("Listening")
        while 42:
            DATA, ADDR = SRV.recvfrom(20)
            if DATA:
                decoded = DATA.decode("ascii").split("|")
                if len(decoded) == 3:
                    myinput.ai_key_single = decoded[0]
                    myinput.ai_key_aoe = decoded[1]
                    myinput.ai_key_burst = decoded[2]
                else:
                    print("broken")
                print(decoded)
