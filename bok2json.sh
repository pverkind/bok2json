#!/usr/bin/env bash

# Requires mdbtools and miller packages
# To install those: run `sudo apt-get install mdbtools miller`

# Usage: 
# bash <path_to_this_script> <input_folder> [<output_folder>]
# e.g., bash ./bok2json.sh ./bok_files ./json_files


# if no input folder is provided, exit with usage guidelines:
if [ -z "$1" ];then
  echo "Please provide at least an input folder"
  echo "containing one or more files with .mdb or .bok extension."
  echo " "
  echo "Usage: bash ./bok2json <input_folder> [<output_folder>]"
  exit 1
fi

# 1. Define the output folder:
if [ -z "$2" ];then
  echo "No output folder supplied"
  outfolder="$1"/json
else
  outfolder="$2"
fi
echo infolder: "$1"
echo outfolder: "$outfolder"

# 2. Create the output folder if it doesn't exist:
[ ! -d "$outfolder" ] && mkdir $outfolder

# 3. convert all .bok and .mdb files in the infolder:
for fp in $1/*.{bok,mdb}; do(
  echo $fp
  fn="${fp##*/}" # remove parent directories, if there are
  fn="${fn%.*}"  # remove extension, if there is one

  # get the names of the tables:
  tables=$(mdb-tables $fp)

  # create a temporary directory to contain all table jsons separately:
  temp_dir="$1"/temp
  [ -d "$temp_dir" ] && rm -rf $temp_dir
  mkdir $temp_dir

  # get the book ID from the table names:
  echo "$tables" > tables.tmp
  book_id=$(grep -P 'b\d\d+' tables.tmp --only-matching)
  rm tables.tmp
  book_id=${book_id:1}
  echo book_id: "$book_id"
  
  # save every table to a temporary file (we will later concatenate them):
  echo Converting tables:
  for table in $tables; do(
    table_fp="$temp_dir"/"$table".json
    echo "* $table > $table_fp"


    # extract the table from the database in csv format:
    table_tsv=$(mdb-export -R _ROW_END_ -d \\t $fp $table)

    # format the csv: 
    table_tsv=${table_tsv//$'\r'/_LINE_END_} # encode carriage return in field
    table_tsv=${table_tsv//$'\n'/_LINE_END_} # encode line endings in field
    table_tsv=${table_tsv//_ROW_END_/$'\n'} # replace row endings
    table_tsv=${table_tsv//$'\"'}  # remove quotation marks

    # save the csv to a temporary file:
    printf "$table_tsv" > temp.txt

    # convert the csv to json
    table_json=$(mlr --t2j --jlistwrap --jvstack cat temp.txt)

    # write the table name as json key to the table file:
    printf "\n\"$table\": " > $table_fp

    # write the json version of the table to the file
    # (writing "[]" if the table was empty):
    #echo length of table $table: ${#table_json}
    if (( ${#table_json} < 5 )); then
      #echo $table is an empty table
      printf '[],' >> "$temp_dir"/"$table".json
    else
      printf "$table_json," >> "$temp_dir"/"$table".json
    fi
  ); done

  # concatenate all the tables into one json file:
  #json_fp="$outfolder/$book_id.json"
  json_fp="$outfolder/$fn.json"
  echo Writing temporary files to json: $json_fp

  # start with an opening bracket:
  printf '[' > $json_fp
  # concatenate all table jsons:
  find "$temp_dir" -type f -name "*.json" -exec cat {} + >> $json_fp
  # remove the final, superfluous, comma from the file:
  truncate -s -1 $json_fp
  # end with a closing bracket
  printf '\n]' >> $json_fp
  
  # CONVERT TO UTF-8:
  # the database files are stored in Windows 1256 (UTF-8) encoding,
  # but mdb tools extract them in Windows 1252 encoding, 
  # and Linux stores them in UTF-8 encoding.
  
  echo "Converting back to Windows 1252 encoding..."
  iconv -f UTF-8 -t CP1252 -o "$json_fp"_1252.json $json_fp
  echo "Interpreting the text as Windows 1256 (Arabic) text"
  echo and saving it with UTF-8 encoding...
  iconv -f CP1256 -t UTF-8 -o "$json_fp" "$json_fp"_1252.json
  echo "$json_fp" saved.
  echo "-----------------------------"

  # clean up temp files:
  rm "$json_fp"_1252.json
  rm -rf "$temp_dir"
  rm temp.txt
); done

echo "done!"
