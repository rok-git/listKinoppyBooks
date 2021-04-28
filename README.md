# listKinoppyBooks

## What?

This program creates a CSV file containing some info (author, author in kana, title, title in kana, publisher, purchased date) for books purchaesed at KINOKUNIYA bookstore.

These information are picked up from the cache file 'Kinokuniya Kinoppy(紀伊国屋kinoppy.app)' uses (~/Library/Containers/jp.co.kinokuniya.kinoppy/Data/Library/Application\ Support/jp.co.kinokuniya.kinoppy/.Contents/0_XXXXXXX).

## How?

### How to build:

Xcode and xcode command-line tools must be installed.

Just type `make` to build.
Type `sudo make install` if you want to install the command at /usr/local/bin.

### How to use:

listKinoppyBooks reads data from default file (~/Library/Containers/jp.co.kinokuniya.kinoppy/Data/Library/Application\ Support/jp.co.kinokuniya.kinoppy/.Contents/0_XXXXXXX).

`listKinoppyBooks > ./kino.csv`

Apple's Numbers can read CSV files in UTF-8 encodeing (default).  But to use the CSV file with Microsoft Excel in Japanese environment you have to convert encodings like below.

`listKinoppyBooks | iconv -c -f UTF-8 -t SJIS > ./kino.csv`

Or if you have nkf installed,

`./listKinoppyBooks | nkf -Ws > ./kino.csv`

I don't know well about character encodings, I think nkf is preferable than iconv.
