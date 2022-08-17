# -*- coding: utf-8 -*-

import json
import pandas as pd
import os

def make_json(start,stop,app_id,file_name,platform):

    row_range=list(range(start-2,stop-1))
    if platform==1:
        url=#url документа для 1 платформы
    elif platform==2:
        url=#url документа для 2 платформы
    table=pd.read_csv(url, usecols=['Sub','Event','Token','App'])
    #usecols=['Sub','Event','Token','App']

    table.columns=['sub','event','token','app']
    result_dict={}
    result_dict["token"]=f"{app_id}"
    result_dict['sku']={}

    for i in row_range[::7]:
        result_dict['sku'][table['sub'].iloc[i]]={"subToken":f"{table.token.iloc[i]}",
                    "renewToken":f"{table.token.iloc[i+1]}",
                    "cancel":f"{table.token.iloc[i+2]}",
                    "recover":f"{table.token.iloc[i+3]}",
                    "refund":f"{table.token.iloc[i+4]}",
                    "empty_card":f"{table.token.iloc[i+5]}",
                    "refill_card":f"{table.token.iloc[i+6]}",
                    "trialDays":0}

    with open(file_name,'w') as test_file:
        json.dump(result_dict,test_file, indent=4)
        test_file.close()

    print('Файл тут -> ',os.getcwd()+file_name)


start=int(input('Номер первой строки excel:'))
stop=int(input('Номер последней строки excel:'))
platform=int(input('Платформа:\n1-IOS\n2-Android\n\n\n'))

print('1-Nandy\n2-Fitcher\n3-Confit\n4-MentalHealth\n5-Holo\n6-Slowdive\n7-VIN\n8-Sleeper')
app_dict={1:'2bt86116ud1c',2:'ccgv6mj9f8qo',3:'s0gqq4ko00sg',4:'490pm3hxwpts',
5:'rweg0y6invnk',6:'xetocxfzxhxc',7:'dtojbsfefkzk',8:'w59ydnl7z6rk'}
app_name_dict={1:'AdjustSKUConfigNandy.json',2:'AdjustSKUConfigFitcher.json',
3:'AdjustSKUConfigConfit.json',4:'AdjustSKUConfigMentalHealth.json',5:'AdjustSKUConfigHolo.json',6:'AdjustSKUConfigSlowdive.json',7:'AdjustSKUConfigVIN.json',8:'AdjustSKUConfigSleeper.json'}
app_id=int(input('Выбор прилы:'))
make_json(start,stop,app_dict[app_id],app_name_dict[app_id],platform)
