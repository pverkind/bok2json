# bok2json

Convert .bok / .mdb files from al-Maktaba al-Shamela into json format.

Shamela's .bok files are Microsoft Access database files,
in Windows 1256 (Arabic) encoding.

This script converts all .bok and .mdb files in a folder into json files;
each table in the bok file has its own entry in the json file. 


## Prerequisites:

The script has been tested only on Ubuntu (Windows WSL)
It requires the [mdbtools](https://github.com/mdbtools/mdbtools) 
and [miller](https://miller.readthedocs.io/en/latest/) packages. 

To install those, run:

```
sudo apt-get install mdbtools miller
```

## Usage: 

The bok2json script does not need to be installed. Simply run

```
bash <path/to/bok2json.sh> <input_folder> [<output_folder>]
```

E.g., `bash ./bok2json.sh ./bok_files ./json_files`

## TO DO:

- add possibility to convert only one file
- add possibility to provide output filename
- add possibility to use table ID instead of filename
- add "overwrite" argument