import subprocess

if __name__ == '__main__':
    files1 = open('list1.list', 'r')
    files = files1.readlines()
    files1.close()
    files2 = open('list2.list', 'r')
    files = files + files2.readlines()
    files2.close()
    files = [f.strip() for f in files]
    for f in files:
        print "Converting %s..."%f
        subprocess.call(['avconv', '-i', "%s.mp3"%f, "%s.ogg"%f])
