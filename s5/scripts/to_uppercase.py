def upperUtf8(s):
    if type(s) == type(u""):
        return s.upper()
    return s.decode("utf8").upper().encode("utf8")

def test(files):
    for x in files:
        with open(x, "r+b") as inputFile:
          content = upperUtf8(inputFile.read())
          inputFile.seek(0)
          inputFile.write(content)

files = ["../data/local/dict/lexicon.txt", "../data/local/dict/nonsilence_phones.txt", "../data/local/dict/phone.list"]
test(files)