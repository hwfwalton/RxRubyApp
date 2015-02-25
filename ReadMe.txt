Henry Walton
hwfwalton@gmail.com

RX COVERAGE CHECKER
=================================================
This is a small Ruby app built for the purposes of demonstration and learning
Ruby. The user can enter the name of their prescription and is shown a list 
of which of four health insurance carriers (Anthem, BlueShield, Cigna, and 
Medicare) cover their prescription and at what tier. The data behind this list
is scraped from pdfs from each of the four aforementioned health insurance
carriers and is stored in an sqlite3 db included with the Ruby app.

USAGE:
=================================================
The only files needed to use the app are RxCoverageChecker.rb and drugs.db. It
is also necesarry to have Ruby installed. Place files both in the same 
directory and either double click RxCoverageCheck.rb or run it from your 
command line or terminal with 'ruby RxCoverageCheck.rb'.

I have also included the files needed to recreate drugs.db if necesarry. Place
the four text files, CreateDb.rb. create.sql, and popEqClass.py in a directory
together. Create the database be either starting sqlite and running create.sql
with '.read create.sql' or by running create.sql directly. Next double click
CreateDB.rb or run it with 'ruby CreateDB.rb' to populate the database from the
text files. Lastly, run popEqClass.py by double clicking it or with 
'python popEqClass.py'. This scans the db and uses the GoodRx API to populate
the equivalence class column. This may take some time.


FILES:
=================================================

RxCoverageChecker.rb      
drugs.db
ReadMe.txt

db_files/Anthem.txt
db_files/BlueShield.txt
db_files/Cigna.txt
db_files/Medicare.txt
db_files/CreateDB.rb
db_files/popEqClass.py
db_files/create.sql


DEVELOPMENT PROCESS AND CHALLENGES
=================================================
There were four main stages in the development of the RxCoverageChecker Ruby
applet. The first and by far most time consuming, was extracting usable data 
from the given pdfs. I initially attempted to pull raw text from the pdfs, and
though this proved viable for the Anthem pdf, it was far from for the others.
Next I tried to convert the pdfs to html. The results from the Python and Ruby
I tried to do this were unusuable, but I eventually acquired a copy of Acrobat
Pro, which was about to extract the formatting much more cleanly. With the html
in hand, it was relatively straight forward to build a few scripts to pull what
I needed. The Python BeautifulSoup Module proved invaluable for this.

The next stage was cleaning up the text. Though I now had the drug names and
tiers in a long list, the names were often inconsistent and literred with 
formatting. I was unsure however, how much information I could strip. many of
the drugs were the same save for a dosage in one of the titles, and I wasn't
sure if keeping this information was important or not. I ended up stripping a
fair amount of the extra information to try to unify more of my database rows.

Next was building the sqlite database to house the values. I chose to use three
tables, Drugs, Carriers, and Covers, the third acting as a Junction Table 
between the first two. I've included the sql script I used to define my tables.
The db can be reconstructed using create.sql to define the tables followed by
CreateDB.rb which populates them from the text files.

With the data now accessible, the next step was building a gui to access it.
The tk gem took some getting used to, but this was otherwise the easiest step.
I had some fun trying to get the list to dynamically update. It sort of works.

The final part, and most challenging, was building my drug equivalence classes.
Though my database was populated at this point, and the applet text matches
similarly named drugs, it did not yet find equivalent drugs to what the user
had searched for (i.e. showing Ibuprofen if the user searches for Motrin). I 
used a combination of the GoodRx API and partial text matching with existing 
entries in my db to populate the EqClass column of the Drugs table. Related
or interchangable drugs share the same EqClass value. I used a Python script
for this (popEqClass.oy) as the list comprehension proved very handy.


KNOWN BUGS AND ISSUES
=================================================
The dynamic results list only sort of works. It is always one input event 
behind. This can be accounted for by using the Update Results button, but
the issue stands. It is a results of using the validation process to 
populate the results list. validation is checked whenever the text field is
editted, launching an update to the results list, but because the edit isn't
acknowledged until the validation command has concluded, the text
validationcommand sees is always one edit behind. The solution to this would
be to switch the results updating to some kind of event handler, and launch and
event upon validation completion. I'm not sure tk or Ruby have these features
by default though, so this could prove difficult.

The results list can some times push the More Results button beneath the bottom
of the window. This happens if the list of equivalent drugs gets too long and
wraps several times. Because the wraps are not line breaks, they are not
counted when determining how many results to show. The solution to this would
be to track the length of the equivalent drugs list as it is being built and
insert breaks rather than relying on wrapping.

