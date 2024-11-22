# hashid2cat
A simple script that:  
- Runs takes a hash as input
- Runs it against hashid
- Gathers all output hashtypes
- Uses them as an argument for hashcat
- Runs the input hash against hashcat through all hashtypes generated via hashid

Recommended for using it in cases that a hash is of unknown type.  That is because running hashcat through all generated hashtypes can take a long time.
If the hashtype is obvious (eg MD5), then it's best to run it directly against hashcat as it will take less time.
