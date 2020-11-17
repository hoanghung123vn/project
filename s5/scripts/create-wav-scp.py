import os
path = os.getcwd()
files = []
for r, d, f in os.walk(path):
    for file in f:
        if '.wav' in file:
            files.append(os.path.join(r, file))
ghi = open('wav.scp','w') 
for f in files:
    x = f.split('/')
    ghi.write(x[-1][:-4]+ ' '+ f +'\n')
ghi.close()
