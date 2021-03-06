import subprocess

install_cmd_list = [
    'echo "passwd" | sudo -S apt -y install virtualenv git python3-tk',
    'virtualenv -p python3 /home/user/multicamp',
    '/home/user/multicamp/bin/pip3 install --upgrade tensorflow==1.14 matplotlib ipykernel jupyter music21 gym',
    '/home/user/multicamp/bin/python3 -m ipykernel install --user',
]
for install_cmd in install_cmd_list:
    install_proc = subprocess.Popen(install_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    while install_proc.poll() is None:
        out = install_proc.stdout.readline()
        print(out.decode('utf-8'), end='')
