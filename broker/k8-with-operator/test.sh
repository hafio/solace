#!/bin/bash

tmpfile=.out
showfile() {
	echo '----------- START ------------'
	cat ${1:-${tmpfile}}
	echo '------------ END -------------'
	echo
}

# Redirecting input, output, and error in different ways

echo "### Demonstrating Bash Redirection ###"

### 1. Basic Output Redirection (`>` and `>>`)
echo -e "\n[1] Writing to a file (>):\n    echo \"This will overwrite the file.\" > ${tmpfile}"
echo "This will overwrite the file." > ${tmpfile}
showfile ${tmpfile}

echo -e "\n[2] Appending to a file (>>):\n    echo \"This line is appended.\" >> ${tmpfile}"
echo "This line is appended." >> ${tmpfile}
showfile ${tmpfile}

### 2. Basic Input Redirection (`<`)
echo -e "\n[3] Reading from a file (<):\n    while read line; do\n        echo \"Reading line: \${line}\"\n    done < ${tmpfile}"
echo '----------- START ------------'
while read line; do
    echo "Reading line: ${line}"
done < ${tmpfile}
echo '------------ END -------------'

### 3. Read/Write Redirection (`<>`) ###
echo -e "\n[4] Read/Write mode (<>), modifying a file:\n    exec 3<> ${tmpfile}\n    echo \"Modified via <> redirection\" >&3\n    exec 3>&-"
echo "Original File Content:"
showfile ${tmpfile}
exec 3<> ${tmpfile}  # Open file for read & write using FD 3
echo "Modified via <> redirection" >&3
exec 3>&-  # Close FD 3
echo "Updated File Content:"
showfile ${tmpfile}
exit
### 4. Here String (`<<<`) ###
echo -e "\n[5] Using Here String (<<<)"
read var <<< "This is input from a Here String"
echo "Captured via Here String: $var"

### 5. Here Document (`<<`) ###
echo -e "\n[6] Using Here Document (<<)"
cat << EOF
This is a Here Document.
It spans multiple lines.
EOF

### 6. Redirecting Errors (`2>` and `2>>`) ###
echo -e "\n[7] Redirecting Errors (2>)"
ls non_existent_file 2> ${tmpfile}
showfile ${tmpfile}
exit

echo -e "\n[8] Appending Errors (2>>)"
ls another_missing_file 2>> error.log
echo "error.log:"
show error.log

### 7. Redirecting Both Output & Error (`&>`, `2>&1`) ###
echo -e "\n[9] Redirecting stdout & stderr together (&>)"
ls non_existent_file another_missing_file &> combined.log
echo "Check 'combined.log' for both output & error."

echo -e "\n[10] Using 2>&1 (stderr to stdout)"
ls non_existent_file another_missing_file > stdout.log 2>&1
echo "Check 'stdout.log' for combined output."

### 8. Discarding Output (`>/dev/null`, `2>/dev/null`) ###
echo -e "\n[11] Discarding Output (>/dev/null)"
echo "This message is thrown away." > /dev/null

echo -e "\n[12] Discarding Errors (2>/dev/null)"
ls missingfile 2> /dev/null

### 9. Using File Descriptors (>& and <&) ###
echo -e "\n[13] Redirecting File Descriptors (>& and <&)"
exec 3> fd_test.txt  # Open FD 3 for writing
echo "Writing via FD 3" >&3
exec 3>&-  # Close FD 3
echo "Check 'fd_test.txt' for output."

### 10. Tee Command to Redirect and
